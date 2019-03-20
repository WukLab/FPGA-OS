const char FL_GAUGE_VERSION[]="V0.0.6";
/****************************************************************
*                       Fl_Gauge.cxx
*
* Instrumentation style guage widget.
* Useable as general meter, tacho, speedo etc
*
* Author: Michael Pearce
*
* Started: 2 August 2004
*
* Copyright: Copyright 2004 Michael Pearce
*            All Rights Reserved
*
* Licence: LGPL with exceptions same as FLTK license Agreement
*          http://www.fltk.org/COPYING.php
*
* This widget based inpart on the work of the FLTK project
* http://www.fltk.org/
*
*****************************************************************
*                     VERSION INFORMATION
*****************************************************************
* V0.0.6 - 6 August 2004
* Added Green Zone
* Added Red Line Mode
* Altered how callback/beep functions work - now on setting value
*****************************************************************
* V0.0.5 - 5 August 2004
* Fixed drawing values in correct place when min > 0
*****************************************************************
* V0.0.4 - 5 August 2004
* Changed defaults so additional values not shown.
*****************************************************************
* V0.0.3 - 4 August 2004
* Fixed drawing problems when -ve values used on scales.
*****************************************************************
* V0.0.2 - 4 August 2004
* Add values for marks to guage dial
*****************************************************************
* V0.0.1 - 3 August 2004
*  Finish round gauge functionality.
*****************************************************************
* V0.0.0 - 2 August 2004
*  Start of Project - Work on Round Guage
****************************************************************/


#include "Fl_Gauge.H"

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define PI 3.14159265

/******************************************************************************
*                              Fl_Gauge
******************************************************************************/
Fl_Gauge :: Fl_Gauge(int X,int Y,int W,int H,const char *l): Fl_Widget(X,Y,W,H+10,l)
{
 box(FL_NO_BOX);

 type(FL_GAUGE_ROUND);

 color(FL_WHITE);

 dialcolor(FL_WHITE);
 framecolor(FL_DARK_CYAN);
 pointercolor(FL_BLACK);
 redlinecolor(FL_RED);
 greenzonecolor(FL_GREEN);
 textcolor(FL_BLACK);




 min(0.0);
 max(100.0);

 step(10.0);                /* OFF */
 stepdiv(2.0);              /* OFF */

 fontsize(12);
 fontface(FL_COURIER);


 RedLineStart=0;
 RedLineMode=FL_GAUGE_RL_OFF;
 RL_cb=NULL;


 GZ_cb=NULL;
 GreenZoneMode=FL_GAUGE_GZ_OFF;
 GreenZoneStart=0;
 GreenZoneEnd=0;


 V2Mode=FL_GAUGE_V2_NONE;
 V2Real=5;
 V2Decimal=2;

 Real=2;
 Decimal=0;

 OdoMode=FL_GAUGE_ODO_OFF;
 OdoReal=5;
 OdoDecimal=2;
 odoincsize(0.01);

 align(FL_ALIGN_TOP);


 Value=0.0;
 Value2=0.0;


}


/******************************************************************************
*                            ~Fl_Gauge
******************************************************************************/
Fl_Gauge :: ~Fl_Gauge(void)
{
}

/******************************************************************************
*                              version
******************************************************************************/
const char* Fl_Gauge::  version(void)
{
 return(FL_GAUGE_VERSION);
}




/******************************************************************************
*                                 draw
******************************************************************************/
void Fl_Gauge:: check_zone(void)
{
 double Hi,Lo;

 if(greenzonemode())
 {
  /* Check Green Zone Polarity */
  if(greenzonestart() > greenzoneend())
  {
   Hi=greenzonestart(); Lo=greenzoneend();
   greenzonestart(Lo);greenzoneend(Hi);
  }

  if(greenzonestart() < min()) greenzonestart(min());
  if(greenzoneend() > max()) greenzoneend(max());

  /* Check for Red line overlap */
  if(redlinestart() < greenzoneend()) redlinestart(greenzoneend());
 }


 if(RedLineMode)
 {
  /* Check Red Line Range */
  if(redlinestart() < min()) redlinestart(min());
  else if(redlinestart() > max()) redlinestart(max());
 }



 /* Check for REDLINE Beep / Callback mode */
 switch(RedLineMode)
 {
  default:
  case FL_GAUGE_RL_OFF:
  case FL_GAUGE_RL_ON:
   break;

  case FL_GAUGE_RL_BEEP:
   if(value() >= redlinestart()) fl_beep(FL_BEEP_ERROR);
   break;

  case FL_GAUGE_RL_CBIN:
   if(value() >= redlinestart()){if(RL_cb !=NULL)(RL_cb)(0);}
   break;

  case FL_GAUGE_RL_CBOUT:
   if(value() < redlinestart()){if(RL_cb !=NULL)(RL_cb)(0);}
   break;
 }


 /* Check for Greenline Beep / Callback mode */
 Lo=greenzonestart(); Hi=greenzoneend();
 switch(GreenZoneMode)
 {
  default:
  case FL_GAUGE_GZ_OFF:
  case FL_GAUGE_GZ_ON:
   break;

  case FL_GAUGE_GZ_BEEP:
   if(value() >= Hi || value() <= Lo) fl_beep(FL_BEEP_ERROR);
   break;

  case FL_GAUGE_GZ_CBIN:
   if(value() <= Hi && value() >= Lo){if(GZ_cb !=NULL)(GZ_cb)(0);}
   break;

  case FL_GAUGE_GZ_CBOUT:
   if(value() > Hi || value() < Lo){if(GZ_cb !=NULL)(GZ_cb)(0);}
   break;
 }
}

/******************************************************************************
*                                 draw
******************************************************************************/
void Fl_Gauge:: draw()
{

 fl_push_clip(x(),y(),w(),h());

 switch(type())
 {
   default:
   case FL_GAUGE_ROUND:
    gauge_round();
    break;

   case FL_GAUGE_SQUARE:
    gauge_square();
    break;

   case FL_GAUGE_LINEAR:
    gauge_linear();
    break;

   case FL_GAUGE_DIGITAL:
    gauge_digital();
    break;
 }

 fl_pop_clip();

 //check_zone();   // Done when value changed

 draw_label(); /* Draw Label Last so it is on the top */
}








/******************************************************************************
*                             gauge_round
******************************************************************************/
void  Fl_Gauge:: gauge_round(void)
{
 int X,Y,W,H,tx,ty,tw,th;
 int A,B;
 double RL,V;

 char tmps[20],sfmt[10];

 X=x();Y=y()+10;W=w();H=h()-10;

 /* Draw main Area */
 //was draw_box(FL_OVAL_BOX,dialcolor()
 draw_box(FL_OVAL_BOX,X,Y,W,H, dialcolor());        /* Draw background           */

 fl_color(framecolor());                    /* Change to frame colour    */
 fl_line_style(FL_SOLID, 3, 0);
 fl_arc(X+1,Y+1,W-2,H-2,0,360);             /* Draw Outer Ring           */

 fl_color(fl_lighter(framecolor()));        /* Change to frame colour    */
 fl_line_style(FL_SOLID, 1, 0);
 fl_arc(X+1,Y+1,W-2,H-2,0,360);             /* Draw Outer Ring           */



 fl_line_style(FL_SOLID, 1, 0);


 /* Draw GreenZone Area */
 if(greenzonemode() != FL_GAUGE_GZ_OFF)
 {
  fl_color(greenzonecolor());
  A=(W/2)/3;
  B=A*2;
  RL=270- (((greenzonestart()-min())/(max()-min())) * 270);
  V=270- (((greenzoneend()-min())/(max()-min())) * 270);

  fl_pie(X+A,Y+A,W-B,H-B,V-45,RL-45);           /* Draw Green Zone */
 }


  /* Draw Redline Area */
 if(redlinemode()!=FL_GAUGE_RL_OFF && redlinestart() < max())
 {
  fl_color(redlinecolor());
  A=(W/2)/3;
  B=A*2;
  RL=270- (((redlinestart()-min())/(max()-min())) * 270);
  fl_pie(X+A,Y+A,W-B,H-B,-45,RL-45);           /* Draw Red Zone */
 }


 /* Draw Value marks etc */
 fl_color(textcolor());

 A=(W/2)/3;                                 /* Calc Placement of 270 Ring */
 B=A*2;
 fl_arc(X+A,Y+A,W-B,H-B,-45,225);           /* Draw 270 degree Ring       */

 /* Draw smallest Divisions */
 if(stepdiv() >0 && stepdiv()< step())
 {
  for(V=min();V<=max();V+=stepdiv())
  {
   RL=(((V-min())/(max()-min()))*270);

   fl_push_matrix();
    fl_translate(X+W/2-.5, Y+H/2-.5);
    fl_scale(W-1, H-1);
    fl_rotate(45+RL);

    fl_begin_line();
     fl_vertex(0.0, 0.31);
     fl_vertex(0.0, 0.33);
    fl_end_line();

   fl_pop_matrix();
  }
 }

 /* Draw Large Divisions */
 if(step() >0 && step()<max())
 {
  for(V=min();V<=max();V+=step())
  {
   RL=(((V-min())/(max()-min()))*270);

   fl_push_matrix();
    fl_translate(X+W/2-.5, Y+H/2-.5);
    fl_scale(W-1, H-1);
    fl_rotate(45+RL);

    fl_begin_line();
     fl_vertex(0.0, 0.3);
     fl_vertex(0.0, 0.35);
    fl_end_line();

   fl_pop_matrix();
  }
 }


 /* Draw the Guage text mark Values */
 RL=min();
 sprintf(sfmt,"%%0%d.0%dlf%%%%",Real,Decimal);


 fl_font(FontFace,FontSize);
 fl_color(textcolor());

 A=(W/3)+5;
 B=(H/3)+5;

 for(V=270+45;V>=45;V-=(step()/(max()-min())*270))
 {
  tx=(int)(sin(V*PI/180)*A) + X + (W/2);
  ty=(int)(cos(V*PI/180)*B) + Y + (H/2);

  sprintf(tmps,sfmt,RL);

  tw=th=0;
  fl_measure(tmps,tw,th,1);

  if(min()<0 && max()>=0)
  {
   if(RL < ((max()+min())/2) )tx-=tw;
   else if(RL == ((max()+min())/2))tx-=(tw/2);
  }
  else
  {
   if(RL < ((max()-min())/2)+min() )tx-=tw;
   else if(RL == ((max()-min())/2)+min())tx-=(tw/2);
  }

  if(ty > (Y+(H/2))) ty+=(th/2);

  fl_draw(tmps,tx,ty);
  RL+=step();
 }



 /* Draw Pointer */
 fl_color(pointercolor());

 A=(W/2)/3;
 B=A*2;

 V=value();
 if(V > max())V=max();
 if(V < min())V=min();
 RL=270-(((V-min())/(max()-min()))*270);

 /* This Matrix modified from FL_Dial */
 fl_push_matrix();
 fl_translate(X+W/2-.5, Y+H/2-.5);
 fl_scale(W-1, H-1);

 fl_rotate(90+RL);

 if(value()>=redlinestart()) fl_color(fl_color_average(pointercolor(),redlinecolor(),0.6));
 else if (value()>=greenzonestart() && value()<=greenzoneend())
 { fl_color(fl_color_average(pointercolor(),greenzonecolor(),0.6));}
 else fl_color(pointercolor());

  fl_begin_polygon();
  fl_vertex(0.0,   0.0);
  fl_vertex(-0.04, 0.0);
  fl_vertex(-0.25, 0.25);
  fl_vertex(0.0,   0.04);
  fl_end_polygon();

  //fl_color(dialcolor());
  fl_color(textcolor());

  fl_begin_loop();
  fl_vertex(0.0,   0.0);
  fl_vertex(-0.04, 0.0);
  fl_vertex(-0.25, 0.25);
  fl_vertex(0.0,   0.04);
  fl_end_loop();

 fl_pop_matrix();


 /* Draw pointer Centre */
 fl_color(framecolor());                    /* Change to frame colour    */
 A=(W/2)-(((W/2)/5)/2);                      /* Calc Placement of Center   */
 B=A*2;
 fl_pie(X+A,Y+A,W-B,H-B,0,360);              /* Draw centre Ring           */



 if(V2Mode !=0)
 {
  switch(V2Mode)
  {
   default:
   case FL_GAUGE_V2_NONE:      /* No Value 2 display                   */
    V=0;
    break;

   case FL_GAUGE_V2_ON:        /* Value 2 Displayed                    */
   case FL_GAUGE_V2_TRIP:      /* Value 2 displayed works as Trip Meter*/
    V=Value2;
    break;

   case FL_GAUGE_V2_V1:        /* Value 2 displayed BUT Equals Value 1 */
    V=Value;
    break;

  }

  /* Draw Value2 Text */
  sprintf(sfmt,"%%0%d.0%dlf",V2Real,V2Decimal);
  sprintf(tmps,sfmt,V);
  fl_color(V2Color);
  fl_font(FontFace,FontSize);
  fl_measure(tmps,tw,th,1);

  tx=X+(W/2)-(tw/2);
  ty=Y+H-(th);

  fl_draw(tmps,tx,ty);
 }


 /* Draw Odometer Text */
 if(OdoMode !=0)
 {
  V=Odometer;

  /* Draw Value2 Text */
  sprintf(sfmt,"%%0%d.0%dlf",OdoReal,OdoDecimal);
  sprintf(tmps,sfmt,V);
  fl_color(OdoColor);
  fl_font(FontFace,FontSize);
  fl_measure(tmps,tw,th,1);

  tx=X+(W/2)-(tw/2);
  ty=Y+H-(th*2);

  fl_draw(tmps,tx,ty);
 }








}

/******************************************************************************
*                            gauge_square
******************************************************************************/
void Fl_Gauge:: gauge_square(void)
{


}


/******************************************************************************
*                              gauge_linear
******************************************************************************/
void Fl_Gauge:: gauge_linear(void)
{
 int X,Y,W,H,tx,ty,tw,th;
 double V,D;


 //char tmps[20],sfmt[10];

 X=x();Y=y();W=w();H=h();

 /* Draw main Area */

 draw_box(FL_FLAT_BOX, dialcolor());        /* Draw background           */

 #if 0      /* Change to 1 if want a border */
 fl_color(framecolor());                    /* Change to frame colour    */
 fl_line_style(FL_SOLID, 3, 0);
 fl_rect(X+1,Y+1,W-2,H-2);                  /* Draw Outer Ring           */

 fl_color(fl_lighter(framecolor()));        /* Change to frame colour    */
 fl_line_style(FL_SOLID, 1, 0);
 fl_rect(X+1,Y+1,W-2,H-2);                  /* Draw Outer Ring           */

 fl_line_style(FL_SOLID, 1, 0);
 #endif


 /* Draw outline of Linear Area */
 fl_color(textcolor());                    /* Change to text colour    */
 fl_line_style(FL_SOLID, 1, 0);
 fl_loop(X+3,Y+H-3,X+W-3,Y+3,X+W-3,Y+H-3);


 /* Calc and Draw Value */



 if(Value > max()) V=max();
 else if(Value < min()) V=min();
 else V=Value;

 /* Force a minimum Step Division */
 if(StepDiv <=0.0)StepDiv=(max()-min())/10;

 ty=Y+H-3;
 tw=1;
 for(D=min();D<=max();D+=StepDiv)
 {
  tx=(int) ((D/(max()-min())) * (W-6) + X + 3);
  th=(int) ((D/(max()-min())) * (W-6) - 1);

  fl_color(dialcolor());
  if(D < V)fl_color(pointercolor());
  if(D > V && D >= redlinestart())fl_color(redlinecolor());
  if(D < V && D >= redlinestart())fl_color(fl_color_average(pointercolor(),redlinecolor(),0.4));

  fl_line_style(FL_SOLID, 1, 0);

  fl_line(tx,ty,tx,ty-th);

 }






}


/******************************************************************************
*                              gauge_digital
******************************************************************************/
void Fl_Gauge:: gauge_digital(void)
{

}





/******************************************************************************
*                              odoplaces
******************************************************************************/
int Fl_Gauge:: odoplaces(int &r,int &d)
{
 if(r==0 & d==0)
 {
  r=OdoReal;
  d=OdoDecimal;
  return(1);
 }

 OdoReal=r;                /* Odometer Real Number Places */
 OdoDecimal=d;             /* Odometer Decimal Places */

 return(0);
}


int Fl_Gauge:: v2places(int &r,int &d)
{
 if(r==0 & d==0)
 {
  r=V2Real;
  d=V2Decimal;
  return(1);
 }

 V2Real=r;                /* Odometer Real Number Places */
 V2Decimal=d;             /* Odometer Decimal Places */

 return(0);
}




int Fl_Gauge:: places(int &r,int &d)
{
 if(r==0 & d==0)
 {
  r=Real;
  d=Decimal;
  return(1);
 }

 Real=r;                /* Odometer Real Number Places */
 Decimal=d;             /* Odometer Decimal Places */

 return(0);
}

