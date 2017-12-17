`ifndef MODULE_oai
`define MODULE_oai

module oai (
    output O,
    input A, B, C
    );

    assign O = C ~& (A | B);

endmodule // OAI

`endif