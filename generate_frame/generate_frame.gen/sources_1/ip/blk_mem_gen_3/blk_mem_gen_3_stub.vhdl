-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Wed Dec 13 14:31:27 2023
-- Host        : thisguy running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/angelonutu/Desktop/ADA2.0/Progetto-Finale-ADA/generate_frame/generate_frame.gen/sources_1/ip/blk_mem_gen_3/blk_mem_gen_3_stub.vhdl
-- Design      : blk_mem_gen_3
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity blk_mem_gen_3 is
  Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    addra : in STD_LOGIC_VECTOR ( 13 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 11 downto 0 )
  );

end blk_mem_gen_3;

architecture stub of blk_mem_gen_3 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,ena,addra[13:0],douta[11:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";
begin
end;