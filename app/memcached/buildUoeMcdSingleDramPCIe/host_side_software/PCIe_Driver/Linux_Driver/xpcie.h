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
//--            ** Copyright (C) 2014, Xilinx, Inc. **
//--            ** All Rights Reserved.             **
//--            **************************************
//--
//--------------------------------------------------------------------------------
//-- Filename: xpcie.h
//--
//-- Description: contains definitions for the ioctl syscall
//--
//--             
//--
//--------------------------------------------------------------------------------
*/


//definitions for communication with the pcie controller for VC709

#ifndef XPCIE_DEFS
#define XPCIE_DEFS

typedef struct
{
	int offset,rdata,wdata;
} xpcie_arg_t;

//macros to get integers to identify different ioctl commands
//It's the UNIX way.
#define XPCIE_READ_REG _IOR('Q', 1, int)
#define XPCIE_WRITE_REG _IOR('Q', 2, int)

#endif
