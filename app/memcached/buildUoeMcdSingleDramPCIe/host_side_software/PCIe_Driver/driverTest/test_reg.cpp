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
//-- Filename: test_reg.cpp
//--
//-- Description: 
//--              
//-- Sample driver for the Memcached demo
//-- Writes and reads to/from all relevant device registers
//--             
//--
//--------------------------------------------------------------------------------
*/

#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <errno.h>

#include "xpcie.h"

#define NUM_T 32

char devname[] = "/dev/xpcie";
int g_devFile = -1;

struct TransferData  {

        unsigned int data[NUM_T];

} *gReadData, *gWriteData;


int ReadReg(int offset){
    
	xpcie_arg_t* q=(xpcie_arg_t*) malloc(sizeof(xpcie_arg_t));
	(*q).offset=offset;
	(*q).rdata=0x55;//will be overwritten, is just a sanity check
	(*q).wdata=0x66;//not used for read,   is just a sanity check
	
	int ret=ioctl(g_devFile,XPCIE_READ_REG,q);//XPCIE_READ_REG is a constant defined in xpcie.h
	if(ret){
		printf("error while reading pcie. offset:%x  error:%x\n",offset,ret);
	}
	//printf("got back offs=%x   rdata=%x    wdata=%x    rcode %d\n",(*q).offset,(*q).rdata,(*q).wdata,ret);
	return ((*q).rdata);
}

void WriteReg(int offset, int wdata){
    
	xpcie_arg_t* q=(xpcie_arg_t*) malloc(sizeof(xpcie_arg_t));
	(*q).offset=offset;
	(*q).rdata=0x55;//not used for write,  is just a sanity check
	(*q).wdata=wdata;
	
	int ret=ioctl(g_devFile,XPCIE_WRITE_REG,q);
	if(ret){
		printf("error while writing pcie. offset:%x  error:%x\n",offset,ret);
	}
	//printf("got back offs=%x   rdata=%x    wdata=%x    rcode %d\n",(*q).offset,(*q).rdata,(*q).wdata,ret);
}

//bulk read from beginning of device memory. Not really needed
int WriteData(char* buff, int size)
{
        int ret = write(g_devFile, buff, size);
                                                                                
        return (ret);
}

//bulk write to beginning of device memory Not really needed
int ReadData(char *buff, int size)
{
        int ret = read(g_devFile, buff, size);

        return (ret);
}

int main()
{
  int i, j;

  char* devfilename = devname;
  g_devFile = open(devfilename, O_RDWR);

  if ( g_devFile < 0 )  {
    printf("Error opening device file\n");
    return 0;
  }

  /*gReadData = (TransferData  *) malloc(sizeof(struct TransferData));	
  gWriteData = (TransferData  *) malloc(sizeof(struct TransferData));	*/
  
  //read address must be 4-aligned to yield proper result
  //ReadReg(0x8);
  // ReadReg(0xffc);//4k     if you go over 0xffc, bad things happen
  
  
  //addresses of FREE regs: 0x30, 0x34, 0x38, 0x3C
	
  //when the FREE regs are written to, the circuit gets notified of the fresh value
  //when the FREE regs are read from, the most significant bit tells if the fifo is full
  	//the other 31 bits hold the value that was written in the last write to the reg
  
  printf("\n\n##############################\n\n");
  int x=ReadReg(0xf0);
  printf("IBM Memcached Power8 Demo: Bitstream revision number: %x\n",x);
  
  
  for(int rwnum=0;rwnum<4;rwnum++){
	  printf("\n\n##############################\n\n");
	  int rwAdd=4*rwnum+0x30;
	  printf("reading free%d from %x\n",rwnum+1,rwAdd);
	  int x=ReadReg(rwAdd);
	  printf("read result: %x\n",x);
	  
	  printf("writing 0xCAFECAFE to free%d at %x\n",rwnum+1,rwAdd);
	  WriteReg(rwAdd,0xCAFECAFE);
	  
	  printf("reading free%d from %x    ",rwnum+1,rwAdd);
	  x=ReadReg(rwAdd);
	  printf("read result: %x\n",x);
	  
	  bool wasFull=x&0x80000000;
	  printf("full flag in top bit was: %s",(wasFull?"true":"false"));
  }
  printf("\n\n##############################\n\n");
  //the DEL reg does nothing for now
  int rwAdd=0x20;
  x=ReadReg(rwAdd);
  printf("reading del from %x\n",rwAdd);
  printf("read result: %x\n",x);
	bool wasFull=x&0x80000000;
	printf("ety flag in top bit was: %s",(wasFull?"true":"false"));

 
  printf("\n\n##############################\n\n");
  
  //check the 4 stats registers, will be occasionally nonzero when ethernet exercised
  //the stats values in the hardware are generated like this:
  	//if data line busy, increase counter1
  	//always increase counter2
  	//if counter2 overflows, reset both, write value of counter1 to software readable register
  //counter2 has 22 bits => max value 2^22-1, so busy percentage is s0/((1<<22)-1)*100;
  
  int maxval=(1<<22)-1;
  for(;;){
  	int s0=ReadReg(0x0);//stats0
  	int s1=ReadReg(0x4);//stats1
  	int s2=ReadReg(0x8);//stats2
  	int s3=ReadReg(0xc);//stats3
  	double p0,p1,p2,p3;
  	p0=(double)s0/maxval*100;
  	p1=(double)s1/maxval*100;
  	p2=(double)s2/maxval*100;
  	p3=(double)s3/maxval*100;
  	
  	//if(s0!=0||x1!=0){
  	//	printf("stats0= %x    stats1= %x    stats2= %x    stats3= %x    ",s0,s1,s2,s3);
  	//}
  	
	//printf("stats0= %x    stats1= %x    stats2= %x    stats3= %x    \r",s0,s1,s2,s3);
  	printf("stats0= %3.2f%%    stats1= %3.2f%%    stats2= %3.2f%%    stats3= %3.2f%%    \r",p0,p1,p2,p3);
  	
  	
  }
}
