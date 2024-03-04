//+------------------------------------------------------------------+
//|                                           VeryNewestStrategy.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#define app_name "Very Newest Strategy"
#define app_magic 020324
#include <Trade/Trade.mqh>
CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

input double InpOrderSize = 0.1; // order size in lots
input int InpMagic = app_magic;          // Magic number
input string InpTradeComment = app_name; // Trade comment
// Indicator inputs
input int InpBollingerPeriod = 20;                               // Bollinger period
input double InpBollingerDeviations = 2.0;                       // Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; // Bollinger applied price
input int InpKeltnerPeriod = 20;                                 // Keltner Channel period
input double InpKeltnerMultiplier = 1.5;                         // Keltner Channel Multiplier
input ENUM_MA_METHOD InpKeltnerMAMethod = MODE_EMA;              // Keltner Channel
input ENUM_APPLIED_PRICE InpKeltnerAppliedPrice = PRICE_CLOSE;   // Keltner applied price
// Entry exit settings
input int InpEntryGapPoints = 10;    // Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; // SL gap points, 50pts=0.5pips
input int    InpEMAPeriod=20;     //  Period of EMA
input int    InpATRPeriod=20;     //  Period of ATR
input double InpATRFactor=20;    //  ATR multiplier
input bool   InpShowLabel=false;   //  show price of level

// Indicator handles
int HandleBollinger; int HandleKeltner;
double ValuesBollingerUpper[]; double ValuesBollingerLower[]; double ValuesBollingerMiddle[]; double ValuesKeltnerUpper[]; double ValuesKeltnerLower[];
MqlRates Rates[]; MqlTick currentTick;
double high; double low; double open; double close;
bool sell_breakout; bool buy_breakout; bool buy_reversal; bool sell_reversal; bool no_setup_and_reversal;
double price; double tp; double sl; double entryGap; double stopLossGap; double candleRange;
int sell_counter; int buy_counter;
int OnInit()
  {
    HandleKeltner = iCustom(Symbol(), Period(), "Keltner Channel.ex5", InpEMAPeriod,InpATRPeriod,InpATRFactor,InpShowLabel);
    HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
    ArraySetAsSeries(ValuesBollingerUpper, true);
    ArraySetAsSeries(ValuesBollingerLower, true);
    ArraySetAsSeries(ValuesBollingerMiddle, true);
    ArraySetAsSeries(ValuesKeltnerUpper, true);
    ArraySetAsSeries(ValuesKeltnerLower, true);
    ArraySetAsSeries(Rates, true);

    entryGap = PointsToDouble(InpEntryGapPoints);
    stopLossGap = PointsToDouble(InpStopLossGapPoints);

    Trade.SetExpertMagicNumber(InpMagic);
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
    IndicatorRelease(HandleBollinger);
    IndicatorRelease(HandleKeltner);   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//-------------START ONTICK-----------
          //change this such that if we're in a reversal and setup, we can assess the [0]th bar.
    //no_setup_and_reversal = (sell_breakout && sell_reversal) || (buy_breakout && buy_reversal);
    
    if (!IsNewBar())
        return;
    int numCandles = 10;
    if (CopyBuffer(HandleBollinger, UPPER_BAND, 0, numCandles, ValuesBollingerUpper) < numCandles)
        return;
    if (CopyBuffer(HandleBollinger, LOWER_BAND, 0, numCandles, ValuesBollingerLower) < numCandles)
        return;
    if (CopyBuffer(HandleBollinger, BASE_LINE, 0, numCandles, ValuesBollingerMiddle) < numCandles)
        return;
    if (CopyBuffer(HandleKeltner, UPPER_BAND, 0, numCandles, ValuesKeltnerUpper) < numCandles)
        return;
    if (CopyBuffer(HandleKeltner, LOWER_BAND, 0, numCandles, ValuesKeltnerLower) < numCandles)
        return;
    if (CopyRates(Symbol(), Period(), 0, numCandles, Rates) < numCandles)
        return;
    if (!bollingerWasInKeltner(numCandles))
        return;



    if (PositionsTotal() == 0) {

        //look for high breakout
        if (sellBreakout(1) && !sell_breakout) {
            sell_counter = 5; sell_breakout = true; sell_reversal = false;
            buy_counter = 0; buy_breakout = false; buy_reversal = false;
            PrintFormat("Sell Breakout found! Resetting buy vals, setting sell_counter to %i", sell_counter);
            sell_counter--;
        }
        //found high breakout, looking for reversal
        if (sell_breakout && !sell_reversal && sell_counter > 0) {
            PrintFormat("In a sell breakout, looking for reversal. sell_counter is %i",sell_counter);
            if (Rates[1].close < Rates[2].close) {
                sell_counter = 5; sell_breakout = true; sell_reversal = true;
                buy_counter = 0; buy_breakout = false; buy_reversal = false;
                PrintFormat("Found reversal candle. Resetting sell_counter to %i",sell_counter);
            }
            sell_counter--;
        }
        //try place an order while 
        if (sell_breakout && sell_reversal && sell_counter > 0) {
            price = Rates[1].low;
            sl = Rates[1].high + 25* _Point;
            tp = ValuesBollingerMiddle[1];
            PrintFormat("Placing order. Price: %f sl: %f tp: %f  sell_counter: %i",price,sl,tp,sell_counter);
            PlaceOrder(ORDER_TYPE_SELL_STOP,price,sl,tp,0.1,InpTradeComment);
            sell_counter--;
        }
        if (sell_counter == 0 && (sell_breakout || sell_reversal)) {
            PrintFormat("Search for SELL expired. Resetting vals.");
            sell_breakout = false; sell_reversal = false; buy_breakout = false; buy_reversal = false; sell_counter = -1; buy_counter == -1;
        }

        //look for low breakout
        if (buyBreakout(1) && !buy_breakout) {
            buy_counter = 5; buy_breakout = true; buy_reversal = false;
            sell_counter = 0; sell_breakout = false; sell_reversal = false;
            PrintFormat("Buy Breakout found! Resetting sell vals, setting buy_counter to %i", buy_counter);
            buy_counter--;
        }
        //found low breakout, looking for reversal
        if (buy_breakout && !buy_reversal && buy_counter > 0) {
            PrintFormat("In a buy breakout, looking for reversal. buy_counter is %i",buy_counter);
            if (Rates[1].close > Rates[2].close) {
                buy_counter = 5; buy_breakout = true; buy_reversal = true;
                sell_counter = 0; sell_breakout = false; sell_reversal = false;
                PrintFormat("Found reversal candle. Resetting buy_counter to %i",buy_counter);
            }
            buy_counter--;
        }
        //try place an order while 
        if (buy_breakout && buy_reversal && buy_counter > 0) {
            price = Rates[1].high;
            sl = Rates[1].low - 25* _Point;
            tp = ValuesBollingerMiddle[1];
            PrintFormat("Placing order. Price: %f sl: %f tp: %f  buy_counter: %i",price,sl,tp,buy_counter);
            PlaceOrder(ORDER_TYPE_BUY_STOP,price,sl,tp,0.1,InpTradeComment);
            buy_counter--;
        }
        if (buy_counter == 0 && (buy_breakout || buy_reversal)) {
            PrintFormat("Search for BUY expired. Resetting vals.");
            sell_breakout = false; sell_reversal = false; buy_breakout = false; buy_reversal = false; sell_counter = -1; buy_counter == -1;
        }
    }
//----------------END ONTICK--------------------
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Returns the last deal ticket in history or -1                    |
//+------------------------------------------------------------------+
bool sellBreakout(int candleIndex) { return Rates[candleIndex].close > ValuesBollingerUpper[candleIndex] ? true : false; }
bool buyBreakout(int candleIndex) { return Rates[candleIndex].close < ValuesBollingerLower[candleIndex] ? true : false; }
//bool sellReversal(candleIndex) { return }
bool bollingerWasInKeltner(int numCandles) {
    for (int i = 0; i < numCandles; i++)
    {

       // PrintFormat("Values: %f",ValuesBollingerLower[i]-ValuesKeltnerLower[i]); //if BBLOW > KCLOW, BBINSIDEKC
        if ((ValuesBollingerLower[i] - ValuesKeltnerLower[i] >= 0) || (ValuesKeltnerUpper[i] - ValuesBollingerUpper[i] >= 0))
        {
            return true;
        }
    }
    return false;
}
// long GetLastDealTime(ulong lastDeal) {
   
// }
// ENUM_DEAL_REASON GetLastDealReason(ulong lastDeal) {

// }
// ENUM_DEAL_TYPE GetLastDealType(ulong lastDeal) {
   
// }
// ENUM_DEAL_ENTRY GetLastDealEntry(ulong lastDeal){
   
// }
ulong GetLastDealTicket()
{
    //--- request history for the last 7 days
    if (!GetTradeHistory(7))
    {
        //--- notify on unsuccessful call and return -1
        Print(__FUNCTION__, " HistorySelect() returned false");
        return -1;
    }
    //---
    ulong first_deal, last_deal, deals = HistoryDealsTotal();
    //--- work with orders if there are any
    if (deals > 0)
    {
//        Print("Deals = ", deals);
        first_deal = HistoryDealGetTicket(0);
        if (deals > 1)
        {
            last_deal = HistoryDealGetTicket((int)deals - 1);
//            PrintFormat("last_deal = %d", last_deal);
            return last_deal;
        }
        return first_deal;
    }
    //--- no deal found, return -1
    return -1;
}
//+--------------------------------------------------------------------------+
//| Requests history for the last days and returns false in case of failure  |
//+--------------------------------------------------------------------------+
bool GetTradeHistory(int days)
{
    //--- set a week period to request trade history
    datetime to = TimeCurrent();
    datetime from = to - days * PeriodSeconds(PERIOD_D1);
    ResetLastError();
    //--- make a request and check the result
    if (!HistorySelect(from, to))
    {
        Print(__FUNCTION__, " HistorySelect=false. Error code=", GetLastError());
        return false;
    }
    //--- history received successfully
    return true;
}
// Source: How to run MQL4 or MQL5 code only one time for each bar
bool IsNewBar()
{
    static datetime previousBarTime = iTime(Symbol(), Period(), 0);
    datetime currentBarTime = iTime(Symbol(), Period(), 0);

    if (currentBarTime == previousBarTime)
        return false;
    previousBarTime = currentBarTime;
    return true;
}
double PointsToDouble(int points, string symbol = "")
{
    if (symbol == "")
        symbol = Symbol();

    double value = (double)points * SymbolInfoDouble(symbol, SYMBOL_POINT);
    return value;
}
void PlaceOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit, double lots, string comment) {
    // refactor TP to use candle Range or rVal
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    price = NormalizeDouble(price, digits);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    PrintFormat("Calling PlaceOrder. PositionsTotal is: ", PositionsTotal());
    // order expires at end of next candle
    datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());

    if (!Trade.OrderOpen(Symbol(), type, lots, 0, price, stopLoss, takeProfit,ORDER_TIME_SPECIFIED, expiration, comment)) {
        PrintFormat("Open Order failed for %s, %s, price=%f, sl=%f, tp=%f",Symbol(), EnumToString(type), price, stopLoss, takeProfit);
    }
}