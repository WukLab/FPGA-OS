RTL TOP 
    axi_mmu_wrapper

Modules
    addr_ch_rx
    This is the receiving part (AXI slave) of MMU that gets the wr/rd addresses from some source.
    This has a buffer that will read in whenever the valid and ready are high. The buffer is read
    from whenever a translation completes. 
    
    addr_ch_tx 
    this is the transmitter (AXI master) of MMU that will send wr/rd with translated address to
    the destination the packet was intended for. Will get all fields from the Receiver module and 
    the physical address and a notification that translation is done.
    
    Wdat_ch 
    single RX/TX part for write data. Once translation is done it start reading from its local 
    buffer till it gets to the last beat of data (*LAST signal of AXI WDATA channel).
    
    Rdat_ch 
    single RX/TX for the read responses. As long as the buffer is not empty it will read and send. 
    Read till the last data beat is seen and if the buffer is not empty then read again the next cycle.
    
    Wresp/B_ch 
    simple buffer based RX/TX. Keep sending back the responses as long as there is any response available.

Translator
    This is brain of the MMU. Will get the virtual address from the *_channel_rx.
    It should do two translation read and write simultaneously. The translation is always
    in-order. Should access BRAM/LUT to get hit/miss/translation_offset info. 
    If hit then send a done with physical address back and *_ch_tx will use these to send 
    the packet to memory controller/next step.
    If miss is expected to be handled then a fault handler should be invoked. 
    This fault handler might invoke memory traffic. TODO :: Add a way to handle the mem-traffic.

Updates
    Hook-up with existing setup - Done
    Move to single clock design - WIP
    Burst/Real traffic simulation - WIP


***** NOTE *****
single port AXI so only one master can send and only Mem-Controller can be connected as slave.
If extra master/MC requirement arise add interconnect at desired end with suitable arbitration.
