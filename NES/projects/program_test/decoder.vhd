----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:55:34 11/17/2015 
-- Design Name: 
-- Module Name:    decoder - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder is
    Port ( sel : in  STD_LOGIC_VECTOR (2 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0));
end decoder;

architecture Behavioral of decoder is

begin

	y <= 	"00000001" when sel = "000" else
			"00000010" when sel = "001" else
			"00000100" when sel = "010" else
			"00001000" when sel = "011" else
			"00010000" when sel = "100" else
			"00100000" when sel = "101" else
			"01000000" when sel = "110" else
			"10000000";

end Behavioral;

