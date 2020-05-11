module LZE(clk,reset,code_valid,code_pos,code_len,chardata,valid,encode,busy,offset,match_len,char_nxt);

input clk;
input reset;
input code_valid;
input [3:0] code_pos;
input [3:0] code_len;   
input [7:0] chardata;

output reg valid;
output reg encode;
output reg busy;
output reg [3:0] offset;
output reg [3:0] match_len;
output reg [7:0] char_nxt;

reg [7:0] code_buff[0:29];
reg [4:0] code_buff_len, code_buff_idx;
reg [3:0] search_buff_len;
reg [4:0] search_buff_idx;
reg [4:0] look_ahead_buff_idx;
reg [3:0] pointer;
reg [3:0] max_offset, temp_offset;
reg [3:0] max_match_len, temp_match_len;
reg [7:0] max_char_nxt, temp_char_nxt;
reg [3:0] curr_state, next_state;
reg last_decode;

parameter LOAD_ENCODE = 4'd0;
parameter COMPARE_SUBSTRING = 4'd1;
parameter CHANGE_SUBSTRING = 4'd2;
parameter ENCODE = 4'd3;
parameter LOAD_DECODE = 4'd4;
parameter COPY_STR = 4'd5;
parameter DECODE = 4'd6;
parameter PRE_LOAD_ENCODE = 4'd7;

parameter max_look_ahead_buff_len = 8;
parameter max_search_buff_len = 9;

always @(posedge clk, posedge reset) begin
    if(reset) begin
        valid <= 0;
        encode <= 0;
        busy <= 0;
        offset <= 0;
        match_len <= 0;
        char_nxt <= 0;
        
        code_buff_len <= 0;
        code_buff_idx <= 0;
        search_buff_idx <= 0;
        search_buff_len <= 0;
        look_ahead_buff_idx <= 0;
        pointer <= 0;
        max_match_len <= 0;
        temp_match_len <= 0;
        last_decode <= 0;

        curr_state <= LOAD_ENCODE;
    end
    else begin
        curr_state <= next_state;
        case (curr_state)
            LOAD_ENCODE: begin
                code_buff[code_buff_len] <= chardata;
                code_buff_len <= code_buff_len + 1;
            end
            COMPARE_SUBSTRING: begin
                busy <= 1;
                /* Not ready to encode */
                valid <= 0;
                encode <= 0;
                if(code_buff[pointer] == code_buff[look_ahead_buff_idx + temp_match_len] && search_buff_len != 0) begin
                    if(temp_match_len == 0) begin
                        temp_offset <= look_ahead_buff_idx - pointer - 1;
                        temp_match_len <= 1;
                        temp_char_nxt <= code_buff[look_ahead_buff_idx + temp_match_len + 1];
                    end
                    else begin
                        temp_match_len <= temp_match_len + 1;
                        temp_char_nxt <= code_buff[look_ahead_buff_idx + temp_match_len + 1];
                    end 
                end
                pointer <= pointer + 1;
            end
            CHANGE_SUBSTRING: begin
                /* Move to the shorter substring */
                search_buff_idx <= search_buff_idx + 1;
                pointer <= search_buff_idx + 1;  
                /* Reset the temp match string */
                temp_match_len <= 0;
                if(max_match_len == 0 && temp_match_len == 0) begin
                    max_offset <= 0;
                    max_match_len <= 0;
                    max_char_nxt <= code_buff[look_ahead_buff_idx];
                end
                else if(temp_match_len > max_match_len) begin
                    max_offset <= temp_offset;
                    max_match_len <= temp_match_len;
                    max_char_nxt <= temp_char_nxt;
                end
            end
            ENCODE: begin
                /* Ready to output encode */
                valid <= 1;
                encode <= 1;
                match_len <= max_match_len;
                offset <= max_offset;
                char_nxt <= max_char_nxt;
                /* Reset the match len in this loop */
                max_match_len <= 0;
                temp_match_len <= 0;
                /* If this is the end of the string, reset all the thing */
                if(look_ahead_buff_idx + max_match_len + 1 == code_buff_len) begin
                    code_buff_len <= 0;
                    code_buff_idx <= 0;
                    search_buff_idx <= 0;
                    search_buff_len <= 0;
                    look_ahead_buff_idx <= 0;
                    pointer <= 0;
                end
                else begin
                    /* If search_buff_len > max_search_buff_len after this encode, need to adjust code_buff_idx */
                    if(search_buff_len + max_match_len + 1 > max_search_buff_len) begin
                        code_buff_idx <= code_buff_idx + search_buff_len + max_match_len + 1 - max_search_buff_len;
                        search_buff_idx <= code_buff_idx + search_buff_len + max_match_len + 1 - max_search_buff_len;
                        pointer <= code_buff_idx + search_buff_len + max_match_len + 1 - max_search_buff_len;
                        search_buff_len <= max_search_buff_len;
                    end
                    /* If search_buff_len <= max_search_buff_len after this encode */
                    else begin
                        search_buff_idx <= code_buff_idx;
                        pointer <= code_buff_idx;
                        search_buff_len <= search_buff_len + max_match_len + 1;
                    end
                    look_ahead_buff_idx <= look_ahead_buff_idx + max_match_len + 1;
                end
            end
            LOAD_DECODE: begin
                valid <= 0;
                encode <= 0;
                if(code_valid) begin
                    search_buff_idx <= (code_buff_idx == 0) ? code_buff_idx - code_pos : code_buff_idx - code_pos - 1; 
                    search_buff_len <= code_len;                    // for loop copy
                    last_decode <= (chardata == 8'h45) ? 1 : 0;
                end
            end
            COPY_STR: begin
                if(search_buff_len == 0) begin
                    code_buff[code_buff_idx] <= chardata;
                    code_buff_idx <= code_buff_idx + 1;
                    search_buff_len <= code_len;
                end
                else begin
                    code_buff[code_buff_idx] <= code_buff[search_buff_idx];
                    code_buff_idx <= code_buff_idx + 1;
                    search_buff_idx <= search_buff_idx + 1;
                    search_buff_len <= search_buff_len - 1;
                end
            end
            DECODE: begin
                valid <= 1;
                char_nxt <= code_buff[look_ahead_buff_idx];
                look_ahead_buff_idx <= look_ahead_buff_idx + 1;
                search_buff_len <= search_buff_len - 1;     
                // if (search_buff_len != 0) begin
                //     curr_state <= DECODE;
                // end
                // else begin
                //     if (chardata == 8'h45) begin
                //         curr_state <= PRE_LOAD_ENCODE;
                //     end
                //     else begin
                //         curr_state <= LOAD_DECODE;
                //     end
                // end
                // //curr_state <= (chardata == 8'h45) ? PRE_LOAD_ENCODE : LOAD_DECODE;
            end
            PRE_LOAD_ENCODE: begin
                valid <= 0;
                busy <= 0;
                code_buff_idx <= 0;
                search_buff_idx <= 0;
                search_buff_len <= 0;
                look_ahead_buff_idx <= 0;
                last_decode <= 0;
            end
        endcase
    end
end

always @(*) begin
    case (curr_state)
        LOAD_ENCODE: begin
            next_state = (code_valid) ? LOAD_ENCODE : COMPARE_SUBSTRING;
        end
        COMPARE_SUBSTRING: begin
           next_state = (pointer == code_buff_len - 1 || pointer - search_buff_idx == max_look_ahead_buff_len - 2 || search_buff_len == 0 || (code_buff[pointer] != code_buff[look_ahead_buff_idx + temp_match_len] && search_buff_len != 0)) ? CHANGE_SUBSTRING : COMPARE_SUBSTRING;
        end
        CHANGE_SUBSTRING: begin
            next_state = (search_buff_idx == look_ahead_buff_idx - 1 || search_buff_len == 0 || temp_match_len == max_look_ahead_buff_len - 1) ? ENCODE : COMPARE_SUBSTRING;
        end
        ENCODE: begin
            next_state = (look_ahead_buff_idx + max_match_len + 1 == code_buff_len) ? LOAD_DECODE : COMPARE_SUBSTRING;
        end
        LOAD_DECODE: begin
            next_state = (code_valid) ? COPY_STR : LOAD_DECODE;
        end
        COPY_STR: begin
            next_state = (search_buff_len == 0) ? DECODE : COPY_STR;
        end
        DECODE: begin
            if (search_buff_len != 0) begin
                next_state = DECODE;
            end
            else begin
                if (last_decode) begin
                    next_state = PRE_LOAD_ENCODE;
                end
                else begin
                    next_state = LOAD_DECODE;
                end
            end
        end
        PRE_LOAD_ENCODE: begin
            next_state = LOAD_ENCODE;
        end
    endcase
end


endmodule