// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Tue Mar  5 15:15:43 2024
// Host        : LAPTOP-ESNLEJG4 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/aless/OneDrive/Documenti/GitHub/ada/Progetto-Finale-ADA/generate_frame/generate_frame.gen/sources_1/ip/blk_mem_gen_3/blk_mem_gen_3_stub.v
// Design      : blk_mem_gen_3
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *)
module blk_mem_gen_3(clka, ena, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,addra[13:0],douta[11:0]" */;
  input clka;
  input ena;
  input [13:0]addra;
  output [11:0]douta;
endmodule
