/* 
    File: n_G.v
    Author: Christian Gobrecht

    Description: 
        Structural model of Group Generate CLA cell.
        Uses CMOS optimizations (NAND, NOR, XOR, XNOR, AOI, OAI only).
        Takes inverted P,G signals from constituent groups,
        Outputs noninverted G signal of combined group.
        Intended for educational purposes.

    Input: INVERTED signals for:
        Upper-group Propagate (n_Pu),
        Upper-group Generate (n_Gu),
        Lower-group Generate (n_Gl)

    Output: NON-INVERTED signals for:
        combined Generate (Gc)
*/
`include "./components/oai.v"

`ifndef MODULE_n_G
`define MODULE_n_G

module n_G (
    output Gc,
    input n_Pu, n_Gu, n_Gl
    );

    // Generate (Gc) if: Lower Generate (Gl) AND Upper Propagate (Pu)
    //                                       OR Upper Generate (Gu)
    //
    // DeMorgan's: Gc = (~Gu) ~& ((~Pu) | (~Gl))
    oai group_generate (
        .O(Gc),
        .A(n_Gl),
        .B(n_Pu),
        .C(n_Gu)
        );

endmodule // n_G

`endif