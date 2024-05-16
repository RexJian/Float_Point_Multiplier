# Float_Point_Multiplier
Design a pipeline multiplier for floating-point numbers and complete the APR, passing the Calibre DRC/LVS checks. Additionally, ensure there are no timing violations in the post-layout gate-level simulation. The timing constraint of the circuit is <strong>0.3 ns</strong>, so for the most time-consuming part, which involves multiplying two 53-bit numbers, use the ChipWare component IP. This component divides the multiplication process into several cycles. Finally, I applied power optimization methods to reduce power consumption from<strong> 10.8 mW to 9.17 mW.</strong>

## State Machine
<p align="center">
  <img src="https://github.com/RexJian/Float_Point_Multiplier/blob/main/Image/state_machine.png" width="800" height="450" alt="Architecture">
</p> 
<strong>INIT</strong>strong>: All variables are initialized. If RESET is asserted or ENABLE becomes 0, the state will be maintained.  
<br><br>
<strong>READ</strong>: Read the two numbers of multiplier when the ENABLE signal is asserted.
<br><br>
<strong>CAL</strong>: Multiply the two numbers, A and B. In the project, I applied the ChipWare IP component for this step because it can divide the multiplication process into my assigned cycles, which helps prevent exceeding the timing constraints.  
<br><br>
<strong>EXPORT</strong>: Export the product of A multiplied by B, which will retain 8 cycles.  
<br><br>
Based on IEEE 754 standard, the double precision are stored in 64 bits: 1 for the sign, 11 for the exponential, and 52 for the fraction. An exponent is an unsigned number represented using the bias method with a bias of 1023. The fraction represents a number less than 1,  
