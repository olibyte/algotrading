//+------------------------------------------------------------------+
//|                                                    TaiwanBot.mq5 |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#include <Trade/Trade.mqh>
#include <Indicators/IndicatorBollinger.mqh>
CTrade Trade;
CPositionInfo PositionInfo;


int rangeHighIndex,rangeLowIndex;
double rangeHigh,rangeLow,H1High,H1Low,H4High,H4Low,M15High,M15Low, closeHigh;
double entry_gap,exit_gap;
CIndicatorBollinger BB;
CIndicatorBollinger BB_H1;
CIndicatorBollinger BB_H4;
CIndicatorBollinger BB_D1;
double ValuesZZ[];
int HandleZZ;


long positionOpenSeconds = -1;
long positionHoldSeconds = 7200; //1H
long positionWaitSeconds = 7200;
int lowTestCount,highTestCount;
bool lowTested, highTested;
bool bullBreakout,bearBreakout;
bool buy_signal, sell_signal, breakout_buy_signal, breakout_sell_signal, last_kiss_buy, last_kiss_sell,aoi_buy,aoi_sell, in_r_zone, in_s_zone = false;
int counter, aoi_counter, lowest, trend = 0;
double lowestPrice,highestPrice, prevLowestPrice, prevHighestPrice;
int prevLowest, prevHighest;
//////////////////////////////////////////

int HandleVolumeAverage;
enum enMaTypes
  {
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma    // Linear weighted MA
  };
//---
enum enVolumeType
  {
   vol_ticks, // Use ticks
   vol_volume // Use real volume
  };
//--- input parameters
input enVolumeType inpVolumeType      = vol_ticks; // Volume type to use
input int          inpAveragePeriod   = 50;        // Average period
input enMaTypes    inpAverageMethod   = ma_ema;    // Average method
input double       inpBreakoutPercent = 50;        // Breakout percentage
input int holdBars = 5; //maximum time to hold a position
input int waitBars = 5; //minimum time before opening new position


//--- buffers
double  val[],valc[],average[];
//////////////////////////////////////
/*
Are there
*/
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//   BB.Init(Symbol(), Period(), 21, 0, .382, MODE_CLOSE);
//   BB_H1.Init(Symbol(),PERIOD_H1,21,0,.382, MODE_CLOSE);
//   BB_H4.Init(Symbol(),PERIOD_H4,21,0,.382, MODE_CLOSE);
//   BB_D1.Init(Symbol(),PERIOD_D1,21,0,.382, MODE_CLOSE);
//---

//   HandleVolumeAverage = iCustom(Symbol(), Period(),"volume_average.ex5",inpVolumeType,inpAveragePeriod,inpAverageMethod,inpBreakoutPercent);
//   ArraySetAsSeries(val,true);
//   ArraySetAsSeries(valc,true);
//   ArraySetAsSeries(average,true);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(!IsNewBar())
      return;
/////////////////////////////////////

   int numCandles = 20;
//   if(CopyBuffer(HandleVolumeAverage, 0, 0, numCandles, val) < numCandles)
//      return;
//   if(CopyBuffer(HandleVolumeAverage, 1, 0, numCandles, valc) < numCandles)
//      return;
//   if(CopyBuffer(HandleVolumeAverage, 2, 0, numCandles, average) < numCandles)
//      return;
//   Print(val[0]);
//   Print(valc[0]);
//   Print("ave: "+DoubleToString(average[1]));
//   Print("ivol: "+IntegerToString(iVolume(Symbol(),Period(),1)));

//if vol is double average vol, place momentum trade.
/////////////////////////////////////

   /*data from last deal*/
   ulong deal_ticket = GetLastDealTicket();
   ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
   ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
   double deal_profit = (double)HistoryDealGetDouble(deal_ticket,DEAL_PROFIT);
   datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   long secondsSinceLastDeal = (long)TimeCurrent()-(long)deal_time;
   long secondsSinceLastPositionOpen = (long)TimeCurrent()-positionOpenSeconds;
//   Print("deal_time: ",deal_time);
//   Print("deal_entry: ",EnumToString(deal_entry));
//   Print("deal_type: ",EnumToString(deal_type));
//   Print("deal_profit",deal_profit);
//   Print("deal_ticket",deal_ticket);
//   Print("PositionInfoSelectByTicket: ",PositionInfo.SelectByTicket(deal_ticket));
//   Print(Period()); //15
//   Print(PeriodSeconds()); //900
//   Print(iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
//   Print("time 5 bars after last deal: ",deal_time + PeriodSeconds(Period())*5);
   /*Don't open another position too soon*/
//if last deal was deal entry in
//get the deal time
//calc deal time + 5 bars
//if time now is > deal time + 5 bars, close position

   if(PositionsTotal() > 0 && deal_entry == DEAL_ENTRY_IN)
     {
      datetime last_deal_expiry = deal_time+(PeriodSeconds(Period())*5);

      //      Print("last deal EXPIRY: ",last_deal_expiry);
      //      Print("last deal entry in time: ",deal_time);
      //      Print("Time now:",TimeCurrent());
      long delta = (long)TimeCurrent()-deal_time;
      long expiry = (long)last_deal_expiry;
      //      Print("DELTA: ", delta);
      //      Print("Expiry: ",expiry);
     }
   if(PositionsTotal() == 0 && deal_entry == DEAL_ENTRY_OUT)
     {
      datetime last_deal_wait = deal_time+(PeriodSeconds(Period())*5);
      //      Print("last deal entry out time: ",deal_time);
      //      Print("Time before we can open next position: ",last_deal_wait);
      //      Print("Time now:",TimeCurrent());
      long delta = (long)TimeCurrent()-deal_time;
      //      Print("DELTA: ", delta);
     }
//don't open a momentum trade if it was a loss.
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits()); //long
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits()); //short
   double sl_gap = PointsToDouble(200);
   double tp_gap = PointsToDouble(200);
   double o = iOpen(Symbol(),Period(),1);
   double h = iHigh(Symbol(),Period(),1);
   double l = iLow(Symbol(),Period(),1);
   double c = iClose(Symbol(),Period(),1);
   double body_size = MathAbs(o-c);
   double head_size = h - MathMax(o,c);
   double tail_size = MathMin(o,c)-l;
   bool strong_bear = (c < o) && head_size > (tail_size*3) && body_size > (tail_size * 3); //long body + head
   bool strong_bull = (c > o) && tail_size > (head_size*3) && body_size > (head_size * 3); //long body + tail

   double H_D1 = iHigh(Symbol(),PERIOD_D1,1);
   double L_D1 = iLow(Symbol(),PERIOD_D1,1);
   double C_D1 = iClose(Symbol(),PERIOD_D1,1);

   double PP_D1 = NormalizeDouble((H_D1 + L_D1 + C_D1) / 3, Digits());

   double R1_D1 = NormalizeDouble((2 * PP_D1) - L_D1, Digits());
   double R2_D1 = NormalizeDouble(PP_D1 + H_D1 - L_D1, Digits());
   double R3_D1 = NormalizeDouble(H_D1 + (2*(PP_D1-L_D1)),Digits());

   double S1_D1 = NormalizeDouble((2 * PP_D1) - H_D1, Digits());
   double S2_D1 = NormalizeDouble(PP_D1 - H_D1 + L_D1, Digits());
   double S3_D1 = NormalizeDouble(L_D1 - (2*(H_D1-PP_D1)),Digits());

   double FR1_D1 = NormalizeDouble(PP_D1+((H_D1-L_D1)*0.368), Digits());
   double FR2_D1 = NormalizeDouble(PP_D1+((H_D1-L_D1)*0.79), Digits());
   double FR3_D1 = NormalizeDouble(PP_D1+((H_D1-L_D1)*1.000), Digits());
   double FR4_D1 = NormalizeDouble(PP_D1+((H_D1-L_D1)*1.68), Digits());
   double FS1_D1 = NormalizeDouble(PP_D1-((H_D1-L_D1)*0.368), Digits());
   double FS2_D1 = NormalizeDouble(PP_D1-((H_D1-L_D1)*0.79), Digits());
   double FS3_D1 = NormalizeDouble(PP_D1-((H_D1-L_D1)*1.000), Digits());
   double FS4_D1 = NormalizeDouble(PP_D1-((H_D1-L_D1)*1.68), Digits());
   double H_H4 = iHigh(Symbol(),PERIOD_H4,1);
   double L_H4 = iLow(Symbol(),PERIOD_H4,1);
   double C_H4 = iClose(Symbol(),PERIOD_H4,1);

   double PP_H4 = NormalizeDouble((H_H4 + L_H4 + C_H4) / 3, Digits());

   double R1_H4 = NormalizeDouble((2 * PP_H4) - L_H4, Digits());
   double R2_H4 = NormalizeDouble(PP_H4 + H_H4 - L_H4, Digits());
   double R3_H4 = NormalizeDouble(H_H4 + (2*(PP_H4-L_H4)),Digits());

   double S1_H4 = NormalizeDouble((2 * PP_H4) - H_H4, Digits());
   double S2_H4 = NormalizeDouble(PP_H4 - H_H4 + L_H4, Digits());
   double S3_H4 = NormalizeDouble(L_H4 - (2*(H_H4-PP_H4)),Digits());

   double FR1_H4 = NormalizeDouble(PP_H4+((H_H4-L_H4)*0.368), Digits());
   double FR2_H4 = NormalizeDouble(PP_H4+((H_H4-L_H4)*0.79), Digits());
   double FR3_H4 = NormalizeDouble(PP_H4+((H_H4-L_H4)*1.000), Digits());
   double FR4_H4 = NormalizeDouble(PP_H4+((H_H4-L_H4)*1.68), Digits());
   double FS1_H4 = NormalizeDouble(PP_H4-((H_H4-L_H4)*0.368), Digits());
   double FS2_H4 = NormalizeDouble(PP_H4-((H_H4-L_H4)*0.79), Digits());
   double FS3_H4 = NormalizeDouble(PP_H4-((H_H4-L_H4)*1.000), Digits());
   double FS4_H4 = NormalizeDouble(PP_H4-((H_H4-L_H4)*1.68), Digits());

//  double H_H1 = iHigh(Symbol(),PERIOD_H1,1);
//  double L_H1 = iLow(Symbol(),PERIOD_H1,1);
//  double C_H1 = iClose(Symbol(),PERIOD_H1,1);

//  double PP_H1 = NormalizeDouble((H_H1 + L_H1 + C_H1) / 3, Digits());

//  double R1_H1 = NormalizeDouble((2 * PP_H1) - L_H1, Digits());
//  double R2_H1 = NormalizeDouble(PP_H1 + H_H1 - L_H1, Digits());
//  double R3_H1 = NormalizeDouble(H_H1 + (2*(PP_H1-L_H1)),Digits());

//  double S1_H1 = NormalizeDouble((2 * PP_H1) - H_H1, Digits());
//  double S2_H1 = NormalizeDouble(PP_H1 - H_H1 + L_H1, Digits());
//  double S3_H1 = NormalizeDouble(L_H1 - (2*(H_H1-PP_H1)),Digits());

//  double FR1_H1 = NormalizeDouble(PP_H1+((H_H1-L_H1)*0.368), Digits());
//  double FR2_H1 = NormalizeDouble(PP_H1+((H_H1-L_H1)*0.79), Digits());
//  double FR3_H1 = NormalizeDouble(PP_H1+((H_H1-L_H1)*1.000), Digits());
//  double FR4_H1 = NormalizeDouble(PP_H1+((H_H1-L_H1)*1.68), Digits());
//  double FS1_H1 = NormalizeDouble(PP_H1-((H_H1-L_H1)*0.368), Digits());
//  double FS2_H1 = NormalizeDouble(PP_H1-((H_H1-L_H1)*0.79), Digits());
//  double FS3_H1 = NormalizeDouble(PP_H1-((H_H1-L_H1)*1.000), Digits());
//  double FS4_H1 = NormalizeDouble(PP_H1-((H_H1-L_H1)*1.68), Digits());
//if Period() > 5)
   /*
      double H_M15 = iHigh(Symbol(),PERIOD_M15,1);
      double L_M15 = iLow(Symbol(),PERIOD_M15,1);
      double C_M15 = iClose(Symbol(),PERIOD_M15,1);

      double PP_M15 = NormalizeDouble((H_M15 + L_M15 + C_M15) / 3, Digits());

      double R1_M15 = NormalizeDouble((2 * PP_M15) - L_M15, Digits());
      double R2_M15 = NormalizeDouble(PP_M15 + H_M15 - L_M15, Digits());
      double R3_M15 = NormalizeDouble(H_M15 + (2*(PP_M15-L_M15)),Digits());

      double S1_M15 = NormalizeDouble((2 * PP_M15) - H_M15, Digits());
      double S2_M15 = NormalizeDouble(PP_M15 - H_M15 + L_M15, Digits());
      double S3_M15 = NormalizeDouble(L_M15 - (2*(H_M15-PP_M15)),Digits());

      double FR1_M15 = NormalizeDouble(PP_M15+((H_M15-L_M15)*0.368), Digits());
      double FR2_M15 = NormalizeDouble(PP_M15+((H_M15-L_M15)*0.79), Digits());
      double FR3_M15 = NormalizeDouble(PP_M15+((H_M15-L_M15)*1.000), Digits());
      double FR4_M15 = NormalizeDouble(PP_M15+((H_M15-L_M15)*1.68), Digits());
      double FS1_M15 = NormalizeDouble(PP_M15-((H_M15-L_M15)*0.368), Digits());
      double FS2_M15 = NormalizeDouble(PP_M15-((H_M15-L_M15)*0.79), Digits());
      double FS3_M15 = NormalizeDouble(PP_M15-((H_M15-L_M15)*1.000), Digits());
      double FS4_M15 = NormalizeDouble(PP_M15-((H_M15-L_M15)*1.68), Digits());
      */

   rangeHighIndex =           iHighest(Symbol(),PERIOD_H4,MODE_HIGH,1000,1); //swing high
   rangeLowIndex =            iLowest(Symbol(),PERIOD_H4,MODE_LOW,1000,1); //swing low
   if(rangeHigh != iHigh(Symbol(),PERIOD_H4,rangeHighIndex)) //if the swing high we have stored is different to the one above...
     {
      //Then we have a new range high
      rangeHigh = iHigh(Symbol(),PERIOD_H4,rangeHighIndex);
//      drawText(rangeHighIndex,clrGreen,"H");
     }
   if(rangeLow != iLow(Symbol(),PERIOD_H4,rangeLowIndex))
     {
      rangeLow = iLow(Symbol(),PERIOD_H4,rangeLowIndex);
//      drawText(rangeLowIndex,clrRed,"L");
     }
   double height = PointsToDouble(50);
   /*
      if(iVolume(Symbol(),Period(),1) > (2*average[1]))
        {
         if(iClose(Symbol(),Period(),1) > iOpen(Symbol(),Period(),1))
           {
            Trade.BuyStop(0.1,ask,Symbol(),ask-sl_gap,ask+tp_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
           }
         else
           {
            Trade.SellStop(0.1,bid,Symbol(),bid+sl_gap,bid-sl_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(),Period(),0)+PeriodSeconds(Period()));
           }

        }
   */
   if(PositionsTotal() > 0)
     {
      if(counter > 4)
        {
         counter = 0;
         breakout_buy_signal = false;
         breakout_sell_signal = false;
        }
      if(secondsSinceLastPositionOpen > positionHoldSeconds)
        {
         Trade.PositionClose(deal_ticket);
        }
     }

   /**/
//S&D tests
   /*
      double prev_close = iClose(Symbol(),Period(),2);
      double prev_low = iLow(Symbol(),Period(),2);
      double prev_high = iHigh(Symbol(),Period(),2);
      if(l > FS1_H4 && prev_low < FS1_H4)    //testing support
        {
         if(!lowTested)
           {
            lowTested = true;
            highTested = false;
            if(counter % 2 == 0)
               counter++;
            if(counter == 1)
               drawText(1,clrBlack,"first touch");
            if(counter == 3)
               drawText(1,clrBlack,"third touch");
            if(counter > 4)
              {
               drawText(1,clrBlue,IntegerToString(counter)+"th touch");
               breakout_buy_signal = true;
               breakout_sell_signal = false;
              }
           }
        }

      if(h < FR1_H4 && prev_high > FR1_H4) //testing resistance
        {
         if(!highTested)
           {
            highTested = true;
            lowTested = false;
            if(counter % 2 == 1)
               counter++;
            if(counter == 2)
               drawText(1,clrBlack,"second touch");
            if(counter == 4)
               drawText(1,clrBlack,"fourth touch");
            if(counter > 4)
              {
               drawText(1,clrRed,IntegerToString(counter)+"th touch");
               breakout_sell_signal = true;
               breakout_buy_signal = false;
              }
           }
        }
   */
//   Print("Bar count on the 'EURUSD,H1' is ",iBars("EURUSD",PERIOD_H1));
//   Print("Bar count on the 'EURUSD,H4' is ",iBars("EURUSD",PERIOD_H4));
//   Print("Bar count on the 'EURUSD,D1' is ",iBars("EURUSD",PERIOD_D1));
//   Print("Bar count on the 'EURUSD,Period' is ",iBars("EURUSD",Period()));
   int window = 35;
//if lowestTime > HighestTime, we're in a downtrend
   lowest = iLowest(Symbol(),PERIOD_H4,MODE_LOW,window,0); //lowest of last 100 bars
   datetime lowestTime = iTime(Symbol(),PERIOD_H4,lowest);
   lowestPrice = iLow(Symbol(),PERIOD_H4,lowest);
   int lowestIndex = iBarShift(Symbol(),Period(),iTime(Symbol(),PERIOD_H4,lowest),true); //index in terms of main chart bars.

 drawText(lowestIndex,clrRed,"L");

   int highest = iHighest(Symbol(),PERIOD_H4,MODE_HIGH,window,0); //highest of last 100
   highestPrice = iHigh(Symbol(),PERIOD_H4,highest);
   datetime highestTime = iTime(Symbol(),PERIOD_H4,highest);
   int highestIndex = iBarShift(Symbol(),Period(),iTime(Symbol(),PERIOD_H4,highest),true); //index in terms of main chart bars.
   drawText(highestIndex,clrGreen,"H");

   prevLowest = iLowest(Symbol(),PERIOD_H4,MODE_LOW,window,MathMax(highest+1,lowest+1)); //lowest of last 100 bars starting from most recent high
   datetime prevLowestTime = iTime(Symbol(),PERIOD_H4,prevLowest);
   prevLowestPrice = iLow(Symbol(),PERIOD_H4,prevLowest);
   int prevLowestIndex = iBarShift(Symbol(),Period(),iTime(Symbol(),PERIOD_H4,prevLowest),true); //index in terms of main chart bars.

   prevHighest = iHighest(Symbol(),PERIOD_H4,MODE_HIGH,window,MathMax(lowest+1,highest+1)); //lowest of last 100 bars starting from most recent low
   datetime prevHighestTime = iTime(Symbol(),PERIOD_H4,prevHighest);
   prevHighestPrice = iHigh(Symbol(),PERIOD_H4,prevHighest);
   int prevHighestIndex = iBarShift(Symbol(),Period(),iTime(Symbol(),PERIOD_H4,prevHighest),true); //index in terms of main chart bars.

   if(lowest < highest)
     {
      //     Print("downtrend"); //t1 is lowest, t2 is highest
       drawZZ("zz1",lowestTime,lowestPrice,highestTime,highestPrice,clrBlack,5);
       drawZZ("zz2",highestTime,highestPrice,prevLowestTime,prevLowestPrice,clrBlue,5);
             drawZZ("zz3",prevLowestTime,prevLowestPrice,prevHighestTime,prevHighestPrice,clrBlack,5);
      // drawEW("ew",lowestTime,lowestPrice,highestTime,highestPrice,prevLowestTime,prevLowestPrice,clrRed,3);
      //      DrawAOIBox("mybox",prevHighestPrice,highestPrice,prevHighestTime,highestTime,clrBlue,true);
      //      Print("lowest"+TimeToString(lowestTime));
      //      Print("highest"+TimeToString(highestTime));
      //      Print("prevLowest"+TimeToString(prevLowestTime));
      //      Print("prevHighest"+TimeToString(prevHighestTime));
      //Price=L+(Retracement Level)×(H−L)
//      double FC1 = NormalizeDouble(lowestPrice+0.368*(highestPrice-lowestPrice), Digits());
//   double FC2 = NormalizeDouble(lowestPrice+0.790*(highestPrice-lowestPrice), Digits());
//   double FC3 = NormalizeDouble(lowestPrice+1.000*(highestPrice-lowestPrice), Digits());

//      drawPivots(lowestPrice,FC1,FC2,FC3,FC1,FC2,FC3);
     }
   else
     {
      //      Print("uptrend"); //t1 is highest, t2 is lowest
       drawZZ("zz1",highestTime,highestPrice,lowestTime,lowestPrice,clrBlue,5);
       drawZZ("zz2",lowestTime,lowestPrice,prevHighestTime,prevHighestPrice,clrBlack,5);
            drawZZ("zz3",prevHighestTime,prevHighestPrice,prevLowestTime,prevLowestPrice,clrBlue,5);
      // drawEW("ew",highestTime,highestPrice,lowestTime,lowestPrice,prevHighestTime,prevHighestPrice,clrGreen,3);
     //             DrawAOIBox("mybox",lowestPrice,prevHighestPrice,lowestTime,prevHighestTime,clrBlue,true);

            Print("lowest"+TimeToString(lowestTime));
            Print("highest"+TimeToString(highestTime));
            Print("prevLowest"+TimeToString(prevLowestTime));
            Print("prevHighest"+TimeToString(prevHighestTime));
            double FC1 = NormalizeDouble(prevLowestPrice+0*(highestPrice-prevLowestPrice), Digits()); //BOTTOM OF RYLBLUE BOX
   double FC2 = NormalizeDouble(prevLowestPrice+0.20*(highestPrice-prevLowestPrice), Digits()); 
   double FC3 = NormalizeDouble(prevLowestPrice+0.368*(highestPrice-prevLowestPrice), Digits()); //BOTTOM OF AOI
            double FC4 = NormalizeDouble(prevLowestPrice+0.50*(highestPrice-prevLowestPrice), Digits());
   double FC5 = NormalizeDouble(prevLowestPrice+0.790*(highestPrice-prevLowestPrice), Digits()); //TOP OF AOI
   double FC6 = NormalizeDouble(prevLowestPrice+1.000*(highestPrice-prevLowestPrice), Digits()); //TOP OF THE RYLBLUE BOX
      drawPivots(FC1,FC1,FC3,FC3,FC5,FC5,FC6);

     }
            Print("lowest"+TimeToString(lowestTime));
            Print("highest"+TimeToString(highestTime));
            Print("prevLowest"+TimeToString(prevLowestTime));
            Print("prevHighest"+TimeToString(prevHighestTime));



//drawZZ("zz2",prevLowestTime,prevLowestPrice,highestTime,highestPrice,clrBlack,5);
//drawZZ("zz3",prevHighestTime,prevHighestPrice,prevLowestTime,prevLowestPrice,clrBlack,5);
//ObjectCreate(0,wavename,OBJ_ELLIOTWAVE3,0,lowestTime,lowestPrice,highestTime,highestPrice,prevLowestTime,prevLowestPrice);
//--- set line color
   /*
   ObjectCreate(0,"downtrend"+TimeToString(lowestTime),OBJ_TREND,0,highestTime,highestPrice,lowestTime,lowestPrice);
    ObjectSetInteger(0,"downtrend"+TimeToString(lowestTime),OBJPROP_STYLE,STYLE_SOLID);
   //--- set line width
      ObjectSetInteger(0,"downtrend"+TimeToString(lowestTime),OBJPROP_WIDTH,5);
   //--- display in the foreground (false) or background (true)
      ObjectSetInteger(0,"downtrend"+TimeToString(lowestTime),OBJPROP_COLOR,clrBlack);
   */

//   if (lowest == 1) {
//      drawText(lowest,clrGreen,"LOWEST");
//trend = -1;
//}
//if (highest == 2) {
//      drawText(highest,clrRed,"HIGHEST");
//trend = 1;
//}
   /*
         if(lowest == 2) //latest candle is not ATL
           {
            if(!lowTested) //first touch
              {
               lowTestCount = 0;
               lowTested = true;
               highTested = false;
               if(counter % 2 == 0) counter++;
                if(counter == 1)
                    {
                  drawText(lowest,clrBlack,"first touch");
                    }
                if (counter == 3){
              drawText(lowest,clrBlack,"third touch");
                }
               if(counter > 4)
                 {
               drawText(lowest,clrRed,"LK SELL "+IntegerToString(counter)+"th touch");
                  last_kiss_sell =  true;
                 }
              }
            lowTestCount++;
            //      drawText(lowest,clrRed,IntegerToString(lowTestCount));
           }

         if(highest == 2) //latest candle is not ATH
           {
            if(!highTested) //first touch
              {
               highTestCount = 0;
               highTested = true;
               lowTested = false;
               if(counter % 2 == 1) counter++;
                 if (counter == 2) {
      //            drawText(highest,clrBlack,"second touch");
                 }
                 if (counter == 4) {
      //            drawText(highest,clrBlack,"fourth touch");
                 }
                  if(counter > 4)
                 {
      //            drawText(highest,clrBlue,"LK BUY "+IntegerToString(counter)+"th touch");
                  last_kiss_buy = true;
                 }
              }
            highTestCount++;
            //      drawText(highest,clrRed,IntegerToString(highTestCount));
           }


         buy_signal = (lowest == 2 && !last_kiss_sell);
         sell_signal = (highest == 2 && !last_kiss_buy);
         breakout_sell_signal = (lowest == 2 && last_kiss_sell);
         breakout_buy_signal = (highest == 2 && last_kiss_buy);
      */

//   DrawAOIBox("R1_H1_Resistance", R1_H1, R2_H1, iTime(Symbol(),Period(),0), iTime(Symbol(),Period(),100), clrRoyalBlue,true); // Blue AOI box for a resistance zone
//   DrawAOIBox("R1_H1_Support", S1_H1, S2_H1, iTime(Symbol(),Period(),0), iTime(Symbol(),Period(),100), clrAqua,true); // Aqua AOI box for a support zone

//   DrawAOIBox("R1_H1_Resistance", R1_H1-(PointsToDouble(100)), R1_H1+(PointsToDouble(100)), iTime(Symbol(),Period(),0), iTime(Symbol(),Period(),100), clrRed,true); // Blue AOI box for a resistance zone
//   DrawAOIBox("R1_H1_Support", S1_H1+(PointsToDouble(100)), S1_H1-(PointsToDouble(100)), iTime(Symbol(),Period(),0), iTime(Symbol(),Period(),100), clrGreen,true); // Aqua AOI box for a support zone
   /*
      if(S1_H1 > R1_H4 || S1_H1 > R1_D1)
        {
         bullBreakout = true;
         drawBreakout(1,clrGreen);
         bull_counter = 10;
        }
      if(R1_H1 < S1_H4 || R1_H1 < S1_D1)
        {
         bearBreakout = true;
         drawBreakout(1,clrRed);
         bear_counter = 10;
        }
        bull_counter--; bear_counter--; if (bull_counter < 0) { bull_counter = 0; bullBreakout = false; } if (bear_counter < 0) { bear_counter = 0; bearBreakout = false; }
     */
//+------------------------------------------------------------------+

//LAST KISS
   /*Wait for price to consolidate in a box between two zones.
    The box should have at least two touches on both zones.
    Wait for price to break beyond one of the zones.
    Once price returns back to the consolidation box, wait for the market
   to print a last-kiss candlestick on the edge of the box.
   For sell trades, a sell stop is placed below the low of the last-kiss candlestick, and for buy trades, a buy stop is placed above the high of the
   last-kiss candlestick.  Emergency stop loss is placed in the midpoint of the consolidation box.  The profit target is the nearest zone.
   */
//if (iClose(Symbol(),Period(),1) < FR1_H4-(PointsToDouble(100))&& iClose(Symbol(),Period(),2) > FS1_H4-(PointsToDouble(100))) drawBreakout(0,clrGreen);
//if (iClose(Symbol(),Period(),1) < S1_D1-(PointsToDouble(100))&& iClose(Symbol(),Period(),2) > S1_D1-(PointsToDouble(100))) drawBreakout(0,clrRed);
   /*
   test r
   test s
   test r
   test s

   test r -> buy_signal
   buystop next bull candle high

   test s -> sellstop
   */
//momentum
   /*
      if(breakout_buy_signal && strong_bull && c > FR1_H4)
        {
         drawText(1,clrBlue,"b");
         Trade.BuyStop(0.1,h,Symbol(),l-sl_gap,h+tp_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
         positionOpenSeconds = (long)TimeCurrent();
         return;
        }
      if(breakout_sell_signal && strong_bear && c < FS1_H4)
        {
         drawText(1,clrRed,"b");
         Trade.SellStop(0.1,l,Symbol(),h+sl_gap,l-tp_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
         positionOpenSeconds = (long)TimeCurrent();
         return;
        }
   //reversal
      if(!breakout_sell_signal && ask+tp_gap < BB.GetValue(1,1) && ask+tp_gap < PP_H1)
        {
         drawText(1,clrBlue,"r");
         Trade.BuyStop(0.1,ask,Symbol(),ask-sl_gap,ask+tp_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
         positionOpenSeconds = (long)TimeCurrent();
         return;
        }
      if(!breakout_buy_signal && bid-tp_gap > BB.GetValue(2,1) && ask+tp_gap > PP_H1)
        {
         drawText(1,clrRed,"r");
         Trade.SellStop(0.1,bid,Symbol(),bid+sl_gap,bid-tp_gap,ORDER_TIME_SPECIFIED,iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()));
         positionOpenSeconds = (long)TimeCurrent();
         return;
        }
   */

//Delete autotrade objects
   int object1_count = ObjectsTotal(0);
   int filter_count = ObjectsTotal(0,1);
   for(int i = 0; i < object1_count; i++)
     {
      string filter_string = "autotrade #";
      string object_name = ObjectName(0,i,0);
      if(StringFind(object_name,filter_string,0) > -1)
        {
         ObjectDelete(0,object_name);
        }
     }

   ShowHTFRangeLine("hi_H4",OBJ_HLINE,H_H4, Green, 2,PERIOD_H4);
   ShowHTFRangeLine("lo_H4",OBJ_HLINE,L_H4, Red, 2,PERIOD_H4);


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawZZ(string name,datetime t1, double p1,datetime t2, double p2, color c, int width)
  {
   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
//--- set line display style
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
//--- set line width
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawEW(string name,datetime t1, double p1,datetime t2, double p2, datetime t3, double p3, color c, int width)
  {
   ObjectCreate(0,name,OBJ_ELLIOTWAVE3,0,t1,p1,t2,p2,t3,p3);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
//--- set line display style
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
//--- set line width
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
  }
//+------------------------------------------------------------------+
void ShowRange(double hi, double lo, color hiclr, color loclr, int width)
  {
   ShowRangeLine("hi", OBJ_HLINE, hi, hiclr,width);
   ShowRangeLine("lo", OBJ_HLINE, lo, loclr,width);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowRangeLine(string name, ENUM_OBJECT type, double value, color rangeclr, int width)
  {
   ObjectDelete(0, name);
   ObjectCreate(0, name, type, 0, iTime(Symbol(), Period(), 1), value);
   ObjectSetInteger(0, name, OBJPROP_COLOR, rangeclr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowHTFRangeLine(string name, ENUM_OBJECT type, double value, color rangeclr, int width, ENUM_TIMEFRAMES tf)
  {
   name = name+EnumToString(tf);
   ObjectDelete(0, name);
   ObjectCreate(0, name, type, 0, iTime(Symbol(), tf, 1), value);
   ObjectSetInteger(0, name, OBJPROP_COLOR, rangeclr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PointsToDouble(int points, string symbol = "")
  {
   if(symbol == "")
      symbol = Symbol();
   double value = (double) points * SymbolInfoDouble(symbol, SYMBOL_POINT);
   return value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PipSize() { return (PipSize(Symbol())); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PipSize(string symbol)
  {
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return (((digits % 2) == 1) ? point * 10 : point);
  }
//https://github.com/OrchardForexTutorials/221008_retracement_breakout_expert/blob/main/Experts/Orchard/Reentrant%20Breakout/Reentrant%20Breakout.mqh
double PipsToDouble(double pips) { return (pips * PipSize(Symbol())); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PipsToDouble(double pips, string symbol) { return (pips * PipSize(symbol)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime previousBarTime = iTime(Symbol(), Period(), 0);
   datetime currentBarTime = iTime(Symbol(), Period(), 0);

   if(currentBarTime == previousBarTime)
      return false;
   previousBarTime = currentBarTime;
   return true;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ulong GetLastDealTicket()
  {
//--- request history for the last 7 days
   if(!GetTradeHistory(7))
     {
      //--- notify on unsuccessful call and return -1
      Print(__FUNCTION__, " HistorySelect() returned false");
      return -1;
     }
//---
   ulong first_deal, last_deal, deals = HistoryDealsTotal();
//--- work with orders if there are any
   if(deals > 0)
     {
      //        Print("Deals = ", deals);
      first_deal = HistoryDealGetTicket(0);
      if(deals > 1)
        {
         last_deal = HistoryDealGetTicket((int) deals - 1);
         //            PrintFormat("last_deal = %d", last_deal);
         return last_deal;
        }
      return first_deal;
     }
//--- no deal found, return -1
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetTradeHistory(int days)
  {
//--- set a week period to request trade history
   datetime to = TimeCurrent();
   datetime from = to - days * PeriodSeconds(PERIOD_D1);
   ResetLastError();
//--- make a request and check the result
   if(!HistorySelect(from, to))
     {
      Print(__FUNCTION__, " HistorySelect=false. Error code=", GetLastError());
      return false;
     }
//--- history received successfully
   return true;
  }
//+------------------------------------------------------------------+
string CheckVolumeFilter()
  {
   string volumeFilter="";
   double myPriceArray[];
   int VolumesDefinition = iVolumes(Symbol(),Period(),VOLUME_TICK);

   ArraySetAsSeries(myPriceArray,true);
   CopyBuffer(VolumesDefinition,0,0,3,myPriceArray);

   double CurrentVolumesValue = (myPriceArray[0]);
   double LastVolumesValue = (myPriceArray[1]);

   if(CurrentVolumesValue > LastVolumesValue)
     {
      volumeFilter = "positive";
     }
   if(CurrentVolumesValue < LastVolumesValue)
     {
      volumeFilter = "negative";
     }

   return volumeFilter;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawPivots(double pp,double s1,double s2,double s3,double r1,double r2,double r3)
  {

   ObjectDelete(0, "PPName");
   ObjectCreate(0, "PPName", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), pp);
   ObjectSetInteger(0, "PPName", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, "PPName", OBJPROP_STYLE, STYLE_DASH);

   ObjectSetInteger(0,"PPName",OBJPROP_WIDTH,2);

   ObjectDelete(0, "S1Name");
   ObjectCreate(0, "S1Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), s1);
   ObjectSetInteger(0, "S1Name", OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, "S1Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"S1Name",OBJPROP_WIDTH,2);

   ObjectDelete(0, "S2Name");
   ObjectCreate(0, "S2Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), s2);
   ObjectSetInteger(0, "S2Name", OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, "S2Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"S2Name",OBJPROP_WIDTH,2);

   ObjectDelete(0, "S3Name");
   ObjectCreate(0, "S3Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), s3);
   ObjectSetInteger(0, "S3Name", OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, "S3Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"S3Name",OBJPROP_WIDTH,2);

   ObjectDelete(0, "R1Name");
   ObjectCreate(0, "R1Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), r1);
   ObjectSetInteger(0, "R1Name", OBJPROP_COLOR, clrRoyalBlue);
   ObjectSetInteger(0, "R1Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"R1Name",OBJPROP_WIDTH,2);

   ObjectDelete(0, "R2Name");
   ObjectCreate(0, "R2Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), r2);
   ObjectSetInteger(0, "R2Name", OBJPROP_COLOR, clrRoyalBlue);
   ObjectSetInteger(0, "R2Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"R2Name",OBJPROP_WIDTH,2);

   ObjectDelete(0, "R3Name");
   ObjectCreate(0, "R3Name", OBJ_HLINE, 0, iTime(Symbol(), Period(), 1), r3);
   ObjectSetInteger(0, "R3Name", OBJPROP_COLOR, clrRoyalBlue);
   ObjectSetInteger(0, "R3Name", OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0,"R3Name",OBJPROP_WIDTH,2);
  }
//+------------------------------------------------------------------+
void DrawAOIBox(string name, double lower_price, double upper_price, datetime start_time, datetime end_time, color box_color,bool fill)
  {
   string timestring = TimeToString(start_time);
   if(!ObjectCreate(0, name+timestring, OBJ_RECTANGLE, 0, start_time, lower_price, end_time, upper_price))
     {
      Print("Error creating AOI BOX: ", GetLastError());
      return;
     };
// }
   ObjectSetInteger(0, name+timestring, OBJPROP_COLOR, box_color);
   ObjectSetInteger(0, name+timestring, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name+timestring, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name+timestring, OBJPROP_FILL, fill);
   ObjectSetInteger(0, name+timestring, OBJPROP_BACK, true);
  }
//EXAMPLE USAGE:
/*
DrawAOIBox("AOI_Supply", 1.2000, 1.2050, Time[50], Time[0], clrRed); // A red AOI box for a supply zone
DrawAOIBox("AOI_Demand", 1.1800, 1.1850, Time[50], Time[0], clrGreen); // A green AOI box for a demand zone
*/
bool WaitForHTF(string symbol, ENUM_TIMEFRAMES timeframe)
  {
   for(int waitCount = 1000; waitCount >= 0; waitCount--)
     {
      Print("Wait count: "+IntegerToString(waitCount));
      datetime t = iTime(symbol, timeframe,0);
      int err = GetLastError();
      if(t > 0)
         return (true);
      Sleep(100);
     }
   return false;
  }

//+------------------------------------------------------------------+
void drawText(int candleIndex, color clr, string text)
  {
   datetime textTime = iTime(Symbol(), Period(), candleIndex);
   double location = iHigh(Symbol(),Period(),candleIndex);
   ObjectCreate(0, text + TimeToString(textTime), OBJ_TEXT, 0, textTime, location);
   ObjectSetString(0,text + TimeToString(textTime),OBJPROP_TEXT,text);
   ObjectSetString(0,text + TimeToString(textTime),OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,text + TimeToString(textTime),OBJPROP_FONTSIZE,16);
   ObjectSetDouble(0,text + TimeToString(textTime),OBJPROP_ANGLE,90.0);
   ObjectSetInteger(0,text + TimeToString(textTime),OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(0, text + TimeToString(textTime), OBJPROP_COLOR, clr);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Function to calculate ZigZag                                     |
//+------------------------------------------------------------------+
void CalculateZigZag(double &prices[], double percentage, double &zigzag[], double &swingHighs[], double &swingLows[])
  {
   int size = ArraySize(prices);
   ArrayResize(zigzag, size);
   ArrayResize(swingHighs, size);
   ArrayResize(swingLows, size);
   ArrayInitialize(zigzag, 0);
   ArrayInitialize(swingHighs, 0);
   ArrayInitialize(swingLows, 0);

   double changeThreshold = percentage / 100.0;
   int trend = 0; // 0: none, 1: up, -1: down
   int lastExtremeIdx = 0;
   double lastExtremePrice = prices[0];

   for(int i = 1; i < size; i++)
     {
      double currentPrice = prices[i];
      double priceChange = (currentPrice - lastExtremePrice) / lastExtremePrice;

      if(trend == 0)
        {
         // Determine the initial trend direction
         if(MathAbs(priceChange) > changeThreshold)
           {
            trend = (priceChange > 0) ? 1 : -1;
            zigzag[i] = currentPrice;
            lastExtremeIdx = i;
            lastExtremePrice = currentPrice;
           }
        }
      else
        {
         if(trend == 1)
           {
            if(currentPrice > lastExtremePrice)
              {
               // Update the last extreme point
               zigzag[i] = currentPrice;
               lastExtremeIdx = i;
               lastExtremePrice = currentPrice;
              }
            else
               if(priceChange < -changeThreshold)
                 {
                  // Trend reversal to down
                  trend = -1;
                  swingHighs[lastExtremeIdx] = lastExtremePrice;
                  zigzag[i] = currentPrice;
                  lastExtremeIdx = i;
                  lastExtremePrice = currentPrice;
                 }
           }
         else
            if(trend == -1)
              {
               if(currentPrice < lastExtremePrice)
                 {
                  // Update the last extreme point
                  zigzag[i] = currentPrice;
                  lastExtremeIdx = i;
                  lastExtremePrice = currentPrice;
                 }
               else
                  if(priceChange > changeThreshold)
                    {
                     // Trend reversal to up
                     trend = 1;
                     swingLows[lastExtremeIdx] = lastExtremePrice;
                     zigzag[i] = currentPrice;
                     lastExtremeIdx = i;
                     lastExtremePrice = currentPrice;
                    }
              }
        }
     }

// Set the last extreme point as the final swing high or low
   if(trend == 1)
      swingHighs[lastExtremeIdx] = lastExtremePrice;
   else
      if(trend == -1)
         swingLows[lastExtremeIdx] = lastExtremePrice;
  }


//+------------------------------------------------------------------+
