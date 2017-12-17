`ifndef MODULE_aoi
`define MODULE_aoi

module aoi (
    output O, 
    input A, B, C
    );

    assign O = C ~| (A & B);

endmodule // AOI

`endif