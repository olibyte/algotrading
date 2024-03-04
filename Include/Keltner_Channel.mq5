//+------------------------------------------------------------------+
//|                                              Keltner Channel.mq5 |
//|        Copyright 2023, Roberto Jacobs (3rjfx) ~ Date: 2023-10-07 |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Roberto Jacobs (3rjfx) ~ Date: 2023-10-07"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "1.00"
#property indicator_chart_window
//---
#property indicator_buffers 4
#property indicator_plots   3
#property indicator_label1  "Middle line" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 
#property indicator_label2  "Upper band" 
#property indicator_type2   DRAW_LINE 
#property indicator_color2  clrWhiteSmoke
#property indicator_style2  STYLE_SOLID 
#property indicator_width2  1 
#property indicator_label3  "Lower band" 
#property indicator_type3   DRAW_LINE 
#property indicator_color3  clrWhiteSmoke
#property indicator_style3  STYLE_SOLID 
#property indicator_width3  1 
//---
//--
input int                period_kc = 20;             // Input Keltner Channel Period 
input ENUM_MA_METHOD     ma_method = MODE_EMA;       // Select MA Type of smoothing
input ENUM_APPLIED_PRICE  ma_price = PRICE_TYPICAL;  // Select MA Applied Price
input int               atr_period = 20;             // Input ATR Period (typically over 10 or 20)
input double            band_multi = 1.00;           // Input the Band Multiplier ATR Desired
//--
//-- Indicator buffers
double KC_Middle[];
double KC_UpperB[];
double KC_LowerB[];
double KC_ATRtemp[];
//--variable for storing the handle of the Keltner Channel indicator 
int handleMA;
int handleATR;
//--- name of the indicator on a chart 
string short_name; 
//--- we will keep the number of values in the Keltner Channel indicator 
int    bars_calculated=0; 
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   //-- assignment of array to indicator buffer 
   SetIndexBuffer(0,KC_Middle,INDICATOR_DATA);
   SetIndexBuffer(1,KC_UpperB,INDICATOR_DATA);
   SetIndexBuffer(2,KC_LowerB,INDICATOR_DATA);
   SetIndexBuffer(3,KC_ATRtemp,INDICATOR_CALCULATIONS);
   //--
   handleMA=iMA(Symbol(),Period(),period_kc,0,MODE_EMA,ma_price);
   //--
   if(handleMA==INVALID_HANDLE) 
     { 
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the Moving Average indicator for the symbol %s/%s, error code %d", 
                  Symbol(), 
                  EnumToString(Period()), 
                  GetLastError()); 
      //--- the indicator is stopped early 
      return(INIT_FAILED); 
     } 
   //--
   handleATR=iATR(Symbol(),Period(),atr_period);
   //--
   if(handleATR==INVALID_HANDLE) 
     { 
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the ATR indicator for the symbol %s/%s, error code %d", 
                  Symbol(), 
                  EnumToString(Period()), 
                  GetLastError()); 
      //--- the indicator is stopped early 
      return(INIT_FAILED); 
     } 
   //--
   short_name=StringFormat("Keltner Channel(%d, %s, %.2f)",period_kc,EnumToString(ma_method),band_multi);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   //--
   return(INIT_SUCCEEDED);
//---
  }
//---------//
//+------------------------------------------------------------------+ 
//| Indicator deinitialization function                              | 
//+------------------------------------------------------------------+ 
void OnDeinit(const int reason) 
  { 
//---
   Comment(""); 
   PrintFormat("%s: Deinitialization reason code=%d",__FUNCTION__,reason);
   Print(getUninitReasonText(reason));
   if(handleMA!=INVALID_HANDLE)  IndicatorRelease(handleMA);
   if(handleATR!=INVALID_HANDLE) IndicatorRelease(handleATR);
   //--
   return;
//---
  }
//---------//
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
    int x,xlimit;
//--- not all data may be calculated
    int calculated=BarsCalculated(handleMA);
    if(calculated<rates_total)
      {
       Print("Not all data of Moving Average Indicator is calculated (",calculated," bars ). Error",GetLastError());
       return(0);
      }
    //--
    calculated=BarsCalculated(handleATR);
    if(calculated<rates_total)
      {
       Print("Not all data of ATR Indicator is calculated (",calculated," bars ). Error",GetLastError());
       return(0);
      }
    //--
//--- we can copy not all data
    int to_copy; 
    if(prev_calculated>rates_total || prev_calculated==0) 
      {
       to_copy=rates_total;
      }
    else
      {
       to_copy=rates_total-prev_calculated;
       if(to_copy==0) to_copy=1;
      }
    //--
    if(IsStopped()) return(0); //Checking for stop flag
    //-- get Moving Average Indicator buffers
    if(CopyBuffer(handleMA,0,0,to_copy,KC_Middle)<0)
      {
       Print("Getting Moving Average buffers is failed! Error",GetLastError());
       return(0);
      }
    //--
    if(IsStopped()) return(0); //Checking for stop flag
    //--- get ATR Indicator buffer
    if(CopyBuffer(handleATR,0,0,to_copy,KC_ATRtemp)<0)
      {
       Print("Getting ATR buffers is failed! Error",GetLastError());
       return(0);
      }
    //--
//--- last counted bar will be recounted
    if(prev_calculated==0)
       xlimit=0;
    else xlimit=prev_calculated-1;
//--- main loop
    for(x=xlimit; x<calculated; x++)
      {
        double bmd=KC_ATRtemp[x]*band_multi;
        KC_UpperB[x]=KC_Middle[x]+bmd;
        KC_LowerB[x]=KC_Middle[x]-bmd;
      }
    //--
//--- memorize the number of values in the Force indicator 
   bars_calculated=calculated;
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//---------//
//+------------------------------------------------------------------+

string getUninitReasonText(int reasonCode) 
  { 
//---
   string text=""; 
   //--- 
   switch(reasonCode) 
     { 
       case REASON_PROGRAM:
            text="The EA has stopped working calling by remove function."; break;
       case REASON_REMOVE: 
            text="Program "+__FILE__+" was removed from chart"; break;
       case REASON_RECOMPILE:
            text="Program recompiled."; break;    
       case REASON_CHARTCHANGE: 
            text="Symbol or timeframe was changed"; break;
       case REASON_CHARTCLOSE: 
            text="Chart was closed"; break; 
       case REASON_PARAMETERS: 
            text="Input-parameter was changed"; break;            
       case REASON_ACCOUNT: 
            text="Account was changed"; break; 
       case REASON_TEMPLATE: 
            text="New template was applied to chart"; break; 
       case REASON_INITFAILED:
            text="The OnInit() handler returned a non-zero value."; break;
       case REASON_CLOSE: 
            text="Terminal closed."; break;
       default: text="Another reason"; break;
     } 
   //--
   return text;
//---
  } //-end getUninitReasonText()
//---------//