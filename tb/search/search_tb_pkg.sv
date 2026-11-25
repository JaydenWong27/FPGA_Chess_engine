`timescale 1ns/1ps
`include "uvm_macros.svh"

package search_tb_pkg;
    import uvm_pkg::*;
    import chess_pkg::*;

    class search_item extends uvm_sequence_item;
        `uvm_object_utils(search_item)

        logic [527:0] pos;
        logic [5:0] depth;
        logic [15:0] best_move;
        logic signed [15:0] best_score;

        function new(string name = "search_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("state = %h depth=%0d best_move=%0h best score=%0d", pos[527:512], depth, best_move , best_score);
        endfunction
    endclass

    typedef uvm_sequencer #(search_item) search_sequencer;

    class search_driver extends uvm_driver #(search_item);
        `uvm_component_utils(search_driver)

        virtual search_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual search_if)::get(this,"", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set ")
        endfunction

        task run_phase(uvm_phase phase);
            vif.start <= 0;
            wait (vif.rst_n === 1);

            forever begin
                seq_item_port.get_next_item(req);

                @(negedge vif.clk);

                vif.pos <= req.pos;
                vif.depth <= req.depth;
                vif.start <= '1;

                @(negedge vif.clk);

                vif.start <= '0;

                fork
                    begin
                        @(posedge vif.clk iff vif.done === 1);
                    end
                    begin
                        for (int i = 0; i < 2000000; i++) begin
                            @(posedge vif.clk);
                        end
                        `uvm_error("TIMEOUT", $sformatf("no done after 2000000 clocks, %s", req.convert2string()) )
                    end
                join_any
                disable fork;

                @(negedge vif.clk);
                seq_item_port.item_done();
            end
        endtask
    endclass

    class search_monitor extends uvm_monitor ;
        `uvm_component_utils(search_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual search_if vif; // reading the pins
        uvm_analysis_port #(search_item) ap; // send items out

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            ap = new("ap", this);// creates port, ports use plai new not type_id:: create
            
            if (!uvm_config_db#(virtual search_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            search_item item;

            forever begin
                @(posedge vif.clk);

                if (vif.start === 1) begin
                    item = search_item::type_id::create("item");
                    item.pos = vif.pos;
                    item.depth = vif.depth;
                end

                if (vif.done === 1) begin
                    if ($isunknown({vif.best_move, vif.best_score})) begin
                        `uvm_error("XOUT", $sformatf("best_move/best_score has X: %h %h", vif.best_move, vif.best_score))
                    end
                    item.best_move = vif.best_move;
                    item.best_score = vif.best_score;

                    `uvm_info("MON", item.convert2string(), UVM_LOW)
                    ap.write(item);
                end

            end
        endtask
    endclass

    class search_agent extends uvm_agent ;
        `uvm_component_utils(search_agent)

        search_sequencer sqr;
        search_driver drv;
        search_monitor mtr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            sqr = search_sequencer::type_id::create("sqr",this);
            drv = search_driver::type_id::create("drv",this);
            mtr = search_monitor::type_id::create("mtr",this);

        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class search_scoreboard extends uvm_subscriber #(search_item);
    `uvm_component_utils(search_scoreboard)

        logic [31:0] golden [logic [533:0]]; // key {pos, depth}, value {move, score}
        int unsigned entries;
        int unsigned mismatches;
        int unsigned counter;
        string path = "../../vectors/search/search.txt";

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            logic [527:0] pos;
            int fd;
            string line;
            int n;
            logic [5:0] depth;
            logic [15:0] move, score;


            super.build_phase(phase);

            fd = $fopen(path, "r");

            if (fd == 0) begin
                `uvm_fatal("VECTORS", "run gen_vectors.py first")
            end

            while ($fgets(line, fd) != 0) begin
                if(line[0] == "#") continue;
                n = $sscanf(line, "%h %h %h %h", pos, depth, move, score);
                if (n == 4) begin
                    golden[{pos, depth}] = {move, score};
                    entries++;
                end
            end

            $fclose(fd);
            
            if (golden.num() == 0) begin
                `uvm_fatal("VECTORS", $sformatf("entries found %0d", entries))
            end
            `uvm_info("VECTORS", $sformatf("loaded %0d records, %0d unique inputs", entries, golden.num()), UVM_LOW)

        endfunction

        function void write(search_item t);
        logic [31:0] exp;
        bit bad;

        counter++;

        if (!golden.exists({t.pos, t.depth})) begin
            `uvm_error("NOKEY",t.convert2string() )
            return;
        end

        exp = golden[{t.pos, t.depth}];

        if (t.best_move !== exp[31:16]) begin
            bad = 1;
            `uvm_error("MISMATCH", $sformatf("move: %s expected %h", t.convert2string(), exp[31:16]))
        end

        if (t.best_score !== exp[15:0]) begin
            bad = 1;
            `uvm_error("MISMATCH", $sformatf("score: %s expected %0d", t.convert2string(), $signed(exp[15:0])))
        end

        if (bad) mismatches++;

        endfunction


        function void report_phase(uvm_phase phase);

            if (mismatches > 0) begin
                `uvm_error("SCORE", "There are more than 0 MISMATCHES found")
            end

            `uvm_info("SCORE", $sformatf("checked %0d items, %0d mismatches", counter, mismatches), UVM_NONE)

        endfunction
    endclass

    class search_coverage extends uvm_subscriber #(search_item);
        `uvm_component_utils(search_coverage)

        logic [5:0] depth;
        logic signed [15:0] score;
        logic null_move;

        covergroup cg;
            cp_depth : coverpoint depth {
                bins d1 = {1};
                bins d2 = {2};
                bins d3 = {3};
            }

            cp_score : coverpoint score {
                bins mated = {[$:-MATE_BOUND]};         // side to move gets mated
                bins neg = {[-MATE_BOUND+1:-1]};
                bins zero = {0};                        // stalemate or dead even
                bins pos = {[1:MATE_BOUND-1]};
                bins mating = {[MATE_BOUND:$]};         // side to move delivers mate
            }

            cp_null : coverpoint null_move {            // no legal moves at the root
                bins has_move = {0};
                bins no_move = {1};
            }
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(search_item t);

        depth = t.depth;
        score = t.best_score;
        null_move = (t.best_move == NULL_MOVE);
        cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
        endfunction

    endclass

    class search_env extends uvm_env;
        `uvm_component_utils(search_env)

          search_agent agt;
        search_scoreboard sb;
        search_coverage cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

              agt = search_agent::type_id::create("agt",this);
            sb = search_scoreboard::type_id::create("sb", this);
            cov = search_coverage::type_id::create("cov", this);

        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mtr.ap.connect(sb.analysis_export);
            agt.mtr.ap.connect(cov.analysis_export);

        endfunction
    endclass

    class search_file_seq extends uvm_sequence #(search_item);
        `uvm_object_utils(search_file_seq)

        string fname;
        int max_depth = 3; // lines deeper than this are skipped, depth 3 sims are slow

        function new(string name = "search_file_seq");
            super.new(name);
        endfunction

        task body();
            int fd;
            string line;
            int n;
            logic [527:0] pos;
            logic [5:0] depth;

            fd = $fopen(fname, "r");

            if (fd == 0) `uvm_fatal("VECTORS", $sformatf("can't open %s", fname))

            while ($fgets(line, fd) != 0) begin
                if (line[0] == "#") continue;
                n = $sscanf(line, "%h %h", pos, depth);
                if (n == 2 && depth <= max_depth) begin
                    req = search_item::type_id::create("req");
                    start_item(req);
                    req.pos = pos;
                    req.depth = depth;
                    finish_item(req);
                end
            end
            $fclose(fd);
        endtask
    endclass

    class search_test extends uvm_test ;
        `uvm_component_utils(search_test)

        search_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env = search_env::type_id::create("env",this);

        endfunction 

        task run_phase(uvm_phase phase);
            search_file_seq seq;

            seq = search_file_seq::type_id::create("seq");
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 20);

            seq.fname = "../../vectors/search/search.txt";
            if (!$value$plusargs("MAX_DEPTH=%d", seq.max_depth))
                seq.max_depth = 3;
            `uvm_info("TEST", $sformatf("max depth %0d", seq.max_depth), UVM_NONE)
            seq.start(env.agt.sqr);

            phase.drop_objection(this);
        endtask
    endclass


endpackage