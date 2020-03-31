`timescale 1ns / 10ps
module div(out, in1, in2, dbz);

parameter width = 8;
integer i;

input [width-1:0] in1; // Dividend
input [width-1:0] in2; // Divisor

output reg [width-1:0] out; // Quotient
output reg dbz;

reg [15:0] remainder; 
reg [15:0] divisor;



always@(*) begin
    if(in2 == 8'd0) begin
        dbz = 1; 
    end
    else begin
        dbz = 0;
        remainder = {8'd0, in1};
        divisor = {in2, 8'd0};
        for(i = 0; i <= width; i = i+1) begin
            if(remainder >= divisor) begin
                remainder = remainder - divisor;
                divisor = divisor >> 1;
                out = out << 1;
                out[0] = 1;
            end
            else begin
                divisor = divisor >> 1;
                out = out << 1;
                out[0] = 0;
            end
        end
    end
end



endmodule