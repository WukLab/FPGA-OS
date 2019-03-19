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
//-- Filename: kernel.h
//--
//-- Description: Useful definitions for OpenCL Host-side
//--
//-- Sample driver for the Memcached demo
//-- Writes and reads to/from all relevant device registers
//--
//--opens the device file instead of talking to driver
//--------------------------------------------------------------------------------
*/

#ifndef TEMPLATE_H_
#define TEMPLATE_H_




#include <CL/cl.h>
#include <string.h>
#include <cstdlib>
#include <iostream>
#include <string>
#include <fstream>


// GLOBALS
#define SDK_SUCCESS 0
#define SDK_FAILURE 1

/*
 * Input data is stored here.
 */
cl_uint *input;
cl_uint *output;
cl_uint multiplier;
cl_uint width;
cl_mem  inputBuffer;
cl_mem	outputBuffer;
cl_context          context;
cl_device_id        *devices;
cl_command_queue    commandQueue;
cl_program program;
cl_kernel  kernel;


// FUNCTION DECLARATIONS

int initializeCL(void);
std::string convertToString(const char * filename);
int runCLKernels(void);
int cleanupCL(void);
void cleanupHost(void);

#endif  /* #ifndef TEMPLATE_H_ */
