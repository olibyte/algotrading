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
input int InpKeltnerLookback = 10;

// Entry exit settings
input int InpEntryGapPoints = 10; // Entry gap points, 50pts=0.5pips
input int InpStopLossGapPoints = 10; // SL gap points, 50pts=0.5pips
input int InpMaxPositionTime = 50;
input int InpWaitTime = 50;
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
