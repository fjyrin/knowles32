/* 
    File: knowles32.v
    Author: Christian Gobrecht

    Description: 
        Structural model of 32-bit, radix-2 Knowles CLA.
        Configurable Knowles grouping at each processing stage.
        Uses CMOS optimizations (AOI/OAI whenever possible, no AND/OR).
        Intended for educational purposes (hence the very verbose documentation)

    Input: 
        First addend (A),
        Second addend (B),
        Carry-in (Ci)

    Output: 
        Sum (S),
        Carry-out (Co)
*/

`include "./components/input_PG_n.v"
`include "./components/PG_n.v"
`include "./components/G_n.v"
`include "./components/n_PG.v"
`include "./components/n_G.v"

`ifndef MODULE_knowles32
`define MODULE_knowles32


//   ____                                              _                       
//  |  _ \    __ _   _ __    __ _   _ __ ___     ___  | |_    ___   _ __   ___ 
//  | |_) |  / _` | | '__|  / _` | | '_ ` _ \   / _ \ | __|  / _ \ | '__| / __|
//  |  __/  | (_| | | |    | (_| | | | | | | | |  __/ | |_  |  __/ | |    \__ \
//  |_|      \__,_| |_|     \__,_| |_| |_| |_|  \___|  \__|  \___| |_|    |___/
//
// These parameters control the Knowles grouping (fanout) of each stage.
// ORing a generating index with a 2^n-1 is a simple means of grouping indexes.
// For the parameters below, only enter a group size (2^n), as the -1 is 
// accounted for in the module implementation. 
//
// Example: 4'd7 = 4'b0111. For indexes 15-8, ORing with this mask produces 15.
// This is a convenient means of making a group of indexes act the same as their
// highest index, which is perfect for Knowles adders--afterwards, all that's 
// left is to subtract the previous group size to find the correct index of
// the lower combined group. 
//
// The maximum knowles group size (fanout) is limited by the size of groups 
// formed in the previous stage. Exceeding this will cause bits to be skipped.
// 
// Additionally, the fanout of an earlier stage CAN NOT exceed the fanout of a
// later stage. This will also cause bits to be skipped.
//
// Summary: Parameters are stage fanouts (2^n) not exceeding the current group
// size OR any later stage's fanout.

module knowles32 
    #(  // Parameters: Stage fanouts: 2^n; Max >= 2^n > 0.
    parameter [31:0] KNOWLES_S2 = 2, // Max: 2
    parameter [31:0] KNOWLES_S3 = 4, // Max: 4
    parameter [31:0] KNOWLES_S4 = 8, // Max: 8
    parameter [31:0] KNOWLES_S5 = 16  // Max: 16
    )
    (   // Ports
    output Co,
    output [32:1] S,    // These are all 1-indexed because carry-in is treated
    input [32:1] A,     // as index 0. Describing the carry-in of adders like
    input [32:1] B,     // this unifies many mathematical relationships and
    input Ci            // allows for more meaningful descriptions.
    );

    genvar i;

    //    ____    _                                 ___  
    //   / ___|  | |_    __ _    __ _    ___       / _ \ 
    //   \___ \  | __|  / _` |  / _` |  / _ \     | | | |
    //    ___) | | |_  | (_| | | (_| | |  __/     | |_| |
    //   |____/   \__|  \__,_|  \__, |  \___|      \___/ 
    //                          |___/                    
    //                        
    //  Stage 0, forming groups of 1.
    //      Inverting half-adders output (inverted) bitwise P,G signals.
    //      
    wire [32:1] s0_P_n;
    wire [32:0] s0_G_n;

    generate
        for (i = 32; i > 0; i=i-1) begin : s0_unknown
            input_PG_n s0u (
                .P_n(s0_P_n[i]),
                .G_n(s0_G_n[i]),
                .A(A[i]),
                .B(B[i])
            );
        end
    endgenerate

    not (s0_G_n[0], Ci);
    // Known C: [0] (Ci)
    // End of Stage 0. 




    //    ____    _                                _ 
    //   / ___|  | |_    __ _    __ _    ___      / |
    //   \___ \  | __|  / _` |  / _` |  / _ \     | |
    //    ___) | | |_  | (_| | | (_| | |  __/     | |
    //   |____/   \__|  \__,_|  \__, |  \___|     |_|
    //                          |___/                
    //
    //  Stage 1, forming groups of 2.
    //      Inverted bitwise signals become noninverted group-of-2 signals.
            localparam S0_KNOWN = 0;
            localparam S0_GROUP_SIZE = 1;
    //      
    wire [31:1] s1_P;
    wire [31:0] s1_G;

    generate
        // Ignoring bit 32 from now on -- it will be its own group of 1,
        // so group-combining is unnecessary until it can be grouped with 31:0
        for (i = 31; i > S0_KNOWN + S0_GROUP_SIZE; i=i-1) begin: s1_unknown
            n_PG s1u (
                .Pc(s1_P[i]),
                .Gc(s1_G[i]),
                .n_Pu(s0_P_n[i]),
                .n_Gu(s0_G_n[i]),
                .n_Pl(s0_P_n[(i-1)]),
                .n_Gl(s0_G_n[(i-1)])
            );
        end
    endgenerate

    // Propagate signal is extraneous for groups with known carry-out
    generate 
        for (i = S0_KNOWN + S0_GROUP_SIZE; i > S0_KNOWN; i=i-1) begin : s1_known
            n_G s1k (
                .Gc(s1_G[i]),
                .n_Pu(s0_P_n[i]),
                .n_Gu(s0_G_n[i]),
                .n_Gl(s0_G_n[(i-1)])
            );
        end
    endgenerate

    // Invert previously-known group carry-out for access by next stage
    not (s1_G[0], s0_G_n[0]);

    // Known C: [1:0]
    // End of Stage 1.
    



    //    ____    _                                ____  
    //   / ___|  | |_    __ _    __ _    ___      |___ \ 
    //   \___ \  | __|  / _` |  / _` |  / _ \       __) |
    //    ___) | | |_  | (_| | | (_| | |  __/      / __/ 
    //   |____/   \__|  \__,_|  \__, |  \___|     |_____|
    //                          |___/                    
    //
    // Stage 2, combining groups of 2: 
    //      Noninverted group-of-2 signals become inverted group-of-4 signals
            localparam S1_KNOWN = 1;
            localparam S1_GROUP_SIZE = 2;
    //
    wire [31:1] s2_P_n;
    wire [31:0] s2_G_n;

    generate
        for (i = 31; i > S1_KNOWN + S1_GROUP_SIZE; i=i-1) begin : s2_unknown
            PG_n s2u (
                .Pc_n(s2_P_n[i]),
                .Gc_n(s2_G_n[i]),
                .Pu(s1_P[i]),
                .Gu(s1_G[i]),
                .Pl(s1_P[(i | KNOWLES_S2-1) - S1_GROUP_SIZE]),
                .Gl(s1_G[(i | KNOWLES_S2-1) - S1_GROUP_SIZE])
                );
        end
    endgenerate    

    // Propagate signal is extraneous for groups with known carry-out
    generate
        for (i = S1_KNOWN + S1_GROUP_SIZE; i > S1_KNOWN; i=i-1) begin : s2_known
            G_n s2k (
                .Gc_n(s2_G_n[i]),
                .Pu(s1_P[i]),
                .Gu(s1_G[i]),
                .Gl(s1_G[(i | KNOWLES_S2-1) - S1_GROUP_SIZE])
                );
        end
    endgenerate

    // Invert previously-known group carry-out for access by next stage
    generate
        for (i = S1_KNOWN; i >= 0; i=i-1) begin : s2_prev_known
            not s2pk (s2_G_n[i], s1_G[i]);
        end
    endgenerate
    // Known C: [3:0]
    // End of Stage 2.




    //    ____    _                                _____ 
    //   / ___|  | |_    __ _    __ _    ___      |___ / 
    //   \___ \  | __|  / _` |  / _` |  / _ \       |_ \ 
    //    ___) | | |_  | (_| | | (_| | |  __/      ___) |
    //   |____/   \__|  \__,_|  \__, |  \___|     |____/ 
    //                          |___/                    
    //
    // Stage 3, combining groups of 4:
    //      Inverted group-of-4 signals become noninverted group-of-8 signals
            localparam S2_KNOWN = 3;
            localparam S2_GROUP_SIZE = 4;
    //
    wire [31:1] s3_P;
    wire [31:0] s3_G;

    generate
        for (i = 31; i > S2_KNOWN + S2_GROUP_SIZE; i=i-1) begin : s3_unknown
            n_PG s3u (
                .Pc(s3_P[i]),
                .Gc(s3_G[i]),
                .n_Pu(s2_P_n[i]),
                .n_Gu(s2_G_n[i]),
                .n_Pl(s2_P_n[(i | KNOWLES_S3-1) - S2_GROUP_SIZE]),
                .n_Gl(s2_G_n[(i | KNOWLES_S3-1) - S2_GROUP_SIZE])
                );
        end
    endgenerate

    // Propagate signal is extraneous for groups with known carry-out
    generate
        for (i = S2_KNOWN + S2_GROUP_SIZE; i > S2_KNOWN; i=i-1) begin : s3_known
            n_G s3k (
                .Gc(s3_G[i]),
                .n_Pu(s2_P_n[i]),
                .n_Gu(s2_G_n[i]),
                .n_Gl(s2_G_n[(i | KNOWLES_S3-1) - S2_GROUP_SIZE])
                );
        end
    endgenerate

    // Invert previously-known group carry-out for access by next stage
    generate 
        for (i = S2_KNOWN; i >= 0; i=i-1) begin : s3_prev_known
            not s3pk (s3_G[i], s2_G_n[i]);
        end
    endgenerate
    // Known C: [7:0]
    // End of Stage 3.




    //    ____    _                                _  _   
    //   / ___|  | |_    __ _    __ _    ___      | || |  
    //   \___ \  | __|  / _` |  / _` |  / _ \     | || |_ 
    //    ___) | | |_  | (_| | | (_| | |  __/     |__   _|
    //   |____/   \__|  \__,_|  \__, |  \___|        |_|  
    //                          |___/                     
    //
    // Stage 4, combining groups of 8:
    //      Noninverted group-of-8 signals become inverted group-of-16 signals
            localparam S3_KNOWN = 7;
            localparam S3_GROUP_SIZE = 8;
    //
    wire [31:1] s4_P_n;
    wire [31:0] s4_G_n;

    generate
        for (i = 31; i > S3_KNOWN + S3_GROUP_SIZE; i=i-1) begin : s4_unknown
            PG_n s4u (
                .Pc_n(s4_P_n[i]),
                .Gc_n(s4_G_n[i]),
                .Pu(s3_P[i]),
                .Gu(s3_G[i]),
                .Pl(s3_P[(i | KNOWLES_S4-1) - S3_GROUP_SIZE]),
                .Gl(s3_G[(i | KNOWLES_S4-1) - S3_GROUP_SIZE])
                );
        end
    endgenerate

    // Propagate signal is extraneous for groups with known carry-out
    generate
        for (i = S3_KNOWN + S3_GROUP_SIZE; i > S3_KNOWN; i=i-1) begin : s4_known
            G_n s4k (
                .Gc_n(s4_G_n[i]),
                .Pu(s3_P[i]),
                .Gu(s3_G[i]),
                .Gl(s3_G[(i | KNOWLES_S4-1) - S3_GROUP_SIZE])
                );
        end
    endgenerate

    // Invert previously-known group carry-out for access by next stage
    generate 
        for (i = S3_KNOWN; i >= 0; i=i-1) begin : s4_prev_known
            not s4pk (s4_G_n[i], s3_G[i]);
        end
    endgenerate
    // Known C: [15:0]
    // End of Stage 4.




    //    ____    _                                ____  
    //   / ___|  | |_    __ _    __ _    ___      | ___| 
    //   \___ \  | __|  / _` |  / _` |  / _ \     |___ \ 
    //    ___) | | |_  | (_| | | (_| | |  __/      ___) |
    //   |____/   \__|  \__,_|  \__, |  \___|     |____/ 
    //                          |___/                    
    //
    // Stage 5, combining groups of 16:
    //      Inverted group-of-16 signals become noninverted group-of-32 signals
            localparam S4_KNOWN = 15;
            localparam S4_GROUP_SIZE = 16;
    //
    wire [31:1] s5_P;
    wire [31:0] s5_G;

    generate
        for (i = 31; i > S4_KNOWN + S4_GROUP_SIZE; i=i-1) begin : s5_unknown
            n_PG s5u (
                .Pc(s5_P[i]),
                .Gc(s5_G[i]),
                .n_Pu(s4_P_n[i]),
                .n_Gu(s4_G_n[i]),
                .n_Pl(s4_P_n[(i | KNOWLES_S5-1) - S4_GROUP_SIZE]),
                .n_Gl(s4_G_n[(i | KNOWLES_S5-1) - S4_GROUP_SIZE])
                );
        end
    endgenerate

    // Propagate signal is extraneous for groups with known carry-out
    generate
        for (i = S4_KNOWN + S4_GROUP_SIZE; i > S4_KNOWN; i=i-1) begin : s5_known
            n_G s5k (
                .Gc(s5_G[i]),
                .n_Pu(s4_P_n[i]),
                .n_Gu(s4_G_n[i]),
                .n_Gl(s4_G_n[(i | KNOWLES_S5-1) - S4_GROUP_SIZE])
                );
        end
    endgenerate

    // Invert previously-known group carry-out for access by next stage
    generate 
        for (i = S4_KNOWN; i >= 0; i=i-1) begin : s5_prev_known
            not s5pk (s5_G[i], s4_G_n[i]);
        end
    endgenerate    
    // Known C: [31:0]
    // End of Stage 5.




    //     ___            _                     _   
    //    / _ \   _   _  | |_   _ __    _   _  | |_ 
    //   | | | | | | | | | __| | '_ \  | | | | | __|
    //   | |_| | | |_| | | |_  | |_) | | |_| | | |_ 
    //    \___/   \__,_|  \__| | .__/   \__,_|  \__|
    //                         |_|                  
    //
    // Final Carry-out and Sum for all bits can now be determined.
    // 

    // Because we chose P = A ^ B instead of P = A | B, we can get 
    // S = A ^ B ^ Cin from our ~P by a simple XNOR with previous bit's carry
    generate
        for (i = 32; i > 0; i=i-1) begin : output_sum
            xnor sum (S[i], s0_P_n[i], s5_G[i-1]);
        end
    endgenerate

    // Because we used an odd number of processing stages, our latest carry
    // signals are noninverted. We could use an OAI to easily combine bit 32
    // with bits 31:0 to get a final carry-out, but only if we first invert
    // group 31:0's generate signal. From a hardware performance perspective,
    // this will add to the critical path if the resulting NOT -> OAI takes 
    // longer than the XNORs used to compute the sum, but this is largely 
    // unavoidable. Flipping the polarity of all intermediate stages of the
    // adder would mean that bit 16's P,G signals could be inverted instead
    // during the earlier stages, but this would require that we use AND gates
    // instead of NAND during stage 0, or that the adder receives inverted
    // A and B inputs initially. This consideration would not be necessary for
    // a 16-bit or 64-bit adder of radix 2 because the final Group Generate 
    // signals would already be inverted.
    //
    // Here, Group [31:0]'s G signal is simply inverted prior to use.
    wire inverted_31_0_G;
    not (inverted_31_0_G, s5_G[31]);
    n_G carry_out (
        .Gc(Co),
        .n_Pu(s0_P_n[32]),
        .n_Gu(s0_G_n[32]),
        .n_Gl(inverted_31_0_G)
        );

endmodule // knowles32

`endif