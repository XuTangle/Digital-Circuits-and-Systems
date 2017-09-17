LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Lab4 IS
   PORT(
      
      clock_50   : IN  STD_LOGIC;
      sw         : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);

      ledr       : OUT STD_LOGIC_VECTOR(17 DOWNTO 0); 
      ledg       : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0); 
      hex0,hex2	 : OUT STD_LOGIC_VECTOR( 6 DOWNTO 0)
      );
END Lab4;

ARCHITECTURE SimpleCircuit OF Lab4 IS

   COMPONENT SevenSegment PORT(        
      dataIn      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      blanking    : IN  STD_LOGIC;
      segmentsOut : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
   );
   END COMPONENT;												--declare the 7-segment componnet to be used
----------------------------------------------------------------------------------------------------
   CONSTANT CLK_DIV_SIZE: INTEGER := 25;     

   SIGNAL Main1HzCLK:   STD_LOGIC; 			--main clock to dive the state machine
   SIGNAL OneHzBinCLK:  STD_LOGIC; 			--1 Hz binary counter
   SIGNAL OneHzModCLK:  STD_LOGIC; 			--1 Hz modulus counter
   SIGNAL TenHzModCLK:  STD_LOGIC; 			--10 Hz modulus counter
   
   SIGNAL bin_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 	--reset binary counter to 0
   SIGNAL mod1_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 	
--reset 1 Hz modulus counter to 0
   SIGNAL mod10_counter:  UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 	
--reset 10 Hz modulus counter to 0
   SIGNAL mod1_terminal: UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 	
--reset 1 Hz termical count to 0
   SIGNAL mod10_terminal: UNSIGNED(CLK_DIV_SIZE-1 DOWNTO 0) := to_unsigned(0,CLK_DIV_SIZE); 	
--reset 10 Hz termical count to 0
   
   TYPE STATES IS (STATE0, STATE1, STATE2, STATE3,STATE4, STATE5);   		-- list of all states
   SIGNAL state, next_state:  STATES;                
   
   SIGNAL state_number: STD_LOGIC_VECTOR(3 DOWNTO 0);		
--4-digit binary number to display state number
   SIGNAL state_counter: UNSIGNED(3 DOWNTO 0);      		
--4-digit binary number to display state count number
----------------------------------------------------------------------

BEGIN

   BinCLK: PROCESS(clock_50)
   BEGIN
      IF (rising_edge(clock_50)) THEN 						
-- binary counter increment on rising clock edge
         bin_counter <= bin_counter + 1;
      END IF;
   END PROCESS;
   OneHzBinCLK <= std_logic(bin_counter(CLK_DIV_SIZE-1)); 	
--binary counter MSB
   LEDG(2) <= OneHzBinCLK;
----------------------------------------------------------------------
   mod1_terminal <= "0000000000000000000000100";		--F=1Hz
   mod10_terminal <= "0001001100010010110011111";		--F=10Hz
---------------------------------------------------------------------
   ModCLK: PROCESS(clock_50) 
   BEGIN  
      IF (rising_edge(clock_50)) THEN			-- build 10 HZ counter based on clock 50
         IF (mod10_counter = mod10_terminal) THEN       
            TENHzModCLK <= NOT TENHzModCLK;               
            mod10_counter <= to_unsigned(0,CLK_DIV_SIZE); 
         ELSE
            mod10_counter <= mod10_counter + 1;
         END IF;
      END IF;
      
      IF (rising_edge(TENHzModCLK))THEN   		-- build 1 Hz counter based on 10 Hz counter
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
--------------------------------------------------------------------
   Main1HzCLK <= OneHzModCLK WHEN (sw(17) = '0') ELSE OneHzBinCLK; 
--------------------------------------------------------------------
   FSM: PROCESS(state, sw) -- main FSM
   BEGIN
      CASE state IS
         WHEN STATE0 => 		--state 0: NS green flashes, EW red on
            state_number <= "0000";
            IF (state_counter = "0001") THEN 		--after 2 seconds, change state.
               next_state <= STATE1;
            ELSE
               next_state <= STATE0;
            END IF;
            ledg(8) <= TENHzModCLK;
            ledr(11) <= '0';
            ledg(7) <= '0';
            ledr(0) <= '1';
         WHEN STATE1 => 			--state 1; NS green on, EW red on
            state_number <= "0001";
            IF (state_counter = "0101") THEN		--after 4 seconds, change state
               next_state <= STATE2;
            ELSE
               next_state <= STATE1;
            END IF;
            ledg(8) <= '1';
            ledr(11) <= '0';
            ledg(7) <= '0';
            ledr(0) <= '1';
         WHEN STATE2 => 		--state 2; NS red flashes, EW red on
            state_number <= "0010";
            IF (state_counter = "0111") THEN		--after 2 seconds, change state	
               next_state <= STATE3;
            ELSE
               next_state <= STATE2;
            END IF;
            ledg(8) <= '0';
            ledr(11) <= TENHzModCLK;
            ledg(7) <= '0';
            ledr(0) <= '1';
         WHEN STATE3 => 		--state 3; NS red on, EW green flashes
            state_number <= "0011";
            IF (state_counter = "1001") THEN		--after 2 seconds, change state
               next_state <= STATE4;
            ELSE
               next_state <= STATE3;
            END IF;
            ledg(8) <= '0';
            ledr(11) <= '1';
            ledg(7) <= TENHzModCLK;
            ledr(0) <= '0';
         WHEN STATE4 => 		--state 4: NS red on,  EW green on
            state_number <= "0100";
            IF (state_counter = "1101") THEN		--after 4 seconds, change state
               next_state <= STATE5;
            ELSE
               next_state <= STATE4;
            END IF;
            ledg(8) <= '0';
            ledr(11) <= '1';
            ledg(7) <= '1';
            ledr(0) <= '0';
         WHEN OTHERS => 		--state 5: NS red on, EW red flashes
            state_number <= "0101";
            IF (state_counter = "1111") THEN		--after 2 seconds, 
               next_state <= STATE0;
            ELSE
               next_state <= STATE5;
            END IF;
            ledg(8) <= '0';
            ledr(11) <= '1';
            ledg(7) <= '0';
            ledr(0) <= TENHzModCLK;
      END CASE;
   END PROCESS;
-------------------------------------------------------------------
   SeqLogic: PROCESS(OneHzModCLK, state) 
   BEGIN
      IF (rising_edge(OneHzModCLK)) THEN
         state <= next_state;    			--update the new state                  
         state_counter <= state_counter + 1;   		
--on the rising edge of clock, the current counter is increment
      END IF;
   END PROCESS;
-------------------------------------------------------------------
   D7S0: SevenSegment PORT MAP( state_number, '0', hex0 );
   D7S4: SevenSegment PORT MAP( std_logic_vector(state_counter), '0', hex2 );

END SimpleCircuit;
