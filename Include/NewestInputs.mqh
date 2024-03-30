#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
// Indicator inputs
input int InpBollingerPeriod = 20; // Bollinger period
input double InpBollingerDeviations = 2.0; // Bollinger deviations
input ENUM_APPLIED_PRICE InpBollingerAppliedPrice = PRICE_CLOSE; // Bollinger applied price
input int InpEMAPeriod = 20; //  Period of EMA
input int InpATRPeriod = 20; //  Period of ATR
input double InpATRFactor = 2.0; //  ATR multiplier
input ENUM_APPLIED_PRICE InpRSIAppliedPrice = PRICE_CLOSE; // Bollinger applied price
input int InpRSIPeriod = 20;
input bool InpShowLabel = false; //  show price of level
input bool InpDrawSignals = true;

input int InpUpperThreshold = 50; //upper threshold used for bullishDoubleTroubleRSI calc
input int InpLowerThreshold = 50; //lower threshold used for bearishDoubleTroubleRSI calc
input int InpRSIUpper = 50;
input int InpRSILower = 50;
//DERIVATIVES
input int     InpBandsPeriod=20;       // Period
input int     InpBandsShift=0;         // Shift
input double  InpBandsDeviations=2.0;  // Deviation
// Entry exit settings
// basic expert uses fixed order size
input double InpOrderSize = 0.1; // order size in lots

input group "Trading Days"
input bool InpSunday = true; //Sunday
input bool InpMonday = true; // Monday
input bool InpTuesday = true; // Tuesday
input bool InpWednesday = true; // Wednesday
input bool InpThursday = true; // Thursday
input bool InpFriday = true;   // Friday
input bool InpSaturday = true; // Saturday

input group "Trading Hours (basic implementation, won't handle overnight cases or other periods. Also needs user input validation.)"
input int InpStartHour = 0; //Start hour (24H)
input int InpEndHour = 24; //Finish hour(24H)

input group "Candlestick Patterns"
input bool InpEuphoria; //euphoria indicator
input bool InpDoubleTroubleWithRSIFilter; //double trouble with rsi filter
input bool InpBarrier;
input bool InpIndecision;
input bool InpHammer;
input bool InpInvertedHammer;
