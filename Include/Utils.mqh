//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
bool IsNewBar() {
    static datetime previousBarTime = iTime(Symbol(), Period(), 0);
    datetime currentBarTime = iTime(Symbol(), Period(), 0);

    if (currentBarTime == previousBarTime)
      return false;
    previousBarTime = currentBarTime;
    return true;
  }
  double PointsToDouble(int points, string symbol = "") {
    if (symbol == "")
      symbol = Symbol();
    double value = (double) points * SymbolInfoDouble(symbol, SYMBOL_POINT);
    return value;
  }
  double PipSize() { return ( PipSize( Symbol() ) ); }
double PipSize( string symbol ) {
   double point  = SymbolInfoDouble( symbol, SYMBOL_POINT );
   int    digits = ( int )SymbolInfoInteger( symbol, SYMBOL_DIGITS );
   return ( ( ( digits % 2 ) == 1 ) ? point * 10 : point );
}
//https://github.com/OrchardForexTutorials/221008_retracement_breakout_expert/blob/main/Experts/Orchard/Reentrant%20Breakout/Reentrant%20Breakout.mqh
double PipsToDouble( double pips ) { return ( pips * PipSize( Symbol() ) ); }
double PipsToDouble( double pips, string symbol ) { return ( pips * PipSize( symbol ) ); }

void ShowRange( double hi, double lo, color hiclr, color loclr ) {

   ShowRangeLine( "hi", OBJ_HLINE, hi, hiclr);
   ShowRangeLine( "lo", OBJ_HLINE, lo, loclr);
  //  ShowRangeLine( "now", OBJ_VLINE, lo );
}

void ShowRangeLine( string name, ENUM_OBJECT type, double value, color rangeclr ) {

   ObjectDelete( 0, name );
   ObjectCreate( 0, name, type, 0, iTime( Symbol(), Period(), 1 ), value );
   ObjectSetInteger( 0, name, OBJPROP_COLOR, rangeclr );
   ObjectSetInteger( 0, name, OBJPROP_STYLE, STYLE_DASH );
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
}
 bool WaitForHTF(string symbol, ENUM_TIMEFRAMES timeframe) {
    for (int waitCount = 9; waitCount >= 0; waitCount--) {
      datetime t = iTime(symbol, timeframe,0);
      int err = GetLastError();
      if (t > 0) return (true);
      Sleep(100);
    }
    return false;
  }

// bool MarketOpen() {
//   MqlDateTime Time;
//   TimeCurrent(Time);
//   datetime from, to;
//   ENUM_DAY_OF_WEEK DOW = (ENUM_DAY_OF_WEEK) Time.day_of_week;
//   SymbolInfoSessionTrade(_Symbol,DOW,0,from,to);
//   TimeToStruct(from,FromTime);
//   TimeToStruct(to,ToTime);
//   if (Time.hour <= FromTime.hour && Time.min <= FromTime.min) {
//     return false;
//   }
//   if (Time.hour >= ToTime.hour && Time.min >= ToTime.min) {
//     return fale;
//   }
//   return true;
// }