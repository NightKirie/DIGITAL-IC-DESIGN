module AS(sel, A, B, S, O);

input [3:0] A, B;
input sel;

output [3:0] S;
output O;

wire B_xor_sel[3:0], A_xor_B[3:0], C[3:0];

xor (B_xor_sel[0], B[0], sel);
xor (B_xor_sel[1], B[1], sel);
xor (B_xor_sel[2], B[2], sel);
xor (B_xor_sel[3], B[3], sel);

xor (A_xor_B[0], A[0], B_xor_sel[0]);
xor (A_xor_B[1], A[1], B_xor_sel[1]);
xor (A_xor_B[2], A[2], B_xor_sel[2]);
xor (A_xor_B[3], A[3], B_xor_sel[3]);

assign S[0] = (A_xor_B[0] ^ sel);
assign C[0] = (sel & A_xor_B[0]) | (A[0] & B_xor_sel[0]);
assign S[1] = (A_xor_B[1] ^ C[0]);
assign C[1] = (C[0] & A_xor_B[1]) | (A[1] & B_xor_sel[1]);
assign S[2] = (A_xor_B[2] ^ C[1]);
assign C[2] = (C[1] & A_xor_B[2]) | (A[2] & B_xor_sel[2]);
assign S[3] = (A_xor_B[3] ^ C[2]);
assign C[3] = (C[2] & A_xor_B[3]) | (A[3] & B_xor_sel[3]);

assign O = C[2] ^ C[3];

endmodule


