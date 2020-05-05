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
reg [2:0] curr_state, next_state;

parameter LOAD_ENCODE = 3'd0;
parameter FIND_MATCH = 3'd1;
parameter ENCODE = 3'd2;
parameter LOAD_DECODE = 3'd3;

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
            FIND_MATCH: begin
                valid <= 0;
                encode <= 0;
                if(search_buff_len == 0) begin
                    char_nxt <= code_buff[0];
                end
                else if(code_buff[search_buff_idx] == code_buff[look_ahead_buff_idx]) begin
                    if(!find_match) begin
                        offset <= search_buff_idx - code_buff_idx + search_buff_len - 1;
                    end
                    match_len <= match_len + 1;
                    char_nxt <= code_buff[search_buff_idx+1];
                    search_buff_idx <= search_buff_idx + 1;
                    look_ahead_buff_idx <= look_ahead_buff_idx + 1;
                    find_match <= 1;
                end           
            end
            ENCODE: begin
                valid <= 1;
                encode <= 1;
                find_match <= 0;
                if(search_buff_len + match_len + 1 > max_search_buff_len) begin
                    code_buff_idx <= code_buff_idx + search_buff_len + match_len + 1 - max_search_buff_len;
                    search_buff_len <= max_search_buff_len;
                    search_buff_idx <= code_buff_idx + search_buff_len + match_len + 1 - max_search_buff_len;
                    look_ahead_buff_idx <= code_buff_idx + search_buff_len + match_len + 1;
                end
                else begin
                    search_buff_len <= search_buff_len + match_len + 1;
                    search_buff_idx <= code_buff_idx;
                    look_ahead_buff_idx <= code_buff_idx + search_buff_len + match_len + 1;
                end
            end
            LOAD_DECODE: begin
                
            end
        endcase
    end
end

always @(*) begin
    case (curr_state)
        LOAD_ENCODE: begin
            next_state = (code_valid) ? LOAD_ENCODE : ENCODE;
        end
        FIND_MATCH: begin
            next_state = (search_buff_idx - code_buff_idx == search_buff_len) ? ENCODE : FIND_MATCH;
        end
        ENCODE: begin
            next_state = (search_buff_idx == code_buff_len - 1) ? LOAD_DECODE : FIND_MATCH;
        end
    endcase
end


endmodule