//Performance & Patterns
bool get_euphoria_accuracy;
int correct_euphoria_bull_preds;
int correct_euphoria_bear_preds;
int total_euphoria_bull_preds;
int total_euphoria_bear_preds;
double euphoria_bull_accuracy;
double euphoria_bear_accuracy;

bool get_barrier_accuracy;
int correct_barrier_bull_preds;
int correct_barrier_bear_preds;
int total_barrier_bull_preds;
int total_barrier_bear_preds;
double barrier_bull_accuracy;
double barrier_bear_accuracy;

bool get_double_trouble_with_rsi_filter_accuracy;
int correct_double_trouble_with_rsi_filter_bull_preds;
int correct_double_trouble_with_rsi_filter_bear_preds;
int total_double_trouble_with_rsi_filter_bull_preds;
int total_double_trouble_with_rsi_filter_bear_preds;
double double_trouble_with_rsi_filter_bear_accuracy;
double double_trouble_with_rsi_filter_bull_accuracy;

bool get_engulfing_bollinger_accuracy;
int correct_engulfing_bollinger_bull_preds;
int correct_engulfing_bollinger_bear_preds;
int total_engulfing_bollinger_bull_preds;
int total_engulfing_bollinger_bear_preds;
double engulfing_bollinger_bear_accuracy;
double engulfing_bollinger_bull_accuracy;

// Draw the hammer candlestick pattern on the chart
void drawHammer(int candleIndex) {
  // Draw a vertical line to represent the body of the hammer
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime hammerTime = iTime(Symbol(), Period(), 1);
  // Draw a circle to represent the lower shadow of the hammer
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
  double location = yHigh;
  clr=clrGreen;               // color
  ObjectCreate(0, "HammerLowerShadow" + hammerTime, OBJ_TEXT, 0, hammerTime, location);
  ObjectSetString(0,"HammerLowerShadow" + hammerTime,OBJPROP_TEXT,"HAMMER");
  ObjectSetString(0,"HammerLowerShadow" + hammerTime,OBJPROP_FONT,"Arial");
  ObjectSetInteger(0,"HammerLowerShadow" + hammerTime,OBJPROP_FONTSIZE,8);
  ObjectSetDouble(0,"HammerLowerShadow" + hammerTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0,"HammerLowerShadow" + hammerTime,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
  ObjectSetInteger(0, "HammerLowerShadow" + hammerTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}
bool isHammer(int candleIndex, double smallMultiplier, double bigMultiplier) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);
  bool hasLargeTail = tailSize >= bodySize * bigMultiplier;
  bool hasSmallWick = wickSize < bodySize * smallMultiplier;
  return (hasLargeTail && hasSmallWick && Rates[candleIndex].close < Rates[candleIndex].open) ? true : false;
}

void drawBearishDoubleTrouble(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishDoubleTroubleTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime, OBJ_TEXT, 0, bearishDoubleTroubleTime, location);
  ObjectSetString(0,"bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime,OBJPROP_TEXT,"DoubleTroubleBullishContinuation");
  ObjectSetDouble(0,"bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bearishDoubleTroubleUpperShadow" + bearishDoubleTroubleTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color
}
bool isDoji(int candleIndex) {
   return (Rates[candleIndex].close > Rates[candleIndex].open && Rates[candleIndex-1].close == Rates[candleIndex].open && Rates[candleIndex-1].close < Rates[candleIndex-1].open) ? true : false;
}
void drawDoji(int candleIndex) {
  // Draw a vertical line to represent the body of the doji
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime dojiTime = iTime(Symbol(), Period(), 1);
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
  if (Rates[candleIndex].close < Rates[candleIndex].open) {
  clr=clrRed;              // color  
  } else {
     clr=clrGreen;               // color 
  }
  ObjectCreate(0, "DojiLowerShadow" + dojiTime, OBJ_TEXT, 0, dojiTime, yLowerShadow);
  ObjectSetString(0,"DojiLowerShadow" + dojiTime,OBJPROP_TEXT,"DOJI");
  ObjectSetString(0,"DojiLowerShadow" + dojiTime,OBJPROP_FONT,"Arial");
  ObjectSetInteger(0,"DojiLowerShadow" + dojiTime,OBJPROP_FONTSIZE,8);
  ObjectSetDouble(0,"DojiLowerShadow" + dojiTime,OBJPROP_ANGLE,90.0);
  ObjectSetInteger(0,"DojiLowerShadow" + dojiTime,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
  ObjectSetInteger(0, "DojiLowerShadow" + dojiTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}
bool isInvertedHammer(int candleIndex, double smallMultiplier, double bigMultiplier) {
  // Calculate the body size and shadow lengths
  double bodySize = getBodySize(candleIndex);
  double tailSize = getTailSize(candleIndex);
  double wickSize = getWickSize(candleIndex);
  double tailWickSize = getTailWickSize(candleIndex);
  bool hasSmallTail = tailSize < bodySize * smallMultiplier;
  bool hasLargeWick = wickSize >= bodySize * bigMultiplier;
  return (hasSmallTail && hasLargeWick && Rates[candleIndex].close < Rates[candleIndex].open) ? true : false;
}
// Draw the hammer candlestick pattern on the chart
void drawInvertedHammer(int candleIndex) {
  // Draw a vertical line to represent the body of the hammer
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime invertedHammerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  clr=clrRed;          // color  
  ObjectCreate(0, "invertedHammerUpperShadow" + invertedHammerTime, OBJ_TEXT, 0, invertedHammerTime, location);
  ObjectSetString(0,"invertedHammerUpperShadow" + invertedHammerTime,OBJPROP_TEXT,"Inverted Hammer");
  ObjectSetDouble(0,"invertedHammerUpperShadow" + invertedHammerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "invertedHammerUpperShadow" + invertedHammerTime, OBJPROP_COLOR, clr); // Set color to red or any other color
}
bool isMorningStar(int candleIndex) {
  return (
  Rates[candleIndex].close > Rates[candleIndex].open &&
  MathMax(Rates[candleIndex+1].close,Rates[candleIndex+1].open) < Rates[candleIndex].open &&
  MathMax(Rates[candleIndex+1].close,Rates[candleIndex+1].open) < Rates[candleIndex+2].close &&
  Rates[candleIndex+2].close < Rates[candleIndex+2].open
  ) ? true : false;
}
bool isEveningStar(int candleIndex) {
  return (
    Rates[candleIndex].close < Rates[candleIndex].open &&
    MathMin(Rates[candleIndex+1].close, Rates[candleIndex+1].open) > Rates[candleIndex].open &&
    MathMin(Rates[candleIndex+1].close,Rates[candleIndex+1].open) > Rates[candleIndex+2].close && 
    Rates[candleIndex+2].close > Rates[candleIndex+2].open
  ) ? true : false;
}
void drawMorningStar(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime morningStarTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "morningStarUpperShadow" + morningStarTime, OBJ_TEXT, 0, morningStarTime, location);
  ObjectSetString(0, "morningStarUpperShadow" + morningStarTime,OBJPROP_TEXT,"Morning Star");
  ObjectSetDouble(0, "morningStarUpperShadow" + morningStarTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"morningStarUpperShadow" + morningStarTime, OBJPROP_COLOR, clrGreen); // red because contrarian pattern
}
void drawEveningStar(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime eveningStarTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "eveningStarUpperShadow" + eveningStarTime, OBJ_TEXT, 0, eveningStarTime, location);
  ObjectSetString(0, "eveningStarUpperShadow" + eveningStarTime,OBJPROP_TEXT,"evening Star");
  ObjectSetDouble(0, "eveningStarUpperShadow" + eveningStarTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"eveningStarUpperShadow" + eveningStarTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isIndecisionCandle(int candleIndex, double tailWickMultiplier) {
  double tailWickSize = 0;
  double bodySize = 0;
  tailWickSize = getTailWickSize(candleIndex);
  bodySize = getBodySize(candleIndex);
  return tailWickSize * tailWickMultiplier >= bodySize ? true : false;
}
void drawIndecisionCandle(int candleIndex) {
     // Draw a vertical line to represent the body of the indecision
  double x = candleIndex; // X-coordinate of the line
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime indecisionTime = iTime(Symbol(), Period(), 1);
  // Draw a circle to represent the lower shadow of the doji
  double yLowerShadow = Rates[candleIndex].low - (Rates[candleIndex].close - Rates[candleIndex].open); // End of lower shadow
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
    Rates[candleIndex].open < Rates[candleIndex].close && //biggest bullish
    Rates[candleIndex+1].open < Rates[candleIndex+1].close && //bigger bullish
    Rates[candleIndex+2].open < Rates[candleIndex+2].close && //bullish
    Rates[candleIndex].close > Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close > Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
bool isBullishEuphoria(int candleIndex) {
  return (
    Rates[candleIndex].open > Rates[candleIndex].close && //biggest bearish
    Rates[candleIndex+1].open > Rates[candleIndex+1].close && //bigger bearish
    Rates[candleIndex+2].open > Rates[candleIndex+2].close && //bearish
    Rates[candleIndex].close < Rates[candleIndex+1].close &&
    Rates[candleIndex+1].close < Rates[candleIndex+2].close &&
    MathAbs(Rates[candleIndex].open-Rates[candleIndex].close) > MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) &&
    MathAbs(Rates[candleIndex+1].open-Rates[candleIndex+1].close) > MathAbs(Rates[candleIndex+2].open-Rates[candleIndex+2].close)
  ) ? true : false;
}
void drawBullishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJ_TEXT, 0, bullishEuphoriaTime, location);
  ObjectSetString(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_TEXT,"Euphoria (L)");
  ObjectSetDouble(0, "bullishEuphoriaUpperShadow" + bullishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEuphoriaUpperShadow" + bullishEuphoriaTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBearishEuphoria(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishEuphoriaTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJ_TEXT, 0, bearishEuphoriaTime, location);
  ObjectSetString(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_TEXT,"Euphoria (S)");
  ObjectSetDouble(0, "bearishEuphoriaUpperShadow" + bearishEuphoriaTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEuphoriaUpperShadow" + bearishEuphoriaTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isBullishBarrier(int candleIndex) {
  int digits = Digits()-1;
  double low = NormalizeDouble(Rates[candleIndex].low,digits);
  double prev_low = NormalizeDouble(Rates[candleIndex+1].low,digits);
  double prev_prev_low = NormalizeDouble(Rates[candleIndex+2].low,digits);
  // double prev_low = Rates[candleIndex+1].low;
    // prev_low = MathRound(prev_low * MathPow(10, digits)) / MathPow(10, digits);
  // double prev_prev_low = Rates[candleIndex+2].low;
    // prev_prev_low = MathRound(prev_prev_low * MathPow(10, digits)) / MathPow(10, digits);
 return (
    Rates[candleIndex].close > Rates[candleIndex].open &&
    Rates[candleIndex+1].close < Rates[candleIndex+1].open &&
    Rates[candleIndex+2].close < Rates[candleIndex+2].open &&
    low == prev_low &&
    low == prev_prev_low
    // Rates[candleIndex].low == Rates[candleIndex+1].low &&
    // Rates[candleIndex].low == Rates[candleIndex+2].low
 ) ? true : false;
}
bool isBearishBarrier(int candleIndex) {
  int digits = Digits()-1;
  double high = NormalizeDouble(Rates[candleIndex].high,digits);
  double prev_high = NormalizeDouble(Rates[candleIndex+1].high,digits);
  double prev_prev_high = NormalizeDouble(Rates[candleIndex+2].high,digits);
 return (
    Rates[candleIndex].close < Rates[candleIndex].open &&
    Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
    Rates[candleIndex+2].close > Rates[candleIndex+2].open &&
    high == prev_high &&
    high == prev_prev_high
    // Rates[candleIndex].high == Rates[candleIndex+1].high &&
    // Rates[candleIndex].high == Rates[candleIndex+2].high
 ) ? true : false;
}
void drawBullishBarrier(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishBarrierTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishBarrierUpperShadow" + bullishBarrierTime, OBJ_TEXT, 0, bullishBarrierTime, location);
  ObjectSetString(0, "bullishBarrierUpperShadow" + bullishBarrierTime,OBJPROP_TEXT,"Barrier (L)");
  ObjectSetDouble(0, "bullishBarrierUpperShadow" + bullishBarrierTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishBarrierUpperShadow" + bullishBarrierTime, OBJPROP_COLOR, clrGreen); // red because contrarian pattern
}
void drawBearishBarrier(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime BearishBarrierTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "BearishBarrierUpperShadow" + BearishBarrierTime, OBJ_TEXT, 0, BearishBarrierTime, location);
  ObjectSetString(0, "BearishBarrierUpperShadow" + BearishBarrierTime,OBJPROP_TEXT,"Barrier (S)");
  ObjectSetDouble(0, "BearishBarrierUpperShadow" + BearishBarrierTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"BearishBarrierUpperShadow" + BearishBarrierTime, OBJPROP_COLOR, clrRed); // red because contrarian pattern
}
bool isBullishDoubleTroubleWithRSIFilter(int candleIndex, int upperThreshold) {
 return (
 Rates[candleIndex].close > Rates[candleIndex].open &&
 Rates[candleIndex].close > Rates[candleIndex+1].close &&
 Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
 Rates[candleIndex].high - Rates[candleIndex].low > (2 * ValuesATR[2]) &&
 Rates[candleIndex].close - Rates[candleIndex].open > Rates[candleIndex+1].close - Rates[candleIndex+1].open &&  
 ValuesRSI[candleIndex] > upperThreshold
 ) ? true : false;
}
void drawBullishDoubleTroubleWithRSIFilter(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishDoubleTroubleWithRSIFilterTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime, OBJ_TEXT, 0, bullishDoubleTroubleWithRSIFilterTime, location);
  ObjectSetString(0,"bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime,OBJPROP_TEXT,"DoubleTroubleRSI");
  ObjectSetDouble(0,"bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bullishDoubleTroubleWithRSIFilterUpperShadow" + bullishDoubleTroubleWithRSIFilterTime, OBJPROP_COLOR, clrGreen); // Set color to red or any other color
}
bool isBearishDoubleTroubleWithRSIFilter(int candleIndex,int lowerThreshold) {
 return (
 Rates[candleIndex].close < Rates[candleIndex].open &&
 Rates[candleIndex].close < Rates[candleIndex+1].close &&
 Rates[candleIndex+1].close < Rates[candleIndex+1].open &&
 Rates[candleIndex].high - Rates[candleIndex].low > (2 * ValuesATR[2]) &&
 Rates[candleIndex].open - Rates[candleIndex].close > Rates[candleIndex+1].open - Rates[candleIndex+1].close &&  
 ValuesRSI[candleIndex] < lowerThreshold
 ) ? true : false;
}
void drawBearishDoubleTroubleWithRSIFilter(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishDoubleTroubleWithRSIFilterTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0, "bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime, OBJ_TEXT, 0, bearishDoubleTroubleWithRSIFilterTime, location);
  ObjectSetString(0,"bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime,OBJPROP_TEXT,"BearishDoubleTroubleRSI");
  ObjectSetDouble(0,"bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0, "bearishDoubleTroubleWithRSIFilterUpperShadow" + bearishDoubleTroubleWithRSIFilterTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color
}
bool isBearishEngulfingBollinger(int candleIndex) {
  return (
 Rates[candleIndex].close < Rates[candleIndex].open &&
 Rates[candleIndex].open > Rates[candleIndex+1].close &&
 Rates[candleIndex].close < Rates[candleIndex+1].open &&
 Rates[candleIndex+1].close > Rates[candleIndex+1].open &&
 Rates[candleIndex+2].close > Rates[candleIndex+2].open &&
 Rates[candleIndex].close > ValuesBollingerUpper[candleIndex]
  ) ? true : false;
}
bool isBullishEngulfingBollinger(int candleIndex) {
  return (
 Rates[candleIndex].close > Rates[candleIndex].open &&
 Rates[candleIndex].open < Rates[candleIndex+1].close &&
 Rates[candleIndex].close > Rates[candleIndex+1].open &&
 Rates[candleIndex+1].close < Rates[candleIndex+1].open && //bearish
 Rates[candleIndex+2].close < Rates[candleIndex+2].open && //bearish
 Rates[candleIndex].close < ValuesBollingerLower[candleIndex]
  ) ? true : false;
}
void drawBullishEngulfingBollinger(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishEngulfingBollingerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime, OBJ_TEXT, 0, bullishEngulfingBollingerTime, location);
  ObjectSetString(0, "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime,OBJPROP_TEXT,"EngulfingBollinger (L)");
  ObjectSetDouble(0, "bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishEngulfingBollingerUpperShadow" + bullishEngulfingBollingerTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void drawBearishEngulfingBollinger(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bearishEngulfingBollingerTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime, OBJ_TEXT, 0, bearishEngulfingBollingerTime, location);
  ObjectSetString(0, "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime,OBJPROP_TEXT,"EngulfingBollinger (S)");
  ObjectSetDouble(0, "bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bearishEngulfingBollingerUpperShadow" + bearishEngulfingBollingerTime, OBJPROP_COLOR, clrRed); //green because contrarian pattern
}
bool isBullishBarrierRSIATR(int candleIndex,int periods) {
  if (isBullishBarrier(candleIndex)) {
    double rsi_atr = 0;
    for (int i = candleIndex; i < periods; i++) {
      rsi_atr += ValuesRSI[candleIndex] / ValuesATR[candleIndex+1];
    }
    rsi_atr = NormalizeDouble((rsi_atr/periods),Digits());
    if (rsi_atr < 20) {
      PrintFormat("BULLISHBARRIERRSIATRFOUND!");
      return true;
    }
  }
  return false;
}
void drawBullishBarrierRSIATR(int candleIndex) {
  double yLow = Rates[candleIndex].low; // Lowest price of the candle
  double yHigh = Rates[candleIndex].high; // Highest price of the candle
  datetime bullishBarrierRSIATRTime = iTime(Symbol(), Period(), 1);
  double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
  double location = yHigh;
  ObjectCreate(0,    "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime, OBJ_TEXT, 0, bullishBarrierRSIATRTime, location);
  ObjectSetString(0, "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime,OBJPROP_TEXT,"BarrierRSIATR (L)");
  ObjectSetDouble(0, "bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime,OBJPROP_ANGLE,90.0);   
  ObjectSetInteger(0,"bullishBarrierRSIATRUpperShadow" + bullishBarrierRSIATRTime, OBJPROP_COLOR, clrGreen); //green because contrarian pattern
}
void DrawSignals(int candleIndex,int periods, int upperThreshold, int lowerThreshold, double indecisionMultiplier) {
  // drawDoubleTrouble(candleIndex);
  if (isBullishEuphoria(candleIndex)) {drawBullishEuphoria(candleIndex);}
  if (isBearishEuphoria(candleIndex)) {drawBearishEuphoria(candleIndex);}
  if (isBullishBarrierRSIATR(candleIndex,periods)) {drawBullishBarrierRSIATR(candleIndex);}
  if (isBullishEngulfingBollinger(candleIndex)) {drawBullishEngulfingBollinger(candleIndex);}
  // if (isBearishEngulfingBollinger(candleIndex)) {drawBearishEngulfingBollinger(candleIndex);}
  if (isBullishDoubleTroubleWithRSIFilter(candleIndex,upperThreshold)) {drawBullishDoubleTroubleWithRSIFilter(candleIndex);}
  if (isBearishDoubleTroubleWithRSIFilter(candleIndex,lowerThreshold)) {drawBearishDoubleTroubleWithRSIFilter(candleIndex);}
  // if (isBullishBarrier(candleIndex)) { drawBullishBarrier(candleIndex);}
  // if (isBearishBarrier(candleIndex)) { drawBearishBarrier(candleIndex);}
  // if (isInvertedHammer(candleIndex)) { drawInvertedHammer(candleIndex);}
  // if (isHammer(candleIndex)) { drawHammer(candleIndex);}
  // if (isMorningStar(candleIndex)) {drawMorningStar(candleIndex);}
  // if (isEveningStar(candleIndex)) {drawEveningStar(candleIndex);}
  // if (isDoji(candleIndex)) {drawDoji(candleIndex);};
  if (isIndecisionCandle(candleIndex,indecisionMultiplier)) {
    drawIndecisionCandle(candleIndex);
  };
  if (isFvboBuySetup(candleIndex) || isFvboSellSetup(candleIndex)) {
    drawFvboSetup(candleIndex);
  };
}

//---PERFORMANCE---//

void getPatternAccuracy(int candleIndex, int upperThreshold, int lowerThreshold, bool euphoria=true, bool barrier=true, bool double_trouble_with_rsi_filter=true,bool engulfing_bollinger=true) {
  if (euphoria) {
    getBearishEuphoriaAccuracy(candleIndex);
    getBullishEuphoriaAccuracy(candleIndex);
  }
  if (barrier) {
    getBearishBarrierAccuracy(candleIndex);
    getBullishBarrierAccuracy(candleIndex);
  }
  if (double_trouble_with_rsi_filter) {
    getBearishDoubleTroubleWithRSIFilterAccuracy(candleIndex,lowerThreshold);
    getBullishDoubleTroubleWithRSIFilterAccuracy(candleIndex,upperThreshold);
  }
  if (engulfing_bollinger) {
    getBearishEngulfingBollingerAccuracy(candleIndex);
    getBullishEngulfingBollingerAccuracy(candleIndex);
  }
}
void getBearishEuphoriaAccuracy(int candleIndex) {
if (isBearishEuphoria(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_euphoria_bear_preds+=1;
    total_euphoria_bear_preds+=1;
    if (correct_euphoria_bear_preds > 0 && total_euphoria_bear_preds > 0) {
      euphoria_bear_accuracy = (double)correct_euphoria_bear_preds/(double)total_euphoria_bear_preds;
      PrintFormat("Euphoria Bear accuracy: %.2f (%i/%i)", euphoria_bear_accuracy*100,correct_euphoria_bear_preds,total_euphoria_bear_preds);
    }
  }
if (isBearishEuphoria(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_euphoria_bear_preds+=1;
  }
}
void getBullishEuphoriaAccuracy(int candleIndex) {
  if (isBullishEuphoria(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_euphoria_bull_preds+=1;
    total_euphoria_bull_preds+=1;
    if (correct_euphoria_bull_preds > 0 && total_euphoria_bull_preds > 0) {
      euphoria_bull_accuracy = (double)correct_euphoria_bull_preds/(double)total_euphoria_bull_preds;
      PrintFormat("Euphoria Bull accuracy: %.2f (%i/%i)", euphoria_bull_accuracy*100,correct_euphoria_bull_preds,total_euphoria_bull_preds);
    }
  }
    if (isBullishEuphoria(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_euphoria_bull_preds+=1;
  }

}
void getBearishBarrierAccuracy(int candleIndex) {
  if (isBearishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_barrier_bear_preds+=1;
    total_barrier_bear_preds+=1;
    if (correct_barrier_bear_preds > 0 && total_barrier_bear_preds > 0) {
      barrier_bear_accuracy = (double)correct_barrier_bear_preds/(double)total_barrier_bear_preds;
      PrintFormat("Barrier Bear accuracy: %.2f (%i/%i)", barrier_bear_accuracy*100,correct_barrier_bear_preds,total_barrier_bear_preds);
    }
  }
  if (isBearishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_barrier_bear_preds+=1;
  }
}
void getBullishBarrierAccuracy(int candleIndex) {
  if (isBullishBarrier(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_barrier_bull_preds+=1;
    total_barrier_bull_preds+=1;
    if (correct_barrier_bull_preds > 0 && total_barrier_bull_preds > 0) {
      barrier_bull_accuracy = (double)correct_barrier_bull_preds/(double)total_barrier_bull_preds;
      PrintFormat("Barrier Bull accuracy: %.2f (%i/%i)", barrier_bull_accuracy*100,correct_barrier_bull_preds,total_barrier_bull_preds);
    }
  }
  if (isBullishBarrier(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_barrier_bull_preds+=1;
  }
}
void getBearishDoubleTroubleWithRSIFilterAccuracy(int candleIndex, int lowerThreshold) {
  if (isBearishDoubleTroubleWithRSIFilter(candleIndex+1,lowerThreshold) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_double_trouble_with_rsi_filter_bear_preds+=1;
    total_double_trouble_with_rsi_filter_bear_preds+=1;
    if (correct_double_trouble_with_rsi_filter_bear_preds > 0 && total_double_trouble_with_rsi_filter_bear_preds > 0) {
      double_trouble_with_rsi_filter_bear_accuracy = (double)correct_double_trouble_with_rsi_filter_bear_preds/(double)total_double_trouble_with_rsi_filter_bear_preds;
      PrintFormat("double_trouble_with_rsi_filter Bear accuracy: %.2f (%i/%i)", double_trouble_with_rsi_filter_bear_accuracy*100,correct_double_trouble_with_rsi_filter_bear_preds,total_double_trouble_with_rsi_filter_bear_preds);
    }
  }
  if (isBearishDoubleTroubleWithRSIFilter(candleIndex+1,lowerThreshold) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_double_trouble_with_rsi_filter_bear_preds+=1;
  }
}
void getBullishDoubleTroubleWithRSIFilterAccuracy(int candleIndex, int upperThreshold) {
  if (isBullishDoubleTroubleWithRSIFilter(candleIndex+1,upperThreshold) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_double_trouble_with_rsi_filter_bull_preds+=1;
    total_double_trouble_with_rsi_filter_bull_preds+=1;
    if (correct_double_trouble_with_rsi_filter_bull_preds > 0 && total_double_trouble_with_rsi_filter_bull_preds > 0) {
      double_trouble_with_rsi_filter_bull_accuracy = (double)correct_double_trouble_with_rsi_filter_bull_preds/(double)total_double_trouble_with_rsi_filter_bull_preds;
      PrintFormat("double_trouble_with_rsi_filter Bull accuracy: %.2f (%i/%i)", double_trouble_with_rsi_filter_bull_accuracy*100,correct_double_trouble_with_rsi_filter_bull_preds,total_double_trouble_with_rsi_filter_bull_preds);
    }
  }
  if (isBullishDoubleTroubleWithRSIFilter(candleIndex+1,upperThreshold) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_double_trouble_with_rsi_filter_bull_preds+=1;
  }
}
void getBearishEngulfingBollingerAccuracy(int candleIndex) {
  if (isBearishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    correct_engulfing_bollinger_bear_preds+=1;
    total_engulfing_bollinger_bear_preds+=1;
    if (correct_engulfing_bollinger_bear_preds > 0 && total_engulfing_bollinger_bear_preds > 0) {
      engulfing_bollinger_bear_accuracy = (double)correct_engulfing_bollinger_bear_preds/(double)total_engulfing_bollinger_bear_preds;
      PrintFormat("engulfing_bollinger Bear accuracy: %.2f (%i/%i)", engulfing_bollinger_bear_accuracy*100,correct_engulfing_bollinger_bear_preds,total_engulfing_bollinger_bear_preds);
    }
  }
  if (isBearishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    total_engulfing_bollinger_bear_preds+=1;
  }
}
void getBullishEngulfingBollingerAccuracy(int candleIndex) {
  if (isBullishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close > Rates[candleIndex].open) {
    correct_engulfing_bollinger_bull_preds+=1;
    total_engulfing_bollinger_bull_preds+=1;
    if (correct_engulfing_bollinger_bull_preds > 0 && total_engulfing_bollinger_bull_preds > 0) {
      engulfing_bollinger_bull_accuracy = (double)correct_engulfing_bollinger_bull_preds/(double)total_engulfing_bollinger_bull_preds;
      PrintFormat("engulfing_bollinger Bull accuracy: %.2f (%i/%i)", engulfing_bollinger_bull_accuracy*100,correct_engulfing_bollinger_bull_preds,total_engulfing_bollinger_bull_preds);
    }
  }
  if (isBullishEngulfingBollinger(candleIndex+1) && Rates[candleIndex].close < Rates[candleIndex].open) {
    total_engulfing_bollinger_bull_preds+=1;
  }
}

