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

#ifndef MEMMANAGER_H
#define MEMMANAGER_H

#include "uDriver.h"
#include <stdint.h>
#include <vector>
#include <stack>
#include <list>
#include <mutex>
#include <thread>

#define FLUSHPROTOCOL true

#define FLUSHSIGNAL 0x7fffffff

//Careful: bottom 1024 (0x400) ram lines (65 536 bytes, 0x10000) are reserved for hash table
//a few bits on top for everything except DRAM get discarded. check the hardware design
//all addresses are indices to 64 byte blocks, hardware takes care of the rest.
//hardware disregards the top nibble for actual addressing, so that can be used to tag addresses.

#define POOL_0_USED true
//#define POOL_0_SIZE  128
#define POOL_0_START 0x00001000   //leaves bottom 4k lines empty, better to have some headroom there.

#define POOL_1_USED true
//#define POOL_1_SIZE  128
#define POOL_1_START 0x10000000


//pool 2 and 3 for possible future versions with more different kinds of memory simultaneously.
#define POOL_2_USED false
//#define POOL_2_SIZE  128
#define POOL_2_START 0x20000000

#define POOL_3_USED false
//#define POOL_3_SIZE  128
#define POOL_3_START 0x30000000

//masks to find out information about the memcached from the version register
#define POOL_0_DRAM(version_reg) version_reg&0x10000000
#define POOL_0_SSD(version_reg) version_reg&0x20000000
#define POOL_0_HOST(version_reg) version_reg&0x40000000
#define POOL_1_DRAM(version_reg) version_reg&0x01000000
#define POOL_1_SSD(version_reg) version_reg&0x02000000
#define POOL_1_HOST(version_reg) version_reg&0x04000000

#define DEFAULT_POOL_SIZE 128

//how many distinct addresses for each type of memory possible. One per 64 bytes possible.
#define DRAM_POOL_SIZE 8*1024
#define SSD_POOL_SIZE  32*1024
#define HOST_POOL_SIZE 32*1024

//we keep 3 address queues for each memory: one each for small, medium and large values
//For byte addressable storage, hardware multiplies address with 64
//therefore smallest granularity is 1 address on 64bytes (512 bit)

//values smaller than treshold go to pool0, larger to pool1.

#define P0P1TRESHOLD 4096

#define SMALL 1         //'small' category values in pool0 get 64 bytes. 'small' in pool 1 gets P0P1TRESHOLD
#define MEDIUM 8        //medium values get 8 times as much space
#define LARGE  32      //large values get 32 times as much space

#define NUM_MEDIUM  10//number of medium sized memory slots in each pool
#define NUM_LARGE  2//number of large sized memory slots in each pool
//rest is for small slots

//sizes in GB as displayed. Allows for a bit of cheating.
#define DRAM_MEMSIZE   8
#define SSD_MEMSIZE  512
#define HOST_MEMSIZE  512


//-if over 1G entries, the address queues start to fill main memory and trashing happens.
//-currently no visualisation if over 160 k total entries to stop the gui from becoming unresponsive
//#define DRAM_POOL_SIZE 0x07fff000  // 8GB/64 -4kB        dimm has 2 GB, ramline is 512B, leave room for hash table
//#define SSD_POOL_SIZE  0x200000000UL  //512GB/64
//#define SSD_POOL_SIZE 0x800000000
enum pool{
    p0,
    p1,
    p2,
    p3
};

enum entrystatus{
    software,
    hardware,
    broken
};


using namespace std;
class memManager
{
    public:
        memManager(uDriver *lpDriver);
        virtual ~memManager();
        //commence managing the device's memory. Blocks until stop flag is set.
        //todo: refactor so thread creation is part of this function instead of caller
        void manage();
        void stopManage();

        void getUsageExact(int &use0, int &use1, int &use2, int &use3);

        //get all entries that changed since last call to getDirtyList. thread safe.
        void getDirtyList(pool which, vector<pair<uint32_t,entrystatus> > *rdirties);//only for the fancy visualisation

        int getPoolSize(pool which);
        const char* getPoolDescription(pool which);
    protected:
    private:
        //sizes of the 4*3 lists of addresses
        uint64_t pool0size,pool1size,pool2size,pool3size;
        uint64_t pool0Msize,pool1Msize,pool2Msize,pool3Msize;
        uint64_t pool0Lsize,pool1Lsize,pool2Lsize,pool3Lsize;

        //all the 4*3 granularities
        uint64_t pool0gran,pool0Mgran,pool0Lgran;
        uint64_t pool1gran,pool1Mgran,pool1Lgran;
        uint64_t pool2gran,pool2Mgran,pool2Lgran;
        uint64_t pool3gran,pool3Mgran,pool3Lgran;


        //textual descriptions
        char pool0desc[30];
        char pool1desc[30];

        void fillPools();//initial fill of empty pools
        void managesingle(deque<uint32_t> * thelist,vector<pair<uint32_t,entrystatus> > &thedirty, free_regs_t freeFifo, mutex *themtx);

        uDriver *m_lpuDriver;

        volatile int stopflag;//stop manager loop (unused)

        //Free addresses in software
        deque<uint32_t> *m_lpFreePool0,*m_lpFreePool1,*m_lpFreePool2,*m_lpFreePool3;
        deque<uint32_t> *m_lpFreePool0M,*m_lpFreePool1M,*m_lpFreePool2M,*m_lpFreePool3M;
        deque<uint32_t> *m_lpFreePool0L,*m_lpFreePool1L,*m_lpFreePool2L,*m_lpFreePool3L;
        mutex fp0_mtx;   //for exclusive access to the pools. For simplicicy, small, M and L share a mutex
        mutex fp1_mtx;
        mutex fp2_mtx;
        mutex fp3_mtx;

        mutex mtx;       //for exclusive access to the usage values
        int usageValues[4];

        //record changes since gui checked in last. Ignores M and L for now
        vector<pair<uint32_t,entrystatus> > m_dirties0;
        vector<pair<uint32_t,entrystatus> > m_dirties1;
        vector<pair<uint32_t,entrystatus> > m_dirties2;
        vector<pair<uint32_t,entrystatus> > m_dirties3;

        enum memKind{
            FLUSHING,
            POOL0,
            POOL1,
            POOL2,
            POOL3,
            POOL0M,
            POOL1M,
            POOL2M,
            POOL3M,
            POOL0L,
            POOL1L,
            POOL2L,
            POOL3L,
            ILLEGAL
        };

        memKind whereFrom(uint32_t address);


};
#endif // MEMMANAGER_H
