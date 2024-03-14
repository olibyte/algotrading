#define app_name "Newest Strategy"
#define app_magic 301124
input int InpMagic = app_magic; // Magic number
input string InpTradeComment = app_name; // Trade comment

#include <Trade/Trade.mqh>
#include <NewestInputs.mqh>
#include <NewestTime.mqh>
CTrade Trade; CPositionInfo PositionInfo; COrderInfo OrderInfo;
color clr;

// Indicator handles
int HandleBollinger;
int HandleKeltner;
int HandleATR;
int HandleRSI;
int HandleRSIATR;
double ValuesBollingerUpper[];
double ValuesBollingerLower[];
double ValuesBollingerMiddle[];
double ValuesKeltnerUpper[];
double ValuesKeltnerLower[];
double ValuesATR[];
double ValuesRSI[];
double ValuesRSIATR[];
MqlRates Rates[];
MqlTick currentTick;

double sl;
double tp;
double price;
double EntryGap;
double StopLossGap;
bool tradeAllowed;
ENUM_ORDER_TYPE currentOrderType;
bool buy_setup;
bool sell_setup;
int buy_counter;
int sell_counter;
bool bollinger_was_in_keltner;
bool position_exists;
bool fvbo_buy_setup;
bool fvbo_sell_setup;
bool waiting_before_new_order;

//Performance & Patterns
bool get_euphoria_accuracy;
int correct_euphoria_bull_preds;
int correct_euphoria_bear_preds;
int total_euphoria_bull_preds;
int total_euphoria_bear_preds;
double euphoria_bull_accuracy;
double euphoria_bear_accuracy;

bool get_barrier_accuracy;
int correct_barrier_bull_preds;
int correct_barrier_bear_preds;
int total_barrier_bull_preds;
int total_barrier_bear_preds;
double barrier_bull_accuracy;
double barrier_bear_accuracy;

bool get_double_trouble_with_rsi_filter_accuracy;
int correct_double_trouble_with_rsi_filter_bull_preds;
int correct_double_trouble_with_rsi_filter_bear_preds;
int total_double_trouble_with_rsi_filter_bull_preds;
int total_double_trouble_with_rsi_filter_bear_preds;
double double_trouble_with_rsi_filter_bear_accuracy;
double double_trouble_with_rsi_filter_bull_accuracy;

bool get_engulfing_bollinger_accuracy;
int correct_engulfing_bollinger_bull_preds;
int correct_engulfing_bollinger_bear_preds;
int total_engulfing_bollinger_bull_preds;
int total_engulfing_bollinger_bear_preds;
double engulfing_bollinger_bear_accuracy;
double engulfing_bollinger_bull_accuracy;

int today;
int server_day;
struct RANGE_STRUCT {
   datetime start_time;
   datetime end_time;
   datetime close_time;
   double high;
   double low;
   bool f_entry;
   bool f_high_breakout;
   bool f_low_breakout;
   
   RANGE_STRUCT() : 
      start_time(0), 
      end_time(0), 
      close_time(0),
      high(0), 
      low(DBL_MAX), 
      f_entry(false), 
      f_high_breakout(false), 
      f_low_breakout(false) {};
};
/*
input group "==== Range Inputs ====";
input int inpRangeStart = 600;
input int inpRangeDuration = 60 * 2;
input int inpRangeClose = 1200;

input group "==== Day of week filter ====";
input bool inpMonday = true;
input bool inpTuesday = true;
input bool inpWednesday = true;
input bool inpThursday = true;
input bool inpFriday = true;
*/
MqlTick prevTick, lastTick;
RANGE_STRUCT range;

// Initialisation
int OnInit() {

  string keltner = "Keltner Channel.ex5";
  HandleKeltner = iCustom(Symbol(), Period(),keltner,InpEMAPeriod,InpATRPeriod,InpATRFactor,InpShowLabel);
  HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
  HandleATR = iATR(Symbol(),Period(),InpATRPeriod);
  HandleRSI = iRSI(Symbol(),Period(),InpRSIPeriod,InpRSIAppliedPrice);
  ArraySetAsSeries(ValuesBollingerUpper, true);
  ArraySetAsSeries(ValuesBollingerLower, true);
  ArraySetAsSeries(ValuesBollingerMiddle, true);
  ArraySetAsSeries(ValuesKeltnerUpper, true);
  ArraySetAsSeries(ValuesKeltnerLower, true);
  ArraySetAsSeries(ValuesATR,true);
  ArraySetAsSeries(ValuesRSI, true);
  ArraySetAsSeries(Rates, true);
  EntryGap = PointsToDouble(InpEntryGapPoints);
  StopLossGap = PointsToDouble(InpStopLossGapPoints);

  Trade.SetExpertMagicNumber(InpMagic);

  return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {
  IndicatorRelease(HandleBollinger);
  IndicatorRelease(HandleKeltner);
  IndicatorRelease(HandleATR);
}
void OnTick() {
  if (!IsNewBar())
    return; // still looking at same bar
  int numCandles = 20;
  if (CopyBuffer(HandleBollinger, UPPER_BAND, 0, numCandles, ValuesBollingerUpper) < numCandles)
    return;
  if (CopyBuffer(HandleBollinger, LOWER_BAND, 0, numCandles, ValuesBollingerLower) < numCandles)
    return;
  if (CopyBuffer(HandleBollinger, BASE_LINE, 0, numCandles, ValuesBollingerMiddle) < numCandles)
    return;
  if (CopyBuffer(HandleKeltner, 0, 0, numCandles, ValuesKeltnerUpper) < numCandles)
    return;
  if (CopyBuffer(HandleKeltner, 2, 0, numCandles, ValuesKeltnerLower) < numCandles)
    return;
  if (CopyBuffer(HandleATR, BASE_LINE, 0, numCandles, ValuesATR) < numCandles)
    return;
  if (CopyBuffer(HandleRSI, BASE_LINE, 0, numCandles, ValuesRSI) < numCandles)
    return;    
  if (CopyRates(Symbol(), Period(), 0, numCandles, Rates) < numCandles)
    return;
  if (!SymbolInfoTick(_Symbol, currentTick)) {
    Print("Failed to get current tick");
    return;
  }
  
  double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits); // LEARN MQL5 85
  double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits); // LEARN MQL5 85
  double candleRange = MathAbs(Rates[1].high - Rates[1].low);
  double rVal = candleRange * 1.2;
  double bodySize = MathAbs(Rates[1].open - Rates[1].close);
  double BBUpperRange = MathAbs(ValuesBollingerUpper[1] - ValuesBollingerMiddle[1]);
  double BBLowerRange = MathAbs(ValuesBollingerLower[1] - ValuesBollingerMiddle[1]);
  
  if (InpDrawSignals) {
    int periods = 5;
    DrawSignals(1,periods);
  }
  //check if today is a trading day
  MqlDateTime current_server_time_struct;
  datetime current_server_time = TimeTradeServer();
  TimeToStruct(current_server_time,current_server_time_struct);

  if (!isTradingDay(current_server_time_struct.day_of_week)) {
    //close position when outside trading day
    if (position_exists) {
      ulong last_deal = GetLastDealTicket();
      PrintFormat("Closing position: %i",last_deal);
      Trade.PositionClose(last_deal);
    }
    return;
  }
  
  if (!isTradingHours(current_server_time_struct.hour, InpStartHour,InpEndHour)) {
    //close position when outside trading hour
    if (position_exists) {
      ulong last_deal = GetLastDealTicket();
      PrintFormat("Closing position: %i",last_deal);
      Trade.PositionClose(last_deal);
    }
    return;
  }  
  //DEFINE TRADING HOURS
  ulong last_deal = GetLastDealTicket();
  ENUM_DEAL_REASON last_deal_reason = GetDealReason(last_deal);
  ENUM_DEAL_ENTRY last_deal_entry = GetDealEntry(last_deal);
  ulong minutes_since_last_deal = GetMinutesSinceDeal(last_deal);
  ulong max_position_time = InpMaxPositionTime; //periodify
  ulong wait_time = InpWaitTime; //periodify
  position_exists = getPositionExists(); 
  //these values called inside setup definitions
  waiting_before_new_order = GetWaitingBeforeNewOrder(last_deal_entry,wait_time,minutes_since_last_deal);
  bollinger_was_in_keltner = getBollingerWasInKeltner(0,InpKeltnerLookback);
 
  getPatternAccuracy(1,get_euphoria_accuracy=false,get_barrier_accuracy=false,get_double_trouble_with_rsi_filter_accuracy=false,get_engulfing_bollinger_accuracy=true);

  if (position_exists) {
    ulong position_ticket = PositionGetTicket(0);
    closeExpiredPosition(position_ticket,minutes_since_last_deal,max_position_time);
  }
  // PrintFormat("last_deal: %i \n last_deal_reason %s \n last_deal_entry: %s \n minutes_since_last_deal: %i",last_deal,EnumToString(last_deal_reason),EnumToString(last_deal_entry),minutes_since_last_deal);
  if (
    isFvboBuySetup(1) 
    // && (isBullishEuphoria(2)) //a step back because candleIndex 1 is the reversal
    ) {
    // PrintFormat("FVBO Buy!: BBL[2]: %f KCL[2]: %f \n Rates[2].close: %f BBL[2]: %f \n Rates[2].close: %f Rates[2].open %f \n Rates[1].close %f Rates[1].open %f", 
    // ValuesBollingerLower[2],ValuesKeltnerLower[2],Rates[2].close, ValuesBollingerLower[2],Rates[2].close, Rates[2].open, Rates[1].close, Rates[1].open); 
    fvbo_buy_setup = true;
    buy_counter = 3;
  }
  //check if we can trade
  if (
    position_exists 
    || waiting_before_new_order
    || !bollinger_was_in_keltner
  ) {
    fvbo_buy_setup = false;
    buy_counter = 0;
    /*
    if (!bollinger_was_in_keltner) {
      PrintFormat("Cannot do trade: bollinger_was_in_keltner: %i", (string)bollinger_was_in_keltner);
    }
    if (waiting_before_new_order) {
      PrintFormat("Too soon to place new order. minutes_since_last_deal %i",minutes_since_last_deal);
    }
    */
    //PrintFormat("Cannot do buy trade. \n position_exists: %s \n waiting_before_new_order: %s \n bollinger_was_in_keltner: %s", (string)position_exists,(string)waiting_before_new_order,(string)bollinger_was_in_keltner);
  }
  //place an order while counter not expired, we have no open positions and we're not waiting before a new order
  if (fvbo_buy_setup && buy_counter >= 0) {
    //can use price = MathMax(Ask, Rates[1].high) to eliminate those pesky invalid price errors
      price = Rates[1].high;
      sl = Rates[1].low-InpStopLossGapPoints*_Point;
      tp = price + rVal;
      int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      //uncomment if we want to move the price away from market price.
      // long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)+50;
      // double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
      string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      // PrintFormat("Before we open an order, our values are... \n Digits: %i \n Parsed in...\n price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s \n buy_counter: %i",digits,price,sl,tp,ValuesBollingerMiddle[1],expiration_string,buy_counter);
      //if high + rval is still less than the midline
      if (tp < ValuesBollingerMiddle[1]) {
        OpenBetterOrder(ORDER_TYPE_BUY_STOP,price,sl,tp,InpOrderSize,InpTradeComment);
      }
    buy_counter--;
    //buy_counter expired
   if (buy_counter == 0) {
      fvbo_buy_setup = false;
      buy_counter = 0;
      // Print("Buy counter expired. Setting buy_counter to 0 and fvbo_buy_setup to false");
   }
   //we must have 
   if (position_exists) {
    // Print("Have an open position. Setting buy_counter to 0 and fvbo_buy_setup to false");
    buy_counter = 0;
    fvbo_buy_setup = false;
   }
  }

  if (
    isFvboSellSetup(1)
    // && (isBearishEuphoria(2))  //a step back because candleIndex 1 is the reversal
    ) {
    // PrintFormat("FVBO SELL!: BBU[2]: %f KCU[2]: %f \n Rates[2].close: %f BBU[2]: %f \n Rates[2].close: %f Rates[2].open %f \n Rates[1].close %f Rates[1].open %f", 
    // ValuesBollingerUpper[2],ValuesKeltnerUpper[2],Rates[2].close, ValuesBollingerUpper[2],Rates[2].close, Rates[2].open, Rates[1].close, Rates[1].open); 
    fvbo_sell_setup = true;
    sell_counter = 3;
  }
  //check if we can trade
  if (position_exists 
  || waiting_before_new_order 
  || !bollinger_was_in_keltner
  ) {
    fvbo_sell_setup = false;
    sell_counter = 0;
    /*
    if (!bollinger_was_in_keltner) {
      PrintFormat("Cannot do trade: bollinger_was_in_keltner: %i", (string)bollinger_was_in_keltner);
    }
    if (waiting_before_new_order) {
      PrintFormat("Too soon to place new order. minutes_since_last_deal %i",minutes_since_last_deal);
    }
    */
    //PrintFormat("Cannot do sell trade. \n position_exists: %s \n waiting_before_new_order: %s \n bollinger_was_in_keltner: %s",(string)position_exists,(string)waiting_before_new_order,(string)bollinger_was_in_keltner);
  }
  if (fvbo_sell_setup && sell_counter >= 0) {
        //can use price = MathMin(Bid, Rates[1].low) to eliminate those pesky invalid price errors
      price = Rates[1].low;
      sl = Rates[1].high+InpStopLossGapPoints*_Point;
      tp = price - rVal;
      int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
      string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      // PrintFormat("Before we open an order, our values are... \n Digits: %i \n Parsed in...\n price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s \n buy_counter: %i",digits,price,sl,tp,ValuesBollingerMiddle[1],expiration_string,buy_counter);
      //validate trade
      if (tp > ValuesBollingerMiddle[1]) {
        OpenBetterOrder(ORDER_TYPE_SELL_STOP,price,sl,tp,InpOrderSize,InpTradeComment);
      }
    sell_counter--;
    //sell_counter expired
   if (sell_counter == 0) {
      fvbo_sell_setup = false;
      sell_counter = 0;
      // Print("Sell counter expired. Setting sell_counter to 0 and fvbo_sell_setup to false");
   }
   //we must have 
   if (position_exists) {
    // Print("Have an open position. Setting sell_counter to 0 and fvbo_sell_setup to false");
    sell_counter = 0;
    fvbo_sell_setup = false;
   }
  }
}
//---PERFORMANCE---//
void getPatternAccuracy(int candleIndex, bool euphoria=true, bool barrier=true, bool double_trouble_with_rsi_filter=true,bool engulfing_bollinger=true) {
  if (euphoria) {
    getBearishEuphoriaAccuracy(candleIndex);
    getBullishEuphoriaAccuracy(candleIndex);
  }
  if (barrier) {
    getBearishBarrierAccuracy(candleIndex);
    getBullishBarrierAccuracy(candleIndex);
  }
  if (double_trouble_with_rsi_filter) {
    getBearishDoubleTroubleWithRSIFilterAccuracy(candleIndex);
    getBullishDoubleTroubleWithRSIFilterAccuracy(candleIndex);
  }
  if (engulfing_bollinger) {
    getBearishEngulfingBollingerAccuracy(candleIndex);
    getBullishEngulfingBollingerAccuracy(candleIndex);
  }
}
void getBearishEuphoriaAccuracy(int candleIndex) {
if (isBearishEuphoria(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_euphoria_bear_preds+=1;
    total_euphoria_bear_preds+=1;
    if (correct_euphoria_bear_preds > 0 && total_euphoria_bear_preds > 0) {
      euphoria_bear_accuracy = (double)correct_euphoria_bear_preds/(double)total_euphoria_bear_preds;
      PrintFormat("Euphoria Bear accuracy: %.2f (%i/%i)", euphoria_bear_accuracy*100,correct_euphoria_bull_preds,total_euphoria_bull_preds);
    }
  }
if (isBearishEuphoria(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_euphoria_bear_preds+=1;
  }
}
void getBullishEuphoriaAccuracy(int candleIndex) {
  if (isBullishEuphoria(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_euphoria_bull_preds+=1;
    total_euphoria_bull_preds+=1;
    if (correct_euphoria_bull_preds > 0 && total_euphoria_bull_preds > 0) {
      euphoria_bull_accuracy = (double)correct_euphoria_bull_preds/(double)total_euphoria_bull_preds;
      PrintFormat("Euphoria Bull accuracy: %.2f (%i/%i)", euphoria_bull_accuracy*100,correct_euphoria_bull_preds,total_euphoria_bull_preds);
    }
  }
    if (isBullishEuphoria(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_euphoria_bull_preds+=1;
  }

}
void getBearishBarrierAccuracy(int candleIndex) {
  if (isBearishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_barrier_bear_preds+=1;
    total_barrier_bear_preds+=1;
    if (correct_barrier_bear_preds > 0 && total_barrier_bear_preds > 0) {
      barrier_bear_accuracy = (double)correct_barrier_bear_preds/(double)total_barrier_bear_preds;
      PrintFormat("Barrier Bear accuracy: %.2f (%i/%i)", barrier_bear_accuracy*100,correct_barrier_bear_preds,total_barrier_bear_preds);
    }
  }
  if (isBearishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_barrier_bear_preds+=1;
  }
}
void getBullishBarrierAccuracy(int candleIndex) {
  if (isBullishBarrier(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_barrier_bull_preds+=1;
    total_barrier_bull_preds+=1;
    if (correct_barrier_bull_preds > 0 && total_barrier_bull_preds > 0) {
      barrier_bull_accuracy = (double)correct_barrier_bull_preds/(double)total_barrier_bull_preds;
      PrintFormat("Barrier Bull accuracy: %.2f (%i/%i)", barrier_bull_accuracy*100,correct_barrier_bull_preds,total_barrier_bull_preds);
    }
  }
  if (isBullishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_barrier_bull_preds+=1;
  }
}
void getBearishDoubleTroubleWithRSIFilterAccuracy(int candleIndex) {
  if (isBearishDoubleTroubleWithRSIFilter(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_double_trouble_with_rsi_filter_bear_preds+=1;
    total_double_trouble_with_rsi_filter_bear_preds+=1;
    if (correct_double_trouble_with_rsi_filter_bear_preds > 0 && total_double_trouble_with_rsi_filter_bear_preds > 0) {
      double_trouble_with_rsi_filter_bear_accuracy = (double)correct_double_trouble_with_rsi_filter_bear_preds/(double)total_double_trouble_with_rsi_filter_bear_preds;
      PrintFormat("double_trouble_with_rsi_filter Bear accuracy: %.2f (%i/%i)", double_trouble_with_rsi_filter_bear_accuracy*100,correct_double_trouble_with_rsi_filter_bear_preds,total_double_trouble_with_rsi_filter_bear_preds);
    }
  }
  if (isBearishDoubleTroubleWithRSIFilter(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_double_trouble_with_rsi_filter_bear_preds+=1;
  }
}
void getBullishDoubleTroubleWithRSIFilterAccuracy(int candleIndex) {
  if (isBullishDoubleTroubleWithRSIFilter(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_double_trouble_with_rsi_filter_bull_preds+=1;
    total_double_trouble_with_rsi_filter_bull_preds+=1;
    if (correct_double_trouble_with_rsi_filter_bull_preds > 0 && total_double_trouble_with_rsi_filter_bull_preds > 0) {
      double_trouble_with_rsi_filter_bull_accuracy = (double)correct_double_trouble_with_rsi_filter_bull_preds/(double)total_double_trouble_with_rsi_filter_bull_preds;
      PrintFormat("double_trouble_with_rsi_filter Bull accuracy: %.2f (%i/%i)", double_trouble_with_rsi_filter_bull_accuracy*100,correct_double_trouble_with_rsi_filter_bull_preds,total_double_trouble_with_rsi_filter_bull_preds);
    }
  }
  if (isBullishDoubleTroubleWithRSIFilter(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_double_trouble_with_rsi_filter_bull_preds+=1;
  }
}
void getBearishEngulfingBollingerAccuracy(int candleIndex) {
  if (isBearishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_engulfing_bollinger_bear_preds+=1;
    total_engulfing_bollinger_bear_preds+=1;
    if (correct_engulfing_bollinger_bear_preds > 0 && total_engulfing_bollinger_bear_preds > 0) {
      engulfing_bollinger_bear_accuracy = (double)correct_engulfing_bollinger_bear_preds/(double)total_engulfing_bollinger_bear_preds;
      PrintFormat("engulfing_bollinger Bear accuracy: %.2f (%i/%i)", engulfing_bollinger_bear_accuracy*100,correct_engulfing_bollinger_bear_preds,total_engulfing_bollinger_bear_preds);
    }
  }
  if (isBearishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_engulfing_bollinger_bear_preds+=1;
  }
}
void getBullishEngulfingBollingerAccuracy(int candleIndex) {
  if (isBullishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_engulfing_bollinger_bull_preds+=1;
    total_engulfing_bollinger_bull_preds+=1;
    if (correct_engulfing_bollinger_bull_preds > 0 && total_engulfing_bollinger_bull_preds > 0) {
      engulfing_bollinger_bull_accuracy = (double)correct_engulfing_bollinger_bull_preds/(double)total_engulfing_bollinger_bull_preds;
      PrintFormat("engulfing_bollinger Bull accuracy: %.2f (%i/%i)", engulfing_bollinger_bull_accuracy*100,correct_engulfing_bollinger_bull_preds,total_engulfing_bollinger_bull_preds);
    }
  }
  if (isBullishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_engulfing_bollinger_bull_preds+=1;
  }
}
bool isTradingDay(int day) { 
  if (InpSunday == false && day == 0) {
    // PrintFormat("Cannot trade on a Sunday");
    return false;
  }
  if (InpMonday == false && day == 1) {
    // PrintFormat("Cannot trade on a Monday");
    return false;
  }
  if (InpTuesday == false && day == 2) {
    // PrintFormat("Cannot trade on a Tuesday");
    return false;
  }
  if (InpWednesday == false && day == 3) {
    // PrintFormat("Cannot trade on a Wednesday");
    return false;
  }
  if (InpThursday == false && day == 4) {
    // PrintFormat("Cannot trade on a Thursday");
    return false;
  }
  if (InpFriday == false && day == 5) {
    // PrintFormat("Cannot trade on a Friday");
    return false;
  }
  if (InpSaturday == false && day == 6) {
    // PrintFormat("Cannot trade on a Saturday");
    return false;
  }
  return true;
}
bool isTradingHours(int hour,int start,int end) {
  return (hour >= start && hour <= end) ? true : false;
}

ulong GetLastDealTicket() {
  //--- request history for the last 7 days
  if (!GetTradeHistory(7)) {
    //--- notify on unsuccessful call and return -1
    Print(__FUNCTION__, " HistorySelect() returned false");
    return -1;
  }
  //---
  ulong first_deal, last_deal, deals = HistoryDealsTotal();
  //--- work with orders if there are any
  if (deals > 0) {
    //        Print("Deals = ", deals);
    first_deal = HistoryDealGetTicket(0);
    if (deals > 1) {
      last_deal = HistoryDealGetTicket((int) deals - 1);
      //            PrintFormat("last_deal = %d", last_deal);
      return last_deal;
    }
    return first_deal;
  }
  //--- no deal found, return -1
  return -1;
}
bool GetTradeHistory(int days) {
  //--- set a week period to request trade history
  datetime to = TimeCurrent();
  datetime from = to - days * PeriodSeconds(PERIOD_D1);
  ResetLastError();
  //--- make a request and check the result
  if (!HistorySelect(from, to)) {
    Print(__FUNCTION__, " HistorySelect=false. Error code=", GetLastError());
    return false;
  }
  //--- history received successfully
  return true;
}
bool GetWaitingBeforeNewOrder(ENUM_DEAL_ENTRY deal_entry, ulong wait_time, ulong minutes_since_deal) {
    if (deal_entry == DEAL_ENTRY_OUT && minutes_since_deal < wait_time) {
      // PrintFormat("Minutes since last %s : %i",EnumToString(deal_entry),minutes_since_deal);
      return true;
    }
    return false;
};
ENUM_DEAL_REASON GetDealReason(ulong deal_ticket) {
    ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(deal_ticket, DEAL_REASON);
    return deal_reason;
}
ENUM_DEAL_ENTRY GetDealEntry(ulong deal_ticket) {
    ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
    return deal_entry;
}
ulong GetDealTime(ulong deal_ticket) {
   datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   return deal_time;
}
ulong GetMinutesSinceDeal(ulong deal_ticket) {
  ulong deal_time = GetDealTime(deal_ticket);
  ulong current_time = (long)TimeCurrent();
  ulong time_since_deal = current_time-deal_time;
  ulong time_since_deal_mins = time_since_deal / 60;
  return time_since_deal_mins;    
}
void closeExpiredPosition(ulong position_ticket, ulong minutes_since_deal, ulong max_position_time) {
  if (minutes_since_deal > max_position_time) {
    // PrintFormat("Minutes Since Last deal: %i \n Closing Position Ticket: %i",minutes_since_deal,position_ticket);   
    Trade.PositionClose(position_ticket);
  }
}
bool getPositionExists() {
  return PositionsTotal() > 0 ? true : false;
}
bool getBollingerWasInKeltner(int candleIndex, int lookback) {
  int count = 0;
  for (int i = candleIndex; i < lookback; i++) {
    if ((ValuesBollingerLower[i] > ValuesKeltnerLower[i]) || (ValuesBollingerUpper[i] < ValuesKeltnerUpper[i])) {
      count++;
    }
  }
  // if (count > 7) {
    // PrintFormat("High Compression...Bollinger inside keltner candles: %i out of last %i",count,lookback);
  // }
  return count > 0 ? true : false;
}
double getTailSize(int candleIndex) {
  double tailSize = 0;
  // candle is bearish, close is lower than open.
  // so tail is close - low.
  if (bearishCandle(candleIndex)) {
    tailSize = Rates[candleIndex].close - Rates[candleIndex].low;
  } else {
    tailSize = Rates[candleIndex].open - Rates[candleIndex].low;
  }
  return tailSize;
}
double getWickSize(int candleIndex) {
  double wickSize = 0;
  // if bearish candle, close is higher than open.
  // so wick is high - close.
  if (bearishCandle(candleIndex)) {
    wickSize = Rates[candleIndex].high - Rates[candleIndex].open;
  } else {
    wickSize = Rates[candleIndex].high - Rates[candleIndex].close;
  }
  return wickSize;
}
double getBodySize(int candleIndex) {
  return MathAbs(Rates[candleIndex].open - Rates[candleIndex].close);
}
double getCandleSize(int candleIndex) {
  return MathAbs(Rates[candleIndex].open - Rates[candleIndex].close);
}
double getTailWickSize(int candleIndex) {
  return getTailSize(candleIndex) + getWickSize(candleIndex);
}
bool isFvboBuySetup(int candleIndex) {
  return (
    ValuesBollingerLower[candleIndex+1] < ValuesKeltnerLower[candleIndex+1] //bollinger outside keltner
    && Rates[candleIndex+1].close < ValuesBollingerLower[candleIndex+1]     //candle closed outside bollinger
    && Rates[candleIndex+1].close < Rates[candleIndex+1].open               //bearish candle
    && Rates[candleIndex].close > Rates[candleIndex].open                   //next candle bullish
    && !fvbo_buy_setup                                                      //not already in a setup
 )           
  ? true : false;
}
bool isFvboSellSetup(int candleIndex) {
  return (
    ValuesBollingerUpper[candleIndex+1] > ValuesKeltnerUpper[candleIndex+1] //bollinger outside keltner
    && Rates[candleIndex+1].close > ValuesBollingerUpper[candleIndex+1]     //candle closed outside bollinger
    && Rates[candleIndex+1].close > Rates[candleIndex+1].open               //bullish candle
    && Rates[candleIndex].close < Rates[candleIndex].open                   //next candle bearish
    && !fvbo_sell_setup                                                     //not already in a setup
  )           
  ? true : false;
}
// Trading
void OpenBetterOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit, double lots, string comment) {
  // refactor TP to use candle Range or rVal
  int digits = Digits();
  price = NormalizeDouble(price, digits);
  stopLoss = NormalizeDouble(stopLoss, digits);
  takeProfit = NormalizeDouble(takeProfit, digits);
  // order expires at end of next candle
  datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
//  string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
//  PrintFormat("Called OpenBetterOrder.\n Digits: %i \n Parsed in... price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s",digits,price,stopLoss,takeProfit,ValuesBollingerMiddle[1],expiration_string);

  if (!Trade.OrderOpen(Symbol(), type, lots, 0, price, stopLoss,
      takeProfit,
      ORDER_TIME_SPECIFIED, expiration, comment)) {
    PrintFormat("Open Order failed for %s, %s, price=%f, sl=%f, tp=%f",
      Symbol(), EnumToString(type), price, stopLoss, takeProfit);
  }
}
bool bearishCandle(int candleIndex) {
  return Rates[candleIndex].close < Rates[candleIndex].open ? true : false;
}
bool bullishCandle(int candleIndex) {
  return Rates[candleIndex].close > Rates[candleIndex].open ? true : false;
}
// Utility functions
// Source: How to run MQL4 or MQL5 code only one time for each bar
bool IsNewBar() {
  static datetime previousBarTime = iTime(Symbol(), Period(), 0);
  datetime currentBarTime = iTime(Symbol(), Period(), 0);

  if (currentBarTime == previousBarTime)
    return false;
  previousBarTime = currentBarTime;
  return true;
}
double PointsToDouble(int points, string symbol = "") {
  if (symbol == "")
    symbol = Symbol();
  double value = (double) points * SymbolInfoDouble(symbol, SYMBOL_POINT);
  return value;
}
bool bbWasInKeltner(int n) {
  datetime bbWasInKeltnerTime;
  for (int i = n; i > 0; i--) {
    bbWasInKeltnerTime = iTime(Symbol(), Period(), i);

    PrintFormat("bbWasInKeltnerTime: %s", TimeToString(bbWasInKeltnerTime));
    PrintFormat("BBL: %f KCL: %f BBU: %f KCU: %f", ValuesBollingerLower[i], ValuesKeltnerLower[i], ValuesBollingerUpper[i], ValuesKeltnerUpper[i]);
    if (
      (ValuesBollingerLower[i] >= ValuesKeltnerLower[i]) || (ValuesBollingerUpper[i] <= ValuesKeltnerUpper[i])) {
      Print("bb inside keltner");
      return true;
    }
  }
  return false;
}
//+------------------------------------------------------------------+
//| INDICATORS, PATTERNS & SIGNALS                    |
//+------------------------------------------------------------------+
void DrawSignals(int candleIndex,int periods) {
  // drawDoubleTrouble(candleIndex);
  if (isBullishBarrierRSIATR(candleIndex,periods)) {drawBullishBarrierRSIATR(candleIndex);}
  // if (isBullishEngulfingBollinger(candleIndex)) {drawBullishEngulfingBollinger(candleIndex);}
  // if (isBearishEngulfingBollinger(candleIndex)) {drawBearishEngulfingBollinger(candleIndex);}
  // if (isBullishDoubleTroubleWithRSIFilter(candleIndex)) {drawBullishDoubleTroubleWithRSIFilter(candleIndex);}
  // if (isBearishDoubleTroubleWithRSIFilter(candleIndex)) {drawBearishDoubleTroubleWithRSIFilter(candleIndex);}
  // if (isBullishBarrier(candleIndex)) { drawBullishBarrier(candleIndex);}
  // if (isBearishBarrier(candleIndex)) { drawBearishBarrier(candleIndex);}
  // if (isBullishEuphoria(candleIndex)) { drawBullishEuphoria(candleIndex);}
  // if (isBearishEuphoria(candleIndex)) { drawBearishEuphoria(candleIndex);}
  // if (isInvertedHammer(candleIndex)) { drawInvertedHammer(candleIndex);}
  // if (isHammer(candleIndex)) { drawHammer(candleIndex);}
  // if (isMorningStar(candleIndex)) {drawMorningStar(candleIndex);}
  // if (isEveningStar(candleIndex)) {drawEveningStar(candleIndex);}
  // if (isDoji(candleIndex)) {drawDoji(candleIndex);};
  if (isIndecisionCandle(candleIndex,0.5)) {
    drawIndecisionCandle(candleIndex);
  };
  if (isFvboBuySetup(candleIndex) || isFvboSellSetup(candleIndex)) {
    drawFvboSetup(candleIndex);
  };
}
bool isHammer(int candleIndex) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);
  bool hasLargeTail = tailSize >= bodySize * 4.0;
  bool hasSmallWick = wickSize < bodySize * 0.5;
  return (hasLargeTail && hasSmallWick && Rates[candleIndex].close < Rates[candleIndex].open) ? true : false;
}
void drawFvboSetup(int candleIndex) {
  datetime setupTime = iTime(Symbol(), Period(), 1);
  if (isFvboBuySetup(candleIndex)) {
    // draw a green buy arrow at high
    ObjectCreate(0, "BuySetup" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
    ObjectSetString(0,"BuySetup" + setupTime,OBJPROP_TEXT,"FVBO");
    ObjectSetInteger(0, "BuySetup" + setupTime, OBJPROP_COLOR, clrBlue);
    ObjectSetDouble(0,"BuySetup" + setupTime,OBJPROP_ANGLE,90.0);
  } else if (isFvboSellSetup(candleIndex)) {
    ObjectCreate(0, "SellSetup" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
    ObjectSetString(0,"SellSetup" + setupTime,OBJPROP_TEXT,"FVBO");
    ObjectSetInteger(0, "SellSetup" + setupTime, OBJPROP_COLOR, clrRed);
    ObjectSetDouble(0,"SellSetup" + setupTime,OBJPROP_ANGLE,90.0);
  }
}
// Draw the hammer candlestick pattern on the chart
void drawHammer(int candleIndex) {
  // Draw a vertical line to represent the body of the hammer
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime hammerTime = iTime(Symbol(), Period(), 1);
  // Draw a circle to represent the lower shadow of the hammer
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
  double location = yHigh;
  clr=clrGreen;               // color
  ObjectCreate(0, "HammerLowerShadow" + hammerTime, OBJ_TEXT, 0, hammerTime, location);
  ObjectSetString(0,"HammerLowerShadow" + hammerTime,OBJPROP_TEXT,"HAMMER");
  ObjectSetString(0,"HammerLowerShadow" + hammerTime,OBJPROP_FONT,"Arial");
  ObjectSetInteger(0,"HammerLowerShadow" + hammerTime,OBJPROP_FONTSIZE,8);
  ObjectSetDouble(0,"HammerLowerShadow" + hammerTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0,"HammerLowerShadow" + hammerTime,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
  ObjectSetInteger(0, "HammerLowerShadow" + hammerTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}

void drawBearishDoubleTrouble(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishDoubleTroubleTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime, OBJ_TEXT, 0, bearishDoubleTroubleTime, location);
  ObjectSetString(0,"bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime,OBJPROP_TEXT,"DoubleTroubleBullishContinuation");
  ObjectSetDouble(0,"bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color
}
bool isDoji(int candleIndex) {
   return (Rates[candleIndex].close > Rates[candleIndex].open && Rates[candleIndex-1].close == Rates[candleIndex].open && Rates[candleIndex-1].close < Rates[candleIndex-1].open) ? true : false;
}
void drawDoji(int candleIndex) {
  // Draw a vertical line to represent the body of the doji
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime dojiTime = iTime(Symbol(), Period(), 1);
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
  if (Rates[candleIndex].close < Rates[candleIndex].open) {
  clr=clrRed;              // color  
  } else {
     clr=clrGreen;               // color 
  }
  ObjectCreate(0, "DojiLowerShadow" + dojiTime, OBJ_TEXT, 0, dojiTime, yLowerShadow);
  ObjectSetString(0,"DojiLowerShadow" + dojiTime,OBJPROP_TEXT,"DOJI");
  ObjectSetString(0,"DojiLowerShadow" + dojiTime,OBJPROP_FONT,"Arial");
  ObjectSetInteger(0,"DojiLowerShadow" + dojiTime,OBJPROP_FONTSIZE,8);
  ObjectSetDouble(0,"DojiLowerShadow" + dojiTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0,"DojiLowerShadow" + dojiTime,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
  ObjectSetInteger(0, "DojiLowerShadow" + dojiTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}
bool isInvertedHammer(int candleIndex) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);
  bool hasSmallTail = tailSize < bodySize * 0.5;
  bool hasLargeWick = wickSize >= bodySize * 4.0;
  return (hasSmallTail && hasLargeWick && Rates[candleIndex].close < Rates[candleIndex].open) ? true : false;
}
// Draw the hammer candlestick pattern on the chart
void drawInvertedHammer(int candleIndex) {
  // Draw a vertical line to represent the body of the hammer
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime invertedHammerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  clr=clrRed;          // color  
  ObjectCreate(0, "invertedHammerUpperShadow" + invertedHammerTime, OBJ_TEXT, 0, invertedHammerTime, location);
  ObjectSetString(0,"invertedHammerUpperShadow" + invertedHammerTime,OBJPROP_TEXT,"Inverted Hammer");
  ObjectSetDouble(0,"invertedHammerUpperShadow" + invertedHammerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "invertedHammerUpperShadow" + invertedHammerTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}
bool isMorningStar(int candleIndex) {
  return (
  Rates[candleIndex].close > Rates[candleIndex].open &&
  MathMax(Rates[candleIndex+1].close,Rates[candleIndex+1].open) < Rates[candleIndex].open &&
  MathMax(Rates[candleIndex+1].close,Rates[candleIndex+1].open) < Rates[candleIndex+2].close &&
  Rates[candleIndex+2].close < Rates[candleIndex+2].open
  ) ? true : false;
}
bool isEveningStar(int candleIndex) {
  return (
    Rates[candleIndex].close < Rates[candleIndex].open &&
    MathMin(Rates[candleIndex+1].close, Rates[candleIndex+1].open) > Rates[candleIndex].open &&
    MathMin(Rates[candleIndex+1].close,Rates[candleIndex+1].open) > Rates[candleIndex+2].close && 
    Rates[candleIndex+2].close > Rates[candleIndex+2].open
  ) ? true : false;
}
void drawMorningStar(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime morningStarTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "morningStarUpperShadow" + morningStarTime, OBJ_TEXT, 0, morningStarTime, location);
  ObjectSetString(0, "morningStarUpperShadow" + morningStarTime,OBJPROP_TEXT,"Morning Star");
  ObjectSetDouble(0, "morningStarUpperShadow" + morningStarTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"morningStarUpperShadow" + morningStarTime, OBJPROP_COLOR, clrGreen); // red because contrarian pattern
}
void drawEveningStar(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime eveningStarTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "eveningStarUpperShadow" + eveningStarTime, OBJ_TEXT, 0, eveningStarTime, location);
  ObjectSetString(0, "eveningStarUpperShadow" + eveningStarTime,OBJPROP_TEXT,"evening Star");
  ObjectSetDouble(0, "eveningStarUpperShadow" + eveningStarTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"eveningStarUpperShadow" + eveningStarTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isIndecisionCandle(int candleIndex, int tailWickMultiplier) {
  double tailWickSize = 0;
  double bodySize = 0;
  tailWickSize = getTailWickSize(candleIndex);
  bodySize = getBodySize(candleIndex);
  return tailWickSize * tailWickMultiplier >= bodySize ? true : false;
}
void drawIndecisionCandle(int candleIndex) {
     // Draw a vertical line to represent the body of the indecision
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime indecisionTime = iTime(Symbol(), Period(), 1);
  // Draw a circle to represent the lower shadow of the doji
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
  double location = yHigh;
  ObjectCreate(0, "IndecisionLowerShadow" + indecisionTime, OBJ_TEXT, 0, indecisionTime, location);
  //--- set the text
  ObjectSetString(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_TEXT,"INDECISION");
  //--- set text font
  ObjectSetString(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_FONT,"Arial");
  //--- set font size
  ObjectSetInteger(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_FONTSIZE,8);
  //--- set the slope angle of the text
  ObjectSetDouble(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0, "IndecisionLowerShadow" + indecisionTime, OBJPROP_COLOR, clrBlue); // Set color to red or any other color
}
bool isBearishEuphoria(int candleIndex) {
  return (
    Rates[candleIndex].open < Rates[candleIndex].close && //biggest bullish
    Rates[candleIndex+1].open < Rates[candleIndex+1].close && //bigger bullish
    Rates[candleIndex+2].open < Rates[candleIndex+2].close && //bullish
    Rates[candleIndex].close > Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close > Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
bool isBullishEuphoria(int candleIndex) {
  return (
    Rates[candleIndex].open > Rates[candleIndex].close && //biggest bearish
    Rates[candleIndex+1].open > Rates[candleIndex+1].close && //bigger bearish
    Rates[candleIndex+2].open > Rates[candleIndex+2].close && //bearish
    Rates[candleIndex].close < Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close < Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
void drawBullishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJ_TEXT, 0, bullishEuphoriaTime, location);
  ObjectSetString(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_TEXT,"Euphoria (L)");
  ObjectSetDouble(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBearishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJ_TEXT, 0, bearishEuphoriaTime, location);
  ObjectSetString(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_TEXT,"Euphoria (S)");
  ObjectSetDouble(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isBullishBarrier(int candleIndex) {
  int digits = Digits()-1;
  double low = NormalizeDouble(Rates[candleIndex].low,digits);
  double prev_low = NormalizeDouble(Rates[candleIndex+1].low,digits);
  double prev_prev_low = NormalizeDouble(Rates[candleIndex+2].low,digits);
  // double prev_low = Rates[candleIndex+1].low;
    // prev_low = MathRound(prev_low * MathPow(10, digits)) / MathPow(10, digits);
  // double prev_prev_low = Rates[candleIndex+2].low;
    // prev_prev_low = MathRound(prev_prev_low * MathPow(10, digits)) / MathPow(10, digits);
 return (
    Rates[candleIndex].close > Rates[candleIndex].open &&
    Rates[candleIndex+1].close < Rates[candleIndex+1].open &&
    Rates[candleIndex+2].close < Rates[candleIndex+2].open &&
    low == prev_low &&
    low == prev_prev_low
    // Rates[candleIndex].low == Rates[candleIndex+1].low &&
    // Rates[candleIndex].low == Rates[candleIndex+2].low
 ) ? true : false;
}
bool isBearishBarrier(int candleIndex) {
  int digits = Digits()-1;
  double high = NormalizeDouble(Rates[candleIndex].high,digits);
  double prev_high = NormalizeDouble(Rates[candleIndex+1].high,digits);
  double prev_prev_high = NormalizeDouble(Rates[candleIndex+2].high,digits);
 return (
    Rates[candleIndex].close < Rates[candleIndex].open &&
    Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
    Rates[candleIndex+2].close > Rates[candleIndex+2].open &&
    high == prev_high &&
    high == prev_prev_high
    // Rates[candleIndex].high == Rates[candleIndex+1].high &&
    // Rates[candleIndex].high == Rates[candleIndex+2].high
 ) ? true : false;
}
void drawBullishBarrier(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishBarrierTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishBarrierUpperShadow" + bullishBarrierTime, OBJ_TEXT, 0, bullishBarrierTime, location);
  ObjectSetString(0, "bullishBarrierUpperShadow" + bullishBarrierTime,OBJPROP_TEXT,"Barrier (L)");
  ObjectSetDouble(0, "bullishBarrierUpperShadow" + bullishBarrierTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishBarrierUpperShadow" + bullishBarrierTime, OBJPROP_COLOR, clrGreen); // red because contrarian pattern
}
void drawBearishBarrier(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime BearishBarrierTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "BearishBarrierUpperShadow" + BearishBarrierTime, OBJ_TEXT, 0, BearishBarrierTime, location);
  ObjectSetString(0, "BearishBarrierUpperShadow" + BearishBarrierTime,OBJPROP_TEXT,"Barrier (S)");
  ObjectSetDouble(0, "BearishBarrierUpperShadow" + BearishBarrierTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"BearishBarrierUpperShadow" + BearishBarrierTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isBullishDoubleTroubleWithRSIFilter(int candleIndex) {
 return (
 Rates[candleIndex].close > Rates[candleIndex].open &&
 Rates[candleIndex].close > Rates[candleIndex+1].close &&
 Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
 Rates[candleIndex].high - Rates[candleIndex].low > (2 * ValuesATR[2]) &&
 Rates[candleIndex].close - Rates[candleIndex].open > Rates[candleIndex+1].close - Rates[candleIndex+1].open &&  
 ValuesRSI[candleIndex] > 50
 ) ? true : false;
}
void drawBullishDoubleTroubleWithRSIFilter(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishDoubleTroubleWithRSIFilterTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime, OBJ_TEXT, 0, bullishDoubleTroubleWithRSIFilterTime, location);
  ObjectSetString(0,"bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime,OBJPROP_TEXT,"DoubleTroubleRSI");
  ObjectSetDouble(0,"bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime, OBJPROP_COLOR, clrGreen); // Set color to red or any other color
}
bool isBearishDoubleTroubleWithRSIFilter(int candleIndex) {
 return (
 Rates[candleIndex].close < Rates[candleIndex].open &&
 Rates[candleIndex].close < Rates[candleIndex+1].close &&
 Rates[candleIndex+1].close < Rates[candleIndex+1].open &&
 Rates[candleIndex].high - Rates[candleIndex].low > (2 * ValuesATR[2]) &&
 Rates[candleIndex].open - Rates[candleIndex].close > Rates[candleIndex+1].open - Rates[candleIndex+1].close &&  
 ValuesRSI[candleIndex] < 50
 ) ? true : false;
}
void drawBearishDoubleTroubleWithRSIFilter(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishDoubleTroubleWithRSIFilterTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime, OBJ_TEXT, 0, bearishDoubleTroubleWithRSIFilterTime, location);
  ObjectSetString(0,"bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime,OBJPROP_TEXT,"BearishDoubleTroubleRSI");
  ObjectSetDouble(0,"bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color
}
bool isBearishEngulfingBollinger(int candleIndex) {
  return (
 Rates[candleIndex].close < Rates[candleIndex].open &&
 Rates[candleIndex].open > Rates[candleIndex+1].close &&
 Rates[candleIndex].close < Rates[candleIndex+1].open &&
 Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
 Rates[candleIndex+2].close > Rates[candleIndex+2].open &&
 Rates[candleIndex].close > ValuesBollingerUpper[candleIndex]
  ) ? true : false;
}
bool isBullishEngulfingBollinger(int candleIndex) {
  return (
 Rates[candleIndex].close > Rates[candleIndex].open &&
 Rates[candleIndex].open < Rates[candleIndex+1].close &&
 Rates[candleIndex].close > Rates[candleIndex+1].open &&
 Rates[candleIndex+1].close < Rates[candleIndex+1].open && //bearish
 Rates[candleIndex+2].close < Rates[candleIndex+2].open && //bearish
 Rates[candleIndex].close < ValuesBollingerLower[candleIndex]
  ) ? true : false;
}
void drawBullishEngulfingBollinger(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishEngulfingBollingerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime, OBJ_TEXT, 0, bullishEngulfingBollingerTime, location);
  ObjectSetString(0, "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime,OBJPROP_TEXT,"EngulfingBollinger (L)");
  ObjectSetDouble(0, "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBearishEngulfingBollinger(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishEngulfingBollingerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime, OBJ_TEXT, 0, bearishEngulfingBollingerTime, location);
  ObjectSetString(0, "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime,OBJPROP_TEXT,"EngulfingBollinger (S)");
  ObjectSetDouble(0, "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime, OBJPROP_COLOR, clrRed); //green because contrarian pattern
}
bool isBullishBarrierRSIATR(int candleIndex,int periods) {
  if (isBullishBarrier(candleIndex)) {
    double rsi_atr = 0;
    for (int i = candleIndex; i < periods; i++) {
      rsi_atr += ValuesRSI[candleIndex] / ValuesATR[candleIndex+1];
    }
    rsi_atr = NormalizeDouble((rsi_atr/periods),Digits());
    if (rsi_atr < 20) {
      PrintFormat("BULLISHBARRIERRSIATRFOUND!");
      return true;
    }
  }
  return false;
}
void drawBullishBarrierRSIATR(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishBarrierRSIATRTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime, OBJ_TEXT, 0, bullishBarrierRSIATRTime, location);
  ObjectSetString(0, "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime,OBJPROP_TEXT,"BarrierRSIATR (L)");
  ObjectSetDouble(0, "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
