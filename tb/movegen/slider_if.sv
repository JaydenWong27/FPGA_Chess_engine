//interface are bunch of wires with a name , without one driver monitor and dut need to reach everysingal passed separatelyh

//with one tb_slider creates one instance and plugs DUT'sport into wire
//driver and monitor get handle then read and write vif.sq, vif.occ and so on

// meeting point between UVM and hardware

interface slider_if (input logic clk);
    logic valid;
    logic [5:0] sq;
    logic [63:0] occ;
    logic [63:0] rook_att, bishop_att;
endinterface