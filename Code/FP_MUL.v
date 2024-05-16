`timescale 1ns/1ps

//cadence translate off
`include "/usr/chipware/CW_mult_pipe.v" 
`include "/usr/chipware/CW_mult_seq.v" 
`include "/usr/chipware/CW_mult.v" 
//cadence translate_on

module FP_MUL (CLK, RESET, ENABLE, DATA_IN, DATA_OUT, READY);
//Parameter
parameter fp_latency=3;
// I/O Ports
input CLK; //clock signal
input RESET; //sync. RESET=1
input ENABLE; //input data sequence when ENABLE =1
input [7:0] DATA IN; //input data sequence 
output [7:0] DATA_OUT; //ouput data sequence
output READY; //output data is READY when READY=1
reg READY;
reg [4:0] counter_in; [7:0] input_A [0:7]; [7:0] input B [0:7];
reg in_data_rdy;
reg [7:0] output_Z [0:7];
reg [7:0] DATA_OUT;
reg [3:0] counter_out;
real real_A, real_B, real_Z;
integer fp_count;
integer i;
wire [63:0] A, B;
wire mul_en;
wire sign A, sign_B, sign_C;
wire [10:0] exp_A, exp_B;
wire [51:0] mantissa A, mantissa_B;
wire [105:0] product, product2;
wire [51:0] product_104_53;
wire [52:0] product_52_0;
wire [7:0] output_C [0:7];
reg [11:0] exp_C; 
wire [10:0] exp_C_buf; 
reg [51:0] mantissa_C; 
reg [5:0] mul_counter;

reg [63:0] C;
reg [2:0] current_state, next_state;
wire product_complete, start_mul;

parameter INIT = 0, READ = 1, CAL 2, EXPORT = 3;
assign exp_C_buf = exp_C[10:0];
assign A = {input_A[7], input_A[6], input_A[5], input_A[4], input_A[3], input_A[2], input_A[1], input_A[0]}; assign B {input_B[7], input_B[6], input_B[5], input_B[4], input_B[3], input_B[2], input_B[1], input_B[0]}; 
assign sign_A = input_A[7][7];
assign sign_B = input_B[7][7];
assign sign_C = sign_A^ sign_B;
assign exp_A = {input_A[7] [6:0], input_A[6][7:4]};
assign exp_B = {input_B[7] [6:0], input_B[6][7:4]};
assign mantissa A = {input_A[6] [3:0], input_A[5], input_A[4], input_A[3], input_A[2], input_A[1], input_A[0]}; 
assign mantissa B = {input_B[6] [3:0], input_B[5], input_B[4], input_B[3], input_B[2], input_B[1], input_B[0]}; 
assign start_mul = current_state == CAL && mul_counter == 6'd0;
assign output_C[7] = C[63:56];
assign output_C[6] = C[55:48];
assign output_C[5] = C [47:40]; 
assign output_C[4] = C[39:32]; 
assign output_C[3] = C[31:24]; 
assign output_C[2] = C[23:16];
assign output_C[1] = C[15:8];
assign output_C[0] = C[7:0];
CW_mult_seq#(53,53,0,53,1,1,0,1) U1(.clk(CLK), .rst_n(~RST), .hold (1'b0), .start(start_mul), .a({1'b1, mantissa_A}), .b({1'b1, mantissa_B}), .complete(product_complete), .product (product));

always @(*) begin
  case (current_state)
    INIT: next_state= (RESET || ~ENABLE)? INIT : READ;
    READ: next_state= ~ENABLE? CAL: READ;
    CAL: next state = mul counter == 6'd57 ? EXPORT: CAL;
    EXPORT: next_state = counter_out >= 4'd7 ? INIT: EXPORT; 
  endcase
end


always @(posedge CLK) begin
  if (RESET)
    C <= 64'd0;
  else if (current_state== CAL && mul_counter == 6'd55) begin
    if (exp_A == 11'd2047 || exp_B == 11'd2047) begin // infinity or NaN
      if (mantissa A != 52'd0 && exp_A == 11'd2047) //NaN_A 
        C<= {sign_A, exp_A, 1'b1, mantissa_A[50:0]};
      else if (mantissa B != 52'd0 && exp_B == 11'd2047) //NaN_B
        C<= {sign_B, exp_B, 1'b1, mantissa_B[50:0]};
      else if (mantissa_A!=52'd0 || mantissa_B!=52'd0) //inifinity * non_zero
        C<= {sign_C, 11'd2047, 52'd0};
      else // infinity * 0
        C<= {sign_C, 63'd0};
    end
    else if (A[62:0] == 63'd0 || B[62:0] == 63'd0)
      C<= {sign_C, 63'd0};
    else begin //Normal
      if (exp_C[11]==1'b1)
        C<={1'b0, 11'd2047, 52'd1};
      else
        C<= {sign_C, exp_C[10:0], mantissa_C};
    end
  end
end

always @(posedge CLK) begin
  if (RESET)
    exp_C<= 12'd0;
  else if (current_state== CAL) begin
    case (mul_counter)
      6'd53: exp_C <= exp_A + exp_B;
      6'd54: exp_C<= product [105] == 1'b1 ? exp_C - 12'd1022 exp_C - 12'd1023; //Normalize 
      default exp_C <= exp_C;
    endcase
  end
end


always @(posedge CLK) begin
  if (RESET)
    mantissa_C <= 52'd0;
  else if (current_state== CAL && mul_counter == 6'd52) 
    if (product [105] == 1'b1) begin
  	  if (product [52] == 1'b1) begin
              if (product [53] == 1'b1 || (product [53] == 1'b0 && product[51:0] != 52'd0)
  		    mantissa C <= product [104:53] + 52'd1;
  	    else
  		    mantissa C <= product [104:53];
            end
    else begin
      if (product[51] == 1'b1) begin
        if (product[52] == 1'b1 || (product[52] == 1'b0 && product[50:0] != 51'd0)
    	    mantissa_C <= product [103:52] + 52'd1;
        else
    	    mantissa_C <= product [103:52];
      end
      else
        mantissa_C <= product[103:52];
    end
  end
end

always @(posedge CLK) begin
  if (RESET)
    DATA_OUT <= 8'd0;
  else if (next_state== EXPORT || (current_state== EXPORT && counter_out < 4'd8)) 
    DATA_OUT <= output_C[counter_out];
  else
    DATA_OUT <= 8'd0;
end

always @(posedge CLK) begin
  if (RESET)
    READY<=1'b0;
  else if (next_state== EXPORT || (current_state == EXPORT && counter_out < 4'd8))
    READY <=1'b1;
  else
    READY <=1'b0;
end


always @(posedge CLK) begin
  if (RESET)
    counter_out <= 4'd0;
  else if (current_state== EXPORT || next_state == EXPORT) 
    counter_out << counter_out + 4'd1;
  else if (current_state == INIT || next_state
    counter_out <= 4'd0;
end

always @(posedge CLK) begin
  if (RESET)
    mul_counter <= 6'd0;
  else if (current_state== CAL && mul_counter != 6'd63)
    mul_counter <= mul_counter + 6'd1;
  else if (current_state== EXPORT)
    mul_counter << 6'd0;
end

always @(posedge CLK) begin
  if (RESET)
   counter_in <= 5'd0;
  else if (ENABLE && counter_in != 5'd15)
    counter_in <= counter_in + 5'd1; 
  else if (current_state== INIT)
    counter_in <= 5'd0;
end

always @(posedge CLK) begin
  if (RESET)
    for(i=0; i<=7; i=i+1) input_B[i] <= 8'd0;
  else if (ENABLE && counter_in > 5'd7 && counter_in <= 5'd15) 
    input_B[counter_in-5'd8] <= DATA_IN;
end

always @(posedge CLK) begin
  if (RESET)
    for(i=0; i<=7; i=i+1) input_A[i] <= 8'd0; 
  else if (ENABLE && counter_in 5'd8) begin 
    input_A[counter_in] <= DATA_IN;
  end
end

always @(posedge CLK) begin
  if (RESET)
    current state <= INIT;
  else
    current_state <= next_state;
end

endmodule
