//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                             Copyright 2000-2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2024, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "Bollinger Bands"
#include <MovingAverages.mqh>
//---
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   7

#property indicator_type1   DRAW_NONE
// #property indicator_color1  LightSeaGreen

#property indicator_type2   DRAW_NONE
// #property indicator_color2  LightSeaGreen

#property indicator_type3   DRAW_NONE
// #property indicator_color3  LightSeaGreen

#property indicator_type4   DRAW_NONE
// #property indicator_color4  clrDodgerBlue
// #property indicator_style4 STYLE_SOLID
// #property indicator_width4 4
#property indicator_type5   DRAW_NONE
// #property indicator_color5  clrDodgerBlue
// #property indicator_style5 STYLE_SOLID
// #property indicator_width5 4

#property indicator_type6   DRAW_NONE
// #property indicator_color6  clrYellow
// #property indicator_style6 STYLE_SOLID
// #property indicator_width6 4

#property indicator_type7   DRAW_NONE
// #property indicator_color7  clrYellow
// #property indicator_style7 STYLE_SOLID
// #property indicator_width7 4

#property indicator_label1  "Bands middle"
#property indicator_label2  "Bands upper"
#property indicator_label3  "Bands lower"
#property indicator_label4  "BBU 1ST DERIVATIVE"
#property indicator_label5  "BBU 2ND DERIVATIVE"
#property indicator_label6  "BBL 1ST DERIVATIVE"
#property indicator_label7  "BBL 2ND DERIVATIVE"

#define UpArrow 233
#define DownArrow 234
#define ArrowShift 15
//--- input parametrs
input int     InpBandsPeriod=20;       // Period
input int     InpBandsShift=0;         // Shift
input double  InpBandsDeviations=2.0;  // Deviation
//--- global variables
int           ExtBandsPeriod,ExtBandsShift;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//--- indicator buffer
double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtStdDevBuffer[];
double        ExtInflectionUpperBuffer1[];
double        ExtInflectionUpperBuffer2[];
double        ExtInflectionLowerBuffer1[];
double        ExtInflectionLowerBuffer2[];

double local_max = 0.002;
double local_min = -0.002;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      PrintFormat("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else
      ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsShift<0)
     {
      ExtBandsShift=0;
      PrintFormat("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.",InpBandsShift,ExtBandsShift);
     }
   else
      ExtBandsShift=InpBandsShift;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      PrintFormat("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else
      ExtBandsDeviations=InpBandsDeviations;
//--- define buffers
   SetIndexBuffer(0,ExtMLBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtTLBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtBLBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtInflectionUpperBuffer1,INDICATOR_DATA);
   SetIndexBuffer(4,ExtInflectionUpperBuffer2,INDICATOR_DATA);
   SetIndexBuffer(5,ExtInflectionLowerBuffer1,INDICATOR_DATA);
   SetIndexBuffer(6,ExtInflectionLowerBuffer2,INDICATOR_DATA);
   SetIndexBuffer(7,ExtStdDevBuffer,INDICATOR_CALCULATIONS);

//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") M");
   PlotIndexSetString(1,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") U");
   PlotIndexSetString(2,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") L");
   PlotIndexSetString(3,PLOT_LABEL,"B("+string(ExtBandsPeriod)+") BBU 1ST derivative ");
   PlotIndexSetString(4,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") BBU 2ND derivative");
   PlotIndexSetString(5,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") BBL 1ST derivative ");
   PlotIndexSetString(6,PLOT_LABEL,"BB("+string(ExtBandsPeriod)+") BBL 2ND derivative");
//   PlotIndexSetString(7,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") stddev");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"Bollinger Bands with Arrows");
//--- indexes draw begin settings

   ExtPlotBegin=ExtBandsPeriod-1;
   // PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtBandsPeriod);

   // PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(3,PLOT_ARROW,DownArrow);
   // PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,ArrowShift);

   // PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(4,PLOT_ARROW,DownArrow);
   // PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,ArrowShift);
   // PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(5,PLOT_ARROW,DownArrow);
   // PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,ArrowShift);

   // PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   // PlotIndexSetInteger(6,PLOT_ARROW,DownArrow);
   // PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,ArrowShift);
//--- indexes shift settings
   // PlotIndexSetInteger(0,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(1,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(2,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(3,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(4,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(5,PLOT_SHIFT,ExtBandsShift);
   // PlotIndexSetInteger(6,PLOT_SHIFT,ExtBandsShift);

//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+

//rates_total-1 is the index of the current bar
//e.g. current time and open:
//Print(time[rates_total-1]," ",open[rates_total-1);
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total<ExtPlotBegin)
      return(0);
      
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=ExtBandsPeriod+begin)
     {
      ExtPlotBegin=ExtBandsPeriod+begin;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
     
//--- starting calculation
   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(int i=pos; i<rates_total-1 && !IsStopped(); i++)
     {
      ExtInflectionUpperBuffer1[i] = EMPTY_VALUE;
      ExtInflectionUpperBuffer2[i] = EMPTY_VALUE;
      ExtInflectionLowerBuffer1[i] = EMPTY_VALUE;
      ExtInflectionLowerBuffer2[i] = EMPTY_VALUE;
      //--- middle line
      ExtMLBuffer[i]=SimpleMA(i,ExtBandsPeriod,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,ExtBandsPeriod);
      //--- upper line
      ExtTLBuffer[i]=ExtMLBuffer[i]+ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i]=ExtMLBuffer[i]-ExtBandsDeviations*ExtStdDevBuffer[i];
      
//      if(i < rates_total-1) {
//         if (ExtTLBuffer[i]-ExtTLBuffer[i+1] < local_max || ExtTLBuffer[i]-ExtTLBuffer[i+1] > local_min) {
            ExtInflectionUpperBuffer1[i] = ExtTLBuffer[i]-ExtTLBuffer[i+1]; 
            ExtInflectionLowerBuffer1[i] = ExtBLBuffer[i]-ExtBLBuffer[i+1]; 
            ExtInflectionUpperBuffer2[i] = ExtInflectionUpperBuffer1[i]-ExtInflectionUpperBuffer1[i+1]; 
            ExtInflectionLowerBuffer2[i] = ExtInflectionLowerBuffer1[i]-ExtInflectionLowerBuffer1[i+1]; 
//Print(ExtTLBuffer[i]," ", ExtTLBuffer[i+1]);
      //}
    }    
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period)
     {
      for(int i=0; i<period; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period);
     }
//--- return calculated value
   return(std_dev);
  }
//+------------------------------------------------------------------+
