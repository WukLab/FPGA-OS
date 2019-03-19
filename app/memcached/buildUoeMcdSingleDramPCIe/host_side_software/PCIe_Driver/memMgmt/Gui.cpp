/*-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
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


#include "Gui.h"

static Gui *Gui_ii;

static char text1[80];//not very clean
static char text2[80];



Gui::Gui(char* devFileName)
{
    //ctor

    this->uDriver_i=new uDriver(devFileName);
    this->memManager_i=new memManager(uDriver_i);
    Gui_ii=this;
    goman_t=NULL;
    drawBoxes=false;
    occuDiag=NULL;
    //the diagram inherits from fl_group, redrawing automatic.
    uint32_t temp0=memManager_i->getPoolSize(p0);
    uint32_t temp1=memManager_i->getPoolSize(p1);
    uint32_t temp2=memManager_i->getPoolSize(p2);
    uint32_t temp3=memManager_i->getPoolSize(p3);
    boxes=new diagram_boxes(520,50,460,750,"Utilisation",temp0,temp1,temp2,temp3 );

    //occuText is on the other hand is so simple it makes no sense
    //to stick it into an extra class.
    occuText=new Fl_Group(520,50,460,750,"Utilisation");
    //initial text. overwritten in first timeout.
    sprintf(text1,"Addresses for memory 1 in hardware:");
    Fl_Box *oc1=new Fl_Box(FL_FLAT_BOX,520,50,400,20,text1);
    sprintf(text2,"Addresses for memory 2 in hardware:");
    Fl_Box *oc2=new Fl_Box(FL_FLAT_BOX,520,80,400,20,text2);
    occuText->end();//all FL_xxx between new and end are added as children of the FL_group

    p0dirties=new vector<pair<uint32_t,entrystatus> >();
    p1dirties=new vector<pair<uint32_t,entrystatus> >();
    p2dirties=new vector<pair<uint32_t,entrystatus> >();
    p3dirties=new vector<pair<uint32_t,entrystatus> >();
}

Gui::~Gui()
{
    delete p0dirties;
    delete p1dirties;
    delete p2dirties;
    delete p3dirties;
}


char revText[80];
char mem0desc[80];
char mem1desc[80];
int Gui::start(int argc,char** argv)
{

    Fl_Window *window;
    Fl_Box *box, *pooltypes;


    printf("%s",memManager_i->getPoolDescription(p0));

    window = new Fl_Window (1000, 800,"Xilinx Key Value Store Demo");
    gauge1=new Fl_Gauge(50,50,150,150,"Ingress Pipeline utilization");
    gauge1->stepdiv(5);
    gauge1->framecolor(FL_GREEN);
    gauge1->v2color(FL_DARK_MAGENTA);
    gauge1->fontsize(8);

    gauge2=new Fl_Gauge(250,50,150,150,"Egress Pipeline utilization");
    gauge2->stepdiv(5);
    gauge2->framecolor(FL_GREEN);
    gauge2->v2color(FL_DARK_MAGENTA);
    gauge2->fontsize(8);

    sprintf(revText,"Revision number: %8x",uDriver_i->ReadRev()&0x00ffffff);
    box=new Fl_Box(50,250,200,20,revText);
    box->labeltype(FL_NORMAL_LABEL);
    box->box(FL_FLAT_BOX);

    manButton = new Fl_Button(50,280,200,20,"start memory manager");
    manButton->callback(onManagePressed);



    sprintf(mem0desc,"%s",  memManager_i->getPoolDescription(p0));
    sprintf(mem1desc,"%s",  memManager_i->getPoolDescription(p1));
    pooltypes=new Fl_Box(50,320,200,20,mem0desc);
    pooltypes=new Fl_Box(50,340,200,20,mem1desc);

    //TODO: uncomment this when software controlled reset works.
    //will generate a reset pulse in the hardware. (sc_reset)
    //hardware_reset_button = new Fl_Button(50,300,180,20,"reset hardware");
    //hardware_reset_button->callback(onResetPressed);

    window->end ();

    //prepare the occu_diag object and add to the window. Could be a bit more elegant.
    make_occupation_diagram();
    window->add(occuDiag); //if you don't want the occupation diagram, comment this line

    window->show (argc, argv);
    Fl::add_timeout(1,timeout);

    return(Fl::run());
};


//draw either the pretty diagram or the simple text info
void Gui::make_occupation_diagram(){
    //space available:
    //horizontal 500-1000
    //vertical 0-800
    if(occuDiag==NULL){
        occuDiag=new Fl_Group(500,0,500,800);

    }else{
        occuDiag->remove(boxes);
        occuDiag->remove(occuText);
        occuDiag->clear();
        occuDiag->begin();
    }
    occuDiag->box(FL_FLAT_BOX);
    occuDiag->color(fl_gray_ramp(20));

    int h,w;
    h=0;w=0;
    const char *but_txt="change mode";
    fl_font(FL_HELVETICA,14);
    fl_measure(but_txt,w,h);
    occu_diag_mode_button=new Fl_Button(520,20,w+5,h+5,but_txt);
    occu_diag_mode_button->callback(onModeButtonPressed);

    if(drawBoxes){
        occuDiag->add(boxes);
    }else{
        occuDiag->add(occuText);
    }
    occuDiag->end();
    occuDiag->redraw();
}


void Gui::refreshDiag(){
    if(drawBoxes){
        boxes->redraw();
    }else{
        occuText->redraw();
    }
}

static void onModeButtonPressed(Fl_Widget *widget, void*){
    printf("mode button\n");
    Gui_ii->drawBoxes=!Gui_ii->drawBoxes;
    Gui_ii->make_occupation_diagram();
}

static void onManagePressed(Fl_Widget *widget, void*){
    if(Gui_ii->goman_t==NULL){
        printf("commence memory management\n");
        Gui_ii->goman_t=new thread(goman);//important: thread object on heap
    }else{ //reinitialize memory manager object so it can detect changed hardware configuration after partial reconfig
        printf("already started\n");
        printf("resetting memory manager\n");
        delete Gui_ii->memManager_i;
        Gui_ii->memManager_i=new memManager(Gui_ii->uDriver_i);    //TODO: dangerous! timeout is still running!
        sprintf(revText,"Revision number: %8x",Gui_ii->uDriver_i->ReadRev()&0x00ffffff);
        sprintf(mem0desc,"%s",  Gui_ii->memManager_i->getPoolDescription(p0));
        sprintf(mem1desc,"%s",  Gui_ii->memManager_i->getPoolDescription(p1));
    }
};

static void goman(){
    Gui_ii->memManager_i->manage();
}

static void onResetPressed(Fl_Widget *widget, void*){
    printf("stopping memory management and resetting hardware\n");
    Gui_ii->memManager_i->stopManage();
    Gui_ii->uDriver_i->softwareControlledReset();
};

static void timeout(void*)
{

    Fl_Gauge *gauge1,*gauge2;

    gauge1=Gui_ii->gauge1;
    gauge2=Gui_ii->gauge2;

    uDriver *uDriver_i=Gui_ii->uDriver_i;

    float st0=uDriver_i->ReadStats_percent(stats0);
    gauge1->value(st0);
    gauge1->redraw();


    float st1=uDriver_i->ReadStats_percent(stats1);
    gauge2->value(st1);
    gauge2->redraw();
    //printf("%x     %x     ",uDriver_i->ReadStats_precise(stats0),uDriver_i->ReadStats_precise(stats1));
    //printf("stats0: %3.2d    stats1: %3.2d\n",st0,st1);

    //update diagram. It may be sensible to move this to a slower timeout
    int ps0,ps1,ps2,ps3;
    ps0=Gui_ii->memManager_i->getPoolSize(p0);
    ps1=Gui_ii->memManager_i->getPoolSize(p1);
    ps2=Gui_ii->memManager_i->getPoolSize(p2);
    ps3=Gui_ii->memManager_i->getPoolSize(p3);
    Gui_ii->memManager_i->getDirtyList(p0,Gui_ii->p0dirties);
    Gui_ii->boxes->setDirties(p0,Gui_ii->p0dirties);
    Gui_ii->memManager_i->getDirtyList(p1,Gui_ii->p1dirties);
    Gui_ii->boxes->setDirties(p1,Gui_ii->p1dirties);

    //update occutext
    int use0,use1,use2,use3;
    Gui_ii->memManager_i->getUsageExact(use0,use1,use2,use3);
    use0=ps0-use0;
    use1=ps1-use1;

    sprintf(text1,"Addresses for memory 1 in hardware: %d of %d",use0, ps0);
    sprintf(text2,"Addresses for memory 2 in hardware: %d of %d",use1, ps1);

    Gui_ii->refreshDiag();

    Fl::repeat_timeout(0.8,timeout);
}
