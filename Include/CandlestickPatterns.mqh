//+------------------------------------------------------------------+
//|                                          CandlestickPatterns.mqh |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
//+------------------------------------------------------------------+
void drawIndecisionCandle(int candleIndex) {
     // Draw a vertical line to represent the body of the indecision
  double x = candleIndex; // X-coordinate of the line
  
  double yLow = iLow(Symbol(),Period(),candleIndex); // Lowest price of the candle
  double yHigh = iHigh(Symbol(),Period(),candleIndex); // Highest price of the candle
  datetime indecisionTime = iTime(Symbol(), Period(), 1);
  // Draw a circle to represent the lower shadow of the doji
  double yLowerShadow = iLow(Symbol(),Period(),candleIndex) - (iClose(Symbol(),Period(),candleIndex) - iOpen(Symbol(),Period(),candleIndex)); // End of lower shadow
  double location = yHigh;
  ObjectCreate(0, "IndecisionLowerShadow" + indecisionTime, OBJ_TEXT, 0, indecisionTime, location);
  //--- set the text
  ObjectSetString(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_TEXT,"INDECISION");
  //--- set text font
  ObjectSetString(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_FONT,"Arial");
  //--- set font size
  ObjectSetInteger(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_FONTSIZE,8);
  //--- set the slope angle of the text
  ObjectSetDouble(0,"IndecisionLowerShadow" + indecisionTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0, "IndecisionLowerShadow" + indecisionTime, OBJPROP_COLOR, clrBlue); // Set color to red or any other color
}
bool isBearishEuphoria(int candleIndex) {
  return (
    iOpen(Symbol(),Period(),candleIndex) < iClose(Symbol(),Period(),candleIndex) && //biggest bullish
    iOpen(Symbol(),Period(),candleIndex+1) < iClose(Symbol(),Period(),candleIndex+1) && //bigger bullish
    iOpen(Symbol(),Period(),candleIndex+2) < iClose(Symbol(),Period(),candleIndex+2) && //bullish
    iClose(Symbol(),Period(),candleIndex) > iClose(Symbol(),Period(),candleIndex+1) &&
    iClose(Symbol(),Period(),candleIndex+1) > iClose(Symbol(),Period(),candleIndex+2) &&
    MathAbs(iOpen(Symbol(),Period(),candleIndex)-iClose(Symbol(),Period(),candleIndex)) > MathAbs(iOpen(Symbol(),Period(),candleIndex+1)-iClose(Symbol(),Period(),candleIndex+1)) &&
    MathAbs(iOpen(Symbol(),Period(),candleIndex+1)-iClose(Symbol(),Period(),candleIndex+1)) > MathAbs(iOpen(Symbol(),Period(),candleIndex+2)-iClose(Symbol(),Period(),candleIndex+2))
  ) ? true : false;
}
bool isBullishEuphoria(int candleIndex) {
  return (
    iOpen(Symbol(),Period(),candleIndex) > iClose(Symbol(),Period(),candleIndex) && //biggest bearish
    iOpen(Symbol(),Period(),candleIndex+1) > iClose(Symbol(),Period(),candleIndex+1) && //bigger bearish
    iOpen(Symbol(),Period(),candleIndex+2) > iClose(Symbol(),Period(),candleIndex+2) && //bearish
    iClose(Symbol(),Period(),candleIndex) < iClose(Symbol(),Period(),candleIndex+1) &&
    iClose(Symbol(),Period(),candleIndex+1) < iClose(Symbol(),Period(),candleIndex+2) &&
    MathAbs(iOpen(Symbol(),Period(),candleIndex)-iClose(Symbol(),Period(),candleIndex)) > MathAbs(iOpen(Symbol(),Period(),candleIndex+1)-iClose(Symbol(),Period(),candleIndex+1)) &&
    MathAbs(iOpen(Symbol(),Period(),candleIndex+1)-iClose(Symbol(),Period(),candleIndex+1)) > MathAbs(iOpen(Symbol(),Period(),candleIndex+2)-iClose(Symbol(),Period(),candleIndex+2))
  ) ? true : false;
}
void drawBullishEuphoria(int candleIndex) {
  double yLow = iLow(Symbol(),Period(),candleIndex); // Lowest price of the candle
  double yHigh = iHigh(Symbol(),Period(),candleIndex); // Highest price of the candle
  datetime bullishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = iHigh(Symbol(),Period(),candleIndex) + iOpen(Symbol(),Period(),candleIndex) - iClose(Symbol(),Period(),candleIndex); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJ_TEXT, 0, bullishEuphoriaTime, location);
  ObjectSetString(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_TEXT,"Euphoria (L)");
  ObjectSetDouble(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBearishEuphoria(int candleIndex) {
  double yLow = iLow(Symbol(),Period(),candleIndex); // Lowest price of the candle
  double yHigh = iHigh(Symbol(),Period(),candleIndex); // Highest price of the candle
  datetime bearishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = iHigh(Symbol(),Period(),candleIndex) + iOpen(Symbol(),Period(),candleIndex) - iClose(Symbol(),Period(),candleIndex); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJ_TEXT, 0, bearishEuphoriaTime, location);
  ObjectSetString(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_TEXT,"Euphoria (S)");
  ObjectSetDouble(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}