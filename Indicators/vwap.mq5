//+------------------------------------------------------------------+
//|                                                         VWAP.mq5 |
//|                     Copyright 2015, SOL Digital Consultoria LTDA |
//|                          http://www.soldigitalconsultoria.com.br |
//+------------------------------------------------------------------+
#property copyright         "Copyright 2015, SOL Digital Consultoria LTDA"
#property link              "http://www.soldigitalconsultoria.com.br"
#property version           "1.47"

//#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   4

//--- plot VWAP
#property indicator_label1  "VWAP Daily"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_DASH
#property indicator_width1  2

#property indicator_label2  "VWAP Weekly"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

#property indicator_label3  "VWAP Monthly"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_DASH
#property indicator_width3  2

//RSI
#property indicator_label4  "RSI"
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 70
#property indicator_type4   DRAW_LINE
#property indicator_color4  DodgerBlue

//--- input parameters
input int InpPeriodRSI=14; // Period
//--- indicator buffers
double    ExtRSIBuffer[];
double    ExtPosBuffer[];
double    ExtNegBuffer[];

int       ExtPeriodRSI;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum DATE_TYPE 
  {
   DAILY,
   WEEKLY,
   MONTHLY
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CreateDateTime(DATE_TYPE nReturnType=DAILY,datetime dtDay=D'2000.01.01 00:00:00',int pHour=0,int pMinute=0,int pSecond=0) 
  {
   datetime    dtReturnDate;
   MqlDateTime timeStruct;

   TimeToStruct(dtDay,timeStruct);
   timeStruct.hour = pHour;
   timeStruct.min  = pMinute;
   timeStruct.sec  = pSecond;
   dtReturnDate=(StructToTime(timeStruct));

   if(nReturnType==WEEKLY) 
     {
      while(timeStruct.day_of_week!=0) 
        {
         dtReturnDate=(dtReturnDate-86400);
         TimeToStruct(dtReturnDate,timeStruct);
        }
     }

   if(nReturnType==MONTHLY) 
     {
      timeStruct.day=1;
      dtReturnDate=(StructToTime(timeStruct));
     }

   return dtReturnDate;
  }

sinput  string              Indicator_Name="Volume Weighted Average Price (VWAP)";

input   bool                Enable_Daily            = true;
input   bool                Enable_Weekly           = false;
input   bool                Enable_Monthly          = false;

bool        Show_Daily_Value    = true;
bool        Show_Weekly_Value   = false;
bool        Show_Monthly_Value  = false;

double      VWAP_Buffer_Daily[];
double      VWAP_Buffer_Weekly[];
double      VWAP_Buffer_Monthly[];

double      nPriceArr[];
double      nTotalTPV[];
double      nTotalVol[];
double      nSumDailyTPV = 0, nSumWeeklyTPV = 0, nSumMonthlyTPV = 0;
double      nSumDailyVol = 0, nSumWeeklyVol = 0, nSumMonthlyVol = 0;

int         nIdxDaily=0,nIdxWeekly=0,nIdxMonthly=0,nIdx=0;

bool        bIsFirstRun=true;

ENUM_TIMEFRAMES LastTimePeriod=PERIOD_MN1;

string      sDailyStr   = "";
string      sWeeklyStr  = "";
string      sMonthlyStr = "";
string      sLevel01Str = "";
string      sLevel02Str = "";
string      sLevel03Str = "";
string      sLevel04Str = "";
string      sLevel05Str = "";
datetime    dtLastDay=CreateDateTime(DAILY),dtLastWeek=CreateDateTime(WEEKLY),dtLastMonth=CreateDateTime(MONTHLY);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() 
  {
   //RSI //RSI //RSI //RSI //RSI //RSI //RSI //RSI //RSI
  
 //--- check for input
   if(InpPeriodRSI<1)
     {
      ExtPeriodRSI=14;
      PrintFormat("Incorrect value for input variable InpPeriodRSI = %d. Indicator will use value %d for calculations.",
                  InpPeriodRSI,ExtPeriodRSI);
     }
   else
      ExtPeriodRSI=InpPeriodRSI;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtPosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtNegBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodRSI);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI("+string(ExtPeriodRSI)+")");
   //RSI //RSI //RSI //RSI //RSI //RSI //RSI //RSI //RSI
   
   
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   SetIndexBuffer(3,VWAP_Buffer_Daily,INDICATOR_DATA);
   SetIndexBuffer(4,VWAP_Buffer_Weekly,INDICATOR_DATA);
   SetIndexBuffer(5,VWAP_Buffer_Monthly,INDICATOR_DATA);

   ObjectCreate(0,"VWAP_Daily",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_CORNER,3);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_XDISTANCE,180);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_YDISTANCE,40);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_COLOR,indicator_color1);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_FONTSIZE,7);
   ObjectSetString(0,"VWAP_Daily",OBJPROP_FONT,"Verdana");
   ObjectSetString(0,"VWAP_Daily",OBJPROP_TEXT," ");

   ObjectCreate(0,"VWAP_Weekly",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"VWAP_Weekly",OBJPROP_CORNER,3);
   ObjectSetInteger(0,"VWAP_Weekly",OBJPROP_XDISTANCE,180);
   ObjectSetInteger(0,"VWAP_Weekly",OBJPROP_YDISTANCE,60);
   ObjectSetInteger(0,"VWAP_Weekly",OBJPROP_COLOR,indicator_color2);
   ObjectSetInteger(0,"VWAP_Weekly",OBJPROP_FONTSIZE,7);
   ObjectSetString(0,"VWAP_Weekly",OBJPROP_FONT,"Verdana");
   ObjectSetString(0,"VWAP_Weekly",OBJPROP_TEXT," ");

   ObjectCreate(0,"VWAP_Monthly",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"VWAP_Monthly",OBJPROP_CORNER,3);
   ObjectSetInteger(0,"VWAP_Monthly",OBJPROP_XDISTANCE,180);
   ObjectSetInteger(0,"VWAP_Monthly",OBJPROP_YDISTANCE,80);
   ObjectSetInteger(0,"VWAP_Monthly",OBJPROP_COLOR,indicator_color3);
   ObjectSetInteger(0,"VWAP_Monthly",OBJPROP_FONTSIZE,7);
   ObjectSetString(0,"VWAP_Monthly",OBJPROP_FONT,"Verdana");
   ObjectSetString(0,"VWAP_Monthly",OBJPROP_TEXT," ");


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int pReason) 
  {
   ObjectDelete(0,"VWAP_Daily");
   ObjectDelete(0,"VWAP_Weekly");
   ObjectDelete(0,"VWAP_Monthly");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime  &time[],
                const double    &open[],
                const double    &high[],
                const double    &low[],
                const double    &close[],
                const long      &tick_volume[],
                const long      &volume[],
                const int       &spread[]) 
  {

   if(PERIOD_CURRENT!=LastTimePeriod) 
     {
      bIsFirstRun=true;
      LastTimePeriod=PERIOD_CURRENT;
     }

   if(rates_total>prev_calculated || bIsFirstRun) 
     {
      ArrayResize(nPriceArr,rates_total);
      ArrayResize(nTotalTPV,rates_total);
      ArrayResize(nTotalVol,rates_total);

      if(Enable_Daily)   {nIdx = nIdxDaily;   nSumDailyTPV = 0;   nSumDailyVol = 0;}
      if(Enable_Weekly)  {nIdx = nIdxWeekly;  nSumWeeklyTPV = 0;  nSumWeeklyVol = 0;}
      if(Enable_Monthly) {nIdx = nIdxMonthly; nSumMonthlyTPV = 0; nSumMonthlyVol = 0;}

      for(; nIdx<rates_total; nIdx++) 
        {
         if(CreateDateTime(DAILY,time[nIdx])!=dtLastDay) 
           {
            nIdxDaily=nIdx;
            nSumDailyTPV = 0;
            nSumDailyVol = 0;
           }
         if(CreateDateTime(WEEKLY,time[nIdx])!=dtLastWeek) 
           {
            nIdxWeekly=nIdx;
            nSumWeeklyTPV = 0;
            nSumWeeklyVol = 0;
           }
         if(CreateDateTime(MONTHLY,time[nIdx])!=dtLastMonth) 
           {
            nIdxMonthly=nIdx;
            nSumMonthlyTPV = 0;
            nSumMonthlyVol = 0;
           }

         nPriceArr[nIdx] = 0;
         nTotalTPV[nIdx] = 0;
         nTotalVol[nIdx] = 0;

         nPriceArr[nIdx]=(close[nIdx]+high[nIdx]+low[nIdx])/3;
         

         if(tick_volume[nIdx]) 
           {
            nTotalTPV[nIdx] = (nPriceArr[nIdx] * tick_volume[nIdx]);
            nTotalVol[nIdx] = (double)tick_volume[nIdx];
              } else if(volume[nIdx]) {
            nTotalTPV[nIdx] = (nPriceArr[nIdx] * volume[nIdx]);
            nTotalVol[nIdx] = (double)volume[nIdx];
           }

         if(Enable_Daily && (nIdx>=nIdxDaily)) 
           {
            nSumDailyTPV += nTotalTPV[nIdx];
            nSumDailyVol += nTotalVol[nIdx];

            if(nSumDailyVol)
               VWAP_Buffer_Daily[nIdx]=(nSumDailyTPV/nSumDailyVol);

            if((sDailyStr!="VWAP Daily: "+(string)NormalizeDouble(VWAP_Buffer_Daily[nIdx],_Digits)) && Show_Daily_Value) 
              {
               sDailyStr="VWAP Daily: "+(string)NormalizeDouble(VWAP_Buffer_Daily[nIdx],_Digits);
               ObjectSetString(0,"VWAP_Daily",OBJPROP_TEXT,sDailyStr);
              }
           }
/*
         if(Enable_Weekly && (nIdx>=nIdxWeekly)) 
           {
            nSumWeeklyTPV += nTotalTPV[nIdx];
            nSumWeeklyVol += nTotalVol[nIdx];

            if(nSumWeeklyVol)
               VWAP_Buffer_Weekly[nIdx]=(nSumWeeklyTPV/nSumWeeklyVol);

            if((sWeeklyStr!="VWAP Weekly: "+(string)NormalizeDouble(VWAP_Buffer_Weekly[nIdx],_Digits)) && Show_Weekly_Value) 
              {
               sWeeklyStr="VWAP Weekly: "+(string)NormalizeDouble(VWAP_Buffer_Weekly[nIdx],_Digits);
               ObjectSetString(0,"VWAP_Weekly",OBJPROP_TEXT,sWeeklyStr);
              }
           }

         if(Enable_Monthly && (nIdx>=nIdxMonthly)) 
           {
            nSumMonthlyTPV += nTotalTPV[nIdx];
            nSumMonthlyVol += nTotalVol[nIdx];

            if(nSumMonthlyVol)
               VWAP_Buffer_Monthly[nIdx]=(nSumMonthlyTPV/nSumMonthlyVol);

            if((sMonthlyStr!="VWAP Monthly: "+(string)NormalizeDouble(VWAP_Buffer_Monthly[nIdx],_Digits)) && Show_Monthly_Value) 
              {
               sMonthlyStr="VWAP Monthly: "+(string)NormalizeDouble(VWAP_Buffer_Monthly[nIdx],_Digits);
               ObjectSetString(0,"VWAP_Monthly",OBJPROP_TEXT,sMonthlyStr);
              }
           }*/

         dtLastDay=CreateDateTime(DAILY,time[nIdx]);
         dtLastWeek=CreateDateTime(WEEKLY,time[nIdx]);
         dtLastMonth=CreateDateTime(MONTHLY,time[nIdx]);
        }

      

      bIsFirstRun=false;
     }
     
     //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION
     if(rates_total<=ExtPeriodRSI)
      return(0);
//--- preliminary calculations
   int pos=prev_calculated-1;
   if(pos<=ExtPeriodRSI)
     {
      double sum_pos=0.0;
      double sum_neg=0.0;
      //--- first RSIPeriod values of the indicator are not calculated
      ExtRSIBuffer[0]=0.0;
      ExtPosBuffer[0]=0.0;
      ExtNegBuffer[0]=0.0;
      for(int i=1; i<=ExtPeriodRSI; i++)
        {
         ExtRSIBuffer[i]=0.0;
         ExtPosBuffer[i]=0.0;
         ExtNegBuffer[i]=0.0;
         double diff=VWAP_Buffer_Daily[i]-VWAP_Buffer_Daily[i-1];
         sum_pos+=(diff>0?diff:0);
         sum_neg+=(diff<0?-diff:0);
        }
      //--- calculate first visible value
      ExtPosBuffer[ExtPeriodRSI]=sum_pos/ExtPeriodRSI;
      ExtNegBuffer[ExtPeriodRSI]=sum_neg/ExtPeriodRSI;
      if(ExtNegBuffer[ExtPeriodRSI]!=0.0)
         ExtRSIBuffer[ExtPeriodRSI]=100.0-(100.0/(1.0+ExtPosBuffer[ExtPeriodRSI]/ExtNegBuffer[ExtPeriodRSI]));
      else
        {
         if(ExtPosBuffer[ExtPeriodRSI]!=0.0)
            ExtRSIBuffer[ExtPeriodRSI]=100.0;
         else
            ExtRSIBuffer[ExtPeriodRSI]=50.0;
        }
      //--- prepare the position value for main calculation
      pos=ExtPeriodRSI+1;
     }
//--- the main loop of calculations
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      double diff=VWAP_Buffer_Daily[i]-VWAP_Buffer_Daily[i-1];
      ExtPosBuffer[i]=(ExtPosBuffer[i-1]*(ExtPeriodRSI-1)+(diff>0.0?diff:0.0))/ExtPeriodRSI;
      ExtNegBuffer[i]=(ExtNegBuffer[i-1]*(ExtPeriodRSI-1)+(diff<0.0?-diff:0.0))/ExtPeriodRSI;
      if(ExtNegBuffer[i]!=0.0)
         ExtRSIBuffer[i]=100.0-100.0/(1+ExtPosBuffer[i]/ExtNegBuffer[i]);
      else
        {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=50.0;
        }
     }
      //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION //RSI CALCULATION
     

   return(rates_total);
  }
//+------------------------------------------------------------------+
