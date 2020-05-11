`timescale 1ns/10ps
`define CYCLE      25.0  
`define End_CYCLE  1000000
`define PAT        "testdata.txt"
module testfixture();

integer linedata;
integer char_count;
string data;
string strdata;
string gold_offset_str;
string gold_match_len_str;
string gold_char_nxt_str;

// ====================================================================
// I/O Pins                                                          //
// ====================================================================
reg clk = 0;
reg reset = 0;
reg code_valid = 0;
reg [3:0] code_pos;
reg [3:0] code_len;
reg [7:0] chardata;
wire valid;
wire encode;
wire busy;
wire [3:0] offset;
wire [3:0] match_len;
wire [7:0] char_nxt;

LZE u_LZE (.clk(clk),
           .reset(reset),
           .code_valid(code_valid),
           .code_pos(code_pos),
           .code_len(code_len),
           .chardata(chardata),
           .valid(valid),
           .encode(encode),
           .busy(busy),
           .offset(offset),
           .match_len(match_len),
           .char_nxt(char_nxt));


// ====================================================================
// Initialize                                                        //
// ====================================================================
always begin #(`CYCLE/2) clk = ~clk; end

initial
begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk); #1; reset = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk); #1;   reset = 1'b0;
end

initial
begin
    linedata = $fopen(`PAT,"r");
    if(linedata == 0)
    begin
        $display ("pattern handle null");
        $finish;
    end
end


// ====================================================================
// Handle end-cycle exceeding situation                              //
// ====================================================================
reg [22:0] cycle=0;

always@(posedge clk)
begin
    cycle=cycle+1;
    if (cycle > `End_CYCLE)
    begin
        $display("--------------------------------------------------");
        $display("-- Failed waiting valid signal, Simulation STOP --");
        $display("--------------------------------------------------");
        $fclose(linedata);
        $finish;
    end
end


// ====================================================================
// Check if answers correct                                          //
// ====================================================================
integer strindex;
integer decode_num;
integer encode_cnt;
integer decode_cnt;
reg [3:0] gold_offset;
reg [3:0] gold_match_len;
reg [7:0] gold_char_nxt;
reg encode_reg;
reg wait_valid;
reg [3:0] get_offset;
reg [3:0] get_match_len;
reg [7:0] get_char_nxt;
reg [3:0] buff_offset[0:15];
reg [3:0] buff_match_len[0:15];
reg [7:0] buff_char_nxt[0:15];

integer allpass=1;
always@(negedge clk)
begin

    if(reset)
        wait_valid=0;
    else
    begin

        if(wait_valid && valid)
        begin

            if(encode_reg) // Check encoding answer
            begin

                wait_valid = 0;
                get_offset = offset;
                get_match_len = match_len;
                get_char_nxt = char_nxt;

                buff_offset[encode_cnt] = offset;
                buff_match_len[encode_cnt] = match_len;
                buff_char_nxt[encode_cnt] = char_nxt;
                encode_cnt = encode_cnt + 1;

                if (!encode)
                begin
                    allpass = 0;
                    $display("cycle %2h, expect encoding, but encode signal is low >> Fail",cycle);
                end
                else if ((get_offset === gold_offset) && (get_match_len === gold_match_len) && (get_char_nxt === gold_char_nxt))
                    $display("cycle %2h, expect(%h,%h,%c) , get(%h,%h,%c) >> Pass",cycle,gold_offset,gold_match_len,gold_char_nxt,get_offset,get_match_len,get_char_nxt);
                else
                begin
                    allpass = 0;
                    $display("cycle %2h, expect(%h,%h,%c) , get(%h,%h,%c) >> Fail",cycle,gold_offset,gold_match_len,gold_char_nxt,get_offset,get_match_len,get_char_nxt);
                end

            end
            else // Check decoding answer
            begin
                
                code_valid = 0;
                decode_num = decode_num + 1;
                if(decode_num == strdata.len())
                    wait_valid = 0;

                get_char_nxt = char_nxt;
                if (encode)
                begin
                    allpass = 0;
                    $display("cycle %2h, expect decoding, but encode signal is high >> Fail",cycle);
                end
                else if(get_char_nxt !== gold_char_nxt)
                begin
                    allpass = 0;
                    $display("cycle %2h, failed to decode %s, expect %c, get %c >> Fail",cycle,strdata,gold_char_nxt,get_char_nxt);
                end
                else
                   $display("cycle %2h, expect %c, get %c >> Pass",cycle,gold_char_nxt,get_char_nxt); 

                strindex = strindex + 1;
                gold_char_nxt = strdata.getc(strindex);

            end

        end

    end

end


// ====================================================================
// Read input string                                                 //
// ====================================================================
always @(negedge clk ) begin
    if (reset) begin
        encode_reg = 1;
    end 
    else begin

        if (!wait_valid)
        begin

            if (strindex < strdata.len() - 1)
            begin
                strindex = strindex + 1;
                chardata = strdata.getc(strindex);
            end 
            else
            begin
                if (!$feof(linedata))
                begin

                    if (((decode_cnt != encode_cnt) && !((decode_cnt == encode_cnt - 1) && (buff_match_len[encode_cnt - 1] == 0) && (buff_char_nxt[encode_cnt - 1] == 8'h45))) || !busy)
                    begin
                        code_valid = 1;
                        char_count = $fgets(data, linedata);
                    end
                    else if ((decode_cnt == encode_cnt - 1) && (buff_match_len[encode_cnt - 1] == 0) && (buff_char_nxt[encode_cnt - 1] == 8'h45))
                    begin
                        code_valid = 1;
                        code_pos = 4'd0;
                        code_len = 4'd0;
                        chardata = 8'h45;
                        decode_cnt = decode_cnt + 1;
                        char_count = 0;
                    end
                    else
                    begin
                        code_valid = 0;
                        char_count = 0;
                    end

                    if (char_count !== 0)
                    begin

                        if(data.substr(0,6) == "string:")
                        begin
                            code_valid = 1;
                            strindex = 0;
                            encode_cnt = 0;
                            decode_cnt = 0;
                            strdata = data.substr(7,data.len() - 2);
                            $display("  __________________________________________________________");
                            $display("  == Encoding string \"%s\"", strdata);
                            chardata = strdata.getc(strindex);
                        end 
                        else if (data.substr(0,6) == "encode:")
                        begin
                            wait_valid = 1;
                            code_valid = 0;
                            encode_reg = 1;
                            chardata = 8'h45; // String ending character
                            gold_offset = data.substr(7,7).atoi();
                            gold_match_len = data.substr(9,9).atoi();
                            gold_char_nxt = data.getc(11);
                        end
                        else if (data.substr(0,6) == "decode:")
                        begin
                            wait_valid = 1;
                            encode_reg = 0;
                            strindex = 0;
                            decode_num = 0;
                            strdata = data.substr(7,data.len() - 2);
                            gold_char_nxt = strdata.getc(strindex);

                            code_valid = 1;
                            code_pos = buff_offset[decode_cnt];
                            code_len = buff_match_len[decode_cnt];
                            chardata = buff_char_nxt[decode_cnt];
                            decode_cnt = decode_cnt + 1;
                            $display("  == Decoding string \"%s\"", strdata);
                        end

                    end

                end
                else
                begin
                    $display("----------------------------------");
                    if(allpass == 1)
                    $display("-- Simulation finish, ALL PASS  --");
                    else
                    $display("-- Simulation finish            --");
                    $display("----------------------------------");
                    $fclose(linedata);
                    $finish;
                end

            end

        end

    end
end

endmodule

