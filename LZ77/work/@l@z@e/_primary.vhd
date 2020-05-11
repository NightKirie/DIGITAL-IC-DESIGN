library verilog;
use verilog.vl_types.all;
entity LZE is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        code_valid      : in     vl_logic;
        code_pos        : in     vl_logic_vector(3 downto 0);
        code_len        : in     vl_logic_vector(3 downto 0);
        chardata        : in     vl_logic_vector(7 downto 0);
        valid           : out    vl_logic;
        encode          : out    vl_logic;
        busy            : out    vl_logic;
        offset          : out    vl_logic_vector(3 downto 0);
        match_len       : out    vl_logic_vector(3 downto 0);
        char_nxt        : out    vl_logic_vector(7 downto 0)
    );
end LZE;
