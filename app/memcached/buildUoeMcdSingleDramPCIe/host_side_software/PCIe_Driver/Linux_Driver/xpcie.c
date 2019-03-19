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
//-- Filename: xpcie.c
//--
//-- Description: XPCIE device driver.
//--
//-- XPCIE is an example Red Hat device driver for the PCI Express Memory
//-- Endpoint Reference design. Device driver has been tested on fedora
//-- 2.6.18.
//--
//--
//-- changed to act as driver for memory management over pcie.
//-- works with all versions of the hardware that use the "pcie2axilite" core from xapp 1201
//--
//--------------------------------------------------------------------------------
*/

#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/fs.h>
#include <asm/uaccess.h>   /* copy_to_user */
#include <asm/io.h>


//definition of struct for ioctl
#include "xpcie.h"


// semaphores
enum  {
        SEM_READ,
        SEM_WRITE,
        SEM_WRITEREG,
        SEM_READREG,
        SEM_WAITFOR,
        SEM_DMA,
        NUM_SEMS
};

//semaphores
struct semaphore gSem[NUM_SEMS];


MODULE_LICENSE("Dual BSD/GPL");

// Max DMA Buffer Size

#define BUF_SIZE                  4096

#define PCI_VENDOR_ID_XILINX      0x10ee
#define PCI_DEVICE_ID_XILINX_PCIE 0x0007
#define KINBURN_REGISTER_SIZE     (4*8)    // There are eight registers, and each is 4 bytes wide.
#define HAVE_REGION               0x01     // I/O Memory region
#define HAVE_IRQ                  0x02     // Interupt
#define SUCCESS                   0
#define CRIT_ERR                  -1

//Status Flags:
//       1 = Resouce successfully acquired
//       0 = Resource not acquired.
#define HAVE_REGION 0x01               // I/O Memory region
#define HAVE_IRQ    0x02               // Interupt
#define HAVE_KREG   0x04               // Kernel registration

int             gDrvrMajor = 240;      // Major number not dynamic. Must be same as in make_device script
unsigned int    gStatFlags = 0x00;     // Status flags used for cleanup.
unsigned long long   gBaseHdwr;             // Base register address (Hardware address)
unsigned long   gBaseLen;              // Base register address Length
void           *gBaseVirt = NULL;      // Base register address (Virtual address, for I/O).
char            gDrvrName[]= "xpcie";   // Name of driver in proc.
struct pci_dev *gDev = NULL;           // PCI device structure.
int             gIrq;                  // IRQ assigned by PCI system.
char           *gBufferUnaligned = NULL;   // Pointer to Unaligned DMA buffer.
char           *gReadBuffer      = NULL;   // Pointer to dword aligned DMA buffer.
char           *gWriteBuffer     = NULL;   // Pointer to dword aligned DMA buffer.

xpcie_arg_t     *ioctl_arg		 = NULL;   //points to data structure for ioctl calls



//-----------------------------------------------------------------------------
// Prototypes
//-----------------------------------------------------------------------------
void    XPCIe_IRQHandler (int irq, void *dev_id, struct pt_regs *regs);
void    initcode(void);
u32     XPCIe_ReadReg (u32 dw_offset);
void    XPCIe_WriteReg (u32 dw_offset, u32 val);
u32 XPCIe_ReadCfgReg (u32 byte);


/*****************************************************************************
 * Name:        XPCIe_Open
 *
 * Description: Book keeping routine invoked each time the device is opened.
 *
 * Arguments: inode :
 *            filp  :
 *
 * Returns: 0 on success, error code on failure.
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/
int XPCIe_Open(struct inode *inode, struct file *filp)
{
    //MOD_INC_USE_COUNT;
    printk("%s: Open: module opened\n",gDrvrName);
    return SUCCESS;
}

/*****************************************************************************
 * Name:        XPCIe_Release
 *
 * Description: Book keeping routine invoked each time the device is closed.
 *
 * Arguments: inode :
 *            filp  :
 *
 * Returns: 0 on success, error code on failure.
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/
int XPCIe_Release(struct inode *inode, struct file *filp)
{
    //MOD_DEC_USE_COUNT;
    printk("%s: Release: module released\n",gDrvrName);
    return(SUCCESS);
}

/***************************************************************************
 * Name:        XPCIe_Write
 *
 * Description: This routine is invoked from user space to write data to
 *              the 3GIO device.
 *
 * Arguments: filp  : file pointer to opened device.
 *            buf   : pointer to location in users space, where data is to
 *                    be acquired.
 *            count : Amount of data in bytes user wishes to send.
 *
 * Returns: SUCCESS  = Success
 *          CRIT_ERR = Critical failure
 *          TIME_ERR = Timeout
 *          LINK_ERR = Link Failure
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/
ssize_t XPCIe_Write(struct file *filp, const char *buf, size_t count,
                       loff_t *f_pos)
{
	int ret = SUCCESS;
	memcpy((char *)gBaseVirt, buf, count);
	printk("%s: XPCIe_Write: %d bytes have been written...\n", gDrvrName, (int)count);
	return (ret);
}

/***************************************************************************
 * Name:        XPCIe_Read
 *
 * Description: This routine is invoked from user space to read data from
 *              the 3GIO device. ***NOTE: This routine returns the entire
 *              buffer, (BUF_SIZE), count is ignored!. The user App must
 *              do any needed processing on the buffer.
 *
 * Arguments: filp  : file pointer to opened device.
 *            buf   : pointer to location in users space, where data is to
 *                    be placed.
 *            count : Amount of data in bytes user wishes to read.
 *
 * Returns: SUCCESS  = Success
 *          CRIT_ERR = Critical failure
 *          TIME_ERR = Timeout
 *          LINK_ERR = Link Failure
 *
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/
ssize_t XPCIe_Read(struct file *filp, char *buf, size_t count, loff_t *f_pos)
{
	printk("enter XPCIe Read\n");
	memcpy(buf, (char *)gBaseVirt, count);
	printk("%s: XPCIe_Read: %d bytes have been read...\n", gDrvrName, (int)count);
	return (0);
}

/***************************************************************************
 * Name:        XPCIe_Ioctl
 *
 * Description: This routine is invoked from user space to configure the
 *              running driver.
 *
 * Arguments: inode :
 *            filp  : File pointer to opened device.
 *            cmd   : Ioctl command to execute, constants defined in xpcie.h
 *            arg   : Argument to Ioctl command.
 *
 * Returns: 0 on success, error code on failure.
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 * march 2014 Stephan Koster    adding functionality to read/write single register at arbitrary offset from base address register
 ****************************************************************************/
ssize_t XPCIe_Ioctl(struct file *filp, unsigned int cmd,
                   unsigned long arg)
{

    //treat arg as pointer to xpcie_arg_t which holds offset,rdata,wdata.
	//get the data structure from the user
	if(copy_from_user(ioctl_arg,(char*)arg,sizeof(xpcie_arg_t))){
        printk("%s: XPCIe_ioctl: Failed copy from user.\n",gDrvrName);
        return -1;
	}
	//check output with dmesg|grep xpcie_ioctl
	//printk(/*KERN_WARNING*/"%s_ioctl: cmd:%x offs:%d wdata:%x rdata:%x \n", gDrvrName, cmd,(*ioctl_arg).offset,(*ioctl_arg).wdata,(*ioctl_arg).rdata);

	//printk("Expecting %x or %x\n", XPCIE_READ_REG, XPCIE_WRITE_REG);
	//find out what userland driver wants to do
	switch(cmd){
		case XPCIE_READ_REG:
			(*ioctl_arg).rdata=XPCIe_ReadReg ((*ioctl_arg).offset);
		break;
		case XPCIE_WRITE_REG:
			XPCIe_WriteReg ((*ioctl_arg).offset, (*ioctl_arg).wdata);
		break;
		default:
			printk("Unexpected cmd: %x\n", cmd);
			return -EINVAL;
	}

	//push the data structure back to the user (may be unnecessary for write)
	if(copy_to_user((char*)arg,ioctl_arg,sizeof(xpcie_arg_t))){
        printk("%s: XPCIe_ioctl: Failed copy from user.\n",gDrvrName);
        return -1;
	}

    return 0;
}
//previous: ioctl instead of unlocked_ioctl
struct file_operations XPCIe_Intf = {
    read:       XPCIe_Read,
    write:      XPCIe_Write,
    unlocked_ioctl:      XPCIe_Ioctl,
    compat_ioctl: XPCIe_Ioctl,
    open:       XPCIe_Open,
    release:    XPCIe_Release,
};




static int XPCIe_init(void)
{
	//previous: pci_find_device
    gDev = pci_get_device (PCI_VENDOR_ID_XILINX, PCI_DEVICE_ID_XILINX_PCIE, gDev);
    if (NULL == gDev) {
        printk(/*KERN_WARNING*/"%s: Init: Hardware not found.\n", gDrvrName);
        //return (CRIT_ERR);
        return (-1);
    }

    if (0 > pci_enable_device(gDev)) {
        printk(/*KERN_WARNING*/"%s: Init: Device not enabled.\n", gDrvrName);
        //return (CRIT_ERR);
        return (-1);
    }

    // Get Base Address of registers from pci structure. Should come from pci_dev
    // structure, but that element seems to be missing on the development system.
    gBaseHdwr = pci_resource_start (gDev, 0);
    if (0 > gBaseHdwr) {
        printk(/*KERN_WARNING*/"%s: Init: Base Address not set.\n", gDrvrName);
        //return (CRIT_ERR);
        return (-1);
    }
    printk(/*KERN_WARNING*/"Base hw val %llx\n", gBaseHdwr);

    gBaseLen = pci_resource_len (gDev, 0);
    printk(/*KERN_WARNING*/"Base hw len %d\n", (unsigned int)gBaseLen);

    // Remap the I/O register block so that it can be safely accessed.
    // I/O register block starts at gBaseHdwr and is 32 bytes long.
    // It is cast to char because that is the way Linus does it.
    // Reference "/usr/src/Linux-2.4/Documentation/IO-mapping.txt".

    gBaseVirt = ioremap(gBaseHdwr, gBaseLen);
    if (!gBaseVirt) {
        printk(/*KERN_WARNING*/"%s: Init: Could not remap memory.\n", gDrvrName);
        //return (CRIT_ERR);
        return (-1);
    }

    printk(/*KERN_WARNING*/"Virt hw val %p\n", gBaseVirt);

    // Get IRQ from pci_dev structure. It may have been remapped by the kernel,
    // and this value will be the correct one.

    gIrq = gDev->irq;
    printk("irq: %d\n",gIrq);

    //--- START: Initialize Hardware

    // Try to gain exclusive control of memory for demo hardware.
    if (0 > check_mem_region(gBaseHdwr, KINBURN_REGISTER_SIZE)) {
        printk(/*KERN_WARNING*/"%s: Init: Memory in use.\n", gDrvrName);
        //return (CRIT_ERR);
        return (-1);
    }

    request_mem_region(gBaseHdwr, KINBURN_REGISTER_SIZE, "3GIO_Demo_Drv");
    gStatFlags = gStatFlags | HAVE_REGION;

    printk(/*KERN_WARNING*/"%s: Init:  Initialize Hardware Done..\n",gDrvrName);

    // Request IRQ from OS.
#if 0
    if (0 > request_irq(gIrq, &XPCIe_IRQHandler,/* SA_INTERRUPT |*/ SA_SHIRQ, gDrvrName, gDev)) {
        printk(/*KERN_WARNING*/"%s: Init: Unable to allocate IRQ",gDrvrName);
        return (-1);
    }
    gStatFlags = gStatFlags | HAVE_IRQ;
#endif

    initcode();

	//allocate ioctl arg structure
	ioctl_arg = kmalloc(sizeof(xpcie_arg_t), GFP_KERNEL);

    //--- END: Initialize Hardware

    //--- START: Allocate Buffers

    gBufferUnaligned = kmalloc(BUF_SIZE, GFP_KERNEL);

    gReadBuffer = gBufferUnaligned;
    if (NULL == gBufferUnaligned) {
        printk(KERN_CRIT"%s: Init: Unable to allocate gBuffer.\n",gDrvrName);
        return (-1);
    }

    gWriteBuffer = kmalloc(BUF_SIZE, GFP_KERNEL);
    if (NULL == gWriteBuffer) {
        printk(KERN_CRIT"%s: Init: Unable to allocate gBuffer.\n",gDrvrName);
        return (-1);
    }

    //--- END: Allocate Buffers

    //--- START: Register Driver
    // Register with the kernel as a character device.
    // Abort if it fails.
    if (0 > register_chrdev(gDrvrMajor, gDrvrName, &XPCIe_Intf)) {
        printk(KERN_WARNING"%s: Init: will not register\n", gDrvrName);
        return (CRIT_ERR);
    }
    printk(KERN_INFO"%s: Init: module registered\n", gDrvrName);
    gStatFlags = gStatFlags | HAVE_KREG;

    printk("%s driver is loaded\n", gDrvrName);

  return 0;
}

static void XPCIe_exit(void)
{

  if (gStatFlags & HAVE_REGION) {
     (void) release_mem_region(gBaseHdwr, KINBURN_REGISTER_SIZE);}

    // Release IRQ
    if (gStatFlags & HAVE_IRQ) {
        (void) free_irq(gIrq, gDev);
    }


    // Free buffer
    if (NULL != gReadBuffer)
        (void) kfree(gReadBuffer);
    if (NULL != gWriteBuffer)
        (void) kfree(gWriteBuffer);

    gReadBuffer = NULL;
    gWriteBuffer = NULL;


    if (gBaseVirt != NULL) {
        iounmap(gBaseVirt);
     }

    gBaseVirt = NULL;


    // Unregister Device Driver
    if (gStatFlags & HAVE_KREG) {
	unregister_chrdev(gDrvrMajor, gDrvrName);
//        if (unregister_chrdev(gDrvrMajor, gDrvrName) > 0) {
//            printk(KERN_WARNING"%s: Cleanup: unregister_chrdev failed\n",
//                   gDrvrName);
//        }
    }

    gStatFlags = 0;

  printk(/*KERN_ALERT*/ "%s driver is unloaded\n", gDrvrName);
}

module_init(XPCIe_init);
module_exit(XPCIe_exit);

void XPCIe_IRQHandler(int irq, void *dev_id, struct pt_regs *regs)
{
}

void initcode(void)
{
}

u32 XPCIe_ReadReg (u32 dw_offset)
{
        u32 ret = 0;
	void *reg_addr  = gBaseVirt + dw_offset;

        //ret = readb((void*)reg_addr);
	//printk("Reading reg from %p\n", (void*)reg_addr);

	ret=readl((void*) reg_addr);

        return ret;
}

void XPCIe_WriteReg (u32 dw_offset, u32 val)
{
        void *reg_addr = gBaseVirt + dw_offset;
        //writeb(val, (void*)reg_addr);
	//printk("Writing to %p\n", reg_addr);
        writel(val, (void*)reg_addr);
}

//unused example code
ssize_t* XPCIe_ReadMem(char *buf, size_t count)
{

    int ret = 0;
    dma_addr_t dma_addr;

    //make sure passed in buffer is large enough
    if ( count < BUF_SIZE )  {
      printk("%s: XPCIe_Read: passed in buffer too small.\n", gDrvrName);
      ret = -1;
      goto exit;
    }

    down(&gSem[SEM_DMA]);

    // pci_map_single return the physical address corresponding to
    // the virtual address passed to it as the 2nd parameter

    dma_addr = pci_map_single(gDev, gReadBuffer, BUF_SIZE, PCI_DMA_FROMDEVICE);
    if ( 0 == dma_addr )  {
        printk("%s: XPCIe_Read: Map error.\n",gDrvrName);
        ret = -1;
        goto exit;
    }

    // Now pass the physical address to the device hardware. This is now
    // the destination physical address for the DMA and hence the to be
    // put on Memory Transactions

    // Do DMA transfer here....

    printk("%s: XPCIe_Read: ReadBuf Virt Addr = %x Phy Addr = %x.\n", gDrvrName, (unsigned int)gReadBuffer, (unsigned int)dma_addr);

    // Unmap the DMA buffer so it is safe for normal access again.
    pci_unmap_single(gDev, dma_addr, BUF_SIZE, PCI_DMA_FROMDEVICE);

    up(&gSem[SEM_DMA]);

    // Now it is safe to copy the data to user space.
    if ( copy_to_user(buf, gReadBuffer, BUF_SIZE) )  {
        ret = -1;
        printk("%s: XPCIe_Read: Failed copy to user.\n",gDrvrName);
        goto exit;
    }
    exit:
      return ((ssize_t*)ret);
}

//unused example code
ssize_t XPCIe_WriteMem(const char *buf, size_t count)
{
    int ret = 0;
    dma_addr_t dma_addr;

    if ( (count % 4) != 0 )  {
       printk("%s: XPCIe_Write: Buffer length not dword aligned.\n",gDrvrName);
       ret = -1;
       goto exit;
    }

    // Now it is safe to copy the data from user space.
    if ( copy_from_user(gWriteBuffer, buf, count) )  {
        ret = -1;
        printk("%s: XPCIe_Write: Failed copy to user.\n",gDrvrName);
        goto exit;
    }

    //set DMA semaphore if in loopback
    down(&gSem[SEM_DMA]);

    // pci_map_single return the physical address corresponding to
    // the virtual address passed to it as the 2nd parameter

    dma_addr = pci_map_single(gDev, gWriteBuffer, BUF_SIZE, PCI_DMA_FROMDEVICE);
    if ( 0 == dma_addr )  {
        printk("%s: XPCIe_Write: Map error.\n",gDrvrName);
        ret = -1;
        goto exit;
    }

    // Now pass the physical address to the device hardware. This is now
    // the source physical address for the DMA and hence the to be
    // put on Memory Transactions

    // Do DMA transfer here....

    printk("%s: XPCIe_Write: WriteBuf Virt Addr = %x Phy Addr = %x.\n", gDrvrName, (unsigned int)gReadBuffer, (unsigned int)dma_addr);

    // Unmap the DMA buffer so it is safe for normal access again.
    pci_unmap_single(gDev, dma_addr, BUF_SIZE, PCI_DMA_FROMDEVICE);

    up(&gSem[SEM_DMA]);

    exit:
      return (ret);
}

//unused example code
u32 XPCIe_ReadCfgReg (u32 byte)
{
   u32 pciReg;
   if (pci_read_config_dword(gDev, byte, &pciReg) < 0) {
        printk("%s: XPCIe_ReadCfgReg: Reading PCI interface failed.",gDrvrName);
        return (-1);
   }
   return (pciReg);
}
