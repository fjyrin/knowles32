/* 
    File: knowles32_testbench.v
    Author: Christian Gobrecht

    Description: 
        Verilog testbench for 32-bit Knowles adder.
        Intended for educational purposes.
*/

`include "knowles32.v"

module knowles32_testbench();
    integer SEED = 255;
    parameter TRIALS = 100000;
    parameter arbitrary_delay = 10;

    // Generated inputs
    reg [31:0] A, B;
    reg Ci;

    // Received outputs
    wire [31:0] S;
    wire Co;
    
    // Auto-test values
    wire [31:0] S_exp = A + B + Ci;
    wire Co_exp = (S < A) | (S < B);
    wire success;
    

    // Monitor response
    initial begin
        $dumpfile("knowles32.vcd");
        $dumpvars(0,knowles32_testbench);  
        $display("success\tout\t\texpect\t\tCo\texpect\t\tTime");
        $monitor("%b\t%d\t%d\t%d\t%d%d", success, S_exp, S, Co_exp, Co, $time);
    end 
        
    // Instantiate device under test
    knowles32 dut (.A(A), .B(B), .Ci(Ci), .S(S), .Co(Co));

    // Stop if there is unexpected output
    assign success = (S_exp == S) && (Co == Co_exp);
    always #arbitrary_delay begin
        if (~success)
            $stop;
    end
    
    // Testing procedure
    integer i;
    initial begin          
        for (i = 0; i <= TRIALS; i = i + 1) begin
            Ci = $random(SEED);
            A = $random(SEED);
            B = $random(SEED);
            #arbitrary_delay;
        end
                  
        $finish;
    end
endmodule
