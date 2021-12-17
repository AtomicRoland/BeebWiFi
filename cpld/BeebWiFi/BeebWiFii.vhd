----------------------------------------------------------------------------------
-- Company:        StarDot Community
-- Engineer:       Roland Leurs
--
-- Create Date:    11/07/2021
-- Design Name:
-- Module Name:    cpld - Behavioral
-- Project Name:   BBC - WiFi
-- Target Devices: XC9572XL
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Revision 0.02 - Bugfix in reset of UART
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpld is
   generic(
      clk_freq : integer := 625;   -- input frequency
      freq     : integer := 144    -- desired output frequency
   );

   port(
      A        : in  std_logic_vector(7 downto 0);
      clk_in   : in  std_logic;  -- Phi1/2 signal
      RnW      : in  std_logic;  -- Electron R/nW signal
      nPGFC    : in  std_logic;  -- Page &FC enable
      nPGFD    : in  std_logic;  -- Page &FD enable
      tx_a     : in  std_logic;  -- TX port A
      rx_a     : in  std_logic;  -- RX port A
      tx_b     : in  std_logic;  -- TX port B
      rx_b     : in  std_logic;  -- RX port B
      reset_in : in  std_logic;  -- Reset signal

      cs_uart  : out std_logic;  -- UART enable
      cs_ram   : out std_logic;  -- Paged RAM enable
      cs_pareg : out std_logic;  -- Page Register enable
      cs_buf   : out std_logic;  -- buffer enable
      bufdir   : out std_logic;  -- data bus direction
      ior      : out std_logic;  -- IOR (nrds)
      iow      : out std_logic;  -- IOW (nwds)
      led_rx_a : out std_logic;  -- LED RX port A
      led_tx_a : out std_logic;  -- LED TX port A
      led_rx_b : out std_logic;  -- LED RX port B
      led_tx_b : out std_logic;  -- LED TX port B
      rx_esp   : out std_logic;  -- Level shifted output of TXB
      reset_out: out std_logic   -- Inverted reset for the UART
   );
end cpld;

architecture Behavioral of cpld is
   type  clkCounter is range 0 to 200000; 
   signal hz10, hz10_1 : STD_LOGIC;
   signal trigger_rx_a : STD_LOGIC := '0';
   signal trigger_rx_b : STD_LOGIC := '0';
   signal trigger_tx_a : STD_LOGIC := '0';
   signal trigger_tx_b : STD_LOGIC := '0';
   signal wifi_disable : STD_LOGIC := '0';
   
   signal enable_ram   : STD_LOGIC := '0';
   signal enable_pareg : STD_LOGIC := '0';
   signal enable_uart  : STD_LOGIC := '0';
   signal enable_buffer: STD_LOGIC := '0';
   
   signal cnPGFC,cnPGFD: STD_LOGIC;

begin

   -- Clean Select Signals 
   -- See Acorn 1MHz Bus Application Note
   -- Derivation Of Valid Page Signals 
   process (clk_in, nPGFC, nPGFD, A)
   begin
      if rising_edge(clk_in) then
         cnPGFC <= nPGFC;
         cnPGFD <= nPGFD;
      end if;
      
      -- Set/reset wifi_disable by writing to the LSR-B (&FC35) and
      -- MSR-B (&FC36) registers
      if rising_edge(clk_in) then
         if nPGFC = '0' and (A(7 downto 1) = "0011010" or A(7 downto 1) = "0011011") and RnW = '0' then
            wifi_disable <= A(0);
         end if;
      end if;
      

   end process;

   -- Chip Control logic
   process(cnPGFC, cnPGFD, A, clk_in, RnW, reset_in, wifi_disable)
   begin
      -- Enable UART at &FC3x
      -- and &FCFF (paged ram register)
      if cnPGFC = '0' and (A(7 downto 4) = "0011" or A(7 downto 0) = "11111111") then
         enable_uart <= '1';
      else
         enable_uart <= '0';
      end if;

      -- Inverted reset for the UART
      -- but only when wifi is not disabled
      if wifi_disable = '0' then
         reset_out <= not reset_in;
      else
         reset_out <= '0';
      end if;

      -- Enable Paged Ram Register when writing to &FCFF
      if cnPGFC = '0' and A(7 downto 0) = "11111111" and RnW = '0' then
         enable_pareg <= '1';
      else
         enable_pareg <= '0';
      end if;
      
      -- Enable Paged RAM memory when reading/writing to page &FD
      if cnPGFD = '0' then
         enable_ram <= '1';
      else
         enable_ram <= '0';
      end if;
            
      -- IOR (nrds) and IOW (nwds) signals
      if clk_in = '1' and RnW = '1' then
         IOR <= '0';
      else
         IOR <= '1';
      end if;
      if clk_in = '1' and RnW = '0' then
         IOW <= '0';
      else
         IOW <= '1';
      end if;
      
      -- Enable data bus buffer
      if enable_ram = '1' or enable_pareg = '1' or enable_uart = '1' then
         enable_buffer <= '1';
      else
         enable_buffer <= '0';
      end if;
      
   end process;

   -- Clock divider, used for led control, not critical
   process (clk_in)
   variable hz10Cnt : clkCounter := 0;
	begin
		if rising_edge(clk_in) then
			-- Clock divider to 10 Hz clock signal
			-- If the input clock is not 1MHz then the 100000 must be adjusted
			if hz10Cnt = 100000 then
				hz10 <= not hz10;
				hz10Cnt := 0;
			else
				hz10Cnt := hz10Cnt + 1;
			end if;
         hz10_1 <= hz10;
		end if;
	end process;

   -- LED controls
   -- The led should go on for 0.1 seconds when there is a state change
   -- on the assigned input pin.

   process(clk_in, hz10, hz10_1, rx_a)
   begin
      if rising_edge(clk_in) then
         if rx_a = '0' then
            trigger_rx_a <= '1';
         end if;
         
         -- detection of rising edge on 10hz signal
         if hz10_1 = '0' and hz10 = '1' then
            led_rx_a <= not trigger_rx_a;
            trigger_rx_a <= '0';
         end if;
      end if;
   end process;

   process(clk_in, hz10, hz10_1, tx_a)
   begin
      if rising_edge(clk_in) then
         if tx_a = '0' then
            trigger_tx_a <= '1';
         end if;
         
         -- detection of rising edge on 10hz signal
         if hz10_1 = '0' and hz10 = '1' then
            led_tx_a <= not trigger_tx_a;
            trigger_tx_a <= '0';
         end if;
      end if;
   end process;

   process(clk_in, hz10, hz10_1, rx_b)
   begin
      if rising_edge(clk_in) then
         if rx_b = '0' then
            trigger_rx_b <= '1';
         end if;
         
         -- detection of rising edge on 10hz signal
         if hz10_1 = '0' and hz10 = '1' then
            led_rx_b <= not trigger_rx_b;
            trigger_rx_b <= '0';
         end if;
      end if;
   end process;

   process(clk_in, hz10, hz10_1, tx_b)
   begin
      if rising_edge(clk_in) then
         if tx_b = '0' then
            trigger_tx_b <= '1';
         end if;
         
         -- detection of rising edge on 10hz signal
         if hz10_1 = '0' and hz10 = '1' then
            led_tx_b <= not trigger_tx_b;
            trigger_tx_b <= '0';
         end if;
      end if;
   end process;

   -- Simple level shifting
   rx_esp <= tx_b;
   
   -- Signals to output
   cs_uart <= not enable_uart;
   cs_pareg <= not enable_pareg;
   cs_ram <= not enable_ram;
   cs_buf <= not enable_buffer;
   bufdir <= not RnW;

end Behavioral;