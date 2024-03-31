  #define app_name "Newest Strategy"
  #define app_magic 301124


/*COMMENT OUT IF WE DON'T WANT TO LOAD INDICATORS FROM HIGHER TIME FRAMES WHILE IN VISUALIZER. IT KILLS.*/
//  #define htf
// #define debug
  input int InpMagic = app_magic; // Magic number
  input string InpTradeComment = app_name; // Trade comment

  input int InpEntryGapPoints = 50;
  input int InpStopLossGapPoints = 50;

  input bool use_fvbo_signal = true;
  input int InpBuyCounter = 5; //Bars before FVBO buy setup resets
  input int InpSellCounter = 5; //Bars before FVBO buy setup resets
  int buy_counter = InpBuyCounter; int sell_counter = InpSellCounter;

  input bool use_max_position_holding_time = true; //use a max time before closing position. Minutes.
  input int InpMaxPositionTime = 50;
  ulong max_position_time = InpMaxPositionTime; //periodify

  input bool use_wait_before_new_order_time = true;
  input int InpWaitTime = 50; //bars before we look for new order
  ulong wait_time = InpWaitTime; //periodify
  bool waiting_before_new_order = use_wait_before_new_order_time;

  input bool use_bollinger_was_in_keltner = true;
  input int InpKeltnerLookback = 10;
  bool bollinger_was_in_keltner;

  input bool              use_macd = true;
  input int                InpFastEMA=8;               // Fast EMA period
  input int                InpSlowEMA=21;               // Slow EMA period
  input int                InpSignalSMA=5;              // Signal SMA period
  input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
  double ExtMacdBuffer[];
  double ExtSignalBuffer[];
  double ExtFastMaBuffer[];
  double ExtSlowMaBuffer[];

  int    ExtFastMaHandle;
  int    ExtSlowMaHandle;
  int numCandles = 26;

  #include <Trade/Trade.mqh>
  #include <NewestInputs.mqh>
  #include <NewestTime.mqh>
  #include <LinReg.mqh>
  #include <PolyReg.mqh>
  #include <Indicators/IndicatorBollinger.mqh>

  // Function to calculate the first derivative of an array of doubles
CTrade Trade; CPositionInfo PositionInfo; COrderInfo OrderInfo;

#ifdef htf
CIndicatorBollinger	Bollinger_H1;
CIndicatorBollinger	Bollinger_H4;
CIndicatorBollinger	Bollinger_D1;
#endif
  color clr;
  // Indicator handles
  int HandleBollinger, HandleKeltner, HandleDerivative,HandleMacd;
  double ValuesBollingerUpper[], ValuesBollingerLower[], ValuesBollingerMiddle[], ValuesKeltnerUpper[], ValuesKeltnerLower[], bbuFirstDerivative[],bblFirstDerivative[],bbuSecondDerivative[],bblSecondDerivative[];
  double StopLoss, TakeProfit, Price, target, EntryGap, StopLossGap;
  ENUM_ORDER_TYPE currentOrderType;
  int today, server_day;  
  bool position_exists, fvbo_buy_setup, fvbo_sell_setup;
  int rsi_upper = InpRSIUpper, rsi_lower = InpRSILower;
  MqlRates Rates[];
  MqlTick prevTick, lastTick, currentTick;

  double local_min = -0.0001; double local_max = 0.0001;

#ifdef htf
  int HandleBollinger_H4;
  double ValuesBollingerUpper_H4[],ValuesBollingerMiddle_H4[],ValuesBollingerLower_H4[];
#endif
  // Initialisation
  int OnInit() {
    string derivative = "Examples\\BB_1H.ex5";
    string keltner = "Keltner Channel.ex5";

#ifdef htf
    Bollinger_H1.Init(Symbol(), PERIOD_H1, InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
    Bollinger_H4.Init(Symbol(), PERIOD_H4, InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
    Bollinger_D1.Init(Symbol(), PERIOD_D1, InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
#endif
    // HandleDerivative = iCustom(Symbol(), Period(),derivative,InpBandsPeriod,InpBandsShift,InpBandsDeviations);
    HandleKeltner = iCustom(Symbol(), Period(),keltner,InpEMAPeriod,InpATRPeriod,InpATRFactor,InpShowLabel);
    HandleMacd = iMACD(Symbol(), Period(),InpFastEMA,InpSlowEMA,InpSignalSMA,InpAppliedPrice);
    ExtFastMaHandle = iMA(Symbol(),Period(),InpFastEMA,0,MODE_EMA,InpAppliedPrice);
    ExtSlowMaHandle = iMA(Symbol(),Period(),InpSlowEMA,0,MODE_EMA,InpAppliedPrice);
    HandleBollinger = iBands(Symbol(), Period(), InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);
    // HandleBollinger_H4 = iBands(Symbol(), PERIOD_H4, InpBollingerPeriod, 0, InpBollingerDeviations, InpBollingerAppliedPrice);

    ArraySetAsSeries(ValuesBollingerUpper, true);
    ArraySetAsSeries(ValuesBollingerLower, true);
    ArraySetAsSeries(ValuesBollingerMiddle, true);
    // ArraySetAsSeries(ValuesBollingerUpper_H4, true);
    // ArraySetAsSeries(ValuesBollingerLower_H4, true);
    // ArraySetAsSeries(ValuesBollingerMiddle_H4, true);
    ArraySetAsSeries(ValuesKeltnerUpper, true);
    ArraySetAsSeries(ValuesKeltnerLower, true);
    ArraySetAsSeries(ExtMacdBuffer, true);
    ArraySetAsSeries(ExtSignalBuffer, true);
    ArraySetAsSeries(ExtFastMaBuffer, true);
    ArraySetAsSeries(ExtSlowMaBuffer, true);
    // ArraySetAsSeries(bbuFirstDerivative,true);
    // ArraySetAsSeries(bbuSecondDerivative,true);
    // ArraySetAsSeries(bblFirstDerivative,true);
    // ArraySetAsSeries(bblSecondDerivative,true);
    ArraySetAsSeries(Rates, true);

    EntryGap = PointsToDouble(InpEntryGapPoints);
    StopLossGap = PointsToDouble(InpStopLossGapPoints);
    Trade.SetExpertMagicNumber(InpMagic);

    return (INIT_SUCCEEDED);
  }
  void OnDeinit(const int reason) {
    IndicatorRelease(HandleBollinger);
    IndicatorRelease(HandleKeltner);
    IndicatorRelease(HandleDerivative);
    IndicatorRelease(HandleMacd);
    IndicatorRelease(ExtFastMaHandle);
    IndicatorRelease(ExtSlowMaHandle);

    ObjectDelete(_Symbol,"LinReg");
    ObjectDelete(_Symbol,"LinReg+std");
    ObjectDelete(_Symbol,"LinReg-std");
    ObjectDelete(_Symbol,"PolyReg");
  }
  void OnTick() {
    if (!IsNewBar()) return; // still looking at same bar
    #ifdef htf
    	if (!WaitForHTF(Symbol(), PERIOD_D1))	return;			//	Anchor data not available
	//OHLC+BB of latest fully formed 4H CANDLE
//  The buffer numbers are the following: 0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND
  double	BBM_H1_1	=	Bollinger_H1.GetValue(0,1); //buffer,index
  double	BBH_H1_1	=	Bollinger_H1.GetValue(1,1); //buffer,index
  double	BBL_H1_1	=	Bollinger_H1.GetValue(2,1); //buffer,index
	double	Open_H1_1	=	iOpen(Symbol(), PERIOD_H1, 1);
  double	Close_H1_1	=	iClose(Symbol(), PERIOD_H1, 1);
  double	High_H1_1	=	iHigh(Symbol(), PERIOD_H1, 1);
  double	Low_H1_1	=	iLow(Symbol(), PERIOD_H1, 1);

	//OHLC+BB of latest fully formed 4H CANDLE
  double	BBM_H4_1	=	Bollinger_H4.GetValue(0,1);
  double	BBH_H4_1	=	Bollinger_H4.GetValue(1,1); //buffer,index
  double	BBL_H4_1	=	Bollinger_H4.GetValue(2,1); //buffer,index
	double	Open_H4_1	=	iOpen(Symbol(), PERIOD_H4, 1);
  double	Close_H4_1	=	iClose(Symbol(), PERIOD_H4, 1);
  double	High_H4_1	=	iHigh(Symbol(), PERIOD_H4, 1);
  double	Low_H4_1	=	iLow(Symbol(), PERIOD_H4, 1);

//OHLC+BB of latest fully formed DAILY CANDLE
  double	BBM_D1_1	=	Bollinger_D1.GetValue(0,1);
  double	BBH_D1_1	=	Bollinger_D1.GetValue(1,1); //buffer,index
  double	BBL_D1_1	=	Bollinger_D1.GetValue(2,1); //buffer,index
  double	Open_D1_1	=	iOpen(Symbol(), PERIOD_D1, 1);
  double	Close_D1_1	=	iClose(Symbol(), PERIOD_D1, 1);
  double	High_D1_1	=	iHigh(Symbol(), PERIOD_D1, 1);
  double	Low_D1_1	=	iLow(Symbol(), PERIOD_D1, 1);
  bool d1_midline_test,h4_midline_test,h1_midline_test;
  bool d1_upper_test,h4_upper_test,h1_upper_test;
  bool d1_lower_test,h4_lower_test,h1_lower_test;
  
  string dir_D1_1;
  string dir_H4_1;
  string dir_H1_1;
  if (Close_H1_1 > Open_H1_1) {
    dir_H1_1 = "BULLISH";
  } else {
    dir_H1_1 = "BEARISH";
  }
  if (Close_D1_1 > Open_D1_1) {
    dir_D1_1 = "BULLISH";
  } else {
    dir_D1_1 = "BEARISH";
  }
 if (Close_H4_1 > Open_H4_1) {
    dir_H4_1 = "BULLISH";
  } else {
    dir_H4_1 = "BEARISH";
  }
  #endif
  // PrintFormat("Latest H4 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n",dir_H4_1,Open_H4_1,High_H4_1,Low_H4_1,Close_H4_1,BBM_H4_1);
  // PrintFormat("Latest D1 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n", dir_D1_1,Open_D1_1,High_D1_1,Low_D1_1,Close_D1_1,BBM_D1_1 );
  // PrintFormat("BBM_H4_1: %f\nClose_H4_1: %f",BBM_H4_1,Close_H4_1);
  // PrintFormat("BBM_D1_1: %f\nClose_D1_1: %f",BBM_D1_1,Close_D1_1);

    if (CopyBuffer(HandleBollinger, UPPER_BAND, 0, numCandles, ValuesBollingerUpper) < numCandles) return;
    if (CopyBuffer(HandleBollinger, LOWER_BAND, 0, numCandles, ValuesBollingerLower) < numCandles) return;
    if (CopyBuffer(HandleBollinger, BASE_LINE, 0, numCandles, ValuesBollingerMiddle) < numCandles) return;
    // if (CopyBuffer(HandleBollinger_H4, UPPER_BAND, 0, numCandles, ValuesBollingerUpper_H4) < numCandles) return;
    // if (CopyBuffer(HandleBollinger_H4, LOWER_BAND, 0, numCandles, ValuesBollingerLower_H4) < numCandles) return;
    // if (CopyBuffer(HandleBollinger_H4, BASE_LINE, 0, numCandles, ValuesBollingerMiddle_H4) < numCandles) return;
    if (CopyBuffer(HandleKeltner, 0, 0, numCandles, ValuesKeltnerUpper) < numCandles) return;
    if (CopyBuffer(HandleKeltner, 2, 0, numCandles, ValuesKeltnerLower) < numCandles) return;
    if(CopyBuffer(HandleMacd,0,0,numCandles,ExtMacdBuffer) < InpSlowEMA) return;
    if(CopyBuffer(HandleMacd,1,0,numCandles,ExtSignalBuffer) < InpSlowEMA) return;
    if(CopyBuffer(ExtFastMaHandle,0,0,numCandles,ExtFastMaBuffer) < InpSlowEMA) return;
    if(CopyBuffer(ExtSlowMaHandle,0,0,numCandles,ExtSlowMaBuffer) < InpSlowEMA) return;

    // if (CopyBuffer(HandleDerivative,3,0,numCandles,bbuFirstDerivative)) return;
    // if (CopyBuffer(HandleDerivative,4,0,numCandles,bbuSecondDerivative)) return;
    // if (CopyBuffer(HandleDerivative,5,0,numCandles,bblFirstDerivative)) return;
    // if (CopyBuffer(HandleDerivative,6,0,numCandles,bblSecondDerivative)) return;
    if (CopyRates(Symbol(), Period(), 0, numCandles, Rates) < numCandles) return;
    if (!SymbolInfoTick(_Symbol, currentTick)) { Print("Failed to get current tick"); return; }
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      double high1 = NormalizeDouble(iHigh(Symbol(),Period(),1),Digits());
      double high2 = NormalizeDouble(iHigh(Symbol(),Period(),2),Digits());
      double low1 = NormalizeDouble(iLow(Symbol(),Period(),1),Digits());
      double low2 = NormalizeDouble(iLow(Symbol(),Period(),2),Digits());
      double close1 = NormalizeDouble(iClose(Symbol(),Period(),1),Digits());
      double close2 = NormalizeDouble(iClose(Symbol(),Period(),2),Digits());
      double open1 = NormalizeDouble(iOpen(Symbol(),Period(),1),Digits());
      double open2 = NormalizeDouble(iOpen(Symbol(),Period(),2),Digits());
      double bodySize1 = MathAbs(close1-open1);
      double bodySize2 = MathAbs(close2-open2);

    //HTF Confluence for BB
    // BBM_M30 = ValuesBollingerMiddle[2];
    // BBM_H1 = ValuesBollingerMiddle[4];
    // BBM_H4 = ValuesBollingerMiddle[16];
    // if (BBM_D1 == EMPTY_VALUE) {BBM_D1 = ValuesBollingerMiddle[1];}
    // if (BBM_W1 == EMPTY_VALUE) {BBM_W1 = ValuesBollingerMiddle[1];}
    //if this is the 1st second of the day, get BBM.
    //if MoD % 30 == 0 BBM_M30 = ValuesBo
    //if MoD
    // if (SoD(TimeCurrent()) == 0) {
    //     Print("NEW DAY! ValuesBollingerMiddle[1]: ",ValuesBollingerMiddle[1]);
    //     BBM_D1 = ValuesBollingerMiddle[1];
    //     Print("BBM_D1 is now ",BBM_D1);
    //     PrintFormat("Current BBM[0]: %f", ValuesBollingerMiddle[0]);
    //     PrintFormat("BBM_M30: %f\nBBM_H1: %f\nBBM_H4: %f\nBBM_D1: %f\nBBM_W1: %f\n",BBM_M30,BBM_H1,BBM_H4,BBM_D1,BBM_W1);
    //     //if this is the 1st second of the week, get BBM. IT'S BROKEN.
    //     if (DoWi(TimeCurrent()) == 1) {
    //       Print("NEW WEEK! ValuesBollingerMiddle[1]: ",ValuesBollingerMiddle[1]);
    //       BBM_W1 = ValuesBollingerMiddle[1];
    //       Print("BBM_W1 is now ",BBM_W1);
    //       PrintFormat("Current BBM[0]: %f", ValuesBollingerMiddle[0]);
    //       PrintFormat("BBM_M30: %f\nBBM_H1: %f\nBBM_H4: %f\nBBM_D1: %f\nBBM_W1: %f\n",BBM_M30,BBM_H1,BBM_H4,BBM_D1,BBM_W1);
    // }
    // if (  HoD(TimeCurrent()) % 4 == 0 && 
    //       MoH(TimeCurrent()) % 60 == 0) {
    //   PrintFormat("4H BAR BEGINS.");
    //   PrintFormat("ValuesBollingerMiddle[0]: %f \nValuesBollingerMiddle_H4[0]: %f",ValuesBollingerMiddle[0],ValuesBollingerMiddle_H4[0]);
    //   PrintFormat("ValuesBollingerMiddle[1]: %f \nValuesBollingerMiddle_H4[1]: %f",ValuesBollingerMiddle[1],ValuesBollingerMiddle_H4[1]);
    // }

    //use iBarshift to find open and close of HTF candles. Determine if that candle was bullish or bearish.   

      // Print(ExtMacdBuffer[0]);
      // Print(ExtSignalBuffer[0]);
      // Print(ExtSlowMaBuffer[0]);
      // Print(ExtFastMaBuffer[0]);

      double rr1 = (high1-low1) * 1.5;
      rr1 = NormalizeDouble(rr1,Digits());
      double tpTarget = (high1-low1) * 1.2;
      tpTarget = NormalizeDouble(tpTarget,Digits());


      ulong last_deal = GetLastDealTicket();
      ENUM_DEAL_REASON last_deal_reason = GetDealReason(last_deal);
      ENUM_DEAL_ENTRY last_deal_entry = GetDealEntry(last_deal);
      ulong minutes_since_last_deal = GetMinutesSinceDeal(last_deal);
      ulong hours_since_last_deal = GetHoursSinceDeal(last_deal);

      waiting_before_new_order = GetWaitingBeforeNewOrder(last_deal_entry,wait_time,minutes_since_last_deal);
      if (!use_wait_before_new_order_time) { waiting_before_new_order = false; }
      if(waiting_before_new_order) {fvbo_sell_setup = false; sell_counter = 0; fvbo_buy_setup = false; buy_counter=0;}

      bollinger_was_in_keltner = getBollingerWasInKeltner(0,InpKeltnerLookback);
      if (!use_bollinger_was_in_keltner) { bollinger_was_in_keltner = true; }
      if(!bollinger_was_in_keltner) {fvbo_sell_setup = false; sell_counter = 0; fvbo_buy_setup = false; buy_counter=0;}
      
      position_exists = getPositionExists();
      if(position_exists) {fvbo_sell_setup = false; sell_counter = 0; fvbo_buy_setup = false; buy_counter=0;}

      if (position_exists && use_max_position_holding_time) {
        ulong position_ticket = PositionGetTicket(0);
        closeExpiredPosition(position_ticket,minutes_since_last_deal,max_position_time);
      }
      //check if we can trade

    if (buy_counter == 0) { fvbo_buy_setup = false; buy_counter = 0; }
    if (sell_counter == 0) { fvbo_sell_setup = false; sell_counter = 0; } 


      //check if today is a trading day
      datetime my_time = iTime(Symbol(),Period(),0); //current time
      datetime my_prev_time = iTime(Symbol(),Period(),1); //time of latest fully formed bar  
      MqlDateTime current_server_time_struct;
      datetime current_server_time = TimeTradeServer();
      TimeToStruct(current_server_time,current_server_time_struct);
      int current_day_of_week = current_server_time_struct.day_of_week;
      int current_hour_of_day = current_server_time_struct.hour;
      // if (!isTradingDay(current_server_time_struct.day_of_week)) {
    //   //close position when outside trading day
    //   if (position_exists) {
    //     ulong last_deal = GetLastDealTicket();
    //     PrintFormat("Closing position: %i",last_deal);
    //     Trade.PositionClose(last_deal);
    //   }
    //   return;
    // }
    // if (!isTradingHours(current_server_time_struct.hour, InpStartHour,InpEndHour)) {
    //   //close position when outside trading hour
    //   if (position_exists) {
    //     ulong last_deal = GetLastDealTicket();
    //     PrintFormat("Closing position: %i",last_deal);
    //     Trade.PositionClose(last_deal);
    //   }
    //   return;
    // }

    //LINEAR & POLYNOMIAL REGRESSION
    double Num[20]; double LPrice[20]; double X[20]; double Y[20];
    for(int i = 0 ; i < 20;i++) {
        Num[i]=i;
        LPrice[20-i-1]=iClose(_Symbol,Period(),0+i);
        X[i] = i;
        Y[i] = iClose(_Symbol, Period(), i);
    }
    LinReg LR(Num, LPrice);
    PolyReg PR(X, Y,2);     // Create a PolyReg object with degree 2
    double newX= 0;
    double predictedPR = PR.Predict(newX);
    double predictedLR = LR.Beta() * (ArraySize(LPrice) - 1) + LR.Intercept();
    // double secondDerivativeL = LR.SecondDerivative(); //always 0
    double secondDerivativeP = PR.SecondDerivative();
    double coefficientP = PR.Coefficient(0);

//   datetime time=D'2024.02.14 10:30';
//   // datetime time =TimeCurrent();
//    string symbol="AUDJPY";
//    ENUM_TIMEFRAMES tf=PERIOD_D1;
//    bool exact=false;
// //--- there is no bar at the specified time, iBarShift will return the index of the nearest bar
//    int bar_index=iBarShift(symbol,tf,time,exact);
//    PrintFormat("1. %s %s %s(%s): bar index is %d (exact=%s)",
//                symbol,EnumToString(tf),TimeToString(time),DayOfWeek(time),bar_index,string(exact));
//    datetime bar_time=iTime(symbol,tf,bar_index);
//    PrintFormat("Time of bar #%d is %s (%s)",
//                bar_index,TimeToString(bar_time),DayOfWeek(bar_time));
// //PrintFormat(iTime(symbol,tf,bar_index));
// //--- Request the index of the bar with the specified time; but there is no bar, return -1
//    exact=true;
//    bar_index=iBarShift(symbol,tf,time,exact);
//    PrintFormat("2. %s %s %s (%s):bar index is %d (exact=%s)",
//                symbol,EnumToString(tf),TimeToString(time),DayOfWeek(time),bar_index,string(exact));

    // Print("LR: ",LR.Beta(),"x+",LR.Intercept());
    // // Print("Second derivativeL: ", secondDerivativeL); //incorrect, this should always be 0
    // Print("Second derivativeP: ", secondDerivativeP);
    // Print("PRCoefficient ", coefficientP);
    // Print("Predicted valueP", newX, ": ", predictedPR); //predicted polynomial regression value same as Coefficient?
    // PrintFormat("Ask: %f\n Bid: %f",Ask,Bid);

      ObjectCreate(_Symbol,"LinReg",OBJ_TREND,0,Rates[19].time,LR.Intercept(),Rates[0].time,LR.Beta()*19+Rates[0].close);
      ObjectSetInteger(0,"LinReg",OBJPROP_COLOR,Red);
      ObjectSetInteger(0,"LinReg",OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,"LinReg",OBJPROP_WIDTH,4);
      ObjectCreate(_Symbol,"LinReg+std",OBJ_TREND,0,Rates[19].time,LR.Intercept() + LR.Std(LPrice),Rates[0].time,LR.Beta()*19+Rates[0].close+ LR.Std(LPrice));   
      ObjectSetInteger(0,"LinReg+std",OBJPROP_COLOR,Green);
      ObjectSetInteger(0,"LinReg+std",OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,"LinReg+std",OBJPROP_WIDTH,0);   
      ObjectCreate(_Symbol,"LinReg-std",OBJ_TREND,0,Rates[19].time,LR.Intercept() - LR.Std(LPrice),Rates[0].time,LR.Beta()*19+Rates[0].close- LR.Std(LPrice));
      ObjectSetInteger(0,"LinReg-std",OBJPROP_COLOR,Green);
      ObjectSetInteger(0,"LinReg-std",OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,"LinReg-std",OBJPROP_WIDTH,0);

      ObjectCreate(_Symbol,"PolyReg",OBJ_TREND,0,Rates[19].time,PR.Coefficient(19),Rates[0].time,PR.Coefficient(0));
      ObjectSetInteger(0,"PolyReg",OBJPROP_COLOR,Blue);
      ObjectSetInteger(0,"PolyReg",OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,"PolyReg",OBJPROP_WIDTH,4);

      

      //BUY CONDITION
      if (isFvboBuySetup(1)) { fvbo_buy_setup = true; buy_counter = InpBuyCounter; }
      if (!use_fvbo_signal) {fvbo_buy_setup = false; fvbo_sell_setup = false; }
      //place an order while counter not expired, we have no open positions and we're not waiting before a new order
      if (fvbo_buy_setup && buy_counter > 0) {
        Price = high1;       // Price = MathMax(Ask, Price);// to eliminate those pesky invalid Price errors
        StopLoss = NormalizeDouble(low1-StopLossGap,Digits());
        TakeProfit = NormalizeDouble(Price + tpTarget,Digits());
        datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
        string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
        if (Price+rr1 < ValuesBollingerMiddle[0]) {
        // Adjustments based on the second derivative
        // if (secondDerivativeL > 0)     // Positive second derivative indicates a strengthening trend, Buy only if Bid is below predicted value
          // {
            // if (TakeProfit < predictedPR) //POLYNOMIAL PRED.
            // if (Bid < predictedLR) //LINEAR PRED
            // if (

            // (ExtFastMaBuffer[0] < ExtSlowMaBuffer[0] && ExtSignalBuffer[0] > 0) //1 trade 100% win
            // && 
            // TakeProfit < predictedPR
            // )
            // {

            double lots = 0.1;
            //our "prediction" is takeProfit. find where takeProfit is relative to HTF BB
            // if (TakeProfit < BBM_M30) { lots+= 0.01; Print("TP < BBM_M30 ",BBM_M30 ,". Increasing lot size to ", lots); }
            // if (TakeProfit < BBM_H1)  { lots+= 0.01; Print("TP < BBM_H1  ",BBM_H1  ,". Increasing lot size to ", lots);}
            // if (TakeProfit < BBM_H4)  { lots+= 0.01; Print("TP < BBM_H4  ",BBM_H4  ,". Increasing lot size to ", lots);}
            // if (TakeProfit < BBM_D1)  { lots+= 0.01; Print("TP < BBM_D1  ",BBM_D1  ,". Increasing lot size to ", lots);}
            // if (TakeProfit < BBM_W1)  { lots+= 0.01; Print("TP < BBM_W1  ",BBM_W1  ,". Increasing lot size to ", lots);}
              //IF GRADIENT IS STEEPLY DECREASING, DECREASE LOT SIZE
            if (LR.Beta() > 0)         {lots+= 0.1;   Print("LR.Beta (slope) > 0. LR Slope is now positive. Increasing lot size to ", lots);} //RARE for the slope to change direction, but it does happen.
            if (LR.Beta() > local_min) {lots+= 0.02; Print("LR.Beta (slope) > local_min ",local_min," Increasing lot size to ", lots);} //if LR slope is greater than...
            if (ExtFastMaBuffer[0] < ExtSlowMaBuffer[0] && ExtSignalBuffer[0] > 0) { lots+=0.1; Print("FastMA < SlowMA and Signal > 0. MACD Crossover. Increasing lot size to ", lots);}
            if (TakeProfit < predictedPR) { lots+= 0.02; Print("TP < predictedPR. Increasing lot size to ", lots);}
            if (TakeProfit < predictedLR) { lots+= 0.02; Print("TP < predictedLR. Increasing lot size to ", lots);}
            // TakeProfit += NormalizeDouble(TakeProfit*lots,Digits());
            #ifdef htf
            PrintFormat("Latest H1 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n",dir_H1_1,Open_H1_1,High_H1_1,Low_H1_1,Close_H1_1,BBM_H1_1);
            PrintFormat("Latest H4 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n",dir_H4_1,Open_H4_1,High_H4_1,Low_H4_1,Close_H4_1,BBM_H4_1);
            PrintFormat("Latest D1 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n", dir_D1_1,Open_D1_1,High_D1_1,Low_D1_1,Close_D1_1,BBM_D1_1);
            //for a buystop, we want to know if the candle was below their midlines
            if (High_D1_1 >BBM_D1_1) {
              Print("D1 high < BBMID. Whole D1 candle below BBMid. D1 did not touch midline.");
            } else {
              Print("D1 high > BBMID");
            }
            if (High_H4_1 >BBM_H4_1) {
              Print("H4 high < BBMID. Whole H4 candle below BBMid. H4 did not touch midline.");
            } else {
              Print("H4 high > BBMID");
            }
            if (High_H1_1 >BBM_H1_1) {
              Print("H4 high < BBMID. Whole H1 candle below BBMid. H1 did not touch midline.");
            } else {
              Print("H4 high > BBMID");
            }
            Print("D1 MIDLINE TEST:");
            Print("H4 MIDLINE TEST:");
            Print("H1 MIDLINE TEST:");
            Print("D1 BBLOW TEST:");
            Print("H4 BBLOW TEST:");
            Print("H1 BBLOW TEST:");
            #endif
            Trade.BuyStop(lots,Price,Symbol(),StopLoss,TakeProfit,ORDER_TIME_SPECIFIED,expiration); 
            // }
        // }
        // else if (secondDerivativeP < 0)     // Negative second derivative indicates a weakening trend, so Buy only if Bid is significantly below predicted value
          // {
          // if (Bid < predictedPR * 0.98) // POLYNOMIAL PRED
          // if (Bid < predictedLR * 0.98) // LINEAR PRED
            // {
              // Trade.BuyStop(0.1, Price, Symbol(), StopLoss, TakeProfit, ORDER_TIME_SPECIFIED, expiration);
            // }
          // }
        }
      buy_counter--;
      }
    
  //SELL CONDITION
    if (isFvboSellSetup(1) && use_fvbo_signal) { fvbo_sell_setup = true; sell_counter = InpSellCounter; }
    //SELL PRICE ACTION
        if (!use_fvbo_signal) {fvbo_buy_setup = false; fvbo_sell_setup = false; }
    if (fvbo_sell_setup && sell_counter > 0) {
        Price = low1; //can use Price = MathMin(Bid, Rates[1].low) to eliminate those pesky invalid Price errors
        StopLoss = NormalizeDouble(high1+StopLossGap,Digits());
        TakeProfit = NormalizeDouble(Price - tpTarget,Digits());
        datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period()); //expiration
        string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
        //validate trade
        if (Price-rr1 > ValuesBollingerMiddle[0]) {
          // Print("SELL: Price - target condition met...");
          // if (secondDerivativeL > 0)
          // {
            // Print("SELL: secondDerivativeL > 0..., STRENGTHENING TREND");
          // Positive second derivative indicates a strengthening trend, so Sell only if Ask is SIGNIFICANTLY above predicted value
            // if (Ask > predictedPR * 1.01) // Adjust the threshold as needed
            // if (Ask > predictedLR * 1.02) // Adjust the threshold as needed
            // {          
              // Print("SO ASKING WELL ABOVE ASK");
              // Trade.SellStop(0.1,Price,Symbol(),StopLoss,TakeProfit,ORDER_TIME_SPECIFIED,expiration); 
            // }
        //  }
      // else if (secondDerivativeL < 0)
        // {
        // Print("SELL: secondDerivativeL > 0..., WEAKENING TREND");
        // Negative second derivative indicates a weakening trend, so sell only if Ask is above predicted value
          // if (TakeProfit > predictedPR)
          // if (Ask > predictedLR)
          // if (

          // && 
          // TakeProfit > predictedPR
          // )
          // {
            double lots = 0.1;
            //our "prediction" is takeProfit. find where takeProfit is relative to HTF
            // if (TakeProfit > BBM_M30) { lots+= 0.01; Print("TP > BBM_M30 ",BBM_M30 ,". Increasing lot size to ", lots);}
            // if (TakeProfit > BBM_H1)  { lots+= 0.01; Print("TP > BBM_H1  ",BBM_H1  ,". Increasing lot size to ", lots);}
            // if (TakeProfit > BBM_H4)  { lots+= 0.01; Print("TP > BBM_H4  ",BBM_H4  ,". Increasing lot size to ", lots);}
            // if (TakeProfit > BBM_D1)  { lots+= 0.01; Print("TP > BBM_D1  ",BBM_D1  ,". Increasing lot size to ", lots);}
            // if (TakeProfit > BBM_W1)  { lots+= 0.01; Print("TP > BBM_W1  ",BBM_W1  ,". Increasing lot size to ", lots);}
            //IF GRADIENT IS STEEPLY INCREASING, DECREASE LOT SIZE
            if (LR.Beta() < 0)          {lots+=0.1;   Print("LR.Beta (slope) < 0. LR Slope is now positive. Increasing lot size to ", lots);} //rare for the slope to change direction, but it has happened
            if (LR.Beta() < local_max)  {lots+= 0.02; Print("LR.Beta (slope) < local_max ",local_max," Increasing lot size to ", lots);} //if LR slope is less than...
            if (ExtFastMaBuffer[0] > ExtSlowMaBuffer[0] && ExtSignalBuffer[0] < 0) { lots+= 0.1; Print("FastMA > SlowMA and Signal < 0. MACD Crossover. Increasing lot size to ", lots);} //1 trade, 100% win
            if (TakeProfit > predictedPR) { lots+= 0.02; Print("TP > predictedPR. Increasing lot size to ", lots);}
            if (TakeProfit > predictedLR) { lots+= 0.02; Print("TP > predictedLR. Increasing lot size to ", lots);}
          // TakeProfit += NormalizeDouble(TakeProfit*lots,Digits());
          #ifdef htf
            PrintFormat("Latest H1 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n",dir_H1_1,Open_H1_1,High_H1_1,Low_H1_1,Close_H1_1,BBM_H1_1);
            PrintFormat("Latest H4 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n",dir_H4_1,Open_H4_1,High_H4_1,Low_H4_1,Close_H4_1,BBM_H4_1);
            PrintFormat("Latest D1 Candle closed %s:\nO:     %f\nH:     %f\nL:     %f\nC:     %f\nBBMid: %f\n", dir_D1_1,Open_D1_1,High_D1_1,Low_D1_1,Close_D1_1,BBM_D1_1 );
            if (Low_D1_1 >BBM_D1_1) {
              Print("D1 low > BBMID. Whole D1 candle above BBMid. D1 did not touch Midline");
            } else {
              Print("D1 low < BBMID");
            }
            if (Low_H4_1 >BBM_H4_1) {
              Print("H4 low > BBMID. Whole H4 candle above BBMid. H4 did not touch Midline");
            } else {
              Print("H4 low < BBMID");
            }
            if (Low_H1_1 >BBM_H1_1) {
              Print("H1 low > BBMID. Whole H1 candle above BBMid. H1 did not touch Midline");
            } else {
              Print("H1 low < BBMID");
            }
            Print("D1 MIDLINE TEST:");
            Print("H4 MIDLINE TEST:");
            Print("H1 MIDLINE TEST:");
            Print("D1 BBUPPER TEST:");
            Print("H4 BBUPPER TEST:");
            Print("H1 BBUPPER TEST:");
            #endif
          Trade.SellStop(lots, Price, Symbol(), StopLoss, TakeProfit, ORDER_TIME_SPECIFIED, expiration);
          // }
        }
      sell_counter--;
    }
      //sell_counter expired
  }
  bool zeroCrossDesc(double y1, double y2) {
    return (y1 > 0 && y2 < 0) ? true: false;
  }
  bool zeroCrossAsc(double y1, double y2) {
    return (y1 < 0 && y2 > 0) ? true: false;
  }
  void drawZeroCross(int candleIndex, double y1, double y2) {
    datetime setupTime = iTime(Symbol(), Period(), 1);
    if (zeroCrossDesc(y1,y2)) {
      // draw a green buy arrow at high
      PrintFormat("FOUND ZERO CROSSING");
      ObjectCreate(0, "zeroCrossDesc" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
      ObjectSetString(0,"zeroCrossDesc" + setupTime,OBJPROP_TEXT,"000000");
      ObjectSetInteger(0, "zeroCrossDesc" + setupTime, OBJPROP_COLOR, clrBlue);
      ObjectSetDouble(0,"zeroCrossDesc" + setupTime,OBJPROP_ANGLE,90.0);
    } else if (zeroCrossAsc(y1,y2)) {
      PrintFormat("FOUND ZERO CROSSING");
      ObjectCreate(0, "zeroCrossAsc" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
      ObjectSetString(0,"zeroCrossAsc" + setupTime,OBJPROP_TEXT,"0000000");
      ObjectSetInteger(0, "zeroCrossAsc" + setupTime, OBJPROP_COLOR, clrRed);
      ObjectSetDouble(0,"zeroCrossAsc" + setupTime,OBJPROP_ANGLE,90.0);
    }
  }
  // //utils
  double calculateGradient(const double& array[], const int startIndex, const int numValues) {
      // Calculate the sum of x and y values, and the sum of their products
      double sumX = 0.0;
      double sumY = 0.0;
      double sumXY = 0.0;
      double sumX2 = 0.0;
      for (int i = 0; i < numValues; i++) {
          sumX += i;
          sumY += array[startIndex + i];
          sumXY += i * array[startIndex + i];
          sumX2 += i * i;
      }

      // Calculate the slope (gradient) using the formula: m = (nΣ(xy) - ΣxΣy) / (nΣ(x^2) - (Σx)^2)
      double gradient = (numValues * sumXY - sumX * sumY) / (numValues * sumX2 - sumX * sumX);
      return gradient;
  }
  // Function to fit a polynomial curve to Bollinger Band values
string DayOfWeek(const datetime time)
  {
   MqlDateTime dt;
   string day="";
   TimeToStruct(time,dt);
   switch(dt.day_of_week)
     {
      case 0: day=EnumToString(SUNDAY);
      break;
      case 1: day=EnumToString(MONDAY);
      break;
      case 2: day=EnumToString(TUESDAY);
      break;
      case 3: day=EnumToString(WEDNESDAY);
      break;
      case 4: day=EnumToString(THURSDAY);
      break;
      case 5: day=EnumToString(FRIDAY);
      break;
      default:day=EnumToString(SATURDAY);
      break;
     }
//---
   return day;
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

  bool isTradingDay(int day) { 
    if (InpSunday == false && day == 0) {
      // PrintFormat("Cannot trade on a Sunday");
      return false;
    }
    if (InpMonday == false && day == 1) {
      // PrintFormat("Cannot trade on a Monday");
      return false;
    }
    if (InpTuesday == false && day == 2) {
      // PrintFormat("Cannot trade on a Tuesday");
      return false;
    }
    if (InpWednesday == false && day == 3) {
      // PrintFormat("Cannot trade on a Wednesday");
      return false;
    }
    if (InpThursday == false && day == 4) {
      // PrintFormat("Cannot trade on a Thursday");
      return false;
    }
    if (InpFriday == false && day == 5) {
      // PrintFormat("Cannot trade on a Friday");
      return false;
    }
    if (InpSaturday == false && day == 6) {
      // PrintFormat("Cannot trade on a Saturday");
      return false;
    }
    return true;
  }
  bool isTradingHours(int hour,int start,int end) {
    return (hour >= start && hour <= end) ? true : false;
  }

  ulong GetLastDealTicket() {
    //--- request history for the last 7 days
    if (!GetTradeHistory(7)) {
      //--- notify on unsuccessful call and return -1
      Print(__FUNCTION__, " HistorySelect() returned false");
      return -1;
    }
    //---
    ulong first_deal, last_deal, deals = HistoryDealsTotal();
    //--- work with orders if there are any
    if (deals > 0) {
      //        Print("Deals = ", deals);
      first_deal = HistoryDealGetTicket(0);
      if (deals > 1) {
        last_deal = HistoryDealGetTicket((int) deals - 1);
        //            PrintFormat("last_deal = %d", last_deal);
        return last_deal;
      }
      return first_deal;
    }
    //--- no deal found, return -1
    return -1;
  }
  bool GetTradeHistory(int days) {
    //--- set a week period to request trade history
    datetime to = TimeCurrent();
    datetime from = to - days * PeriodSeconds(PERIOD_D1);
    ResetLastError();
    //--- make a request and check the result
    if (!HistorySelect(from, to)) {
      Print(__FUNCTION__, " HistorySelect=false. Error code=", GetLastError());
      return false;
    }
    //--- history received successfully
    return true;
  }
  bool GetWaitingBeforeNewOrder(ENUM_DEAL_ENTRY deal_entry, ulong wait_time, ulong minutes_since_deal) {
      if (deal_entry == DEAL_ENTRY_OUT && minutes_since_deal < wait_time) {
        // PrintFormat("Minutes since last %s : %i",EnumToString(deal_entry),minutes_since_deal);
        return true;
      }
      return false;
  };
  ENUM_DEAL_REASON GetDealReason(ulong deal_ticket) {
      ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(deal_ticket, DEAL_REASON);
      return deal_reason;
  }
  ENUM_DEAL_ENTRY GetDealEntry(ulong deal_ticket) {
      ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
      return deal_entry;
  }
  ulong GetDealTime(ulong deal_ticket) {
    datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
    return deal_time;
  }
  ulong GetMinutesSinceDeal(ulong deal_ticket) {
    ulong deal_time = GetDealTime(deal_ticket);
    ulong current_time = (long)TimeCurrent();
    ulong time_since_deal = current_time-deal_time;
    ulong time_since_deal_mins = time_since_deal / 60;
    return time_since_deal_mins;    
  }
  ulong GetHoursSinceDeal(ulong deal_ticket) {
    ulong deal_time = GetDealTime(deal_ticket);
    ulong current_time = (long)TimeCurrent();
    ulong time_since_deal = current_time-deal_time;
    ulong time_since_deal_mins = time_since_deal / 60;
    ulong time_since_deal_hours = time_since_deal_mins / 24;
    return time_since_deal_hours; 
  }
  void closeExpiredPosition(ulong position_ticket, ulong minutes_since_deal, ulong max_position_time) {
    if (minutes_since_deal > max_position_time) {
      // PrintFormat("Minutes Since Last deal: %i \n Closing Position Ticket: %i",minutes_since_deal,position_ticket);   
      Trade.PositionClose(position_ticket);
    }
  }
  bool getPositionExists() {
    return PositionsTotal() > 0 ? true : false;
  }
  bool getBollingerWasInKeltner(int candleIndex, int lookback) {
    int count = 0;
    for (int i = candleIndex; i < lookback; i++) {
      if ((ValuesBollingerLower[i] > ValuesKeltnerLower[i]) || (ValuesBollingerUpper[i] < ValuesKeltnerUpper[i])) {
        count++;
      }
    }
    // if (count > 7) {
      // PrintFormat("High Compression...Bollinger inside keltner candles: %i out of last %i",count,lookback);
    // }
    return count > 0 ? true : false;
  }
  double getTailSize(int candleIndex) {
    double tailSize = 0;
    // candle is bearish, close is lower than open.
    // so tail is close - low.
    if (bearishCandle(candleIndex)) {
      tailSize = Rates[candleIndex].close - Rates[candleIndex].low;
    } else {
      tailSize = Rates[candleIndex].open - Rates[candleIndex].low;
    }
    return tailSize;
  }
  double getWickSize(int candleIndex) {
    double wickSize = 0;
    // if bearish candle, close is higher than open.
    // so wick is high - close.
    if (bearishCandle(candleIndex)) {
      wickSize = Rates[candleIndex].high - Rates[candleIndex].open;
    } else {
      wickSize = Rates[candleIndex].high - Rates[candleIndex].close;
    }
    return wickSize;
  }
  double getBodySize(int candleIndex) {
    return MathAbs(Rates[candleIndex].open - Rates[candleIndex].close);
  }
  double getTailWickSize(int candleIndex) {
    return getTailSize(candleIndex) + getWickSize(candleIndex);
  }
  bool isFvboBuySetup(int i) {
      double close1 = NormalizeDouble(iClose(Symbol(),Period(),i),Digits());
      double close2 = NormalizeDouble(iClose(Symbol(),Period(),i+1),Digits());
      double open1 = NormalizeDouble(iOpen(Symbol(),Period(),i),Digits());
      double open2 = NormalizeDouble(iOpen(Symbol(),Period(),i+1),Digits());
    return (ValuesBollingerLower[i+1] < ValuesKeltnerLower[i+1]  //candle 2 bollinger outside keltner
      && close2 < ValuesBollingerLower[i+1]                     //candle 2 closed outside bollinger
      && close2 < open2                                         //candle 2 is bearish candle
      && close1 > open1                                         //candle1 bullish
      && !fvbo_buy_setup)                                       //not already in a setup           
    ? true : false;
  }
  bool isFvboSellSetup(int i) {
  double close1 = NormalizeDouble(iClose(Symbol(),Period(),i),Digits());
  double close2 = NormalizeDouble(iClose(Symbol(),Period(),i+1),Digits());
  double open1 = NormalizeDouble(iOpen(Symbol(),Period(),i),Digits());
  double open2 = NormalizeDouble(iOpen(Symbol(),Period(),i+1),Digits());
    return (
      ValuesBollingerUpper[i+1] > ValuesKeltnerUpper[i+1]                      //candle2 bollinger outside keltner
      && close2 > ValuesBollingerUpper[i+1]                                   //candle2 closed outside bollinger
      && close2 > open2                                                       //candle2 is bullish
      && close1 < open1                                                       //candle1 is bearish
      && !fvbo_sell_setup                                                     //not already in a setup
    )           
    ? true : false;
  }
  // Trading
  void OpenBetterOrder(ENUM_ORDER_TYPE type, double price, double stopLoss, double takeProfit, double lots, string comment) {
    // refactor TP to use candle Range or rVal
    int digits = Digits();
    // price = NormalizeDouble(price, digits);
    // stopLoss = NormalizeDouble(stopLoss, digits);
    // takeProfit = NormalizeDouble(takeProfit, digits);
    // order expires at end of next candle
    datetime expiration = iTime(Symbol(), Period(), 0) + PeriodSeconds(Period());
  string expiration_string = TimeToString(expiration,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
  //  PrintFormat("Called OpenBetterOrder.\n Digits: %i \n Parsed in... price: %.3f \n stopLoss: %.3f \n takeProfit: %.3f \n BBMID: %.3f \n Expiration: %s",digits,price,stopLoss,takeProfit,ValuesBollingerMiddle[1],expiration_string);

    if (!Trade.OrderOpen(Symbol(), type, lots, 0, price, stopLoss,
        takeProfit,
        ORDER_TIME_SPECIFIED, expiration, comment)) {
      PrintFormat("Open Order failed for %s, %s, price=%f, sl=%f, tp=%f",
        Symbol(), EnumToString(type), price, stopLoss, takeProfit);
    }
  }
  bool bearishCandle(int candleIndex) {
    return Rates[candleIndex].close < Rates[candleIndex].open ? true : false;
  }
  bool bullishCandle(int candleIndex) {
    return Rates[candleIndex].close > Rates[candleIndex].open ? true : false;
  }
  // Utility functions
  // Source: How to run MQL4 or MQL5 code only one time for each bar
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
  bool bbWasInKeltner(int n) {
    datetime bbWasInKeltnerTime;
    for (int i = n; i > 0; i--) {
      bbWasInKeltnerTime = iTime(Symbol(), Period(), i);

      PrintFormat("bbWasInKeltnerTime: %s", TimeToString(bbWasInKeltnerTime));
      PrintFormat("BBL: %f KCL: %f BBU: %f KCU: %f", ValuesBollingerLower[i], ValuesKeltnerLower[i], ValuesBollingerUpper[i], ValuesKeltnerUpper[i]);
      if (
        (ValuesBollingerLower[i] >= ValuesKeltnerLower[i]) || (ValuesBollingerUpper[i] <= ValuesKeltnerUpper[i])) {
        Print("bb inside keltner");
        return true;
      }
    }
    return false;
  }
  //+------------------------------------------------------------------+
  //| INDICATORS, PATTERNS & SIGNALS                    |
  //+------------------------------------------------------------------+


  void drawFvboSetup(int candleIndex) {
    datetime setupTime = iTime(Symbol(), Period(), 1);
    if (isFvboBuySetup(candleIndex)) {
      // draw a green buy arrow at high
      ObjectCreate(0, "BuySetup" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
      ObjectSetString(0,"BuySetup" + setupTime,OBJPROP_TEXT,"FVBO");
      ObjectSetInteger(0, "BuySetup" + setupTime, OBJPROP_COLOR, clrBlue);
      ObjectSetDouble(0,"BuySetup" + setupTime,OBJPROP_ANGLE,90.0);
    } else if (isFvboSellSetup(candleIndex)) {
      ObjectCreate(0, "SellSetup" + setupTime, OBJ_TEXT, 0, setupTime, Rates[candleIndex].high);
      ObjectSetString(0,"SellSetup" + setupTime,OBJPROP_TEXT,"FVBO");
      ObjectSetInteger(0, "SellSetup" + setupTime, OBJPROP_COLOR, clrRed);
      ObjectSetDouble(0,"SellSetup" + setupTime,OBJPROP_ANGLE,90.0);
    }
  }

  /*
  bool isFVBO_BUY_M10(int candleIndex){}
  bool isFVBO_BUY_M30(int candleIndex){}
  bool isFVBO_BUY_H1(int candleIndex){} //print times
  bool isFVBO_SELL_M10(int candleIndex){}
  bool isFVBO_SELL_M30(int candleIndex){}
  bool isFVBO_SELL_H1(int candleIndex){} 
  bool isCandleBelowMidline(int candleIndex, int timeframe){} //midline test
  bool isCandleAboveMidline(int candleIndex, int timeframe){} //remember, candle doesn't need to close, just needs either a h/l 
  bool isCandleTestBelowBBL(int candleIndex, int timeframe){}
  bool isCandleAboveBBL(int candleIndex, int timeframe){}
  bool isCandleBelowBBU(int candleIndex, int timeframe){}
  bool isCandleAboveBBU(int candleIndex, int timeframe){}
  double getBbGradient() {}
  int peakFinder(){}
  */

