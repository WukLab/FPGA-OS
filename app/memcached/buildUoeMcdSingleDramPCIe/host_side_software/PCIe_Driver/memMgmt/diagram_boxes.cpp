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
    -- PART OF THIS FILE AT ALL TIMES.*/


#include "diagram_boxes.h"
#include <math.h>
#include <FL/fl_draw.H>
diagram_boxes::diagram_boxes(int x,int y,int w,int h,const char* title,uint32_t ps0,uint32_t ps1,uint32_t ps2,uint32_t ps3):Fl_Group(x,y,w,h,title)
{
    //super constructor contains implicit fltk "begin", so all fltk objects construced until "end" are added as children
    //determine square side length so al squares fit in the area
    int pstot=ps0+ps1+ps2+ps3;

    int wav=this->w()-20;
    int hav=this->h()-20-80;//ensure there's space for an extra line
    float sq=(float)(hav*wav)/(float) pstot;
    sq=max(sq,(float)1);
    int sqs=floor(sqrt(sq));//side length of displayed squares in pixels
    sqs=min(sqs,40);
    sqs=max(sqs,1);

    int cols=wav/sqs;
    int rows0=ceil((float)ps0/(float)cols);
    int rows1=ceil((float)ps1/(float)cols);
    int rows2=ceil((float)ps2/(float)cols);
    int rows3=ceil((float)ps3/(float)cols);

    int xbase=this->x()+10;
    int ybase=this->y()+20;

    printf("rcs %x %x  %x   \n",rows0,cols,sqs);

    if(pstot<0x01000000){//safeguard against excessive memory consumption by the gui
        int ct=0;
        if(POOL_0_USED){
            for(int row=0;row<rows0;row++){
                for(int col=0;col<cols;col++){
                    ct=row*cols+col;
                    if(ct>=ps0) continue;
                    int space=sqs>3?1:0;
                    int my=ybase+row*sqs+space;
                    int mx=xbase+col*sqs+space;
                    int i=row*cols+col;
                    Fl_Box *b = new Fl_Box(FL_FLAT_BOX,mx,my,sqs-2*space,sqs-2*space,"");
                    b->color(FL_BLUE);
                    p0boxes.push_back(b);
                }
            }
        }

        ybase+=rows0*sqs+10;
        if(POOL_1_USED){
            for(int row=0;row<rows1;row++){
                for(int col=0;col<cols;col++){
                    ct=row*cols+col;
                    if(ct>=ps0) continue;
                    int space=sqs>3?1:0;
                    int my=ybase+row*sqs+space;
                    int mx=xbase+col*sqs+space;
                    int i=row*cols+col;
                    Fl_Box *b = new Fl_Box(FL_FLAT_BOX,mx,my,sqs-2*space,sqs-2*space,"");
                    b->color(FL_BLUE);
                    p1boxes.push_back(b);
                }
            }
        }
        //could also include pools 3 and 4 here.
    }
    //Fl_Box *derp=new Fl_Box(FL_FRAME_BOX,x+10,y+10,50,50,"placeholder");
    end();

}

diagram_boxes::~diagram_boxes()
{
    //dtor
    for(vector<Fl_Box*>::iterator it=p0boxes.begin();it!=p0boxes.end();it++){
        delete *it;
    }
}


//gets called to alert the diagram of changed values
void diagram_boxes::setDirties(pool which,vector<pair<uint32_t,entrystatus> > *dirties){
    int offset, granularity;
    vector<Fl_Box*> *pboxes;
    switch(which){
    case p0:
        pboxes=&p0boxes;
        offset=POOL_0_START;
        granularity=1;
        break;
    case p1:
        pboxes=&p1boxes;
        offset=POOL_1_START;
        granularity=P0P1TRESHOLD;
        break;
    case p2:
        pboxes=&p2boxes;
        offset=POOL_2_START;
        break;
    case p3:
        pboxes=&p3boxes;
        offset=POOL_3_START;
        break;
    }
    //Go through list of changes
    //from address calculate which squares are concerned
    //color them appropriately
    for(int i=0;i<dirties->size();i++){
        uint32_t whichbox=(dirties->at(i).first-offset)/granularity;
        entrystatus status=dirties->at(i).second;
        if(whichbox<pboxes->size()){
            Fl_Box *tmp=pboxes->at(whichbox);
            switch(status){
            case software:
                tmp->color(FL_BLUE);
                break;
            case hardware:
                tmp->color(FL_RED);
                break;
            case broken:
                break;
            }
        }
    }

}

