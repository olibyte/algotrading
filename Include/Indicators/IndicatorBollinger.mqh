//+------------------------------------------------------------------+
//|                                                 IndicatorCSR.mqh |
//|                                Copyright 2024, olibyte.github.io |
//|                                        https://olibyte.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, olibyte.github.io"
#property link      "https://olibyte.github.io"
#property version   "1.00"
#include "IndicatorBase.mqh"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 3

#property indicator_color1 clrYellow
#property indicator_width1 3
#property indicator_style1 STYLE_DASH
#property indicator_type1 DRAW_LINE
#property indicator_label1 "ICSR-BBand flip"

#property indicator_color2 clrFireBrick
#property indicator_width2 3
#property indicator_style2 STYLE_SOLID
#property indicator_type2 DRAW_LINE
#property indicator_label2 "Resistance"

#property indicator_color3 clrGreen
#property indicator_width3 3
#property indicator_style3 STYLE_DOT
#property indicator_type3 DRAW_LINE
#property indicator_label3 "Support"

input int                  InpPeriod = 20;                  //Period
input double               InpDeviations = 2.0;             //Deviations
input ENUM_APPLIED_PRICE   InpAppliedPrice = PRICE_CLOSE;   //Applied Price

double BufferTrend[];
double BufferResistance[];
double BufferSupport[];
//Working buffers
double BufferUpper[];
double BufferLower[];

int HandleCSR;
/*
	CIndicatorCSR
	Usage: CIndicatorCSR Bollinger = new CIndicatorCSR(symbol, timeframe, bandsPeriod, bandsShift, deviation, appliedPrice)
*/
class CIndicatorCSR : public CIndicatorBase {

private:

protected:

	int	mbandsPeriod;
	int	mbandsShift;
	double	mdeviation;
	int	mAppliedPrice;
	
public:

	CIndicatorCSR()	:	CIndicatorBase()	{};
	CIndicatorCSR(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice);
	~CIndicatorCSR();

	void			Init(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice);
	
	#ifdef __MQL4__
		double	GetValue(int bufferNumber, int index);
	#endif
	
};

CIndicatorCSR::CIndicatorCSR(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice)
		: CIndicatorBase() {
		
	Init(symbol, timeframe, bandsPeriod, bandsShift, deviation, appliedPrice);
	
}

void		CIndicatorCSR::Init(string symbol,int timeframe,int bandsPeriod,int bandsShift,double deviation,int appliedPrice) {

	//	Only needed for mql4 but no harm for mql5
	mSymbol			=	symbol;
	mTimeframe		=	timeframe;
	mbandsPeriod		=	bandsPeriod;
	mbandsShift		=	bandsShift;
	mdeviation	=	deviation;
	mAppliedPrice	=	appliedPrice;
	
	#ifdef __MQL5__
	
	SetIndexBuffer(0,BufferTrend);
   SetIndexBuffer(1,BufferResistance);
   SetIndexBuffer(2,BufferSupport);
   
   //Buffers required to track upper and low values
   SetIndexBuffer(3,BufferUpper,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferLower,INDICATOR_CALCULATIONS);
   
   //set as series to keep consistent with functions like iHigh, iLow...
   ArraySetAsSeries(BufferTrend, true);
   ArraySetAsSeries(BufferResistance, true);
   ArraySetAsSeries(BufferSupport, true);
   ArraySetAsSeries(BufferUpper, true);
   ArraySetAsSeries(BufferLower, true);   
	
	
		mHandle	=	iBands(symbol, (ENUM_TIMEFRAMES)timeframe, bandsPeriod, bandsShift, deviation, appliedPrice);		
	#endif
	
	//	Set initialised
	//	I'm not currently using this but I should
	mInitialised		=	true;

}

CIndicatorCSR::~CIndicatorCSR() {
}

#ifdef __MQL4__
	double	CIndicatorCSR::GetValue(int bufferNumber, int index) {
		double	result	=	iBands(mSymbol, mTimeframe, mbandsPeriod, mbandsShift, mdeviation, mAppliedPrice, bufferNumber, index);
		return(result);
	}
#endif 
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
  //need a min number of available rates to function
   if (rates_total<InpPeriod) return(0);   
   
   //Housekeeping to release ASAP
   if (IsStopped()) return(0);
   
      //Indicator values may take time to fill - if still filling just go around again
   int calculated = BarsCalculated(HandleCSR);
   if (calculated < rates_total) {
      Print("Waiting on calculations");
      return(0);
   }
   
   int limit;
   if (prev_calculated>rates_total || prev_calculated<0) {
   limit = rates_total; 
   } else {
      limit = rates_total-prev_calculated;
      if (prev_calculated>0) limit++;
   }
   
   if ((CopyBuffer(HandleCSR,UPPER_BAND,0,limit, BufferUpper)<=0)) {
      Print("Getting Bands failed! Error ", GetLastError());
      return(0);
   }
   if ((CopyBuffer(HandleCSR,LOWER_BAND,0,limit, BufferLower)<=0)) {
      Print("Getting Bands failed! Error ", GetLastError());
      return(0);
   }
   //ENSURE the indices are right to left
   ArraySetAsSeries(close,true);
   
   //SKIP VALS ALREADY CALCULATED
   int start = (prev_calculated==0) ? 
                                    rates_total-InpPeriod-1 : 
                                    rates_total-prev_calculated;
   
   //Loop through bars
   for (int i = start; i>=0 && !IsStopped(); i--) {
      //calc bands
      double upper = BufferUpper[i];
      double lower = BufferLower[i];
   
      int prev = i+1;
      BufferResistance[i] = EMPTY_VALUE;
      BufferSupport[i] = EMPTY_VALUE;
   
      if(close[i]>BufferTrend[prev] && close[prev]<=BufferTrend[prev]) {
         //closed above upper trend line
         BufferTrend[i]=lower;
         BufferSupport[i]=lower;
      } else
      if(close[i]<BufferTrend[prev] && close[prev]>=BufferTrend[prev]) {
         //closed below lower trend line
         BufferTrend[i] = upper;
         BufferResistance[i] = upper;
      } else
      if (BufferTrend[prev]<lower) {
         //move lower trend line up
         BufferTrend[i]=lower;
         BufferSupport[i]=lower;
      } else
      if (BufferTrend[prev] >upper) {
         //move upper trend line down
         BufferTrend[i]=upper;
         BufferResistance[i]=upper;
      } else {
         //keep all trend lines at previous level, established trend lines cannot move further away
         BufferTrend[i]=BufferTrend[prev];
         BufferSupport[i]=BufferSupport[prev];
         BufferResistance[i]=BufferResistance[prev];
      }         
   }
   
   return(rates_total);
 }

