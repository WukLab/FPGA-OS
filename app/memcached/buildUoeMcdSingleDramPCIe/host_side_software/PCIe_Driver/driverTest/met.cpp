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
//-- Filename: met.cpp
//--
//-- Description: 
//--              
//-- Sample memory endpoint test program for the XPCIE device driver.              
//--              
//--              
//--              
//--
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

char devname[] = "/dev/xpcie";
int g_devFile = -1;

struct TransferData  {

        unsigned int data[2048];

} *gReadData, *gWriteData;


int WriteData(char* buff, int size)
{
        int ret = write(g_devFile, buff, size);
                                                                                
        return (ret);
}

int ReadData(char *buff, int size)
{
        int ret = read(g_devFile, buff, size);

        return (ret);
}

int main()
{
  int i, j;
  int iter_count = 1000000;

  char* devfilename = devname;
  g_devFile = open(devfilename, O_RDWR);

  if ( g_devFile < 0 )  {
    printf("Error opening device file\n");
    return 0;
  }

  gReadData = (TransferData  *) malloc(sizeof(struct TransferData));	
  gWriteData = (TransferData  *) malloc(sizeof(struct TransferData));	

  for (j = 0; j < iter_count; j++) 
  {
    for(i=0; i<2048; i++)
      gWriteData->data[i]=rand();

    WriteData((char*) gWriteData, 8192);
    //WriteData((char*) gWriteData, 4);

    ReadData((char *) gReadData, 8192);
    //ReadData((char *) gReadData, 4);

    for(i=0; i<2048; i++) {
    //for(i=0; i<1; i++) {
      if (gReadData->data[i] != gWriteData->data[i])
        printf("DWORD miscompare [%d] -> expected %x : found %x \n", i, gWriteData->data[i], gReadData->data[i]);
    }

    if ((j % 1000) == 0)
      printf("Pass #[%d]\n", j);
  }
}
