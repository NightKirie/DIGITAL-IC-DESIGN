library verilog;
use verilog.vl_types.all;
entity div is
    port(
        \out\           : out    vl_logic_vector(7 downto 0);
        in1             : in     vl_logic_vector(7 downto 0);
        in2             : in     vl_logic_vector(7 downto 0);
        dbz             : out    vl_logic
    );
end div;
