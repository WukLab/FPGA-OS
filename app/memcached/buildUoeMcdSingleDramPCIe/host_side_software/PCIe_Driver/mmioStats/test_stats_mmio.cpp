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
//-- mounts the device file instead of using a proper driver
//--------------------------------------------------------------------------------
*/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <ctype.h>
#include <termios.h>

#include <endian.h>



#define NUM_T 32

void *memblk;

struct TransferData  {

        unsigned int data[NUM_T];

} *gReadData, *gWriteData;


/**reads a 64 bit wide register, gets it to host's endinness
and truncates to least significant 32 bit*/
int ReadReg32(uintmax_t offset){
    	void* adr = (void*) ((uintmax_t)memblk + offset);
	
	uint64_t ret=*((uint64_t *)adr);
	ret=be64toh(ret);
	//printf("%016jx\n",ret);
	
	//int ret = le32toh(*((uint32_t *)adr));
	return (int)ret;
}


/** expand to 64 bit, convert to big endian, send 64bit reg to hw
*/
void WriteReg32(uintmax_t offset, uint32_t wdata){
    	 void* adr = (void*) ((uintmax_t)memblk + offset);
	 wdata=(uint64_t) wdata;
 	 *((uint64_t *)adr) = htobe64(wdata);
	 // *((uint32_t *)adr) = htole32(wdata);
}

int main(int argc, char *argv[])
{
  int priv2;
  struct stat sb;

  if (argc !=2) {
    printf("Usage: mmio_stats <Region_file>\n\n");
    exit(-1);
  }
  
  if ((priv2 = open(argv[1], O_RDWR)) < 0) {
    printf("Can not open %s\n",argv[1]);
    exit(-1);
  }

  fstat(priv2, &sb);
  //printf("size of bar: %d\n",sb.st_size);
  
  memblk = mmap(NULL,sb.st_size, PROT_WRITE|PROT_READ, MAP_SHARED, priv2, 0);
  if (memblk == MAP_FAILED) {
    printf("Can not mmap %s\n",argv[1]);
    exit(-1);
  }

  printf("\n\n##############################\n\n");
  		     //0x2000100
  void* rwAdd=(void*) (0x2000000+0x100);
  int x=ReadReg32((uintmax_t)rwAdd);
  printf("IBM Memached demo bitstream revision %d\n",x);
  
  printf("\n\n##############################\n\n");
	
  printf("write test:write 12345678 to c0 \n");
  	
  WriteReg32(0x2000000+0xc0, 0x12345678);
  
  x=ReadReg32(0x2000000+0xc0);
  printf("read test: read from c0:  %08x",x);
 
  printf("\n\n##############################\n\n");
  


  //for version with memory management over pcie, provide 2 addresses
  WriteReg32(30, 0);
  WriteReg32(30, 4);
  WriteReg32(34, 0x10);
  WriteReg32(34, 0x14);
  
  //check the 4 stats registers, will be occasionally nonzero when ethernet exercised
  //the stats values in the hardware are generated like this:
  	//if data line busy, increase counter1
  	//always increase counter2
  	//if counter2 overflows, reset both, write value of counter1 to software readable register
  //counter2 has 22 bits => max value 2^22-1, so busy percentage is s0/((1<<22)-1)*100;
  
  int maxval=(1<<22)-1;
  for(;;){
  	int s0=ReadReg32(0x2000000+0x00);//stats0
  	int s1=ReadReg32(0x2000000+0x00+0x10);//stats1
  	int s2=ReadReg32(0x2000000+0x00+0x20);//stats2
  	int s3=ReadReg32(0x2000000+0x00+0x30);//stats3
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
  
  munmap(memblk,sb.st_size);
  close(priv2);
}
