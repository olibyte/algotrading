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
#define tester
//#define big_shadow_filter

#include <Trade/Trade.mqh>
#include <Indicators/IndicatorBollinger.mqh>
// #include <Indicators/IndicatorCSR.mqh>
#include <Indicators/IndicatorMACD.mqh>
#include <Indicators/IndicatorRSI.mqh>
#include <Utils.mqh>
#include <CandlestickPatterns.mqh>
#include <FVBO.mqh>
// ,external_use,max_bars,htf,aoi_lower_level,aoi_higher_level,breakout_add_pips,enable_alert,enable_email,enable_mobile,zz_InpDepth_ltf,zz_InpDeviation_ltf,zz_InpBackstep_ltf,zz_InpDepth_htf,zz_InpDeviation_htf,zz_InpBackstep_htf,InpPeriod,InpCoeff,InpCoeffV,InpPeriodSm,enable_zz_htf,zz_htf_clr_buy,zz_htf_clr_sell,enable_zz_ltf,zz_ltf_clr_buy,zz_ltf_clr_sell,enable_zz_br,zz_br_clr_buy,zz_br_clr_sell,enable_aoi,zz_aoi_clr_buy,zz_aoi_clr_sell,enable_diver,zz_div_clr_buy,zz_div_clr_sell,zz_div_width,


input bool external_use=false;
input int max_bars=1000;
input int htf=16388;
input double aoi_lower_level=38.6;
input double aoi_higher_level=79;
input int breakout_add_pips=10;
input bool enable_alert=true;
input bool enable_email=false;
input bool enable_mobile=false;
input int zz_InpDepth_ltf=12;
input int zz_InpDeviation_ltf=5;
input int zz_InpBackstep_ltf=3;
input int zz_InpDepth_htf=12;
input int zz_InpDeviation_htf=5;
input int zz_InpBackstep_htf=3;
input int InpPeriod=130; //VFO
input double InpCoeff=0.2; //VFO
input double InpCoeffV=2.5; //VFO
input int InpPeriodSm=3; //VFO
input bool enable_zz_htf=true;
input int zz_htf_clr_buy=10156544; //MEDIUMSPRINGGREEN, THICK ZZ
input int zz_htf_clr_sell=17919; //ORANGERED, THICK ZZ
input bool enable_zz_ltf=true;
input int zz_ltf_clr_buy=8421376; //TEAL
input int zz_ltf_clr_sell=16748574; //DODGERBLUE
input bool enable_zz_br=true;
input int zz_br_clr_buy=2237106; //special dark red line FIREBRICK
input int zz_br_clr_sell=15631086; //special purple line VIOLET
input bool enable_aoi=true;
input int zz_aoi_clr_buy=16776960; //AQUA
input int zz_aoi_clr_sell=14772545; //ROYALBLUE
input bool enable_diver=true;
input int zz_div_clr_buy=16777215; //WHITE
input int zz_div_clr_sell=16777215; //WHITE
input int zz_div_width=2;

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
// Input parameters for the Fibonacci levels


input string InpFiboName = "FiboLevels";      // Object name
input color  InpFiboColor = clrRed;           // Fibonacci lines color
input ENUM_LINE_STYLE InpFiboStyle = STYLE_SOLID; // Line style
input int    InpFiboWidth = 2;                // Line width
input bool   InpFiboRayRight = true;          // Extend lines to the right
input double InpLevel1 = 0.0;                 // Level 1 (0%)
input double InpLevel2 = 0.236;               // Level 2 (23.6%)
input double InpLevel3 = 0.386;               // Level 3 (38.2%)
input double InpLevel4 = 0.5;                 // Level 4 (50%)
input double InpLevel5 = 0.618;               // Level 5 (61.8%)
input double InpLevel6 = 0.79;               // Level 6 (76.4%)
input double InpLevel7 = 1.0;                 // Level 7 (100%)

input ulong InpWaitBars            = 5;    //Num of bars to wait before considering new trade
//input int InpMaxHoldMins         = 150;
input int InpMaxPositions        = 1;     //Max positions.
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
CIndicatorBollinger BB_M30;
CIndicatorBollinger BB_H1;
CIndicatorRSI RSI;
CIndicatorRSI RSI_M30;
CIndicatorMACD MACD;
//FVBO
bool fvbo_buy_flag,fvbo_sell_flag;
datetime buy_signal_time, sell_signal_time;
int lookback = 5;
double rangeHigh,rangeLow;
double prevLow, prevHigh, currLow, currHigh = 0;
int prevHighIndex,currentHighIndex = 0;
double hourlyLow, hourlyHigh,dailyLow,dailyHigh;
int rangeHighIndex, rangeLowIndex, hourlyLowIndex, hourlyHighIndex,dailyLowIndex,dailyHighIndex,prev_fvbo_buy_index,fvbo_buy_index,fvbo_sell_index,prev_fvbo_sell_index, barsSinceLastLow, barsSinceLastHigh;
int rsi_score, bb_score, macd_score, highTestCount,lowTestCount = 0;
bool canShort = true;
bool canLong = true;
bool priceInAoi = false;
double blue_bottom, aqua_top, blue_border, aqua_border;
//Patterns
int bearishPattern = 0;
int bullishPattern = 0;
int patternMomentum = 0;
int purpleMomentum = 0;
int fvboLong = 0;
int fvboShort = 0;
double zz_high =0;
double zz_low = 10000;
bool dd_up, dd_down;
double low_retrace_61_4;
double low_retrace_21_0;
double low_retrace_38_6;
double low_retrace_79_0;
double high_retrace_61_4;
double high_retrace_21_0;
double high_retrace_38_6;
double high_retrace_79_0;
//ICT
// _AOI_SELL:14772545
// _AOI_BUY: 16776960

int filter_total, purple_total, dark_red_total,signal_total, buy_aoi_total,sell_aoi_total = 0;
datetime last_purple_signal, last_dark_red_signal, last_buy_aoi, last_sell_aoi;
int last_purple_bar, last_dark_red_bar, last_aqua_top_bar, last_blue_bottom_bar, last_breakout_buy_bar, last_breakout_sell_bar;
double last_purple_price, last_dark_red_price, last_aqua_top_price, last_blue_bottom_price, last_aqua_border_price, last_blue_border_price;

//PLAYBOOK
bool biasToolCompleted, bbRiverConfluence, breakoutAligned, deepTrendAligned, firstTestOfSDZone, SDZoneNotBunched;
double prevRangeHigh = 0;
double prevRangeLow = 0;
double currRangeHigh = 0;
double currRangeLow = 0;
int OnInit()
  {
// string indicator_name = "Step_2_ICT_Breakout_Indicator.ex5";
//  HandleICT = iCustom(Symbol(), Period(),"Step_2_ICT_Breakout_Indicator.ex5",external_use,max_bars,htf,aoi_lower_level,aoi_higher_level,breakout_add_pips,enable_alert,enable_email,enable_mobile,zz_InpDepth_ltf,zz_InpDeviation_ltf,zz_InpBackstep_ltf,zz_InpDepth_htf,zz_InpDeviation_htf,zz_InpBackstep_htf,InpPeriod,InpCoeff,InpCoeffV,InpPeriodSm,enable_zz_htf,zz_htf_clr_buy,zz_htf_clr_sell,enable_zz_ltf,zz_ltf_clr_buy,zz_ltf_clr_sell,enable_zz_br,zz_br_clr_buy,zz_br_clr_sell,enable_aoi,zz_aoi_clr_buy,zz_aoi_clr_sell,enable_diver,zz_div_clr_buy,zz_div_clr_sell,zz_div_width);
//  ArraySetAsSeries(ValuesICT,true);

//ICUSTOM VFO
   BB.Init(Symbol(), Period(), InpBBPeriod, 0, InpBBDeviations, InpBBAppliedPrice);
//BB_M30.Init(Symbol(),PERIOD_M30,InpBBPeriod,0,InpBBDeviations,InpBBAppliedPrice);
  MACD.Init(Symbol(),Period(),8,21,5,PRICE_CLOSE);
  RSI.Init(Symbol(),Period(),5,PRICE_CLOSE);
//  RSI_M30.Init(Symbol(),PERIOD_M30,5,PRICE_CLOSE);
//  BB_H1.Init(Symbol(),PERIOD_H1,InpBBPeriod,0,InpBBDeviations,InpBBAppliedPrice);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;                     // still looking at same bar
//  if(!WaitForHTF(Symbol(), PERIOD_D1)) return;   // Anchor data not available
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits()); //long
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits()); //short
//OHLC for latest 2 fully formed bars
   double open1 =  NormalizeDouble(iOpen(Symbol(),Period(),1),Digits());
   double high1 =  NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
   double low1 =   NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
   double close1 = NormalizeDouble(iClose(Symbol(),Period(),1),Digits());
   double open2 =  NormalizeDouble(iOpen(Symbol(),Period(),2),Digits());
   double close2 = NormalizeDouble(iClose(Symbol(),Period(),2),Digits());


// Update the previous rangeHigh and rangeLow with the current values before updating them with the new values

//HIGHER HIGHS, LOWER LOWS. NEED TO TRACK PREV PRICE+INDEX
//if currHigh > prevHigh, market trending up
//if currLow < prevLow market trending down
//if currHigh < prevHigh && currLow > prevLow ...indecision?
//rangeHigh is like a rolling rangeHigh
//Oliver to do:
//prevHigh = currHigh, currHigh = rangeHigh,
   rangeHighIndex =           iHighest(Symbol(),PERIOD_H4,MODE_HIGH,20,1);
   rangeLowIndex =            iLowest(Symbol(),PERIOD_H4,MODE_LOW,20,1);
   if(rangeHigh != iHigh(Symbol(),PERIOD_H4,rangeHighIndex)) //
     {
      if(!dd_up) //if we're not already in an uptrend
        {
         prevRangeHigh = rangeHigh;
         dd_up = true;
         dd_down = false;
        }
      rangeHigh = iHigh(Symbol(),PERIOD_H4,rangeHighIndex);
     }

   if(rangeLow != iLow(Symbol(),PERIOD_H4,rangeLowIndex))
     {
      if(!dd_down)
        {
         prevRangeLow = rangeLow;
         dd_down = true;
         dd_up = false;
        }
      rangeLow =                 iLow(Symbol(),PERIOD_H4,rangeLowIndex);
     }

// Print statements to verify the values
   Print("dd_up: "+dd_up);
   Print("dd_down: "+dd_down);
   Print("prevRange High: ", prevRangeHigh);
   Print("prevRange Low :  ", prevRangeLow);
   double delta = rangeHigh - rangeLow;
   if(dd_up)
     {
      low_retrace_61_4 = rangeLow + (delta * 0.614);
      low_retrace_21_0 = rangeLow + (delta * 0.21);
      low_retrace_38_6 = rangeLow + (delta * 0.386);
      low_retrace_79_0 = rangeLow + (delta * 0.79);
      DrawAOIBox("AOI_Supply", rangeHigh, high_retrace_38_6, iTime(Symbol(),PERIOD_H4,20), iTime(Symbol(),PERIOD_H4,0), BlueViolet); // A red AOI box for a supply zone
      DrawAOIBox("AOI_Demand", rangeLow, low_retrace_38_6, iTime(Symbol(),PERIOD_H4,20), iTime(Symbol(),PERIOD_H4,0), OrangeRed); // A green AOI box for a demand zone

     }
   if(dd_down)
     {
      high_retrace_61_4 = rangeHigh - (delta * 0.614);
      high_retrace_21_0 = rangeHigh - (delta * 0.21);
      high_retrace_38_6 = rangeHigh - (delta * 0.386);
      high_retrace_79_0 = rangeHigh - (delta * 0.79);
      DrawAOIBox("AOI_Supply", rangeHigh, high_retrace_38_6, iTime(Symbol(),PERIOD_H4,20), iTime(Symbol(),PERIOD_H4,0), BlueViolet); // A red AOI box for a supply zone
      DrawAOIBox("AOI_Demand", rangeLow, low_retrace_38_6, iTime(Symbol(),PERIOD_H4,20), iTime(Symbol(),PERIOD_H4,0), OrangeRed); // A green AOI box for a demand zone

     }
   Print("low_retrace 79_0:   ",low_retrace_79_0);
   Print("low_Retrace 38_6:   ",low_retrace_38_6);
   Print("low_retrace 61_4:   ",low_retrace_61_4);
   Print("low_Retrace 21_0:   ",low_retrace_21_0);
   Print("Range Low : ", rangeLow);
   Print("Delta: "+delta);
   Print("Range High: ", rangeHigh);
   Print("high_Retrace 21_0:   ",high_retrace_21_0);
   Print("high_Retrace 38_6:   ",high_retrace_38_6);
   Print("high_retrace 61_4:   ",high_retrace_61_4);
   Print("high_retrace 79_0:   ",high_retrace_79_0);

   hourlyHighIndex =           iHighest(Symbol(),PERIOD_H1,MODE_HIGH,50,1);
   hourlyLowIndex =            iLowest(Symbol(),PERIOD_H1,MODE_LOW,50,1);
   hourlyHigh =                iHigh(Symbol(),PERIOD_H1,hourlyHighIndex);
   hourlyLow =                 iLow(Symbol(),PERIOD_H1,hourlyLowIndex);
   dailyHighIndex =           iHighest(Symbol(),PERIOD_H1,MODE_CLOSE,150,1);
   dailyLowIndex =            iLowest(Symbol(),PERIOD_H1,MODE_CLOSE,150,1);
   dailyHigh =                iClose(Symbol(),PERIOD_H1,dailyHighIndex);
   dailyLow =                 iClose(Symbol(),PERIOD_H1,dailyLowIndex);
//  dailyHigh = MathMax(iHigh(Symbol(),PERIOD_D1,0),iHigh(Symbol(),PERIOD_D1,1));
// hourlyHigh = MathMax(iHigh(Symbol(),PERIOD_H1,0),iHigh(Symbol(),PERIOD_H1,1));

//0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND
   double BBM = NormalizeDouble(BB.GetValue(0,1), Digits());
   double BBU = NormalizeDouble(BB.GetValue(1,1), Digits());
   double BBL = NormalizeDouble(BB.GetValue(2,1), Digits());

   double tp =                BBM;
   double sl =                BBM;
   double lots =              InpLotSize;
   double sl_gap =            PointsToDouble(InpStopLossGapPoints);
   double entry_gap =         PointsToDouble(InpEntryGapPoints);
   double rr = (high1-low1)*InpRR;
   double tp_target = (high1-low1)*InpTakeProfitTarget;
   double candleRange = MathAbs(close1-open1);
   double pointsTarget = PointsToDouble(8,Symbol());
   datetime expiration =      iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
   string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);

//FIND ICT OBJECTS
   int object1_count = ObjectsTotal(0);
   int filter_count = ObjectsTotal(0,1);
   int purple_count = 0;
   int dark_red_count = 0;
   int buy_aoi_count = 0;
   int sell_aoi_count = 0;
   for(int i = 0; i < object1_count; i++)
     {
      string matched_string1 = "_L"; //line start
      string matched_string2 = "_AOI";
      string matched_string3 = "_R"; //line end
      string matched_string4 = "_B";
      string matched_string5 = "_C";
      string matched_string6 = "_V";
      int object_color;
      double object_price;
      string object_end_time;
      datetime object_time;
      datetime object_end_datetime;

      string object_name = ObjectName(0,i,0);
#ifdef tester
      //filter out autrade objects:
      string filter_string = "autotrade #";
      if(StringFind(object_name,filter_string,0) > -1)
        {
         ObjectDelete(0,object_name);
        }
#endif
      //identify ICT objects
      if((StringFind(object_name,matched_string1,0) > -1) || (StringFind(object_name,matched_string2,0) > -1) || (StringFind(object_name,matched_string3,0) > -1) || (StringFind(object_name,matched_string4,0) > -1) || (StringFind(object_name,matched_string5,0) > -1) || (StringFind(object_name,matched_string6,0) > -1))
        {
         Print("Finding objects by color");
         object_color = ObjectGetInteger(0,object_name,OBJPROP_COLOR);
         object_price = NormalizeDouble(ObjectGetDouble(0,object_name,OBJPROP_PRICE,0),Digits());
         object_time = (datetime)ObjectGetInteger(0,object_name,OBJPROP_TIME);

         // if (StringFind(object_name,matched_string6) > -1) {
         //     Print("_V color: "+object_color);
         //     Print(object_price);
         // }
         //     if (StringFind(object_name,matched_string1) > -1) {
         //     Print("_R color: "+object_color);
         //     Print(object_price);
         // }
         // PURPLE ZIGZAG;
         if(object_color == 15631086 && StringFind(object_name,matched_string3) > -1)
           {
            last_purple_price = object_price;
            //  Print("Purple end:   "+object_time+" "+object_price);
            purple_count++;
           };
         //DARK RED ZIGZAG
         if(object_color == 2237106 && StringFind(object_name,matched_string3,0) > -1)
           {
            last_dark_red_price = object_price;
            // Print("Dark red end: "+object_time+" "+object_price);
            dark_red_count++;
           };

         //DARK BLUE BOX
         if(object_color == 14772545 && StringFind(object_name,matched_string2) > -1)
           {
            // Print("SELL_AOI end: "+object_time+" "+object_price);
            sell_aoi_count++;
            blue_bottom = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue box
            last_blue_bottom_price = object_price;
           };
         //DARK BLUE BORDER BOTTOM represents a low point based on zigzag indicator?
         if(object_color == 14772545 && StringFind(object_name,matched_string4) > -1)
           {
            // Print("ZZ_LOW end: "+object_time+" "+object_price);
            blue_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue border
            last_blue_border_price = object_price;
           };
         //AQUA BOX
         if(object_color == 16776960 && StringFind(object_name,matched_string2) > -1)
           {
            // Print("BUY_AOI end:  "+object_time+" "+object_price);
            buy_aoi_count++;
            aqua_top = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua box
            last_aqua_top_price = object_price;
           };
         //AQUA BORDER TOP represents a high point based on zig zag indicator
         if(object_color == 16776960 && StringFind(object_name,matched_string4) > -1)
           {
            // Print("ZZ_BUY_B end:  "+object_time+" "+object_price);
            aqua_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua border
            last_aqua_border_price = object_price;
           };
        };

     };
// breakout signals based on divergence?
//If vfo is rising and zz is falling, and vice versa.
//if zz is up and (htf zz is down OR vfo)
// Print("dark_red_count:"+dark_red_count);
// Print("filter_count:"+filter_count);
// Print("purple_count:"+purple_count);
// Print("Signal total:"+signal_total);
// Print("buy_aoi_total:"+buy_aoi_total);
// Print("sell_aoi_total:"+sell_aoi_total);
   if(buy_aoi_total != buy_aoi_count)
     {
      Print("buy_aoi added. buy_aoi_total was "+buy_aoi_total+" and is now "+buy_aoi_count);
      buy_aoi_total = buy_aoi_count;
      last_buy_aoi = TimeCurrent();

      // canShort = false; canLong = true;
     };
   if(sell_aoi_total != sell_aoi_count)
     {
      Print("sell_aoi added. sell_aoi_total was "+sell_aoi_total+" and is now "+sell_aoi_count);
      sell_aoi_total = sell_aoi_count;
      last_sell_aoi = TimeCurrent();

      // canShort = true; canLong = false;
      // bullishPattern = 0; bearishPattern = 0;
      // fvboLong = 0; fvboShort = 0;
     };
   if(purple_total != purple_count)
     {
      Print("Purple added. Purple total was "+purple_total+" and is now "+purple_count); //not correct, need to paint vfo for debugging
      purple_total = purple_count;
      //SELL BREAKOUT SIGNAL - just left a dark blue box
      if(filter_total == filter_count)
        {
         signal_total++;
         last_purple_signal = TimeCurrent();
         // canLong = false; canShort = true;
        };
     };
   if(dark_red_total != dark_red_count)
     {
      Print("Dark red added. Dark red total was "+dark_red_total+" and is now "+dark_red_count); //not correct, need to paint vfo for debugging
      dark_red_total = dark_red_count;
      //BUY BREAKOUT SIGNAL - just left an aqua box
      if(filter_total == filter_count)
        {
         signal_total++;
         last_dark_red_signal = TimeCurrent();
         // canLong = true; canShort = false;
        }
     };
//FILTER SIGNALS
   Print("Filtering signals...");
   if(filter_total != filter_count)
     {
      Print("Signal filtered. Filter total was "+filter_total+" and is now "+filter_count);
      filter_total = filter_count;
     };

   last_blue_bottom_bar = iBarShift(Symbol(),Period(),last_sell_aoi);
   last_aqua_top_bar = iBarShift(Symbol(),Period(),last_buy_aoi);
   last_breakout_buy_bar = iBarShift(Symbol(),Period(),last_dark_red_signal); //needs fixing
   last_breakout_sell_bar = iBarShift(Symbol(),Period(),last_purple_signal); //needs fixing


   if(last_blue_bottom_bar > last_aqua_top_bar)
     {
      canShort = false;
      canLong = true;
      // DrawFibonacciLevels(rangeLow,rangeHigh,clrGreen,PERIOD_H4);
     }
   if(last_blue_bottom_bar < last_aqua_top_bar)
     {
      canShort = true;
      canLong = false;
      // DrawFibonacciLevels(rangeHigh,rangeLow,clrRed,PERIOD_H4);
     }
   Print("Last blue_bottom_price: "+last_blue_bottom_price);  //supply zone
   Print("Last blue_border_price: "+ last_blue_border_price); //supply zone
   Print("Last aqua_top_price: "+ last_aqua_top_price); //demand zone
   Print("Last aqua_border_price: "+ last_aqua_border_price); //demand zone
   Print("Last breakout_buy_bar: "+ last_breakout_buy_bar);
   Print("Last breakout_sell_bar: "+ last_breakout_sell_bar);
   ShowRange(rangeHigh,rangeLow,BlueViolet,OrangeRed,2);

//if rangeLowIndex < rangeHighIndex, zz going up
// Print("RangeHighIndex"+rangeHighIndex);
// Print("RangeLowIndex"+rangeLowIndex);
//if rangeLowIndex < rangeHighIndex, zz going up and our box is aqua
// Print("HourlyHighIndex"+hourlyHighIndex);
// Print("HourlyLowIndex"+hourlyLowIndex);

//if (high_retrace_38_6 < low_retrace_38_6) {
//    Print("High retrace < Low retace. Returning.");
//  return;
//}
//improved results!
//  if(last_aqua_top_price >= last_blue_bottom_price)
//  {
// Print("S&D bunched together. Returning.");
// return;
//  }
   ulong last_deal_ticket = GetLastDealTicket();                  //last deal ticket
   ulong minutes_since_deal = GetMinutesSinceDeal(last_deal_ticket); //mins since last deal
   ulong hold_mins = barsToMinutes(InpHoldBars);
   ulong wait_mins = barsToMinutes(InpWaitBars);
 if(PositionsTotal() == InpMaxPositions)
   {
    if(minutes_since_deal > hold_mins)
      {
       PrintFormat("Held too long, closing position");
       Trade.PositionClose(Symbol(),last_deal_ticket);
      }
   }
 if(PositionsTotal() == 0)
   {
    if(minutes_since_deal < wait_mins)
      {
       PrintFormat("Too soon to place another deal, returning.");
       return;
      }
   }

   Print("Finding FVBO Signals...");
////////////////////FVBO SIGNALS////////////////
   if(close2 < BB.GetValue(2,2) && close1 > open1 && !fvbo_buy_flag)
     {
      fvboLong++;
      drawFVBO(1,clrPink);
      fvbo_buy_flag = true;
      fvbo_sell_flag = false;
      prev_fvbo_buy_index = fvbo_buy_index;
      fvbo_buy_index = 0;
      PrintFormat("prev_fvbo_buy_index: %i\nfvbo_buy_index: %i",prev_fvbo_buy_index,fvbo_buy_index);
      buy_signal_time = TimeCurrent();
     }
   fvbo_buy_index++;
   prev_fvbo_buy_index++;
   if(close2 > BB.GetValue(1,2) && close1 < open1 && !fvbo_sell_flag)
     {
      fvboShort++;
      drawFVBO(1,clrPink);
      fvbo_buy_flag = false;
      fvbo_sell_flag = true;
      PrintFormat("FVBO SELL");
      prev_fvbo_sell_index = fvbo_sell_index;
      fvbo_sell_index = 0;
      PrintFormat("prev_fvbo_sell_index: %i\nfvbo_sell_index: %i",prev_fvbo_sell_index,fvbo_sell_index);
      sell_signal_time = TimeCurrent();
     }
   fvbo_sell_index++;
   prev_fvbo_sell_index++;
///////////////////FVBO TRADE MANAGEMENT/////////////////////
   double price = (ask + bid) / 2;
//vbo 2.0 hammer in an uptrend
   fvbo_buy_flag = false;
   fvbo_sell_flag = false;
   canLong = false;
   canShort = false;
///////////////////VBO TRADE MANAGEMENT///////////
//if DD aligned and S+D not bunched, trade
//if closed outside BB && dd up && s 386 is above d386
//FILTERS
if (high_retrace_61_4 < low_retrace_61_4){ Print("Retracement levels bunched. Returning."); return;}

   if(
   dd_up &&
   close1 < BB.GetValue(0,0) && //and bullish
   RSI.GetValue(0) <= 30 &&
//   close1 < BB_M30.GetValue(0,0) &&
//   RSI_M30.GetValue(0) < 50 &&
   //close1 < BB_H1.GetValue(2,0) &&
   MACD.GetValue(0,0) < MACD.GetValue(1,0)
   )
     {
      //PLACE BUY ORDER
      Print("Conditions met for BUY");
      sl = low1-PointsToDouble(100,Symbol());
      price = high1;
      tp = high1+PointsToDouble(200,Symbol());
      Trade.BuyStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
     }
   if(
   dd_down && 
   close1 > BB.GetValue(0,0) && 
   RSI.GetValue(0) >= 70 &&
//   close1 > BB_M30.GetValue(0,0) &&
//   RSI_M30.GetValue(0) > 50 &&
//   close1 > BB_H1.GetValue(1,0) &&
   MACD.GetValue(0,0) > MACD.GetValue(1,0)
   )
     {
      //PLACE SELL ORDER
      Print("Conditions met for SELL");
      sl = high1+PointsToDouble(100,Symbol());
      price = low1;
      tp = low1-PointsToDouble(100,Symbol());
      Trade.SellStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
     }

   if(fvbo_buy_flag)
     {
      int buy_signal_candle = iBarShift(Symbol(),Period(),buy_signal_time,false);
      if(buy_signal_candle > lookback)
        {
         fvbo_buy_flag = false;
        }
      //PLACE BUY ORDER
      sl = low1;
      price = high1;
      tp = BBM;
      if(PositionsTotal() == 1)
        {
         fvbo_buy_flag = false;
         return;
        }
      if(!canLong)
        {
         fvbo_buy_flag = false;
         return;
        }
      //if ask is too high, don't buy.
      Trade.BuyStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
     }

   if(fvbo_sell_flag)
     {
      int sell_signal_candle = iBarShift(Symbol(),Period(),sell_signal_time,false);
      if(sell_signal_candle > lookback)
        {
         fvbo_sell_flag = false;
         return;
        }
      //Place a sell order
      sl         = high1;
      price      = low1;
      tp = BBM;
      if(PositionsTotal() == 1)
        {
         fvbo_sell_flag = false;
         return;
        }
      if(!canShort)
        {
         fvbo_sell_flag = false;
         return;
        }
      //if bid is too low, don't sell.
      Trade.SellStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getLastSignalIndex(datetime t)
  {
   return -1;
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
void DrawAOIBox(string name, double lower_price, double upper_price, datetime start_time, datetime end_time, color box_color)
  {
// if (ObjectFind(0, name) == -1) {
   if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, start_time, lower_price, end_time, upper_price))
     {
      Print("Error creating AOI BOX: ", GetLastError());
      return;
     };
// }
   ObjectSetInteger(0, name, OBJPROP_COLOR, box_color);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
  }
//EXAMPLE USAGE:
/*
DrawAOIBox("AOI_Supply", 1.2000, 1.2050, Time[50], Time[0], clrRed); // A red AOI box for a supply zone
DrawAOIBox("AOI_Demand", 1.1800, 1.1850, Time[50], Time[0], clrGreen); // A green AOI box for a demand zone
*/


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawFibonacciLevels(double price1, double price2, color FiboClr, ENUM_TIMEFRAMES tf)
  {
// Define anchor points for the Fibonacci levels
   datetime time1 = iTime(Symbol(), tf, 100);  // Example anchor point 1
   datetime time2 = iTime(Symbol(), tf, 0);   // Example anchor point 2

// Create Fibonacci object
   if(!ObjectCreate(0, InpFiboName, OBJ_FIBO, 0, time1, price1, time2, price2))
     {
      Print("Error creating Fibonacci object: ", GetLastError());
      return;
     }

// Set object properties
   ObjectSetInteger(0, InpFiboName, OBJPROP_COLOR, FiboClr);
   ObjectSetInteger(0, InpFiboName, OBJPROP_STYLE, InpFiboStyle);
   ObjectSetInteger(0, InpFiboName, OBJPROP_WIDTH, InpFiboWidth);
   ObjectSetInteger(0, InpFiboName, OBJPROP_RAY_RIGHT, InpFiboRayRight);

// Set Fibonacci levels and prices
   double levels[] = {InpLevel1, InpLevel2, InpLevel3, InpLevel4, InpLevel5, InpLevel6, InpLevel7};
   double priceAtLevels[ArraySize(levels)];

   for(int i = 0; i < ArraySize(levels); i++)
     {
      ObjectSetDouble(0, InpFiboName, OBJPROP_LEVELVALUE, i, levels[i]);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELSTYLE, i, InpFiboStyle);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELWIDTH, i, InpFiboWidth);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELCOLOR, i, FiboClr);

      // Calculate price at each level
      priceAtLevels[i] = price1 + (price2 - price1) * levels[i];
      Print("Level ", levels[i] * 100, "%: Price ", priceAtLevels[i]);

      // Create text label for price
      string labelName = InpFiboName + "_Price_" + IntegerToString(i);
      if(!ObjectCreate(0, labelName, OBJ_TEXT, 0, time2, priceAtLevels[i]))
        {
         Print("Error creating label: ", GetLastError());
         return;
        }
      ObjectSetString(0, labelName, OBJPROP_TEXT, DoubleToString(priceAtLevels[i], Digits()));
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, FiboClr);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
     }
  }
//+------------------------------------------------------------------+
//|                       Bias for MACD, RSI, BB                   |
//+------------------------------------------------------------------+
int getBias()
  {
   return 0;
  }
//+------------------------------------------------------------------+
//|           Both in oversold/overbought territory                  |
//+------------------------------------------------------------------+
bool getBBRiverConfluence(ENUM_TIMEFRAMES tf1, ENUM_TIMEFRAMES tf2)
  {
   return false;
  }
//+------------------------------------------------------------------+
//|           is the supply box overlapping demand box?              |
//+------------------------------------------------------------------+
bool getSupplyAndDemandZoneIsBunched(double supply, double demand)
  {
   return false;
  }
//+------------------------------------------------------------------+
//|                 is this the 1st test of s+d box?                 |
//+------------------------------------------------------------------+
bool getFirstTestOfSupplyAndDemandZone()
  {
   return false;
  }
//are we experience higher highs, and higher lows?
//or lower highs and lower lows?
int getDominantDirection()
  {
   return -1;
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
//|

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
