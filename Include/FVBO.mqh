//+------------------------------------------------------------------+
//|                                                         FVBO.mqh |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
void drawFVBO(int i, color c)
  {
   datetime setupTime = iTime(Symbol(), Period(), i);
   ObjectCreate(0, "Setup" + setupTime, OBJ_TEXT, 0, setupTime, iHigh(Symbol(),Period(),i));
   ObjectSetString(0,"Setup" + setupTime,OBJPROP_TEXT,"FVBO");
   ObjectSetInteger(0, "Setup" + setupTime, OBJPROP_COLOR, c);
   ObjectSetDouble(0,"Setup" + setupTime,OBJPROP_ANGLE,90.0);
  }