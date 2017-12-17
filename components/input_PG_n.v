/* 
    File: input_PG_n.v
    Author: Christian Gobrecht

    Description: 
        Structural model of input Propagate/Generate CLA cell.
        Uses CMOS optimizations (NAND, NOR, XOR, XNOR, AOI, OAI only).
        Takes noninverted A,B adder bit inputs,
        Outputs inverted P,G signals of that bit.
        Intended for educational purposes.

    Input: NON-INVERTED signals for:
        Bit of first addend (A),
        Bit of second addend (B)

    Output: INVERTED signals for:
        Bitwise Propagate (P_n),
        Bitwise Generate (G_n)
*/

`ifndef MODULE_input_PG_n
`define MODULE_input_PG_n

module input_PG_n (
    output P_n, G_n,
    input A, B
    );

    nand inverted_generate (G_n, A, B);

    // "xnor" is used here rather than "or" so that 
    // the final sum may be computed with this output once the carry is known:
    // Sum = (A ~^ B) ~^ Cin
    xnor inverted_propagate (P_n, A, B);     

endmodule // input_PG_n

`endif