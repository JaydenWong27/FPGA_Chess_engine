`timescale 1ns/1ps
`include "uvm_macros.svh"

package slider_tb_pkg;
    import uvm_pkg::*;

    class slider_item extends uvm_sequence_item;
        `uvm_object_utils(slider_item)

        rand logic [5:0] sq;
        rand logic [63:0] occ;
        logic [63:0] rook_att, bishop_att;

            function new(string name = "slider_item");
                super.new(name);
            endfunction

            function string convert2string();
                return $sformatf("sq=%h occ=%h rook_att=%h bishop_att=%h",sq, occ, rook_att, bishop_att);
            endfunction  

    endclass

    typedef uvm_sequencer #(slider_item) slider_sequencer;

    class slider_driver extends uvm_driver #(slider_item);
        `uvm_component_utils(slider_driver)

        virtual slider_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual slider_if)::get(this,"", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.try_next_item(req);

                @(negedge vif.clk);

                if (req == null) begin
                    vif.valid <= 0;
                end else begin
                    vif.sq <= req.sq;
                    vif.occ <= req.occ;
                    vif.valid <= 1;
                    seq_item_port.item_done();
                end

            end
        endtask
    endclass

    class slider_monitor extends uvm_monitor ;
        `uvm_component_utils(slider_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual slider_if vif; // reading the pins
        uvm_analysis_port #(slider_item) ap; // send items out

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            ap = new("ap", this);// creates port, ports use plai new not type_id:: create
            
            if (!uvm_config_db#(virtual slider_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "vif not set")
        endfunction

        task run_phase(uvm_phase phase);
            slider_item item;

            forever begin
                @(posedge vif.clk);

                if (vif.valid === 1) begin
                    item = slider_item::type_id::create("item");
                    item.sq = vif.sq;
                    item.occ = vif.occ;
                    item.rook_att = vif.rook_att;
                    item.bishop_att = vif.bishop_att;
                    if ($isunknown(vif.rook_att) || $isunknown(vif.bishop_att))
                        `uvm_error("XOUT", "rook_att or bishop_att is X or Z")

                    `uvm_info("MON", item.convert2string(), UVM_LOW)
                    ap.write(item);
                end
            end
        endtask
    endclass

    class slider_agent extends uvm_agent ;
        `uvm_component_utils(slider_agent)

        slider_sequencer sqr;
        slider_driver drv;
        slider_monitor mtr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            sqr = slider_sequencer::type_id::create("sqr",this);
            drv = slider_driver::type_id::create("drv",this);
            mtr = slider_monitor::type_id::create("mtr",this);

        endfunction

        function void connect_phase(uvm_phase phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class slider_scoreboard extends uvm_subscriber #(slider_item);
    `uvm_component_utils(slider_scoreboard)

    logic [127:0] golden [logic [69:0]];
        int unsigned entries;
        int unsigned mismatches;
        int unsigned counter;
        string files[4] = '{"empty.txt", "full.txt", "single.txt", "random.txt"};
        string path = "../../vectors/attacks/";

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            int fd;
            string line;
            int n;
            logic [5:0] sq;
            logic [63:0] occ, rook, bishop;


            super.build_phase(phase);
            
            foreach (files[i]) begin
                fd = $fopen({path, files[i]}, "r");
                if (fd == 0) `uvm_fatal("VECTORS", "run gen_vectors.py first")
                while ($fgets(line, fd) != 0) begin
                    if(line[0] == "#") continue;
                    n = $sscanf(line, "%h %h %h %h", sq, occ, rook, bishop);
                    if (n == 4) begin
                        golden[{sq, occ}] = {rook, bishop};
                        entries++;

                    end
                end
                $fclose(fd);
            end

                if (golden.num() == 0) begin
                    `uvm_fatal("VECTORS", $sformatf("entries found %0d", entries))
                end
                `uvm_info("VECTORS", $sformatf("loaded %0d records, %0d unique inputs", entries, golden.num()), UVM_LOW)

        endfunction

        function void write(slider_item t);
            logic [63:0] exp_rook;
            logic [63:0] exp_bishop;
            logic [69:0] key;
            logic [127:0] exp;

            counter++;
            key = {t.sq, t.occ};

            if (!golden.exists(key)) begin
                `uvm_error("NOKEY", t.convert2string())
                return;
            end

            exp = golden[key];
            exp_rook = exp[127:64];
            exp_bishop = exp[63:0];

            if (t.rook_att !== exp_rook) begin 
                mismatches++;
                `uvm_error("MISMATCH", $sformatf("rook: %s, expected %h", t.convert2string(), exp_rook))
            end

            if (t.bishop_att !== exp_bishop) begin 
                mismatches++;
                `uvm_error("MISMATCH", $sformatf("bishop: %s, expected %h", t.convert2string(), exp_bishop))
            end
        endfunction


        function void report_phase(uvm_phase phase);

            if (mismatches > 0) begin
                `uvm_error("SCORE", "There are more than 0 MISMATCHES found")
            end

            `uvm_info("SCORE", $sformatf("checked %0d items, %0d mismatches", counter, mismatches), UVM_NONE)

        endfunction
    endclass

    class slider_coverage extends uvm_subscriber #(slider_item);
        `uvm_component_utils(slider_coverage)

        slider_item item;

        covergroup cg;
            cp_sq : coverpoint item.sq;

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

        function void write(slider_item t);
            item = t;
            cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
        endfunction

    endclass

    class slider_env extends uvm_env;
        `uvm_component_utils(slider_env)

          slider_agent agt;
        slider_scoreboard sb;
        slider_coverage cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

              agt = slider_agent::type_id::create("agt",this);
            sb = slider_scoreboard::type_id::create("sb", this);
            cov = slider_coverage::type_id::create("cov", this);

        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mtr.ap.connect(sb.analysis_export);
            agt.mtr.ap.connect(cov.analysis_export);

        endfunction
    endclass

    class slider_file_seq extends uvm_sequence #(slider_item);
        `uvm_object_utils(slider_file_seq)

        string fname;

        function new(string name = "slider_file_seq");
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
                    req = slider_item::type_id::create("req");
                    start_item(req);
                    req.sq = sq;
                    req.occ = occ;
                    finish_item(req);
                end
            end
            $fclose(fd);
        endtask
    endclass

    class slider_test extends uvm_test ;
        `uvm_component_utils(slider_test)

        slider_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env = slider_env::type_id::create("env",this);

        endfunction 

        task run_phase(uvm_phase phase);
            slider_file_seq seq;
            string files[4] = '{"empty.txt", "full.txt", "single.txt", "random.txt"};

            seq = slider_file_seq::type_id::create("seq");
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