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
reg find_match;
reg [3:0] pointer;
reg [3:0] max_offset;
reg [3:0] max_match_len;
reg [7:0] max_char_nxt;
reg [2:0] curr_state, next_state;

parameter LOAD_ENCODE = 3'd0;
parameter COMPARE_SUBSTRING = 3'd1;
parameter CHANGE_SUBSTRING = 3'd2;
parameter ENCODE = 3'd3;
parameter LOAD_DECODE = 3'd4;

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
        find_match <= 0;
        pointer <= 0;
        max_match_len <= 0;

        curr_state <= LOAD_ENCODE;
    end
    else begin
        curr_state <= next_state;
        case (curr_state)
            LOAD_ENCODE: begin
                if (code_valid) begin
                    code_buff[code_buff_len] <= chardata;
                    code_buff_len <= code_buff_len + 1;
                end
            end
            COMPARE_SUBSTRING: begin
                /* Not ready to encode */
                valid <= 0;
                encode <= 0;
                if(code_buff[pointer] == code_buff[look_ahead_buff_idx + max_match_len] && search_buff_len != 0) begin
                    offset <= search_buff_len - pointer - 1;
                    match_len <= 1;
                    char_nxt <= code_buff[look_ahead_buff_idx + max_match_len + 1];
                end
                pointer <= pointer + 1;
            end
            CHANGE_SUBSTRING: begin
                search_buff_idx <= search_buff_idx + 1;
                pointer <= search_buff_idx + 1;  
                find_match <= 0;
                if(max_match_len == 0 && match_len == 0) begin
                    max_offset <= 0;
                    max_match_len <= 0;
                    max_char_nxt <= code_buff[look_ahead_buff_idx];
                end
                else if(match_len > max_match_len) begin
                    max_offset <= offset;
                    max_match_len <= match_len;
                    max_char_nxt <= char_nxt;
                end
            end
            ENCODE: begin
                /* Ready to output encode */
                valid <= 1;
                encode <= 1;
                match_len <= max_match_len;
                offset <= max_offset;
                char_nxt <= max_char_nxt;
                /* Reset the max_match_len */

                max_match_len <= 0;
                /* If search_buff_len > max_search_buff_len after this encode, need to adjust code_buff_idx */
                if(search_buff_len + match_len + 1 > max_search_buff_len) begin
                    {code_buff_idx, search_buff_idx, pointer} <= {3 {code_buff_idx + search_buff_len + match_len + 1 - max_search_buff_len} };
                    search_buff_len <= max_search_buff_len;
                end
                /* If search_buff_len <= max_search_buff_len after this encode */
                else begin
                    {search_buff_idx, pointer} <= {2 {code_buff_idx} };
                    search_buff_len <= search_buff_len + match_len + 1;
                end
                look_ahead_buff_idx <= look_ahead_buff_idx + match_len + 1;
            end
            LOAD_DECODE: begin
                
            end
        endcase
    end
end

always @(*) begin
    case (curr_state)
        LOAD_ENCODE: begin
            next_state = (code_valid) ? LOAD_ENCODE : COMPARE_SUBSTRING;
        end
        // COMPARE_SUBSTRING: begin
        //     if(search_buff_len == 0 || match_len >= look_ahead_buff_idx - search_buff_idx) 
        //         next_state = ENCODE;                
        //     else if(pointer == look_ahead_buff_idx - 1)
        //         next_state = CHANGE_SUBSTRING;
        //     else
        //         next_state = COMPARE_SUBSTRING;
        // end
        // CHANGE_SUBSTRING: begin
        //     next_state = (search_buff_idx == look_ahead_buff_idx - 1) ? ENCODE : COMPARE_SUBSTRING;
        // end
        // ENCODE: begin
        //     next_state = (search_buff_idx == code_buff_len - 1) ? LOAD_DECODE : COMPARE_SUBSTRING;
        // end
        COMPARE_SUBSTRING: begin
           next_state = (pointer == look_ahead_buff_idx - 1 || search_buff_len == 0) ? CHANGE_SUBSTRING : COMPARE_SUBSTRING;
        end
        CHANGE_SUBSTRING: begin
            next_state = (search_buff_idx == look_ahead_buff_idx - 1 || search_buff_len == 0) ? ENCODE : COMPARE_SUBSTRING;
        end
        ENCODE: begin
            next_state = (look_ahead_buff_idx + match_len + 1 == code_buff_len) ? LOAD_DECODE : COMPARE_SUBSTRING;
        end
    endcase
end


endmodule