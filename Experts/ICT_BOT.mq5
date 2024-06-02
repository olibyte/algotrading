//+------------------------------------------------------------------+
//|                                                      ICT_Bot.mq5 |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#include <Trade/Trade.mqh>
#include <Indicators/IndicatorBollinger.mqh>
#include <Utils.mqh>

input int InpBBPeriod = 20; // Bollinger period
input double InpBBDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE InpBBAppliedPrice = PRICE_CLOSE; // Bollinger applied price

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


// // Input parameters for the Zig Zag indicator
input ENUM_TIMEFRAMES InpZigZagTimeframe = PERIOD_H4; // Zig Zag timeframe
input int InpZigZagDepth = 12;          // Zig Zag Depth
input double InpZigZagDeviation = 5.0;       // Zig Zag Deviation
input int InpZigZagBackstep = 3;        // Zig Zag Backstep
int zigzag_handle;


//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CIndicatorBollinger BB;

int filter_total, purple_total, dark_red_total,signal_total, buy_aoi_total,sell_aoi_total = 0;
datetime last_purple_signal, last_dark_red_signal, last_buy_aoi, last_sell_aoi;
double blue_bottom, aqua_top, blue_border, aqua_border;
//identify ICT objects

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      BB.Init(Symbol(), Period(), InpBBPeriod, 0, InpBBDeviations, InpBBAppliedPrice);

     zigzag_handle = iCustom(Symbol(), InpZigZagTimeframe, "Examples\\ZigZag", InpZigZagDepth, InpZigZagDeviation, InpZigZagBackstep);
 if (zigzag_handle == INVALID_HANDLE)
     {
      Print("Failed to initialize ZigZag indicator. Error code: ", GetLastError());
      return(INIT_FAILED);
     }
     return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    // Delete Fibonacci levels from the chart
   ObjectDelete(0, InpFiboName);
     // Release ZigZag indicator handle
   if (zigzag_handle != INVALID_HANDLE)
     {
      IndicatorRelease(zigzag_handle);
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if(!IsNewBar()) return;                    // still looking at same bar
     // Retrieve ZigZag values
   double zigzagBuffer[];
   int copied = CopyBuffer(zigzag_handle, 0, 0, 100, zigzagBuffer);
   if(copied <= 0)
     {
      Print("Failed to copy ZigZag buffer. Error code: ", GetLastError());
      return;
     }
   // Process ZigZag values
   for(int i = 0; i < copied; i++)
     {
      if(zigzagBuffer[i] != 0.0)
        {
        //  Print("ZigZag point at ", TimeToString(iTime(Symbol(), InpZigZagTimeframe, i)), " Price: ", zigzagBuffer[i]);
        }
     }
    // if(!WaitForHTF(Symbol(), PERIOD_H4)) return;   // Anchor data not available
   //FIND ICT OBJECTS
      int object1_count = ObjectsTotal(0); int filter_count = ObjectsTotal(0,1);
      int purple_count, dark_red_count, buy_aoi_count, sell_aoi_count = 0;
      
        //price action
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits()); //long
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits()); //short
        double price = NormalizeDouble((ask+bid) / 2, Digits());
        double sl, tp;
        Print("Price is: "+price);

string matched_string1 = "_L"; //line start
string matched_string2 = "_AOI";
string matched_string3 = "_R"; //line end
string matched_string4 = "_B";
string matched_string5 = "_C";
string matched_string6 = "_V";
int object_color;
double object_price;
datetime object_time;


     for (int i = 0; i < object1_count; i++) {
        string object_name = ObjectName(0,i,0);

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
        //  Print("Purple end:   "+object_time+" "+object_price);
         purple_count++;
      };
      //DARK RED ZIGZAG
       if (object_color == 2237106 && StringFind(object_name,matched_string3) > -1) {
        // Print("Dark red end: "+object_time+" "+object_price);
        dark_red_count++;
      };

      //DARK BLUE BOX
      if (object_color == 14772545 && StringFind(object_name,matched_string2) > -1) {
        // Print("SELL_AOI end: "+object_time+" "+object_price);
        sell_aoi_count++;
        blue_bottom = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue box       
      };
      //DARK BLUE BORDER BOTTOM represents a low point based on zigzag indicator?
      if (object_color == 14772545 && StringFind(object_name,matched_string4) > -1) {
        // Print("ZZ_LOW end: "+object_time+" "+object_price);
        blue_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0); //bottom of the blue border
      };
      //AQUA BOX
      if (object_color == 16776960 && StringFind(object_name,matched_string2) > -1) {
        // Print("BUY_AOI end:  "+object_time+" "+object_price);
        buy_aoi_count++;
        aqua_top = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua box
      };
      //AQUA BORDER TOP represents a high point based on zig zag indicator
      if (object_color == 16776960 && StringFind(object_name,matched_string4) > -1) {
        // Print("ZZ_BUY_B end:  "+object_time+" "+object_price);
        aqua_border = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);  //top of the aqua border
      };    
    };
   };
   
    if (buy_aoi_total != buy_aoi_count) {
      Print("buy_aoi added. buy_aoi_total was "+buy_aoi_total+" and is now "+buy_aoi_count);
      buy_aoi_total = buy_aoi_count;
      last_buy_aoi = TimeCurrent();
      // canShort = false; canLong = true;
      // bullishPattern = 0; bearishPattern = 0;
      // fvboLong = 0; fvboShort = 0;
  };
    if (sell_aoi_total != sell_aoi_count) {
      Print("sell_aoi added. sell_aoi_total was "+sell_aoi_total+" and is now "+sell_aoi_count);
      sell_aoi_total = sell_aoi_count;
      last_sell_aoi = TimeCurrent();
      // canShort = true; canLong = false;
      // bullishPattern = 0; bearishPattern = 0;
      // fvboLong = 0; fvboShort = 0;
  };
    if (purple_total != purple_count) {
    Print("Purple added. Purple total was "+purple_total+" and is now "+purple_count);
    purple_total = purple_count;
    //SELL BREAKOUT SIGNAL - just left a dark blue box
    if (filter_total == filter_count) { 
      signal_total++;
      last_purple_signal = TimeCurrent();
      //place trade
      Print("Placing Sell...");
        datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
        sl = NormalizeDouble(iHigh(Symbol(), PERIOD_H4, 0),Digits());    // Example price 2
        tp = NormalizeDouble(BB.GetValue(2,1), Digits());
        Print("$$: "+price);
        Print("sl: "+sl);
        Print("tp: "+tp);
        Trade.SellStop(0.1,NormalizeDouble(ask,Digits()),Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
      };
  };
      if (dark_red_total != dark_red_count) {
    Print("Dark red added. Dark red total was "+dark_red_total+" and is now "+dark_red_count);
    dark_red_total = dark_red_count;
    //BUY BREAKOUT SIGNAL - just left an aqua box
    if (filter_total == filter_count) { 
      signal_total++;
      last_dark_red_signal = TimeCurrent();
        //place buy trade
        Print("Placing buy...");
          datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
        sl = NormalizeDouble(iLow(Symbol(), PERIOD_H4, 0),Digits());    // Example price 2
        tp = NormalizeDouble(BB.GetValue(1,1), Digits());
        Print("$$: "+price);
        Print("sl: "+sl);
        Print("tp: "+tp);
        Trade.BuyStop(0.1,bid,Symbol(),sl,tp,ORDER_TIME_SPECIFIED,expiration);
      };
    };
  //FILTER SIGNALS
  if (filter_total != filter_count) {
    Print("Signal filtered. Filter total was "+filter_total+" and is now "+filter_count);
    filter_total = filter_count;
  };

  Print("Last purple signal:   "+last_purple_signal);
  Print("Last dark red signal: "+last_dark_red_signal);
  Print("Last buy_aoi signal:  "+last_buy_aoi+ "  "+blue_bottom);
  Print("Last sell_aoi signal: "+last_sell_aoi+ " "+aqua_top);
 
  }
//+------------------------------------------------------------------+
void DrawFibonacciLevels()
  {
   // Define anchor points for the Fibonacci levels
   datetime time1 = iTime(Symbol(), PERIOD_H4, 100);  // Example anchor point 1
   double price1 = iLow(Symbol(), PERIOD_H4, 100);    // Example price 1
   datetime time2 = iTime(Symbol(), PERIOD_H4, 0);   // Example anchor point 2
   double price2 = iHigh(Symbol(), PERIOD_H4, 0);    // Example price 2

   // Create Fibonacci object
   if (!ObjectCreate(0, InpFiboName, OBJ_FIBO, 0, time1, price1, time2, price2))
     {
      Print("Error creating Fibonacci object: ", GetLastError());
      return;
     }

   // Set object properties
   ObjectSetInteger(0, InpFiboName, OBJPROP_COLOR, InpFiboColor);
   ObjectSetInteger(0, InpFiboName, OBJPROP_STYLE, InpFiboStyle);
   ObjectSetInteger(0, InpFiboName, OBJPROP_WIDTH, InpFiboWidth);
   ObjectSetInteger(0, InpFiboName, OBJPROP_RAY_RIGHT, InpFiboRayRight);

   // Set Fibonacci levels
   double levels[] = {InpLevel1, InpLevel2, InpLevel3, InpLevel4, InpLevel5, InpLevel6, InpLevel7};
   for (int i = 0; i < ArraySize(levels); i++)
     {
      ObjectSetDouble(0, InpFiboName, OBJPROP_LEVELVALUE, i, levels[i]);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELSTYLE, i, InpFiboStyle);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELWIDTH, i, InpFiboWidth);
      ObjectSetInteger(0, InpFiboName, OBJPROP_LEVELCOLOR, i, InpFiboColor);
     }

//    Print("Fibonacci levels drawn successfully.");
  }