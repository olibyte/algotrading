#define app_name "Newest Strategy"
#define app_magic 301124
#include <Trade/Trade.mqh>

CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

// basic expert uses fixed order size
input double InpOrderSize = 0.1; // order size in lots
// Trades also have a magic number and a comment
input int InpMagic = app_magic; // Magic number
input string InpTradeComment = app_name; // Trade comment
// Indicator inputs
input int InpBollingerPeriod = 20; // Bollinger period
input double InpBollingerDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; // Bollinger applied price
input int InpKeltnerPeriod = 20; // Keltner Channel period
input double InpKeltnerMultiplier = 1.5; // Keltner Channel Multiplier
input ENUM_MA_METHOD InpKeltnerMAMethod = MODE_EMA; // Keltner Channel
input ENUM_APPLIED_PRICE InpKeltnerAppliedPrice = PRICE_CLOSE; // Keltner applied price
// Entry exit settings
input int InpEntryGapPoints = 10; // Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; // SL gap points, 50pts=0.5pips
input int InpEMAPeriod = 20; //  Period of EMA
input int InpATRPeriod = 20; //  Period of ATR
input double InpATRFactor = 20; //  ATR multiplier
input bool InpShowLabel = false; //  show price of level

// Indicator handles
int HandleBollinger;
int HandleKeltner;
double ValuesBollingerUpper[];
double ValuesBollingerLower[];
double ValuesBollingerMiddle[];
double ValuesKeltnerUpper[];
double ValuesKeltnerLower[];

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

ENUM_ORDER_TYPE currentOrderType;
int counter;
bool breakoutHigh;
bool buy_reversal;
bool sell_reversal;
bool buy_setup;
bool sell_setup;
int buy_counter;
int sell_counter;
bool bollingerWasInKeltner;

// Initialisation
int OnInit() {

  HandleKeltner = iCustom(Symbol(), Period(), "Keltner Channel.ex5", InpEMAPeriod, InpATRPeriod, InpATRFactor, InpShowLabel);
  HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
  ArraySetAsSeries(ValuesBollingerUpper, true);
  ArraySetAsSeries(ValuesBollingerLower, true);
  ArraySetAsSeries(ValuesBollingerMiddle, true);
  ArraySetAsSeries(ValuesKeltnerUpper, true);
  ArraySetAsSeries(ValuesKeltnerLower, true);
  ArraySetAsSeries(Rates, true);

  EntryGap = PointsToDouble(InpEntryGapPoints);
  StopLossGap = PointsToDouble(InpStopLossGapPoints);

  Trade.SetExpertMagicNumber(InpMagic);

  return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {
  IndicatorRelease(HandleBollinger);
  IndicatorRelease(HandleKeltner);
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+

// void OnTrade()
// {
//     // //--- receive the last deal's ticket from week's trading history
//     // ulong last_deal = GetLastDealTicket();
//     // if (HistoryDealSelect(last_deal))
//     // {
//     //     ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(last_deal, DEAL_REASON);
//     //     if (
//     //         dealReason == DEAL_REASON_TP ||
//     //         dealReason == DEAL_REASON_SL)
//     //     {
//     //         PrintFormat("Last deal was a %s",EnumToString(dealReason));
//     //     }
//     //     long last_deal_entry = HistoryDealGetInteger(last_deal, DEAL_ENTRY);
//     //     long deal_time_msc = HistoryDealGetInteger(last_deal, DEAL_TIME_MSC);
//     //     long deal_time_current = TimeCurrent();
//     //     deal_time_current = deal_time_current * 1000;
//     //     long time_since_last_deal_mins = (deal_time_current - deal_time_msc) / (1000 * 60);
//         //PrintFormat("TIME SINCE LAST DEAL MSC %i ", time_since_last_deal_mins);
//     // }
//     // else {
//     //     PrintFormat("HistoryDealSelect() failed for #%d. Eror code=%d",
//     //                 last_deal, GetLastError());
//     // }
// }
void OnTick() {
  if (!IsNewBar())
    return; // still looking at same bar
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

  sl = 0;
  price = 0;
  tp = 0;
  currentHigh = Rates[1].high;
  currentLow = Rates[1].low;

  double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits); // LEARN MQL5 85
  double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits); // LEARN MQL5 85

  // RiskReturn based on candle extremum and BB range.
  double candleRange = MathAbs(Rates[1].high - Rates[1].low);
  double rVal = candleRange * 1.2;
  double bodySize = MathAbs(Rates[1].open - Rates[1].close);
  double BBMidRange = MathAbs(ValuesBollingerUpper[1] - ValuesBollingerMiddle[1]);
  bool candleSizeInRange = candleRange * 2 <= BBMidRange;

  bollingerWasInKeltner = false;

  if (!SymbolInfoTick(_Symbol, currentTick)) {
    Print("Failed to get current tick");
    return;
  }
  for (int i = 0; i < numCandles; i++) {

    if ((ValuesBollingerLower[i] - ValuesKeltnerLower[i] >= 0) || (ValuesKeltnerUpper[i] - ValuesBollingerUpper[i] >= 0)) {
      bollingerWasInKeltner = true;
      break;
    }
  }

  if (Rates[1].close > ValuesBollingerUpper[1] && !sell_setup && PositionsTotal() == 0) {
    sell_counter = 5;
    PrintFormat("Close broken upper BB. Short setup. Looking for reversal. Setting sell_counter to : %i", sell_counter);
    sell_setup = true;
    sell_reversal = false;
    buy_setup = false;
  }
  if (Rates[1].close < ValuesBollingerLower[1] && !buy_setup && PositionsTotal() == 0) {
    buy_counter = 5;
    PrintFormat("Close broken lower BB. Long setup Setting buy_counter to : %i", buy_counter);
    buy_setup = true;
    buy_reversal = false;
    sell_setup = false;
  }
  //closed outside 
  if (Rates[1].close > ValuesBollingerUpper[1] && Rates[1].close > Rates[2].close && PositionsTotal() == 0) {
    Print("2 consecutive short setups, resetting sell counter so we don't expire too soon.");
    sell_counter = 5;
    sell_setup = true;
    sell_reversal = false;
    buy_setup = false;
  }
  //closed outside 
  if (Rates[1].close < ValuesBollingerLower[1] && Rates[1].close < Rates[2].close && PositionsTotal() == 0) {
    Print("2 consecutive long setups, resetting buy counter so we don't expire too soon.");
    buy_counter = 5;
    buy_setup = true;
    buy_reversal = false;
    sell_setup = false;
  }

  // CHECK LAST DEAL TIME & REASON.
  ulong last_deal = GetLastDealTicket();
  long deal_time_msc = HistoryDealGetInteger(last_deal, DEAL_TIME_MSC);
  long deal_time_current = TimeCurrent() * 1000;
  long time_since_last_deal_mins = (deal_time_current - deal_time_msc) / (1000 * 60);
  long minimum_wait_for_new_deal_mins = 50;
  long max_position_time = 50;
  long min_position_time = 10;

  if (HistoryDealSelect(last_deal)) {
    // Determine if it was a TP or SL.
    ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON) HistoryDealGetInteger(last_deal, DEAL_REASON);
    //PrintFormat("LAST DEAL REASON: %s ",EnumToString(dealReason));

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
    //IF WE HAVE A POSITION OPEN, KEEP IT OPEN FOR A MINIMUM OF 10MIN & MAX OF 50MIN
    if (PositionsTotal() > 0) {
      sell_setup = false;
      buy_setup = false;
      buy_reversal = false;
      sell_reversal = false;
      PrintFormat("Positions total is %i. Resetting setups & reversals.", PositionsTotal());
      if (time_since_last_deal_mins < min_position_time) {
        //CAN'T CLOSE A POSITION
        PrintFormat("Shouldn't close position, it's only been open for %i mins.", time_since_last_deal_mins);
      }
      if (time_since_last_deal_mins > max_position_time) {
        PrintFormat("Last deal was not a SL or TP, is was a reason %s %i mins ago. Closing position.", EnumToString(dealReason), time_since_last_deal_mins);
        Trade.PositionClose(Symbol());
      }
    }
  }
  /////HANDLE SELL SETUP
  if (sell_setup) {
    if (!sell_reversal) {
      PrintFormat("...waiting for  reversal.  %i candles left.", sell_counter);
    }
//    if (sell_reversal) {
//      PrintFormat("Reversal found! Place an order: P:  %i more candles.", Rates[1].low,sell_counter);
//    }
//    PrintFormat("Rates[1].close: %f", Rates[1].close);
//    PrintFormat("Rates[2].close: %f", Rates[2].close);
    //        PrintFormat("Rates[0].close: %f",Rates[0].close);

    // check for reversal while sell_counter > 0
    if (sell_counter > 0) {
      // if candle closed lower and we haven't yet encounted a reversal
//      if (sell_reversal) {
//        if (Rates[1].low > Rates[2].low) {
          //                    PrintFormat("Rates[1].low is %f \nhigher than \nRates[2].low. %f Returning.",Rates[1].low,Rates[2].low);
//          PrintFormat("No lower low. Sell counter is %i . Decrementing sell_counter by 1 and moving on to the next candle.", sell_counter);
//        }
        if (Rates[1].low <= Rates[2].low 
        || sell_reversal) {
          price = currentTick.bid; // look at current ask price
          PrintFormat("Trying to place order at %f", Rates[1].low);
//          PrintFormat("Price (current bid) is: %f", price);
          PrintFormat("currentLow is: %f", currentLow);
          PrintFormat("Found a lower low in Rates[1].low: %f Rates[2].low %f", Rates[1].low, Rates[2].low);

          if ((price >= currentLow && currentLow - rVal >= ValuesBollingerMiddle[1]) 
          || sell_reversal) {
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
            PrintFormat("BUT RR is Abs(%f - %f) * 1.2 = %f so less than required %f", Rates[1].high, Rates[1].low, rVal, BBMidRange); //this is fucked
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
  if (buy_setup) {
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
            sl = Rates[1].low - 50 * _Point; // set sl price to strike - stop loss gap
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
            PrintFormat("BUT RR is Abs(%f - %f) * 1.2 = %f so less than required %f", Rates[1].high, Rates[1].low, rVal, BBMidRange); //this is fucked
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
}
//---UTILS---//
bool isHammer(int candleIndex) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);

  bool hasLargeTail = tailSize >= bodySize * 4.0;
  bool hasSmallWick = wickSize < bodySize * 0.5;

  return (hasLargeTail && hasSmallWick) ? true : false;
}
bool buySetup(int candleIndex) {
  return openBelowBBLower(candleIndex) && closeAboveBBLower(candleIndex) ? true : false;
}
bool sellSetup(int candleIndex) {
  return openAboveBBUpper(candleIndex) && closeBelowBBUpper(candleIndex) ? true : false;
}
void drawSetup(int candleIndex) {
  datetime setupTime = iTime(Symbol(), Period(), 1);

  if (buySetup(candleIndex)) {
    // draw a green buy arrow at high
    ObjectCreate(0, "BuySetupArrow" + setupTime, OBJ_ARROW_BUY, 0, setupTime, Rates[candleIndex].high);
    ObjectSetInteger(0, "BuySetupArrow" + setupTime, OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "BuySetupArrow" + setupTime, OBJPROP_WIDTH, 2);
    // draw a green sell arrow sell at BB mid
    ObjectCreate(0, "BuySetupTP" + setupTime, OBJ_ARROW_SELL, 0, setupTime, ValuesBollingerMiddle[candleIndex]);
    ObjectSetInteger(0, "BuySetupTP" + setupTime, OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "BuySetupTP" + setupTime, OBJPROP_WIDTH, 2);
  } else if (sellSetup(candleIndex)) {
    // draw a green sell arrow at low
    ObjectCreate(0, "SellSetupArrow" + setupTime, OBJ_ARROW_SELL, 0, setupTime, Rates[candleIndex].low);
    ObjectSetInteger(0, "SellSetupArrow" + setupTime, OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "SellSetupArrow" + setupTime, OBJPROP_WIDTH, 2);
    // draw a green buy arrow at BBMid
    ObjectCreate(0, "SellSetupTP" + setupTime, OBJ_ARROW_BUY, 0, setupTime, ValuesBollingerMiddle[1]);
    ObjectSetInteger(0, "SellSetupTP" + setupTime, OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "SellSetupTP" + setupTime, OBJPROP_WIDTH, 2);
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
  ObjectCreate(0, "HammerLowerShadow" + hammerTime, OBJ_ARROW_UP, 0, hammerTime, yLowerShadow);
  ObjectSetInteger(0, "HammerLowerShadow" + hammerTime, OBJPROP_COLOR, clrGreen); // Set color to red or any other color
  ObjectSetInteger(0, "HammerLowerShadow" + hammerTime, OBJPROP_WIDTH, 5);
}
bool isShootingStar(int candleIndex) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);

  bool hasSmallTail = tailSize < bodySize * 0.5;
  bool hasLargeWick = wickSize >= bodySize * 3.0;

  return (hasSmallTail && hasLargeWick) ? true : false;
}
// Draw the hammer candlestick pattern on the chart
void drawShootingStar(int candleIndex) {
  // Draw a vertical line to represent the body of the hammer
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime shootingStarTime = iTime(Symbol(), Period(), 1);

  // Draw a circle to represent the upper shadow of the shooting star
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  ObjectCreate(0, "ShootingStarUpperShadow" + shootingStarTime, OBJ_ARROW_DOWN, 0, shootingStarTime, yUpperShadow);
  ObjectSetInteger(0, "ShootingStarUpperShadow" + shootingStarTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color
  ObjectSetInteger(0, "ShootingStarUpperShadow" + shootingStarTime, OBJPROP_WIDTH, 5);
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

bool isIndecisionCandle(int candleIndex, int tailWickMultiplier) {
  double tailWickSize = 0;
  double bodySize = 0;
  tailWickSize = getTailWickSize(candleIndex);
  bodySize = getBodySize(candleIndex);
  return tailWickSize * tailWickMultiplier >= bodySize ? true : false;
}
// Trading
void OpenBetterOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit, double lots, string comment) {

  // refactor TP to use candle Range or rVal
  int digits = (int) SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
  price = NormalizeDouble(price, digits);
  stopLoss = NormalizeDouble(stopLoss, digits);
  takeProfit = NormalizeDouble(takeProfit, digits);
  Print(PositionsTotal());
  // order expires at end of next candle
  datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());

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
void drawSignals(int candleIndex) {
  if (isShootingStar(candleIndex)) {
    drawShootingStar(candleIndex);
  };
  if (isHammer(candleIndex)) {
    drawHammer(candleIndex);
  };

  if (buySetup(candleIndex) || sellSetup(candleIndex)) {
    drawSetup(candleIndex);
  };
}
//+------------------------------------------------------------------+
//| Returns the last deal ticket in history or -1                    |
//+------------------------------------------------------------------+
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
//+--------------------------------------------------------------------------+
//| Requests history for the last days and returns false in case of failure  |
//+--------------------------------------------------------------------------+
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