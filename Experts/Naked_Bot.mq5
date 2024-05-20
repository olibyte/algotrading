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
CIndicatorRSI RSI;
CIndicatorMACD MACD;
//FVBO
bool fvbo_buy_flag,fvbo_sell_flag;
datetime buy_signal_time, sell_signal_time;
double rangeHigh,rangeLow;
double prevLow, prevHigh = 0;
double hourlyLow, hourlyHigh,dailyLow,dailyHigh;
int rangeHighIndex, rangeLowIndex, hourlyLowIndex, hourlyHighIndex,dailyLowIndex,dailyHighIndex,prev_fvbo_buy_index,fvbo_buy_index,fvbo_sell_index,prev_fvbo_sell_index, barsSinceLastLow, barsSinceLastHigh;
int rsi_score, bb_score, macd_score, highTestCount,lowTestCount = 0;
bool found_target = false;
bool canShort = true;
bool canLong = true;
double blue_bottom, aqua_top, blue_border, aqua_border;

//ICT
// _AOI_SELL:14772545
// _AOI_BUY: 16776960

int filter_total, purple_total, dark_red_total,signal_total, buy_aoi_total,sell_aoi_total = 0;
datetime last_purple_signal, last_dark_red_signal, last_buy_aoi, last_sell_aoi;
int OnInit()
  {
    // string indicator_name = "Step_2_ICT_Breakout_Indicator.ex5";
  //  HandleICT = iCustom(Symbol(), Period(),"Step_2_ICT_Breakout_Indicator.ex5",external_use,max_bars,htf,aoi_lower_level,aoi_higher_level,breakout_add_pips,enable_alert,enable_email,enable_mobile,zz_InpDepth_ltf,zz_InpDeviation_ltf,zz_InpBackstep_ltf,zz_InpDepth_htf,zz_InpDeviation_htf,zz_InpBackstep_htf,InpPeriod,InpCoeff,InpCoeffV,InpPeriodSm,enable_zz_htf,zz_htf_clr_buy,zz_htf_clr_sell,enable_zz_ltf,zz_ltf_clr_buy,zz_ltf_clr_sell,enable_zz_br,zz_br_clr_buy,zz_br_clr_sell,enable_aoi,zz_aoi_clr_buy,zz_aoi_clr_sell,enable_diver,zz_div_clr_buy,zz_div_clr_sell,zz_div_width);   
  //  ArraySetAsSeries(ValuesICT,true);


   BB.Init(Symbol(), Period(), InpBBPeriod, 0, InpBBDeviations, InpBBAppliedPrice);
   MACD.Init(Symbol(),Period(),8,21,5,PRICE_CLOSE);
   RSI.Init(Symbol(),Period(),5,PRICE_CLOSE);

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
   if(!IsNewBar()) return;                     // still looking at same bar
   if(!WaitForHTF(Symbol(), PERIOD_D1)) return;   // Anchor data not available
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits()); //long
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits()); //short
//OHLC for latest 2 fully formed bars
   double open1 =  NormalizeDouble(iOpen(Symbol(),Period(),1),Digits());
   double high1 =  NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
   double low1 =   NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
   double close1 = NormalizeDouble(iClose(Symbol(),Period(),1),Digits());
   double open2 =  NormalizeDouble(iOpen(Symbol(),Period(),2),Digits());
   double high2 =  NormalizeDouble(iHigh(Symbol(),Period(),2),Digits());
   double low2 =   NormalizeDouble(iLow(Symbol(),Period(),2),Digits());
   double close2 = NormalizeDouble(iClose(Symbol(),Period(),2),Digits());
//HIGHER HIGHS, LOWER LOWS
   rangeHighIndex =           iHighest(Symbol(),Period(),MODE_CLOSE,7,2);
   rangeLowIndex =            iLowest(Symbol(),Period(),MODE_CLOSE,7,2);
   rangeHigh =                iClose(Symbol(),Period(),rangeHighIndex);
   rangeLow =                 iClose(Symbol(),Period(),rangeLowIndex);
   hourlyHighIndex =           iHighest(Symbol(),PERIOD_H1,MODE_CLOSE,50,0);
   hourlyLowIndex =            iLowest(Symbol(),PERIOD_H1,MODE_CLOSE,50,0);
   hourlyHigh =                iClose(Symbol(),PERIOD_H1,hourlyHighIndex);
   hourlyLow =                 iClose(Symbol(),PERIOD_H1,hourlyLowIndex);
   dailyHighIndex =           iHighest(Symbol(),PERIOD_H1,MODE_CLOSE,150,0);
   dailyLowIndex =            iLowest(Symbol(),PERIOD_H1,MODE_CLOSE,150,0);
   dailyHigh =                iClose(Symbol(),PERIOD_H1,dailyHighIndex);
   dailyLow =                 iClose(Symbol(),PERIOD_H1,dailyLowIndex);
  //  dailyHigh = MathMax(iHigh(Symbol(),PERIOD_D1,0),iHigh(Symbol(),PERIOD_D1,1));
  // hourlyHigh = MathMax(iHigh(Symbol(),PERIOD_H1,0),iHigh(Symbol(),PERIOD_H1,1));

//0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND
   double BBM = NormalizeDouble(BB.GetValue(0,1), Digits());
   double BBU = NormalizeDouble(BB.GetValue(1,1), Digits());
   double BBL = NormalizeDouble(BB.GetValue(2,1), Digits());

   double tp =                BBM;
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
     for (int i = 0; i < object1_count; i++) {
      string object_name = ObjectName(0,i,0);

      //filter out autrade objects:
      string filter_string = "autotrade #";
      if (StringFind(object_name,filter_string,0) > -1) {
        ObjectDelete(0,object_name);
      }
      //identify ICT objects
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
      if ((StringFind(object_name,matched_string1,0) > -1) || (StringFind(object_name,matched_string2,0) > -1) || (StringFind(object_name,matched_string3,0) > -1) || (StringFind(object_name,matched_string4,0) > -1) || (StringFind(object_name,matched_string5,0) > -1) || (StringFind(object_name,matched_string6,0) > -1)) {
        object_color = ObjectGetInteger(0,object_name,OBJPROP_COLOR);
        object_price = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
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
        if (object_color == 15631086 && StringFind(object_name,matched_string3) > -1)
          {
         Print("Purple end:   "+object_time+" "+object_price);
         purple_count++;
      };
      //DARK RED ZIGZAG
       if (object_color == 2237106 && StringFind(object_name,matched_string3) > -1) {
        Print("Dark red end: "+object_time+" "+object_price);
        dark_red_count++;
      };

      //DARK BLUE BOX
      if (object_color == 14772545 && StringFind(object_name,matched_string2) > -1) {
        Print("SELL_AOI end: "+object_time+" "+object_price);
        sell_aoi_count++;
        blue_bottom = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue box       
      };
      //DARK BLUE BORDER BOTTOM represents a low point based on zigzag indicator?
      if (object_color == 14772545 && StringFind(object_name,matched_string4) > -1) {
        Print("ZZ_LOW end: "+object_time+" "+object_price);
        blue_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue border
      };
      //AQUA BOX
      if (object_color == 16776960 && StringFind(object_name,matched_string2) > -1) {
        Print("BUY_AOI end:  "+object_time+" "+object_price);
        buy_aoi_count++;
        aqua_top = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua box
      };
      //AQUA BORDER TOP represents a high point based on zig zag indicator
      if (object_color == 16776960 && StringFind(object_name,matched_string4) > -1) {
        Print("ZZ_BUY_B end:  "+object_time+" "+object_price);
        aqua_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua border
      };
      //zz_htf_clr_buy=10156544; 
      //zz_htf_clr_sell=17919;
    
    };
   };
  Print("dark_red_count:"+dark_red_count);
  Print("filter_count:"+filter_count);
  Print("purple_count:"+purple_count);
  Print("Signal total:"+signal_total);
  Print("buy_aoi_total:"+buy_aoi_total);
  Print("sell_aoi_total:"+sell_aoi_total);
    if (buy_aoi_total != buy_aoi_count) {
      Print("buy_aoi added. buy_aoi_total was "+buy_aoi_total+" and is now "+buy_aoi_count);
      buy_aoi_total = buy_aoi_count;
      last_buy_aoi = TimeCurrent();
  };
    if (sell_aoi_total != sell_aoi_count) {
      Print("sell_aoi added. sell_aoi_total was "+sell_aoi_total+" and is now "+sell_aoi_count);
      sell_aoi_total = sell_aoi_count;
      last_sell_aoi = TimeCurrent();
  };
    if (purple_total != purple_count) {
    Print("Purple added. Purple total was "+purple_total+" and is now "+purple_count);
    purple_total = purple_count;
    //SELL BREAKOUT SIGNAL - just left a dark blue box
    if (filter_total == filter_count) { 
      signal_total++;
      // canShort = true; canLong = false;
      last_purple_signal = TimeCurrent();
      };
  };
      if (dark_red_total != dark_red_count) {
    Print("Dark red added. Dark red total was "+dark_red_total+" and is now "+dark_red_count);
    dark_red_total = dark_red_count;
    //BUY BREAKOUT SIGNAL - just left an aqua box
    if (filter_total == filter_count) { 
      signal_total++;
      canShort = false; canLong = true;
      last_dark_red_signal = TimeCurrent();
      }
  };
  //FILTER SIGNALS
  if (filter_total != filter_count) {
    Print("Signal filtered. Filter total was "+filter_total+" and is now "+filter_count);
    filter_total = filter_count;
  };
  if (signal_total == 0) {
    canShort = true; canLong = true;
  }

  Print("Last purple signal:   "+last_purple_signal);
  Print("Last dark red signal: "+last_dark_red_signal);
  Print("Last buy_aoi signal:  "+last_buy_aoi);
  Print("Last sell_aoi signal: "+last_sell_aoi);
  Print("canShort: "+canShort+"canLong: "+canLong);
  Print("blue_aoi_bottom: "+blue_bottom);
  Print("blue_border_bottom: "+blue_border);
  Print("aqua_aoi_top:    "+aqua_top);
  Print("aqua_border_top: "+aqua_border);
  canLong = true; canShort = true;
  if (last_buy_aoi > last_sell_aoi) {
    Print("BULLISH");
    canLong = true; canShort = false;
  } else {
    Print("BEARISH");
    canLong = false; canShort = true;
  }
  Print("canLong: "+canLong+" canShort: "+canShort);
  // int blue_border_top_index = iHighest(Symbol(),Period(),MODE_HIGH,1000,2);
  // double blue_border_top = iClose(Symbol(),Period(),blue_border_top_index);
  // Print("blue_border_top? "+blue_border_top);

  //82.175 = low = blue border bottom
  //83.063572 = //blue bottom
  
  //REVERSE ENGINEERING FOR A 38.2 FIB LEVEL
  //FIB_LEVEL = 38.2
  //83.063572−82.175=0.382×(High Point−82.175)
  //0.888572=0.382×(High Point−82.175)
  //High Point-82.175= (0.888572/0.382 )
  //High Point=82.175+ (0.888572/0.382 )
  //High Point=82.175+2.326
  //  High Point=84.501 //OUR BLUE BORDER TOP LEVEL

  //REVERSE ENGINEERING FOR A 79.0 FIB LEVEL
  //FIB_LEVEL = 79
  //83.063572−82.175=0.79×(High Point−82.175)
  //0.888572=0.79×(High Point−82.175)
//  82.175 = 0.79
  //High Point-82.175= (0.888572/0.382 )
  //High Point=82.175+ (0.888572/0.382 )
  //High Point=82.175+2.326
  //  High Point=84.501 //OUR BLUE BORDER TOP LEVEL



  //82.175 +0.386 * 2 //blue bottom (what we think the algorithm is)
  //82.175 + 0.79 * 2 //blue top
  //FIND THE HIGH POINT
  //0.386 * (HIGHPOINT - blue border bottom)                     //blue border top, an unknown high point

   ulong last_deal_ticket = GetLastDealTicket();                  //last deal ticket
   ulong minutes_since_deal = GetMinutesSinceDeal(last_deal_ticket); //mins since last deal
   ulong hold_mins = barsToMinutes(InpHoldBars);
   ulong wait_mins = barsToMinutes(InpWaitBars);
   if(PositionsTotal() == InpMaxPositions)
     {
      if (minutes_since_deal > hold_mins) {
        PrintFormat("Held too long, closing position");
        Trade.PositionClose(Symbol(),last_deal_ticket);
      }
     }
     if (PositionsTotal() == 0) {
      if (minutes_since_deal < wait_mins) {
          PrintFormat("Too soon to place another deal, returning.");
          return;
      }
     } 



////////////////////FVBO SIGNALS////////////////
   if(close2 < BB.GetValue(2,2) && close1 > open1 && !fvbo_buy_flag)
     {
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
   if(close2 > BB.GetValue(1,2) && close1 < open1 && !fvbo_sell_flag
   )
     {
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
    // Check if the price is in or near an aqua box (BUY_AOI)
    // if (price >= aqua_top) // Assuming aqua_top is the upper limit of the aqua box
    // {
    //     canLong = true;
    //     canShort = false;
    // }

   if(fvbo_buy_flag && canLong)
     {
      //check if search has expired
      int lookback = 5;
      int buy_signal_candle = iBarShift(Symbol(),Period(),buy_signal_time,false);
      if(buy_signal_candle > lookback)
        { fvbo_buy_flag = false; }
      //PLACE BUY ORDER
      double sl =    NormalizeDouble(low1-sl_gap,   Digits());
      double price = high1;
      double tp =    price + tp_target;

      //RiskReward must be below midline and score must be positive
      if(price+rr < BBM && candleRange > pointsTarget)
        {
        Trade.BuyStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
        }
     }
    // Check if the price is in or near a dark blue box (SELL_AOI)
    // if (price <= blue_bottom) // Assuming blue_bottom is the lower limit of the dark blue box
    // {
    //     canShort = true;
    //     canLong = false;
    // }
   if(fvbo_sell_flag && canShort)
     {
      int lookback = 5;
      int sell_signal_candle = iBarShift(Symbol(),Period(),sell_signal_time,false);
      if(sell_signal_candle > lookback)
        {
         fvbo_sell_flag = false;
        }
      //Place a sell order
      double sl         = NormalizeDouble(high1+sl_gap,Digits());
      double price      = low1;
      double tp         = price - tp_target;

      if(price-rr > BBM && candleRange > pointsTarget)
        {
         if(PositionsTotal() == 1)
           {
            fvbo_sell_flag = false;
            return;
           }
         Trade.SellStop(lots,price,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
        }
     }
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLowTest(int i, color c, int count)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "TestL" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"TestL" + setupTime,OBJPROP_TEXT,"t"+count);
   ObjectSetInteger(0, "TestL" + setupTime, OBJPROP_COLOR, c);
   ObjectSetDouble(0,"TestL" + setupTime,OBJPROP_ANGLE,0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawHighTest(int i, color c,int count)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "TestH" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"TestH" + setupTime,OBJPROP_TEXT,"t"+count);
   ObjectSetInteger(0, "TestH" + setupTime, OBJPROP_COLOR, c);
   ObjectSetDouble(0,"TestH" + setupTime,OBJPROP_ANGLE,0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawNewLow(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "SetupL" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"SetupL" + setupTime,OBJPROP_TEXT,"L");
   ObjectSetInteger(0, "SetupL" + setupTime, OBJPROP_COLOR, c);
    ObjectSetInteger(0,"SetupH" + setupTime,OBJPROP_WIDTH,2);
   ObjectSetDouble(0,"SetupL" + setupTime,OBJPROP_ANGLE,0.0);
  }
  void drawPrevLow(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "PrevL" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"PrevL" + setupTime,OBJPROP_TEXT,"L");
   ObjectSetInteger(0, "PrevL" + setupTime, OBJPROP_COLOR, c);
    ObjectSetInteger(0,"Prev" + setupTime,OBJPROP_WIDTH,2);
   ObjectSetDouble(0,"PrevL" + setupTime,OBJPROP_ANGLE,0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawNewHigh(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "SetupH" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"SetupH" + setupTime,OBJPROP_TEXT,"H");
   ObjectSetInteger(0, "SetupH" + setupTime, OBJPROP_COLOR, c);
   ObjectSetInteger(0,"SetupH" + setupTime,OBJPROP_WIDTH,2);
   ObjectSetDouble(0,"SetupH" + setupTime,OBJPROP_ANGLE,0.0);
  }
  void drawPrevHigh(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "PrevH" + setupTime, OBJ_TEXT, 0, setupTime, iLow(Symbol(),Period(),i));
   ObjectSetString(0,"PrevH" + setupTime,OBJPROP_TEXT,"H");
   ObjectSetInteger(0, "PrevH" + setupTime, OBJPROP_COLOR, c);
   ObjectSetInteger(0,"PrevH" + setupTime,OBJPROP_WIDTH,2);
   ObjectSetDouble(0,"PrevH" + setupTime,OBJPROP_ANGLE,0.0);
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
