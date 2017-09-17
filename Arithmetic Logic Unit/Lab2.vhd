library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- 7-segment display driver. It displays a 4-bit number on 7-segments 
-- This is created as an entity so that it can be reused many times easily
--

entity SevenSegment is port (
   
   dataIn      :  in  std_logic_vector(3 downto 0);   -- The 4 bit data to be displayed
   blanking    :  in  std_logic;                      -- This bit turns off all segments
   
   segmentsOut :  out std_logic_vector(6 downto 0)    -- 7-bit outputs to a 7-segment
); 
end SevenSegment;

architecture Behavioral of SevenSegment is

-- 
-- The following statements convert a 4-bit input, called dataIn to a pattern of 7 bits
-- The segment turns on when it is '0' otherwise '1'
-- The blanking input is added to turns off the all segments
--

begin

   with blanking & dataIn select --  gfedcba        b3210      -- D7S
      segmentsOut(6 downto 0) <=    "1000000" when "00000",    -- [0]
                                    "1111001" when "00001",    -- [1]
                                    "0100100" when "00010",    -- [2]      +---- a ----+
                                    "0110000" when "00011",    -- [3]      |           |
                                    "0011001" when "00100",    -- [4]      |           |
                                    "0010010" when "00101",    -- [5]      f           b
                                    "0000010" when "00110",    -- [6]      |           |
                                    "1111000" when "00111",    -- [7]      |           |
                                    "0000000" when "01000",    -- [8]      +---- g ----+
                                    "0010000" when "01001",    -- [9]      |           |
                                    "0001000" when "01010",    -- [A]      |           |
                                    "0000011" when "01011",    -- [b]      e           c
                                    "1000110" when "01100",    -- [c]      |           |
                                    "0100001" when "01101",    -- [d]      |           |
                                    "0000110" when "01110",    -- [E]      +---- d ----+
                                    "0001110" when "01111",    -- [F]
                                    "1111111" when others;     -- [ ]

end Behavioral;

--------------------------------------------------------------------------------
-- Main entity
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab2 is port (
      
     -- key              :   in  std_logic_vector(3 downto 0); -- 4 push buttons
      sw               :   in  std_logic_vector(17 downto 0); -- 18 input switches
      ledr             :   out std_logic_vector(17 downto 0); -- 18 output red LEDs      
      hex0, hex1, hex2, hex4, hex5, hex6, hex7:   out std_logic_vector(6 downto 0)  -- 7 output seven-segment desplays
);
end Lab2;

architecture SimpleCircuit of Lab2 is

   component SevenSegment port (
      dataIn      :  in    std_logic_vector(3 downto 0);
      blanking    :  in    std_logic;
      segmentsOut :  out   std_logic_vector(6 downto 0)
   );
   end component;

   -- define the output and input signals
   signal firstnum, secondnum: std_logic_vector(7 downto 0); 	-- input signal firstnum and secondnum will contain 8-digital-numbers
   signal result: std_logic_vector(11 downto 0);				-- output signal result will contain 8-digital-numbers		
   signal operator: std_logic_vector(1 downto 0);				-- input signal operator will contain 8-digital-numbers	
	  
begin
  
   firstnum <= sw(7 downto 0);  		--input the values from swich 0-7 to signal firstnum
   secondnum <= sw(15 downto 8);  		--input the values from swich 8-15 to signal secondnum
   operator <= sw(17 downto 16); 		--input the values from swich 16-17 to signal operator
   

   with operator select												-- define the operator based on it's value
		result <= "0000"&(firstnum and secondnum) when "00",		-- when the value of the operator is 00, do AND for firstnum and secondnum and save it into result
		          "0000"&(firstnum or secondnum) when "01",			-- when the value of the operator is 01, do OR for firstnum and secondnum and save it into result
		          "0000"&(firstnum xor secondnum) when "10",		-- when the value of the operator is 10, do XOR for firstnum and secondnum and save it into result
		          std_logic_vector (unsigned ("0000"&firstnum) + unsigned ("0000"&secondnum)) when "11"; 		-- when the value of the operator is 11, ADD firstnum and secondnum and save it into result
		          
		           
	ledr(11 downto 0) <= result; 		--output the result value with 12 red LED lights (ledr 10-12won;t really be used)
	ledr(17 downto 16) <= operator; 	--output the operator value with 2 red LED lights

   D7SH0: SevenSegment port map(result(3 downto 0), '0', hex0 ); 			
   D7SH1: SevenSegment port map(result(7 downto 4), '0', hex1 );			
   D7SH2: SevenSegment port map(result(11 downto 8), not result(8), hex2 );	--display the result on seven-segment display 0-2 in hex number
  
   D7SH4: SevenSegment port map(firstnum(3 downto 0), '0', hex4 );
   D7SH5: SevenSegment port map(firstnum(7 downto 4), '0', hex5 ); 			--display the secondnum on seven-segment display 0-2 in hex number
   
   D7SH6: SevenSegment port map(secondnum(3 downto 0), '0', hex6 );			
   D7SH7: SevenSegment port map(secondnum(7 downto 4), '0', hex7 );			--display the firstnum on seven-segment display 0-2 in hex number
   

end SimpleCircuit;
