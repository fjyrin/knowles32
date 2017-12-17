/* 
    File: n_PG.v
    Author: Christian Gobrecht

    Description: 
        Structural model of Group Propagate/Generate CLA cell.
        Uses CMOS optimizations (NAND, NOR, XOR, XNOR, AOI, OAI only).
        Takes inverted P,G signals from constituent groups,
        Outputs noninverted P,G signals of combined group.
        Intended for educational purposes.

    Input: INVERTED signals for:
        Upper-group Propagate (n_Pu),
        Upper-group Generate (n_Gu),
        Lower-group Propagate (n_Pl),
        Lower-group Generate (n_Gl)

    Output: NON-INVERTED signals for:
        Combined Propagate (Pc),
        Combined Generate (Gc)
*/
`include "./components/oai.v"

`ifndef MODULE_n_PG
`define MODULE_n_PG

module n_PG (
    output Pc, Gc,
    input n_Pu, n_Gu, n_Pl, n_Gl
    );

    // Propagate (Pc) if: Upper Propagate (Pu) AND Lower Propagate (Pl)
    // DeMorgan's: Pc = (~Pu) ~| (~Pl) 
    nor group_propagate (Pc, n_Pu, n_Pl); 


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

endmodule // n_PG

`endif