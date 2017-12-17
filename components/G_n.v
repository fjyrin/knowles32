/* 
    File: G_n.v
    Author: Christian Gobrecht

    Description: 
        Structural model of Group Propagate/Generate CLA cell.
        Uses CMOS optimizations (NAND, NOR, XOR, XNOR, AOI, OAI only).
        Takes noninverted P,G signals from constituent groups,
        Outputs inverted P,G signals of combined group.
        Intended for educational purposes.

    Input: NON-INVERTED signals for:
        Upper-group Propagate (Pu),
        Upper-group Generate (Gu),
        Lower-group Generate (Gl)

    Output: INVERTED signals for:
        Combined Generate (Gc_n)
*/
`include "./components/aoi.v"

`ifndef MODULE_G_n
`define MODULE_G_n

module G_n (
    output Gc_n,
    input Pu, Gu, Gl
    );


    // Generate (Gc) if: Lower Generate (Gl) AND Upper Propagate (Pu)
    //                                       OR Upper Generate (Gu)
    aoi group_generate (
        .O(Gc_n),
        .A(Gl),
        .B(Pu),
        .C(Gu)
        );

endmodule // G_n

`endif