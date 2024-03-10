#define app_name "Newest Strategy"
#define app_magic 301124
#include <Trade/Trade.mqh>

CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

// basic expert uses fixed order size
input double InpOrderSize = 0.1; // order size in lots
input int InpMagic = app_magic; // Magic number
input string InpTradeComment = app_name; // Trade comment

// Indicator inputs
input int InpBollingerPeriod = 20; // Bollinger period
input double InpBollingerDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; // Bollinger applied price

// Entry exit settings
input int InpEntryGapPoints = 10; // Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; // SL gap points, 50pts=0.5pips
input int InpEMAPeriod = 20; //  Period of EMA
input int InpATRPeriod = 20; //  Period of ATR
input double InpATRFactor = 2.0; //  ATR multiplier
input bool InpShowLabel = false; //  show price of level
input bool InpDrawSignals = true;
input int InpKeltnerLookback = 10;
input int InpMaxPositionTime = 50;
input int InpWaitTime = 50;

// Indicator handles
int HandleBollinger;
int HandleKeltner;
int HandleATR;
double ValuesBollingerUpper[];
double ValuesBollingerLower[];
double ValuesBollingerMiddle[];
double ValuesKeltnerUpper[];
double ValuesKeltnerLower[];
double ValuesATR[];

MqlRates Rates[];
MqlTick currentTick;
double currentOpen;
double currentClose;
double currentHigh;
double currentLow;
double prevOpen;
double prevClose;
double prevHigh;
double prevLow;
double sl;
double tp;
double price;
double EntryGap;
double StopLossGap;
bool tradeAllowed;
ENUM_ORDER_TYPE currentOrderType;
int counter;
bool breakoutHigh;
bool buy_reversal;
bool sell_reversal;
bool buy_setup;
bool sell_setup;
int buy_counter;
int sell_counter;
bool bollinger_was_in_keltner;
bool position_exists;
bool fvbo_buy_setup;
bool fvbo_sell_setup;
color clr;
int bullishDoubleTroubleCount;
bool waiting_before_new_order;

// Initialisation
int OnInit() {

  string keltner = "Keltner Channel.ex5";
  HandleKeltner = iCustom(Symbol(), Period(),keltner,InpEMAPeriod,InpATRPeriod,InpATRFactor,InpShowLabel);
  HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
  HandleATR = iATR(Symbol(),Period(),InpATRPeriod);
  ArraySetAsSeries(ValuesBollingerUpper, true);
  ArraySetAsSeries(ValuesBollingerLower, true);
  ArraySetAsSeries(ValuesBollingerMiddle, true);
  ArraySetAsSeries(ValuesKeltnerUpper, true);
  ArraySetAsSeries(ValuesKeltnerLower, true);
  ArraySetAsSeries(ValuesATR,true);
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
    DrawSignals(1);
    drawDoubleTrouble(1);
  }
  ulong last_deal = GetLastDealTicket();
  ENUM_DEAL_REASON last_deal_reason = GetDealReason(last_deal);
  ENUM_DEAL_ENTRY last_deal_entry = GetDealEntry(last_deal);
  ulong minutes_since_last_deal = GetMinutesSinceDeal(last_deal);
  ulong max_position_time = InpMaxPositionTime; //input-ify
  ulong wait_time = InpWaitTime; //input-ify
  position_exists = getPositionExists(); 
  //these values called inside setup definitions

  waiting_before_new_order = GetWaitingBeforeNewOrder(last_deal_entry,wait_time,minutes_since_last_deal);
  bollinger_was_in_keltner = getBollingerWasInKeltner(0,InpKeltnerLookback);

  if (position_exists) {
    ulong position_ticket = PositionGetTicket(0);
    closeExpiredPosition(position_ticket,minutes_since_last_deal,max_position_time);
  }
  // PrintFormat("last_deal: %i \n last_deal_reason %s \n last_deal_entry: %s \n minutes_since_last_deal: %i",last_deal,EnumToString(last_deal_reason),EnumToString(last_deal_entry),minutes_since_last_deal);

  if (isFvboBuySetup(1)) {
    PrintFormat("FVBO Buy!: BBL[2]: %f KCL[2]: %f \n Rates[2].close: %f BBL[2]: %f \n Rates[2].close: %f Rates[2].open %f \n Rates[1].close %f Rates[1].open %f", 
    ValuesBollingerLower[2],ValuesKeltnerLower[2],Rates[2].close, ValuesBollingerLower[2],Rates[2].close, Rates[2].open, Rates[1].close, Rates[1].open); 
    fvbo_buy_setup = true;
    buy_counter = 3;
  }
  //check if we can trade
  if (position_exists || waiting_before_new_order || !bollinger_was_in_keltner) {
    fvbo_buy_setup = false;
    buy_counter = 0;
    if (!bollinger_was_in_keltner) {
      PrintFormat("Cannot do trade: bollinger_was_in_keltner: %i", (string)bollinger_was_in_keltner);
    }
    if (waiting_before_new_order) {
      PrintFormat("Too soon to place new order. minutes_since_last_deal %i",minutes_since_last_deal);
    }
    //PrintFormat("Cannot do buy trade. \n position_exists: %s \n waiting_before_new_order: %s \n bollinger_was_in_keltner: %s", (string)position_exists,(string)waiting_before_new_order,(string)bollinger_was_in_keltner);
  }
  //place an order while counter not expired, we have no open positions and we're not waiting before a new order
  if (fvbo_buy_setup && buy_counter >= 0) {
      price = Rates[1].high;
      sl = Rates[1].low-InpStopLossGapPoints*_Point;
      tp = price + rVal;
      int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
      string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      PrintFormat("Before we open an order, our values are... \n Digits: %i \n Parsed in...\n price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s \n buy_counter: %i",digits,price,sl,tp,ValuesBollingerMiddle[1],expiration_string,buy_counter);
      //if high + rval is still less than the midline
      if (tp < ValuesBollingerMiddle[1]) {
        OpenBetterOrder(ORDER_TYPE_BUY_STOP,price,sl,tp,InpOrderSize,InpTradeComment);
      }
    buy_counter--;
    //buy_counter expired
   if (buy_counter == 0) {
      fvbo_buy_setup = false;
      buy_counter = 0;
      Print("Buy counter expired. Setting buy_counter to 0 and fvbo_buy_setup to false");
   }
   //we must have 
   if (position_exists) {
    Print("Have an open position. Setting buy_counter to 0 and fvbo_buy_setup to false");
    buy_counter = 0;
    fvbo_buy_setup = false;
   }
  }

  if (isFvboSellSetup(1)) {
    PrintFormat("FVBO SELL!: BBU[2]: %f KCU[2]: %f \n Rates[2].close: %f BBU[2]: %f \n Rates[2].close: %f Rates[2].open %f \n Rates[1].close %f Rates[1].open %f", 
    ValuesBollingerUpper[2],ValuesKeltnerUpper[2],Rates[2].close, ValuesBollingerUpper[2],Rates[2].close, Rates[2].open, Rates[1].close, Rates[1].open); 
    fvbo_sell_setup = true;
    sell_counter = 3;
  }
  //check if we can trade
  if (position_exists || waiting_before_new_order || !bollinger_was_in_keltner) {
    fvbo_sell_setup = false;
    sell_counter = 0;
    if (!bollinger_was_in_keltner) {
      PrintFormat("Cannot do trade: bollinger_was_in_keltner: %i", (string)bollinger_was_in_keltner);
    }
    if (waiting_before_new_order) {
      PrintFormat("Too soon to place new order. minutes_since_last_deal %i",minutes_since_last_deal);
    }
    //PrintFormat("Cannot do sell trade. \n position_exists: %s \n waiting_before_new_order: %s \n bollinger_was_in_keltner: %s",(string)position_exists,(string)waiting_before_new_order,(string)bollinger_was_in_keltner);
  }
  if (fvbo_sell_setup && sell_counter >= 0) {
      price = Rates[1].low;
      sl = Rates[1].high+InpStopLossGapPoints*_Point;
      tp = price - rVal;
      int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
      string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      PrintFormat("Before we open an order, our values are... \n Digits: %i \n Parsed in...\n price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s \n buy_counter: %i",digits,price,sl,tp,ValuesBollingerMiddle[1],expiration_string,buy_counter);
      //validate trade
      if (tp < ValuesBollingerMiddle[1]) {
          
      }
      if (tp > ValuesBollingerMiddle[1]) {
        OpenBetterOrder(ORDER_TYPE_SELL_STOP,price,sl,tp,InpOrderSize,InpTradeComment);
      }
    sell_counter--;
    //sell_counter expired
        //buy_counter expired
   if (sell_counter == 0) {
      fvbo_sell_setup = false;
      sell_counter = 0;
      Print("Sell counter expired. Setting sell_counter to 0 and fvbo_sell_setup to false");
   }
   //we must have 
   if (position_exists) {
    Print("Have an open position. Setting sell_counter to 0 and fvbo_sell_setup to false");
    sell_counter = 0;
    fvbo_sell_setup = false;
   }
  }
}
  // // bollingerWasInKeltner = false;
  // bollingerWasInKeltner = getBollingerWasInKeltner(0,numCandles);
  // fvbo_sell_setup = isFvboSellSetup(0);
  // fvbo_buy_setup = isFvboSellSetup(0);
  // //if candle closed outside upper bollinger 
  // if (isFvboSellSetup(0) 
  // && !sell_setup 
  // && bollingerWasInKeltner
  // && !positionExists
  // ) {
  //   sell_counter = 5;
  //   PrintFormat("Close broken upper BB. Short setup. Looking for reversal. Setting sell_counter to : %i", sell_counter);
  //   sell_setup = true;
  //   sell_reversal = false;
  //   buy_setup = false;
  // }
  /*
  if (Rates[1].close < ValuesBollingerLower[1] && !buy_setup && PositionsTotal() == 0 && BBLowerBelowKCLower(1)) {
    buy_counter = 5;
    PrintFormat("Close broken lower BB. Long setup Setting buy_counter to : %i", buy_counter);
    PrintFormat("KCU: %f",ValuesKeltnerLower[1]);
    PrintFormat("BBU: %f",ValuesBollingerLower[1]);
    buy_setup = true;
    buy_reversal = false;
    sell_setup = false;
  }
  */

  //closed outside 
  /*
  if (Rates[1].close > ValuesBollingerUpper[1] 
  && Rates[1].close > Rates[2].close 
  && PositionsTotal() == 0 
  && BBUpperAboveKCUpper(1)) {
    Print("2 consecutive short setups, resetting sell counter so we don't expire too soon.");
    sell_counter = 5;
    sell_setup = true;
    sell_reversal = false;
    buy_setup = false;
  }
  */
  /*
  //closed outside 
  if (Rates[1].close < ValuesBollingerLower[1] && Rates[1].close < Rates[2].close && PositionsTotal() == 0 && BBLowerBelowKCLower(1)) {
    Print("2 consecutive long setups, resetting buy counter so we don't expire too soon.");
    buy_counter = 5;
    buy_setup = true;
    buy_reversal = false;
    sell_setup = false;
  }
  */




   //POSITION_TIME
  // CHECK LAST DEAL TIME & REASON.
  // ulong last_deal = GetLastDealTicket();
  // long deal_time_msc = HistoryDealGetInteger(last_deal, DEAL_TIME_MSC);
  // long deal_time_current = TimeCurrent() * 1000;
  // long time_since_last_deal_mins = (deal_time_current - deal_time_msc) / (1000 * 60);
  // long minimum_wait_for_new_deal_mins = 30;
  // long max_position_time = 50;
  // long min_position_time = 10;
/*
  if (HistoryDealSelect(last_deal)) {
    // Determine if it was a TP or SL, whether we entered or exited.
    ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON) HistoryDealGetInteger(last_deal, DEAL_REASON);
    ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(last_deal,DEAL_ENTRY);
    PrintFormat("dealEntry: %s", EnumToString(dealEntry));
    PrintFormat("time_since_last_deal_mins: %i", time_since_last_deal_mins);
    PrintFormat("deal_time_current: %i", deal_time_current);
      
      //Minimum wait time
    if (dealReason == DEAL_REASON_TP || dealReason == DEAL_REASON_SL) {
      //can't place another deal for 50 mins after sl or tp was triggered
      if (time_since_last_deal_mins < minimum_wait_for_new_deal_mins) {
        PrintFormat("TIME SINCE LAST %s : %i mins", EnumToString(dealReason), time_since_last_deal_mins);
        PrintFormat("Too soon to place another deal. Reset setups & reversals.");
        buy_setup = false;
        buy_reversal = false;
        sell_setup = false;
        sell_reversal = false;
      }
    }
    if (dealEntry == DEAL_ENTRY_IN && PositionsTotal() > 0) {
          ulong positionTicket = PositionGetTicket(0);      
          PrintFormat("Position with ticket: %i has been open for %i",positionTicket,time_since_last_deal_mins);
          if (time_since_last_deal_mins > max_position_time) {
            PrintFormat("We've had %i positions open for %i mins. Time to close the of ticket %i.",PositionsTotal(),time_since_last_deal_mins,positionTicket);
            Trade.PositionClose(positionTicket);
            PrintFormat("Positions total: %i",PositionsTotal());
          }
    }
  } 
  */  
/*
  /////HANDLE SELL SETUP
  if (sell_setup && tradeAllowed) {
    if (!sell_reversal) {
      PrintFormat("...waiting for  reversal.  %i candles left.", sell_counter);
    }

    // check for reversal while sell_counter > 0
    if (sell_counter > 0) {
      // if candle closed lower and we haven't yet encounted a reversal
//      if (sell_reversal) {
//        if (Rates[1].low > Rates[2].low) {
          //                    PrintFormat("Rates[1].low is %f \nhigher than \nRates[2].low. %f Returning.",Rates[1].low,Rates[2].low);
//          PrintFormat("No lower low. Sell counter is %i . Decrementing sell_counter by 1 and moving on to the next candle.", sell_counter);
//        }
        if (Rates[1].low <= Rates[2].low || sell_reversal) {
          price = currentTick.bid; // look at current ask price
          PrintFormat("Trying to place order at %f", Rates[1].low);
          PrintFormat("Found a lower low in Rates[1].low: %f Rates[2].low %f", Rates[1].low, Rates[2].low);

          if ((price >= Rates[1].low && Rates[1].low - rVal >= ValuesBollingerMiddle[1]) || sell_reversal) {
            price = Rates[1].low;
            // rVal = MathAbs(Rates[1].high - Rates[1].low) * 1.2;
            sl = Rates[1].high + 25 * _Point; // set sl price to strike - stop loss gap
            tp = Rates[1].low - rVal;
            if (PositionsTotal() == 0 && tp >= ValuesBollingerMiddle[1]) {
              if (!bollingerWasInKeltner) {
                PrintFormat("Cannot open sell order, no compressed volatility for the last %i candles. Setting sell_setup to false.", numCandles);
                sell_setup = false;
                sell_reversal = false;
              }
              if (sell_setup){
                OpenBetterOrder(ORDER_TYPE_SELL_STOP, price, sl, tp, InpOrderSize, InpTradeComment); // todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
            }
          }
          if (currentLow - candleRange < ValuesBollingerMiddle[1]) {
            PrintFormat("BUT RR is Abs(%f - %f) * 1.2 = %f so less than required %f", Rates[1].high, Rates[1].low, rVal, BBUpperRange); //this is fucked
          }
        }
      }
        if (!sell_reversal && Rates[1].close < Rates[2].close) {
        sell_reversal = true;
        sell_counter = 5; // reset the counter
        PrintFormat("Found reversal. Re-setting sell_counter to %i ", sell_counter);
      }
    }
    sell_counter--;
    if (sell_counter <= 0) {
      Print("Search for a SELL EXPIRED");
      sell_setup = false;
      sell_reversal = false;
    }
  }
  ////////////////////////////////////////////HANDLE BUY
  if (buy_setup && tradeAllowed) {
    if (!buy_reversal) {
      PrintFormat("In a BUY setup waiting for reversal. Looking at next %i candles.", buy_counter);
    }
    if (buy_reversal) {
      PrintFormat("In a BUY setup, reversal was found. Looking at %i more candles.", buy_counter);
    }

    PrintFormat("Rates[1].close: %f", Rates[1].close);
    PrintFormat("Rates[2].close: %f", Rates[2].close);
    if (buy_counter > 0) {

      if (buy_reversal) {

        if (Rates[1].high < Rates[2].high) {
          //PrintFormat("Rates[1].high is %f \nlower than \nRates[2].high. %f Returning.",Rates[1].high,Rates[2].high);
          PrintFormat("No higher high, buy_counter is %i . Decrementing buy counter by 1 and moving on the next candle.", buy_counter);
        }
        if ((Rates[1].high >= Rates[2].high) || buy_reversal) {
          if ((price <= currentHigh && currentHigh + rVal <= ValuesBollingerMiddle[1]) || buy_reversal) {
            price = Rates[1].high;
            PrintFormat("Trying to place order at previous high: %f", Rates[1].high);
            //rVal = MathAbs(Rates[1].high - Rates[1].low) * 1.2;
            sl = Rates[1].low - 25 * _Point; // set sl price to strike - stop loss gap
            tp = Rates[1].high + rVal;
            if (PositionsTotal() == 0 && tp <= ValuesBollingerMiddle[1]) {
              if (!bollingerWasInKeltner) {
                PrintFormat("Cannot open buy order, no compressed volatility for the last %i candles. Setting buy_setup to false.", numCandles);
                buy_setup = false;
                buy_reversal = false;
              }
              if (buy_setup) {
                OpenBetterOrder(ORDER_TYPE_BUY_STOP, price, sl, tp, InpOrderSize, InpTradeComment); // todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
              }
            }
            /////
          } else if (currentHigh + candleRange > ValuesBollingerMiddle[1]) {
            PrintFormat("BUT RR is Abs(%f - %f) * 1.2 = %f so less than required %f", Rates[1].high, Rates[1].low, rVal, BBLowerRange); //this is fucked
          }
        }
      }
    // if candle closed lower and we haven't encounted a reversal
      if (Rates[1].close > Rates[2].close && !buy_reversal) {
        buy_reversal = true;
        buy_counter = 5;
        PrintFormat("Found first reversal candle. Setting buy_counter to %i ", buy_counter);
      }


    }
    buy_counter--;
    if (buy_counter <= 0) {
      Print("Search for a BUY EXPIRED");
      buy_setup = false;
      buy_reversal = false;
    }
  }
*/
//---UTILS---//
bool GetWaitingBeforeNewOrder(ENUM_DEAL_ENTRY deal_entry, ulong wait_time, ulong minutes_since_deal) {
    if (deal_entry == DEAL_ENTRY_OUT && minutes_since_deal < wait_time) {
      PrintFormat("Minutes since last %s : %i",EnumToString(deal_entry),minutes_since_deal);
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
    PrintFormat("Minutes Since Last deal: %i \n Closing Position Ticket: %i",minutes_since_deal,position_ticket);   
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
  if (count > 7) {
    PrintFormat("High Compression...Bollinger inside keltner candles: %i out of last %i",count,lookback);
  }
  return count > 0 ? true : false;
}
bool BBUpperAboveKCUpper(int candleIndex) {
  return ValuesBollingerUpper[candleIndex] >= ValuesKeltnerUpper[candleIndex] ? true : false;
}
bool BBLowerBelowKCLower(int candleIndex) {
  return ValuesBollingerLower[candleIndex] <= ValuesKeltnerLower[candleIndex] ? true : false;
}
bool closeBelowBBUpper(int candleIndex) {
  return Rates[candleIndex].close <= ValuesBollingerUpper[candleIndex] ? true : false;
}
bool openAboveBBUpper(int candleIndex) {
  return Rates[candleIndex].open > ValuesBollingerUpper[candleIndex] ? true : false;
}
bool closeAboveBBLower(int candleIndex) {
  return Rates[candleIndex].close >= ValuesBollingerLower[candleIndex] ? true : false;
}
bool openBelowBBLower(int candleIndex) {
  return Rates[candleIndex].open < ValuesBollingerLower[candleIndex] ? true : false;
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
  int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
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
bool BollingerBelowKeltner(int candleIndex) {
  return ValuesBollingerLower[candleIndex] < ValuesKeltnerLower[candleIndex] ? true : false;
}
bool BollingerAboveKeltner(int candleIndex) {
  return ValuesBollingerUpper[candleIndex] > ValuesKeltnerUpper[candleIndex] ? true : false;
}
bool CloseAboveBollinger(int candleIndex) {
  return Rates[candleIndex].close >= ValuesBollingerUpper[candleIndex] ? true : false;
}
bool CloseBelowBollinger(int candleIndex) {
  return Rates[candleIndex].close <= ValuesBollingerLower[candleIndex] ? true : false;
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
void DrawSignals(int candleIndex) {
  drawDoubleTrouble(candleIndex);
  if (isBullishEuphoria(candleIndex)) { drawBullishEuphoria(candleIndex);}
  if (isBearishEuphoria(candleIndex)) { drawBearishEuphoria(candleIndex);}
  if (isInvertedHammer(candleIndex)) { drawInvertedHammer(candleIndex);}
  if (isHammer(candleIndex)) { drawHammer(candleIndex);}
  if (isMorningStar(candleIndex)) {drawMorningStar(candleIndex);}
  if (isEveningStar(candleIndex)) {drawEveningStar(candleIndex);}
  if (isDoji(candleIndex)) {
    drawDoji(candleIndex);
  };
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
void drawDoubleTrouble(int candleIndex) {
  if ((Rates[candleIndex].high - Rates[candleIndex].low) > ValuesATR[candleIndex]) {
      double atr = ValuesATR[candleIndex];
      double candleRange = MathAbs(Rates[candleIndex].high-Rates[candleIndex].low);
      double atrTarget = atr*2;
      if (candleRange > atrTarget) {
         if (Rates[candleIndex].close > Rates[candleIndex].open && Rates[candleIndex].close > Rates[candleIndex+1].close &&
            Rates[candleIndex+1].close > Rates[candleIndex+1].open && (Rates[1].close-Rates[1].open) < (Rates[candleIndex+1].close-Rates[candleIndex+1].open)) { 
            drawBullishDoubleTrouble(candleIndex); 
         }
         if (Rates[candleIndex].close < Rates[candleIndex].open && Rates[candleIndex].close < Rates[candleIndex+1].close &&
            Rates[candleIndex+1].close < Rates[candleIndex+1].open && (Rates[candleIndex].open-Rates[candleIndex].close) > (Rates[candleIndex+1].open-Rates[candleIndex+1].close)) {
            drawBearishDoubleTrouble(candleIndex);
         }
   }
  }
}
void drawBullishDoubleTrouble(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishDoubleTroubleTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bullishDoubleTroubleUpperShadow" + bullishDoubleTroubleTime, OBJ_TEXT, 0, bullishDoubleTroubleTime, location);
  ObjectSetString(0,"bullishDoubleTroubleUpperShadow" + bullishDoubleTroubleTime,OBJPROP_TEXT,"Double Trouble");
  ObjectSetDouble(0,"bullishDoubleTroubleUpperShadow" + bullishDoubleTroubleTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bullishDoubleTroubleUpperShadow" + bullishDoubleTroubleTime, OBJPROP_COLOR, clrGreen); // Set color to red or any other color
}
void drawBearishDoubleTrouble(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishDoubleTroubleTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime, OBJ_TEXT, 0, bearishDoubleTroubleTime, location);
  ObjectSetString(0,"bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime,OBJPROP_TEXT,"Double Trouble");
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
    Rates[candleIndex].open > Rates[candleIndex].close &&
    Rates[candleIndex+1].open > Rates[candleIndex+1].close &&
    Rates[candleIndex+2].open > Rates[candleIndex+2].close &&
    Rates[candleIndex].close < Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close < Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
bool isBullishEuphoria(int candleIndex) {
  return (
    Rates[candleIndex].open < Rates[candleIndex].close &&
    Rates[candleIndex+1].open < Rates[candleIndex+1].close &&
    Rates[candleIndex+2].open < Rates[candleIndex+2].close &&
    Rates[candleIndex].close > Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close > Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
void drawBearishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJ_TEXT, 0, bearishEuphoriaTime, location);
  ObjectSetString(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_TEXT,"Euphoria");
  ObjectSetDouble(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBullishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJ_TEXT, 0, bullishEuphoriaTime, location);
  ObjectSetString(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_TEXT,"Euphoria");
  ObjectSetDouble(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
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