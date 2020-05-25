library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RTC_slave is
        Port ( 
        SDA : inout std_logic;
        SCL : in std_logic
        );
end RTC_slave;

architecture RTC_slave_arch of RTC_slave is

signal Hr,Min,Sec: std_logic_vector(7 downto 0) := (others =>'0');
signal CLK_COUNT: std_logic_vector(16 downto 0) := (others =>'0');

begin














Counting: process(SCL)
begin
--f = 400kHz => 1100001101010000000
--f = 50MHz =>  10111110101111000010000000

--f = 100kHz => 100 000 taktów zegara na sekundê => 11000011010100000
--T = 10us
if rising_edge(SCL) then
    CLK_COUNT <= CLK_COUNT + "01";
    if(CLK_COUNT = "11000011010100000") then
        CLK_COUNT <= (others => '0');
        Sec <= Sec + "01";  
    end if;
    if(Sec = "00111100") then 
        Sec <= (others =>'0');
        Min <= Min + "01";
    end if;
    if(Min = "00111100") then
        Min <= (others => '0');
        Hr <= Hr + "01";
    end if;
    if(Hr = "00011000") then
        Hr <= (others => '0');
    end if;
end if;
end process Counting;
end RTC_slave_arch;
