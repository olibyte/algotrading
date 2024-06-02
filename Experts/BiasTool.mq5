//+------------------------------------------------------------------+
//|                                                     BiasTool.mq5 |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#include <Trade/Trade.mqh>

//#define HTF
//#define LTF
//#define multicurrency
int bbHandle,macdHandle,rsiHandle;
double bbu[],bbl[],bbm[],macdVals[],signalVals[],rsiVals[];

int bbHandlem5,macdHandlem5,rsiHandlem5;
double bbum5[],bblm5[],bbmm5[],macdValsm5[],signalValsm5[],rsiValsm5[];

int bbHandlem15,macdHandlem15,rsiHandlem15;
double bbum15[],bblm15[],bbmm15[],macdValsm15[],signalValsm15[],rsiValsm15[];

int bbHandleh1,macdHandleh1,rsiHandleh1;
double bbuh1[],bblh1[],bbmh1[],macdValsh1[],signalValsh1[],rsiValsh1[];

int bbHandleh4,macdHandleh4,rsiHandleh4;
double bbuh4[],bblh4[],bbmh4[],macdValsh4[],signalValsh4[],rsiValsh4[];

int bbHandled1,macdHandled1,rsiHandled1;
double bbud1[],bbld1[],bbmd1[],macdValsd1[],signalValsd1[],rsiValsd1[];

int bbHandleAUDNZD, macdHandleAUDNZD, rsiHandleAUDNZD;
double bbuAUDNZD[],bblAUDNZD[],bbmAUDNZD[],macdValsAUDNZD[],signalValsAUDNZD[],rsiValsAUDNZD[];

int bbHandleAUDNZDh1,macdHandleAUDNZDh1,rsiHandleAUDNZDh1;
double bbuAUDNZDh1[],bblAUDNZDh1[],bbmAUDNZDh1[],macdValsAUDNZDh1[],signalValsAUDNZDh1[],rsiValsAUDNZDh1[];

int bbHandleAUDNZDh4,macdHandleAUDNZDh4,rsiHandleAUDNZDh4;
double bbuAUDNZDh4[],bblAUDNZDh4[],bbmAUDNZDh4[],macdValsAUDNZDh4[],signalValsAUDNZDh4[],rsiValsAUDNZDh4[];

int bbHandleAUDNZDd1,macdHandleAUDNZDd1,rsiHandleAUDNZDd1;
double bbuAUDNZDd1[],bblAUDNZDd1[],bbmAUDNZDd1[],macdValsAUDNZDd1[],signalValsAUDNZDd1[],rsiValsAUDNZDd1[];


CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   bbHandle = iBands(Symbol(), Period(), 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbu,true);
   ArraySetAsSeries(bbl,true);
   ArraySetAsSeries(bbm, true);
   macdHandle = iMACD(Symbol(),Period(),8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdVals,true);
   ArraySetAsSeries(signalVals,true);
   rsiHandle = iRSI(Symbol(),Period(),14,PRICE_CLOSE);
   ArraySetAsSeries(rsiVals,true);

#ifdef multicurrency
   bbHandleAUDNZD = iBands("AUDNZD", Period(), 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuAUDNZD, true);
   ArraySetAsSeries(bblAUDNZD, true);
   ArraySetAsSeries(bbmAUDNZD, true);
   macdHandleAUDNZD = iMACD("AUDNZD", Period(), 8, 21, 5, PRICE_CLOSE);
   ArraySetAsSeries(macdValsAUDNZD, true);
   ArraySetAsSeries(signalValsAUDNZD, true);
   rsiHandleAUDNZD = iRSI("AUDNZD", Period(), 14, PRICE_CLOSE);
   ArraySetAsSeries(rsiValsAUDNZD, true);
#endif
#ifdef LTF
   bbHandlem5 = iBands(Symbol(), PERIOD_M5, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbum5,true);
   ArraySetAsSeries(bblm5,true);
   ArraySetAsSeries(bbmm5, true);
   macdHandlem5 = iMACD(Symbol(),PERIOD_M5,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsm5,true);
   ArraySetAsSeries(signalValsm5,true);
   rsiHandlem5 = iRSI(Symbol(),PERIOD_M5,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsm5,true);

   bbHandlem15 = iBands(Symbol(), PERIOD_M15, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbum15,true);
   ArraySetAsSeries(bblm15,true);
   ArraySetAsSeries(bbmm15, true);
   macdHandlem15 = iMACD(Symbol(),PERIOD_M15,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsm15,true);
   ArraySetAsSeries(signalValsm15,true);
   rsiHandlem15 = iRSI(Symbol(),PERIOD_M15,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsm15,true);
#endif

#ifdef HTF
   bbHandleh1 = iBands(Symbol(), PERIOD_H1, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuh1,true);
   ArraySetAsSeries(bblh1,true);
   ArraySetAsSeries(bbmh1, true);
   macdHandleh1 = iMACD(Symbol(),PERIOD_H1,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsh1,true);
   ArraySetAsSeries(signalValsh1,true);
   rsiHandleh1 = iRSI(Symbol(),PERIOD_H1,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsh1,true);

   bbHandleh4 = iBands(Symbol(), PERIOD_H4, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuh4,true);
   ArraySetAsSeries(bblh4,true);
   ArraySetAsSeries(bbmh4, true);
   macdHandleh4 = iMACD(Symbol(),PERIOD_H4,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsh4,true);
   ArraySetAsSeries(signalValsh1,true);
   rsiHandleh4 = iRSI(Symbol(),PERIOD_H4,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsh4,true);

   bbHandled1 = iBands(Symbol(), PERIOD_D1, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbud1,true);
   ArraySetAsSeries(bbld1,true);
   ArraySetAsSeries(bbmd1, true);
   macdHandled1 = iMACD(Symbol(),PERIOD_D1,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsd1,true);
   ArraySetAsSeries(signalValsd1,true);
   rsiHandled1 = iRSI(Symbol(),PERIOD_D1,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsd1,true);
//AUDNZD
   bbHandleAUDNZDh1 = iBands("AUDNZD", PERIOD_H1, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuAUDNZDh1,true);
   ArraySetAsSeries(bblAUDNZDh1,true);
   ArraySetAsSeries(bbmAUDNZDh1, true);
   macdHandleAUDNZDh1 = iMACD("AUDNZD",PERIOD_H1,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsAUDNZDh1,true);
   ArraySetAsSeries(signalValsAUDNZDh1,true);
   rsiHandleAUDNZDh1 = iRSI("AUDNZD",PERIOD_H1,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsAUDNZDh1,true);

   bbHandleAUDNZDh4 = iBands("AUDNZD", PERIOD_H4, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuAUDNZDh4,true);
   ArraySetAsSeries(bblAUDNZDh4,true);
   ArraySetAsSeries(bbmAUDNZDh4, true);
   macdHandleAUDNZDh4 = iMACD("AUDNZD",PERIOD_H4,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsAUDNZDh4,true);
   ArraySetAsSeries(signalValsAUDNZDh1,true);
   rsiHandleAUDNZDh4 = iRSI("AUDNZD",PERIOD_H4,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsAUDNZDh4,true);

   bbHandleAUDNZDd1 = iBands("AUDNZD", PERIOD_D1, 20, 0, 2.0, PRICE_CLOSE);
   ArraySetAsSeries(bbuAUDNZDd1,true);
   ArraySetAsSeries(bblAUDNZDd1,true);
   ArraySetAsSeries(bbmAUDNZDd1, true);
   macdHandleAUDNZDd1 = iMACD("AUDNZD",PERIOD_D1,8,21,5,PRICE_CLOSE);
   ArraySetAsSeries(macdValsAUDNZDd1,true);
   ArraySetAsSeries(signalValsAUDNZDd1,true);
   rsiHandleAUDNZDd1 = iRSI("AUDNZD",PERIOD_D1,14,PRICE_CLOSE);
   ArraySetAsSeries(rsiValsAUDNZDd1,true);
#endif
//---
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
//---
   if(!IsNewBar())
      return;

   int numCandles = 21;

   if(CopyBuffer(bbHandle, UPPER_BAND, 0, numCandles, bbu) < numCandles)
      return;
   if(CopyBuffer(bbHandle, LOWER_BAND, 0, numCandles, bbl) < numCandles)
      return;
   if(CopyBuffer(bbHandle, BASE_LINE, 0, numCandles, bbm) < numCandles)
      return;
   if(CopyBuffer(macdHandle,0,0,numCandles,macdVals) < 8)
      return;
   if(CopyBuffer(macdHandle,1,0,numCandles,signalVals) < numCandles)
      return;
   if(CopyBuffer(rsiHandle,0,0,numCandles,rsiVals) < 14)
      return;
#ifdef multicurrency
   if(CopyBuffer(bbHandleAUDNZD, UPPER_BAND, 0, numCandles, bbuAUDNZD) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZD, LOWER_BAND, 0, numCandles, bblAUDNZD) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZD, BASE_LINE, 0, numCandles, bbmAUDNZD) < numCandles)
      return;
   if(CopyBuffer(macdHandleAUDNZD, 0, 0, numCandles, macdValsAUDNZD) < 8)
      return;
   if(CopyBuffer(macdHandleAUDNZD, 1, 0, numCandles, signalValsAUDNZD) < numCandles)
      return;
   if(CopyBuffer(rsiHandleAUDNZD, 0, 0, numCandles, rsiValsAUDNZD) < 14)
      return;
#endif

#ifdef LTF
   if(CopyBuffer(bbHandlem5, UPPER_BAND, 0, numCandles, bbum5) < numCandles)
      return;
   if(CopyBuffer(bbHandlem5, LOWER_BAND, 0, numCandles, bblm5) < numCandles)
      return;
   if(CopyBuffer(bbHandlem5, BASE_LINE, 0, numCandles, bbmm5) < numCandles)
      return;
   if(CopyBuffer(macdHandlem5,0,0,numCandles,macdValsm5) < 8)
      return;
   if(CopyBuffer(macdHandlem5,1,0,numCandles,signalValsm5) < numCandles)
      return;
   if(CopyBuffer(rsiHandlem5,0,0,numCandles,rsiValsm5) < 14)
      return;

   if(CopyBuffer(bbHandlem15, UPPER_BAND, 0, numCandles, bbum15) < numCandles)
      return;
   if(CopyBuffer(bbHandlem15, LOWER_BAND, 0, numCandles, bblm15) < numCandles)
      return;
   if(CopyBuffer(bbHandlem15, BASE_LINE, 0, numCandles, bbmm15) < numCandles)
      return;
   if(CopyBuffer(macdHandlem15,0,0,numCandles,macdValsm15) < 8)
      return;
   if(CopyBuffer(macdHandlem15,1,0,numCandles,signalValsm15) < numCandles)
      return;
   if(CopyBuffer(rsiHandlem15,0,0,numCandles,rsiValsm15) < 14)
      return;
#endif

#ifdef HTF
   if(CopyBuffer(bbHandleh1, UPPER_BAND, 0, numCandles, bbuh1) < numCandles)
      return;
   if(CopyBuffer(bbHandleh1, LOWER_BAND, 0, numCandles, bblh1) < numCandles)
      return;
   if(CopyBuffer(bbHandleh1, BASE_LINE, 0, numCandles, bbmh1) < numCandles)
      return;
   if(CopyBuffer(macdHandleh1,0,0,numCandles,macdValsh1) < 8)
      return;
   if(CopyBuffer(macdHandleh1,1,0,numCandles,signalValsh1) < numCandles)
      return;
   if(CopyBuffer(rsiHandleh1,0,0,numCandles,rsiValsh1) < 14)
      return;

   if(CopyBuffer(bbHandleh4, UPPER_BAND, 0, numCandles, bbuh4) < numCandles)
      return;
   if(CopyBuffer(bbHandleh4, LOWER_BAND, 0, numCandles, bblh4) < numCandles)
      return;
   if(CopyBuffer(bbHandleh4, BASE_LINE, 0, numCandles, bbmh4) < numCandles)
      return;
   if(CopyBuffer(macdHandleh4,0,0,numCandles,macdValsh4) < 8)
      return;
   if(CopyBuffer(macdHandleh4,1,0,numCandles,signalValsh4) < numCandles)
      return;
   if(CopyBuffer(rsiHandleh4,0,0,numCandles,rsiValsh4) < 14)
      return;

   if(CopyBuffer(bbHandled1, UPPER_BAND, 0, numCandles, bbud1) < numCandles)
      return;
   if(CopyBuffer(bbHandled1, LOWER_BAND, 0, numCandles, bbld1) < numCandles)
      return;
   if(CopyBuffer(bbHandled1, BASE_LINE, 0, numCandles, bbmd1) < numCandles)
      return;
   if(CopyBuffer(macdHandled1,0,0,numCandles,macdValsd1) < 8)
      return;
   if(CopyBuffer(macdHandled1,1,0,numCandles,signalValsd1) < numCandles)
      return;
   if(CopyBuffer(rsiHandled1,0,0,numCandles,rsiValsd1) < 14)
      return;
   double dailyClose = NormalizeDouble(iClose(Symbol(),PERIOD_D1,1),Digits());
   double dailyOpen = NormalizeDouble(iOpen(Symbol(),PERIOD_D1,1),Digits());
//AUDNZD
   if(CopyBuffer(bbHandleAUDNZDh1, UPPER_BAND, 0, numCandles, bbuAUDNZDh1) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDh1, LOWER_BAND, 0, numCandles, bblAUDNZDh1) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDh1, BASE_LINE, 0, numCandles, bbmAUDNZDh1) < numCandles)
      return;
   if(CopyBuffer(macdHandleAUDNZDh1,0,0,numCandles,macdValsAUDNZDh1) < 8)
      return;
   if(CopyBuffer(macdHandleAUDNZDh1,1,0,numCandles,signalValsAUDNZDh1) < numCandles)
      return;
   if(CopyBuffer(rsiHandleAUDNZDh1,0,0,numCandles,rsiValsAUDNZDh1) < 14)
      return;

   if(CopyBuffer(bbHandleAUDNZDh4, UPPER_BAND, 0, numCandles, bbuAUDNZDh4) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDh4, LOWER_BAND, 0, numCandles, bblAUDNZDh4) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDh4, BASE_LINE, 0, numCandles, bbmAUDNZDh4) < numCandles)
      return;
   if(CopyBuffer(macdHandleAUDNZDh4,0,0,numCandles,macdValsAUDNZDh4) < 8)
      return;
   if(CopyBuffer(macdHandleAUDNZDh4,1,0,numCandles,signalValsAUDNZDh4) < numCandles)
      return;
   if(CopyBuffer(rsiHandleAUDNZDh4,0,0,numCandles,rsiValsAUDNZDh4) < 14)
      return;

   if(CopyBuffer(bbHandleAUDNZDd1, UPPER_BAND, 0, numCandles, bbuAUDNZDd1) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDd1, LOWER_BAND, 0, numCandles, bblAUDNZDd1) < numCandles)
      return;
   if(CopyBuffer(bbHandleAUDNZDd1, BASE_LINE, 0, numCandles, bbmAUDNZDd1) < numCandles)
      return;
   if(CopyBuffer(macdHandleAUDNZDd1,0,0,numCandles,macdValsAUDNZDd1) < 8)
      return;
   if(CopyBuffer(macdHandleAUDNZDd1,1,0,numCandles,signalValsAUDNZDd1) < numCandles)
      return;
   if(CopyBuffer(rsiHandleAUDNZDd1,0,0,numCandles,rsiValsAUDNZDd1) < 14)
      return;
   double dailyAUDNZDClose = NormalizeDouble(iClose("AUDNZD",PERIOD_D1,1),Digits());
   double dailyAUDNZDOpen = NormalizeDouble(iOpen("AUDNZD",PERIOD_D1,1),Digits());
#endif

   double sl = PointsToDouble(50);
   double tp = PointsToDouble(100);
   datetime expiration =      iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());

   double close = NormalizeDouble(iClose(Symbol(),Period(),1),Digits());
   double low = NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
   double high = NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits()); //long
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits()); //short

   int scorem5 = 0, scorem15 = 0, scoreh1= 0, scoreh4 = 0, scored1 = 0;
   int score = CalculateScore(macdVals, signalVals, bbu, bbl, rsiVals, close);

#ifdef multicurrency
   double closeAUDNZD = NormalizeDouble(iClose("AUDNZD", Period(), 1), Digits());
   double lowAUDNZD = NormalizeDouble(iLow("AUDNZD", Period(), 1), Digits());
   double highAUDNZD = NormalizeDouble(iHigh("AUDNZD", Period(), 1), Digits());
   double askAUDNZD = NormalizeDouble(SymbolInfoDouble("AUDNZD", SYMBOL_ASK), Digits()); //long
   double bidAUDNZD = NormalizeDouble(SymbolInfoDouble("AUDNZD", SYMBOL_BID), Digits()); //short
   int scoreAUDNZDm5 = 0, scoreAUDNZDm15 = 0, scoreAUDNZDh1= 0, scoreAUDNZDh4 = 0, scoreAUDNZDd1 = 0;
   int scoreAUDNZD = CalculateScore(macdValsAUDNZD, signalValsAUDNZD, bbuAUDNZD, bblAUDNZD, rsiValsAUDNZD, NormalizeDouble(iClose("AUDNZD", Period(), 1), Digits()));
#endif
   /*
      int m = 0, b = 0, r = 0;
      if (macdVals[0] < signalVals[0]) {m = -1;}
      else if (macdVals[0] > signalVals[0]) {m = 1;}

      if (close > bbu[1]) {b = -1;}
      else if (close < bbl[1]) {b = 1;}

      if (rsiVals[0] >= 70) {r = -1;}
      else if (rsiVals[0] <= 30) {r = 1;}

      if (m == -1) {
         if (r == 1 && b == 1) {score = 1;}
         else if (r == -1 || b == -1) {score = -1;}
      }
      if (m == 1) {
         if (r == -1 && b == -1) {score = -1;}
         else if (r == 1 || b == 1) {score = 1;}
      }
      Print("macd: "+macdVals[0]+" bbu: "+bbu[1]+" bbl: "+bbl[1]+" r: "+rsiVals[0]);
      Print("m: "+m+" b: "+b+" r: "+r);
      */
#ifdef LTF
//M5
   int mm5 = 0, bm5 = 0, rm5 = 0;
   if(macdValsm5[0] < signalValsm5[0])
      mm5 = -1;
   else
      if(macdValsm5[0] > signalValsm5[0])
         mm5 = 1;

   if(close > bbmm5[0])
      bm5 = -1;
   else
      if(close < bbmm5[0])
         bm5 = 1;

   if(rsiValsm5[0] >= 70)
      rm5 = -1;
   else
      if(rsiValsm5[0] <= 30)
         rm5 = 1;

   if(mm5 == -1)
     {
      if(rm5 == 1 && bm5 == 1)
         scorem5 = 1;
      else
         if(rm5 == -1 || bm5 == -1)
            scorem5 = -1;
     }
   if(mm5 == 1)
     {
      if(rm5 == -1 && bm5 == -1)
         scorem5 = -1;
      else
         if(rm5 == 1 || bm5 == 1)
            scorem5 = 1;
     }

//M15
   int mm15 = 0, bm15 = 0, rm15 = 0;
   if(macdValsm15[0] < signalValsm15[0])
      mm15 = -1;
   else
      if(macdValsm15[0] > signalValsm15[0])
         mm15 = 1;

   if(close > bbmm15[0])
      bm15 = -1;
   else
      if(close < bbmm15[0])
         bm15 = 1;

   if(rsiValsm15[0] >= 70)
      rm15 = -1;
   else
      if(rsiValsm15[0] <= 30)
         rm15 = 1;

   if(mm15 == -1)
     {
      if(rm15 == 1 && bm15 == 1)
         scorem15 = 1;
      else
         if(rm15 == -1 || bm15 == -1)
            scorem15 = -1;
     }
   if(mm15 == 1)
     {
      if(rm15 == -1 && bm15 == -1)
         scorem15 = -1;
      else
         if(rm15 == 1 || bm15 == 1)
            scorem15 = 1;
     }
#endif

#ifdef HTF
//H1
   int mh1 = 0, bh1 = 0, rh1 = 0;

   double highh1 = NormalizeDouble(iHigh(Symbol(),PERIOD_H1,1),Digits());
   double lowh1 = NormalizeDouble(iLow(Symbol(),PERIOD_H1,1),Digits());
   double closeh1 = NormalizeDouble(iClose(Symbol(),PERIOD_H1,1),Digits());
   double openh1 = NormalizeDouble(iOpen(Symbol(),PERIOD_H1,1),Digits());

   if(macdValsh1[0] < signalValsh1[0])
     {
      mh1 = -1;
     }
   else
      if(macdValsh1[0] > signalValsh1[0])
        {
         mh1 = 1;
        }

   if(closeh1 > bbmh1[1])
     {
      bh1 = -1;
     }
   else
      if(closeh1 < bbmh1[1])
        {
         bh1 = 1;
        }

   if(rsiValsh1[0] >= 70)
     {
      rh1 = -1;
     }
   else
      if(rsiValsh1[0] <= 30)
        {
         rh1 = 1;
        }

   if(mh1 == -1)
     {
      if(rh1 == 1 && bh1 == 1)
        {
         scoreh1 = 1;
        }
      else
         if(rh1 == -1 || bh1 == -1)
           {
            scoreh1 = -1;
           }
     }
   if(mh1 == 1)
     {
      if(rh1 == -1 && bh1 == -1)
         scoreh1 = -1;
      else
         if(rh1 == 1 || bh1 == 1)
            scoreh1 = 1;
     }
//H4
   int mh4 = 0, bh4 = 0, rh4 = 0;

   double highh4 = NormalizeDouble(iHigh(Symbol(),PERIOD_H4,1),Digits());
   double lowh4 = NormalizeDouble(iLow(Symbol(),PERIOD_H4,1),Digits());
   double closeh4 = NormalizeDouble(iClose(Symbol(),PERIOD_H4,1),Digits());
   double openh4 = NormalizeDouble(iOpen(Symbol(),PERIOD_H4,1),Digits());

   if(macdValsh4[0] < signalValsh4[0])
      mh4 = -1;
   else
      if(macdValsh4[0] > signalValsh4[0])
         mh4 = 1;

   if(closeh4 > bbmh4[1])
      bh4 = -1;
   else
      if(closeh4 < bbmh4[1])
         bh4 = 1;

   if(rsiValsh4[0] >= 70)
      rh4 = -1;
   else
      if(rsiValsh4[0] <= 30)
         rh4 = 1;

   if(mh4 == -1)
     {
      if(rh4 == 1 && bh4 == 1)
         scoreh4 = 1;
      else
         if(rh4 == -1 || bh4 == -1)
            scoreh4 = -1;
     }
   if(mh4 == 1)
     {
      if(rh4 == -1 && bh4 == -1)
         scoreh4 = -1;
      else
         if(rh4 == 1 || bh4 == 1)
            scoreh4 = 1;
     }

//d1
   int md1 = 0, bd1 = 0, rd1 = 0;

   if(macdValsd1[0] < signalValsd1[0])
      md1 = -1;
   else
      if(macdValsd1[0] > signalValsd1[0])
         md1 = 1;

   if(close > bbmd1[1])
      bd1 = -1;
   else
      if(close < bbmd1[1])
         bd1 = 1;

   if(rsiValsd1[0] >= 70)
      rd1 = -1;
   else
      if(rsiValsd1[0] <= 30)
         rd1 = 1;

   if(md1 == -1)
     {
      if(rd1 == 1 && bd1 == 1)
         scored1 = 1;
      else
         if(rd1 == -1 || bd1 == -1)
            scored1 = -1;
     }
   if(md1 == 1)
     {
      if(rd1 == -1 && bd1 == -1)
         scored1 = -1;
      else
         if(rd1 == 1 || bd1 == 1)
            scored1 = 1;
     }
#endif

#ifdef multicurrency
//AUDNZD HTF
//H1
   int mAUDNZDh1 = 0, bAUDNZDh1 = 0, rAUDNZDh1 = 0;

   double highAUDNZDh1 = NormalizeDouble(iHigh("AUDNZD",PERIOD_H1,1),Digits());
   double lowAUDNZDh1 = NormalizeDouble(iLow("AUDNZD",PERIOD_H1,1),Digits());
   double closeAUDNZDh1 = NormalizeDouble(iClose("AUDNZD",PERIOD_H1,1),Digits());
   double openAUDNZDh1 = NormalizeDouble(iOpen("AUDNZD",PERIOD_H1,1),Digits());

   if(macdValsAUDNZDh1[0] < signalValsAUDNZDh1[0])
     {
      mAUDNZDh1 = -1;
     }
   else
      if(macdValsAUDNZDh1[0] > signalValsAUDNZDh1[0])
        {
         mAUDNZDh1 = 1;
        }

   if(closeAUDNZDh1 > bbmAUDNZDh1[1])
     {
      bAUDNZDh1 = -1;
     }
   else
      if(closeAUDNZDh1 < bbmAUDNZDh1[1])
        {
         bAUDNZDh1 = 1;
        }

   if(rsiValsAUDNZDh1[0] >= 70)
     {
      rAUDNZDh1 = -1;
     }
   else
      if(rsiValsAUDNZDh1[0] <= 30)
        {
         rAUDNZDh1 = 1;
        }

   if(mAUDNZDh1 == -1)
     {
      if(rAUDNZDh1 == 1 && bAUDNZDh1 == 1)
        {
         scoreAUDNZDh1 = 1;
        }
      else
         if(rAUDNZDh1 == -1 || bAUDNZDh1 == -1)
           {
            scoreAUDNZDh1 = -1;
           }
     }
   if(mAUDNZDh1 == 1)
     {
      if(rAUDNZDh1 == -1 && bAUDNZDh1 == -1)
         scoreAUDNZDh1 = -1;
      else
         if(rAUDNZDh1 == 1 || bAUDNZDh1 == 1)
            scoreAUDNZDh1 = 1;
     }
//H4
   int mAUDNZDh4 = 0, bAUDNZDh4 = 0, rAUDNZDh4 = 0;

   double highAUDNZDh4 = NormalizeDouble(iHigh("AUDNZD",PERIOD_H4,1),Digits());
   double lowAUDNZDh4 = NormalizeDouble(iLow("AUDNZD",PERIOD_H4,1),Digits());
   double closeAUDNZDh4 = NormalizeDouble(iClose("AUDNZD",PERIOD_H4,1),Digits());
   double openAUDNZDh4 = NormalizeDouble(iOpen("AUDNZD",PERIOD_H4,1),Digits());

   if(macdValsAUDNZDh4[0] < signalValsAUDNZDh4[0])
      mAUDNZDh4 = -1;
   else
      if(macdValsAUDNZDh4[0] > signalValsAUDNZDh4[0])
         mAUDNZDh4 = 1;

   if(closeAUDNZDh4 > bbmAUDNZDh4[1])
      bAUDNZDh4 = -1;
   else
      if(closeAUDNZDh4 < bbmAUDNZDh4[1])
         bAUDNZDh4 = 1;

   if(rsiValsAUDNZDh4[0] >= 70)
      rAUDNZDh4 = -1;
   else
      if(rsiValsAUDNZDh4[0] <= 30)
         rAUDNZDh4 = 1;

   if(mAUDNZDh4 == -1)
     {
      if(rAUDNZDh4 == 1 && bAUDNZDh4 == 1)
         scoreAUDNZDh4 = 1;
      else
         if(rAUDNZDh4 == -1 || bAUDNZDh4 == -1)
            scoreAUDNZDh4 = -1;
     }
   if(mAUDNZDh4 == 1)
     {
      if(rAUDNZDh4 == -1 && bAUDNZDh4 == -1)
         scoreAUDNZDh4 = -1;
      else
         if(rAUDNZDh4 == 1 || bAUDNZDh4 == 1)
            scoreAUDNZDh4 = 1;
     }

//d1
   int mAUDNZDd1 = 0, bAUDNZDd1 = 0, rAUDNZDd1 = 0;

   if(macdValsAUDNZDd1[0] < signalValsAUDNZDd1[0])
      mAUDNZDd1 = -1;
   else
      if(macdValsAUDNZDd1[0] > signalValsAUDNZDd1[0])
         mAUDNZDd1 = 1;

   if(closeAUDNZD > bbmAUDNZDd1[1])
      bAUDNZDd1 = -1;
   else
      if(closeAUDNZD < bbmAUDNZDd1[1])
         bAUDNZDd1 = 1;

   if(rsiValsAUDNZDd1[0] >= 70)
      rAUDNZDd1 = -1;
   else
      if(rsiValsAUDNZDd1[0] <= 30)
         rAUDNZDd1 = 1;

   if(mAUDNZDd1 == -1)
     {
      if(rAUDNZDd1 == 1 && bAUDNZDd1 == 1)
         scoreAUDNZDd1 = 1;
      else
         if(rAUDNZDd1 == -1 || bAUDNZDd1 == -1)
            scoreAUDNZDd1 = -1;
     }
   if(mAUDNZDd1 == 1)
     {
      if(rAUDNZDd1 == -1 && bAUDNZDd1 == -1)
         scoreAUDNZDd1 = -1;
      else
         if(rAUDNZDd1 == 1 || bAUDNZDd1 == 1)
            scoreAUDNZDd1 = 1;
     }
#endif


//Print("score: "+score);
   if(score == 1)
     {
      double price = NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
      Trade.BuyStop(0.1,high,Symbol(),high-sl,high+tp,ORDER_TIME_SPECIFIED,expiration);
     }
   if(score == -1)
     {
      double price = NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
      Trade.SellStop(0.1,low,Symbol(),low+sl,low-tp,ORDER_TIME_SPECIFIED,expiration);
     }

#ifdef multicurrency
   if(scoreAUDNZD == 1)
     {
      if(GetOpenPositionCount("AUDNZD") > 0)
         return;

      Trade.BuyStop(0.1, highAUDNZD, "AUDNZD", highAUDNZD - sl, highAUDNZD + tp, ORDER_TIME_SPECIFIED, expiration);
     }
   if(scoreAUDNZD == -1)
     {
      if(GetOpenPositionCount(Symbol()) > 0)
         return;

      if(GetOpenPositionCount("AUDNZD") > 0)
         return;

      Trade.SellStop(0.1, lowAUDNZD, "AUDNZD", lowAUDNZD + sl, lowAUDNZD - tp, ORDER_TIME_SPECIFIED, expiration);
     }
#endif
  }

//+------------------------------------------------------------------+
int CalculateScore(double &macdVals[], double &signalVals[], double &bbu[], double &bbl[], double &rsiVals[], double close)
  {
   int m = 0, b = 0, r = 0;
   if(macdVals[0] < signalVals[0])
     {
      m = -1;
     }
   else
      if(macdVals[0] > signalVals[0])
        {
         m = 1;
        }

   if(close > bbu[1])
     {
      b = -1;
     }
   else
      if(close < bbl[1])
        {
         b = 1;
        }

   if(rsiVals[0] >= 70)
     {
      r = -1;
     }
   else
      if(rsiVals[0] <= 30)
        {
         r = 1;
        }

   if(m == -1)
     {
      if(r == 1 && b == 1)
         return 1;
      else
         if(r == -1 || b == -1)
            return -1;
     }
   if(m == 1)
     {
      if(r == -1 && b == -1)
         return -1;
      else
         if(r == 1 || b == 1)
            return 1;
     }
   return 0;
  }
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
double PipSize(string symbol)
  {
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return (((digits % 2) == 1) ? point * 10 : point);
  }
//https://github.com/OrchardForexTutorials/221008_retracement_breakout_expert/blob/main/Experts/Orchard/Reentrant%20Breakout/Reentrant%20Breakout.mqh
double PipsToDouble(double pips) { return (pips * PipSize(Symbol())); }
double PipsToDouble(double pips, string symbol) { return (pips * PipSize(symbol)); }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetOpenPositionCount(string symbol)
  {
   int totalPositions = PositionsTotal();
   int count = 0;
   for(int i = 0; i < totalPositions; i++)
     {
      if(PositionGetSymbol(i) == symbol)
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
