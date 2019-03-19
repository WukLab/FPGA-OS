/*****************************************
*            Fl_Gauge.H
*
* Header file for Fl_Gauge.cxx
* See Fl_Gauge.cxx for details
*****************************************/
#ifndef _Fl_Gauge_H_
#define _Fl_Gauge_H_

#include <FL/Enumerations.H>
#include <FL/Fl_Widget.H>
#include <FL/fl_draw.H>
#include <FL/fl_ask.H>


/* Drawing Types */
#define FL_GAUGE_ROUND       0
#define FL_GAUGE_SQUARE      1
#define FL_GAUGE_LINEAR      2
#define FL_GAUGE_DIGITAL     4


/* Green Zone settings */
#define FL_GAUGE_GZ_OFF    0      /* Turn it OFF */
#define FL_GAUGE_GZ_ON     1      /* Display it  */
#define FL_GAUGE_GZ_BEEP   2      /* Display and Beep if OUT of zone         */
#define FL_GAUGE_GZ_CBIN   3      /* Display and use callback if IN zone     */
#define FL_GAUGE_GZ_CBOUT  4      /* Display and use callback if OUT of zone */


/* Red Line settings */
#define FL_GAUGE_RL_OFF    0      /* Turn it OFF */
#define FL_GAUGE_RL_ON     1      /* Display it  */
#define FL_GAUGE_RL_BEEP   2      /* Display and Beep if OUT of zone         */
#define FL_GAUGE_RL_CBIN   3      /* Display and use callback if IN zone     */
#define FL_GAUGE_RL_CBOUT  4      /* Display and use callback if OUT of zone */


/* Value 2 Modes  */
#define FL_GAUGE_V2_NONE 0      /* No Value 2 display                   */
#define FL_GAUGE_V2_ON   1      /* Value 2 Displayed                    */
#define FL_GAUGE_V2_V1   2      /* Value 2 displayed BUT Equals Value 1 */
#define FL_GAUGE_V2_TRIP 3      /* Value 2 displayed works as Trip Meter*/

/* Odometer Modes */
#define FL_GAUGE_ODO_OFF 0      /* Odometer OFF */
#define FL_GAUGE_ODO_ON  1      /* Odometer ON  */



class FL_EXPORT Fl_Gauge: public Fl_Widget
{


 protected:


  virtual void draw();

  /* Drawing functions for different modes */
  void gauge_square(void);
  void gauge_round(void);
  void gauge_linear(void);
  void gauge_digital(void);


  /* Variables etc */

  double Value;
  double Value2;
  double Odometer;
  double OdoIncSize;


  double Min;
  double Max;
  double Step;
  double StepDiv;
  double RedLineStart;
  double GreenZoneStart;
  double GreenZoneEnd;


  int Type;                   /* Type of Guage */
  int RedLineMode;
  int GreenZoneMode;
  int V2Mode;                 /* Value 2 Mode  */
  int Real;
  int Decimal;
  int V2Real;
  int V2Decimal;
  int OdoMode;                /* Odometer Mode */
  int OdoReal;                /* Odometer Real Number Places */
  int OdoDecimal;             /* Odometer Decimal Places */



  Fl_Color DialColor;
  Fl_Color FrameColor;
  Fl_Color PointerColor;
  Fl_Color RedLineColor;
  Fl_Color TextColor;
  Fl_Color OdoColor;
  Fl_Color V2Color;
  Fl_Color GreenZoneColor;

  int FontSize;
  int FontFace;


  void (*RL_cb)(void*);

  void (*GZ_cb)(void*);


  void check_zone(void);

 public:

  Fl_Gauge(int ,int ,int ,int ,const char * = 0);
  ~Fl_Gauge(void);

  const char* version(void);                         /* return widget version */

  Fl_Color dialcolor(void){return (DialColor);}      /* colour of the Dial    */
  void dialcolor(Fl_Color C){DialColor=C;}


  Fl_Color framecolor(void){return (FrameColor);}      /* colour of the Frame    */
  void framecolor(Fl_Color C){FrameColor=C;}


  Fl_Color pointercolor(void){return(PointerColor);} /* Colour of the pointer */
  void pointercolor(Fl_Color C){PointerColor=C;}

  Fl_Color redlinecolor(void){return(RedLineColor);} /* Colour of Over Limit */
  void redlinecolor(Fl_Color C){RedLineColor=C;}

  Fl_Color textcolor(void){return(TextColor);}       /* colour of value text */
  void textcolor(Fl_Color C){TextColor=C;}


  Fl_Color odocolor(void){return(OdoColor);}         /* colour of odometer text */
  void odocolor(Fl_Color C){OdoColor=C;}

  Fl_Color v2color(void){return(V2Color);}           /* colour of value 2 text */
  void v2color(Fl_Color C){V2Color=C;}

  Fl_Color greenzonecolor(void){return(GreenZoneColor);} /* Green Zone Color */
  void greenzonecolor(Fl_Color C){GreenZoneColor=C;}


  double value(void) {return(Value);}                /* Main Value           */
  void   value(double v) {Value=v; check_zone();}

  double value2(void) {return(Value2);}              /* Secondary Value      */
  void   value2(double v) {Value2=v;}

  double redlinestart(void){return(RedLineStart);}   /* Red Line Start point */
  void   redlinestart(double r){RedLineStart=r;check_zone();}

  int redlinemode(void){return(RedLineMode);}        /* Red Line Mode */
  void redlinemode(int m){RedLineMode=m;}

  void redlinecb(void (*cb)(void *)){RL_cb=cb;}     /* Set Alert Callback    */


  int type(void){return(Type);}                      /* Type of gauge drawn  */
  void type(int t){Type=t;}


  double min(void){return(Min);}                     /* Minimum Guage Value */
  void min(double m){Min=m;}

  double max(void){return(Max);}                     /* Maximum Guage Value */
  void max(double m){Max=m;}

  double step(void){return(Step);}                   /* Graduation step size */
  void step(double s){Step=s;}

  double stepdiv(void){return(StepDiv);}             /* Division between above */
  void stepdiv(double s){StepDiv=s;}

  int fontsize(void){return(FontSize);}              /* Font Size for numbers */
  void fontsize(int f){FontSize=f;}

  int fontface(void){return(FontFace);}              /* Font face for numbers */
  void fontface(int f){FontFace=f;}

  double odometer(void){return(Odometer);}           /* Return Odometer value */
  void odometer(double o){Odometer=o;}               /* Set Odometer value    */

  int odomode(void){return(OdoMode);}                /* Return Odometer Mode  */
  void odomode(int o){OdoMode=o;};                   /* Set Odometer Mode     */

  int odoplaces(int &,int &);                        /* Set/get format for odmeter*/

  double odoincsize(void){return(OdoIncSize);}
  void odoincsize(double i){OdoIncSize=i;}

  void odoinc(void){Odometer+=OdoIncSize;if(V2Mode==FL_GAUGE_V2_TRIP)Value2+=OdoIncSize;}
  void ododec(void){Odometer-=OdoIncSize;if(V2Mode==FL_GAUGE_V2_TRIP)Value2-=OdoIncSize;}

  int v2mode(void){return (V2Mode);}                 /* return value 2 Mode   */
  void v2mode(int v){V2Mode=v;}                      /* Set Value 2 Mode      */

  int v2places(int &,int &);

  int places(int &, int &);

  int greenzonemode(void){return(GreenZoneMode);}
  void greenzonemode(int m){GreenZoneMode=m;check_zone();}

  double greenzonestart(void){return (GreenZoneStart);}
  void greenzonestart(double z) {GreenZoneStart=z;check_zone();}   /* Begining of green zone */

  double greenzoneend(void) {return(GreenZoneEnd);}
  void greenzoneend(double z) {GreenZoneEnd=z;check_zone();}




  void greenzonecb(void (*cb)(void *)){GZ_cb=cb;}     /* Set GreenZone Callback    */
};



/******* END OF FILE ********/
#endif

