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
void ShowRange( double hi, double lo ) {

   ShowRangeLine( "hi", OBJ_HLINE, hi );
   ShowRangeLine( "lo", OBJ_HLINE, lo );
   ShowRangeLine( "now", OBJ_VLINE, lo );
}

void ShowRangeLine( string name, ENUM_OBJECT type, double value ) {

   ObjectDelete( 0, name );
   ObjectCreate( 0, name, type, 0, iTime( Symbol(), Period(), 1 ), value );
   ObjectSetInteger( 0, name, OBJPROP_COLOR, clrWhite );
   ObjectSetInteger( 0, name, OBJPROP_STYLE, STYLE_DOT );
}