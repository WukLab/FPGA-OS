/*
//--------------------------------------------------------------------------------
//--
//-- This file is owned and controlled by Xilinx and must be used solely
//-- for design, simulation, implementation and creation of design files
//-- limited to Xilinx devices or technologies. Use with non-Xilinx
//-- devices or technologies is expressly prohibited and immediately
//-- terminates your license.
//--
//-- Xilinx products are not intended for use in life support
//-- appliances, devices, or systems. Use in such applications is
//-- expressly prohibited.
//--
//--            **************************************
//--            ** Copyright (C) 2006, Xilinx, Inc. **
//--            ** All Rights Reserved.             **
//--            **************************************
//--
//--------------------------------------------------------------------------------
//-- Filename: kernel.cl
//--
//-- Description: Goes to the trouble of calling an
//-- OpenCL kernel to compute a percentage
//--
//-- Sample driver for the Memcached demo
//-- Writes and reads to/from all relevant device registers
//--
//--opens the device file instead of talking to driver
//--------------------------------------------------------------------------------
*/


__kernel void fractionize(__global  double * output,
                             __global  double * input)
{
    uint tid = get_global_id(0);

    if(tid == 0)
        output[tid] = input[tid] / (double)((1<<22)-1) * 100;

}

