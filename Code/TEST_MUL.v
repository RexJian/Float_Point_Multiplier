
`timescale 1ns/1ps 
define CYCLE 0.3 
`include "FP_MUL.v"

module TEST;
//parameter CYCLE=0.5;
parameter SIM_CYCLE=200;
parameter SIM_SPECIAL_CYCLE=10; integer seed;
reg CLK, RESET;
reg ENABLE;
reg [7:0] DATA_IN;
wire [7:0] DATA_OUT;
wire READY;
reg [63:0] A, B; //FP input
reg [63:0] Z; //FP_MUL output
reg [63:0] C; //Expect FP_MUL output reg tar_sign_C;
reg [10:0] tar_exp_C;
reg [51:0] tar_mantissa_C;
reg [103:0] prod;
reg [31:0] err_count;
reg [31:0] sim_count;
integer i, special_cnt;
reg rand_sign1, rand_sign2;
reg [10:0] rand_expl, rand_exp2;
reg [51:0] rand_mantissal, rand_mantissa2;
reg [63:0] SPECIAL_IN_A, SPECIAL_IN_B;
FP_MUL FP_MUL(. CLK (CLK), .RESET (RESET), .ENABLE (ENABLE), .DATA_IN (DATA_IN), .DATA_OUT(DATA_OUT), .READY(READY));

always #(`CYCLE/2.0) CLK-CLK;


initial begin 
$fsdbDumpfile("FP_MUL.fsdb");
$fsdbDumpvars;
$fsdbDumpMDA; 
seed = 11;
CLK=0; RESET=0; ENABLE=0;
DATA IN=0;
A=0; B=0; Z=0; C=0;
err_count=0;
@(negedge CLK) RESET=1;
@(negedge CLK) RESET=0;

for(i=0; i <= SIM_CYCLE; i=i+1) begin
  //Give Pattern
  fp_patten;
  //Check Result
  fp_check;
  repeat (2) @(negedge CLK); //wait 2 clock cycles 
end

for(i=0; i< SIM_SPECIAL_CYCLE; i=i+1) begin
  for (special_cnt=0; special_cnt <= 3; special_cnt=special_cnt+1) begin
    rand_sign1 = $random; 
    rand_sign2 = $random; 
    rand exp1 = $random; 
    rand_exp2 = $random;
    rand_mantissal = {$random, $random}; 
    rand_mantissa2 = {$random, $random};
    if (special_cnt == 0) // A is 0 
	    A = 64'do;
    else if(special_cnt == 1) // A is infinite 
	    A = {rand_sign1, 11'd2047, 52'de};
    else // A is NaN
	    A = {rand_sign1, 11'd2047, rand_mantissal}; 
            B = {rand_sign2, rand_exp2, rand_mantissa2};
    fp_special_patten;
    fp_check;
    repeat (2) @(negedge CLK); //wait 2 clock cycles
  end
end


if (err_count !=0)
begin
  $display("\n\n**********");
  $display ("Simulation Fail ");
  $display("**********\n\n");
end else begin
  $display("\n\n**********");
  $display ("Simulation OK ");
  $display("**********\n\n");
end
#10 $finish
end

task fp_patten;
  real A_real, B_real, C_real, D_real, E_real, F_real; 
  reg [7:0] IN_A [0:7];
  reg [7:0] IN_B [0:7];
  integer sim_time;
  integer i;
begin
  ENABLE=1'b0;
  DATA_IN=0;
  //Generate Random Input
  sim_time=$time;
  C_real=$random(sim_time);
  D_real=$random(sim_time);
  E_real=$random(sim_time);
  F_real=$random(sim_time);
  A_real=C_real/D_real; 
  B_real=E_real/F_real;
  A=$realtobits(A_real); 
  B=$realtobits (B_real);
  {IN_A[7], IN_A[6], IN_A[5], IN_A[4], IN_A[3], IN_A[2], IN_A[1], IN_A[0]}=A; 
  {IN_B[7], IN_B[6], IN_B[5], IN_B[4], IN_B[3], IN_B[2], IN_B[1], IN_B[0]}=B; 
  prod = A[51:0]*B[51:0];
  //Input Data to FP_MUL
  for(i=0; i<= 7; i=i+1) begin
    @(negedge CLK) begin
      ENABLE=1'b1;
      DATA_IN = IN_A[i];
    end
  end
  
  for(i=0; i <= 7; i=i+1) begin
    @(negedge CLK) begin
      ENABLE=1'b1;
      DATA_IN = IN_B[i];
    end
  end
  
  @(negedge CLK) ENABLE=1'b0;

end
endtask 


task fp_special_patten;
  real A_real, B_real, C_real, D_real, E_real, F_real;
  reg [7:0] IN_A [0:7];
  reg [7:0] IN_B [0:7];
  integer sim_time;
  integer i;
begin
  ENABLE=1'b0;
  DATA_IN=0;
  //Generate Random Input
  {IN_A[7], IN_A[6], IN_A[5], IN_A[4], IN_A[3], IN_A[2], IN_A[1],IN_A[0]} = A; 
  {IN_B[7], IN_B[6], IN_B[5], IN_B[4], IN_B[3], IN_B[2], IN_B[1], IN_B[0]} = B; 
  prod A[510]*B[51:0];
  //Input Data to FP_MUL
  for(i=0; i<= 7; i=i+1) begin
    @(negedge CLK) begin
      ENABLE=1'b1;
      DATA_IN = IN_A[i];
    end
  end
  
  for(i=0; i<= 7; i=i+1) begin
    @(negedge CLK) begin
      ENABLE=1'b1; 
      DATA_IN = IN_B[i];
    end
  end
  
  @(negedge CLK) ENABLE=1'b0;
end 
endtask


task fp_check;
  real checkA, checkB, checkZ;
  reg [7:0] IN_Z [0:7];
  integer i;
begin
//Get Data from FP MUL
  checkA = $bitstoreal (A);
  checkB $bitstoreal (B);
  checkZ = checkA checkB; //FP MUL
  C = $realtobits (checkZ); 
  tar_sign_C=C[63];
  tar_exp_C=C[62:52]; 
  tar_mantissa C = C[51:0];
  @(posedge READY) begin
    for(i=0; i<= 7; i=i+1) begin
      @(negedge CLK) IN_Z[i] = DATA_OUT;
    end
  end
  //Check Results
  Z = {IN_Z[7],IN_Z[6], IN_Z[5], IN_Z[4], IN_Z[3], IN_Z[2],IN_Z[1],IN_Z[0]};
  //Display Debug Information
  fp_show;
  if(C != Z) begin //If answer is wrong
    err_count = err_count + 1'b1;
    $display("Error at %t", $time);
  end
end
endtask


task fp_show; 
begin
  $display("\n");
  $display("************************************************************************");
  $display("(%+f) * (%+f) = %+f", $bitstoreal (A), $bitstoreal (B), $bitstoreal (Z)); 
  $display ("A=%b_b_%b", A[63], A[62:52], A[51:0]); 
  $display("B=%b_%b_%b", B[63], B[62:52], B[51:0]);
  $display("-------------------------Your Result------------------------------------");
  $display ("Z=%b_%b_%b", Z[63], Z[62:52], Z[51:0]);
  $display("-------------------------Correct Result------------------------------------");
  $display("C=%b_b_%b", C[63], C[62:52], C[51:0]);
  $display("************************************************************************");
end
endtask
