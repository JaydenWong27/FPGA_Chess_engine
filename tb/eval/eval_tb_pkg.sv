`timescale 1ns/1ps
`include "uvm_macros.svh"

package eval_tb_pkg;
    import uvm_pkg::*;
    import chess_pkg::*;

    class eval_item extends uvm_sequence_item;
        `uvm_object_utils(eval_item)

        logic [527:0] pos;
        logic signed [15:0] score, mat , pst;

        function new(string name = "eval_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("state = %h mat=%0d pst=%0d score=%0d", pos[527:512], mat, pst, score);
        endfunction
    endclass

    typedef uvm_sequencer #(eval_item) eval_sequencer;

    class eval_driver extends uvm_driver #(eval_item);
        `uvm_component_utils(eval_driver)

        virtual eval_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual eval_if)::get(this,"", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set ")
        endfunction

        task run_phase(uvm_phase phase);
            vif.start <= 0;
            wait (vif.rst_n === 1);

            forever begin
                seq_item_port.get_next_item(req);

                @(negedge vif.clk);

                vif.pos <= req.pos;
                vif.start <= '1;

                @(negedge vif.clk);

                vif.start <= '0;

                fork
                    begin
                        @(posedge vif.clk iff vif.done === 1);
                    end
                    begin
                        for (int i = 0; i < 5000; i++) begin
                            @(posedge vif.clk);
                        end
                        `uvm_error("TIMEOUT", $sformatf("no done after 5000 clocks, %s", req.convert2string()) )
                    end
                join_any
                disable fork;

                @(negedge vif.clk);
                seq_item_port.item_done();
            end
        endtask
    endclass

    class eval_monitor extends uvm_monitor ;
        `uvm_component_utils(eval_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual eval_if vif; // reading the pins
        uvm_analysis_port #(eval_item) ap; // send items out

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            ap = new("ap", this);// creates port, ports use plai new not type_id:: create
            
            if (!uvm_config_db#(virtual eval_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            eval_item item;

            forever begin
                @(posedge vif.clk);

                if (vif.start === 1) begin
                    item = eval_item::type_id::create("item");
                    item.pos = vif.pos;
                end

                if (vif.done === 1) begin
                    if ($isunknown(vif.score) || $isunknown(vif.mat_score) || $isunknown(vif.pst_score)) begin
                        `uvm_error("XOUT", "unknown value, one of the three socres is X")
                    end
                    item.score = vif.score;
                    item.mat = vif.mat_score;
                    item.pst = vif.pst_score;

                    `uvm_info("MON", item.convert2string(), UVM_LOW)
                    ap.write(item);
                end

            end
        endtask
    endclass

    class eval_agent extends uvm_agent ;
        `uvm_component_utils(eval_agent)

        eval_sequencer sqr;
        eval_driver drv;
        eval_monitor mtr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            sqr = eval_sequencer::type_id::create("sqr",this);
            drv = eval_driver::type_id::create("drv",this);
            mtr = eval_monitor::type_id::create("mtr",this);

        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class eval_scoreboard extends uvm_subscriber #(eval_item);
    `uvm_component_utils(eval_scoreboard)

        logic [47:0] golden [logic [527:0]];
        int unsigned entries;
        int unsigned mismatches;
        int unsigned counter;
        string path = "../../vectors/eval/eval.txt";

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            logic [527:0] pos;
            int fd;
            string line;
            int n;
            logic [15:0] mat, pst, score;


            super.build_phase(phase);

            fd = $fopen(path, "r");

            if (fd == 0) begin
                `uvm_fatal("VECTORS", "run gen_vectors.py first")
            end

            while ($fgets(line, fd) != 0) begin
                if(line[0] == "#") continue;
                n = $sscanf(line, "%h %h %h %h", pos, mat, pst, score);
                if (n == 4) begin
                    golden[pos] = {mat, pst, score};
                    entries++;
                end
            end

            $fclose(fd);
            
            if (golden.num() == 0) begin
                `uvm_fatal("VECTORS", $sformatf("entries found %0d", entries))
            end
            `uvm_info("VECTORS", $sformatf("loaded %0d records, %0d unique inputs", entries, golden.num()), UVM_LOW)

        endfunction

        function void write(eval_item t);
        logic [47:0] exp;
        bit bad;

        counter++;

        if (!golden.exists(t.pos)) begin
            `uvm_error("NOKEY",t.convert2string() )
            return;
        end

        exp = golden[t.pos];
        
        if (t.mat !== exp[47:32]) begin
            bad = 1;
            `uvm_error("MISMATCH", $sformatf("mat: %s expected %0d", t.convert2string(), $signed(exp[47:32])))
        end

        if (t.pst !== exp[31:16]) begin
            bad = 1;
            `uvm_error("MISMATCH", $sformatf("pst: %s expcted %0d", t.convert2string(), $signed(exp[31:16])))
        end

        if (t.score !== exp[15:0]) begin
            bad = 1;
            `uvm_error("MISMATCH", $sformatf("score: %s expcted %0d", t.convert2string(), $signed(exp[15:0])))
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

    class eval_coverage extends uvm_subscriber #(eval_item);
        `uvm_component_utils(eval_coverage)

        logic stm;
        logic signed [15:0] score, mat;

        covergroup cg;
            cp_stm: coverpoint stm {
                bins white = {0};
                bins black = {1};
            }

            cp_score : coverpoint score {
                bins neg = {[$:-1]};
                bins zero = {0};
                bins pos = {[1:$]};
            }

            cp_mat : coverpoint mat {
                bins black_ahead = {[$:-100]};
                bins even = {[-99:99]};
                bins white_ahead = {[100:$]};
            }

            x_stm_score : cross cp_stm, cp_score;

        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(eval_item t);

        stm = t.pos[512];
        score = t.score;
        mat = t.mat;
        cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
        endfunction

    endclass

    class eval_env extends uvm_env;
        `uvm_component_utils(eval_env)

          eval_agent agt;
        eval_scoreboard sb;
        eval_coverage cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

              agt = eval_agent::type_id::create("agt",this);
            sb = eval_scoreboard::type_id::create("sb", this);
            cov = eval_coverage::type_id::create("cov", this);

        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mtr.ap.connect(sb.analysis_export);
            agt.mtr.ap.connect(cov.analysis_export);

        endfunction
    endclass

    class eval_file_seq extends uvm_sequence #(eval_item);
        `uvm_object_utils(eval_file_seq)

        string fname;

        function new(string name = "eval_file_seq");
            super.new(name);
        endfunction

        task body();
            int fd;
            string line;
            int n;
            logic [527:0] pos;

            fd = $fopen(fname, "r");

            if (fd == 0) `uvm_fatal("VECTORS", $sformatf("can't open %s", fname))

            while ($fgets(line, fd) != 0) begin
                if (line[0] == "#") continue;
                n = $sscanf(line, "%h", pos);
                if (n == 1) begin
                    req = eval_item::type_id::create("req");
                    start_item(req);
                    req.pos = pos;
                    finish_item(req);
                end
            end
            $fclose(fd);
        endtask
    endclass

    class eval_test extends uvm_test ;
        `uvm_component_utils(eval_test)

        eval_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env = eval_env::type_id::create("env",this);

        endfunction 

        task run_phase(uvm_phase phase);
            eval_file_seq seq;

            seq = eval_file_seq::type_id::create("seq");
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 20);

            seq.fname = "../../vectors/eval/eval.txt";
            seq.start(env.agt.sqr);

            phase.drop_objection(this);
        endtask
    endclass


endpackage