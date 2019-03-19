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


/*
* a GUI using the fltk framework.
* when the GUI is present (depends on compile flags) it controls the operation.
* timeout functions check stats and fancy graphic memory occupation diagram.
*/

#ifndef GUI_H
#define GUI_H

#include "uDriver.h"
#include "memManager.h"

#include <mutex>
#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.h>
#include <FL/Fl_Table.h>
#include "Fl_Gauge.H"

#include <thread>

#include "diagram_boxes.h"
#include <list>

class Gui;
static void timeout(void*);

static void onManagePressed(Fl_Widget *widget, void*);
static void onResetPressed(Fl_Widget *widget, void*);
static void onModeButtonPressed(Fl_Widget *widget, void*);
static void goman();


class Gui
{

    public:
         Gui(char* devFileName);
        int start(int,char**);
        virtual ~Gui();
        void refreshDiag();
        friend  void timeout(void*);

        //static helper functions that get passed to fltk as callbacks
        friend  void onManagePressed(Fl_Widget *widget, void*);
        friend  void onResetPressed(Fl_Widget *widget, void*);
        friend  void goman();
        friend  void onModeButtonPressed(Fl_Widget *widget, void*);

    protected:
    private:

        thread *goman_t;
        uDriver* uDriver_i;
        memManager *memManager_i;
        Fl_Gauge *gauge1,*gauge2;
        Fl_Button *manButton;
        Fl_Button *occu_diag_mode_button;
        Fl_Button *hardware_reset_button;
        void make_occupation_diagram();
        Fl_Group *occuDiag;
        Fl_Group *occuText;
        diagram_boxes *boxes;

        vector<pair<uint32_t,entrystatus> > *p0dirties;
        vector<pair<uint32_t,entrystatus> > *p1dirties;
        vector<pair<uint32_t,entrystatus> > *p2dirties;
        vector<pair<uint32_t,entrystatus> > *p3dirties;

        bool drawBoxes;
};

#endif // GUI_H
