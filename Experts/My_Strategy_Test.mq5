#define app_name "Bollinger Bounce"
#define app_magic 301123

//basic expert uses fixed order size
input double InpOrderSize = 0.10; //order size in lots
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
   int numCandles = 3;

   if (!IsNewBar()) return;
   if (CopyBuffer(HandleBollinger, UPPER_BAND, 0, numCandles, ValuesBollingerUpper) < numCandles) return;
   if (CopyBuffer(HandleBollinger, LOWER_BAND, 0, numCandles, ValuesBollingerLower) < numCandles) return;
   if (CopyBuffer(HandleBollinger, BASE_LINE, 0, numCandles, ValuesBollingerMiddle) < numCandles) return;
   if (CopyBuffer(HandleKeltner, UPPER_BAND, 0, numCandles, ValuesKeltnerUpper) < numCandles) return;
   if (CopyBuffer(HandleKeltner, LOWER_BAND, 0, numCandles, ValuesKeltnerLower) < numCandles) return;
   if (CopyRates(Symbol(), Period(), 0, numCandles, Rates) < numCandles) return;   
   
   double sl = 0;
   double price = 0;
   int prev = 2;
   int latest = 1; //latest fully formed candle
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits); //LEARN MQL5 85
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits); //LEARN MQL5 85 
   if (!SymbolInfoTick(_Symbol,currentTick)) {Print("Failed to get current tick"); return;}
   

   
   //BB closed outside KC. Candle closed outside BB. Latest candle reversed.
   if ( 
      BollingerAboveKeltner(prev)  //BB above KC
   && CloseAboveBollinger(prev)    //Candle closed outside upper BB
   && bearishCandle(latest) //prev was a bullish candle(?), now latest has reversed and is bearish
  // && (Rates[latest].close < ValuesBollingerUpper[latest]) //back inside bb -REMOVE 
   ) {
         double candleRange = 0;
         double rVal = 0;
         double distanceToMid = 0;
         double midToHigh = 0;
         double tailWickSize = 0;
         double strikeSell = 0;
   
         candleRange = Rates[latest].high - Rates[latest].low; 
         tailWickSize = MathAbs(Rates[latest].high - Rates[latest].low - candleRange);
         rVal = candleRange + (candleRange*1.5);
         midToHigh =  Rates[latest].high - ValuesBollingerMiddle[latest];

      //r check and omit indecision candles
      if ( 
         (rVal <= midToHigh) 
         //&& (tailWickSize < candleRange) 
         ) {
         price = currentTick.bid; //look at current bid
         strikeSell = Rates[latest].high - EntryGap; //set strike price as latest fully formed candle high - entry gap
         //if the current bid reaches the strike price, open an order
         if (price >= strikeSell) { 
         sl = strikeSell +StopLossGap; //set sl to strike price + stop loss gap

         PrintFormat("Ask is %f, Bid is %f", Ask, Bid);
         PrintFormat("Setup 2 CANDLES AGO: O: %f, H: %f, L: %f, C: %f",Rates[prev].open,Rates[prev].high,Rates[prev].low,Rates[prev].close);         
         PrintFormat("Trigger 1 CANDLE AGO: O: %f, H: %f, L: %f, C: %f",Rates[latest].open,Rates[latest].high,Rates[latest].low,Rates[latest].close);
         PrintFormat("Placing order at price: %f and sl: %f", price,sl);
         OpenOrder(ORDER_TYPE_SELL_STOP,price,sl,InpTakeProfitMultiplier,InpOrderSize,InpTradeComment);      
         }
      }
   } else if ( 
            BollingerBelowKeltner(prev) //BB outside Keltner
         && CloseBelowBollinger(prev) //prev Candle closed outside lower BB
         && bullishCandle(latest) //prev candle was bearish(?), latest candle now bullish
      //   && (Rates[latest].close > ValuesBollingerLower[latest]) //latest candle now back in BB
   ) {   
         double candleRange = 0;
         double rVal = 0;
         double distanceToMid = 0;
         double midToLow = 0;
         double tailWickSize = 0;
         double strikeBuy = 0;
       
         candleRange = Rates[latest].high - Rates[latest].low; //candle range is based on high and low
         //candleRange = Rates[latest].close - Rates[latest].open; //search for larger candle
         tailWickSize = MathAbs(Rates[latest].high - Rates[latest].low - candleRange);
         
         rVal = candleRange + (candleRange*1.5);
         midToLow = ValuesBollingerMiddle[latest] - Rates[latest].low;
         
         //r check
         if ( 
         (rVal <= midToLow) 
         //&& (tailWickSize < candleRange) 
         ) {
            price = currentTick.ask; //look at current ask price
            strikeBuy = Rates[latest].low+EntryGap; //set strike price as latest fully formed candle low + entry gap
            //if ask reaches strike, open the order
            if (price <= strikeBuy) {
            sl = strikeBuy-StopLossGap; //set sl price to strike - stop loss gap

    // Calculate buy stop and stop loss levels
            PrintFormat("Setup 2 CANDLES AGO: O: %f, H: %f, L: %f, C: %f",Rates[prev].open,Rates[prev].high,Rates[prev].low,Rates[prev].close);              
            PrintFormat("Trigger 1 CANDLE AGO: O: %f, H: %f, L: %f, C: %f",Rates[latest].open,Rates[latest].high,Rates[latest].low,Rates[latest].close);
            PrintFormat("Placing order at price: %f and sl: %f", price,sl);
            OpenOrder(ORDER_TYPE_BUY_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment); //todo: price at low of the reversal candle. sl fixed based on lo. tp fixed (1.2 R toward midBB)
            }
         }     
   }
   
   /*ORIGINAL LOGIC FROM ORCHARD FOREX
   //if the 50 moving average is below the 100 moving average, and the high has broken out above upperBB
   if ((ValuesFastMA[1] < ValuesSlowMA[1]) && Rates[1].high > ValuesBollingerUpper[1]) {
      //
      price = Rates[1].low - EntryGap;
      sl = Rates[1].high + StopLossGap;
      tpVal = price + (price-sl) * InpTakeProfitMultiplier;
      OpenOrder(ORDER_TYPE_SELL_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment);
      PrintFormat("SELL!!! Price is %f, SL is %f", price, sl, tpVal);
   }
   else if ((ValuesFastMA[1] > ValuesSlowMA[1]) && Rates[1].low < ValuesBollingerLower[1]) {
   
      price = Rates[1].high + EntryGap;
      sl = Rates[1].low - StopLossGap;
      tpVal = price + (price-sl) * InpTakeProfitMultiplier;
      OpenOrder(ORDER_TYPE_BUY_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment);
      
      PrintFormat("BUY!!! Price is %f, SL is %f, tpVal is %f", price, sl, tpVal);
   }
   } else if ((ValuesBollingerLower[2] < ValuesKeltnerLower[2]) && Rates[2].close < ValuesBollingerLower[2] ) {
      //Print("Bollinger below KC, Candle closed below BB. Low breakout.");
      //broken out low...is there a bullish candle next?
      if ( Rates[1].close > Rates[2].close) {
         //Print("prev candle closed above previous candle...");
         if (Rates[0].close > Rates[1].close && Rates[0].close > ValuesBollingerLower[0]) {
         Print("A low breakout then 2 consecutive bullish candles. Current back in range. Set price at current close.");
         
            price = Rates[1].close;
            
            double stdDev = 0;
            double distanceFromMiddle = 0;
            
            stdDev = iStdDev(Symbol(),Period(),InpBollingerPeriod,0,MODE_EMA,InpBollingerAppliedPrice);
            distanceFromMiddle = (price - ValuesBollingerMiddle[0]) / ValuesStdDev[0];
            PrintFormat("stdDev is %f",stdDev);
            PrintFormat("distanceFromMiddle is %f",distanceFromMiddle);
            if (MathAbs(distanceFromMiddle) > 1.2) {
                  
                  Print("Price is more than 1.2R away from BB mid but now back inside BBLower");
                  sl = price - (EntryGap*5);
                  tp = ValuesBollingerMiddle[0];   
                  
                  PrintFormat("Price is...%f", price);
                  PrintFormat("Mid BB is... %f",ValuesBollingerMiddle[0]);
                  PrintFormat("tp is: %f",tp);
                  PrintFormat("sl is..%f",sl);
                  Print("Opening buy...");                              
         
                  OpenBuyOrder(ORDER_TYPE_BUY_STOP, price, sl, tp, InpOrderSize, InpTradeComment);
                  
            }

         }
         price = Rates[1].high + EntryGap;
         sl = Rates[1].low - StopLossGap;
         OpenOrder(ORDER_TYPE_SELL_STOP, price, sl, InpTakeProfitMultiplier, InpOrderSize, InpTradeComment);
         */
}

// Trading
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
   
   //order expires at end of next candle
   datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());

   if (!Trade.OrderOpen(Symbol(), type, lots, 0, price, stopLoss, takeProfit, 
   ORDER_TIME_SPECIFIED, expiration, comment)) {
      PrintFormat("Open Order failed for %s, %s, price=%f, sl=%f, tp=%f", 
         Symbol(), EnumToString(type), price, stopLoss, takeProfit);
   }
}

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