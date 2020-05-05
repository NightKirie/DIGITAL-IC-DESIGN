library verilog;
use verilog.vl_types.all;
entity LZE is
    generic(
        LOAD_ENCODE     : vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi0);
        COMPARE_SUBSTRING: vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi1);
        CHANGE_SUBSTRING: vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi0);
        \ENCODE\        : vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi1);
        LOAD_DECODE     : vl_logic_vector(0 to 2) := (Hi1, Hi0, Hi0);
        max_look_ahead_buff_len: integer := 8;
        max_search_buff_len: integer := 9
    );
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
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of LOAD_ENCODE : constant is 1;
    attribute mti_svvh_generic_type of COMPARE_SUBSTRING : constant is 1;
    attribute mti_svvh_generic_type of CHANGE_SUBSTRING : constant is 1;
    attribute mti_svvh_generic_type of \ENCODE\ : constant is 1;
    attribute mti_svvh_generic_type of LOAD_DECODE : constant is 1;
    attribute mti_svvh_generic_type of max_look_ahead_buff_len : constant is 1;
    attribute mti_svvh_generic_type of max_search_buff_len : constant is 1;
end LZE;
