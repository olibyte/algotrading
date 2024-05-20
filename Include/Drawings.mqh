//+------------------------------------------------------------------+
//|                                                     Drawings.mqh |
//|                                      Copyright 2024, olibyte.github.io |
//|                                       https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"

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
