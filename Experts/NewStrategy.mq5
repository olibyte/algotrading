#define app_name "Bollinger Bounce2"
#define app_magic 301124

//basic expert uses fixed order size
input double InpOrderSize = 0.1; //order size in lots
// Trades also have a magic number and a comment
input int InpMagic = app_magic; //Magic number
input string InpTradeComment = app_name; //Trade comment

//Indicator inputs
//Fast EMA
input int InpFastMAPeriod = 50; //Fast MA Period
input ENUM_MA_METHOD InpFastMAMethod = MODE_EMA;//Fast MA Method
input ENUM_APPLIED_PRICE InpFastMAAppliedPrice = PRICE_CLOSE;//Fast MA Applied Price

//Slow EMA
input int InpSlowMAPeriod = 100; //Slow MA Period
input ENUM_MA_METHOD InpSlowMAMethod = MODE_EMA; //Slow MA Method
input ENUM_APPLIED_PRICE InpSlowMAAppliedPrice = PRICE_CLOSE; //Slow MA Applied price
//EMA period for Keltner Channels use
input int InpEMAPeriod = 20;
input ENUM_MA_METHOD InpEMAMethod = MODE_EMA;
input ENUM_APPLIED_PRICE InpEMAAppliedPrice = PRICE_CLOSE;
//Bollinger Band
input int InpBollingerPeriod = 20; // Bollinger period
input double InpBollingerDeviations = 2.0; //Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; //Bollinger applied price
//Keltner Channel
input int InpKeltnerPeriod = 20; //Keltner Channel period
input double InpKeltnerMultiplier = 2.0; // Keltner Channel Multiplier
input ENUM_MA_METHOD InpKeltnerMAMethod = MODE_EMA; // Keltner Channel
input ENUM_APPLIED_PRICE InpKeltnerAppliedPrice = PRICE_CLOSE; //Keltner applied price

//Entry exit settings
input int InpEntryGapPoints = 10; //Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; //SL gap points, 50pts=0.5pips
input double InpTakeProfitMultiplier = 1; //Take profit multiplier

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
bool isOrderOpen;
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
   int numCandles = 5;
   
   if (!IsNewBar()) return;
//   if (PositionsTotal() > 0) return;
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
   
   //RiskReturn based on candle extremum and BB range.
   double candleRange = MathAbs(Rates[1].high-Rates[1].low);
   double BBMidRange = MathAbs(ValuesBollingerUpper[1]-ValuesBollingerMiddle[1]);
   bool candleSizeInRange = candleRange*2.5 <= BBMidRange;
   
   
   
      //BUY SCENARIO

      //if current candle close inside BB
//      Rates[1].close is latest fully formed candle & will inform prices. Rates[0].close onTick will print the current Open.
      //OPENED BELOW BBLOW,CLOSED ABOVE BBLOW, 
      if (Rates[1].close >= ValuesBollingerLower[1] && Rates[1].open < ValuesBollingerLower[1]) {
                  
            //WE'RE ON!
            price = currentTick.ask; //look at current ask price
            double strikeBuy = Rates[1].high; //set strike price as latest fully formed candle high
            //if ask reaches strike, open the order
            PrintFormat("price: %f   strikeBuy: %f", price,strikeBuy);
            
              if (price <= strikeBuy && candleSizeInRange && (!isIndecisionCandle(1))) {
               sl = Rates[1].low; //set sl price to strike - stop loss gap
               //tp = strikeBuy+75*_Point;
               tp = strikeBuy+candleRange*1.2;
               // Calculate buy stop and stop loss levels
               PrintFormat("Setup 2 CANDLES AGO: O: %f, H: %f, L: %f, C: %f",Rates[2].open,Rates[2].high,Rates[2].low,Rates[2].close);  //if setup closed outside            
               PrintFormat("Trigger 1 CANDLE AGO: O: %f, H: %f, L: %f, C: %f",Rates[1].open,Rates[1].high,Rates[1].low,Rates[1].close); //and trigger closed inside
               PrintFormat("Placing order at price: %f and sl: %f", price,sl);
               //Trade.PositionOpen(Symbol(),ORDER_TYPE_BUY_STOP,InpOrderSize,price,sl,tp,InpTradeComment);
              OpenBetterOrder(ORDER_TYPE_BUY_STOP, price, sl, tp, InpOrderSize, InpTradeComment);
              //OpenOrder(ORDER_TYPE_BUY_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment);
               //todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
               }

      }
            //SELL SCENARIO
      //if latest ff candle close inside BB. 
      if (Rates[1].close <= ValuesBollingerUpper[1] && Rates[1].open > ValuesBollingerUpper[1]) {
           
            //WE'RE ON!
            price = currentTick.bid; //look at current ask price
 
            double strikeSell = Rates[1].low; //set strike price as latest fully formed candle low
            //if ask reaches strike, open the order
            PrintFormat("price: %f   strikeSell: %f", price,strikeSell);

              if (price <= strikeSell && candleSizeInRange && (!isIndecisionCandle(1))) {
               sl = Rates[1].high; //set sl price to strike - stop loss gap
               //tp = strikeSell-75*_Point;
               tp = strikeSell-candleRange*1.2;
               // Calculate buy stop and stop loss levels
               PrintFormat("Setup 2 CANDLES AGO: O: %f, H: %f, L: %f, C: %f",Rates[2].open,Rates[2].high,Rates[2].low,Rates[2].close);              
               PrintFormat("Trigger 1 CANDLE AGO: O: %f, H: %f, L: %f, C: %f",Rates[1].open,Rates[1].high,Rates[1].low,Rates[1].close);
               PrintFormat("Placing order at price: %f and sl: %f", price,sl);
               //Trade.PositionOpen(Symbol(),ORDER_TYPE_SELL_STOP,InpOrderSize,price,sl,tp,InpTradeComment);
               OpenBetterOrder(ORDER_TYPE_SELL_STOP, price, sl, tp, InpOrderSize, InpTradeComment); //todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
               //OpenOrder(ORDER_TYPE_SELL_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment); //todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
               }
      }
}
bool isIndecisionCandle(int candleIndex) {
   
   double wickSize = 0;
   double tailSize = 0;
   //candle is bearish, close is lower than open. wick is high - open.
   if (Rates[candleIndex].close > Rates[candleIndex].open) {
        wickSize = Rates[candleIndex].high - Rates[candleIndex].open;
        tailSize = Rates[candleIndex].close - Rates[candleIndex].low;
   } else {
      wickSize = Rates[candleIndex].high - Rates[candleIndex].close;
      tailSize = Rates[candleIndex].open - Rates[candleIndex].low;
   }
   double tailWickSize = wickSize+tailSize;
   double bodySize = MathAbs(Rates[candleIndex].open - Rates[candleIndex].close);
   PrintFormat("Tail: %f   Wick: %f    TailWick: %f   Body: %f", tailSize,wickSize,tailWickSize,bodySize);
   bodySize = bodySize*10;
   return tailWickSize > bodySize ? true : false;
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
void OpenOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double multiplier, double lots, string comment) {
   
   double takeProfit = 0;
   /*
   price - stopLoss will be positive for a long entry because stopLoss will be less than price
   price - stopLoss will be negative for a short because stopLoss will be higher than price
   */
   takeProfit = price + (price - stopLoss) * multiplier; //price-stopLoss handles slippage
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

bool BollingerBelowKeltner(int candleIndex) {
   return ValuesBollingerLower[candleIndex] < ValuesKeltnerLower[candleIndex]? true : false;
}
bool BollingerAboveKeltner(int candleIndex) {
   return ValuesBollingerUpper[candleIndex] > ValuesKeltnerUpper[candleIndex] ? true : false;
}
bool CloseAboveBollinger(int candleIndex) {
   return Rates[candleIndex].close > ValuesBollingerUpper[candleIndex] ? true : false;
}
bool CloseBelowBollinger(int candleIndex) {
   return Rates[candleIndex].close < ValuesBollingerLower[candleIndex] ? true : false;
}
bool bearishCandle(int candleIndex) {
   return Rates[candleIndex].close < Rates[candleIndex].open ? true : false;
}
bool bullishCandle(int candleIndex) {
   return Rates[candleIndex].close > Rates[candleIndex].open ? true : false;
}