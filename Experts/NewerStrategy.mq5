#define app_name "Bollinger Bounce2"
#define app_magic 301124

//basic expert uses fixed order size
input double InpOrderSize = 0.1; //order size in lots
// Trades also have a magic number and a comment
input int InpMagic = app_magic; //Magic number
input string InpTradeComment = app_name; //Trade comment

//Indicator inputs
input int InpBollingerPeriod = 20; // Bollinger period
input double InpBollingerDeviations = 2.0; //Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; //Bollinger applied price
input int InpKeltnerPeriod = 20; //Keltner Channel period
input double InpKeltnerMultiplier = 2.0; // Keltner Channel Multiplier
input ENUM_MA_METHOD InpKeltnerMAMethod = MODE_EMA; // Keltner Channel
input ENUM_APPLIED_PRICE InpKeltnerAppliedPrice = PRICE_CLOSE; //Keltner applied price

//Entry exit settings
input int InpEntryGapPoints = 10; //Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; //SL gap points, 50pts=0.5pips

#include <Trade/Trade.mqh>
CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;

//Indicator handles
int HandleBollinger;
int HandleKeltner;

double ValuesBollingerUpper[];
double ValuesBollingerLower[];
double ValuesBollingerMiddle[];
double ValuesKeltnerUpper[];
double ValuesKeltnerLower[];
MqlRates Rates[];
MqlTick currentTick;
double currentHigh;
double currentLow;
double currentAsk;
double currentBid;
double EntryGap;
double StopLossGap;
bool buySetUpFlag;
bool sellSetupFlag;
ENUM_ORDER_TYPE currentOrderType;

// Initialisation
int OnInit() {

   HandleKeltner = iCustom(Symbol(), Period(),"Keltner Channel.ex5", InpKeltnerPeriod, InpKeltnerMultiplier, InpKeltnerMAMethod, InpKeltnerAppliedPrice);   
   HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);

   ArraySetAsSeries(ValuesBollingerUpper,true);
   ArraySetAsSeries(ValuesBollingerLower,true);
   ArraySetAsSeries(ValuesBollingerMiddle, true);
   ArraySetAsSeries(ValuesKeltnerUpper,true);
   ArraySetAsSeries(ValuesKeltnerLower,true);
   ArraySetAsSeries(Rates,true);
   
   EntryGap = PointsToDouble(InpEntryGapPoints);
   StopLossGap = PointsToDouble(InpStopLossGapPoints);
   
   Trade.SetExpertMagicNumber(InpMagic);
   
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   IndicatorRelease(HandleBollinger);
   IndicatorRelease(HandleKeltner);
}

void OnTick() {
   if (!IsNewBar()) return;
   int numCandles = 5;

   if (CopyBuffer(HandleBollinger, UPPER_BAND, 0, numCandles, ValuesBollingerUpper) < numCandles) return;
   if (CopyBuffer(HandleBollinger, LOWER_BAND, 0, numCandles, ValuesBollingerLower) < numCandles) return;
   if (CopyBuffer(HandleBollinger, BASE_LINE, 0, numCandles, ValuesBollingerMiddle) < numCandles) return;
   if (CopyBuffer(HandleKeltner, UPPER_BAND, 0, numCandles, ValuesKeltnerUpper) < numCandles) return;
   if (CopyBuffer(HandleKeltner, LOWER_BAND, 0, numCandles, ValuesKeltnerLower) < numCandles) return;
   if (CopyRates(Symbol(), Period(), 0, numCandles, Rates) < numCandles) return;   
   
   double sl = 0;
   double price = 0;
   double tp = 0;
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits); //LEARN MQL5 85
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits); //LEARN MQL5 85 
   if (!SymbolInfoTick(_Symbol,currentTick)) {Print("Failed to get current tick"); return;}
   double window = 5;
   if (isShootingStar(1)) { drawShootingStar(1); };   
   if (isHammer(1)) { drawHammer(1); };
   
   if (buySetup(1) || sellSetup(1)) { drawSetup(1); };

   //RiskReturn based on candle extremum and BB range.
   double candleRange = MathAbs(Rates[1].high-Rates[1].low);
   double bodySize = MathAbs(Rates[1].open-Rates[1].close);
   double BBMidRange = MathAbs(ValuesBollingerUpper[1]-ValuesBollingerMiddle[1]);
   bool candleSizeInRange = candleRange*2 <= BBMidRange;
   
   //if Rates[1].close > BBUp[1]
   //alpha= 5;
   //if rates[1].close 
   
   
      //BUY SCENARIO
      if (buySetup(1)) {   
            //WE'RE ON!
            price = currentTick.ask; //look at current ask price
            double strikeBuy = Rates[1].high; //set strike price as latest fully formed candle high..Mathmax(Rates[0].high || Rates[1].low ?)
            if (!candleSizeInRange) { Print("No buy: Candle size not in range"); }
//            if (isIndecisionCandle(1,10)) { Print("Is indecision candle"); }

              if (price <= strikeBuy 
              && candleSizeInRange 
              ) {
               sl = Rates[1].low; //set sl price to strike - stop loss gap
               tp = ValuesBollingerMiddle[1]-25*_Point;
//               tp = strikeBuy+candleRange*1.2;
              OpenBetterOrder(ORDER_TYPE_BUY_STOP, price, sl, tp, InpOrderSize, InpTradeComment);
               }
      }
      //SELL SCENARIO
      if (sellSetup(1)) {
            //WE'RE ON!
            price = currentTick.bid; //look at current ask price
            double strikeSell = Rates[1].low; //set strike price as latest fully formed candle low
            
            if (!candleSizeInRange) { Print("No sell: Candle size not in range"); }
            //if (isIndecisionCandle(1,10)) { Print("'Is indecision candle"); }
              if (price <= strikeSell 
              && candleSizeInRange 
              ) {
               sl = Rates[1].high; //set sl price to strike - stop loss gap
               //tp = strikeSell-75*_Point;
               tp = ValuesBollingerMiddle[1]+25*_Point;
               //tp = strikeSell-candleRange*1.2;
               OpenBetterOrder(ORDER_TYPE_SELL_STOP, price, sl, tp, InpOrderSize, InpTradeComment); //todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
               }
      }
}
bool isHammer(int candleIndex) {
    // Calculate the body size and shadow lengths
    double bodySize = getBodySize(candleIndex);
    double tailSize = getTailSize(candleIndex);
    double wickSize = getWickSize(candleIndex);
    double tailWickSize = getTailWickSize(candleIndex);

   bool hasLargeTail = tailSize >= bodySize*4.0;
   bool hasSmallWick = wickSize < bodySize*0.5;

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
    
   if (buySetup(candleIndex) ) {
      //draw a green buy arrow at high
      ObjectCreate(0, "BuySetupArrow" + setupTime, OBJ_ARROW_BUY, 0, setupTime, Rates[candleIndex].high);
      ObjectSetInteger(0, "BuySetupArrow" + setupTime, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0,"BuySetupArrow" + setupTime,OBJPROP_WIDTH,2);
      //draw a green sell arrow sell at BB mid
      ObjectCreate(0, "BuySetupTP" + setupTime, OBJ_ARROW_SELL, 0, setupTime, ValuesBollingerMiddle[candleIndex]);
      ObjectSetInteger(0, "BuySetupTP" + setupTime, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0,"BuySetupTP" + setupTime,OBJPROP_WIDTH,2);
   } else if (sellSetup(candleIndex)) {
      //draw a green sell arrow at low
      ObjectCreate(0, "SellSetupArrow" + setupTime, OBJ_ARROW_SELL, 0, setupTime, Rates[candleIndex].low);
      ObjectSetInteger(0, "SellSetupArrow" + setupTime, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0,"SellSetupArrow" + setupTime, OBJPROP_WIDTH,2);
      //draw a green buy arrow at BBMid
      ObjectCreate(0, "SellSetupTP" + setupTime, OBJ_ARROW_BUY, 0, setupTime, ValuesBollingerMiddle[1]);
      ObjectSetInteger(0, "SellSetupTP" + setupTime, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0,"SellSetupTP" + setupTime,OBJPROP_WIDTH,2);
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
    ObjectSetInteger(0,"HammerLowerShadow" + hammerTime,OBJPROP_WIDTH,5);
}
bool isShootingStar(int candleIndex) {
    // Calculate the body size and shadow lengths
    double bodySize = getBodySize(candleIndex);
    double tailSize = getTailSize(candleIndex);
    double wickSize = getWickSize(candleIndex);
    double tailWickSize = getTailWickSize(candleIndex);
    
    bool hasSmallTail = tailSize < bodySize*0.5;
    bool hasLargeWick = wickSize >= bodySize*3.0;
    
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
    ObjectSetInteger(0,"ShootingStarUpperShadow" + shootingStarTime,OBJPROP_WIDTH,5);
}
bool closeBelowBBUpper(int candleIndex) { return Rates[candleIndex].close <= ValuesBollingerUpper[candleIndex] ? true : false; }
bool openAboveBBUpper(int candleIndex) { return Rates[candleIndex].open > ValuesBollingerUpper[candleIndex] ? true : false; }
bool closeAboveBBLower(int candleIndex) { return Rates[candleIndex].close >= ValuesBollingerLower[candleIndex] ? true : false; }
bool openBelowBBLower(int candleIndex) { return Rates[candleIndex].open < ValuesBollingerLower[candleIndex] ? true : false; }
double getTailSize(int candleIndex) {
   double tailSize = 0;
      //candle is bearish, close is lower than open.
      //so tail is close - low.
   if (bearishCandle(candleIndex)) {
      tailSize = Rates[candleIndex].close - Rates[candleIndex].low;
   } else {
      tailSize = Rates[candleIndex].open - Rates[candleIndex].low;
   }
   return tailSize;
}
double getWickSize(int candleIndex) {
   double wickSize = 0;
   //if bearish candle, close is higher than open.
   //so wick is high - close.
   if (bearishCandle(candleIndex)) {
      wickSize = Rates[candleIndex].high - Rates[candleIndex].open;
   } else {
      wickSize = Rates[candleIndex].high - Rates[candleIndex].close;
   }
   return wickSize;
}
double getBodySize(int candleIndex) { return MathAbs(Rates[candleIndex].open - Rates[candleIndex].close); }
double getCandleSize(int candleIndex) { return MathAbs(Rates[candleIndex].open - Rates[candleIndex].close); }
double getTailWickSize(int candleIndex) { return getTailSize(candleIndex)+getWickSize(candleIndex); }

bool isIndecisionCandle(int candleIndex,int tailWickMultiplier) {
     double tailWickSize = 0;
     double bodySize = 0;
     tailWickSize = getTailWickSize(candleIndex);
     bodySize = getBodySize(candleIndex);
     return tailWickSize*tailWickMultiplier >= bodySize ? true : false;
}
// Trading
void OpenBetterOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit, double lots, string comment) {
   
   //refactor TP to use candle Range or rVal
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   price = NormalizeDouble(price, digits);
   stopLoss = NormalizeDouble(stopLoss, digits);
   takeProfit = NormalizeDouble(takeProfit, digits);
   Print(PositionsTotal());
   //order expires at end of next candle
   datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());

   if (!Trade.OrderOpen(Symbol(), type, lots, 0, price, stopLoss, 
   takeProfit, 
   ORDER_TIME_SPECIFIED, expiration, comment)) {
      PrintFormat("Open Order failed for %s, %s, price=%f, sl=%f, tp=%f", 
         Symbol(), EnumToString(type), price, stopLoss, takeProfit);
   }
}

bool BollingerBelowKeltner(int candleIndex) { return ValuesBollingerLower[candleIndex] < ValuesKeltnerLower[candleIndex]? true : false; }
bool BollingerAboveKeltner(int candleIndex) { return ValuesBollingerUpper[candleIndex] > ValuesKeltnerUpper[candleIndex] ? true : false; }
bool CloseAboveBollinger(int candleIndex) { return Rates[candleIndex].close >= ValuesBollingerUpper[candleIndex] ? true : false; }
bool CloseBelowBollinger(int candleIndex) { return Rates[candleIndex].close <= ValuesBollingerLower[candleIndex] ? true : false; }
bool bearishCandle(int candleIndex) { return Rates[candleIndex].close < Rates[candleIndex].open ? true : false; }
bool bullishCandle(int candleIndex) { return Rates[candleIndex].close > Rates[candleIndex].open ? true : false; }
// Utility functions
//Source: How to run MQL4 or MQL5 code only one time for each bar
bool IsNewBar() {
   static datetime previousBarTime = iTime(Symbol(), Period(), 0);
   datetime currentBarTime = iTime(Symbol(), Period(), 0);
   
   if (currentBarTime == previousBarTime) return false;
   previousBarTime = currentBarTime;
   return true;
}

double PointsToDouble(int points, string symbol = "") {
   
   if (symbol == "") symbol = Symbol();
   
   double value = (double)points * SymbolInfoDouble(symbol, SYMBOL_POINT);
   return value;
}

/*
//code a simple RSI EA in MQL5 - trustful trading
bool countOpenPositions(int &cntBuy, int &cntSell) {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for (int i = total-1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (ticket<=0) {
         Print("Failed to get position ticket"); 
         return false;
      }
      if (!PositionSelectByTicket(ticket)) {
         Print("Failed to select position"); 
         return false;
      }
      long magic;
      
      if (!PositionGetInteger(POSITION_MAGIC,magic)) {
         Print("Failed to get position magicnumber");
         return false;
      }
      
      if (magic==InpMagic) {
         long type;
         if (!PositionGetInteger(POSITION_TYPE,type)) {
            Print("Failed to get position type.");
            return false;
            }
         if (type==POSITION_TYPE_BUY) {
            cntBuy++;
            }
         if (type == POSITION_TYPE_SELL) {
            cntSell++;
            } 
      }
   }
}
*/