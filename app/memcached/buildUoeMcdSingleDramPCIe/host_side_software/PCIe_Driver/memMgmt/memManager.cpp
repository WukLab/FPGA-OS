/*-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
    --
    -- This file contains confidential and proprietary information
    -- of Xilinx, Inc. and is protected under U.S. and
    -- international copyright and other intellectual property
    -- laws.
    --
    -- DISCLAIMER
    -- This disclaimer is not a license and does not grant any
    -- rights to the materials distributed herewith. Except-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
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
    -- PART OF THIS FILE AT ALL TIMES. as
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

#include "memManager.h"
#include "stdio.h"

//#define MEMMANAGER_DEBUG TRUE
#define MEMMANAGER_DEGUG_L1 TRUE

#ifdef MEMMANAGER_DEGUG_L1
#define L1dprintf(...) printf(__VA_ARGS__)
#else
#define L1dprintf(...) {}
#endif // MEMMANAGER_DEBUG


#ifdef MEMMANAGER_DEBUG
#define L1dprintf(...) printf(__VA_ARGS__)
#define dprintf(...) printf(__VA_ARGS__)
#else
#define dprintf(...) {}
#endif // MEMMANAGER_DEBUG

//record values that have changed status since the gui last checked. Do not record if we have no gui.
#ifdef GUI
#define makedirty(dirtylist,address,whereto) dirtylist .push_back(make_pair(address,whereto));
#else
#define makedirty(dirtylist,address,whereto) ;
#endif


//fill a single pool
#define fillpool(which) \
    printf("pool %d\n",which);\
    for(uint32_t i=0; i<pool##which##size; i++)\
    {\
        uint32_t temp_address=POOL_##which##_START+i*pool##which##gran;\
        m_lpFreePool##which ->push_back(temp_address);\
        makedirty( m_dirties##which ,temp_address,software);\
    }\
    for(uint32_t i=pool##which##size;i<pool##which##size+MEDIUM*NUM_MEDIUM;i+=MEDIUM){\
        uint32_t temp_address=POOL_##which##_START+i*pool##which##Mgran;\
        m_lpFreePool##which##M ->push_back(temp_address);\
    }\
   for(uint32_t i=pool##which##size+MEDIUM*NUM_MEDIUM;i<pool##which##size+MEDIUM*NUM_MEDIUM+LARGE*NUM_LARGE;i+=LARGE){\
        uint32_t temp_address=POOL_##which##_START+i*pool##which##Lgran;\
        m_lpFreePool##which##L ->push_back(temp_address);\
   }\



using namespace std;

memManager::memManager(uDriver *lpDriver)
{

    dprintf("making the memmanager\n");

    stopflag=0;
    m_lpuDriver=lpDriver;

    //prepare the address maps
    m_lpFreePool0=new deque<uint32_t>();
    m_lpFreePool1=new deque<uint32_t>();
    m_lpFreePool2=new deque<uint32_t>();
    m_lpFreePool3=new deque<uint32_t>();

    m_lpFreePool0M=new deque<uint32_t>();
    m_lpFreePool1M=new deque<uint32_t>();
    m_lpFreePool2M=new deque<uint32_t>();
    m_lpFreePool3M=new deque<uint32_t>();

    m_lpFreePool0L=new deque<uint32_t>();
    m_lpFreePool1L=new deque<uint32_t>();
    m_lpFreePool2L=new deque<uint32_t>();
    m_lpFreePool3L=new deque<uint32_t>();

    //hardware is not prepared for pool 2 and 3, so just ignore

    //decide on the granularities of the different address types

    //check the version register
    //use Macro to decode version register

    //decide on pool sizes for each value size (small med large)
    //default size means no medium or large
    //decide on pool descriptions

    pool0gran=1;
    pool0Mgran=MEDIUM;
    pool0Lgran=LARGE;
    pool1gran=P0P1TRESHOLD;
    pool1Mgran=MEDIUM*pool1gran;
    pool1Lgran=LARGE*pool1gran;



    uint32_t versionReg=m_lpuDriver->ReadRev();
    if(POOL_0_DRAM(versionReg)){
        sprintf(pool0desc,"DRAM: capacity %8d GB",DRAM_MEMSIZE);
        pool0size=DRAM_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool0Msize=NUM_MEDIUM;
        pool0Lsize=NUM_LARGE;
    }else if(POOL_0_SSD(versionReg)){
        sprintf(pool0desc,"SSD : capacity %8d GB",SSD_MEMSIZE);
        pool0size=SSD_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool0Msize=NUM_MEDIUM;
        pool0Lsize=NUM_LARGE;
    }else if(POOL_0_HOST(versionReg)){
        sprintf(pool0desc,"Host : capacity %8d GB",HOST_MEMSIZE);
        pool0size=HOST_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool0Msize=NUM_MEDIUM;
        pool0Lsize=NUM_LARGE;
    }else{
        sprintf(pool0desc,"BRAM");
        pool0size=DEFAULT_POOL_SIZE;
        pool0Msize=0;
        pool0Lsize=0;
    }
    if(POOL_1_DRAM(versionReg)){
        sprintf(pool1desc,"DRAM: capacity %8d GB",DRAM_MEMSIZE);
        pool1size=DRAM_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool0Msize=NUM_MEDIUM;
        pool0Lsize=NUM_LARGE;
    }else if(POOL_1_SSD(versionReg)){
        sprintf(pool1desc,"SSD : capacity %8d GB",SSD_MEMSIZE);
        pool1size=SSD_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool0Msize=NUM_MEDIUM;
        pool0Lsize=NUM_LARGE;
    }else if(POOL_1_HOST(versionReg)){
        sprintf(pool1desc,"Host : capacity %8d GB",HOST_MEMSIZE);
        pool1size=HOST_POOL_SIZE-NUM_MEDIUM*MEDIUM-NUM_LARGE*LARGE;
        pool1Msize=NUM_MEDIUM;
        pool1Lsize=NUM_LARGE;
    }else{
        sprintf(pool1desc,"BRAM");
        pool1size=DEFAULT_POOL_SIZE;
        pool0Msize=0;
        pool0Lsize=0;
    }

    fillPools();

    printf("fp0 start:  %x\n",m_lpFreePool0->front());
    printf("fp1 start:  %x\n",m_lpFreePool1->front());
}



memManager::~memManager()
{
    //dtor
    delete m_lpFreePool0;
    delete m_lpFreePool1;
    delete m_lpFreePool2;
    delete m_lpFreePool3;
}

void memManager::fillPools()
{
    fp0_mtx.lock();
    fp1_mtx.lock();
    fp2_mtx.lock();
    fp3_mtx.lock();
    printf("filling pools\n");

    if(POOL_0_USED)
    {
        fillpool(0)
    }
    if(POOL_1_USED)
    {
        fillpool(1)
    }
    if(POOL_2_USED)
    {
        fillpool(2)
    }
    if(POOL_3_USED)
    {
        fillpool(3)

    }
    fp0_mtx.unlock();
    fp1_mtx.unlock();
    fp2_mtx.unlock();
    fp3_mtx.unlock();
}

int memManager::getPoolSize(pool which){
    switch(which){
        case p0:
        return pool0size;
        case p1:
        return pool1size;
        case p2:
        return pool2size;
        case p3:
        return pool3size;
        default:
        return -1;
    }
}
const char* memManager::getPoolDescription(pool which){
    switch(which){
        case p0:
        return pool0desc;
        case p1:
        return pool1desc;
        case p2:
        return "debug";
        case p3:
        return "debug";
        default:
        return "error";
    }
}

void memManager::stopManage(){
    stopflag=1;
}

void memManager::managesingle(deque<uint32_t> * thelist,vector<pair<uint32_t,entrystatus> > &thedirty, free_regs_t freeFifo, mutex *themtx){
    uint32_t ret;
    if(!m_lpuDriver->ReadFree(freeFifo,ret )){
            dprintf("space in free fifo %d available     ",freeFifo);
            themtx->lock();
            if(!thelist->empty())
            {
                L1dprintf("writing to fifo%x: %x\n",freeFifo,thelist->front());
                m_lpuDriver->WriteFree(freeFifo,thelist->front());//push value to fifo
                makedirty(thedirty,thelist->front(),hardware);//record for the gui
                thelist->pop_front();//pop from driver's pool

            }
            else
            {
                dprintf("nothing to write \n");
            }
            themtx->unlock();
        }
        else{
            dprintf("no space in free fifo %d\n",freeFifo);
        }
}


void memManager::manage()
{
    uint32_t ret;
    //try to push to all FREE fifos, try to read DEL fifo
    //put result of DEL back into appropriate FREE list.
    for(;!stopflag;)
    {
        //top up the full fifos with some mem locations of free memory
        if(POOL_0_USED)
        {
            managesingle(m_lpFreePool0,m_dirties0,free1,&fp0_mtx);
            managesingle(m_lpFreePool0M,m_dirties0,free1M,&fp0_mtx);
            managesingle(m_lpFreePool0L,m_dirties0,free1L,&fp0_mtx);

        }

        if(POOL_1_USED)
        {
           managesingle(m_lpFreePool1,m_dirties1,free2,&fp1_mtx);
           managesingle(m_lpFreePool1M,m_dirties1,free2M,&fp1_mtx);
           managesingle(m_lpFreePool1L,m_dirties1,free2L,&fp1_mtx);
        }

        if(POOL_2_USED)
        {
            managesingle(m_lpFreePool2,m_dirties2,free3,&fp2_mtx);
            managesingle(m_lpFreePool2M,m_dirties2,free3M,&fp2_mtx);
            managesingle(m_lpFreePool2L,m_dirties2,free3L,&fp2_mtx);
        }


        if(POOL_3_USED)
        {
            managesingle(m_lpFreePool3,m_dirties3,free4,&fp3_mtx);
            managesingle(m_lpFreePool3M,m_dirties3,free4,&fp3_mtx);
            managesingle(m_lpFreePool3L,m_dirties3,free4,&fp3_mtx);
        }

        if(FLUSHPROTOCOL){
            //check for flush signal
            if(m_lpuDriver->isFlushReq()){
                L1dprintf("flush required\n");
                //send flush ack
                m_lpuDriver->sendFlushAck();
                L1dprintf("sending flushack\n");
                //reset address pools
                fp0_mtx.lock();
                fp1_mtx.lock();
                fp2_mtx.lock();
                fp3_mtx.lock();
                m_lpFreePool0->clear();
                m_lpFreePool1->clear();
                m_lpFreePool3->clear();
                m_lpFreePool3->clear();
                fp0_mtx.unlock();
                fp1_mtx.unlock();
                fp2_mtx.unlock();
                fp3_mtx.unlock();
                fillPools();
                //poll for flush done
                L1dprintf("waiting for flushdone\n");
                while(!m_lpuDriver->isFlushDone());
                L1dprintf("flush done\n");
                //continue normal operation
            }
        }



        //pop from the empty fifo, find where to put it back.
        if(!m_lpuDriver->ReadDel(ret))
        {
            //find out which memory device ret is from, put it back into pool

            memManager::memKind wf=whereFrom(ret);
            dprintf("del not empty     ");
            L1dprintf("read from del queue: %x\n",ret);


            switch(wf)
            {
            case POOL0:
                fp0_mtx.lock();
                if(m_lpFreePool0->back()==ret){//paranoid check. TODO: eliminate the underlying hardware bug, remove check
                    printf("duplicate read #################\n");
                    exit(-1);
                }else{
                    m_lpFreePool0->push_back(ret);
                    makedirty(m_dirties0,ret,software);
                }
                fp0_mtx.unlock();
                break;
            case POOL0M:
                fp0_mtx.lock(); m_lpFreePool0M->push_back(ret); fp0_mtx.unlock(); break;
            case POOL0L:
                fp0_mtx.lock(); m_lpFreePool0L->push_back(ret); fp0_mtx.unlock(); break;
            case POOL1:
                fp1_mtx.lock();
                m_lpFreePool1->push_back(ret);
                 makedirty(m_dirties1,ret,software);
                fp1_mtx.unlock();
                break;
            case POOL1M:
                fp1_mtx.lock(); m_lpFreePool1M->push_back(ret); fp1_mtx.unlock(); break;
            case POOL1L:
                fp1_mtx.lock(); m_lpFreePool1L->push_back(ret); fp1_mtx.unlock(); break;
            case POOL2:
                fp2_mtx.lock();
                m_lpFreePool2->push_back(ret);
                makedirty(m_dirties2,ret,software);
                fp2_mtx.unlock();
                break;
            case POOL3:
                fp3_mtx.lock();
                m_lpFreePool3->push_back(ret);
                makedirty(m_dirties3,ret,software);
                fp3_mtx.unlock();
                break;
            case FLUSHING:
                L1dprintf("Return address is an old style flush req: address ffffffff. Check your bitstream.\n");
                break;
            default:
                L1dprintf("illegal memory address returned from HW del list: %x\n",ret);
            }
        }
        else
        {
            dprintf("del empty, ret=%x\n",ret);
        }

        mtx.lock();
        fp0_mtx.lock();
        fp1_mtx.lock();
        fp2_mtx.lock();
        fp3_mtx.lock();
        usageValues[0]=m_lpFreePool0->size();
        usageValues[1]=m_lpFreePool1->size();
        usageValues[2]=m_lpFreePool2->size();
        usageValues[3]=m_lpFreePool3->size();
        fp0_mtx.unlock();
        fp1_mtx.unlock();
        fp2_mtx.unlock();
        fp3_mtx.unlock();
        mtx.unlock();
    }
    stopflag=0;//ready for next start
}

//determine where the returned address came from by decoding the value
//TODO: find out if return address is from one of the M or L queues as well
//right now M and L queue values get flagged as ILLEGAL
memManager::memKind memManager::whereFrom(uint32_t address)
{
    if(address==FLUSHSIGNAL)//obsolete flush signal (return address ffffffff)
    {
        return FLUSHING;
    }
    uint32_t p0end=POOL_0_START+pool0size;
    uint32_t p0mEnd=p0end+pool0Msize*pool0Mgran;
    uint32_t p0lEnd=p0mEnd+pool0Lsize*pool0Lgran;
    if(address>=POOL_0_START)
    {
        if(address<p0end)
            return POOL0;
        else if(address<p0mEnd)
            return POOL0M;
        else if(address<p0lEnd)
            return POOL0L;
    }

    uint32_t p1end=POOL_1_START+pool1size;
    uint32_t p1mEnd=p1end+pool1Msize*pool1Mgran;
    uint32_t p1lEnd=p1mEnd+pool1Lsize*pool1Lgran;
    if(address>=POOL_0_START)
    {
        if(address<p1end)
            return POOL1;
        else if(address<p1mEnd)
            return POOL1M;
        else if(address<p1lEnd)
            return POOL1L;
    }

    //pool 2 and 3 are not implemented in hardware, so these are left simple
    if(address>=POOL_2_START && address<POOL_2_START+pool2size)
    {
        return POOL2;
    }
    else if(address>=POOL_3_START && address<POOL_3_START+pool3size)
    {
        return POOL3;
    }
    else
    {
        return ILLEGAL;
    }
}

void memManager::getUsageExact(int &use0, int &use1, int &use2, int &use3)
{

    mtx.lock();
    use0=usageValues[0];
    use1=usageValues[1];
    use2=usageValues[2];
    use3=usageValues[3];
    mtx.unlock();
}

//returns a list of all changes since last call of this function.
//Is used to update the GUI.
void memManager::getDirtyList(pool which, vector<pair<uint32_t,entrystatus> > *rdirties){
    //lock the appropriate mutex, copy values over, clean the list.
    //should get called only to update the tile diagram
    switch(which)
    {
    case p0:
        fp0_mtx.lock();
        rdirties->assign(m_dirties0.begin(),m_dirties0.end());
        m_dirties0.clear();
        fp0_mtx.unlock();
        break;
    case p1:
        fp1_mtx.lock();
        rdirties->assign(m_dirties1.begin(),m_dirties1.end());
        m_dirties1.clear();
        fp1_mtx.unlock();
        break;
    case p2:
        fp2_mtx.lock();
        rdirties->assign(m_dirties2.begin(),m_dirties2.end());
        m_dirties2.clear();
        fp2_mtx.unlock();
        break;
    case p3:
        fp3_mtx.lock();
        rdirties->assign(m_dirties3.begin(),m_dirties3.end());
        m_dirties3.clear();
        fp3_mtx.unlock();
        break;
    }
}

