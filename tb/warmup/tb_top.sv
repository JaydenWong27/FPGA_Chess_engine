`timescale 1ns/1ps
`include "uvm_macros.svh"
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
    int unsigned [16:0] entries;
    int unsigned [16:0] mismatches;
    string path = "../../vectors/castle_update.txt";

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
    int fd;
    string line;
    logic [3:0] a, d;
    logic [5:0] b, c;

        super.build_phase(phase);

        fd = $fopen(path, "r")
        if (fd == 0) `uvm_fatal("Not Available", "run gen_vectors.py first")
        while ($fgets(line, fd) != 0) begin
            if(line[0] == "#") begin
            end else begin
                $sscanf(line, "%h %h %h %h", a, b, c, d)

            end
        end

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

class castle_test extends uvm_test ;
    `uvm_component_utils(castle_test)

    castle_agent agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt = castle_agent::type_id::create("agt",this);

    endfunction 

    task run_phase(uvm_phase phase);
        castle_seq item;
        phase.raise_objection(this);

        phase.phase_done.set_drain_time(this, 20);
        
        item = castle_seq::type_id::create("seq");

        item.start(castle_agent.sqr);

        phase.drop_objection(this);
    endtask
    

endclass


module tb;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    castle_if cif (.clk(clk));

    castle_update dut (
        .castle_in (cif.castle_in),
        .castle_out (cif.castle_out),
        .from_sq (cif.from_sq),
        .to_sq (cif.to_sq)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual castle_if)::set(null, "*", "vif", cif);
        run_test();

    end

endmodule

