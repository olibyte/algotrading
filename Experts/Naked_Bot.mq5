#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#define app_name "Naked Bot"
#define app_magic 310324
#define fvbo_core
#include <Trade/Trade.mqh>
#include <Indicators/IndicatorBollinger.mqh>
#include <Indicators/IndicatorCSR.mqh>
#include <Utils.mqh>
//user input
input int BBPeriod = 20; // Bollinger period
input double BBDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE BBAppliedPrice = PRICE_CLOSE; // Bollinger applied price

input int InpStopLossGapPoints = 100; //Stop loss gap in points.
input int InpEntryGapPoints = 50; //flexibility when placing orders.
input int InpMaxPositions = 1; //Max number of positions open at any given time.
input double InpLotSize = 0.1; //Size in lots.

//classes
CTrade Trade; CPositionInfo PositionInfo; COrderInfo OrderInfo;

CIndicatorBollinger	BB;
int HandleBB;
double BBUpper[],BBLower[],BBMiddle[];

CIndicatorCSR CSR;
//FVBO
bool fvbo_buy_flag,fvbo_sell_flag;
datetime buy_signal_time, sell_signal_time;
int OnInit()
  {
       BB.Init(Symbol(), Period(), BBPeriod, 0, BBDeviations, BBAppliedPrice);    
//       ArraySetAsSeries(BBUpper, true);
//       ArraySetAsSeries(BBLower, true);
//       ArraySetAsSeries(BBMiddle, true);
       
       //BUFFER INDEX: 0: TREND, 1: SUPPORT, 2: RESISTANCE
       CSR.Init(Symbol(), Period(), BBPeriod, 0, BBDeviations, BBAppliedPrice);  

   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
      if (!IsNewBar()) return; // still looking at same bar
      if (PositionsTotal() > InpMaxPositions) return; //max positions
      
      //0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND
      double BBM = NormalizeDouble( BB.GetValue(0,0), Digits() );
      double BBU = NormalizeDouble( BB.GetValue(1,0), Digits() );
      double BBL = NormalizeDouble( BB.GetValue(2,0), Digits() );
      
      double CSRTrend = NormalizeDouble( CSR.GetValue(0,0), Digits() );
      double CSRSupport = NormalizeDouble( CSR.GetValue(1,0), Digits() );
      double CSRResistance = NormalizeDouble( CSR.GetValue(2,0), Digits() );
      if (CSR.GetValue(0,0) == CSR.GetValue(1,0)) {
         Print("In a support zone");
      } else if (CSR.GetValue(0,0) == CSR.GetValue(2,0)) {
         Print("In a resistance zone");
      }
      
      Print("CSR Trend: ",CSRTrend);  
      Print("CSR Support: ",CSRSupport);  
      Print("CSR Resistance: ",CSRResistance);  
      Print("CSR 4?: ",CSR.GetValue(3,0)); 
      Print("CSR 5?: ",CSR.GetValue(4,0)); 
      double open1 =  NormalizeDouble( iOpen(Symbol(),Period(),1)  ,Digits());
      double high1 =  NormalizeDouble( iHigh(Symbol(),Period(),1)  ,Digits());
      double low1 =   NormalizeDouble( iLow(Symbol(),Period(),1)   ,Digits());
      double close1 = NormalizeDouble( iClose(Symbol(),Period(),1) ,Digits());
      
      double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
      double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
      
      double tp =          BBM;
      double lots =        InpLotSize;
      double sl_gap =      PointsToDouble(InpStopLossGapPoints);
      double entry_gap =   PointsToDouble(InpEntryGapPoints);
      double rr = (high1-low1)*1.5;
      double tp_target = (high1-low1)*1.2;


      
      datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
      string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      
      
      #ifdef fvbo_core
      //FVBO SIGNALS
      if (
      iClose(Symbol(),Period(),2) < BB.GetValue(2,2) &&           //candle 2 closed below lower BB
      iClose(Symbol(),Period(),1) > iOpen(Symbol(),Period(),1)    //candle 1 is bullish
      ) { drawFVBO(1,clrPink); fvbo_buy_flag = true; fvbo_sell_flag = false; buy_signal_time = TimeCurrent(); }
      if (
      iClose(Symbol(),Period(),2) > BB.GetValue(1,2) &&           //candle 2 closed above upper BB
      iClose(Symbol(),Period(),1) < iOpen(Symbol(),Period(),1)    //candle 1 is bearish
      ) { drawFVBO(1,clrPink); fvbo_buy_flag = false; fvbo_sell_flag = true; sell_signal_time = TimeCurrent(); }
      
      //IF FVBO SIGNAL FOUND, LOOK FOR TRADE: Set up expires after lookback candles. 
      if (fvbo_buy_flag) {

         //check if search has expired
         int lookback = 3;
         int buy_signal_candle = iBarShift(Symbol(),Period(),buy_signal_time,false);
         
         if (buy_signal_candle > lookback) {
         PrintFormat("Last buy signal: %s. Resetting buy flag.",TimeToString(buy_signal_time));
         fvbo_buy_flag = false;
         }
         
         //PLACE BUY ORDER           
         double sl =    NormalizeDouble(low1-sl_gap,   Digits());
         double price = high1;
         double tp =    price + tp_target;
         //RiskReward must be below midline
         if (price+rr < BBM) {
            //if trend is resistance, bear market. shorts only.
            //if trend is support, bull market. long only. 
            if (CSRTrend == CSRSupport) Trade.BuyStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
         } 
      }
      
      if (fvbo_sell_flag) {
      
         int lookback = 3;
         int sell_signal_candle = iBarShift(Symbol(),Period(),sell_signal_time,false);
      
         if (sell_signal_candle > lookback) {
         PrintFormat("Last sell signal: %s. Resetting sell flag.",TimeToString(sell_signal_time));
         fvbo_sell_flag = false;
         }
         
         //Place a sell order
         double sl =    NormalizeDouble(high1+sl_gap,Digits());
         double price = low1;     
         double tp =    price - tp_target;
         
         //RiskReward must be above midline
         if (price-rr > BBM) {
            if (CSRTrend == CSRResistance) Trade.SellStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
         }
      }
      
      #endif
   }
  
  void drawFVBO(int i, color c) {
      datetime setupTime = iTime(Symbol(), Period(), i);      
      ObjectCreate(0, "BuySetup" + setupTime, OBJ_TEXT, 0, setupTime, iHigh(Symbol(),Period(),i));
      ObjectSetString(0,"BuySetup" + setupTime,OBJPROP_TEXT,"FVBO");
      ObjectSetInteger(0, "BuySetup" + setupTime, OBJPROP_COLOR, c);
      ObjectSetDouble(0,"BuySetup" + setupTime,OBJPROP_ANGLE,90.0);
  }