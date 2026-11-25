`timescale 1ns/1ps
`include "uvm_macros.svh"

package castle_tb_pkg;
    import uvm_pkg::*;

    class my_test extends uvm_test;
        `uvm_component_utils(my_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info("HELLO", "UVM is running", UVM_LOW)
            #10;

            phase.drop_objection(this);
        endtask

    endclass

    class castle_item extends uvm_sequence_item;
        `uvm_object_utils(castle_item)

        rand logic [3:0] castle_in;
        rand logic [5:0] from_sq;
        rand logic [5:0] to_sq;
            logic [3:0] castle_out;

            function new(string name = "castle_item");
                super.new(name);
            endfunction

            function string convert2string();
                return $sformatf("in=%0d from=%0d to=%0d out=%0d", castle_in, from_sq, to_sq, castle_out);
            endfunction  

    endclass

    typedef uvm_sequencer #(castle_item) castle_sequencer;

    class castle_seq extends uvm_sequence #(castle_item);
        `uvm_object_utils(castle_seq)

        function new(string name = "castle_seq");
            super.new(name);
        endfunction

        task body();
            repeat (5) begin
                req = castle_item::type_id::create("req");
                start_item(req);
                req.castle_in = 4'b1111;
                req.from_sq = 6'd4;
                req.to_sq = 6'd6;
                finish_item(req);
            end
        endtask

    endclass


    class castle_driver extends uvm_driver #(castle_item);
        `uvm_component_utils(castle_driver)

        virtual castle_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual castle_if)::get(this,"", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.try_next_item(req);

                @(negedge vif.clk);

                if (req == null) begin
                    vif.valid <= 0;
                end else begin
                    vif.castle_in <= req.castle_in;
                    vif.from_sq <= req.from_sq;
                    vif.to_sq <= req.to_sq;
                    vif.valid <= 1;
                    seq_item_port.item_done();
                end

            end
        endtask
    endclass

    class castle_monitor extends uvm_monitor ;
        `uvm_component_utils(castle_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual castle_if vif; // reading the pins
        uvm_analysis_port #(castle_item) ap; // send items out

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            ap = new("ap", this);// creates port, ports use plai new not type_id:: create
            
            if (!uvm_config_db#(virtual castle_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            castle_item item;

            forever begin
                @(posedge vif.clk);

                if (vif.valid === 1) begin
                    item = castle_item::type_id::create("item");
                    item.castle_in = vif.castle_in;
                    item.from_sq = vif.from_sq;
                    item.to_sq = vif.to_sq;
                    if ($isunknown(vif.castle_out))
                        `uvm_error("XOUT", "castle_out is X or Z")
                    item.castle_out = vif.castle_out;

                    `uvm_info("MON", item.convert2string(), UVM_LOW)
                    ap.write(item);
                end
            end
        endtask
    endclass

    class castle_scoreboard extends uvm_subscriber #(castle_item);
        `uvm_component_utils(castle_scoreboard)

        logic [3:0] golden_table [65535:0];
        bit seen [65536];
        bit expect_all;
        int unsigned entries;
        int unsigned mismatches;
        int unsigned counter;
        string path = "../../vectors/castle_update.txt";

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
        int fd;
        string line;
        int n;
        logic [3:0] c_in, c_out;
        logic [5:0] f, t;

            super.build_phase(phase);

            fd = $fopen(path, "r");
            if (fd == 0) `uvm_fatal("VECTORS", "run gen_vectors.py first")
            while ($fgets(line, fd) != 0) begin
                if(line[0] == "#") continue;
                n = $sscanf(line, "%h %h %h %h", c_in, f, t, c_out);
                if (n == 4) begin
                    golden_table[{c_in, f, t}] = c_out;
                    entries++;

                end
            end
            $fclose(fd);
            if (entries != 65536) begin
                `uvm_fatal("VECTORS", $sformatf("entries found %0d", entries))
            end

        endfunction

        function void write(castle_item t);
            logic [3:0] exp;
            exp = golden_table[{t.castle_in, t.from_sq, t.to_sq}];
            seen[{t.castle_in, t.from_sq, t.to_sq}] = '1;
            counter++;

            if (t.castle_out !== exp) begin
                mismatches++;
                `uvm_error("MISMATCH", $sformatf("%s, expected %b", t.convert2string(), exp))
            end
        endfunction

        function void report_phase(uvm_phase phase);
        int unsigned count = 0;

            foreach (seen[i])
                count += seen[i];

            if (expect_all && count != 65536) begin
                `uvm_error("SCORE",  $sformatf("only %0d of 65536 inputs seen", count))
            end

            if (mismatches > 0) begin
                `uvm_error("SCORE", "There are more than 0 MISMATCHES found")
            end

            `uvm_info("SCORE", $sformatf("checked %0d items, %0d mismatches", counter, mismatches), UVM_NONE)

        endfunction
    endclass

    class castle_agent extends uvm_agent ;
        `uvm_component_utils(castle_agent)

        castle_sequencer sqr;
        castle_driver drv;
        castle_monitor mtr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            sqr = castle_sequencer::type_id::create("sqr",this);
            drv = castle_driver::type_id::create("drv",this);
            mtr = castle_monitor::type_id::create("mtr",this);

        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class castle_coverage extends uvm_subscriber #(castle_item);
        `uvm_component_utils(castle_coverage)

        castle_item item;

        covergroup cg; // covergroup reads from this
            cp_castle : coverpoint item.castle_in;
            cp_from : coverpoint item.from_sq {
                bins a1 = {0};
                bins e1 = {4};
                bins h1 = {7};
                bins a8 = {56};
                bins e8 = {60};
                bins h8 = {63};
                bins other = { [1:3], [5:6], [8:55], [57:59], [61:62]};
            }

            cp_to : coverpoint item.to_sq {            
                bins a1 = {0};
                bins e1 = {4};
                bins h1 = {7};
                bins a8 = {56};
                bins e8 = {60};
                bins h8 = {63};
                bins other = { [1:3], [5:6], [8:55], [57:59], [61:62]};
            }

            x_from_to : cross cp_from, cp_to;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(castle_item t);
            item = t;
            cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
        endfunction
    endclass

    class castle_env extends uvm_env;
        `uvm_component_utils(castle_env)

        castle_agent agt;
        castle_scoreboard sb;
        castle_coverage cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            agt = castle_agent::type_id::create("agt",this);
            sb = castle_scoreboard::type_id::create("sb", this);
            cov = castle_coverage::type_id::create("cov", this);

        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mtr.ap.connect(sb.analysis_export);
            agt.mtr.ap.connect(cov.analysis_export);

        endfunction
    endclass

    class castle_test extends uvm_test ;
        `uvm_component_utils(castle_test)

        castle_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env = castle_env::type_id::create("env",this);

        endfunction 

        task run_phase(uvm_phase phase);
            castle_seq item;
            phase.raise_objection(this);

            phase.phase_done.set_drain_time(this, 20);
            
            item = castle_seq::type_id::create("seq");

            item.start(env.agt.sqr);

            phase.drop_objection(this);
        endtask
    endclass

    class castle_exhaustive_seq extends uvm_sequence #(castle_item);
        `uvm_object_utils(castle_exhaustive_seq)

        function new(string name = "castle_exhaustive_seq");
            super.new(name);
        endfunction

        task body();
            for (int i = 0; i < 16; i++) begin
                for (int j = 0; j < 64; j++) begin
                    for(int k = 0; k < 64; k++) begin
                        req = castle_item::type_id::create("req");
                        start_item(req);
                        req.castle_in = i;
                        req.from_sq = j;
                        req.to_sq = k;
                        finish_item(req);
                    end

                end

            end
        endtask

    endclass

    class castle_random_seq extends uvm_sequence #(castle_item);
        `uvm_object_utils(castle_random_seq)

        int unsigned n_items = 1000;

        function new(string name = "castle_random_seq");
            super.new(name);
        endfunction

        task body();
            bit from_special; 
            bit to_special;

            repeat(n_items) begin
                req = castle_item::type_id::create("req");
                start_item(req);

                from_special = $urandom_range(1);
                to_special = $urandom_range(1);

                if (!req.randomize() with {
                    from_special -> from_sq inside {0, 4 ,7, 56, 60, 63}; // from -> from means if a is true then b must hold, if a is false no rule at a
                    // means must be one of these vlaues six keep squares
                    to_special -> to_sq inside {0, 4 ,7, 56, 60, 63};
                })

                    `uvm_fatal("RAND", "randomize failed")

                finish_item(req);

            end 

        endtask
    endclass

    class castle_full_test extends castle_test;
        `uvm_component_utils(castle_full_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        castle_exhaustive_seq ces;
        castle_random_seq crs;

        task run_phase(uvm_phase phase);
            ces = castle_exhaustive_seq::type_id::create("ces");
            crs = castle_random_seq::type_id::create("crs");
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 20);
            env.sb.expect_all = 1;

            ces.start(env.agt.sqr);
            crs.start(env.agt.sqr);



            phase.drop_objection(this);

        endtask

    endclass


endpackage