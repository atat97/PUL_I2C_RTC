library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RTC is
    Port(
        SDA : inout std_logic;
        SCL : out std_logic;
        CLK : in std_logic;
        R_n : in std_logic;
        BUSY : out std_logic;
        ADDRESS : in std_logic_vector(7 downto 0);
        DATA_WR : in std_logic_vector(7 downto 0);
        DATA_RD : out std_logic_vector(7 downto 0);
        ENA_n : in std_logic      
        );
end RTC;

architecture RTC_arch of RTC is

signal address_s : std_logic_vector(7 downto 0); -- bajt zawierajacy adres i kierunek transmisji
-- osobne adresy dla godzin, minut i sekund;
type STATES is (Idle,Read_Address,GetHr,GetMin,GetSec,SetHr,SetMin,SetSec);
signal STATE : STATES := Idle;

signal DATA : std_logic_vector(7 downto 0) := (others =>'0');
signal BIT_INDEX: integer range 0 to 7 := 7;

signal an_flag1,an_flag2,done_reading : boolean := false;

begin
Process1: process(SCL)
begin
    if rising_edge(SCL) then
        case STATE is
            when Idle =>
                if(R_n = '1') then
                    STATE <= Idle;
                else
                    --SDA <= ENA_n;               
                    if(SDA = '0' and SCL = '1') then --wykrycie bitu startu
                        STATE <= Read_Address;
                    else
                        SDA <= '1'; --stan wysoki na lini danych ciagle nadawany przez slave????
                        STATE <= Idle;
                    end if;
                end if;
            when Read_Address =>
                --odebranie adresu
                address_s(BIT_INDEX) <= SDA;
                if(BIT_INDEX > 0) then
                    BIT_INDEX <= BIT_INDEX - 1;
                    STATE <= Read_Address;
                else
                    BIT_INDEX <= 7;
                    case address_s is   -- 
                        when "00010001" => STATE <= GetHr;  --adres 7
                        when "00011011" => STATE <= GetMin; --adres 13  --bit R/W = 1
                        when "00100111" => STATE <= GetSec; --adres 19
                        
                        when "00010000" => STATE <= SetHr;  
                        when "00011010" => STATE <= SetMin; --jw. --bit R/W = 0
                        when "00100110" => STATE <= SetSec;
                        
                        when others => STATE <= Idle;
                    end case;
                end if;
                
            when GetHr =>
                DATA <= Hr;
                SDA <= '0'; --pierwszy bit aknowledge
                SDA <= DATA(BIT_INDEX);
                if(BIT_INDEX > 0) then
                    BIT_INDEX <= BIT_INDEX - 1;
                    STATE <= GetHr;
                else
                    BIT_INDEX <= 7;
                    SDA <= '1'; --drugi bit aknowledge
                    STATE <= Idle;
                end if;
            when GetMin =>
                DATA <= Min;
                SDA <= '0'; --pierwszy bit aknowledge
                SDA <= DATA(BIT_INDEX);
                if(BIT_INDEX > 0) then
                    BIT_INDEX <= BIT_INDEX - 1;
                    STATE <= GetMin;
                else
                    BIT_INDEX <= 7;
                    SDA <= '1'; --drugi bit aknowledge
                    STATE <= Idle;
                end if;
            when GetSec =>
                DATA <= Sec;
                SDA <= '0'; --pierwszy bit aknowledge
                SDA <= DATA(BIT_INDEX);
                if(BIT_INDEX > 0) then
                    BIT_INDEX <= BIT_INDEX - 1;
                    STATE <= GetSec;
                else
                    BIT_INDEX <= 7;
                    SDA <= '1'; --drugi bit aknowledge
                    STATE <= Idle;
                end if;
                
            --To by by³o rozwi¹zane tutaj-- wartoœci wprowadzane przez uzytkownika
            when SetHr =>       --Tutaj jeszcze trwaj¹ prace
                if (SDA = '0' and an_flag1 = false) then --sprawdzenie 1. bitu aknowledge
                    an_flag1 <= true;
                    STATE <= SetHr;
                elsif(an_flag1 <= true and done_reading = false) then
                    DATA(BIT_INDEX) <= SDA;
                    if(BIT_INDEX > 0) then
                        BIT_INDEX <= BIT_INDEX - 1;
                        STATE <= SetHr;
                    else
                        BIT_INDEX <= 7;
                        done_reading <= true;
                        STATE <= SetHr;
                    
                elsif(SDA = '1') then
                    an_flag2 <= true;
                    Hr <= DATA;
                    
                    STATE <= Idle;
            when SetMin =>
            
            when SetSec =>
                    
            when others =>
                STATE <= Idle; 
        end case;
    end if;
end process Process1;


-- proces licz¹cy czas up³ywaj¹cy
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

SCL_gen: process
begin
SCL <= not SCL after 5000 ns;
end process SCL_gen;

end RTC_arch;