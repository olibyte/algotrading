//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#define app_name "Naked Bot"
#define app_magic 190424
//#define use_htf
#define fvbo_core
//#define tester
//#define big_shadow_filter

#include <Trade/Trade.mqh>
#include <Indicators/IndicatorBollinger.mqh>
#include <Indicators/IndicatorCSR.mqh>
#include <Indicators/IndicatorMACD.mqh>
#include <Indicators/IndicatorRSI.mqh>
#include <Utils.mqh>


//BB user input
input bool InpRSI_filter = true;
input bool InpMACD_filter = true;
input bool InpBB_direction_filter = true;
input int InpBBPeriod = 20; // Bollinger period
input double InpBBDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE InpBBAppliedPrice = PRICE_CLOSE; // Bollinger applied price

//RSI user input
input int InpRSIPeriod = 5; // RSI period
input ENUM_APPLIED_PRICE   InpRSIAppliedPrice         = PRICE_CLOSE; // RSI applied price

//MACD user input
input int                  InpMACDPeriod              = 20;             // MACD period
input int                mFastPeriod                = 8;              //Fast period
input int                mSlowPeriod                = 21;             //Slower period
input int                mSignalPeriod              = 5;              //Signal period
input ENUM_APPLIED_PRICE   mAppliedPrice              = PRICE_CLOSE;    //MACD Applied Price

input ulong InpWaitBars            = 5;    //Num of bars to wait before considering new trade
//input int InpMaxHoldMins         = 150;
input int InpMaxPositions        = 1;     //Max number of positions open at any given time.
input ulong InpHoldBars            = 5;     //Maximum bars to hold a position
input int InpStopLossGapPoints   = 100;  //Stop loss gap in points.
input int InpEntryGapPoints = 50;      //flexibility when placing orders
input double InpLotSize = 0.1;         //Size in lots.
input double InpRR = 1.5; //Risk reward
input double InpTakeProfitTarget = 1.2; //TakeProfitTarget
input double InpMX = 0.0001; //slope. Minimum val for BB direction to be significant.
input bool InpUseHTF = false; //Use higher timeframes to calculate bias. Do not use when running visual tester.
//classes
CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CIndicatorBollinger BB;
CIndicatorRSI RSI;
CIndicatorMACD MACD;
CIndicatorBollinger BB_H1;
CIndicatorRSI RSI_H1;
CIndicatorMACD MACD_H1;
//FVBO
bool fvbo_buy_flag,fvbo_sell_flag;
datetime buy_signal_time, sell_signal_time;
double rangeHigh,rangeLow;
int rangeHighIndex, rangeLowIndex;
int rsi_score, bb_score, macd_score = 0;
int OnInit()
  {
   BB.Init(Symbol(), Period(), InpBBPeriod, 0, InpBBDeviations, InpBBAppliedPrice);
   MACD.Init(Symbol(),Period(),8,21,5,PRICE_CLOSE);
   RSI.Init(Symbol(),Period(),5,PRICE_CLOSE);
#ifdef use_htf
   BB_H1.Init(Symbol(), PERIOD_H1, InpBBPeriod, 0, InpBBDeviations, InpBBAppliedPrice);
   MACD_H1.Init(Symbol(),PERIOD_H1,8,21,5,PRICE_CLOSE);
   RSI_H1.Init(Symbol(),PERIOD_H1,5,PRICE_CLOSE);
#endif
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;                              // still looking at same bar
   if(!WaitForHTF(Symbol(), PERIOD_D1))
      return;   // Anchor data not available
   ulong last_deal_ticket = GetLastDealTicket();                  //last deal ticket
   ulong minutes_since_deal = GetMinutesSinceDeal(last_deal_ticket); //mins since last deal
   ulong hold_mins = barsToMinutes(InpHoldBars);
   ulong wait_mins = barsToMinutes(InpWaitBars);
   if(PositionsTotal() >= InpMaxPositions)
     {
      PrintFormat("Minutes since deal #%i: %i\nHold mins: %i",last_deal_ticket,minutes_since_deal,hold_mins);
      if(minutes_since_deal >= hold_mins)
        {
         Print("Closing ticket...");
         Trade.PositionClose(last_deal_ticket);
        }
     }
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
//OHLC for latest 2 fully formed bars
   double open1 =  NormalizeDouble(iOpen(Symbol(),Period(),1),Digits());
   double high1 =  NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
   double low1 =   NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
   double close1 = NormalizeDouble(iClose(Symbol(),Period(),1),Digits());
   double open2 =  NormalizeDouble(iOpen(Symbol(),Period(),2),Digits());
   double high2 =  NormalizeDouble(iHigh(Symbol(),Period(),2),Digits());
   double low2 =   NormalizeDouble(iLow(Symbol(),Period(),2),Digits());
   double close2 = NormalizeDouble(iClose(Symbol(),Period(),2),Digits());

//0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND
   double BBM = NormalizeDouble(BB.GetValue(0,1), Digits());
   double BBU = NormalizeDouble(BB.GetValue(1,1), Digits());
   double BBL = NormalizeDouble(BB.GetValue(2,1), Digits());

#ifdef use_htf
   double BBM_H1 = NormalizeDouble(BB_H1.GetValue(0,1), Digits());
   double BBU_H1 = NormalizeDouble(BB_H1.GetValue(1,1), Digits());
   double BBL_H1 = NormalizeDouble(BB_H1.GetValue(2,1), Digits());
#endif
   double tp =                BBM;
   double lots =              InpLotSize;
   double sl_gap =            PointsToDouble(InpStopLossGapPoints);
   double entry_gap =         PointsToDouble(InpEntryGapPoints);
   double rr = (high1-low1)*InpRR;
   double tp_target = (high1-low1)*InpTakeProfitTarget;
   datetime expiration =      iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
   string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);

   double current_high =      iHigh(Symbol(),Period(),1);
   double current_low =       iLow(Symbol(),Period(),1);
   //keep talloy of low below the lowest close
   //keep talloy of high above the highest close
   rangeHighIndex =           iHighest(Symbol(),Period(),MODE_CLOSE,48,3);
   rangeLowIndex =            iLowest(Symbol(),Period(),MODE_CLOSE,48,3);
   rangeHigh =                iClose(Symbol(),Period(),rangeHighIndex);
   rangeLow =                 iClose(Symbol(),Period(),rangeLowIndex);
   PrintFormat("RangeHigh: %.3f\nCurrentHigh: %.3f",rangeHigh,current_high);
   double candleRange = MathAbs(close1-open1);
   double pointsTarget = PointsToDouble(8,Symbol());
   if(candleRange > pointsTarget) { PrintFormat("Good candle, candle range is: %f\n points target is %f ",candleRange, pointsTarget); }

   ShowRange(rangeHigh,rangeLow,clrOrange,clrBlue);

//BB DIRECTION FILTER
   double mx = InpMX; //significant slope value
   int BBMdirection = getBBDirection(BB,0,0,3,mx);
   int BBUdirection = getBBDirection(BB,1,0,3,mx);
   int BBLdirection = getBBDirection(BB,2,0,3,mx);
//assign BB, MACD, RSI scores for current timeframe.
   int bbu_score = 0;
   int bbl_score = 0;
   if(BBUdirection > mx)    //upper band sloping upwards
     {
      bbu_score = 1;
     }
   else
      if(BBUdirection < -1*mx)    //upper band sloping down
        {
         bbu_score = -1;
        }
   if(BBLdirection > mx)    //lower band sloping upwards
     {
      bbl_score = 1;
     }
   else
      if(BBLdirection < -1*mx)    //lower band sloping downwards
        {
         bbl_score = -1;
        }

//STRICTER BB DIRECTION CONDITIONS
   if(BBUdirection > mx && BBLdirection > mx)    //BOTH BB in same direction
     {
      bb_score = 1;
     }
   else
      if(BBUdirection < -1*mx && BBLdirection < -1*mx)    //BOTH in same direction
        {
         bb_score = -1;
        }
      else
        {
         bb_score = 0;
        }
//RSI FILTER
   if(RSI.GetValue(0) >= 50 && RSI.GetValue(0) <= 80)    //user input
     {
      rsi_score = 1;
     }
   else
      if(RSI.GetValue(0) <= 50 && RSI.GetValue(0) >= 20)
        {
         rsi_score = -1;
        }
      else
        {
         rsi_score = 0;
        }
//MACD FILTER
   if(MACD.GetValue(0,0) > MACD.GetValue(1,0) && MACD.GetValue(0,1) < MACD.GetValue(1,1))
     {
      macd_score = 1;
     }
   else
      if(MACD.GetValue(0,0) < MACD.GetValue(1,0) && MACD.GetValue(0,1) > MACD.GetValue(1,1))
        {
         macd_score = -1;
        }
/////////////////HTF Scores///////////////
#ifdef use_htf
   int bb_h1_score = ((iClose(Symbol(),PERIOD_H1,0) < BBM_H1)) ? 1:-1; //closed below midline, buy. else, sell.
   int rsi_h1_score, macd_h1_score;
   if(RSI_H1.GetValue(0) >= 50 && RSI_H1.GetValue(0) <= 80)
     {
      rsi_h1_score = 1;
     }
   else
      if(RSI_H1.GetValue(0) <= 50 && RSI_H1.GetValue(0) >= 20)
        {
         rsi_h1_score = -1;
        }
      else
        {
         rsi_h1_score = 0;
        }
   if(MACD_H1.GetValue(0,0) > MACD_H1.GetValue(1,0) && MACD_H1.GetValue(0,1) < MACD_H1.GetValue(1,1))
     {
      macd_h1_score = 1;
     }
   else
      if(MACD_H1.GetValue(0,0) < MACD_H1.GetValue(1,0) && MACD_H1.GetValue(0,1) > MACD_H1.GetValue(1,1))
        {
         macd_h1_score = -1;
        }
   int hourly_score = bb_h1_score+rsi_h1_score+macd_h1_score;

   if(InpBB_direction_filter == false)
     {
      bbh_1_score = 0;
     }
#endif

   if(InpBB_direction_filter == false)
     {
      bb_score = 0;
      bbl_score = 0;
      bbu_score = 0;
     }
   if(InpRSI_filter == false)
     {
      rsi_score = 0;
     }
   if(InpMACD_filter == false)
     {
      macd_score = 0;
     }

///////////////////AVERAGE OUT SCORES///////////////

   int daily_close_score = (iClose(Symbol(),PERIOD_D1,0) > iOpen(Symbol(),PERIOD_D1,0)) ? 1:-1;
   int total_score = bb_score+rsi_score+macd_score+daily_close_score;
   int total_sell_score = bbu_score+rsi_score+macd_score+daily_close_score;
   int total_buy_score = bbl_score+rsi_score+macd_score+daily_close_score;
////////////////////FVBO SIGNALS////////////////
#ifdef fvbo_core
   if(close2 < BB.GetValue(2,2) && close1 > open1 && !fvbo_buy_flag)
     {
      drawFVBO(1,clrPink);
      fvbo_buy_flag = true;
      fvbo_sell_flag = false;
      buy_signal_time = TimeCurrent();
     }
   if(close2 > BB.GetValue(1,2) && close1 < open1 && !fvbo_sell_flag)
     {
      drawFVBO(1,clrPink);
      fvbo_buy_flag = false;
      fvbo_sell_flag = true;
      sell_signal_time = TimeCurrent();
     }
   if (close2 < rangeLow) { PrintFormat("NEW RANGE LOW");}
   if (close2 > rangeHigh) { PrintFormat("NEW RANGE HIGH");}
///////////////////FVBO TRADE MANAGEMENT/////////////////////
   if(fvbo_buy_flag)
     {
      //check if search has expired
      int lookback = 3;
      int buy_signal_candle = iBarShift(Symbol(),Period(),buy_signal_time,false);

      if(buy_signal_candle > lookback)
        {
         fvbo_buy_flag = false;
        }
      //PLACE BUY ORDER
      double sl =    NormalizeDouble(low1-sl_gap,   Digits());
      double price = high1;
      double tp =    price + tp_target;
      PrintFormat("Assessing BUY bias...total_score: %i\nmacd_score: %i\nbb_score: %i\nrsi_score: %i\ndaily_close_score: %i", total_score,macd_score,bb_score,rsi_score,daily_close_score);
      PrintFormat("and BBL score: %i",bbl_score);

#ifdef use_htf
      PrintFormat("and Hourly score: %i",hourly_score);
#endif
      //RiskReward must be below midline and score must be positive
      if(price+rr < BBM && candleRange > pointsTarget)
        {
         Trade.BuyStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
        }
     }

   if(fvbo_sell_flag)
     {
      int lookback = 3;
      int sell_signal_candle = iBarShift(Symbol(),Period(),sell_signal_time,false);
      if(sell_signal_candle > lookback)
        {
         fvbo_sell_flag = false;
        }
      //Place a sell order
      double sl         = NormalizeDouble(high1+sl_gap,Digits());
      double price      = low1;
      double tp         = price - tp_target;
      PrintFormat("Assessing SELL bias...total_score: %i\nmacd_score: %i\nbb_score: %i\nrsi_score: %i\ndaily_close_score: %i", total_score,macd_score,bb_score,rsi_score,daily_close_score);         //RiskReward must be above midline && score must be negative
      PrintFormat("and BBU score: %i",bbu_score);

#ifdef use_htf
      PrintFormat("and Hourly score: %i",hourly_score);
#endif
      if(price-rr > BBM && candleRange > pointsTarget)
        {
         Trade.SellStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
        }
     }
#endif
  }


//should be abstracted to CBollinger class
int getBBDirection(CIndicatorBollinger &Bollinger, int bufferIndex, int startBar, int endBar, double mx)
  {
   double startValue =  Bollinger.GetValue(bufferIndex,startBar);
   double endValue =    Bollinger.GetValue(bufferIndex,endBar);
   if(startValue-endValue > mx)
     {
      return 1; //upwards direction
     }
   else
      if(startValue-endValue < -1*mx)
        {
         return -1; //downwards direction
        }
      else
        {
         return 0; //since we're working with doubles, 0 will rarely happen. Consider normalizing to n digits.
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawFVBO(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "Setup" + setupTime, OBJ_TEXT, 0, setupTime, iHigh(Symbol(),Period(),i));
   ObjectSetString(0,"Setup" + setupTime,OBJPROP_TEXT,"FVBO");
   ObjectSetInteger(0, "Setup" + setupTime, OBJPROP_COLOR, c);
   ObjectSetDouble(0,"Setup" + setupTime,OBJPROP_ANGLE,90.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
//+------------------------------------------------------------------+
bool GetWaitingBeforeNewOrder(ENUM_DEAL_ENTRY deal_entry, ulong wait_time, ulong minutes_since_deal)
  {
   if(deal_entry == DEAL_ENTRY_OUT && minutes_since_deal < wait_time)
     {
      // PrintFormat("Minutes since last %s : %i",EnumToString(deal_entry),minutes_since_deal);
      return true;
     }
   return false;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_DEAL_REASON GetDealReason(ulong deal_ticket)
  {
   ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(deal_ticket, DEAL_REASON);
   return deal_reason;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_DEAL_ENTRY GetDealEntry(ulong deal_ticket)
  {
   ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
   return deal_entry;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong GetDealTime(ulong deal_ticket)
  {
   datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   return deal_time;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong GetMinutesSinceDeal(ulong deal_ticket)
  {
   ulong deal_time = GetDealTime(deal_ticket);
   ulong current_time = (long)TimeCurrent();
   ulong time_since_deal = current_time-deal_time;
   ulong time_since_deal_mins = time_since_deal / 60;
   return time_since_deal_mins;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong GetHoursSinceDeal(ulong deal_ticket)
  {
   ulong deal_time = GetDealTime(deal_ticket);
   ulong current_time = (long)TimeCurrent();
   ulong time_since_deal = current_time-deal_time;
   ulong time_since_deal_mins = time_since_deal / 60;
   ulong time_since_deal_hours = time_since_deal_mins / 24;
   return time_since_deal_hours;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeExpiredPosition(ulong position_ticket, ulong minutes_since_deal, ulong max_position_time)
  {
   if(minutes_since_deal > max_position_time)
     {
      Trade.PositionClose(position_ticket);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong barsToMinutes(ulong bars)
  {

   ulong minutes = PeriodSeconds(PERIOD_CURRENT) / 60;
   return minutes * bars;
  }
//+------------------------------------------------------------------+
