/*
-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
    --
    -- This file contains confidential and proprietary information
    -- of Xilinx, Inc. and is protected under U.S. and
    -- international copyright and other intellectual property
    -- laws.
    --
    -- DISCLAIMER
    -- This disclaimer is not a license and does not grant any
    -- rights to the materials distributed herewith. Except as
    -- otherwise provided in a valid license issued to you by
    -- Xilinx, and to the maximum extent permitted by applicable
    -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
    -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
    -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
    -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
    -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
    -- (2) Xilinx shall not be liable (whether in contract or tort,
    -- including negligence, or under any other theory of
    -- liability) for any loss or damage of any kind or nature
    -- related to, arising under or in connection with these
    -- materials, including for any direct, or any indirect,
    -- special, incidental, or consequential loss or damage
    -- (including loss of data, profits, goodwill, or any type of
    -- loss or damage suffered as a result of any action brought
    -- by a third party) even if such damage or loss was
    -- reasonably foreseeable or Xilinx had been advised of the
    -- possibility of the same.
    --
    -- CRITICAL APPLICATIONS
    -- Xilinx products are not designed or intended to be fail-
    -- safe, or for use in any application requiring fail-safe
    -- performance, such as life-support or safety devices or
    -- systems, Class III medical devices, nuclear facilities,
    -- applications related to the deployment of airbags, or any
    -- other applications that could lead to death, personal
    -- injury, or severe property or environmental damage
    -- (individually and collectively, "Critical
    -- Applications"). Customer assumes the sole risk and
    -- liability of any use of Xilinx products in Critical
    -- Applications, subject only to applicable laws and
    -- regulations governing limitations on product liability.
    --
    -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
    -- PART OF THIS FILE AT ALL TIMES.
*/

/**
* This header defines all functions a valid user driver should offer to te rest of the application.
* The makefile determines which implementation is actually used.
* uDriver.cpp is the recommended implementation that communicates with a custom character device.
**/


#ifndef UDRIVER_H
#define UDRIVER_H


#include <stdint.h>
#include <mutex>
#include <sys/stat.h>


enum free_regs_t
{
    free1=0,
    free2=1,
    free3=2,
    free4=3,
    free1M=4,
    free2M=5,
    free3M=6,
    free4M=7,
    free1L=8,
    free2L=9,
    free3L=10,
    free4L=11,
};

enum stats_reg_t
{
    stats0=0,
    stats1=1,
    stats2=2,
    stats3=3
};

//provides primitives to talk with the Memcached hardware over PCIe
class uDriver
{
public:
    uDriver(char* devFileName);
    virtual ~uDriver();

    void WriteFree(free_regs_t which, uint32_t value);
    bool ReadFree(free_regs_t which, uint32_t &ret);//returns if free list is full and the previously written value

    bool ReadDel(uint32_t &ret);

    uint32_t ReadStats_precise(stats_reg_t which);
    double ReadStats_percent(stats_reg_t which);


    bool isFlushReq();
    void sendFlushAck();
    bool isFlushDone();

    void softwareControlledReset();

    uint32_t ReadRev();

protected:

private:
    int ReadReg(int offset);
    void WriteReg(int offset, int wdata);
    int WriteData(char* buff, int size);
    int ReadData(char *buff, int size);

    void *memblk;//only for device file based access
    struct  stat sb;//only for device file based access

    int g_devFile;


    void* argpt;
    std::mutex mtx;

};

#endif // UDRIVER_H
