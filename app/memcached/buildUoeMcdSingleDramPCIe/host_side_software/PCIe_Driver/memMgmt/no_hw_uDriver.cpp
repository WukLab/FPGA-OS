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


//provides the same functionality as the real uDriver, but
//instead of talking to hardware it just pretends
#include "uDriver.h"
uDriver::uDriver(char* devFileName){
    //could fork a new process here that simulates the hardware
};
uDriver::~uDriver(){
};
int uDriver::ReadReg(int offset){
    mtx.lock();
    int r=1000;
    for(int i=0;i<200000;i++)
        r/=i;
    mtx.unlock();
    return r;
};
void uDriver::WriteReg(int offset, int wdata){
    mtx.lock();
    int r=349;
     for(int i=0;i<200000;i++)
        r/=i;
    mtx.unlock();
};
int uDriver::WriteData(char* buff, int size){
    mtx.lock();
    int r=345;
     for(int i=0;i<200000;i++)
        r/=i;
    mtx.unlock();
    return 0;
};
int uDriver::ReadData(char *buff, int size){
    mtx.lock();
    int r=3234444;
     for(int i=0;i<200000;i++)
        r/=i;
    mtx.unlock();
    return 0;
};




void uDriver::WriteFree(free_regs_t which, uint32_t value){
    //WriteReg(0x30+4*which,value);
};
bool uDriver::ReadFree(free_regs_t which, uint32_t &ret){
//    ret=ReadReg(0x30+4*which);
//    return 0x80000000&ret;
    ret=0xf5ee0000+which;
    return false;
};

bool uDriver::ReadDel(uint32_t &ret){
//    ret=ReadReg(0x20);
//    return 0x80000000&ret;
    ret=0xde100000;
};

uint32_t uDriver::ReadStats_precise(stats_reg_t which){
//    return ReadReg(0x00+4*which);
    return 0x0000ffff;
};
double uDriver::ReadStats_percent(stats_reg_t which){
    uint32_t maxval=1<<22-1;
    uint32_t exact_val=ReadStats_precise(which);
    return (double)which/maxval*100;
};

bool uDriver::isFlushReq(){
    return false;
};
void uDriver::sendFlushAck(){

};
bool uDriver::isFlushDone(){

};

void uDriver::softwareControlledReset(){
};


uint32_t uDriver::ReadRev(){
//    return ReadReg(0xf0);
    return 99;
};
