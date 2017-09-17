LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--
-- 7-segment display driver. It displays a 4-bit number on 7-segments 
-- This is created as an entity so that it can be reused many times easily
--

ENTITY SevenSegment IS PORT (
   
   dataIn      :  IN  std_logic_vector(3 DOWNTO 0);   -- The 4 bit data to be displayed
   blanking    :  IN  std_logic;                      -- This bit turns off all segments
   
   segmentsOut :  OUT std_logic_vector(6 DOWNTO 0)    -- 7-bit outputs to a 7-segment
); 

END SevenSegment;

ARCHITECTURE Behavioral OF SevenSegment IS

-- 
-- The following statements convert a 4-bit input, called dataIn to a pattern of 7 bits
-- The segment turns on when it is '0' otherwise '1'
-- The blanking input is added to turns off the all segments
--

BEGIN

   with blanking & dataIn SELECT --  gfedcba        b3210      -- D7S
      segmentsOut(6 DOWNTO 0) <=    "1000000" WHEN "00000",    -- [0]
                                    "1111001" WHEN "00001",    -- [1]
                                    "0100100" WHEN "00010",    -- [2]      +---- a ----+
                                    "0110000" WHEN "00011",    -- [3]      |           |
                                    "0011001" WHEN "00100",    -- [4]      |           |
                                    "0010010" WHEN "00101",    -- [5]      f           b
                                    "0000010" WHEN "00110",    -- [6]      |           |
                                    "1111000" WHEN "00111",    -- [7]      |           |
                                    "0000000" WHEN "01000",    -- [8]      +---- g ----+
                                    "0010000" WHEN "01001",    -- [9]      |           |
                                    "0001000" WHEN "01010",    -- [A]      |           |
                                    "0000011" WHEN "01011",    -- [b]      e           c
                                    "0100111" WHEN "01100",    -- [c]      |           |
                                    "0100001" WHEN "01101",    -- [d]      |           |
                                    "0000110" WHEN "01110",    -- [E]      +---- d ----+
                                    "0001110" WHEN "01111",    -- [F]
                                    "1111111" WHEN OTHERS;     -- [ ]

END Behavioral;

--------------------------------------------------------------------------------
-- Main entity
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Lab5 IS
   PORT(
      
      clock_50   : IN  STD_LOGIC;
      sw         : IN  STD_LOGIC_VECTOR(17 DOWNTO 0); -- 18 dip switches on the board

      ledr       : OUT STD_LOGIC_VECTOR(17 DOWNTO 0); -- LEDs, many Red ones are available
      ledg       : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0); -- LEDs, many Green ones are available
      hex0, hex2, hex4, hex6 : OUT STD_LOGIC_VECTOR( 6 DOWNTO 0)  -- seven segments to display numbers
);
END Lab5;

ARCHITECTURE SimpleCircuit OF Lab5 IS

--
-- In order to use the "SevenSegment" entity, we should declare it with first
-- 

   COMPONENT SevenSegment PORT(        -- Declare the 7 segment component to be used
      dataIn      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      blanking    : IN  STD_LOGIC;
      segmentsOut : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
   );
   END COMPONENT;
----------------------------------------------------------------------------------------------------
   CONSTANT CLK_DIV_SIZE: INTEGER := 25;     -- size of vectors for the counters

   SIGNAL Main1HzCLK:   STD_LOGIC; -- main 1Hz clock to drive FSM
   SIGNAL OneHzBinCLK:  STD_LOGIC; -- binary 1 Hz clock
   SIGNAL OneHzModCLK:  STD_LOGIC; -- modulus 1 Hz clock
   SIGNAL TenHzModCLK:  STD_LOGIC; -- modulus 10 Hz clock

   SIGNAL bin_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 
   SIGNAL mod1_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 
   SIGNAL mod10_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE);
   SIGNAL mod1_terminal: UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE);
   SIGNAL mod10_terminal: UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 

   TYPE STATES IS (STATE0, STATE1, STATE2, STATE3,STATE4, STATE5);  
   SIGNAL state, nextstate:  STATES;               
   
   SIGNAL statenumber: STD_LOGIC_VECTOR(3 DOWNTO 0);

   SIGNAL statecounter, nextstatecounter, waitWE, waitNS: UNSIGNED(3 DOWNTO 0);  
----------------------------------------------------------------------------------------------------

BEGIN

   BinCLK: PROCESS(clock_50)
   BEGIN
      IF (rising_edge(clock_50)) THEN 
         bin_counter <= bin_counter + 1;
      END IF;
   END PROCESS;
   OneHzBinCLK <= std_logic(bin_counter(CLK_DIV_SIZE-1)); 
   LEDG(2) <= OneHzBinCLK;
----------------------------------------------------------------------------------------------------
   mod1_terminal <= "0000000000000000000000100";
   mod10_terminal <= "0000000000000000000000001"; -- 0000000000000000000000001 0001001100010010110011111
-------------------------------------------------------------------------------------------------------
   ModCLK: PROCESS(clock_50) 
   BEGIN  													--10 Hz mod counter based on clock 50
      IF (rising_edge(clock_50)) THEN 
         IF (mod10_counter = mod10_terminal) THEN       
            TENHzModCLK <= NOT TENHzModCLK;                 
            mod10_counter <= to_unsigned(0,CLK_DIV_SIZE); 
         ELSE
            mod10_counter <= mod10_counter + 1;
         END IF;
      END IF;
      
      IF (rising_edge(TENHzModCLK)) THEN 					--1 Hz mod counter based on 10 Hz mod counter
         IF (mod1_counter = mod1_terminal) THEN      
            OneHzModCLK <= NOT OneHzModCLK;                
            mod1_counter <= to_unsigned(0,CLK_DIV_SIZE); 
         ELSE
            mod1_counter <= mod1_counter + 1;
         END IF;
      END IF;
   END PROCESS;
   
   LEDG(1) <= OneHzModCLK;
   LEDG(0) <= TENHzModCLK;
----------------------------------------------------------------------------------------------------
   FSM: PROCESS(state, sw) -- main FSM
   BEGIN
      CASE state IS
		 --state 0 : NS green flashes, EW red on.
         WHEN STATE0 =>
            statenumber <= "0000";
            IF (statecounter = "0001") THEN 
               nextstate <= STATE1;
               nextstatecounter <="0000";
               --change to state1 after two seconds
            ELSE
               nextstate <= STATE0;
               nextstatecounter <= statecounter+1;
            END IF;
            
			ledr(11) <= '0';
            ledg(7) <= '0';
            ledr(0) <= '1';
            
            --when night mode + default NS + no car on WE, NS green on instead of flashing
			IF (sw(16)='0' and sw(14)='0' and sw(17)='1') Then
			ledg(8) <= '1';
			ELSE 
			ledg(8) <= TENHzModCLK;
            END IF;
		
		 --state 1: NS green on, WE red on	
         WHEN STATE1 =>
            statenumber <= "0001";
            IF (statecounter = "0011") THEN
               nextstate <= STATE2;
               nextstatecounter <="0000";
			   --change to state 2 after 4 seconds
            ELSE
               nextstate <= STATE1;
               nextstatecounter <= statecounter+1;
            END IF;
            
            ledg(8) <= '1';
            ledr(11) <= '0';
            ledg(7) <= '0';
            ledr(0) <= '1';
          
         --state 2: NS red flashes, WE red on 
         WHEN STATE2 => 
            statenumber <= "0010";
            IF (statecounter = "0001") THEN 
				IF (sw(16)='0' and sw(14)='0' and sw(17)='1')THEN 
				nextstate <= STATE0; 
				ELSE
				nextstate <= STATE3;
				END IF; 
			nextstatecounter <="0000";
			--when night mode + default NS + no car on WE, go back to state 1 after 2 seconds
			--otherwise go to state 3 after 2 seconds
			
            ELSE
               nextstate <= STATE2;
               nextstatecounter <= statecounter+1;
            END IF;
            
            ledg(8) <= '0';
            ledr(11) <= TENHzModCLK;
            ledg(7) <= '0';
            ledr(0) <= '1';
         
         --state 3: NS red on, WE green flashes   
         WHEN STATE3 =>
            statenumber <= "0011";
            IF (statecounter = "0001") THEN
               nextstate <= STATE4;
               nextstatecounter <="0000";
               --change to state 5 after 2 seconds
            ELSE
               nextstate <= STATE3;
               nextstatecounter <= statecounter+1;
            END IF;
            
            ledg(8) <= '0';
            ledr(11) <= '1';
			ledr(0) <= '0';
			
			--when night mode + default WE + no car on NS, EW green on instead of flashing
            IF (sw(15)='0' and sw(17)='1' and sw(16)='1')THEN
			ledg(7) <= '1';
            ELSE 
			ledg(7) <= TENHzModCLK;
            END IF;
           
         --state 4: NS red on, EW green on 
         WHEN STATE4 =>
            statenumber <= "0100";
            IF (statecounter = "0011") THEN
               nextstate <= STATE5;
               nextstatecounter <="0000";
               --change state after 4 seconds
            ELSE
               nextstate <= STATE4;
               nextstatecounter <= statecounter+1;
            END IF;
            
            ledg(8) <= '0';
            ledr(11) <= '1';
            ledg(7) <= '1';
            ledr(0) <= '0';
          
         --state 5: NS red on, WE red flashes 
         WHEN STATE5 =>
            statenumber <= "0101";
            IF (statecounter = "0001") THEN 
				IF (sw(15)='0' and sw(17)='1' and sw(16)='1')THEN 
				nextstate <= STATE3; 
				ELSE 
				nextstate <= STATE0;
				END IF;
			nextstatecounter <="0000"; 
			--when night mode + default WE + no car on NS, go back to state 3 after 2 seconds
			--otherwise go to state 0 after 2 seconds
			
            ELSE
               nextstate <= STATE5;
               nextstatecounter <= statecounter+1;
            END IF;
            
            ledg(8) <= '0';
            ledr(11) <= '1';
            ledg(7) <= '0';
            ledr(0) <= TENHzModCLK;

      END CASE;
   END PROCESS;
----------------------------------------------------------------------------------------------------
   SeqLogic: PROCESS(OneHzModCLK) 
   BEGIN
      IF (rising_edge(OneHzModCLK)) THEN
         state <= nextstate;       						 	                
         statecounter <= nextstatecounter;					
         
         IF (sw(16)='0' and sw(14)='1' and sw(17)='1'and (state =STATE0 or state=STATE1 or state=STATE2)) THEN
			waitWE <= waitWE +1;
			--when night mode + default NS + car sensor on on WE + state 0 or 1 or 2 count waitWE
		 ELSE
			waitWE <= "0000";
			--otherwise clear waitWE to 0
		 END IF;
		 
		 IF (sw(15)='1' and sw(17)='1' and sw(16)='1'and (state =STATE3 or state=STATE4 or state=STATE5)) THEN
			waitNS <= waitNS +1;
			--when night mode + default WE + car sensor on on NS + state 3  or 4 or 5, count waitNS
		 ELSE
			waitNS <= "0000";
			--otherwise clear waitNS to 0
		 END IF;
		 
      END IF;
   END PROCESS;
----------------------------------------------------------------------------------------------------
   D7S0: SevenSegment PORT MAP( statenumber, '0', hex0 );
   D7S2: SevenSegment PORT MAP( std_logic_vector(statecounter), '0', hex2 );
   D7S4: SevenSegment PORT MAP( std_logic_vector(waitNS), '0', hex4 );
   D7S6: SevenSegment PORT MAP( std_logic_vector(waitWE), '0', hex6 );

END SimpleCircuit;