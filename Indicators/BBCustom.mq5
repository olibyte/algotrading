
//+------------------------------------------------------------------+
//|                                             Spread And Candle Timer|
//|                                             forexroboteasy.com    |
//|                                             Forex Robot Easy Team |
//+------------------------------------------------------------------+

#property strict

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
datetime lastCandleTime = 0;
double lastSpread = 0;
color dojiColor = clrRed;
color engulfingColor = clrGreen;
color hammerColor = clrBlue;
color shootingStarColor = clrYellow;
int sensitivity = 3;

//+------------------------------------------------------------------+
//| Custom Indicator Initialization Function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom Indicator Deinitialization Function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Perform any necessary cleanup tasks here
}

//+------------------------------------------------------------------+
//| Custom Indicator Calculation Function                             |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Loop through each candlestick
   for (int i = prev_calculated; i < rates_total; i++)
   {
      // Calculate spread and check for pattern formations
      double currentSpread = spread[i];
      datetime currentCandleTime = time[i];

      // Check for doji pattern
      if (IsDoji(open[i], high[i], low[i], close[i]))
      {
         HighlightPattern(i, dojiColor);
      }

      // Check for engulfing pattern
      if (IsEngulfing(open[i], high[i], low[i], close[i]))
      {
         HighlightPattern(i, engulfingColor);
      }

      // Check for hammer pattern
      if (IsHammer(open[i], high[i], low[i], close[i]))
      {
         HighlightPattern(i, hammerColor);
      }

      // Check for shooting star pattern
      if (IsShootingStar(open[i], high[i], low[i], close[i]))
      {
         HighlightPattern(i, shootingStarColor);
      }

      // Update last candle time and spread
      lastCandleTime = currentCandleTime;
      lastSpread = currentSpread;
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Helper Functions                                                  |
//+------------------------------------------------------------------+
bool IsDoji(double open, double high, double low, double close)
{
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   double upperShadowSize = high - MathMax(open, close);
   double lowerShadowSize = MathMin(open, close) - low;
   
   // Check if the candle satisfies doji condition
   if (bodySize < (sensitivity * _Point) && upperShadowSize >= (sensitivity * _Point) && lowerShadowSize >= (sensitivity * _Point))
   {
      return true;
   }
   
   return false;
}

bool IsEngulfing(double open, double high, double low, double close)
{
   double prevOpen = iOpen(Symbol(), PERIOD_CURRENT, 1);
   double prevClose = iClose(Symbol(), PERIOD_CURRENT, 1);
   double prevHigh = iHigh(Symbol(),PERIOD_CURRENT,1);
   double prevLow = iLow(Symbol(), PERIOD_CURRENT,1);
   
   // Check if the current candle engulfs the previous candle
   if (open < prevOpen && close > prevClose && high > prevHigh && low < prevLow)
   {
      return true;
   }
   
   return false;
}

bool IsHammer(double open, double high, double low, double close)
{
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   double upperShadowSize = high - MathMax(open, close);
   double lowerShadowSize = MathMin(open, close) - low;
   
   // Check if the candle satisfies hammer condition
   if (bodySize < (sensitivity * _Point) && upperShadowSize >= (sensitivity * _Point) && lowerShadowSize >= (2 * sensitivity * _Point))
   {
      return true;
   }
   
   return false;
}

bool IsShootingStar(double open, double high, double low, double close)
{
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   double upperShadowSize = high - MathMax(open, close);
   double lowerShadowSize = MathMin(open, close) - low;
   
   // Check if the candle satisfies shooting star condition
   if (bodySize < (sensitivity * _Point) && upperShadowSize >= (2 * sensitivity * _Point) && lowerShadowSize >= (sensitivity * _Point))
   {
      return true;
   }
   
   return false;
}

void HighlightPattern(int index, color highlightColor)
{
   // Highlight the pattern on the chart
   // Add implementation code here
    datetime shootingStarTime = iTime(Symbol(), Period(), 1);
    
   double yUpperShadow = iHigh(Symbol(),Period(),1);
   // Draw a circle to represent the upper shadow of the shooting star
//    double yUpperShadow = Rates[candleIndex].high + (Rates[candleIndex].open - Rates[candleIndex].close); // End of upper shadow
    ObjectCreate(0, "ShootingStarUpperShadow" + shootingStarTime, OBJ_ARROW, 0, shootingStarTime, yUpperShadow);
    ObjectSetInteger(0, "ShootingStarUpperShadow" + shootingStarTime, OBJPROP_COLOR, clrRed); // Set color to red or any other color

}

//+------------------------------------------------------------------+
//| Custom Indicator Event Functions                                  |
//+------------------------------------------------------------------+

void OnTimer()
{
   // Check for new candle formation
   datetime currentCandleTime = iTime(Symbol(), PERIOD_CURRENT, 0);
   
   if (currentCandleTime != lastCandleTime)
   {
      // Perform actions when new candle forms
   }
}