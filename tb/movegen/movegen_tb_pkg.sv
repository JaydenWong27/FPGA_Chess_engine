`timescale 1ns/1ps
`include "uvm_macros.svh"

package movegen_tb_pkg;
    import uvm_pkg::*;
    import chess_pkg::*;

    class movegen_item extends uvm_sequence_item;
        `uvm_object_utils(movegen_item)

        logic [527:0] pos;
        logic [15:0] moves[$];

        function new(string name = "movegen_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("moves size=%0d, state=%h", moves.size(), pos[527:512]);
        endfunction
    endclass

    typedef uvm_sequencer #(movegen_item) movegen_sequencer;

    class movegen_driver extends uvm_driver #(movegen_item);
        `uvm_component_utils(movegen_driver)

        virtual movegen_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual movegen_if)::get(this,"", "vif", vif))
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

    class movegen_monitor extends uvm_monitor ;
        `uvm_component_utils(movegen_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual movegen_if vif; // reading the pins
        uvm_analysis_port #(movegen_item) ap; // send items out

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            ap = new("ap", this);// creates port, ports use plai new not type_id:: create
            
            if (!uvm_config_db#(virtual movegen_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            movegen_item item;

            forever begin
                @(posedge vif.clk);

                if (vif.start === 1) begin
                    item = movegen_item::type_id::create("ITEM");
                    item.pos = vif.pos;
                end

                if (vif.move_valid === 1) begin
                    if ($isunknown(vif.move)) begin
                        `uvm_error("XOUT","move is X or Z")
                    end
                    item.moves.push_back(vif.move);

                end

                if (vif.done === 1) begin
                    `uvm_info("MON", item.convert2string(), UVM_LOW)
                    ap.write(item);
                end

            end
        endtask
    endclass

    class movegen_agent extends uvm_agent ;
        `uvm_component_utils(movegen_agent)

        movegen_sequencer sqr;
        movegen_driver drv;
        movegen_monitor mtr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            sqr = movegen_sequencer::type_id::create("sqr",this);
            drv = movegen_driver::type_id::create("drv",this);
            mtr = movegen_monitor::type_id::create("mtr",this);

        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class movegen_scoreboard extends uvm_subscriber #(movegen_item);
    `uvm_component_utils(movegen_scoreboard)

    logic [15:0] golden [logic [527:0]][$];
        int unsigned entries;
        int unsigned mismatches;
        int unsigned counter;
        string path = "../../vectors/movegen/positions.txt";

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            int fd;
            string line;
            int n;
            logic [527:0] pos;
            int count;


            super.build_phase(phase);

            fd = $fopen(path, "r");

            if (fd == 0) begin
                `uvm_fatal("VECTORS", "run gen_vectors.py first")
            end

            while ($fgets(line, fd) != 0) begin
                if(line[0] == "#") continue;
                n = $sscanf(line, "%h %h", pos, count);
                if (n == 2) begin
                    golden[pos] = {};
                    for (int i = 0; i < count; i++)
                        golden[pos].push_back(line.substr(136+5*i, 139+5*i).atohex());
                    entries++;
                end
            end

            $fclose(fd);
            
            if (golden.num() == 0) begin
                `uvm_fatal("VECTORS", $sformatf("entries found %0d", entries))
            end
            `uvm_info("VECTORS", $sformatf("loaded %0d records, %0d unique inputs", entries, golden.num()), UVM_LOW)

        endfunction

        function void write(movegen_item t);
        logic [15:0] exp[$];
        logic [15:0] got[$];
        bit bad;
        bit found;

        counter++;

        if (!golden.exists(t.pos)) begin
            `uvm_error("NOKEY",t.convert2string() )
            return;
        end

        exp = golden[t.pos];
        got = t.moves;
        got.sort();

        for (int i = 0; i < exp.size(); i++) begin
            found = 0;
            for (int j = 0; j < got.size(); j++) begin
                if (got[j] == exp[i]) begin
                    found = 1;
                end
            end

            if (!found) begin
                bad = 1;
                `uvm_error("MISSING", $sformatf("%s move %h", t.convert2string(), exp[i]))
            end

        end

        for (int i = 0; i < got.size(); i++) begin
            found = 0;
            for (int j = 0; j < exp.size(); j++) begin
                if (got[i] == exp[j]) begin
                    found = 1;
                end
            
            end

            if (!found) begin
                bad = 1;
                `uvm_error("EXTRA", $sformatf("%s move %h", t.convert2string(), got[i]))
            end

        end

        if (got.size() != exp.size()) begin
            bad = 1;
            `uvm_error("COUNT", $sformatf("%s expected %0d", t.convert2string(), exp.size()))
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

    class movegen_coverage extends uvm_subscriber #(movegen_item);
        `uvm_component_utils(movegen_coverage)

        logic [15:0] m;

        covergroup cg;
            cp_flag: coverpoint m[15:12] {
                bins quiet = {FLAG_QUIET_MOVE};
                bins double_push = {FLAG_DOUBLE_PAWN_PUSH};
                bins castle_king_side = {FLAG_CASTLE_KING_SIDE};
                bins castle_queen_side = {FLAG_CASTLE_QUEEN_SIDE};
                bins capture = {FLAG_CAPTURE};
                bins en_passant = {FLAG_EN_PASSANT_CAPTURE};
                bins promotion_bishop = {FLAG_PROMOTE_TO_BISHOP};
                bins promotion_rook = {FLAG_PROMOTE_TO_ROOK};
                bins promotion_knight = {FLAG_PROMOTE_TO_KNIGHT};
                bins promotion_queen = {FLAG_PROMOTE_TO_QUEEN};
                bins capture_promotion_bishop = {FLAG_CAPTURE_PROMOTE_BISHOP};
                bins capture_promotion_rook = {FLAG_CAPTURE_PROMOTE_ROOK};
                bins capture_promotion_knigth = {FLAG_CAPTURE_PROMOTE_KNIGHT};
                bins capture_promotion_queen = {FLAG_CAPTURE_PROMOTE_QUEEN};
            }

            cp_occ : coverpoint item.occ {
                bins empty = {64'h0};
                bins full = {64'hFFFF_FFFF_FFFF_FFFF};
                bins other = {[64'h0000_0000_0000_0001: 64'hFFFF_FFFF_FFFF_FFFE]};
            }

            x_sq_occ : cross cp_sq, cp_occ;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(movegen_item t);
            item = t;
            cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
        endfunction

    endclass

    class movegen_env extends uvm_env;
        `uvm_component_utils(movegen_env)

          movegen_agent agt;
        movegen_scoreboard sb;
        movegen_coverage cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

              agt = movegen_agent::type_id::create("agt",this);
            sb = movegen_scoreboard::type_id::create("sb", this);
            cov = movegen_coverage::type_id::create("cov", this);

        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mtr.ap.connect(sb.analysis_export);
            agt.mtr.ap.connect(cov.analysis_export);

        endfunction
    endclass

    class movegen_file_seq extends uvm_sequence #(movegen_item);
        `uvm_object_utils(movegen_file_seq)

        string fname;

        function new(string name = "movegen_file_seq");
            super.new(name);
        endfunction

        task body();
            int fd;
            string line;
            int n;
            logic [5:0] sq;
            logic [63:0] occ,rook, bishop;

            fd = $fopen(fname, "r");

            if (fd == 0) `uvm_fatal("VECTORS", $sformatf("can't open %s", fname))

            while ($fgets(line, fd) != 0) begin
                if (line[0] == "#") continue;
                n = $sscanf(line, "%h %h %h %h", sq, occ, rook, bishop);
                if (n == 4) begin
                    req = movegen_item::type_id::create("req");
                    start_item(req);
                    req.sq = sq;
                    req.occ = occ;
                    finish_item(req);
                end
            end
            $fclose(fd);
        endtask
    endclass

    class movegen_test extends uvm_test ;
        `uvm_component_utils(movegen_test)

        movegen_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env = movegen_env::type_id::create("env",this);

        endfunction 

        task run_phase(uvm_phase phase);
            movegen_file_seq seq;
            string files[4] = '{"empty.txt", "full.txt", "single.txt", "random.txt"};

            seq = movegen_file_seq::type_id::create("seq");
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 20);

            foreach (files[i]) begin
                seq.fname = {"../../vectors/attacks/", files[i]};
                seq.start(env.agt.sqr);
            end

            phase.drop_objection(this);
        endtask
    endclass


endpackage