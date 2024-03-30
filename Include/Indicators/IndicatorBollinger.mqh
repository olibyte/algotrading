#property copyright "Copyright 2024, olibyte"
#property link      "https://olibyte.github.io"
#property version   "1.00"

#include "IndicatorBase.mqh"

/*
	CIndicatorBollinger
	Usage: CIndicatorBollinger Bollinger = new CIndicatorBollinger(symbol, timeframe, bandsPeriod, bandsShift, deviation, appliedPrice)
*/
class CIndicatorBollinger : public CIndicatorBase {

private:

protected:

	int	mbandsPeriod;
	int	mbandsShift;
	int	mdeviation;
	int	mAppliedPrice;
	
public:

	CIndicatorBollinger()	:	CIndicatorBase()	{};
	CIndicatorBollinger(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice);
	~CIndicatorBollinger();

	void			Init(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice);
	
	#ifdef __MQL4__
		double	GetValue(int bufferNumber, int index);
	#endif
	
};

CIndicatorBollinger::CIndicatorBollinger(string symbol, int timeframe, int bandsPeriod, int bandsShift, double deviation, int appliedPrice)
		: CIndicatorBase() {
		
	Init(symbol, timeframe, bandsPeriod, bandsShift, deviation, appliedPrice);
	
}

void		CIndicatorBollinger::Init(string symbol,int timeframe,int bandsPeriod,int bandsShift,double deviation,int appliedPrice) {

	//	Only needed for mql4 but no harm for mql5
	mSymbol			=	symbol;
	mTimeframe		=	timeframe;
	mbandsPeriod		=	bandsPeriod;
	mbandsShift		=	bandsShift;
	mdeviation	=	deviation;
	mAppliedPrice	=	appliedPrice;
	
	#ifdef __MQL5__
		mHandle	=	iBands(symbol, (ENUM_TIMEFRAMES)timeframe, bandsPeriod, bandsShift, deviation, appliedPrice);
	#endif
	
	//	Set initialised
	//	I'm not currently using this but I should
	mInitialised		=	true;

}

CIndicatorBollinger::~CIndicatorBollinger() {
}

#ifdef __MQL4__
	double	CIndicatorBollinger::GetValue(int bufferNumber, int index) {
		double	result	=	iBands(mSymbol, mTimeframe, mbandsPeriod, mbandsShift, mdeviation, mAppliedPrice, bufferNumber, index);
		return(result);
	}
#endif 

