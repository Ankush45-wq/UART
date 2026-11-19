`timescale 1ns/1ps

module tb;

parameter W = 8;

//------------------------------------
// Signals
//------------------------------------
reg clk;
reg rst;
reg tx_start;
reg [W-1:0] data_in;

wire tx;

//------------------------------------
// DUT
//------------------------------------
top #(.W(W)) dut
(
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .data_in(data_in),
    .tx(tx)
);

//------------------------------------
// Clock
//------------------------------------
initial
    clk = 0;

always #10 clk = ~clk;

//------------------------------------
// Task
//------------------------------------
task send_byte;
input [7:0] data;
begin

    @(negedge clk);
    data_in  = data;
    tx_start = 1;

    @(negedge clk);
    tx_start = 0;

    // Wait for complete transmission
    repeat(6000) @(posedge clk);

end
endtask

//------------------------------------
// Stimulus
//------------------------------------
initial
begin

    $dumpfile("uart_tx.vcd");
    $dumpvars(0,tb);

    rst      = 1;
    tx_start = 0;
    data_in  = 8'h00;

    repeat(5) @(posedge clk);
    rst = 0;

    repeat(2) @(posedge clk);

    send_byte(8'hA5);
    send_byte(8'h5A);
    send_byte(8'h3C);
    send_byte(8'hF0);
    send_byte(8'h55);

    repeat(20) @(posedge clk);

    $finish;

end

//------------------------------------
// Monitor
//------------------------------------
initial
begin
    $monitor(
    "T=%0t rst=%b start=%b data=%h tx=%b",
    $time,
    rst,
    tx_start,
    data_in,
    tx
    );
end

endmodule
