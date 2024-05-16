# Float_Point_Multiplier
Design a pipeline multiplier for floating-point numbers and <strong>complete the APR, passing the Calibre DRC/LVS checks. Additionally, ensure there are no timing violations in the post-layout gate-level simulation</strong>. The timing constraint of the circuit is <strong>0.3 ns</strong>, so for the most time-consuming part, which involves multiplying two 53-bit numbers, use the ChipWare component IP. This component divides the multiplication process into several cycles. Finally, I applied power optimization methods to reduce power consumption from<strong> 10.8 mW to 9.17 mW.</strong>

## Table of Content
- [IEEE 754 Double Precision](#ieee-754-double-precision)
- [Specification](#specification)
- [State Machine](#state-machine)
- [Simulate Waveform](#simulate-waveform)
- [APR Result](#apr-result)

## IEEE 754 Double Precision
Based on the IEEE 754 standard, double precision numbers are stored in 64 bits: 1 for the sign, 11 for the exponent, and 52 for the fraction. The exponent is an unsigned number represented using the bias method with a bias of 1023. The fraction represents a number less than 1. Additionally, when the biased exponent is 2047, all fraction bits are zero, representing infinity, and when the biased exponent is 2047 with a nonzero fraction part, it represents NaN (Not a Number). When both the biased exponent and the fraction part are 0, the extracted number is 0. The architecture of IEEE 754 double precision is depicted in the image below. I tested all cases of my circuit, including NaN, zero, or infinity, to ensure that my designed circuit can work correctly in most scenarios.
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/IEEE754_double.jpg" width="800" height="250" alt="Architecture">
</p> 

## Specification

| Signal Name | I/O | Width | Sample Description |
| :----: | :----: | :----: | :----|
| CLK | I | 1 | Clock Signal |
| RESET | I | 1 | Reset signal |
| ENABLE | O | 1 | It represents the DATA_IN signal is valid. |
| DATA_IN | O | 8 | Part of the number of multiplier because it has 2 number it take 16 cycles. |
| READY | O | 1 | It represent the DATA_OUT signal is valid. |
| DATA_OUT | O | 8 | Part of the product, lower bytes are inputted first. It takes 8 cycles. |

## State Machine
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/state_machine.png" width="800" height="350" alt="Architecture">
</p> 
<strong>INIT</strong>strong>: All variables are initialized. If RESET is asserted or ENABLE becomes 0, the state will be maintained.  
<br><br>
<strong>READ</strong>: Read the two numbers of multiplier when the ENABLE signal is asserted.
<br><br>
<strong>CAL</strong>: Multiply the two numbers, A and B. In the project, I applied the ChipWare IP component for this step because it can divide the multiplication process into my assigned cycles, which helps prevent exceeding the timing constraints.  
<br><br>
<strong>EXPORT</strong>: Export the product of A multiplied by B, which will retain 8 cycles.  
<br><br>

## Simulate Waveform
1. When the ENABLE signal is asserted, the circuit reads the data for 16 cycles. The first 8 cycles represent the value of A, while the last 8 cycles represent the value of B.
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/Wave/Wave1.png" width="900" height="200" alt="Architecture">
</p> 
2. After reading the data, it will calculate the result of A multiplied B. The latency is 59 cycles.
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/Wave/wave2.png" width="900" height="200" alt="Architecture">
</p> 

3. After calculating the product of A and B, export the results.
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/Wave/wave3.png" width="900" height="200" alt="Architecture">
</p> 

## APR Result
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/APR_Result.png" width="450" height="450" alt="Architecture">
</p> 
