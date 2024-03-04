//+------------------------------------------------------------------+
//|                                                        Hello.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input uint GreetingHour = 0;
string Greeting(int hour)
{
   string messages[3] = {"Good morning", "Good day", "Good evening"};
   return messages[hour % 24/8];
}
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
      Print(Greeting(GreetingHour), ", ", Symbol());
  }
//+------------------------------------------------------------------+
