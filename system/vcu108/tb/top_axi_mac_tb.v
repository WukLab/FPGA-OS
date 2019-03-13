// -----------------------------------------------------------------------------
// Description: This testbench will exercise the ports of the Axi Ethernet core
//              to demonstrate the functionality.
//------------------------------------------------------------------------------
//
// This testbench performs the following operations on the Axi Ethernet core
// and its design example, depending upon the testbench mode (DEMO or BIST):

//  - The MDIO interface will respond to a read request with data to prevent the
//    example design thinking it is real hardware

//  "DEMO" Mode
//  - Four frames are then pushed into the receiver from the PHY
//    interface (GMII/MII or RGMII):
//    The first is of minimum length (Length/Type = Length = 46 bytes).
//    The second frame sets Length/Type to Type = 0x8000.
//    The third frame has an error inserted.
//    The fourth frame only sends 4 bytes of data: the remainder of the
//    data field is padded up to the minimum frame length i.e. 46 bytes.

//  - These frames are then parsed from the MAC into the MAC's design
//    example.  The design example provides a MAC user loopback
//    function so that frames which are received without error will be
//    looped back to the MAC transmitter and transmitted back to the
//    testbench.  The testbench verifies that this data matches that
//    previously injected into the receiver.

//  - The four frames are then re-sent at 100Mb/s, 10Mb/s and finally 1Gb/s again.
//
//  "BIST" Mode
//  - The internal pattern generator and pattern checker are enabled
//    with data being looped back at the PHY interface.

//  - the testbench is allowed to run for a set time.

//  - Any errors are captured and both the pass/fail status and the AVB bandwidth
//    displayed at the end of the test.

// DEMO Mode
//----------------------------------------------------------------------
//                         DEMONSTRATION TESTBENCH                     |
//                                                                     |
//                                                                     |
//     ----------------------------------------------                  |
//     |           TOP LEVEL WRAPPER (DUT)          |                  |
//     |  -------------------    ----------------   |                  |
//     |  | USER LOOPBACK   |    | AXI          |   |                  |
//     |  | DESIGN EXAMPLE  |    | ETHERNET     |   |                  |
//     |  |                 |    | CORE         |   |                  |
//     |  |                 |    |              |   |       Monitor    |
//     |  |         ------->|--->|          Tx  |-------->  Frames     |
//     |  |         |       |    |          PHY |   |                  |
//     |  |         |       |    |          I/F |   |                  |
//     |  |         |       |    |              |   |                  |
//     |  |         |       |    |              |   |                  |
//     |  |         |       |    |              |   |                  |
//     |  |         |       |    |          Rx  |   |                  |
//     |  |         |       |    |          PHY |   |                  |
//     |  |         --------|<---|          I/F |<-------- Generate    |
//     |  |                 |    |              |   |      Frames      |
//     |  -------------------    ----------------   |                  |
//     --------------------------------^-------------                  |
//                                     |                               |
//                                     |                               |
//                                 Stimulate                           |
//                               Management I/F                        |
//                               (if present)                          |
//                                                                     |
//----------------------------------------------------------------------

// BIST Mode
//--------------------------------------------------------------------------
//                             DEMONSTRATION TESTBENCH                     |
//                                                                         |
//                                                                         |
//     --------------------------------------------------                  |
//     |              TOP LEVEL WRAPPER (DUT)           |                  |
//     |  -----------------------    ----------------   |                  |
//     |  | BIST                |    | AXI          |   |                  |
//     |  | DESIGN EXAMPLE      |    | ETHERNET     |   |                  |
//     |  |                     |    | CORE         |   |                  |
//     |  |  -------   -------  |    |              |   |                  |
//     |  |  |     |-->|  F  |->|--->|              |   |                  |
//     |  |  | pat |   |  I  |  |    | L            |   |                  |
//     |  |  | gen |   |  F  |  |    | E            |   |                  |
//     |  |  |     |   |  O  |  |    | G            |   |                  |
//     |  |  -------   -------  |    | A            |   |                  |
//     |  |  -------   -------  |    | C        Tx  |-------->             |
//     |  |  |     |   |  F  |  |    | Y        PHY |   |    |             |
//     |  |  | pat |   |  I  |  |    |          I/F |   |    |             |
//     |  |  | chk |---|  F  |--|<---|              |   |    |  Loopback   |
//     |  |  |     |   |  O  |  |    |              |   |    |  Frames     |
//     |  |  -------   -------  |    |              |   |    |             |
//     |  |  -------            |    |          Rx  |   |    |             |
//     |  |  |     |----------->|--->|          PHY |   |    |             |
//     |  |  | pat |            |    |          I/F |<--------             |
//     |  |  | gen |            |    |              |   |                  |
//     |  |  |     |            |    | A            |   |                  |
//     |  |  -------            |    | V            |   |                  |
//     |  |  -------            |    |              |   |                  |
//     |  |  |     |            |    |              |   |                  |
//     |  |  | pat |            |    |              |   |                  |
//     |  |  | chk |------------|<---|              |   |                  |
//     |  |  |     |            |    |              |   |                  |
//     |  |  -------            |    |              |   |                  |
//     |  |                     |    |              |   |                  |
//     |  -----------------------    ----------------   |                  |
//     ------------------------------------^-------------                  |
//                                         |                               |
//                                         |                               |
//                                     Stimulate                           |
//                                   Management I/F                        |
//                                   (if present)                          |
//                                                                         |
//----------------------------------------------------------------------


`timescale 1ps / 1ps
//------------------------------------------------------------------------------
// This module is the demonstration testbench
//------------------------------------------------------------------------------

module legofpga_mac_axi_tb ;

//---------------------------------
// testbench mode selection
//---------------------------------
// the testbench has two modes of operation:
//  - DEMO :=   In this mode frames are generated and checked by the testbench
//              and looped back at the user side of the MAC.
//  - BIST :=   In this mode the built in pattern generators and patttern
//              checkers are used with the data looped back in the PHY domain.

    parameter TB_MODE = "DEMO";
// The following parameter does not control the value the address filter is set to
// it is only used in the testbench
//parameter address_filter_value = 96'h06050403025A_0605040302DA ; //SA and DA
  parameter address_filter_value = 96'h06050403025A_FFFFFFFFFFFF ; //SA and DA

  `define FRAME_TYP [8*62+62+62+8*4+4+4+8*4+4+4+1:1]

  initial
    $timeformat(-9, 0, "ns", 7);

  localparam  CMNDSETSPEED1000            = 8'h61,
              CMNDSETSPEED100             = 8'h62,
              CMNDSETSPEED10              = 8'h63,
              CMNDSETSLAVELOOPBACK        = 8'h69,
              CMNDSETMASTERLOOPBACK       = 8'h65,
              CMNDRESETPATCHKERROR        = 8'h74     ;


//----------------------------------------------------------------------------
// types to support frame data
//----------------------------------------------------------------------------

axi_ethernet_0_frame_typ frame0();
axi_ethernet_0_frame_typ frame1();
axi_ethernet_0_frame_typ frame2();
axi_ethernet_0_frame_typ frame3();
axi_ethernet_0_frame_typ rx_stimulus_working_frame();
axi_ethernet_0_frame_typ tx_monitor_working_frame();


//----------------------------------------------------------------------------
// Stimulus - Frame data
//----------------------------------------------------------------------------
// The following constant holds the stimulus for the testbench. It is
// an ordered array of frames, with frame 0 the first to be injected
// into the core transmit interface by the testbench.
//----------------------------------------------------------------------------
  initial
  begin
//-----------
// Frame 0
//-----------
    frame0.data[0]  = 8'h01;  frame0.valid[0]  = 1'b1;  frame0.error[0]  = 1'b0; // Destination Address (DA)
    frame0.data[1]  = 8'h02;  frame0.valid[1]  = 1'b1;  frame0.error[1]  = 1'b0;
    frame0.data[2]  = 8'h03;  frame0.valid[2]  = 1'b1;  frame0.error[2]  = 1'b0;
    frame0.data[3]  = 8'h04;  frame0.valid[3]  = 1'b1;  frame0.error[3]  = 1'b0;
    frame0.data[4]  = 8'h05;  frame0.valid[4]  = 1'b1;  frame0.error[4]  = 1'b0;
    frame0.data[5]  = 8'h06;  frame0.valid[5]  = 1'b1;  frame0.error[5]  = 1'b0;
    frame0.data[6]  = 8'h01;  frame0.valid[6]  = 1'b1;  frame0.error[6]  = 1'b0; // Source Address  (5A)
    frame0.data[7]  = 8'h02;  frame0.valid[7]  = 1'b1;  frame0.error[7]  = 1'b0;
    frame0.data[8]  = 8'h03;  frame0.valid[8]  = 1'b1;  frame0.error[8]  = 1'b0;
    frame0.data[9]  = 8'h04;  frame0.valid[9]  = 1'b1;  frame0.error[9]  = 1'b0;
    frame0.data[10] = 8'h05;  frame0.valid[10] = 1'b1;  frame0.error[10] = 1'b0;
    frame0.data[11] = 8'h06;  frame0.valid[11] = 1'b1;  frame0.error[11] = 1'b0;
    frame0.data[12] = 8'h00;  frame0.valid[12] = 1'b1;  frame0.error[12] = 1'b0;
    frame0.data[13] = 8'h2E;  frame0.valid[13] = 1'b1;  frame0.error[13] = 1'b0; // Length/Type = Length = 46
    frame0.data[14] = 8'h01;  frame0.valid[14] = 1'b1;  frame0.error[14] = 1'b0;
    frame0.data[15] = 8'h02;  frame0.valid[15] = 1'b1;  frame0.error[15] = 1'b0;
    frame0.data[16] = 8'h03;  frame0.valid[16] = 1'b1;  frame0.error[16] = 1'b0;
    frame0.data[17] = 8'h04;  frame0.valid[17] = 1'b1;  frame0.error[17] = 1'b0;
    frame0.data[18] = 8'h05;  frame0.valid[18] = 1'b1;  frame0.error[18] = 1'b0;
    frame0.data[19] = 8'h06;  frame0.valid[19] = 1'b1;  frame0.error[19] = 1'b0;
    frame0.data[20] = 8'h07;  frame0.valid[20] = 1'b1;  frame0.error[20] = 1'b0;
    frame0.data[21] = 8'h08;  frame0.valid[21] = 1'b1;  frame0.error[21] = 1'b0;
    frame0.data[22] = 8'h09;  frame0.valid[22] = 1'b1;  frame0.error[22] = 1'b0;
    frame0.data[23] = 8'h0A;  frame0.valid[23] = 1'b1;  frame0.error[23] = 1'b0;
    frame0.data[24] = 8'h0B;  frame0.valid[24] = 1'b1;  frame0.error[24] = 1'b0;
    frame0.data[25] = 8'h0C;  frame0.valid[25] = 1'b1;  frame0.error[25] = 1'b0;
    frame0.data[26] = 8'h0D;  frame0.valid[26] = 1'b1;  frame0.error[26] = 1'b0;
    frame0.data[27] = 8'h0E;  frame0.valid[27] = 1'b1;  frame0.error[27] = 1'b0;
    frame0.data[28] = 8'h0F;  frame0.valid[28] = 1'b1;  frame0.error[28] = 1'b0;
    frame0.data[29] = 8'h10;  frame0.valid[29] = 1'b1;  frame0.error[29] = 1'b0;
    frame0.data[30] = 8'h11;  frame0.valid[30] = 1'b1;  frame0.error[30] = 1'b0;
    frame0.data[31] = 8'h12;  frame0.valid[31] = 1'b1;  frame0.error[31] = 1'b0;
    frame0.data[32] = 8'h13;  frame0.valid[32] = 1'b1;  frame0.error[32] = 1'b0;
    frame0.data[33] = 8'h14;  frame0.valid[33] = 1'b1;  frame0.error[33] = 1'b0;
    frame0.data[34] = 8'h15;  frame0.valid[34] = 1'b1;  frame0.error[34] = 1'b0;
    frame0.data[35] = 8'h16;  frame0.valid[35] = 1'b1;  frame0.error[35] = 1'b0;
    frame0.data[36] = 8'h17;  frame0.valid[36] = 1'b1;  frame0.error[36] = 1'b0;
    frame0.data[37] = 8'h18;  frame0.valid[37] = 1'b1;  frame0.error[37] = 1'b0;
    frame0.data[38] = 8'h19;  frame0.valid[38] = 1'b1;  frame0.error[38] = 1'b0;
    frame0.data[39] = 8'h1A;  frame0.valid[39] = 1'b1;  frame0.error[39] = 1'b0;
    frame0.data[40] = 8'h1B;  frame0.valid[40] = 1'b1;  frame0.error[40] = 1'b0;
    frame0.data[41] = 8'h1C;  frame0.valid[41] = 1'b1;  frame0.error[41] = 1'b0;
    frame0.data[42] = 8'h1D;  frame0.valid[42] = 1'b1;  frame0.error[42] = 1'b0;
    frame0.data[43] = 8'h1E;  frame0.valid[43] = 1'b1;  frame0.error[43] = 1'b0;
    frame0.data[44] = 8'h1F;  frame0.valid[44] = 1'b1;  frame0.error[44] = 1'b0;
    frame0.data[45] = 8'h20;  frame0.valid[45] = 1'b1;  frame0.error[45] = 1'b0;
    frame0.data[46] = 8'h21;  frame0.valid[46] = 1'b1;  frame0.error[46] = 1'b0;
    frame0.data[47] = 8'h22;  frame0.valid[47] = 1'b1;  frame0.error[47] = 1'b0;
    frame0.data[48] = 8'h23;  frame0.valid[48] = 1'b1;  frame0.error[48] = 1'b0;
    frame0.data[49] = 8'h24;  frame0.valid[49] = 1'b1;  frame0.error[49] = 1'b0;
    frame0.data[50] = 8'h25;  frame0.valid[50] = 1'b1;  frame0.error[50] = 1'b0;
    frame0.data[51] = 8'h26;  frame0.valid[51] = 1'b1;  frame0.error[51] = 1'b0;
    frame0.data[52] = 8'h27;  frame0.valid[52] = 1'b1;  frame0.error[52] = 1'b0;
    frame0.data[53] = 8'h28;  frame0.valid[53] = 1'b1;  frame0.error[53] = 1'b0;
    frame0.data[54] = 8'h29;  frame0.valid[54] = 1'b1;  frame0.error[54] = 1'b0;
    frame0.data[55] = 8'h2A;  frame0.valid[55] = 1'b1;  frame0.error[55] = 1'b0;
    frame0.data[56] = 8'h2B;  frame0.valid[56] = 1'b1;  frame0.error[56] = 1'b0;
    frame0.data[57] = 8'h2C;  frame0.valid[57] = 1'b1;  frame0.error[57] = 1'b0;
    frame0.data[58] = 8'h2D;  frame0.valid[58] = 1'b1;  frame0.error[58] = 1'b0;
    frame0.data[59] = 8'h2E;  frame0.valid[59] = 1'b1;  frame0.error[59] = 1'b0;  // 46th Byte of Data
// unused
    frame0.data[60] = 8'h00;  frame0.valid[60] = 1'b0;  frame0.error[60] = 1'b0;
    frame0.data[61] = 8'h00;  frame0.valid[61] = 1'b0;  frame0.error[61] = 1'b0;

// No error in this frame
    frame0.bad_frame  = 1'b0;


//-----------
// Frame 1
//-----------
    frame1.data[0]  = 8'hFF;  frame1.valid[0]  = 1'b1;  frame1.error[0]  = 1'b0; // Destination Address (DA)
    frame1.data[1]  = 8'hFF;  frame1.valid[1]  = 1'b1;  frame1.error[1]  = 1'b0;
    frame1.data[2]  = 8'hFF;  frame1.valid[2]  = 1'b1;  frame1.error[2]  = 1'b0;
    frame1.data[3]  = 8'hFF;  frame1.valid[3]  = 1'b1;  frame1.error[3]  = 1'b0;
    frame1.data[4]  = 8'hFF;  frame1.valid[4]  = 1'b1;  frame1.error[4]  = 1'b0;
    frame1.data[5]  = 8'hFF;  frame1.valid[5]  = 1'b1;  frame1.error[5]  = 1'b0;
    frame1.data[6]  = 8'h5A;  frame1.valid[6]  = 1'b1;  frame1.error[6]  = 1'b0; // Source Address  (5A)
    frame1.data[7]  = 8'h02;  frame1.valid[7]  = 1'b1;  frame1.error[7]  = 1'b0;
    frame1.data[8]  = 8'h03;  frame1.valid[8]  = 1'b1;  frame1.error[8]  = 1'b0;
    frame1.data[9]  = 8'h04;  frame1.valid[9]  = 1'b1;  frame1.error[9]  = 1'b0;
    frame1.data[10] = 8'h05;  frame1.valid[10] = 1'b1;  frame1.error[10] = 1'b0;
    frame1.data[11] = 8'h06;  frame1.valid[11] = 1'b1;  frame1.error[11] = 1'b0;
    frame1.data[12] = 8'h80;  frame1.valid[12] = 1'b1;  frame1.error[12] = 1'b0; // Length/Type = Type = 8000
    frame1.data[13] = 8'h00;  frame1.valid[13] = 1'b1;  frame1.error[13] = 1'b0;
    frame1.data[14] = 8'h01;  frame1.valid[14] = 1'b1;  frame1.error[14] = 1'b0;
    frame1.data[15] = 8'h02;  frame1.valid[15] = 1'b1;  frame1.error[15] = 1'b0;
    frame1.data[16] = 8'h03;  frame1.valid[16] = 1'b1;  frame1.error[16] = 1'b0;
    frame1.data[17] = 8'h04;  frame1.valid[17] = 1'b1;  frame1.error[17] = 1'b0;
    frame1.data[18] = 8'h05;  frame1.valid[18] = 1'b1;  frame1.error[18] = 1'b0;
    frame1.data[19] = 8'h06;  frame1.valid[19] = 1'b1;  frame1.error[19] = 1'b0;
    frame1.data[20] = 8'h07;  frame1.valid[20] = 1'b1;  frame1.error[20] = 1'b0;
    frame1.data[21] = 8'h08;  frame1.valid[21] = 1'b1;  frame1.error[21] = 1'b0;
    frame1.data[22] = 8'h09;  frame1.valid[22] = 1'b1;  frame1.error[22] = 1'b0;
    frame1.data[23] = 8'h0A;  frame1.valid[23] = 1'b1;  frame1.error[23] = 1'b0;
    frame1.data[24] = 8'h0B;  frame1.valid[24] = 1'b1;  frame1.error[24] = 1'b0;
    frame1.data[25] = 8'h0C;  frame1.valid[25] = 1'b1;  frame1.error[25] = 1'b0;
    frame1.data[26] = 8'h0D;  frame1.valid[26] = 1'b1;  frame1.error[26] = 1'b0;
    frame1.data[27] = 8'h0E;  frame1.valid[27] = 1'b1;  frame1.error[27] = 1'b0;
    frame1.data[28] = 8'h0F;  frame1.valid[28] = 1'b1;  frame1.error[28] = 1'b0;
    frame1.data[29] = 8'h10;  frame1.valid[29] = 1'b1;  frame1.error[29] = 1'b0;
    frame1.data[30] = 8'h11;  frame1.valid[30] = 1'b1;  frame1.error[30] = 1'b0;
    frame1.data[31] = 8'h12;  frame1.valid[31] = 1'b1;  frame1.error[31] = 1'b0;
    frame1.data[32] = 8'h13;  frame1.valid[32] = 1'b1;  frame1.error[32] = 1'b0;
    frame1.data[33] = 8'h14;  frame1.valid[33] = 1'b1;  frame1.error[33] = 1'b0;
    frame1.data[34] = 8'h15;  frame1.valid[34] = 1'b1;  frame1.error[34] = 1'b0;
    frame1.data[35] = 8'h16;  frame1.valid[35] = 1'b1;  frame1.error[35] = 1'b0;
    frame1.data[36] = 8'h17;  frame1.valid[36] = 1'b1;  frame1.error[36] = 1'b0;
    frame1.data[37] = 8'h18;  frame1.valid[37] = 1'b1;  frame1.error[37] = 1'b0;
    frame1.data[38] = 8'h19;  frame1.valid[38] = 1'b1;  frame1.error[38] = 1'b0;
    frame1.data[39] = 8'h1A;  frame1.valid[39] = 1'b1;  frame1.error[39] = 1'b0;
    frame1.data[40] = 8'h1B;  frame1.valid[40] = 1'b1;  frame1.error[40] = 1'b0;
    frame1.data[41] = 8'h1C;  frame1.valid[41] = 1'b1;  frame1.error[41] = 1'b0;
    frame1.data[42] = 8'h1D;  frame1.valid[42] = 1'b1;  frame1.error[42] = 1'b0;
    frame1.data[43] = 8'h1E;  frame1.valid[43] = 1'b1;  frame1.error[43] = 1'b0;
    frame1.data[44] = 8'h1F;  frame1.valid[44] = 1'b1;  frame1.error[44] = 1'b0;
    frame1.data[45] = 8'h20;  frame1.valid[45] = 1'b1;  frame1.error[45] = 1'b0;
    frame1.data[46] = 8'h21;  frame1.valid[46] = 1'b1;  frame1.error[46] = 1'b0;
    frame1.data[47] = 8'h22;  frame1.valid[47] = 1'b1;  frame1.error[47] = 1'b0;
    frame1.data[48] = 8'h23;  frame1.valid[48] = 1'b1;  frame1.error[48] = 1'b0;
    frame1.data[49] = 8'h24;  frame1.valid[49] = 1'b1;  frame1.error[49] = 1'b0;
    frame1.data[50] = 8'h25;  frame1.valid[50] = 1'b1;  frame1.error[50] = 1'b0;
    frame1.data[51] = 8'h26;  frame1.valid[51] = 1'b1;  frame1.error[51] = 1'b0;
    frame1.data[52] = 8'h27;  frame1.valid[52] = 1'b1;  frame1.error[52] = 1'b0;
    frame1.data[53] = 8'h28;  frame1.valid[53] = 1'b1;  frame1.error[53] = 1'b0;
    frame1.data[54] = 8'h29;  frame1.valid[54] = 1'b1;  frame1.error[54] = 1'b0;
    frame1.data[55] = 8'h2A;  frame1.valid[55] = 1'b1;  frame1.error[55] = 1'b0;
    frame1.data[56] = 8'h2B;  frame1.valid[56] = 1'b1;  frame1.error[56] = 1'b0;
    frame1.data[57] = 8'h2C;  frame1.valid[57] = 1'b1;  frame1.error[57] = 1'b0;
    frame1.data[58] = 8'h2D;  frame1.valid[58] = 1'b1;  frame1.error[58] = 1'b0;
    frame1.data[59] = 8'h2E;  frame1.valid[59] = 1'b1;  frame1.error[59] = 1'b0;
    frame1.data[60] = 8'h2F;  frame1.valid[60] = 1'b1;  frame1.error[60] = 1'b0; // 47th Data byte
// unused
    frame1.data[61] = 8'h00;  frame1.valid[61] = 1'b0;  frame1.error[61] = 1'b0;

// No error in this frame
    frame1.bad_frame  = 1'b0;


//-----------
// Frame 2
//-----------
    frame2.data[0]  = 8'hFF;  frame2.valid[0]  = 1'b1;  frame2.error[0]  = 1'b0; // Destination Address (DA)
    frame2.data[1]  = 8'hFF;  frame2.valid[1]  = 1'b1;  frame2.error[1]  = 1'b0;
    frame2.data[2]  = 8'hFF;  frame2.valid[2]  = 1'b1;  frame2.error[2]  = 1'b0;
    frame2.data[3]  = 8'hFF;  frame2.valid[3]  = 1'b1;  frame2.error[3]  = 1'b0;
    frame2.data[4]  = 8'hFF;  frame2.valid[4]  = 1'b1;  frame2.error[4]  = 1'b0;
    frame2.data[5]  = 8'hFF;  frame2.valid[5]  = 1'b1;  frame2.error[5]  = 1'b0;
    frame2.data[6]  = 8'h5A;  frame2.valid[6]  = 1'b1;  frame2.error[6]  = 1'b0; // Source Address  (5A)
    frame2.data[7]  = 8'h02;  frame2.valid[7]  = 1'b1;  frame2.error[7]  = 1'b0;
    frame2.data[8]  = 8'h03;  frame2.valid[8]  = 1'b1;  frame2.error[8]  = 1'b0;
    frame2.data[9]  = 8'h04;  frame2.valid[9]  = 1'b1;  frame2.error[9]  = 1'b0;
    frame2.data[10] = 8'h05;  frame2.valid[10] = 1'b1;  frame2.error[10] = 1'b0;
    frame2.data[11] = 8'h06;  frame2.valid[11] = 1'b1;  frame2.error[11] = 1'b0;
    frame2.data[12] = 8'h00;  frame2.valid[12] = 1'b1;  frame2.error[12] = 1'b0;
    frame2.data[13] = 8'h2E;  frame2.valid[13] = 1'b1;  frame2.error[13] = 1'b0; // Length/Type = Length = 46
    frame2.data[14] = 8'h01;  frame2.valid[14] = 1'b1;  frame2.error[14] = 1'b0;
    frame2.data[15] = 8'h02;  frame2.valid[15] = 1'b1;  frame2.error[15] = 1'b0;
    frame2.data[16] = 8'h03;  frame2.valid[16] = 1'b1;  frame2.error[16] = 1'b0;
    frame2.data[17] = 8'h00;  frame2.valid[17] = 1'b1;  frame2.error[17] = 1'b0; // Underrun this frame
    frame2.data[18] = 8'h00;  frame2.valid[18] = 1'b1;  frame2.error[18] = 1'b0;
    frame2.data[19] = 8'h00;  frame2.valid[19] = 1'b1;  frame2.error[19] = 1'b0;
    frame2.data[20] = 8'h00;  frame2.valid[20] = 1'b1;  frame2.error[20] = 1'b0;
    frame2.data[21] = 8'h00;  frame2.valid[21] = 1'b1;  frame2.error[21] = 1'b0;
    frame2.data[22] = 8'h00;  frame2.valid[22] = 1'b1;  frame2.error[22] = 1'b0;
    frame2.data[23] = 8'h00;  frame2.valid[23] = 1'b1;  frame2.error[23] = 1'b1; // Error asserted
    frame2.data[24] = 8'h00;  frame2.valid[24] = 1'b1;  frame2.error[24] = 1'b0;
    frame2.data[25] = 8'h00;  frame2.valid[25] = 1'b1;  frame2.error[25] = 1'b0;
    frame2.data[26] = 8'h00;  frame2.valid[26] = 1'b1;  frame2.error[26] = 1'b0;
    frame2.data[27] = 8'h00;  frame2.valid[27] = 1'b1;  frame2.error[27] = 1'b0;
    frame2.data[28] = 8'h00;  frame2.valid[28] = 1'b1;  frame2.error[28] = 1'b0;
    frame2.data[29] = 8'h00;  frame2.valid[29] = 1'b1;  frame2.error[29] = 1'b0;
    frame2.data[30] = 8'h00;  frame2.valid[30] = 1'b1;  frame2.error[30] = 1'b0;
    frame2.data[31] = 8'h00;  frame2.valid[31] = 1'b1;  frame2.error[31] = 1'b0;
    frame2.data[32] = 8'h00;  frame2.valid[32] = 1'b1;  frame2.error[32] = 1'b0;
    frame2.data[33] = 8'h00;  frame2.valid[33] = 1'b1;  frame2.error[33] = 1'b0;
    frame2.data[34] = 8'h00;  frame2.valid[34] = 1'b1;  frame2.error[34] = 1'b0;
    frame2.data[35] = 8'h00;  frame2.valid[35] = 1'b1;  frame2.error[35] = 1'b0;
    frame2.data[36] = 8'h00;  frame2.valid[36] = 1'b1;  frame2.error[36] = 1'b0;
    frame2.data[37] = 8'h00;  frame2.valid[37] = 1'b1;  frame2.error[37] = 1'b0;
    frame2.data[38] = 8'h00;  frame2.valid[38] = 1'b1;  frame2.error[38] = 1'b0;
    frame2.data[39] = 8'h00;  frame2.valid[39] = 1'b1;  frame2.error[39] = 1'b0;
    frame2.data[40] = 8'h00;  frame2.valid[40] = 1'b1;  frame2.error[40] = 1'b0;
    frame2.data[41] = 8'h00;  frame2.valid[41] = 1'b1;  frame2.error[41] = 1'b0;
    frame2.data[42] = 8'h00;  frame2.valid[42] = 1'b1;  frame2.error[42] = 1'b0;
    frame2.data[43] = 8'h00;  frame2.valid[43] = 1'b1;  frame2.error[43] = 1'b0;
    frame2.data[44] = 8'h00;  frame2.valid[44] = 1'b1;  frame2.error[44] = 1'b0;
    frame2.data[45] = 8'h00;  frame2.valid[45] = 1'b1;  frame2.error[45] = 1'b0;
    frame2.data[46] = 8'h00;  frame2.valid[46] = 1'b1;  frame2.error[46] = 1'b0;
    frame2.data[47] = 8'h00;  frame2.valid[47] = 1'b1;  frame2.error[47] = 1'b0;
    frame2.data[48] = 8'h00;  frame2.valid[48] = 1'b1;  frame2.error[48] = 1'b0;
    frame2.data[49] = 8'h00;  frame2.valid[49] = 1'b1;  frame2.error[49] = 1'b0;
    frame2.data[50] = 8'h00;  frame2.valid[50] = 1'b1;  frame2.error[50] = 1'b0;
    frame2.data[51] = 8'h00;  frame2.valid[51] = 1'b1;  frame2.error[51] = 1'b0;
    frame2.data[52] = 8'h00;  frame2.valid[52] = 1'b1;  frame2.error[52] = 1'b0;
    frame2.data[53] = 8'h00;  frame2.valid[53] = 1'b1;  frame2.error[53] = 1'b0;
    frame2.data[54] = 8'h00;  frame2.valid[54] = 1'b1;  frame2.error[54] = 1'b0;
    frame2.data[55] = 8'h00;  frame2.valid[55] = 1'b1;  frame2.error[55] = 1'b0;
    frame2.data[56] = 8'h00;  frame2.valid[56] = 1'b1;  frame2.error[56] = 1'b0;
    frame2.data[57] = 8'h00;  frame2.valid[57] = 1'b1;  frame2.error[57] = 1'b0;
    frame2.data[58] = 8'h00;  frame2.valid[58] = 1'b1;  frame2.error[58] = 1'b0;
    frame2.data[59] = 8'h00;  frame2.valid[59] = 1'b1;  frame2.error[59] = 1'b0;
// unused
    frame2.data[60] = 8'h00;  frame2.valid[60] = 1'b0;  frame2.error[60] = 1'b0;
    frame2.data[61] = 8'h00;  frame2.valid[61] = 1'b0;  frame2.error[61] = 1'b0;

// Error this frame
    frame2.bad_frame  = 1'b1;


//-----------
// Frame 3
//-----------
    frame3.data[0]  = 8'hFF;  frame3.valid[0]  = 1'b1;  frame3.error[0]  = 1'b0; // Destination Address (DA)
    frame3.data[1]  = 8'hFF;  frame3.valid[1]  = 1'b1;  frame3.error[1]  = 1'b0;
    frame3.data[2]  = 8'hFF;  frame3.valid[2]  = 1'b1;  frame3.error[2]  = 1'b0;
    frame3.data[3]  = 8'hFF;  frame3.valid[3]  = 1'b1;  frame3.error[3]  = 1'b0;
    frame3.data[4]  = 8'hFF;  frame3.valid[4]  = 1'b1;  frame3.error[4]  = 1'b0;
    frame3.data[5]  = 8'hFF;  frame3.valid[5]  = 1'b1;  frame3.error[5]  = 1'b0;
    frame3.data[6]  = 8'h5A;  frame3.valid[6]  = 1'b1;  frame3.error[6]  = 1'b0; // Source Address  (5A)
    frame3.data[7]  = 8'h02;  frame3.valid[7]  = 1'b1;  frame3.error[7]  = 1'b0;
    frame3.data[8]  = 8'h03;  frame3.valid[8]  = 1'b1;  frame3.error[8]  = 1'b0;
    frame3.data[9]  = 8'h04;  frame3.valid[9]  = 1'b1;  frame3.error[9]  = 1'b0;
    frame3.data[10] = 8'h05;  frame3.valid[10] = 1'b1;  frame3.error[10] = 1'b0;
    frame3.data[11] = 8'h06;  frame3.valid[11] = 1'b1;  frame3.error[11] = 1'b0;
    frame3.data[12] = 8'h00;  frame3.valid[12] = 1'b1;  frame3.error[12] = 1'b0;
    frame3.data[13] = 8'h03;  frame3.valid[13] = 1'b1;  frame3.error[13] = 1'b0; // Length/Type = Length = 03
    frame3.data[14] = 8'h01;  frame3.valid[14] = 1'b1;  frame3.error[14] = 1'b0; // Therefore padding is required
    frame3.data[15] = 8'h02;  frame3.valid[15] = 1'b1;  frame3.error[15] = 1'b0;
    frame3.data[16] = 8'h03;  frame3.valid[16] = 1'b1;  frame3.error[16] = 1'b0;
    frame3.data[17] = 8'h00;  frame3.valid[17] = 1'b1;  frame3.error[17] = 1'b0; // Padding starts here
    frame3.data[18] = 8'h00;  frame3.valid[18] = 1'b1;  frame3.error[18] = 1'b0;
    frame3.data[19] = 8'h00;  frame3.valid[19] = 1'b1;  frame3.error[19] = 1'b0;
    frame3.data[20] = 8'h00;  frame3.valid[20] = 1'b1;  frame3.error[20] = 1'b0;
    frame3.data[21] = 8'h00;  frame3.valid[21] = 1'b1;  frame3.error[21] = 1'b0;
    frame3.data[22] = 8'h00;  frame3.valid[22] = 1'b1;  frame3.error[22] = 1'b0;
    frame3.data[23] = 8'h00;  frame3.valid[23] = 1'b1;  frame3.error[23] = 1'b0;
    frame3.data[24] = 8'h00;  frame3.valid[24] = 1'b1;  frame3.error[24] = 1'b0;
    frame3.data[25] = 8'h00;  frame3.valid[25] = 1'b1;  frame3.error[25] = 1'b0;
    frame3.data[26] = 8'h00;  frame3.valid[26] = 1'b1;  frame3.error[26] = 1'b0;
    frame3.data[27] = 8'h00;  frame3.valid[27] = 1'b1;  frame3.error[27] = 1'b0;
    frame3.data[28] = 8'h00;  frame3.valid[28] = 1'b1;  frame3.error[28] = 1'b0;
    frame3.data[29] = 8'h00;  frame3.valid[29] = 1'b1;  frame3.error[29] = 1'b0;
    frame3.data[30] = 8'h00;  frame3.valid[30] = 1'b1;  frame3.error[30] = 1'b0;
    frame3.data[31] = 8'h00;  frame3.valid[31] = 1'b1;  frame3.error[31] = 1'b0;
    frame3.data[32] = 8'h00;  frame3.valid[32] = 1'b1;  frame3.error[32] = 1'b0;
    frame3.data[33] = 8'h00;  frame3.valid[33] = 1'b1;  frame3.error[33] = 1'b0;
    frame3.data[34] = 8'h00;  frame3.valid[34] = 1'b1;  frame3.error[34] = 1'b0;
    frame3.data[35] = 8'h00;  frame3.valid[35] = 1'b1;  frame3.error[35] = 1'b0;
    frame3.data[36] = 8'h00;  frame3.valid[36] = 1'b1;  frame3.error[36] = 1'b0;
    frame3.data[37] = 8'h00;  frame3.valid[37] = 1'b1;  frame3.error[37] = 1'b0;
    frame3.data[38] = 8'h00;  frame3.valid[38] = 1'b1;  frame3.error[38] = 1'b0;
    frame3.data[39] = 8'h00;  frame3.valid[39] = 1'b1;  frame3.error[39] = 1'b0;
    frame3.data[40] = 8'h00;  frame3.valid[40] = 1'b1;  frame3.error[40] = 1'b0;
    frame3.data[41] = 8'h00;  frame3.valid[41] = 1'b1;  frame3.error[41] = 1'b0;
    frame3.data[42] = 8'h00;  frame3.valid[42] = 1'b1;  frame3.error[42] = 1'b0;
    frame3.data[43] = 8'h00;  frame3.valid[43] = 1'b1;  frame3.error[43] = 1'b0;
    frame3.data[44] = 8'h00;  frame3.valid[44] = 1'b1;  frame3.error[44] = 1'b0;
    frame3.data[45] = 8'h00;  frame3.valid[45] = 1'b1;  frame3.error[45] = 1'b0;
    frame3.data[46] = 8'h00;  frame3.valid[46] = 1'b1;  frame3.error[46] = 1'b0;
    frame3.data[47] = 8'h00;  frame3.valid[47] = 1'b1;  frame3.error[47] = 1'b0;
    frame3.data[48] = 8'h00;  frame3.valid[48] = 1'b1;  frame3.error[48] = 1'b0;
    frame3.data[49] = 8'h00;  frame3.valid[49] = 1'b1;  frame3.error[49] = 1'b0;
    frame3.data[50] = 8'h00;  frame3.valid[50] = 1'b1;  frame3.error[50] = 1'b0;
    frame3.data[51] = 8'h00;  frame3.valid[51] = 1'b1;  frame3.error[51] = 1'b0;
    frame3.data[52] = 8'h00;  frame3.valid[52] = 1'b1;  frame3.error[52] = 1'b0;
    frame3.data[53] = 8'h00;  frame3.valid[53] = 1'b1;  frame3.error[53] = 1'b0;
    frame3.data[54] = 8'h00;  frame3.valid[54] = 1'b1;  frame3.error[54] = 1'b0;
    frame3.data[55] = 8'h00;  frame3.valid[55] = 1'b1;  frame3.error[55] = 1'b0;
    frame3.data[56] = 8'h00;  frame3.valid[56] = 1'b1;  frame3.error[56] = 1'b0;
    frame3.data[57] = 8'h00;  frame3.valid[57] = 1'b1;  frame3.error[57] = 1'b0;
    frame3.data[58] = 8'h00;  frame3.valid[58] = 1'b1;  frame3.error[58] = 1'b0;
    frame3.data[59] = 8'h00;  frame3.valid[59] = 1'b1;  frame3.error[59] = 1'b0;
// unused
    frame3.data[60] = 8'h00;  frame3.valid[60] = 1'b0;  frame3.error[60] = 1'b0;
    frame3.data[61] = 8'h00;  frame3.valid[61] = 1'b0;  frame3.error[61] = 1'b0;

// No error in this frame
    frame3.bad_frame  = 1'b0;
    


  end


//--------------------------------------------------------------------
// CRC engine
//--------------------------------------------------------------------
  task calc_crc;
      input  [7:0]  data;
      inout  [31:0] fcs;

      reg [31:0] crc;
      reg        crc_feedback;
      integer    I;
  begin

      crc = ~ fcs;

      for (I = 0; I < 8; I = I + 1)
      begin
          crc_feedback = crc[0] ^ data[I];

          crc[0]       = crc[1];
          crc[1]       = crc[2];
          crc[2]       = crc[3];
          crc[3]       = crc[4];
          crc[4]       = crc[5];
          crc[5]       = crc[6]  ^ crc_feedback;
          crc[6]       = crc[7];
          crc[7]       = crc[8];
          crc[8]       = crc[9]  ^ crc_feedback;
          crc[9]       = crc[10] ^ crc_feedback;
          crc[10]      = crc[11];
          crc[11]      = crc[12];
          crc[12]      = crc[13];
          crc[13]      = crc[14];
          crc[14]      = crc[15];
          crc[15]      = crc[16] ^ crc_feedback;
          crc[16]      = crc[17];
          crc[17]      = crc[18];
          crc[18]      = crc[19];
          crc[19]      = crc[20] ^ crc_feedback;
          crc[20]      = crc[21] ^ crc_feedback;
          crc[21]      = crc[22] ^ crc_feedback;
          crc[22]      = crc[23];
          crc[23]      = crc[24] ^ crc_feedback;
          crc[24]      = crc[25] ^ crc_feedback;
          crc[25]      = crc[26];
          crc[26]      = crc[27] ^ crc_feedback;
          crc[27]      = crc[28] ^ crc_feedback;
          crc[28]      = crc[29];
          crc[29]      = crc[30] ^ crc_feedback;
          crc[30]      = crc[31] ^ crc_feedback;
          crc[31]      =           crc_feedback;
      end

// return the CRC result
      fcs = ~ crc;

  end
  endtask // calc_crc


//----------------------------------------------------------------------------
// Test Bench signals and constants
//----------------------------------------------------------------------------

// Delay to provide setup and hold timing at the GMII/RGMII.
  parameter dly = 5800;  // has to be valid from 6ns to 8ns
  parameter gtx_period = 4000;  // ps


// testbench signals
  
  reg         gtx_clk;
  reg         reset;
  reg         demo_mode_error = 1'b0;
  reg  [9:0]  tenbit_data = 0;
  reg  [9:0]  tenbit_data_rev = 0;

  wire        mdc;
  wire        mdio;
  reg  [5:0]  mdio_count;
  reg         last_mdio;
  reg         mdio_read;
  reg         mdio_addr;
  reg         mdio_fail;
  reg clk_enable = 1'b1;

// signals for the Tx monitor following 8B10B decode
  reg [7:0] tx_pdata;
  reg tx_is_k;
  reg stim_tx_clk_1000;
  reg stim_tx_clk_100;
  reg stim_tx_clk_10;
  reg clock_enable;   // SGMII mode only: Used to create data at different rates

  reg  stim_tx_clk;   // Transmitter clock (stimulus process).
  wire mon_tx_clk;    // Transmitter clock (monitor process).

// signals for the Rx stimulus prior to 8B10B encode
  reg [7:0] rx_pdata;
  reg rx_is_k;
  reg rx_even;        // Keep track of the even/odd position
  reg rx_rundisp_pos; // Indicates +ve running disparity
  reg stim_rx_clk;    // Receiver clock (stimulus process).
  wire mon_rx_clk;    // Receiver clock (monitor process).
  reg  bitclock;      // clock running at Transceiver serial frequency


// testbench control semaphores
  reg start_config;   //kicks off controller FSM
  reg  tx_monitor_finished_1G;
  reg  tx_monitor_finished_10M;
  reg  tx_monitor_finished_100M;
  reg  management_config_finished;

  reg [7:0] cmnd_data;
  reg cmnd_data_valid;
  wire cmnd_data_ready;

  reg [1:0] phy_speed;
  reg [1:0] mac_speed;
  reg       update_speed;
  wire [7:0]   gmii_rxd_dut;
  wire         gmii_rx_dv_dut;
  wire         gmii_rx_er_dut;

  reg          gen_tx_data;
  reg          check_tx_data;
  reg          config_bist;
  wire         frame_error;
  reg          bist_mode_error;
  wire         serial_response;
  parameter UI = 800; //800 ps
  reg gtref_clk_p;
  reg rxp;
  reg rxn;
  reg drp_clk;
  reg lvds_clk;
  wire txp;
  wire txn;
  wire sgmii_rxp_dut;
  wire speed_is_100;
  wire speed_is_10_100;
  wire[31:0] num_of_repeat; 
  reg[4:0] phy_addr=5'd1;
  reg[4:0] phy_addr_mdio = 0;
  reg mdio_addr_on_board = 1;
  reg mdio_addr_pcs_pma = 1;
  reg mdio_txn_found=1'b0;



  assign speed_is_100    = (mac_speed[0] == 1'b1 && mac_speed[1] == 1'b0)?1'b1:1'b0;
  assign speed_is_10_100 = (mac_speed[1] == 1'b0)?1'b1:1'b0;

// select between loopback or local data

  assign sgmii_rxp_dut = (TB_MODE == "BIST") ? txp : rxp;

  reg [16:0]   hw_frame_cnt=16'h0000;

// select between loopback or local data

  reg  ref_clk=0;
  reg clk_625=0;

  wire interrupt;
  wire mac_irq;
  wire mdio_io;
  wire mdio_mdc;
  wire phy_rst_n;
  reg [4:0] pcs_pma_reg_addr = 1;

//----------------------------------------------------------------------------
// Wire up Device Under Test
//----------------------------------------------------------------------------
  wire phy_resetn;

wire  ddr4_sdram_c1_act_n;
wire  [16:0]ddr4_sdram_c1_adr;
wire  [1:0]ddr4_sdram_c1_ba;
wire  ddr4_sdram_c1_bg;
wire  ddr4_sdram_c1_ck_c;
wire  ddr4_sdram_c1_ck_t;
wire  ddr4_sdram_c1_cke;
wire  ddr4_sdram_c1_cs_n;
wire  [7:0]ddr4_sdram_c1_dm_n;
wire  [63:0]ddr4_sdram_c1_dq;
wire  [7:0]ddr4_sdram_c1_dqs_c;
wire  [7:0]ddr4_sdram_c1_dqs_t;
wire  ddr4_sdram_c1_odt;
wire  ddr4_sdram_c1_reset_n;

top dut (
// asynchronous reset
      .sys_rst              (reset           ),
      .start_config         (start_config    ),
      .mtrlb_pktchk_error   (frame_error     ),
      .mtrlb_activity_flash (                ),

      .control_data         (cmnd_data[3:0]  ),
      .control_valid        (cmnd_data_valid ),
      .control_ready        (cmnd_data_ready ),
                .mgt_clk_p            (lvds_clk         ),
                .mgt_clk_n            (~lvds_clk        ),
      .sgmii_rxn            (~sgmii_rxp_dut  ),
      .sgmii_rxp            (sgmii_rxp_dut   ),
      .sgmii_txn            (txn             ),
      .sgmii_txp            (txp             ),
      .phy_rst_n            (phy_rst_n       ),
// MDIO Interface
//---------------
      .mdc                  (mdc             ),
      .mdio                 (mdio            ),

// 125MHZ clock input from board
      .sysclk_125_clk_p           (ref_clk),
      .sysclk_125_clk_n           (~ref_clk),

    .ddr4_sdram_c1_act_n	(ddr4_sdram_c1_act_n),
    .ddr4_sdram_c1_adr		(ddr4_sdram_c1_adr),
    .ddr4_sdram_c1_ba		(ddr4_sdram_c1_ba),
    .ddr4_sdram_c1_bg		(ddr4_sdram_c1_bg),
    .ddr4_sdram_c1_ck_c		(ddr4_sdram_c1_ck_c),
    .ddr4_sdram_c1_ck_t		(ddr4_sdram_c1_ck_t),
    .ddr4_sdram_c1_cke		(ddr4_sdram_c1_cke),
    .ddr4_sdram_c1_cs_n		(ddr4_sdram_c1_cs_n),
    .ddr4_sdram_c1_dm_n		(ddr4_sdram_c1_dm_n),
    .ddr4_sdram_c1_dq		(ddr4_sdram_c1_dq),
    .ddr4_sdram_c1_dqs_c	(ddr4_sdram_c1_dqs_c),
    .ddr4_sdram_c1_dqs_t	(ddr4_sdram_c1_dqs_t),
    .ddr4_sdram_c1_odt		(ddr4_sdram_c1_odt),
    .ddr4_sdram_c1_reset_n	(ddr4_sdram_c1_reset_n)
);

//---------------------------------------------------------------------------
//-- If the simulation is still going then
//-- something has gone wrong
//---------------------------------------------------------------------------
  initial
  begin
    if (TB_MODE == "BIST")
      repeat(14)
       #8_00_000_000;
    else
      repeat(12)
       #8_00_000_000;
    $display("** ERROR: Simulation Running Forever");
    $stop;
  end

  initial begin
    repeat (5) begin
        #5000_000       $display("Simulation running at time %t ", $time);
    end
    repeat (11) begin
        #80_000_000     $display("Simulation running at time %t ", $time);
    end
        #100_000_000    $display("Simulation running at time %t ", $time);
    forever begin
        #500_000_000    $display("Simulation running at time %t ", $time);
    end
  end

//----------------------------------------------------------------------------
// Simulate the MDIO -
// respond with sensible data to mdio reads and accept writes
//----------------------------------------------------------------------------
// expect mdio to try and read from reg addr 1 - return all 1's if we don't
// want any other mdio accesses
// if any other response then mdio will write to reg_addr 9 then 4 then 0
// (may check for expected write data?)
// finally mdio read from reg addr 1 until bit 5 is seen high
// NOTE - do not check any other bits so could drive all high again..


// count through the mdio transfer
  always @(posedge mdc or posedge reset)
  begin
     if (reset) begin
        mdio_count <= 0;
        last_mdio <= 1'b0;
     end
     else begin
        last_mdio <= mdio;
        if (mdio_count >= 32) begin
           mdio_count <= 0;
        end
        else if (mdio_count != 0) begin
           mdio_count <= mdio_count + 1;
        end
        else begin // only get here if mdio state is 0 - now look for a start
          if ((mdio === 1'b1) && (last_mdio === 1'b0)) begin
            mdio_count <= 1;
            mdio_txn_found <= 1'b1;
          end 
        end
     end
  end

  assign mdio = (mdio_read & (mdio_count >= 14) & (mdio_count <= 31)) ? 1'b1 : 1'bz;

// only respond to phy addr 7 and pcspma reg address 
  always @(posedge mdc or posedge reset)
  begin
     if (reset) begin
        mdio_read <= 1'b0;
        mdio_addr <= 1'b1; // this will go low if the address doesn't match required
        mdio_fail <= 1'b0;
     end
     else
     begin
        if (mdio_count == 2) begin
           mdio_addr <= 1'b1;    // new access so address needs to be revalidated
           mdio_addr_on_board <= 1'b1;
           mdio_addr_pcs_pma <= 1'b1;

           if ({last_mdio,mdio} === 2'b10)
              mdio_read <= 1'b1;
           else // take a write as a default as won't drive at the wrong time
              mdio_read <= 1'b0;
        end
        else if ((mdio_count <= 12)) begin
// check address is phy addr/reg addr are correct
           if (mdio_count <= 7 & mdio_count >= 5) begin
              if (mdio !== 1'b1)
                 mdio_addr_on_board <= 1'b0;
           end
           if (mdio_count <= 7 ) begin
             phy_addr_mdio[7-mdio_count] <= mdio;
           end else begin
             if(phy_addr_mdio != phy_addr) begin
               mdio_addr_pcs_pma <= 1'b0;
             end
           end
           mdio_addr <= mdio_addr_on_board | mdio_addr_pcs_pma;
           if(mdio_addr==0) begin
             mdio_fail <= 1;
             $display("FAIL : ADDR phase is incorrect at %t ", $time);
           end
           if (mdio_count <= 12 & mdio_count >= 8) begin
             pcs_pma_reg_addr[12-mdio_count] <= mdio;
           end  
        end
        else if ((mdio_count == 14)) begin
           if (!mdio_read & (mdio | !last_mdio)) begin
              $display("FAIL : Write TA phase is incorrect at %t ", $time);
           end
        end
        else if ((mdio_count >= 15) && (mdio_count <= 30) && mdio_addr && pcs_pma_reg_addr == 5'h00) begin
           if (!mdio_read) begin
              if (mdio_count == 20 && mdio_addr_pcs_pma) begin
                 if (mdio) begin  // remove isolation
                    mdio_fail <= 1;
                    $display("FAIL : ISOLATION is not disabled at %t ", $time);
                 end
              end
              else if (mdio_count == 16) begin
                 if(TB_MODE == "DEMO") begin
                   if (mdio && mdio_addr_on_board ) begin  // loopback not enabled
                    mdio_fail <= 1;
                    $display("FAIL : LOOP BACK is enabled for ON BOARD PHY in DEMO modeat %t ", $time);
                   end
                 end
                 else if (!mdio && mdio_addr_on_board ) begin  // loopback not enabled
                    mdio_fail <= 1;
                    $display("FAIL : LOOP BACK not enabled for ON BOARD PHY at %t ", $time);
                 end
                 else if (mdio && mdio_addr_pcs_pma) begin  // loopback enabled for pcspma
                    mdio_fail <= 1;
                    $display("FAIL : LOOP BACK enabled for pcspma %t ", $time);
                 end
              end
              else if (mdio_count == 18 && mdio_addr_pcs_pma) begin
                 if (mdio) begin  // AN not disabled
                    mdio_fail <= 1;
                    $display("FAIL : AN not Disabled for pcspma at %t ", $time);
                 end
              end
              else if (mdio_count == 22) begin
                 if (!mdio) begin  // Not in FULL Duplex
                    mdio_fail <= 1;
                    $display("FAIL : PHY Configured in HALF DUPLEX Mode at %t ", $time);
                 end
              end
           end
           
        end
     end
  end

//----------------------------------------------------------------------------
// Clock drivers
//----------------------------------------------------------------------------

  initial begin
    ref_clk =1'b0;
    forever begin
      ref_clk = ~ref_clk;
      #4000;
      ref_clk = ~ref_clk;
      #4000;
    end
  end

  initial begin
    clk_625 =1'b0;
    forever begin
      clk_625 = ~clk_625;
      #800;
    end
  end

  initial begin
    gtx_clk = 1'b0;
    forever begin
     gtx_clk = 1'b0;
      #4000;
     gtx_clk = 1'b1;
      #4000;
    end
  end


 initial begin
    gtref_clk_p = 1'b0;
    forever begin
     gtref_clk_p = 1'b0;
      #4000 ;
     gtref_clk_p = 1'b1;
      #4000 ;

    end
  end

initial begin
    drp_clk = 1'b0;
    forever begin
     drp_clk = 1'b0;
      #10000 ;
     drp_clk = 1'b1;
      #10000 ;

    end
  end

initial begin
    lvds_clk = 1'b0;
    forever begin
      lvds_clk = 1'b0;
      #800 ;
      lvds_clk = 1'b1;
      #800 ;
    end
  end



  initial                 // drives Rx stimulus clock at 125 MHz
  begin
    stim_rx_clk <= 1'b0;
    forever
    begin
      stim_rx_clk <= 1'b0;
      #4000;
      stim_rx_clk <= 1'b1;
      #4000;
    end
  end

  initial                 // drives p_stim_tx_clk_1000 at 125 MHz
  begin
    stim_tx_clk_1000 <= 1'b0;
    forever
    begin
      stim_tx_clk_1000 <= 1'b0;
      #4000;
      stim_tx_clk_1000 <= 1'b1;
      #4000;
    end
  end

  initial                 // drives stim_tx_clk_100 at 12.5 MHz
  begin
    stim_tx_clk_100 <= 1'b0;
    forever
    begin
      stim_tx_clk_100 <= 1'b0;
      #40000;
      stim_tx_clk_100 <= 1'b1;
      #40000;
    end
  end

  initial                 // drives stim_tx_clk_10 at 12.5 MHz
  begin
    stim_tx_clk_10 <= 1'b0;
    forever
    begin
      stim_tx_clk_10 <= 1'b0;
      #400000;
      stim_tx_clk_10 <= 1'b1;
      #400000;
    end
  end
// Select between 10Mb/s, 100Mb/s and 1Gb/s Tx clock frequencies
  always @ * begin
    if (speed_is_10_100 == 1'b0) begin
      stim_tx_clk <= stim_tx_clk_1000;
    end
    else begin
      if (speed_is_100) begin
        stim_tx_clk <= stim_tx_clk_100;
      end
      else begin
        stim_tx_clk <= stim_tx_clk_10;
      end
    end
  end

  initial                 // drives bitclock at 1.25GHz
  begin
    bitclock <= 1'b0;
    forever
    begin
      bitclock <= 1'b0;
      #(UI/2);
      bitclock <= 1'b1;
      #(UI/2);
    end
  end

// monitor clock for the GMII receiver.
  assign mon_tx_clk = stim_tx_clk_1000;

//drives input to an MMCM at 200MHz which creates gtx_clk at 125 MHz


//----------------------------------------------------------------------------
// A Task to reset the MAC
//----------------------------------------------------------------------------
    task mac_reset;
        begin
            $display("** Note: Resetting core...");

            reset <= 1'b1;
            #400000

            reset <= 1'b0;

        end
    endtask // mac_reset;

    task send_command;
        input [7:0] data;
    begin
        cmnd_data       = data;
        cmnd_data_valid = 1'b1;
        wait(cmnd_data_ready);
        cmnd_data_valid = 1'b0;
        $display ( "+++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        $display ( " Configured DUT with control word %h at time %t ", data, $time);
        $display ( "+++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    end
    endtask


// monitor frame error and output error when asserted (with timestamp)
  always @(posedge gtx_clk or posedge reset)
  begin
     if (reset) begin
        bist_mode_error <= 0;
     end
     else if (frame_error & !bist_mode_error) begin
        bist_mode_error <= 1;
        $display("ERROR: frame mismatch at time %t ", $time);
     end
  end

//----------------------------------------------------------------------------
// Management process. This process waits for setup to complete by monitoring the mdio
// (the host always runs at gtx_clk so the setup after mdio accesses are complete
// doesn't take long) and then allows packets to be sent
//----------------------------------------------------------------------------
  initial
  begin : p_management

    mac_speed <= 2'b10;
    phy_speed <= 2'b10;
    update_speed <= 1'b0;
    gen_tx_data <= 1'b0;
    check_tx_data <= 1'b0;
    config_bist <= 0;
    management_config_finished <= 0;
    cmnd_data <= 8'h00;
    cmnd_data_valid <= 1'b0;
    start_config <= 1'b0;


// reset the core
    mac_reset;
    #100000;
   
        repeat(15) 
           #200000000; // LVDS CDR Lock

    #100000;
    if(TB_MODE == "DEMO")
        send_command(CMNDSETSLAVELOOPBACK);
    else   
        send_command(CMNDSETMASTERLOOPBACK);
    start_config <= 1'b1;
    #200000000; // wait for all management programming to happen

    if (TB_MODE == "BIST") begin
       gen_tx_data <= 1'b1;
       check_tx_data <= 1'b1;
// run for a set time and then stop
       repeat (500000) @(posedge gtx_clk);
// Our work here is done

       if(hw_frame_cnt <5) begin
          $display("ERROR: No sufficient frames transmitted So far....");
       end
       if (frame_error) begin
          $display("ERROR: Frame mismatch seen");
       end
       else if (serial_response) begin
          $display("ERROR: AXI4 Lite state Machine error.  Incorrect or non-existant PTP frame.");
       end
       else begin
           if(mdio_txn_found == 1'b0) begin
             $display("FAIL : MDIO Transaction not happend %t ", $time);
           end
          
          $display("Test completed successfully");
       end
       $display("Simulation Stopped");
       $stop;
    end
    else begin

// Signal that configuration is complete.  Other processes will now
// be allowed to run.
// The stimulus process will now send 5 frames at 1Gb/s.
       management_config_finished = 0;
       @(posedge gtx_clk);
       mac_speed <= 2'b10;
       update_speed <= 1'b1;
       @(posedge gtx_clk);
        @(posedge gtx_clk);
       @(posedge gtx_clk);
       update_speed <= 1'b0;
        send_command(CMNDSETSPEED1000);
        #200_000_000;
       #1000000;

       phy_speed <= 2'b10;
////// wait for the mdio access and remainder of setup accesses (internal)
// mostly moved to example design axi lite conttroller init_config();
// Wait for 1G monitor process to complete.
       management_config_finished = 1;
       wait (tx_monitor_finished_1G == 1);
// Signal that configuration is complete.  Other processes will now
// be allowed to run.
////initiate_reset();
       management_config_finished = 0;

//------------------------------------------------------------------
// Change the speed to 100Mb/s and send the 5 frames
//------------------------------------------------------------------


// The stimulus process will now send 5 frames at 100 Mb/s.
       #10000;
       @(posedge gtx_clk);
//initiate_reset();
       #2000000; //allow frames to flush out of DUT
       #50000000;
       mac_speed <= 2'b01;
       phy_speed <= 2'b01;
        send_command(CMNDSETSPEED100);
        #200_000_000;
       #1000000;
       management_config_finished = 1;
// Wait for 100M monitor process to complete.
       wait (tx_monitor_finished_100M == 1);
       management_config_finished = 0;
       update_speed <= 1'b1;
       @(posedge gtx_clk);
       @(posedge gtx_clk);
       @(posedge gtx_clk);
       update_speed <= 1'b0;

//------------------------------------------------------------------
// Change the speed to 10Mb/s and send the 5 frames
//------------------------------------------------------------------
       #100000;
       #20000000; //allow frames to flush out of DUT
       #50000000;
       phy_speed <= 2'b00;
       mac_speed <= 2'b00;
       #10000;
        send_command(CMNDSETSPEED10);
        #200_000_000;
       #1000000;
// mostly moved to example design axi lite conttroller init_config();
       management_config_finished = 1;
// Wait for 10M monitor process to complete.
       wait (tx_monitor_finished_10M == 1);
       management_config_finished = 0;

       #1000000;
// Change the speed back to 1Gb/s and send the 5 frames
//------------------------------------------------------------------

       @(posedge gtx_clk);
       mac_speed <= 2'b10;
       phy_speed <= 2'b10;
       #1000000;
        send_command(CMNDSETSPEED1000);
        #200_000_000;
       update_speed <= 1'b1;
       #1000000;
       @(posedge gtx_clk);
       @(posedge gtx_clk);
       @(posedge gtx_clk);
       update_speed <= 1'b0;

// changed for 1G -----------

       #10000;
// mostly moved to example design axi lite conttroller init_config();
       management_config_finished = 1;
       wait (tx_monitor_finished_1G == 1);
// Our work here is done
       if (demo_mode_error == 1'b0 && bist_mode_error == 1'b0) begin
         $display("Test completed successfully");
       end
       $display("Simulation Stopped");
       $stop;
     end
  end // p_management

//sgmii 10, 100, 1000 clkocks
// Unit Interval for Gigabit Ethernet


//----------------------------------------------------------------------------
// Procedure to perform 8B10B decoding
//----------------------------------------------------------------------------

// Decode the 8B10B code. No disparity verification is performed, just
// a simple table lookup.
    task decode_8b10b;
        input  [0:9] d10;
        output [7:0] q8;
        output       is_k;
        reg          k28;
        reg    [9:0] d10_rev;
        integer I;
    begin
// reverse the 10B codeword
        for (I = 0; I < 10; I = I + 1)
            d10_rev[I] = d10[I];
        case (d10_rev[5:0])
            6'b000110 : q8[4:0] = 5'b00000;   //D.0
            6'b111001 : q8[4:0] = 5'b00000;   //D.0
            6'b010001 : q8[4:0] = 5'b00001;   //D.1
            6'b101110 : q8[4:0] = 5'b00001;   //D.1
            6'b010010 : q8[4:0] = 5'b00010;   //D.2
            6'b101101 : q8[4:0] = 5'b00010;   //D.2
            6'b100011 : q8[4:0] = 5'b00011;   //D.3
            6'b010100 : q8[4:0] = 5'b00100;   //D.4
            6'b101011 : q8[4:0] = 5'b00100;   //D.4
            6'b100101 : q8[4:0] = 5'b00101;   //D.5
            6'b100110 : q8[4:0] = 5'b00110;   //D.6
            6'b000111 : q8[4:0] = 5'b00111;   //D.7
            6'b111000 : q8[4:0] = 5'b00111;   //D.7
            6'b011000 : q8[4:0] = 5'b01000;   //D.8
            6'b100111 : q8[4:0] = 5'b01000;   //D.8
            6'b101001 : q8[4:0] = 5'b01001;   //D.9
            6'b101010 : q8[4:0] = 5'b01010;   //D.10
            6'b001011 : q8[4:0] = 5'b01011;   //D.11
            6'b101100 : q8[4:0] = 5'b01100;   //D.12
            6'b001101 : q8[4:0] = 5'b01101;   //D.13
            6'b001110 : q8[4:0] = 5'b01110;   //D.14
            6'b000101 : q8[4:0] = 5'b01111;   //D.15
            6'b111010 : q8[4:0] = 5'b01111;   //D.15
            6'b110110 : q8[4:0] = 5'b10000;   //D.16
            6'b001001 : q8[4:0] = 5'b10000;   //D.16
            6'b110001 : q8[4:0] = 5'b10001;   //D.17
            6'b110010 : q8[4:0] = 5'b10010;   //D.18
            6'b010011 : q8[4:0] = 5'b10011;   //D.19
            6'b110100 : q8[4:0] = 5'b10100;   //D.20
            6'b010101 : q8[4:0] = 5'b10101;   //D.21
            6'b010110 : q8[4:0] = 5'b10110;   //D.22
            6'b010111 : q8[4:0] = 5'b10111;   //D/K.23
            6'b101000 : q8[4:0] = 5'b10111;   //D/K.23
            6'b001100 : q8[4:0] = 5'b11000;   //D.24
            6'b110011 : q8[4:0] = 5'b11000;   //D.24
            6'b011001 : q8[4:0] = 5'b11001;   //D.25
            6'b011010 : q8[4:0] = 5'b11010;   //D.26
            6'b011011 : q8[4:0] = 5'b11011;   //D/K.27
            6'b100100 : q8[4:0] = 5'b11011;   //D/K.27
            6'b011100 : q8[4:0] = 5'b11100;   //D.28
            6'b111100 : q8[4:0] = 5'b11100;   //K.28
            6'b000011 : q8[4:0] = 5'b11100;   //K.28
            6'b011101 : q8[4:0] = 5'b11101;   //D/K.29
            6'b100010 : q8[4:0] = 5'b11101;   //D/K.29
            6'b011110 : q8[4:0] = 5'b11110;   //D.30
            6'b100001 : q8[4:0] = 5'b11110;   //D.30
            6'b110101 : q8[4:0] = 5'b11111;   //D.31
            6'b001010 : q8[4:0] = 5'b11111;   //D.31
            default   : q8[4:0] = 5'b11110;    //CODE VIOLATION - return /E/
        endcase

        k28 = ~((d10[2] | d10[3] | d10[4] | d10[5] | ~(d10[8] ^ d10[9])));

        case (d10_rev[9:6])
            4'b0010 : q8[7:5] = 3'b000;       //D/K.x.0
            4'b1101 : q8[7:5] = 3'b000;       //D/K.x.0
            4'b1001 :
                if (!k28)
                    q8[7:5] = 3'b001;             //D/K.x.1
                else
                    q8[7:5] = 3'b110;             //K28.6
                4'b0110 :
                    if (k28)
                        q8[7:5] = 3'b001;         //K.28.1
                    else
                        q8[7:5] = 3'b110;         //D/K.x.6
                    4'b1010 :
                        if (!k28)
                            q8[7:5] = 3'b010;         //D/K.x.2
                        else
                            q8[7:5] = 3'b101;         //K28.5
                        4'b0101 :
                            if (k28)
                                q8[7:5] = 3'b010;         //K28.2
                            else
                                q8[7:5] = 3'b101;         //D/K.x.5
                            4'b0011 : q8[7:5] = 3'b011;       //D/K.x.3
                            4'b1100 : q8[7:5] = 3'b011;       //D/K.x.3
                            4'b0100 : q8[7:5] = 3'b100;       //D/K.x.4
                            4'b1011 : q8[7:5] = 3'b100;       //D/K.x.4
                            4'b0111 : q8[7:5] = 3'b111;       //D.x.7
                            4'b1000 : q8[7:5] = 3'b111;       //D.x.7
                            4'b1110 : q8[7:5] = 3'b111;       //D/K.x.7
                            4'b0001 : q8[7:5] = 3'b111;       //D/K.x.7
                            default : q8[7:5] = 3'b111;   //CODE VIOLATION - return /E/
        endcase
        is_k = ((d10[2] & d10[3] & d10[4] & d10[5])
        | ~(d10[2] | d10[3] | d10[4] | d10[5])
        | ((d10[4] ^ d10[5]) & ((d10[5] & d10[7] & d10[8] & d10[9])
    | ~(d10[5] | d10[7] | d10[8] | d10[9]))));

    end
    endtask // decode_8b10b



//----------------------------------------------------------------------------
// Procedure to perform comma detection
//----------------------------------------------------------------------------

    function is_comma;
        input [0:9] codegroup;
    begin
        case (codegroup[0:6])
            7'b0011111 : is_comma = 1;
            7'b1100000 : is_comma = 1;
            default : is_comma = 0;
        endcase // case(codegroup[0:6])
    end
    endfunction // is_comma


//----------------------------------------------------------------------------
// Procedure to perform 8B10B encoding
//----------------------------------------------------------------------------

    task encode_8b10b;
        input [7:0] d8;
        input is_k;
        output [0:9] q10;
        input disparity_pos_in;
        output disparity_pos_out;
        reg [5:0] b6;
        reg [3:0] b4;
        reg k28, pdes6, a7, l13, l31, a, b, c, d, e;
        integer I;

    begin  // encode_8b10b
// precalculate some common terms
        a = d8[0];
        b = d8[1];
        c = d8[2];
        d = d8[3];
        e = d8[4];

        k28 = is_k && d8[4:0] === 5'b11100;

        l13 = (((a ^ b) & !(c | d))
                | ((c ^ d) & !(a | b)));

        l31 = (((a ^ b) & (c & d))
                | ((c ^ d) & (a & b)));

        a7  = is_k | ((l31 & d & !e & disparity_pos_in)
                   | (l13 & !d & e & !disparity_pos_in));

// calculate the running disparity after the 5B6B block encode
        if (k28)                           //K.28
            if (!disparity_pos_in)
                b6 = 6'b111100;
            else
                b6 = 6'b000011;

        else
            case (d8[4:0])
                5'b00000 :                 //D.0
                    if (disparity_pos_in)
                        b6 = 6'b000110;
                    else
                        b6 = 6'b111001;
                5'b00001 :                 //D.1
                    if (disparity_pos_in)
                        b6 = 6'b010001;
                    else
                        b6 = 6'b101110;
                5'b00010 :                 //D.2
                    if (disparity_pos_in)
                        b6 = 6'b010010;
                    else
                        b6 = 6'b101101;
                5'b00011 :
                    b6 = 6'b100011;              //D.3
                5'b00100 :                 //-D.4
                    if (disparity_pos_in)
                        b6 = 6'b010100;
                    else
                        b6 = 6'b101011;
                5'b00101 :
                    b6 = 6'b100101;          //D.5
                5'b00110 :
                    b6 = 6'b100110;          //D.6
                5'b00111 :                 //D.7
                    if (!disparity_pos_in)
                        b6 = 6'b000111;
                    else
                        b6 = 6'b111000;
                5'b01000 :                 //D.8
                    if (disparity_pos_in)
                        b6 = 6'b011000;
                    else
                        b6 = 6'b100111;
                5'b01001 :
                    b6 = 6'b101001;          //D.9
                5'b01010 :
                    b6 = 6'b101010;          //D.10
                5'b01011 :
                    b6 = 6'b001011;          //D.11
                5'b01100 :
                    b6 = 6'b101100;          //D.12
                5'b01101 :
                    b6 = 6'b001101;          //D.13
                5'b01110 :
                    b6 = 6'b001110;          //D.14
                5'b01111 :                 //D.15
                    if (disparity_pos_in)
                        b6 = 6'b000101;
                    else
                        b6 = 6'b111010;

                5'b10000 :                 //D.16
                    if (!disparity_pos_in)
                        b6 = 6'b110110;
                    else
                        b6 = 6'b001001;

                5'b10001 :
                    b6 = 6'b110001;          //D.17
                5'b10010 :
                    b6 = 6'b110010;          //D.18
                5'b10011 :
                    b6 = 6'b010011;          //D.19
                5'b10100 :
                    b6 = 6'b110100;          //D.20
                5'b10101 :
                    b6 = 6'b010101;          //D.21
                5'b10110 :
                    b6 = 6'b010110;          //D.22
                5'b10111 :                 //D/K.23
                    if (!disparity_pos_in)
                        b6 = 6'b010111;
                    else
                        b6 = 6'b101000;
                5'b11000 :                 //D.24
                    if (disparity_pos_in)
                        b6 = 6'b001100;
                    else
                        b6 = 6'b110011;
                5'b11001 :
                    b6 = 6'b011001;          //D.25
                5'b11010 :
                    b6 = 6'b011010;          //D.26
                5'b11011 :                 //D/K.27
                    if (!disparity_pos_in)
                        b6 = 6'b011011;
                    else
                        b6 = 6'b100100;
                5'b11100 :
                    b6 = 6'b011100;          //D.28
                5'b11101 :                 //D/K.29
                    if (!disparity_pos_in)
                        b6 = 6'b011101;
                    else
                        b6 = 6'b100010;
                5'b11110 :                 //D/K.30
                    if (!disparity_pos_in)
                        b6 = 6'b011110;
                    else
                        b6 = 6'b100001;
                5'b11111 :                 //D.31
                    if (!disparity_pos_in)
                        b6 = 6'b110101;
                    else
                        b6 = 6'b001010;
                default :
                    b6 = 6'bXXXXXX;
            endcase // case(d8[4:0])

// reverse the bits
        for (I = 0; I < 6; I = I + 1)
            q10[I] = b6[I];


// calculate the running disparity after the 5B6B block encode
        if (k28)
            pdes6 = !disparity_pos_in;
        else
            case (d8[4:0])
                5'b00000 : pdes6 = !disparity_pos_in;
                5'b00001 : pdes6 = !disparity_pos_in;
                5'b00010 : pdes6 = !disparity_pos_in;
                5'b00011 : pdes6 = disparity_pos_in;
                5'b00100 : pdes6 = !disparity_pos_in;
                5'b00101 : pdes6 = disparity_pos_in;
                5'b00110 : pdes6 = disparity_pos_in;
                5'b00111 : pdes6 = disparity_pos_in;
                5'b01000 : pdes6 = !disparity_pos_in;
                5'b01001 : pdes6 = disparity_pos_in;
                5'b01010 : pdes6 = disparity_pos_in;
                5'b01011 : pdes6 = disparity_pos_in;
                5'b01100 : pdes6 = disparity_pos_in;
                5'b01101 : pdes6 = disparity_pos_in;
                5'b01110 : pdes6 = disparity_pos_in;
                5'b01111 : pdes6 = !disparity_pos_in;
                5'b10000 : pdes6 = !disparity_pos_in;
                5'b10001 : pdes6 = disparity_pos_in;
                5'b10010 : pdes6 = disparity_pos_in;
                5'b10011 : pdes6 = disparity_pos_in;
                5'b10100 : pdes6 = disparity_pos_in;
                5'b10101 : pdes6 = disparity_pos_in;
                5'b10110 : pdes6 = disparity_pos_in;
                5'b10111 : pdes6 = !disparity_pos_in;
                5'b11000 : pdes6 = !disparity_pos_in;
                5'b11001 : pdes6 = disparity_pos_in;
                5'b11010 : pdes6 = disparity_pos_in;
                5'b11011 : pdes6 = !disparity_pos_in;
                5'b11100 : pdes6 = disparity_pos_in;
                5'b11101 : pdes6 = !disparity_pos_in;
                5'b11110 : pdes6 = !disparity_pos_in;
                5'b11111 : pdes6 = !disparity_pos_in;
                default  : pdes6 = disparity_pos_in;
            endcase // case(d8[4:0])

        case (d8[7:5])
            3'b000 :                     //D/K.x.0
                if (pdes6)
                    b4 = 4'b0010;
                else
                    b4 = 4'b1101;
            3'b001 :                     //D/K.x.1
             if (k28 && !pdes6)
               b4 = 4'b0110;
             else
               b4 = 4'b1001;
     3'b010 :                     //D/K.x.2
             if (k28 && !pdes6)
               b4 = 4'b0101;
             else
               b4 = 4'b1010;
     3'b011 :                     //D/K.x.3
             if (!pdes6)
               b4 = 4'b0011;
             else
               b4 = 4'b1100;
     3'b100 :                     //D/K.x.4
             if (pdes6)
               b4 = 4'b0100;
             else
               b4 = 4'b1011;
     3'b101 :                     //D/K.x.5
             if (k28 && !pdes6)
               b4 = 4'b1010;
             else
               b4 = 4'b0101;
     3'b110 :                     //D/K.x.6
             if (k28 && !pdes6)
               b4 = 4'b1001;
             else
               b4 = 4'b0110;
     3'b111 :                     //D.x.P7
             if (!a7)
               if (!pdes6)
     b4 = 4'b0111;
               else
     b4 = 4'b1000;
             else                   //D/K.y.A7
               if (!pdes6)
     b4 = 4'b1110;
               else
     b4 = 4'b0001;
     default :
             b4 = 4'bXXXX;
   endcase

// Reverse the bits
        for (I = 0; I < 4; I = I + 1)
            q10[I+6] = b4[I];

// Calculate the running disparity after the 4B group
        case (d8[7:5])
            3'b000  : disparity_pos_out = ~pdes6;
            3'b001  : disparity_pos_out = pdes6;
            3'b010  : disparity_pos_out = pdes6;
            3'b011  : disparity_pos_out = pdes6;
            3'b100  : disparity_pos_out = ~pdes6;
            3'b101  : disparity_pos_out = pdes6;
            3'b110  : disparity_pos_out = pdes6;
            3'b111  : disparity_pos_out = ~pdes6;
            default : disparity_pos_out = pdes6;
        endcase
    end
    endtask // encode_8b10b

// Set the expected data rate: sample the data on every clock at
// 1Gbps, every 10 clocks at 100Mbps, every 100 clocks at 10Mbps
    integer sample_count;

    initial
        sample_count = 0;

    always @(posedge stim_rx_clk)
    begin : gen_clock_enable
        if (speed_is_10_100 == 1'b0) begin
            sample_count  = 0;
            clock_enable <= 1'b1;                            // sample on every clock
        end
        else begin
            if ((speed_is_100 &&  sample_count == 9) ||      // sample every 10 clocks
                (!speed_is_100 &&  sample_count == 99)) begin // sample every 100 clocks
                    sample_count  = 0;
                    clock_enable <= 1'b1;
                end
                else begin
                    if (sample_count == 99) begin
                        sample_count = 0;
                    end
                    else begin
                        sample_count = sample_count + 1;
                    end
                    clock_enable <= 1'b0;
                end
        end
    end

// A task to create an Idle /I1/ code group
    task send_I1;
        begin
            rx_pdata  <= 8'hBC;  // /K28.5/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
            rx_pdata  <= 8'hC5;  // /D5.6/
            rx_is_k   <= 1'b0;
            @(posedge stim_rx_clk);
        end
    endtask // send_I1;

// A task to create an Idle /I2/ code group
    task send_I2;
        begin
            rx_pdata  <= 8'hBC;  // /K28.5/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
            rx_pdata  <= 8'h50;  // /D16.2/
            rx_is_k   <= 1'b0;
            @(posedge stim_rx_clk);
        end
    endtask // send_I2;

// A task to create a Start of Packet /S/ code group
    task send_S;
        begin
            rx_pdata  <= 8'hFB;  // /K27.7/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    endtask // send_S;

// A task to create a Start of Packet SFD code group
    task send_SFD;
        begin
            rx_pdata  <= 8'hD5;  // /D21.6/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    endtask // send_SFD;

// A task to send Preamble
    task send_preamble;
        integer i;
    begin      
        for(i=0;i<7;i=i+1) begin
            rx_pdata  <= 8'h55;  // /D21.6/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    end
    endtask // send_preamble;

// A task to create a Terminate /T/ code group
    task send_T;
        begin
            rx_pdata  <= 8'hFD;  // /K29.7/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    endtask // send_T;

// A task to create a Carrier Extend /R/ code group
    task send_R;
        begin
            rx_pdata  <= 8'hF7;  // /K23.7/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    endtask // send_R;

// A task to create an Error Propogation /V/ code group
    task send_V;
        begin
            rx_pdata  <= 8'hFE;  // /K30.7/
            rx_is_k   <= 1'b1;
            @(posedge stim_rx_clk);
        end
    endtask // send_V;


    task send_frame;  
        input   `FRAME_TYP frame;
        integer column_index;
        integer I;
        reg [31:0] fcs;

    begin
// import the frame into scratch space
        rx_stimulus_working_frame.frombits(frame);
        fcs = 32'h0;

//----------------------------------
// Send a Start of Packet code group
//----------------------------------
        send_S;

//----------------------------------
// Send Preamble
//----------------------------------
        repeat(num_of_repeat)
            send_preamble;

//----------------------------------
// Send a SFD
//----------------------------------
        repeat(num_of_repeat)
            send_SFD;

//----------------------------------
// Send frame data
//----------------------------------
        column_index = 0;

// loop over columns in frame
        while (rx_stimulus_working_frame.valid[column_index] != 1'b0) begin
            if (rx_stimulus_working_frame.error[column_index] == 1'b1) begin
                repeat(num_of_repeat)
                    send_V; // insert an error propogation code group
            end   
            else
            begin
/////
/////
                repeat(num_of_repeat) begin
                    rx_pdata <= rx_stimulus_working_frame.data[column_index];
                    rx_is_k  <= 1'b0;
                    @(posedge stim_rx_clk);
                end
                calc_crc(rx_stimulus_working_frame.data[column_index],fcs);
            end
            column_index = column_index + 1;
        end // while

//send CRC
        for(I=1;I<=4;I=I+1) begin
            repeat(num_of_repeat) begin
                rx_pdata <= fcs[((I*8)-1)-:8];
                rx_is_k  <= 1'b0;
                @(posedge stim_rx_clk);
            end
        end

//----------------------------------
// Send a frame termination sequence
//----------------------------------
        send_T;    // Terminate code group
        send_R;    // Carrier Extend code group

// An extra Carrier Extend code group should be sent to end the frame
// on an even boundary.
        if (rx_even == 1'b1)
            send_R;  // Carrier Extend code group

//----------------------------------
// Send an Inter Packet Gap.
//----------------------------------
// The initial Idle following a frame should be chosen to ensure
// that the running disparity is returned to -ve.
        if (rx_rundisp_pos == 1'b1)
            send_I1;  // /I1/ will flip the running disparity
        else
            send_I2;  // /I2/ will maintain the running disparity

// The remainder of the IPG is made up of /I2/ 's.
// NOTE: the number 4 in the following calculations is made up
//      from 2 bytes of the termination sequence and 2 bytes from
//      the initial Idle.

// 1Gb/s: 4 /I2/'s = 8 clock periods (12 - 4)
        if (!speed_is_10_100) begin
            for (I = 0; I < 4; I = I + 1)
                send_I2;
        end

        else begin
// 100Mb/s: 58 /I2/'s = 116 clock periods (120 - 4)
            if (speed_is_100) begin
                for (I = 0; I < 58; I = I + 1)
                    send_I2;
            end

// 10Mb/s: 598 /I2/'s = 1196 clock periods (1200 - 4)
            else begin
                for (I = 0; I < 598; I = I + 1)
                    send_I2;
            end
        end

    end
    endtask // send_frame;

// A task to serialise a single 10-bit code group
    task rx_stimulus_send_10b_column;
        input [0:9] d;
        integer I;
    begin
        for (I = 0; I < 10; I = I + 1)
        begin
            @(posedge bitclock)
            rxp <= d[I];
            rxn <= ~d[I];
        end // I
    end
    endtask // rx_stimulus_send_10b_column




//----------------------------------------------------------------------------
// Stimulus process. This process will inject frames of data into the
// PHY side of the receiver.
//----------------------------------------------------------------------------
    initial
    begin : p_rx_stimulus

// Initialise stimulus
        rx_rundisp_pos <= 0;      // Initialise running disparity
        rx_pdata       <= 8'hBC;  // /K28.5/
        rx_is_k        <= 1'b1;


// Send four frames through the MAC and Design Exampled
// at each state Ethernet speed
//      -- frame 0 = standard frame
//      -- frame 1 = type frame
//      -- frame 2 = frame containing an error
//      -- frame 3 = standard frame with padding

//-----------------------------------------------------



// 1 Gb/s speed
//-----------------------------------------------------
// Wait for the Management MDIO transaction to finish.
////while (management_config_finished !== 1)
// wait for the internal resets to settle before staring to send traffic
        @(posedge stim_rx_clk);    
        while (management_config_finished !== 1)
            send_I2;
          $display("Rx Stimulus: %t sending 5 frames at 1G ... ",$time);

        send_frame(frame0.tobits(0));
	$display("Finished sending ...");
        //send_frame(frame1.tobits(1));
        //send_frame(frame2.tobits(2));
        //send_frame(frame3.tobits(3));
        while (tx_monitor_finished_1G != 1)
            send_I2;

// 100 Mb/s speed
//-----------------------------------------------------
        while (management_config_finished !== 1)
            send_I2;
        $display("Rx Stimulus: sending 5 frames at 100M ... ");
        send_frame(frame0.tobits(0));
        send_frame(frame1.tobits(1));
        send_frame(frame2.tobits(2));
        send_frame(frame3.tobits(3));
        while (tx_monitor_finished_100M != 1)
            send_I2;


// 10 Mb/s speed
//-----------------------------------------------------
        while (management_config_finished !== 1)
            send_I2;
        $display("Rx Stimulus: sending 5 frames at 10M ... ");
        send_frame(frame0.tobits(0));
        send_frame(frame1.tobits(1));
        send_frame(frame2.tobits(2));
        send_frame(frame3.tobits(3));
        while (tx_monitor_finished_10M != 1)
            send_I2;


// 1 Gb/s speed
//-----------------------------------------------------
        while (management_config_finished != 1)
            send_I2;
        send_frame(frame0.tobits(0));
        send_frame(frame1.tobits(1));
        send_frame(frame2.tobits(2));
        send_frame(frame3.tobits(3));
        forever
        send_I2;

    end // p_rx_stimulus

//----------------------------------------------------------------------------
// A process to keep track of the even/odd code group position for the
// injected receiver code groups.
//----------------------------------------------------------------------------
    initial
    begin : p_rx_even_odd
        rx_even <= 1'b0;
        forever
            begin
                @(posedge stim_rx_clk)
                rx_even <= ! rx_even;
            end
    end // p_rx_even_odd


// 8B10B encode the Rx stimulus
    initial
    begin : p_rx_encode
        reg [0:9] encoded_data;

// Get synced up with the Rx clock
        @(posedge stim_rx_clk)

// Perform 8B10B encoding of the data stream
        forever
            begin
                encode_8b10b(
                    rx_pdata,
                    rx_is_k,
                    encoded_data,
                    rx_rundisp_pos,
                rx_rundisp_pos);

                rx_stimulus_send_10b_column(encoded_data);
            end // forever
    end // p_rx_encode

    initial
    begin : p_tx_decode

        reg [0:9] code_buffer;
        reg [7:0] decoded_data;
        integer bit_count;
        reg is_k_var;
        reg initial_sync;

        bit_count = 0;
        initial_sync = 0;

        forever
    begin
        @(negedge bitclock);
        code_buffer = {code_buffer[1:9], txp};
// comma detection
        if (is_comma(code_buffer))
        begin
            bit_count = 0;
            initial_sync = 1;
        end

        if (bit_count == 0 && initial_sync)
        begin
// Perform 8B10B decoding of the data stream
            tenbit_data = code_buffer;
            decode_8b10b(code_buffer,
            decoded_data,
        is_k_var);

// drive the output signals with the results
        tx_pdata <= decoded_data;

        if (is_k_var)
            tx_is_k <= 1'b1;
        else
            tx_is_k <= 1'b0;
        end

        if (initial_sync)
        begin
            bit_count = bit_count + 1;
            if (bit_count == 10)
                bit_count = 0;
        end

    end // forever
    end // p_tx_decode



    assign num_of_repeat = (mac_speed == 2'b10 ? 1 :
                            mac_speed == 2'b01 ? 10 :
                           (mac_speed == 2'b00 ? 100:1));




    task check_frame;
        input `FRAME_TYP frame;
        input integer frame_number;
        integer column_index;
        reg frame_filtered;
        reg[95:0] addr_comp_reg;
        integer J,I;
        reg [31:0] fcs;
        reg [8*4:0] frame_type;

    begin
        $timeformat(-9, 0, "ns", 7);
        tx_monitor_working_frame.frombits(frame);
        column_index = 0;
        frame_filtered = 1'b0;  
        J=0;
        fcs = 32'h0;
        addr_comp_reg = 0;

        while (tx_monitor_working_frame.valid[column_index] !== 1'b0 && column_index < 12)
        begin
            for (J = 0; J < 8; J = J + 1) begin
                addr_comp_reg[column_index*8+J] = tx_monitor_working_frame.data[column_index][J];
            end
            column_index = column_index + 1;
        end

        if (addr_comp_reg === address_filter_value) begin
            frame_filtered = 0;
        end
        else begin
            frame_filtered = 1;
        end

            frame_filtered = 0;

        column_index = 0;
        if  (frame_filtered === 1'b1) begin
            $display("FRAME %d DROPPED by Address Filter ",frame_number);
        end

        if(tx_monitor_working_frame.bad_frame === 1'b1 || frame_filtered == 1'b1)   
        begin
            $display("Frame %d is Dropped ",frame_number);
        end 
        else
        begin
// Detect the Start of Frame
            while (tx_pdata !== 8'hFB) begin
                @(posedge mon_tx_clk);
                #1;
            end

// Move past the Start of Frame code to the 1st byte of preamble
            repeat (num_of_repeat) begin
                @(posedge mon_tx_clk);
                #1;
            end
// tx_pdata should now hold the SFD.  We need to move to the SFD of the injected frame.
            while(tx_pdata !== 8'hD5) begin
                repeat (num_of_repeat) begin
                    @(posedge mon_tx_clk);
                    #1;
                end
            end
            if (TB_MODE == "DEMO") begin
// Start comparing transmitted frame data to the injected frame data
                repeat (num_of_repeat) begin
                    @(posedge mon_tx_clk);
                    #1;
                end

                $display("Tx Monitor : Comparing transmitted frame with injected frame %d", frame_number);

// frame has started, loop over columns of frame until the frame termination is detected
                while (tx_monitor_working_frame.valid[column_index] !== 1'b0) begin        
                    calc_crc(tx_pdata,fcs);
                    if(column_index < 6) begin
                        if (tx_pdata !== tx_monitor_working_frame.data[column_index+6]) begin
                            $display("** Error: Tx Monitor : data incorrect during DA at %t tx_pdata=%h frame_data = %h",  $realtime,tx_pdata,tx_monitor_working_frame.data[column_index]);
                            demo_mode_error <= 1;
                        end 
                    end
                    else if(column_index < 12) begin
                        if (tx_pdata !== tx_monitor_working_frame.data[column_index-6]) begin
                            $display("** Error: Tx Monitor : data incorrect during SA at %t tx_pdata=%h frame_data = %h",  $realtime,tx_pdata,tx_monitor_working_frame.data[column_index]);
                            demo_mode_error <= 1;
                        end 
                    end
                    else begin
                        if (tx_pdata !== tx_monitor_working_frame.data[column_index]) begin
                            $display("** Error: Tx Monitor : data incorrect during frame at %t tx_pdata=%h frame_data = %h",  $realtime,tx_pdata,tx_monitor_working_frame.data[column_index]);
                            demo_mode_error <= 1;
                        end 
                    end
                    column_index = column_index + 1;
                    repeat (num_of_repeat) begin
                        @(posedge mon_tx_clk);
                        #1;
                    end
                end
                for(I=0;I<4;I=I+1) begin
                    case(I)
                        0 :  if (tx_pdata !== fcs[7:0]) begin
                            $display("** ERROR: gmii_txd incorrect during frame %d  FCS field at %t txdata = %h fcs = %h", frame_number,$realtime,tx_pdata,fcs);
                            demo_mode_error <= 1;
                        end
                        1 :  if (tx_pdata !== fcs[15:8]) begin
                            $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime, "ps");
                            $display("** ERROR: gmii_txd incorrect during frame %d  FCS field at %t txdata = %h fcs = %h", frame_number,$realtime,tx_pdata,fcs);
                            demo_mode_error <= 1;
                        end
                        2 :  if (tx_pdata !== fcs[23:16]) begin
                            $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime, "ps");
                            $display("** ERROR: gmii_txd incorrect during frame %d  FCS field at %t txdata = %h fcs = %h", frame_number,$realtime,tx_pdata,fcs);
                            demo_mode_error <= 1;
                        end
                        3 :  if (tx_pdata !== fcs[31:24]) begin
                            $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime, "ps");
                            $display("** ERROR: gmii_txd incorrect during frame %d  FCS field at %t txdata = %h fcs = %h", frame_number,$realtime,tx_pdata,fcs);
                            demo_mode_error <= 1;
                        end
                    endcase
                    repeat (num_of_repeat) begin
                        @(posedge mon_tx_clk);
                        #1;
                    end
                end
            end 
            else begin
// this is the BIST tb mode - want to idnetify the frame type  - VLAN or not to help with the bandwidth calc
// check the type field and if equal to 81 then classify as vlan (could do more but that should be adequate)
                frame_type = "";
                for (I = 0; I < 10; I = I + 1) begin
                    tenbit_data_rev[I] = tenbit_data[9 - I];
                end
                while (tenbit_data != 10'h2E8 && tenbit_data != 10'h117) begin
                    for (I = 0; I < 10; I = I + 1) begin
                        tenbit_data_rev[I] = tenbit_data[9 - I];
                    end

                    if (column_index == 13 & tx_pdata == 8'h81) begin
                        frame_type = "VLAN";
                    end

// wait for next column of data
                    repeat (num_of_repeat) begin
                        @(posedge mon_tx_clk);
                        #1;
                    end
                    column_index = column_index + 1;
                end
                hw_frame_cnt =  hw_frame_cnt + 1;
                $display("%t : %s Frame transmitted is of size %d", $time, frame_type, column_index);
            end
        end
    end
    endtask // tx_monitor_check_frame

//----------------------------------------------------------------------------
// Monitor process. This process checks the data coming out of the
// transmitter to make sure that it matches that inserted into the
// receiver.
//----------------------------------------------------------------------------

    initial
    begin : p_tx_monitor
        tx_monitor_finished_1G    <= 0;
        tx_monitor_finished_100M  <= 0;
        tx_monitor_finished_10M   <= 0;

        if (TB_MODE == "DEMO") begin
// Compare the transmitted frame to the received frames
//      -- frame 0 = minimum length frame
//      -- frame 1 = type frame
//      -- frame 2 = errored frame
//      -- frame 3 = padded frame
// Repeated for all stated speeds.
//-----------------------------------------------------
// wait for the reset to complete before starting monitor
            @(negedge reset);
// 1 Gb/s speed
//-----------------------------------------------------
// Check the frames
            check_frame(frame0.tobits(0),1);
            //check_frame(frame1.tobits(0),2);
            //check_frame(frame2.tobits(0),3);
            //check_frame(frame3.tobits(0),4);
	    $display("Finishied 1G 1 frame checking");
            #200000
            tx_monitor_finished_1G  <= 1;
/*
// 100 Mb/s speed
//-----------------------------------------------------
// Check the frames
        check_frame(frame0.tobits(0),1);
        check_frame(frame1.tobits(0),2);
        check_frame(frame2.tobits(0),3);
        check_frame(frame3.tobits(0),4);

        #200000
        tx_monitor_finished_100M  <= 1;
        tx_monitor_finished_1G    <= 0;
// 10 Mb/s speed
//-----------------------------------------------------
// Check the frames
        check_frame(frame0.tobits(0),1);
        check_frame(frame1.tobits(0),2);
        check_frame(frame2.tobits(0),3);
        check_frame(frame3.tobits(0),4);
        #200000
        tx_monitor_finished_10M  <= 1;
// 1 Gb/s speed
//-----------------------------------------------------
// Check the frames
        check_frame(frame0.tobits(0),1);
        check_frame(frame1.tobits(0),2);
        check_frame(frame2.tobits(0),3);
        check_frame(frame3.tobits(0),4);

        #200000
        tx_monitor_finished_1G  <= 1;
*/
    end
    else begin
        forever check_frame(frame0.tobits(0),1);
    end

    end // p_tx_monitor
endmodule
