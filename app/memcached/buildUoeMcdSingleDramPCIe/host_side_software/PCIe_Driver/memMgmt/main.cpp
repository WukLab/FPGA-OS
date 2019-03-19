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


/*
this main file contains functions to run the protocols stepwise for debug purposes
in real operation, the the memManager object does all the work.
*/

#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include "uDriver.h"
#include "memManager.h"
#include <stdlib.h>

#include <unistd.h>

#include <thread>


#ifdef GUI
    #include "Gui.h"
#endif // GUI


//#define FILEOUT
using namespace std;




static uDriver *uDriver_i;
static memManager *memManager_i;
#ifdef GUI
static Gui *Gui_i;
#endif // GUI

void revNo(){
    //uDriver *uDriver_i=new uDriver();

    printf("\n\n##############################\n\n");
    int x=uDriver_i->ReadRev()&0x00ffffff;
    printf("Xilinx Memcached Demo: Bitstream revision number: %x\n",x);
    printf("pool0: %s    pool1: %s    pool2: %s    pool3: %s",POOL_0_USED?"active":"inactive",POOL_1_USED?"active":"inactive",POOL_2_USED?"active":"inactive",POOL_3_USED?"active":"inactive");
}

void place(){
    printf("\n\n##############################\n\n");

    uint32_t ret=0;

    printf("which queue (1 to 4) ? ");
    uint32_t which;
    scanf ("%x",&which);


    if(which>0 && which<=12){
        free_regs_t frwhich=(free_regs_t)(which-1);
        bool isfull=uDriver_i->ReadFree(frwhich,ret);
        printf("read free%x: %s  prev val:%x\n",which,(isfull?"full":"nonfull"),ret);

        printf("enter value");
        uint32_t val;
        scanf ("%x",&val);
        printf("write to free%x,  ",which);
        uDriver_i->WriteFree(frwhich, val);

        isfull=uDriver_i->ReadFree(frwhich,ret);

        printf("read free%x: %s  new val:%x\n",which,(isfull?"full":"nonfull"),ret);
    }
}

void get(){
    printf("\n\n##############################\n\n");
    printf("read from del,  ");
    uint32_t ret;
    bool ok=uDriver_i->ReadDel(ret);
    printf("result: %s  %x\n",(ok?"empty":"nonempty"),ret);

}

void sendReset(){
    uDriver_i->softwareControlledReset();
}

void checkStats(){

    printf("\n\n##############################\n\n");
    printf("read 4 stats values\n");
    printf("ingress        egress         dummy        dummy\n");
    for(;;){
        /*printf("\n\n##############################\n\n");
        printf("read 4 stats values\n");*/
        uint32_t st0,st1,st2,st3;
        st0=uDriver_i->ReadStats_precise(stats0);
        st1=uDriver_i->ReadStats_precise(stats1);
        st2=uDriver_i->ReadStats_precise(stats2);
        st3=uDriver_i->ReadStats_precise(stats3);
        //if(st0!=0)
        //    printf("raw:  %8x    %8x    %8x    %8x    \n",st0,st1,st2,st3);

        double p0,p1,p2,p3;
        p0=uDriver_i->ReadStats_percent(stats0);
        p1=uDriver_i->ReadStats_percent(stats1);
        p2=uDriver_i->ReadStats_percent(stats2);
        p3=uDriver_i->ReadStats_percent(stats3);
        //printf("     usage ratio :  %8.2f    %8.2f    %8.2f    %8.2f \r",p0,p1,p2,p3);


        //printf("raw:  %8x    %8x    %8x    %8x    ||",st0,st1,st2,st3);
        printf("%5.2f%%    %5.2f%%    %5.2f%%    %5.2f%% \r",p0,p1,p2,p3);
        //system("clear");
        //printf("\n\n##############################\n\n");
    }

}


int globalCounter=0;
void fillGarbage(){//quick and dirty testing
    //fill all 4 free queues
    uint32_t ret;


//    globalCounter+=0x100;
//
//
    int oldgc;
//
    if(POOL_0_USED){
        oldgc=globalCounter;
        while(!uDriver_i->ReadFree(free1,ret )){
                //uDriver_i->WriteFree(free1,0x11110000+i++);
                int val=globalCounter++;
                cout<<hex<<val<<endl;
                uDriver_i->WriteFree(free1,val);
        }
        cout<<"free1 filled with "<<globalCounter-oldgc<<" addresses"<<endl;
    }

    if(POOL_1_USED){
        oldgc=globalCounter;
        while(!uDriver_i->ReadFree(free2,ret )){
                //uDriver_i->WriteFree(free2,0x22220000+i++);
                int val=globalCounter++;
                cout<<hex<<val<<endl;
                uDriver_i->WriteFree(free2,val);
        }
        cout<<"free2 filled with "<<globalCounter-oldgc<<" addresses"<<endl;
    }
    if(POOL_2_USED){
            oldgc=globalCounter;
        while(!uDriver_i->ReadFree(free3,ret )){
                int val=globalCounter++;
                uDriver_i->WriteFree(free3,val);
        }
        cout<<"free3 filled with "<<globalCounter-oldgc<<" addresses"<<endl;
    }
    if(POOL_3_USED){
        oldgc=globalCounter;
        while(!uDriver_i->ReadFree(free4,ret )){
                int val=globalCounter++;
                uDriver_i->WriteFree(free4,val);
        }
        cout<<"free4 filled with "<<globalCounter-oldgc<<" addresses"<<endl;
    }

}

void flushprot(int what){
    switch(what){
    case 0:
        cout<<"is flush rq?   "<<uDriver_i->isFlushReq()<<endl;
        break;
    case 1:
        cout<<"sending flush ack "<<endl;
        uDriver_i->sendFlushAck();
        break;
    case 2:
        cout<<"is flush done?   "<<uDriver_i->isFlushDone()<<endl;
        break;
    }
}


void manage(){
    memManager_i->manage();
}


void runBackGround(){
    //will compile but fail without the -lpthread compiler option
    //for legible output, make sure memmanager_debug in memManager.cpp is not defined
    thread manT(manage);

    printf("\n\n##############################\n\n");
        printf("Ingress, egress           ||     unused memory addresses: \n");
    for(;;){
        double p0,p1,p2,p3;
        p0=uDriver_i->ReadStats_percent(stats0);
        p1=uDriver_i->ReadStats_percent(stats1);
        p2=uDriver_i->ReadStats_percent(stats2);
        p3=uDriver_i->ReadStats_percent(stats3);
        int us0,us1,us2,us3;
        memManager_i->getUsageExact(us0,us1,us2,us3);
        printf("%5.2f%%  |  %5.2f%%         ||     %4d  |  %4d  |  %4d  |  %4d  \r",p0,p1,p2,p3,us0,us1,us2,us3);
    }

    manT.join();//won't be reached, but nicer

}





void init(char* devFileName){
    uDriver_i=new uDriver(devFileName);
    memManager_i=new memManager(uDriver_i);
}

int main(int argc, char *argv[])
{
    system("clear");
    char* devFileName=(char*)"none";
    if(argc>1){
        devFileName=argv[argc-1];
        argc--;
    }
    #ifndef GUI
    init(devFileName);
    #endif
    #ifdef FILEOUT
    //continually overwrite a file with the stats.
    //a scripts can then scp the file to another pc where the "comanion gui" can display them
    //was needed because the IBM power 8 system in the demo had no graphical output
    while(true){
            FILE *pFile;
            pFile=fopen("rawdata_host.dat","w+");
             double p0,p1;
             int revno;
            p0=uDriver_i->ReadStats_percent(stats0);
            p1=uDriver_i->ReadStats_percent(stats1);
            revno=uDriver_i->ReadRev()&0x00ffffff;
            printf("%f %f %x\n",p0,p1,revno);
            fprintf(pFile,"%f %f %x\n",p0,p1,revno);
            fclose(pFile);
            //sleep(1);
            usleep(1000);
    }
    #else
    #ifdef GUI
    Gui *Gui_i=new Gui(devFileName);
    return Gui_i->start(argc,argv);
    #else

    /*
    //pretty command line without any interaction:
    printf("###################################################################\n\n");
    printf("Xilinx IBM Power8 Key Value Store Demo\n\n");
    printf("###################################################################\n\n");
    printf("Revision number: %2d\n\n",uDriver_i->ReadRev()&0x00ffffff);
    printf("Ingress pipeline utilization     |     Egress pipeline utilization\n");
    while(true){
        double p0,p1;
        p0=uDriver_i->ReadStats_percent(stats0);
        p1=uDriver_i->ReadStats_percent(stats1);
        printf("        %5.2f%%                   |            %5.2f%%             \r",p0,p1);
    }*/
    while(true){
        cout<<"what would you like to do?"<<endl;
        //cout<<"enter 'i' to init"<<endl;
        cout<<"enter 'd' to display rev. no. and some other stuff"<<endl;
        cout<<"enter 's' to check 4 stats regs continuous"<<endl;
        cout<<"enter 'p' to write one value to a free list"<<endl;
        cout<<"enter 'g' to get one value from del list"<<endl;
        cout<<"enter 'f' to fill all free lists once"<<endl<<endl;
        cout<<"enter 'm' to run memory manager only"<<endl;
        cout<<"enter 'b' to run memory manager and stats checker"<<endl;
        cout<<"press 'r' for software controlled reset *"<<endl;
        cout<<"enter 'u' to check flush req *"<<endl;
        cout<<"enter 'i' to send flush ack *"<<endl;
        cout<<"enter 'o' to check flushDone *"<<endl;
        cout<<"enter 'e' to exit"<<endl;
        cout<<"* not supported on older bitstreams"<<endl<<endl;
        char sel;
        cin>>sel;
        switch(sel){
        case 'd':
            revNo();
            break;
        case 's':
            checkStats();
            break;
        case 'm':
            manage();
            break;
        case 'g':
            get();
            break;
        case 'p':
            place();
            break;
        case 'f':
            fillGarbage();
            break;
        case 'b':
            runBackGround();
            break;
        case 'u':
            flushprot(0);
            break;
        case 'i':
            flushprot(1);
            break;
        case 'o':
            flushprot(2);
            break;
        case 'r':
            sendReset();
            break;
        case 'e':
            return 0;
        default:
            break;
        }
        cout<<endl<<endl<<endl;
    }
    #endif // GUI
    #endif // FILEOUT
    return 0;
}
