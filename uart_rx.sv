// Code your design here
//=======================synchronizer==================================
module synchronizer (
  input clk,
  input rst,
  input rx,
  output rx_sync
);
  reg ff1,ff2;
  always@(posedge clk)
    begin
      if(rst)
        begin
          ff1 <= 1'b1;
          ff2 <= 1'b1; // UART line is idle high
        end
      else
        begin
          ff1 <= rx;
          ff2 <= ff1;
        end
    end
  assign rx_sync = ff2;
endmodule

//==========================start_detector======================
module start_bit_detector(
  input clk,
  input rst,
  input rx_sync,
  output reg start_detect
);
  reg prev_rx;
  always @(posedge clk)
    begin
      if(rst)
        begin
          start_detect <= 0;
          prev_rx <= 1'b1;
        end
      else
        begin
        if(!rx_sync && prev_rx)
          begin
            start_detect <= 1'b1;
          end
        else
          begin
            start_detect <= 1'b0;
          end
         prev_rx <= rx_sync;
       end
    end
  endmodule

//====================================Baud_generator=======================
module baud_gen #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9_600
)(
    input  wire clk,
    input  wire rst,
    input  wire baud_en,

    output reg  baud_tick,
    output reg  half_tick
);

    localparam integer DIVIDER   = CLK_FREQ / BAUD_RATE;
    localparam integer CNT_WIDTH = $clog2(DIVIDER);

    reg [CNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 1'b0;
            half_tick <= 1'b0;
        end
        else begin
            // Default outputs (1-clock pulses)
            baud_tick <= 1'b0;
            half_tick <= 1'b0;

            if (baud_en) begin

                // Half-bit pulse
                if (counter == (DIVIDER/2))
                    half_tick <= 1'b1;

                // Full-bit pulse
                if (counter == (DIVIDER - 1)) begin
                    baud_tick <= 1'b1;
                    counter   <= 0;
                end
                else begin
                    counter <= counter + 1'b1;
                end

            end
            else begin
                // Hold counter when receiver is idle
                counter <= counter;
            end
        end
    end

endmodule
  
//=========================FSM==========================
module uart_fsm(
  input clk,
  input rst,
  input start_detect,
  input half_tick,
  input baud_tick,
  input rx_sync,
  input bit_done,
  input parity_en,
  
  output reg baud_en,
  output reg shift_en,
  output reg bit_cnt_en,
  output reg data_valid,
  output reg parity_check
);
  localparam IDLE =  3'b000;
  localparam START = 3'b001;
  localparam DATA =  3'b010;
  localparam PARITY =3'b011;
  localparam STOP =  3'b100;
  localparam DONE =  3'b101;
   
  // states
  reg[2:0]state,next_state;
  
  //state register
  always @(posedge clk)
    begin
      if(rst)
        begin
          state <= IDLE;
        end
      else 
        begin
          state <= next_state;
        end
    end
  
  // next logic
  always@(*)
    begin
      next_state = state;
      case(state)
        IDLE:
          begin
            if(start_detect)
              begin
                next_state = START;
              end
            else
              begin
                next_state = IDLE;
              end
          end
            START:
              begin
                if(half_tick)
                  begin
                    if(!rx_sync)
                      begin
                        next_state = DATA;
                      end
                    else
                      begin
                        next_state =  IDLE;
                      end
                  end
                else
                  begin
                    next_state =  START;
                  end
            
              end
            DATA:
              begin
                if(baud_tick && bit_done) 
                  begin
                    if(parity_en)
                      begin
                        next_state = PARITY;
                      end
                    else
                      begin
                        next_state =  STOP;
                      end
                  end
                else
                  begin
                    next_state = DATA;
                  end
              end
            PARITY:
              begin
                if(baud_tick)
                  begin
                    next_state = STOP;
                  end
                else
                  begin
                    next_state = PARITY;
                  end
              end
            STOP:
              begin
                if(baud_tick)
                  begin
                    next_state = DONE;
                  end
                else
                  begin
                    next_state = STOP;
                  end
              end
        DONE:
          begin
            next_state = IDLE;
          end
        default:
          next_state = IDLE;
      endcase
    end
  
  //output logic
  always@(*)
    begin
     baud_en = 0;
     shift_en = 0;
     bit_cnt_en = 0;
     data_valid = 0;
     parity_check = 0;
      case(state)
        IDLE:
          begin
            
          end
        START:
          begin
            baud_en = 1'b1;
          end
        DATA:
          begin
            baud_en    = 1'b1;
            shift_en   = baud_tick;
            bit_cnt_en = baud_tick;
          end
        PARITY:
          begin
            baud_en = 1'b1;
            parity_check = baud_tick;
          end
        STOP:
          begin
            baud_en = 1'b1;
          end
        DONE:
          begin
            data_valid = 1'b1;
          end
      endcase
    end
endmodule
  
  
//===================Bit_Counter=================================
module bit_counter(
  input clk,
  input rst,
  input bit_cnt_en,
  
  output reg [2:0]bit_count,
  output  reg bit_done
);
  always@(posedge clk)
    begin
      if(rst)
        begin
          bit_count  <= 1'b0;
          bit_done <= 1'b0;
        end
      else
        begin
          if(bit_cnt_en)
            begin
              if(bit_count == 7)
                begin
                  bit_done <= 1'b1;
                  bit_count <= 0;
                end
              else
                begin
                  bit_count <= bit_count+1;
                  bit_done <= 0;
                end
            end
          else
            begin
              bit_count <= bit_count;
              bit_done  <= 0;
            end
        end
    end
endmodule
//===============shift register========================
module shift_reg(
  input clk,
  input rst,
  input shift_en,
  input rx_sync,
  
  output reg [7:0]data_out
);
  always@(posedge clk)
    begin
      if(rst)
        begin
          data_out <= 8'b0;
        end
      else
        begin
            if(shift_en)
              begin
                data_out <= {rx_sync,data_out[7:1]};
              end
        end
      end
endmodule

//======================parity_cheker======================
module parity_checker(
  input clk,
  input rst,
  input parity_check,
  input [7:0]data_out,
  input parity_rx,
  
  output  reg parity_error
  
);
  wire calc_parity;
  assign calc_parity = ^data_out;
  always@(posedge clk)
    begin
      if(rst)
        begin
          parity_error <= 1'b0;
        end
      else
        begin
          parity_error <= 1'b0;   // Default
          if(parity_check)
            begin
              parity_error <= (calc_parity != parity_rx);
            end
        end
    end
endmodule
  
  
  
  
  
  
  
  
  
  
  
  
  
