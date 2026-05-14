# RO PUF Implementation on FPGA
Implementation of a Ring Oscillator Physical Unclonable Function (PUF) on Xilinx Zynq-7000 series FPGAs, evaluated on a PYNQ-Z2 and Zybo board.

## Contents
- Necessary .vhd files and constraints
- puf_data contains 98 runs from PYNQ-Z2, capture.tcl (Vivado TCL script for automated data collection) and analyze_all_boards.py (Multi-board analysis including uniqueness)
- puf_data_zybo contains Zybo collected responses (13 runs)
- analysis_results_all_boards.txt is the result of running analyze_all_boards.py for this data

## Reference
G. E. Suh and S. Devadas, "Physical Unclonable Functions for Device Authentication and Secret Key Generation," DAC 2007.
