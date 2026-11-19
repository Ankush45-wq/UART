/////////////////////////BAUD_GEN///////////////////////////
module baud_gen(
    input clk,
    input rst,
    output reg baud_tick
);

parameter clk_fre   = 50000000;
parameter baud_rate = 9600;

localparam DIVIDER   = clk_fre/baud_rate;
localparam cnt_width = $clog2(DIVIDER);

reg [cnt_width-1:0] count;

always @(posedge clk)
begin
    if(rst)
    begin
        count <= 0;
        baud_tick <= 0;
    end
    else
    begin
        baud_tick <= 0;

        if(count == DIVIDER-1)
        begin
            count <= 0;
            baud_tick <= 1;
        end
        else
            count <= count + 1;
    end
end

endmodule


module shift_reg #(parameter W=8)
(
    input clk,
    input rst,
    input load,
    input shift,
    input [W-1:0] data_in,
    output tx_data
);

reg [W-1:0] shift_reg;

assign tx_data = shift_reg[0];

always @(posedge clk)
begin
    if(rst)
        shift_reg <= 0;

    else if(load)
        shift_reg <= data_in;

    else if(shift)
        shift_reg <= {1'b1,shift_reg[W-1:1]};

end

endmodule

module bit_counter
(
    input clk,
    input rst,
    input shift,

    output reg done,
    output reg [3:0] bit_count
);

always @(posedge clk)
begin
    done <= 0;          // default pulse

    if(rst)
    begin
        bit_count <= 0;
        done <= 0;
    end
    else if(shift)
    begin
        if(bit_count == 7)
        begin
            bit_count <= 0;
            done <= 1;
        end
        else
            bit_count <= bit_count + 1;
    end
end

endmodule
//===========================FSM==================================
module uart_tx_fsm
(
    input clk,
    input rst,

    input tx_start,
    input baud_tick,
    input done,

    output reg load,
    output reg shift
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state,next_state;

reg load_done;

/////////////////////////
// State Register
/////////////////////////

always @(posedge clk)
begin

    if(rst)
    begin
        state <= IDLE;
        load_done <= 0;
    end

    else
    begin

        state <= next_state;

        if(state==IDLE)
            load_done <=0;

        else if(state==START && !load_done)
            load_done<=1;

    end

end

/////////////////////////
// Next State
/////////////////////////

always @(*)
begin

    next_state = state;

    case(state)

    IDLE:
    begin
        if(tx_start)
            next_state = START;
    end

    START:
    begin
        if(baud_tick)
            next_state = DATA;
    end

    DATA:
    begin
        if(done)
            next_state = STOP;
    end

    STOP:
    begin
        if(baud_tick)
            next_state = IDLE;
    end

    default:
        next_state = IDLE;

    endcase

end

/////////////////////////
// Output Logic
/////////////////////////

always @(*)
begin

    load  = 0;
    shift = 0;

    case(state)

    IDLE:
    begin
    end

    START:
    begin

        if(!load_done)
            load = 1;

    end

    DATA:
    begin

        if(baud_tick)
            shift = 1;

    end

    STOP:
    begin
    end

    endcase

end

endmodule
// =========================top modules=========================

module top #(parameter W = 8)
(
    input clk,
    input rst,
    input tx_start,
    input [W-1:0] data_in,
    output tx
);

/////////////////////////
// Internal Wires
/////////////////////////

wire baud_tick;
wire load;
wire shift;
wire done;
wire tx_data;
wire [3:0] bit_count;

/////////////////////////
// Baud Generator
/////////////////////////

baud_gen b1(
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick)
);

/////////////////////////
// Shift Register
/////////////////////////

shift_reg #(.W(W)) s1(
    .clk(clk),
    .rst(rst),
    .load(load),
    .shift(shift),
    .data_in(data_in),
    .tx_data(tx_data)
);

/////////////////////////
// Bit Counter
/////////////////////////

bit_counter b2(
    .clk(clk),
    .rst(rst),
    .shift(shift),
    .done(done),
    .bit_count(bit_count)
);

/////////////////////////
// UART FSM
/////////////////////////

uart_tx_fsm u1(
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .baud_tick(baud_tick),
    .done(done),
    .tx_data(tx_data),
    .load(load),
    .shift(shift),
    .tx(tx)
);

endmodule
