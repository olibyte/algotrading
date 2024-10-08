//+------------------------------------------------------------------+
//|                                      BBOnKeltnerChannel_MCEA.mq5 |
//|        Copyright 2023, Roberto Jacobs (3rjfx) ~ Date: 2023-11-10 |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Roberto Jacobs (3rjfx) ~ Date: 2023-12-04"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "1.00"
#property strict
#property description "The Expert BBOnKeltnerChannel_MCEA is the Automated Trading Multi Currency Forex Expert Advisor for MetaTrader 5"
#property description "by using Bollinger Bands® On Keltner Channel indicator which trade Multiple Pairs in one Chart."
#property description "version: 1.00 ~ Update number: 1 ~ Last update: 2023/12/05 @00:40 (AM) WIT (Western Indonesian Time)"
//#property icon "\\Images\\BBOnKeltnerChannel_MCEA.ico";
//+------------------------------------------------------------------+
//|                             Include                              |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
//--
CTrade              mc_trade;
CSymbolInfo         mc_symbol;
CPositionInfo       mc_position; 
CAccountInfo        mc_account;
//---
//--
enum tm_zone
 {
   Cus_Session,        // Trading on Custom Session
   New_Zealand,        // Trading on New Zealand Session
   Australia,          // Trading on Autralia Sydney Session
   Asia_Tokyo,         // Trading on Asia Tokyo Session
   Europe_London,      // Trading on Europe London Session
   US_New_York         // Trading on US New York Session
 };
//--
enum swhour
  {
    hr_00=0,   // 00:00
    hr_01=1,   // 01:00
    hr_02=2,   // 02:00
    hr_03=3,   // 03:00
    hr_04=4,   // 04:00
    hr_05=5,   // 05:00
    hr_06=6,   // 06:00
    hr_07=7,   // 07:00
    hr_08=8,   // 08:00
    hr_09=9,   // 09:00
    hr_10=10,  // 10:00
    hr_11=11,  // 11:00
    hr_12=12,  // 12:00
    hr_13=13,  // 13:00
    hr_14=14,  // 14:00
    hr_15=15,  // 15:00
    hr_16=16,  // 16:00
    hr_17=17,  // 17:00
    hr_18=18,  // 18:00
    hr_19=19,  // 19:00
    hr_20=20,  // 20:00
    hr_21=21,  // 21:00
    hr_22=22,  // 22:00
    hr_23=23   // 23:00
  };
//--
enum inmnt
  {
    mn_00=0,   // Minute 0
    mn_05=5,   // Minute 5
    mn_10=10,  // Minute 10
    mn_15=15,  // Minute 15
    mn_20=20,  // Minute 20
    mn_25=25,  // Minute 25
    mn_30=30,  // Minute 30
    mn_35=35,  // Minute 35
    mn_40=40,  // Minute 40
    mn_45=45,  // Minute 45
    mn_50=50,  // Minute 50
    mn_55=55   // Minute 55
  };
//--
enum PairsTrade
 {
   All30,  // All Forex 30 Pairs
   TrdWi,  // Trader Wishes Pairs 
   Usds,   // Forex USD Pairs
   Eurs,   // Forex EUR Pairs
   Gbps,   // Forex GBP Pairs
   Auds,   // Forex AUD Pairs
   Nzds,   // Forex NZD Pairs
   Cads,   // Forex CDD Pairs
   Chfs,   // Forex CHF Pairs
   Jpys    // Forex JPY Pairs
 };   
//--
enum YN
  {
   No,
   Yes
  };
//--
enum mmt
  {
   FixedLot,   // Fixed Lot Size
   DynamLot    // Dynamic Lot Size
  };
//--
enum TFUSE
  {
   TFM5,     // PERIOD_M5
   TFM15,    // PERIOD_M15
   TFM30,    // PERIOD_M30
   TFH1,     // PERIOD_H1
   TFH2,     // PERIOD_H2
   TFH3,     // PERIOD_H3
   TFH4,     // PERIOD_H4
   TFH6,     // PERIOD_H6
   TFH8,     // PERIOD_H8
   TFH12,    // PERIOD_H12
   TFD1      // PERIOD_D1
  };
//--
//---
input group               "=== Global Strategy EA Parameter ==="; // Global Strategy EA Parameter
input TFUSE               tfinuse = TFH1;             // Select Expert TimeFrame, default PERIOD_H1
input int                KCPeriod = 20;               // Input Keltner Channel Period, default 20
input ENUM_MA_METHOD     KCMethod = MODE_EMA;         // Select Keltner Channel MA Method, default EMA
input ENUM_APPLIED_PRICE   KCMAAP = PRICE_TYPICAL;    // Select Keltner Channel MA Applied Price, default Price Typical
input int                KCATRPer = 20;               // Input Keltner Channel ATR Period, default 20
input double      KCATRBandsMulti = 1.0;              // Input Keltner Channel ATR bands multiplier
input int                BBPeriod = 38;               // Input Bollinger Bands® Indicator period, default 38
input double               BBDevi = 1.0;              // Input Bollinger Bands® Indicator Deviations, default 1.00
//---
input group               "=== Select Pairs to Trade ===";  // Selected Pairs to trading
input PairsTrade         usepairs = All30;           // Select Pairs to Use
input string         traderwishes = "eg. eurusd,usdchf"; // If Use Trader Wishes Pairs, input pair name here, separate by comma
input string           sym_prefix = "";              // Input the symbol prefix in case sensitive (if any)
input string           sym_suffix = "";              // Input the symbol suffix in case sensitive (if any)
//--
input group               "=== Money Management Lot Size Parameter ==="; // Money Management Lot Size Parameter
input mmt                  mmlot = DynamLot;         // Money Management Type
input double                Risk = 10.0;             // Percent Equity Risk per Trade (Min=1.0% / Max=10.0%)
input double                Lots = 0.01;             // Input Manual Lot Size FixedLot
//--Trade on Specific Time
input group               "=== Trade on Specific Time ==="; // Trade on Specific Time
input YN           trd_time_zone = Yes;              // Select If You Like to Trade on Specific Time Zone
input tm_zone            session = Cus_Session;      // Select Trading Time Zone
input swhour            stsescuh = hr_00;            // Time Hour to Start Trading Custom Session (0-23)
input inmnt             stsescum = mn_15;            // Time Minute to Start Trading Custom Session (0-55)
input swhour            clsescuh = hr_23;            // Time Hour to Stop Trading Custom Session (0-23)
input inmnt             clsescum = mn_55;            // Time Minute to Stop Trading Custom Session (0-55)
//--Day Trading On/Off
input group               "=== Day Trading On/Off ==="; // Day Trading On/Off
input YN                    ttd0 = No;               // Select Trading on Sunday (Yes) or (No)
input YN                    ttd1 = Yes;              // Select Trading on Monday (Yes) or (No)
input YN                    ttd2 = Yes;              // Select Trading on Tuesday (Yes) or (No)
input YN                    ttd3 = Yes;              // Select Trading on Wednesday (Yes) or (No)
input YN                    ttd4 = Yes;              // Select Trading on Thursday (Yes) or (No)
input YN                    ttd5 = Yes;              // Select Trading on Friday (Yes) or (No)
input YN                    ttd6 = No;               // Select Trading on Saturday (Yes) or (No)
//--Trade & Order management Parameter
input group               "=== Trade & Order management Parameter ==="; // Trade & Order management Parameter
input YN                  use_sl = No;               // Use Order Stop Loss (Yes) or (No)
input YN                  autosl = Yes;              // Use Automatic Calculation Stop Loss (Yes) or (No)
input double               SLval = 30;               // If Not Use Automatic SL - Input SL value in Pips
input YN                  use_tp = Yes;              // Use Order Take Profit (Yes) or (No)
input YN                  autotp = Yes;              // Use Automatic Calculation Take Profit (Yes) or (No)
input double               TPval = 100;              // If Not Use Automatic TP - Input TP value in Pips
input YN            TrailingSLTP = Yes;              // Use Trailing SL/TP (Yes) or (No)
input YN                 autotrl = Yes;              // Use Automatic Trailing (Yes) or (No)
input double               TSval = 5;                // If Not Use Automatic Trailing Input Trailing value in Pips
input double               TSmin = 5;                // Minimum Pips to start Trailing Stop
input double               TPmin = 25;               // Input Trailing Profit Value in Pips
input YN           Close_by_Opps = Yes;              // Close Trade By Opposite Signal (Yes) or (No)
input YN               SaveOnRev = Yes;              // Close Trade and Save profit due to weak signal (Yes) or (No)
//--Others Expert Advisor Parameter
input group               "=== Others Expert Advisor Parameter ==="; // Others EA Parameter
input YN                  alerts = Yes;              // Display Alerts / Messages (Yes) or (No)
input YN           UseEmailAlert = No;               // Email Alert (Yes) or (No)
input YN           UseSendnotify = No;               // Send Notification (Yes) or (No)
input YN      trade_info_display = Yes;              // Select Display Trading Info on Chart (Yes) or (No)
input ulong              magicEA = 20231204;        // Expert ID (Magic Number)
//---
//---------//
//+------------------------------------------------------------------+
//| Class for working Expert Advisor                                 |
//+------------------------------------------------------------------+
class MCEA
  {
//---
    private:
    //---- 
    int              x_year;       // Year 
    int              x_mon;        // Month 
    int              x_day;        // Day of the month 
    int              x_hour;       // Hour in a day 
    int              x_min;        // Minutes 
    int              x_sec;        // Seconds
    //--
    int              oBm,
                     oSm,
                     ldig;
    //--- Variables used in prefix and suffix symbols
    int              posCur1,
                     posCur2;
    int              inpre,
                     insuf;
    bool             symbfix;
    string           pre,suf;
    string           prefix,suffix;       
    //--- Variables are used in Trading Time Zone
    int              ishour,
                     onhour;
    int              tftrlst,
                     tfcinws;
    datetime         rem,
                     znop,
                     zncl,
                     zntm;
    datetime         SesCuOp,
                     SesCuCl,
                     Ses01Op,
                     Ses01Cl,
                     Ses02Op,
                     Ses02Cl,
                     Ses03Op,
                     Ses03Cl,
                     Ses04Op,
                     Ses04Cl,
                     Ses05Op,
                     Ses05Cl,
                     SesNoOp,
                     SesNoCl;
    //--
    string           tz_ses,
                     tz_opn,
                     tz_cls;
    //--
    string           tmopcu,
                     tmclcu,
                     tmop01,
                     tmcl01,
                     tmop02,
                     tmcl02,
                     tmop03,
                     tmcl03,
                     tmop04,
                     tmcl04,
                     tmop05,
                     tmcl05,
                     tmopno,
                     tmclno;      
    //----------------------    
    //--
    double           LotPS;
    double           slv,
                     tpv,
                     pip,
                     xpip;
   double            SARstep,
                     SARmaxi;
    double           floatprofit,
                     fixclprofit;
    //--
    string           pairs,
                     hariini,
                     daytrade,
                     trade_mode;
    //--
    double           OPEN[],
                     HIGH[],
                     LOW[],
                     CLOSE[];
    datetime         TIME[];
    datetime         closetime;
    //--
    //------------
     
    //------------
    void             SetSymbolNamePS(void);
    void             HandlingSymbolArrays(void);
    void             Set_Time_Zone(void);
    void             Time_Zone(void);
    bool             Trade_session(void);
    string           PosTimeZone(void);
    int              ThisTime(const int reqmode);
    int              ReqTime(datetime reqtime,const int reqmode);
    //--
    int              DirectionMove(const string symbol,const ENUM_TIMEFRAMES stf);
    int              BBOnKeltnerChannel(const string symbol);
    int              PARSAR05(const string symbol);
    int              LotDig(const string symbol);
    //--
    double           MLots(const string symbx);
    double           NonZeroDiv(double val1,double val2);
    double           OrderSLSet(const string xsymb,ENUM_ORDER_TYPE type,double atprice);
    double           OrderTPSet(const string xsymb,ENUM_ORDER_TYPE type,double atprice);
    double           SetOrderSL(const string xsymb,ENUM_POSITION_TYPE type,double atprice);
    double           SetOrderTP(const string xsymb,ENUM_POSITION_TYPE type,double atprice);
    double           TSPrice(const string xsymb,ENUM_POSITION_TYPE ptype,int TS_type);
    //--
    string           ReqDate(int d,int h,int m);
    string           TF2Str(ENUM_TIMEFRAMES period);
    string           timehr(int hr,int mn);
    string           TradingDay(void);
    string           AccountMode();
    string           GetCommentForOrder(void)             { return(expname); }
    //------------

    public:
    //---
    
    //-- BBOnKeltnerChannel_MCEA Config --
    string           DIRI[],
                     AS30[],
                     VSym[];
    string           SPC[];
    string           USD[];
    string           EUR[];
    string           GBP[];
    string           AUD[];
    string           NZD[];
    string           CAD[];
    string           CHF[];
    string           JPY[];             
    //--                 
    string           expname;
    string           indiname;
    //--
    int              hKC[];
    int              hBB[];
    int              hParIU[],
                     hPar05[];
    int              ALO,
                     dgts,
                     arrsar,
                     arrsymbx;
    int              sall,
                     arusd,
                     aretc,
                     arspc,
                     arper;
    ulong            slip;        
    //--
    double           profitb[],
                     profits[];
    //--
    int              Buy,
                     Sell;
    int              ccur,
                     psec,
                     xtto,
                     checktml;
    int              OpOr[],xob[],xos[];         
    //--
    int              year,  // Year 
                     mon,   // Month 
                     day,   // Day 
                     hour,  // Hour 
                     min,   // Minutes 
                     sec,   // Seconds 
                     dow,   // Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
                     doy;   // Day number of the year (January 1st is assigned the number value of zero)
    //--
    ENUM_TIMEFRAMES  TFt,
                     TFT05;
    //--
    bool             PanelExtra;
    //------------
                     MCEA(void);
                     ~MCEA(void);            
    //------------
    //--
    virtual void     BBOnKeltnerChannel_MCEA_Config(void);
    virtual void     ExpertActionTrade(void);
    //--
    void             ArraySymbolResize(void);
    void             CurrentSymbolSet(const string symbol);
    void             Pips(const string symbol);
    void             TradeInfo(void);
    void             Do_Alerts(const string symbx,string msgText);
    void             CheckOpenPMx(const string symbx);
    void             SetSLTPOrders(void);
    void             CloseBuyPositions(const string symbol);
    void             CloseSellPositions(const string symbol);
    void             CloseAllOrders(void);
    void             CheckClose(const string symbx);
    void             TodayOrders(void);
    void             UpdatePrice(const string symbol,ENUM_TIMEFRAMES xtf);
    void             RefreshPrice(const string symbx,ENUM_TIMEFRAMES xtf,int bars);
    //--
    bool             RefreshTick(const string symbx);  
    bool             TradingToday(void);
    bool             OpenBuy(const string symbol);
    bool             OpenSell(const string symbol);
    bool             ModifyOrderSLTP(double mStop,double ordtp);
    bool             ModifySLTP(const string symbx,int TS_type);          
    bool             CloseAllProfit(void);
    bool             ManualCloseAllProfit(void);
    //--
    int              PairsIdxArray(const string symbol);
    int              ValidatePairs(const string symbol);
    int              GetOpenPosition(const string symbol);
    int              GetCloseInWeakSignal(const string symbol,int exis);
    //--
    string           getUninitReasonText(int reasonCode);
    //--
    //------------
//---
  }; //-end class MCEA
//---------//
 
MCEA mc;

//---------//

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MCEA::MCEA(void): x_year(0),
                  x_mon(0),
                  x_day(0),
                  x_hour(0),
                  x_min(0),
                  x_sec(0),
                  year(0),
                  mon(1),
                  day(2),
                  hour(3),
                  min(4),
                  sec(5),
                  dow(6),
                  doy(7),
                  psec(0),
                  Buy(1),
                  Sell(-1),
                  slip(16),
                  arper(25),
                  checktml(0),
                  SARmaxi(0.2),
                  SARstep(0.02),
                  prefix(sym_prefix),
                  suffix(sym_suffix),
                  expname("BBOnKeltnerChannel_MCEA"),
                  indiname("Keltner Channel.ex5"),
                  closetime(TimeCurrent())
  {
  }
//---------//

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MCEA::~MCEA(void)
  {
  }
//---------//

//+------------------------------------------------------------------+
//| Expert Configuration                                             |
//+------------------------------------------------------------------+
void MCEA::BBOnKeltnerChannel_MCEA_Config(void) 
  {
//---
    //--
    HandlingSymbolArrays(); // With this function we will handle all pairs that will be traded
    //--
    TFT05=PERIOD_M5;
    ENUM_TIMEFRAMES TFs[]={PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1};
    int arTFs=ArraySize(TFs);
    //--
    for(int x=0; x<arTFs; x++) if(tfinuse==x) TFt=TFs[x]; // TF for calculation signal
    //--
    //-- Keltner Channel and Bollinger Bands® Indicators handle for all symbol
    for(int x=0; x<arrsymbx; x++) 
      {
        hKC[x]=iCustom(DIRI[x],TFt,indiname,KCPeriod,KCMethod,KCMAAP,KCATRPer,KCATRBandsMulti); //-- Handle for the Keltner Channel indicator
        hParIU[x]=iSAR(DIRI[x],TFt,SARstep,SARmaxi);         //-- Handle for the iSAR indicator according to the selected Timeframe
        hPar05[x]=iSAR(DIRI[x],TFT05,SARstep,SARmaxi);       //-- Handle for the iSAR indicator for M5 Timeframe
        //--
      }
    //--
    for(int x=0; x<arrsymbx; x++) 
      hBB[x]=iBands(DIRI[x],TFt,BBPeriod,0,BBDevi,hKC[x]); //-- Handle for the iBands On Keltner Channel Indicator handle
    //--
    ALO=(int)mc_account.LimitOrders()>sall ? sall : (int)mc_account.LimitOrders();
    //--
    LotPS=(double)ALO;
    //--
    mc_trade.SetExpertMagicNumber(magicEA);
    mc_trade.SetDeviationInPoints(slip);
    mc_trade.SetMarginMode();
    Set_Time_Zone();
    //--
    return;
//---
  } //-end BBOnKeltnerChannel_MCEA_Config()
//---------//

void MCEA::HandlingSymbolArrays(void)
  {
//---
    string All30[]={"EURUSD","GBPUSD","AUDUSD","NZDUSD","USDCAD","USDCHF","USDJPY","EURGBP",
                    "EURAUD","EURNZD","EURCAD","EURCHF","EURJPY","GBPAUD","GBPNZD","GBPCAD",
                    "GBPCHF","GBPJPY","AUDNZD","AUDCAD","AUDCHF","AUDJPY","NZDCAD","NZDCHF",
                    "NZDJPY","CADCHF","CADJPY","CHFJPY","XAUUSD","XAGUSD"}; // 30 pairs
    string USDs[]={"USDCAD","USDCHF","USDJPY","AUDUSD","EURUSD","GBPUSD","NZDUSD","XAUUSD","XAGUSD"}; // USD pairs
    string EURs[]={"EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD"}; // EUR pairs
    string GBPs[]={"GBPAUD","GBPCAD","GBPCHF","EURGBP","GBPJPY","GBPNZD","GBPUSD"}; // GBP pairs
    string AUDs[]={"AUDCAD","AUDCHF","EURAUD","GBPAUD","AUDJPY","AUDNZD","AUDUSD"}; // AUD pairs
    string NZDs[]={"AUDNZD","NZDCAD","NZDCHF","EURNZD","GBPNZD","NZDJPY","NZDUSD"}; // NZD pairs
    string CADs[]={"AUDCAD","CADCHF","EURCAD","GBPCAD","CADJPY","NZDCAD","USDCAD"}; // CAD pairs
    string CHFs[]={"AUDCHF","CADCHF","EURCHF","GBPCHF","NZDCHF","CHFJPY","USDCHF"}; // CHF pairs
    string JPYs[]={"AUDJPY","CADJPY","CHFJPY","EURJPY","GBPJPY","NZDJPY","USDJPY"}; // JPY pairs
    //--
    sall=ArraySize(All30);
    arusd=ArraySize(USDs);
    aretc=ArraySize(EURs);
    ArrayResize(VSym,sall,sall);
    ArrayCopy(VSym,All30,0,0,WHOLE_ARRAY);
    //--
    if(usepairs==TrdWi && StringFind(traderwishes,"eg.",0)<0)
      {
        string to_split=traderwishes; // A string to split into substrings pairs name
        string sep=",";               // A separator as a character 
        ushort u_sep;                 // The code of the separator character 
        //--- Get the separator code 
        u_sep=StringGetCharacter(sep,0);
        //--- Split the string to substrings 
        int p=StringSplit(to_split,u_sep,SPC); 
        if(p>0)
          {
            for(int i=0; i<p; i++) StringToUpper(SPC[i]);
            //--
            for(int i=0; i<p; i++)
              {
                if(ValidatePairs(SPC[i])<0) ArrayRemove(SPC,i,1);
              }
          }
        arspc=ArraySize(SPC);
      }
    //--
    SetSymbolNamePS();      // With this function we will detect whether the Symbol Name has a prefix and/or suffix
    //--
    if(inpre>0 || insuf>0)
      {
        if(usepairs==TrdWi && arspc>0)
          {
            for(int t=0; t<arspc; t++)
              {
                SPC[t]=pre+SPC[t]+suf;
              }
          }
        //--
        for(int t=0; t<sall; t++)
          {
            All30[t]=pre+All30[t]+suf;
          }
        for(int t=0; t<arusd; t++)
          {
            USDs[t]=pre+USDs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            EURs[t]=pre+EURs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            GBPs[t]=pre+GBPs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            AUDs[t]=pre+AUDs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            NZDs[t]=pre+NZDs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            CADs[t]=pre+CADs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            CHFs[t]=pre+CHFs[t]+suf;
          }
        for(int t=0; t<aretc; t++)
          {
            JPYs[t]=pre+JPYs[t]+suf;
          }
      }
    //--
    ArrayCopy(VSym,All30,0,0,WHOLE_ARRAY);
    ArrayResize(AS30,sall,sall);
    ArrayCopy(AS30,All30,0,0,WHOLE_ARRAY);
    for(int x=0; x<sall; x++) {SymbolSelect(AS30[x],true);}
    if(ValidatePairs(Symbol())>=0) symbfix=true;
    if(!symbfix) 
      {
        Alert("Expert Advisors will not trade on pairs "+Symbol());
        Alert("-- "+expname+" -- ",Symbol()," -- expert advisor will be Remove from the chart.");
        ExpertRemove();
      }
    //--
    switch(usepairs)
      {
        case 0: // All Forex 30 Pairs
          {
            ArrayResize(DIRI,sall,sall);
            arrsymbx=sall;
            ArraySymbolResize();
            ArrayCopy(DIRI,All30,0,0,WHOLE_ARRAY);
            pairs="Multi Currency 30 Pairs";
            //--
            break;
          }
        case 1: // Trader wishes pairs
          {
            ArrayResize(DIRI,arspc,arspc);
            arrsymbx=arspc;
            ArraySymbolResize();
            ArrayCopy(DIRI,SPC,0,0,WHOLE_ARRAY);
            pairs="("+string(arspc)+") Trader Wishes Pairs";
            //--
            break;
          }
        case 2: // USD pairs
          {
            ArrayResize(DIRI,arusd,arusd);
            arrsymbx=arusd;
            ArraySymbolResize();
            ArrayCopy(DIRI,USDs,0,0,WHOLE_ARRAY);
            pairs="("+string(arusd)+") Multi Currency USD Pairs";
            //--
            break;
          }
        case 3: // EUR pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,EURs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex EUR Pairs";
            //--
            break;
          }
        case 4: // GBP pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,GBPs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex GBP Pairs";
            //--
            break;
          }
        case 5: // AUD pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,AUDs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex AUD Pairs";
            //--
            break;
          }
        case 6: // NZD pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,NZDs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex NZD Pairs";
            //--
            break;
          }
        case 7: // CAD pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,CADs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex CAD Pairs";
            //--
            break;
          }
        case 8: // CHF pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,CHFs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex CHF Pairs";
            //--
            break;
          }
        case 9: // JPY pairs
          {
            ArrayResize(DIRI,aretc,aretc);
            arrsymbx=aretc;
            ArraySymbolResize();
            ArrayCopy(DIRI,JPYs,0,0,WHOLE_ARRAY);
            pairs="("+string(aretc)+") Forex JPY Pairs";
            //--
            break;
          }
      }
    //--
    return;
//---
  } //-end HandlingSymbolArrays()
//---------//

void MCEA::SetSymbolNamePS(void)
  {
//---
   symbfix=false;
   int ptriml;
   int ptrimr;
   string insymbol=Symbol();
   int sym_Lenpre=StringLen(prefix);
   int sym_Lensuf=StringLen(suffix);
   if(sym_Lenpre>0)
     {
       ptriml=StringTrimLeft(suffix);
       ptriml=StringTrimRight(suffix);
     }
   if(sym_Lensuf>0)
     {
       ptrimr=StringTrimLeft(suffix);
       ptrimr=StringTrimRight(suffix);
     }
   string sym_pre=prefix;
   string sym_suf=suffix;
   //--
   pre=sym_pre;
   suf=sym_suf;
   inpre=StringLen(pre);
   insuf=StringLen(suf);
   posCur1=inpre;
   posCur2=posCur1+3;
   //--
   return;
//---
  } //-end SetSymbolNamePS()
//---------//

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---
   mc.BBOnKeltnerChannel_MCEA_Config();
   //--
   return(INIT_SUCCEEDED);
//---
  } //-end OnInit()
//---------//
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment("");
   //-- Release all handle indicators for all symbols
   for(int x=0; x<mc.arrsymbx; x++) 
     {
       IndicatorRelease(mc.hKC[x]);
       IndicatorRelease(mc.hBB[x]);
       IndicatorRelease(mc.hPar05[x]);
       IndicatorRelease(mc.hParIU[x]);
     }
   //--
   PrintFormat("%s: Deinitialization reason code=%d",__FUNCTION__,reason);
   Print(mc.getUninitReasonText(reason));
   ObjectsDeleteAll(0,0,OBJ_BUTTON);
   ObjectsDeleteAll(0,0,OBJ_LABEL);
   ObjectsDeleteAll(0,0,OBJ_RECTANGLE_LABEL);
   //--
   return;
//---
  } //-end OnDeinit()
//---------//
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//---
    mc.ExpertActionTrade();
    //--
    return;
//---
  } //-end OnTick()
//---------//
//+------------------------------------------------------------------+

void MCEA::ExpertActionTrade(void)
  {
//---
    //--Check Trading Terminal
    ResetLastError();
    //--
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED) && mc.checktml==0) //-- Check whether MT5 Algorithmic trading is Allow or Prohibit
      {
        mc.Do_Alerts(Symbol(),"Trading Expert at "+Symbol()+" are NOT Allowed by Setting.");
        mc.checktml=1;  //-- Variable checktml is given a value of 1, so that the alert is only done once.
        return;
      }
    //--
    if(!DisplayManualButton("M","C","R")) DisplayManualButton(); //-- Show the expert manual button panel
    //--
    if(trade_info_display==Yes) mc.TradeInfo(); //-- Displayed Trading Info on Chart
    //---
    //--
    int mcsec=mc.ThisTime(mc.sec); 
    //--
    if(fmod((double)mcsec,5.0)==0) mc.ccur=mcsec;
    //--
    if(mc.ccur!=mc.psec)
      {
        string symbol;
        //-- Here we start with the rotation of the name of all symbol or pairs to be traded
        for(int x=0; x<mc.arrsymbx && !IsStopped(); x++) 
          {
            //-- 
            if(mc.DIRI[x]==Symbol()) symbol=Symbol();
            else symbol=mc.DIRI[x];
            //--
            mc.CurrentSymbolSet(symbol);
            //--
            if(mc.TradingToday() && mc.Trade_session())
              {
                //--
                mc.OpOr[x]=mc.GetOpenPosition(symbol); //-- Get trading signals to open positions
                //--                                   //-- and store in the variable OpOr[x]
                if(mc.OpOr[x]==mc.Buy) //-- If variable OpOr[x] get result of GetOpenPosition(symbol) as "Buy" (value=1)
                  {
                    //--
                    mc.CheckOpenPMx(symbol);
                    //--
                    if(Close_by_Opps==Yes && mc.xos[x]>0) mc.CloseSellPositions(symbol);
                    //--
                    if(mc.xob[x]==0 && mc.xtto<mc.ALO) mc.OpenBuy(symbol);
                    else
                    if(mc.xtto>=mc.ALO)
                      {
                        //--
                        mc.Do_Alerts(symbol,"Maximum amount of open positions and active pending orders has reached"+
                                            "\n the limit = "+string(mc.ALO)+" Orders ");
                        //--
                        mc.CheckOpenPMx(symbol);
                        //--
                        if(mc.xos[x]>0 && mc.profits[x]<-1.02 && mc.xob[x]==0) {mc.CloseSellPositions(symbol); mc.OpenBuy(symbol);}
                        else
                        if(SaveOnRev==Yes) mc.CloseAllProfit();
                      }
                  }
                if(mc.OpOr[x]==mc.Sell) //-- If variable OpOr[x] get result of GetOpenPosition(symbol) as "Sell" (value=-1)
                  {
                    //--
                    mc.CheckOpenPMx(symbol);
                    //--
                    if(Close_by_Opps==Yes && mc.xob[x]>0) mc.CloseBuyPositions(symbol);
                    //--
                    if(mc.xos[x]==0 && mc.xtto<mc.ALO) mc.OpenSell(symbol);
                    else
                    if(mc.xtto>=mc.ALO)
                      {
                        //--
                        mc.Do_Alerts(symbol,"Maximum amount of open positions and active pending orders has reached"+
                                            "\n the limit = "+string(mc.ALO)+" Orders ");
                        //--
                        mc.CheckOpenPMx(symbol);
                        //--
                        if(mc.xob[x]>0 && mc.profitb[x]<-1.02 && mc.xos[x]==0) {mc.CloseBuyPositions(symbol); mc.OpenSell(symbol);}
                        else
                        if(SaveOnRev==Yes) mc.CloseAllProfit();
                      }
                  }
              }
            //--
            mc.CheckOpenPMx(symbol);
            //--
            if(mc.xtto>0)
              {
                //--
                if(SaveOnRev==Yes) //-- Close Trade and Save profit due to weak signal (Yes)
                  {
                    mc.CheckOpenPMx(symbol);
                    if(mc.profitb[x]>0.02 && mc.xob[x]>0 && mc.GetCloseInWeakSignal(symbol,mc.Buy)==mc.Sell) 
                      {
                        mc.CloseBuyPositions(symbol); 
                        mc.Do_Alerts(symbol,"Close BUY order "+symbol+" to save profit due to weak signal.");
                      }
                    if(mc.profits[x]>0.02 && mc.xos[x]>0 && mc.GetCloseInWeakSignal(symbol,mc.Sell)==mc.Buy)
                      {
                        mc.CloseSellPositions(symbol); 
                        mc.Do_Alerts(symbol,"Close SELL order "+symbol+" to save profit due to weak signal.");
                      }
                  }
                //--
                if(TrailingSLTP==Yes) //-- Use Trailing SL/TP (Yes)
                  {
                    if(autotrl==Yes) mc.ModifySLTP(symbol,1); //-- If Use Automatic Trailing (Yes)
                    if(autotrl==No)  mc.ModifySLTP(symbol,0); //-- Use Automatic Trailing (No)
                  }
              }
            //--
            mc.CheckClose(symbol);
          }
        //--
        mc.psec=mc.ccur;
      }
    //--
    return;
//---
  } //-end ExpertActionTrade()
//---------//

int MCEA::PairsIdxArray(const string symbol)
  {
//---
    int pidx=-1;
    //--
    for(int x=0; x<arrsymbx; x++)
      {
        if(DIRI[x]==symbol)
          {
            pidx=x;
            break;
          }
      } 
    //--
    return(pidx);
//---
  } //-end PairsIdxArray()
//---------//

int MCEA::ValidatePairs(const string symbol)
  {
//---
    int pidx=-1;
    //--
    for(int x=0; x<sall; x++)
      {
        if(VSym[x]==symbol)
          {
            pidx=x;
            break;
          }
      } 
    //--
    return(pidx);
//---
  } //-end ValidatePairs()
//---------//

void MCEA::ArraySymbolResize(void)
  {
//---
    ArrayFree(DIRI);
    ArrayFree(xob);
    ArrayFree(xos);
    ArrayFree(OpOr);
    ArrayFree(profitb);
    ArrayFree(profits);
    ArrayFree(hKC);
    ArrayFree(hBB);
    ArrayFree(hPar05);
    ArrayFree(hParIU);
    //--
    ArrayResize(DIRI,arrsymbx,arrsymbx);
    ArrayResize(xob,arrsymbx,arrsymbx);
    ArrayResize(xos,arrsymbx,arrsymbx);
    ArrayResize(OpOr,arrsymbx,arrsymbx);
    ArrayResize(profitb,arrsymbx,arrsymbx);
    ArrayResize(profits,arrsymbx,arrsymbx);
    ArrayResize(hKC,arrsymbx,arrsymbx);
    ArrayResize(hBB,arrsymbx,arrsymbx);
    ArrayResize(hPar05,arrsymbx,arrsymbx);
    ArrayResize(hParIU,arrsymbx,arrsymbx);
    //--
    return;
//---
  } //-end ArraySymbolResize()
//---------//

void MCEA::UpdatePrice(const string symbol,ENUM_TIMEFRAMES xtf)
  {
//---
    //--
    ArrayFree(OPEN);
    ArrayFree(HIGH);
    ArrayFree(LOW);
    ArrayFree(CLOSE);
    ArrayFree(TIME);
    //--
    ArrayResize(OPEN,arper,arper);
    ArrayResize(HIGH,arper,arper);
    ArrayResize(LOW,arper,arper);
    ArrayResize(CLOSE,arper,arper);
    ArrayResize(TIME,arper,arper);
    //--
    ArraySetAsSeries(OPEN,true);
    ArraySetAsSeries(HIGH,true);
    ArraySetAsSeries(LOW,true);
    ArraySetAsSeries(CLOSE,true);
    ArraySetAsSeries(TIME,true);
    //--
    ArrayInitialize(OPEN,0.0);
    ArrayInitialize(HIGH,0.0);
    ArrayInitialize(LOW,0.0);
    ArrayInitialize(CLOSE,0.0);
    ArrayInitialize(TIME,0);    
    //--
    RefreshPrice(symbol,xtf,arper);
    //--
    int co=CopyOpen(symbol,xtf,0,arper,OPEN);
    int ch=CopyHigh(symbol,xtf,0,arper,HIGH);
    int cl=CopyLow(symbol,xtf,0,arper,LOW);
    int cc=CopyClose(symbol,xtf,0,arper,CLOSE);
    int ct=CopyTime(symbol,xtf,0,arper,TIME);
   //--
   return;
//---
  } //-end UpdatePrice()
//---------//

void MCEA::RefreshPrice(const string symbx,ENUM_TIMEFRAMES xtf,int bars)
  {
//---
    MqlRates parray[]; 
    ArraySetAsSeries(parray,true); 
    int copied=CopyRates(symbx,xtf,0,bars,parray);
    //--
    return;
//---
  } //-end RefreshPrice()
//---------//

bool MCEA::RefreshTick(const string symbx)
  {
//---
    mc_symbol.Name(symbx); 
    if(mc_symbol.RefreshRates()) return(true);
    //--
    return(false);
//---
  } //-end RefreshTick()
//---------//

void MCEA::CurrentSymbolSet(const string symbol)
  {
//---
   mc_symbol.Name(symbol);
   mc_symbol.CheckMarketWatch();
   mc_symbol.IsSynchronized();
   mc_trade.SetTypeFillingBySymbol(symbol);
   mc_symbol.Refresh();
   mc_symbol.RefreshRates();
   //--
   return;
//---
  } //-end CurrentSymbolSet()
//---------//

void MCEA::Pips(const string symbol)
  {
//---
   CurrentSymbolSet(symbol);
   //--
   double point=mc_symbol.Point();
   dgts=(int)mc_symbol.Digits();
   //--
   xpip=10.0; 
   pip=point*xpip;
   //--
   return;
//---
  } //-end Pips()
//---------//

int MCEA::DirectionMove(const string symbol,const ENUM_TIMEFRAMES stf) // Bar Price Direction 
  {
//---
    int ret=0;
    int rise=1,
        down=-1;
    Pips(symbol);
    double difud=mc_symbol.NormalizePrice(1.5*pip);
    UpdatePrice(symbol,stf);
    //--
    if(CLOSE[0]>OPEN[0]+difud) ret=rise;
    if(CLOSE[0]<OPEN[0]-difud) ret=down;
    //--
    return(ret);
//---
  } //-end DirectionMove()
//---------//

int MCEA::BBOnKeltnerChannel(const string symbol) // Fungction of Bollinger Bands® On Keltner Channel Indicator
  {
//---
    int ret=0;
    int rise=1,
        down=-1;
    int br=3;
    Pips(symbol);
    double difud=mc_symbol.NormalizePrice(1.5*pip);
    //--
    double KCmb[], // Destination array for Keltner Channel Middle Line buffer
           KCub[], // Destination array for Keltner Channel Upper Band buffer
           KClb[]; // Destination array for Keltner Channel Lower Band buffer
    double BBmb[], // Destination array for Bollinger Bands® BASE_LINE buffer
           BBub[], // Destination array for Bollinger Bands® UPPER_BAND buffer
           BBlb[]; // Destination array for Bollinger Bands® LOWER_BAND buffer
    //--
    ArrayResize(KCmb,br,br);
    ArrayResize(KCub,br,br);
    ArrayResize(KClb,br,br);
    ArrayResize(BBmb,br,br);
    ArrayResize(BBub,br,br);
    ArrayResize(BBlb,br,br);
    ArraySetAsSeries(KCmb,true);
    ArraySetAsSeries(KCub,true);
    ArraySetAsSeries(KClb,true);
    ArraySetAsSeries(BBmb,true);
    ArraySetAsSeries(BBub,true);
    ArraySetAsSeries(BBlb,true);
    //--
    int xx=PairsIdxArray(symbol);
    //--
    CopyBuffer(hKC[xx],0,0,br,KCmb);
    CopyBuffer(hKC[xx],1,0,br,KCub);
    CopyBuffer(hKC[xx],2,0,br,KClb);
    CopyBuffer(hBB[xx],0,0,br,BBmb);
    CopyBuffer(hBB[xx],1,0,br,BBub);
    CopyBuffer(hBB[xx],2,0,br,BBlb);
    //--
    bool BBKCrise1=(KCmb[1]<=BBlb[1] && KCmb[0]>BBlb[0]+difud);
    bool BBKCrise2=(KCmb[1]<=BBmb[1] && KCmb[0]>BBmb[0]+difud);
    bool BBKCrise3=(KCmb[1]<=BBub[1] && KCmb[0]>BBub[0]+difud);
    //--
    bool BBKCdown1=(KCmb[1]>=BBub[1] && KCmb[0]<BBub[0]-difud);
    bool BBKCdown2=(KCmb[1]>=BBmb[1] && KCmb[0]<BBmb[0]-difud);
    bool BBKCdown3=(KCmb[1]>=BBlb[1] && KCmb[0]<BBlb[0]-difud);
    //--
    if(BBKCrise1 || BBKCrise2 || BBKCrise3) ret=rise;
    if(BBKCdown1 || BBKCdown2 || BBKCdown3) ret=down;
    //--
    return(ret);
//---
  } //-end BBOnKeltnerChannel()
//---------//

int MCEA::GetOpenPosition(const string symbol) // Signal Open Position 
  {
//---
    int ret=0;
    int rise=1,
        down=-1;
    //--
    int BBOnKC=BBOnKeltnerChannel(symbol);
    //--
    if(BBOnKC==rise) ret=rise;
    if(BBOnKC==down) ret=down;
    //--
    return(ret);
//---
  } //-end GetOpenPosition()
//---------//

int MCEA::GetCloseInWeakSignal(const string symbol,int exis) // Signal Indicator Position Close in profit
  {
//---
    int ret=0;
    int rise=1,
        down=-1;
    //--
    int br=3;
    Pips(symbol);
    double difud=mc_symbol.NormalizePrice(1.5*pip);
    //--
    double KCub[],
           KClb[];
    double BBub[],
           BBlb[];
    //--
    ArrayResize(KCub,br,br);
    ArrayResize(KClb,br,br);
    ArrayResize(BBub,br,br);
    ArrayResize(BBlb,br,br);
    ArraySetAsSeries(KCub,true);
    ArraySetAsSeries(KClb,true);
    ArraySetAsSeries(BBub,true);
    ArraySetAsSeries(BBlb,true);
    //--
    int xx=PairsIdxArray(symbol);
    //--
    CopyBuffer(hKC[xx],1,0,br,KCub);
    CopyBuffer(hKC[xx],2,0,br,KClb);
    CopyBuffer(hBB[xx],1,0,br,BBub);
    CopyBuffer(hBB[xx],2,0,br,BBlb);
    //--
    int dirmove=DirectionMove(symbol,TFt);
    bool closebuy=(KClb[1]>=BBub[1] && KClb[0]<BBub[0]-difud);
    bool closesel=(KCub[1]<=BBlb[1] && KCub[0]>BBlb[0]+difud);
    //--
    if(exis==down && closesel && dirmove==rise) ret=rise;
    if(exis==rise && closebuy && dirmove==down) ret=down;
    //--
    return(ret);
//---
  } //-end GetCloseInWeakSignal()
//---------//

int MCEA::PARSAR05(const string symbol) // formula Parabolic SAR M5
  {
//---
   int ret=0;
   int rise=1,
       down=-1;
   int br=2;
//--
   double PSAR[];
   ArrayResize(PSAR,br,br);
   ArraySetAsSeries(PSAR,true);
   int xx=PairsIdxArray(symbol);
   CopyBuffer(hPar05[xx],0,0,br,PSAR);
//--
   RefreshPrice(symbol,TFT05,br);
   double HIG0=iHigh(symbol,TFT05,0);
   double LOW0=iLow(symbol,TFT05,0);
//--
   if(PSAR[0]<LOW0)
      ret=rise;
   if(PSAR[0]>HIG0)
      ret=down;
//--
   return(ret);
//---
  } //-end PARSAR05()
//---------//

bool MCEA::OpenBuy(const string symbol) 
  {
//---
    ResetLastError();
    //--
    bool buyopen      = false;
    string ldComm     = GetCommentForOrder()+"_Buy";
    double ldLot      = MLots(symbol);
    ENUM_ORDER_TYPE type_req = ORDER_TYPE_BUY;
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //-- structure is set to zero
    ZeroMemory(req);
    ZeroMemory(res);
    ZeroMemory(check);
    //--
    CurrentSymbolSet(symbol);
    double SL=OrderSLSet(symbol,type_req,mc_symbol.Bid());
    double TP=OrderTPSet(symbol,type_req,mc_symbol.Ask());
    //--
    if(RefreshTick(symbol))
       buyopen=mc_trade.Buy(ldLot,symbol,mc_symbol.Ask(),SL,TP,ldComm);
    //--
    int error=GetLastError();
    if(buyopen||error==0)
      {
        string bsopen="Open BUY Order for "+symbol+" ~ Ticket= ["+(string)mc_trade.ResultOrder()+"] successfully..!";
        Do_Alerts(symbol,bsopen);
      }
    else
      {
        mc_trade.CheckResult(check);
        Do_Alerts(Symbol(),"Open BUY order for "+symbol+" FAILED!!. Return code= "+
                 (string)mc_trade.ResultRetcode()+". Code description: ["+mc_trade.ResultRetcodeDescription()+"]");
        return(false);   
      }
    //--
    return(buyopen);
    //--
//---
  } //-end OpenBuy
//---------//

bool MCEA::OpenSell(const string symbol) 
  {
//---
    ResetLastError();
    //--
    bool selopen      = false;
    string sdComm     = GetCommentForOrder()+"_Sell";
    double sdLot      = MLots(symbol);
    ENUM_ORDER_TYPE type_req = ORDER_TYPE_SELL;
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //-- structure is set to zero
    ZeroMemory(req);
    ZeroMemory(res);
    ZeroMemory(check);
    //--
    CurrentSymbolSet(symbol);
    double SL=OrderSLSet(symbol,type_req,mc_symbol.Ask());
    double TP=OrderTPSet(symbol,type_req,mc_symbol.Bid());
    //--
    if(RefreshTick(symbol))
       selopen=mc_trade.Sell(sdLot,symbol,mc_symbol.Bid(),SL,TP,sdComm);
    //--
    int error=GetLastError();
    if(selopen||error==0)
      {
        string bsopen="Open SELL Order for "+symbol+" ~ Ticket= ["+(string)mc_trade.ResultOrder()+"] successfully..!";
        Do_Alerts(symbol,bsopen);
      }
    else
      {
        mc_trade.CheckResult(check);
        Do_Alerts(Symbol(),"Open SELL order for "+symbol+" FAILED!!. Return code= "+
                 (string)mc_trade.ResultRetcode()+". Code description: ["+mc_trade.ResultRetcodeDescription()+"]");
        return(false);   
      }
    //--
    return(selopen);
    //--
//---
  } //-end OpenSell
//---------//

double MCEA::OrderSLSet(const string xsymb,ENUM_ORDER_TYPE type,double atprice)
  {
//---
    slv=0.0;
    int x=PairsIdxArray(xsymb);
    Pips(xsymb);
    RefreshTick(xsymb);
    //--
    switch(type) 
      { 
       case (ORDER_TYPE_BUY):
         {
           if(use_sl==Yes && autosl==Yes) slv=mc_symbol.NormalizePrice(atprice-38*pip);
           else
           if(use_sl==Yes && autosl==No)  slv=mc_symbol.NormalizePrice(atprice-SLval*pip);
           else slv=0.0;
           //--
           break;
         }
       case (ORDER_TYPE_SELL):
         {
           if(use_sl==Yes && autosl==Yes) slv=mc_symbol.NormalizePrice(atprice+38*pip);
           else
           if(use_sl==Yes && autosl==No)  slv=mc_symbol.NormalizePrice(atprice+SLval*pip);
           else slv=0.0;
         }
      }
    //---
    return(slv);
//---
  } //-end OrderSLSet()
//---------//

double MCEA::OrderTPSet(const string xsymb,ENUM_ORDER_TYPE type,double atprice)
  {
//---
    tpv=0.0;
    int x=PairsIdxArray(xsymb);
    Pips(xsymb);
    RefreshTick(xsymb);
    //--
    switch(type) 
      { 
       case (ORDER_TYPE_BUY):
         {
           if(use_tp==Yes && autotp==Yes) tpv=mc_symbol.NormalizePrice(atprice+50*pip);
           else
           if(use_tp==Yes && autotp==No)  tpv=mc_symbol.NormalizePrice(atprice+TPval*pip);
           else tpv=0.0;
           //--
           break;
         }
       case (ORDER_TYPE_SELL):
         {
           if(use_tp==Yes && autotp==Yes) tpv=mc_symbol.NormalizePrice(atprice-50*pip);
           else
           if(use_tp==Yes && autotp==No)  tpv=mc_symbol.NormalizePrice(atprice-TPval*pip);
           else tpv=0.0;
         }
      }
    //---
    return(tpv);
//---
  } //-end OrderTPSet()
//---------//

void MCEA::CheckOpenPMx(const string symbx) //-- function: CheckOpenTrade.
  {
//---
    int totalorder=PositionsTotal();
    xtto=totalorder;
    //--
    int xi=PairsIdxArray(symbx);
    xob[xi]=0;
    xos[xi]=0;
    profitb[xi]=0;
    profits[xi]=0;
    double pos_profit = 0.0;
    double pos_swap   = 0.0;
    double pos_comm   = 0.0;
    //--    
    for(int i=0; i<totalorder && !IsStopped(); i++)
      {
        string position_symbol=PositionGetSymbol(i);
        long magic = mc_position.Magic();
        if(position_symbol==symbx && magic==magicEA)
          {
            //--
            ENUM_POSITION_TYPE opstype = mc_position.PositionType();
            if(opstype == POSITION_TYPE_BUY)
              {
                xob[xi]++;
                pos_profit = mc_position.Profit();
                pos_swap   = mc_position.Swap();
                pos_comm   = mc_position.Commission();
                profitb[xi] += NormalizeDouble(pos_profit+pos_swap+pos_comm,2);
              }
            if(opstype == POSITION_TYPE_SELL) 
              {
                xos[xi]++;
                pos_profit = mc_position.Profit();
                pos_swap   = mc_position.Swap();
                pos_comm   = mc_position.Commission();
                profits[xi] += NormalizeDouble(pos_profit+pos_swap+pos_comm,2);
              }
            //--
          }
      }
    //---
    return;
//---
  } //-end CheckOpenPMx()
//---------//

double MCEA::TSPrice(const string xsymb,ENUM_POSITION_TYPE ptype,int TS_type)
  {
//---
    int br=2;
    double pval=0.0;
    int x=PairsIdxArray(xsymb);
    Pips(xsymb);
    //--
    switch(TS_type)
      {
        case 0:
          {
            RefreshTick(xsymb);
            if(ptype==POSITION_TYPE_BUY)  pval=mc_symbol.NormalizePrice(mc_symbol.Bid()-TSval*pip);
            if(ptype==POSITION_TYPE_SELL) pval=mc_symbol.NormalizePrice(mc_symbol.Ask()+TSval*pip);
            break;
          }
        case 1:
          {
            double PSAR[];
            ArrayResize(PSAR,br,br);
            ArraySetAsSeries(PSAR,true);
            CopyBuffer(hParIU[x],0,0,br,PSAR);
            RefreshPrice(xsymb,TFt,br);
            //--
            if(ptype==POSITION_TYPE_BUY  && (PSAR[0]<iLow(xsymb,TFt,0)))
               pval=PSAR[0];
            if(ptype==POSITION_TYPE_SELL && (PSAR[0]>iHigh(xsymb,TFt,0)))
               pval=PSAR[0];
            break;
          }
      }
    //--
    return(pval);
//---
  } //-end TSPrice()
//---------//

bool MCEA::ModifySLTP(const string symbx,int TS_type)
  {
//---
   ResetLastError();
   MqlTradeRequest req={};
   MqlTradeResult  res={};
   MqlTradeCheckResult check={};
   //--
   int TRSP=TS_type;
   bool modist=false;
   int x=PairsIdxArray(symbx);
   Pips(symbx);
   //--
   int total=PositionsTotal();
   //--        
   for(int i=total-1; i>=0; i--) 
     {
       string symbol=PositionGetSymbol(i);
       if(symbol==symbx && mc_position.Magic()==magicEA)
         {
           ENUM_POSITION_TYPE opstype = mc_position.PositionType();
           if(opstype==POSITION_TYPE_BUY) 
             {
               RefreshTick(symbol);
               double price = mc_position.PriceCurrent();
               double vtrsb = mc_symbol.NormalizePrice(TSPrice(symbx,opstype,TRSP));
               double pos_open   = mc_position.PriceOpen();
               double pos_stop   = mc_position.StopLoss();
               double pos_profit = mc_position.Profit();
               double pos_swap   = mc_position.Swap();
               double pos_comm   = mc_position.Commission();
               double netp=pos_profit+pos_swap+pos_comm;
               double modstart=mc_symbol.NormalizePrice(pos_open+TSmin*pip);
               double modminsl=mc_symbol.NormalizePrice(vtrsb+TSmin*pip);
               double modbuysl=vtrsb;
               double modbuytp=mc_symbol.NormalizePrice(price+TPmin*pip);
               bool modbuy = (price>modminsl && modbuysl>modstart && (pos_stop==0.0||modbuysl>pos_stop));
               //--
               if(modbuy && netp>0.05)
                 {
                   modist=mc_trade.PositionModify(symbol,modbuysl,modbuytp);
                 }  
             }
           if(opstype==POSITION_TYPE_SELL) 
             {
               RefreshTick(symbol);
               double price = mc_position.PriceCurrent();
               double vtrss = mc_symbol.NormalizePrice(TSPrice(symbx,opstype,TRSP));
               double pos_open   = mc_position.PriceOpen();
               double pos_stop   = mc_position.StopLoss();
               double pos_profit = mc_position.Profit();
               double pos_swap   = mc_position.Swap();
               double pos_comm   = mc_position.Commission();
               double netp=pos_profit+pos_swap+pos_comm;
               double modstart=mc_symbol.NormalizePrice(pos_open-TSmin*pip);
               double modminsl=mc_symbol.NormalizePrice(vtrss-TSmin*pip);
               double modselsl=vtrss;
               double modseltp=mc_symbol.NormalizePrice(price-TPmin*pip);
               bool modsel = (price<modminsl && modselsl<modstart && (pos_stop==0.0||modselsl<pos_stop)); 
               //--
               if(modsel && netp>0.05)
                 {
                   modist=mc_trade.PositionModify(symbol,modselsl,modseltp);
                 }  
             }
         }
     }
    //--
    return(modist);
//---
  } //-end ModifySLTP()
//---------//

void MCEA::SetSLTPOrders(void) 
  {
//---
   ResetLastError();
   MqlTradeRequest req={};
   MqlTradeResult  res={};
   MqlTradeCheckResult check={};
   //--
   double modbuysl=0;
   double modselsl=0;
   double modbuytp=0;
   double modseltp=0;
   string position_symbol;
   int totalorder=PositionsTotal();
   //--    
   for(int i=totalorder-1; i>=0; i--) 
     {
       string symbol=PositionGetSymbol(i);
       position_symbol=symbol;
       if(mc_position.Magic()==magicEA)
         {
           ENUM_POSITION_TYPE opstype = mc_position.PositionType();
           if(opstype==POSITION_TYPE_BUY) 
             {
               Pips(symbol);
               RefreshTick(symbol);
               double price    = mc_position.PriceCurrent();
               double pos_open = mc_position.PriceOpen();
               double pos_stop = mc_position.StopLoss();
               double pos_take = mc_position.TakeProfit();
               modbuysl=SetOrderSL(symbol,opstype,pos_open);
               if(price<modbuysl) modbuysl=mc_symbol.NormalizePrice(price-slip*pip);
               modbuytp=SetOrderTP(symbol,opstype,pos_open);
               if(price>modbuytp) modbuytp=mc_symbol.NormalizePrice(price+slip*pip);
               //--
               if(pos_stop==0.0 || pos_take==0.0)
                 {
                   if(!mc_trade.PositionModify(position_symbol,modbuysl,modbuytp))
                     {
                       mc_trade.CheckResult(check);
                       Do_Alerts(symbol,"Set SL and TP for "+EnumToString(opstype)+" on "+symbol+" FAILED!!. Return code= "+
                                (string)mc_trade.ResultRetcode()+". Code description: ["+mc_trade.ResultRetcodeDescription()+"]");
                     }
                 }
             }
           if(opstype==POSITION_TYPE_SELL) 
             {
               Pips(symbol);
               RefreshTick(symbol);
               double price    = mc_position.PriceCurrent();
               double pos_open = mc_position.PriceOpen();
               double pos_stop = mc_position.StopLoss();
               double pos_take = mc_position.TakeProfit();
               modselsl=SetOrderSL(symbol,opstype,pos_open);
               if(price>modselsl) modselsl=mc_symbol.NormalizePrice(price+slip*pip);
               modseltp=SetOrderTP(symbol,opstype,pos_open);
               if(price<modseltp) modseltp=mc_symbol.NormalizePrice(price-slip*pip);
               //--
               if(pos_stop==0.0 || pos_take==0.0)
                 {
                   if(!mc_trade.PositionModify(position_symbol,modselsl,modseltp))
                     {
                       mc_trade.CheckResult(check);
                       Do_Alerts(symbol,"Set SL and TP for "+EnumToString(opstype)+" on "+symbol+" FAILED!!. Return code= "+
                                (string)mc_trade.ResultRetcode()+". Code description: ["+mc_trade.ResultRetcodeDescription()+"]");
                     }
                 }
             }
         }
     }
    //--
    return;
//---
  } //-end SetSLTPOrders
//---------//

double MCEA::SetOrderSL(const string xsymb,ENUM_POSITION_TYPE type,double atprice)
  {
//---
    slv=0.0;
    int x=PairsIdxArray(xsymb);
    Pips(xsymb);
    RefreshTick(xsymb);
    //--
    switch(type) 
      { 
       case (POSITION_TYPE_BUY):
         {
           slv=mc_symbol.NormalizePrice(atprice-SLval*pip);
           //--
           break;
         }
       case (POSITION_TYPE_SELL):
         {
           slv=mc_symbol.NormalizePrice(atprice+SLval*pip);
           //--
           break;
         }
      }
    //---
    return(slv);
//---
  } //-end SetOrderSL()
//---------//

double MCEA::SetOrderTP(const string xsymb,ENUM_POSITION_TYPE type,double atprice)
  {
//---
    tpv=0.0;
    int x=PairsIdxArray(xsymb);
    Pips(xsymb);
    RefreshTick(xsymb);
    //--
    switch(type) 
      { 
       case (POSITION_TYPE_BUY):
         {
           tpv=mc_symbol.NormalizePrice(atprice+TPval*pip);
           //--
           break;
         }
       case (POSITION_TYPE_SELL):
         {
           tpv=mc_symbol.NormalizePrice(atprice-TPval*pip);
         }
      }
    //---
    return(tpv);
//---
  } //-end SetOrderTP()
//---------//

void MCEA::CloseBuyPositions(const string symbol)
   {
 //---
    //--
    ResetLastError();
    int total=PositionsTotal(); // number of open positions
    ENUM_POSITION_TYPE closetype = POSITION_TYPE_BUY;
    ENUM_ORDER_TYPE     type_req = ORDER_TYPE_SELL;
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //--
    //--- iterate over all open positions
    for(int i=total-1; i>=0; i--)
      {
        if(mc_position.SelectByIndex(i))
          {
            //--- Parameters of the order
            string position_Symbol   = PositionGetSymbol(i);
            ulong  position_ticket   = PositionGetTicket(i);
            ENUM_POSITION_TYPE  type = mc_position.PositionType();
            //--- if the MagicNumber matches
            if((position_Symbol==symbol) && (mc_position.Magic()==magicEA))
              { 
                //--
                if(type==closetype)
                  {
                    RefreshTick(position_Symbol);
                    bool buyclose=mc_trade.PositionClose(position_Symbol,slip);
                    //--- output information about the closure
                    PrintFormat("Close Buy #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                  }
              }
          }
      }
   //---
   return;
//----
   } //-end CloseBuyPositions()
//---------//

void MCEA::CloseSellPositions(const string symbol)
  {
    //---
    ResetLastError();
    int total=PositionsTotal(); // number of open positions
    ENUM_POSITION_TYPE closetype = POSITION_TYPE_SELL;
    ENUM_ORDER_TYPE     type_req = ORDER_TYPE_BUY;
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //--
    //--- iterate over all open positions
    for(int i=total-1; i>=0; i--)
      {
        if(mc_position.SelectByIndex(i))
          {
            //--- Parameters of the order
            string position_Symbol   = PositionGetSymbol(i);
            ulong  position_ticket   = PositionGetTicket(i);
            ENUM_POSITION_TYPE  type = mc_position.PositionType();
            //--- if the MagicNumber matches
            if((position_Symbol==symbol) && (mc_position.Magic()==magicEA))
              { 
                //--
                if(type==closetype)
                  {
                    RefreshTick(position_Symbol);
                    bool sellclose=mc_trade.PositionClose(position_Symbol,slip);
                    //--- output information about the closure
                    PrintFormat("Close Sell #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                  }
              }
          }
      }
   //---
   return;
//----
   } //-end CloseSellPositions()
//---------//

bool MCEA::CloseAllProfit(void)
   {
//----
    ResetLastError();
    //--
    int up=1,
        dw=-1;
    bool orclose=false;
    string isgood="trend is still good";
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //--
    int ttlorder=PositionsTotal(); // number of open positions
    //--
    for(int x=0; x<arrsymbx; x++)
       {
         string symbol=DIRI[x];
         int hps=PARSAR05(symbol);
         orclose=false;
         //--
         for(int i=ttlorder-1; i>=0; i--)
            {
              string position_Symbol   = PositionGetSymbol(i);
              ENUM_POSITION_TYPE  type = mc_position.PositionType();
              if((position_Symbol==symbol) && (mc_position.Magic()==magicEA))
                {
                  double pos_profit = mc_position.Profit();
                  double pos_swap   = mc_position.Swap();
                  double pos_comm   = mc_position.Commission();
                  double cur_profit = NormalizeDouble(pos_profit+pos_swap+pos_comm,2);
                  ulong  position_ticket = PositionGetTicket(i);
                  //---
                  if(type==POSITION_TYPE_BUY && cur_profit>0.02 && hps==dw)
                    {
                      RefreshTick(position_Symbol);
                      orclose = mc_trade.PositionClose(position_Symbol,slip);
                      //--- output information about the closure
                      PrintFormat("Close #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                    }
                  else if(hps==up) PrintFormat("Not Closed yet #%I64d %s",position_ticket,isgood);
                  if(type==POSITION_TYPE_SELL && cur_profit>0.02 && hps==up)
                    {
                      RefreshTick(position_Symbol);
                      orclose = mc_trade.PositionClose(position_Symbol,slip);
                      //--- output information about the closure
                      PrintFormat("Close #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                    }
                  else if(hps==dw) PrintFormat("Not Closed yet #%I64d %s",position_ticket,isgood);
                }
            }
       }
     //--
     return(orclose);
//----
   } //-end CloseAllProfit()
//---------//

bool MCEA::ManualCloseAllProfit(void)
   {
//----
    ResetLastError();
    //--
    bool orclose=false;
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //--
    int ttlorder=PositionsTotal(); // number of open positions
    //--
    for(int x=0; x<arrsymbx; x++)
       {
         string symbol=DIRI[x];
         orclose=false;
         //--
         for(int i=ttlorder-1; i>=0; i--)
            {
              string position_Symbol   = PositionGetSymbol(i);
              ENUM_POSITION_TYPE  type = mc_position.PositionType();
              if((position_Symbol==symbol) && (mc_position.Magic()==magicEA))
                {
                  double pos_profit = mc_position.Profit();
                  double pos_swap   = mc_position.Swap();
                  double pos_comm   = mc_position.Commission();
                  double cur_profit = NormalizeDouble(pos_profit+pos_swap+pos_comm,2);
                  ulong  position_ticket = PositionGetTicket(i);
                  //---
                  if(type==POSITION_TYPE_BUY && cur_profit>0.02)
                    {
                      RefreshTick(position_Symbol);
                      orclose = mc_trade.PositionClose(position_Symbol,slip);
                      //--- output information about the closure
                      PrintFormat("Close #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                    }
                  if(type==POSITION_TYPE_SELL && cur_profit>0.02)
                    {
                      RefreshTick(position_Symbol);
                      orclose = mc_trade.PositionClose(position_Symbol,slip);
                      //--- output information about the closure
                      PrintFormat("Close #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
                    }
                }
            }
       }
     //--
     return(orclose);
//----
   } //-end ManualCloseAllProfit()
//---------//

void MCEA::CloseAllOrders(void) //-- function: close all order
   {
//----
    ResetLastError();
    //--
    MqlTradeRequest req={};
    MqlTradeResult  res={};
    MqlTradeCheckResult check={};
    //--
    int total=PositionsTotal(); // number of open positions
    //--- iterate over all open positions
    for(int i=total-1; i>=0; i--)
      {
        //--- if the MagicNumber matches
        if(mc_position.Magic()==magicEA)
          { 
            //--
            string position_Symbol   = PositionGetSymbol(i);  // symbol of the position
            ulong  position_ticket   = PositionGetTicket(i);  // ticket of the the opposite position
            ENUM_POSITION_TYPE  type = mc_position.PositionType();
            RefreshTick(position_Symbol);
            bool closepos = mc_trade.PositionClose(position_Symbol,slip);
            //--- output information about the closure
            PrintFormat("Close #%I64d %s %s",position_ticket,position_Symbol,EnumToString(type));
            //---
          }
      }
   //---
   return;
//----
   } //-end CloseAllOrders()
//---------//

void MCEA::CheckClose(const string symbx)
   {
//---
    //--
    ResetLastError();
    Pips(symbx);
    //--
    datetime to=TimeCurrent();
    datetime from=to-(60);
    closetime=TimeCurrent()-(6); // 6 seconds ago
//--- request the entire history 
    HistorySelect(from,to);
    //--- total number in the list of deals
    int deals=HistoryDealsTotal();
    //--
    datetime deal_time  =0;     // time of a deal execution
    ulong  deal_ticket  =0;     // deal ticket 
    long   deal_magic   =0;     // deal magic number
    long   deal_type    =0;     // Order Type
    double deal_price   =0.0;   // deal/order CLOSE price
    double deal_profit  =0.0;   // deal profit
    double deal_swap    =0.0;   // position swap
    double deal_comm    =0.0;   // position commission
    string deal_symbol  ="";    // symbol of the deal
    ENUM_DEAL_ENTRY deal_entry =0; // enum deal entry
    double profit_loss  =0.0;   // Order profit or loss 
    //--
//--- go through deals in a loop 
    for(int z=deals-1; z>=0 && !IsStopped(); z--)
      {
        deal_ticket = HistoryDealGetTicket(z);
        deal_symbol = HistoryDealGetString(deal_ticket,DEAL_SYMBOL);
        deal_magic  = HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
        deal_entry  = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
        deal_type   = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
        //--
        if(deal_symbol==symbx && deal_magic==magicEA)
          {
            if((deal_entry==DEAL_ENTRY_OUT)||(deal_entry==DEAL_ENTRY_OUT_BY))
              {
                deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
                if((deal_time>0) && (deal_time>=closetime))
                  {
                    deal_price  = HistoryDealGetDouble(deal_ticket,DEAL_PRICE);
                    deal_profit = HistoryDealGetDouble(deal_ticket,DEAL_PROFIT); 
                    deal_swap   = HistoryDealGetDouble(deal_ticket,DEAL_SWAP); 
                    deal_comm   = HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);                  
                    profit_loss = NormalizeDouble(deal_profit+deal_swap+deal_comm,2);
                    string xtype = deal_type==DEAL_TYPE_BUY ? "SELL" : deal_type==DEAL_TYPE_SELL ? "BUY": "";
                    //--
                    if(profit_loss>0) 
                      {
                        string ckclose="Close "+xtype+" Position on "+symbx+" at price : "+DoubleToString(deal_price,dgts)+
                                       " OrderCloseTime(): "+TimeToString(deal_time,TIME_DATE|TIME_MINUTES)+
                                       " in profit : "+DoubleToString(profit_loss,2);
                        Do_Alerts(symbx,ckclose);    
                      }
                    if(profit_loss<=0) 
                      {  
                        string ckclose="Close "+xtype+" Position on "+symbx+" at price : "+DoubleToString(deal_price,dgts)+
                                       " OrderCloseTime(): "+TimeToString(deal_time,TIME_DATE|TIME_MINUTES)+
                                       " in loss : "+DoubleToString(profit_loss,2);
                        Do_Alerts(symbx,ckclose);
                      }
                    //--
                    break;
                  }
              }
          }
      }
    //---
    return;
//----
  } //-end CheckClose()
//---------//

void MCEA::TodayOrders(void)
  {
//---
    //--
    ResetLastError();
    //--
    datetime from=StringToTime(ReqDate(ThisTime(day),0,0));
    datetime to=TimeCurrent();
//--- request the entire history
    HistorySelect(from,to);
    //--- total number in the list of deals
    int deals=HistoryDealsTotal();
    //--
    datetime deal_time  =0;     // time of a deal execution
    ulong  deal_ticket  =0;     // deal ticket 
    long   deal_magic   =0;     // deal magic number
    long   deal_type    =0;     // Order Type
    double deal_price   =0.0;   // deal/order CLOSE price
    double deal_profit  =0.0;   // deal profit
    double deal_swap    =0.0;   // position swap
    double deal_comm    =0.0;   // position commission
    ENUM_DEAL_ENTRY deal_entry =0; // enum deal entry
    //--
    string pos_symbol   ="";    // Position symbol
    fixclprofit         =0.0;   // Order Close profit
    floatprofit         =0.0;   // float position profit
    oBm=0;                      // Order buy 
    oSm=0;                      // Order sell
    //--
    int totalorder=PositionsTotal();
    //--    
    for(int i=0; i<totalorder && !IsStopped(); i++)
      {
        pos_symbol = PositionGetSymbol(i);
        long magic = mc_position.Magic();
        if(mc_position.Symbol() == pos_symbol && magic==magicEA)
          {
            //--
            ENUM_POSITION_TYPE opstype = mc_position.PositionType();
            if(opstype == POSITION_TYPE_BUY)  {oBm++; floatprofit += mc_position.Profit();}
            if(opstype == POSITION_TYPE_SELL) {oSm++; floatprofit += mc_position.Profit();}
            //--
          }
      }
    xtto=oBm+oSm;
    //--
//--- go through deals in a loop 
    for(int z=0; z<deals && !IsStopped(); z++)
      {
        deal_ticket = HistoryDealGetTicket(z); 
        deal_magic  = HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
        deal_entry  = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
        deal_type   = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
        if(deal_magic==magicEA)
          {
            if((deal_entry==DEAL_ENTRY_OUT)||(deal_entry==DEAL_ENTRY_OUT_BY))
              {
                deal_time = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
                //--
                if((deal_time>0) && (deal_time>=from))
                  {
                    deal_profit = HistoryDealGetDouble(deal_ticket,DEAL_PROFIT); 
                    deal_swap   = HistoryDealGetDouble(deal_ticket,DEAL_SWAP); 
                    deal_comm   = HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);                  
                    //--
                    fixclprofit += NormalizeDouble(deal_profit+deal_swap+deal_comm,2);
                  }
              }
          }
      }
    //---
    return;
//----
  } //-end TodayOrders()
//---------//

double MCEA::MLots(const string symbx) // function: calculation lots size
  {
//----
   double Lsize=0.0;
   double sym_Lm=0.0;
   string sym_use ="";
   int pil;
   int Lpair;
   int xsym=-1;
   //--
   string sCur1=StringSubstr(symbx,posCur1,3);
   string sCur2=StringSubstr(symbx,posCur2,3);
   //--
   if(sCur1=="EUR"||sCur1=="GBP"||sCur1=="AUD"||sCur1=="NZD") pil=0;
   if(sCur1=="CAD"||sCur1=="CHF") pil=1;
   if(sCur1=="XAU"||sCur1=="XAG") pil=2;
   if(sCur1=="USD") pil=3;
   //--
   switch(pil)
     {
       case 0: sym_use=sCur1+"USD"; break;
       case 1: sym_use="USD"+sCur1; break;
       case 2: sym_use=symbx;       break;
       case 3: sym_use=symbx;       break;
     }
   //--
   xsym=PairsIdxArray(sym_use);
   if(xsym!=-1) sym_use=DIRI[xsym];
   Lpair = StringFind(sym_use,"USD",0);
   //--
   CurrentSymbolSet(sym_use);
   double csize  = mc_symbol.ContractSize();
   double AFMar  = mc_account.FreeMargin();
   double AFLev  = (double)mc_account.Leverage();
   double symbid = mc_symbol.Bid();
   //--
   double Lmaxs  = SymbolInfoDouble(symbx,SYMBOL_VOLUME_MAX);
   double Lmins  = SymbolInfoDouble(symbx,SYMBOL_VOLUME_MIN);
   //--
   double useRisk = (Risk/100.0);
   double PctUse  = ((100.0-Risk)/100.0);
   //--
   double NZ1=NonZeroDiv(AFMar*AFLev,csize);
   double NZ2=NonZeroDiv(AFMar*AFLev,symbid);
   //--
   if(Lpair>=0 && Lpair<posCur2) {sym_Lm = fmin(Lmaxs,NZ1);}
   else {sym_Lm = fmin(Lmaxs,NonZeroDiv(NZ2,csize));}
   //--
   double sym_Lc = NormalizeDouble(sym_Lm*useRisk,LotDig(symbx));
   double asize  = NormalizeDouble(sym_Lc/(double)LotPS,LotDig(symbx));
   //--
   if(mmlot==DynamLot) 
     {
       Lsize = NormalizeDouble(asize*PctUse,LotDig(symbx));
     } 
   else {Lsize = Lots;}
   //--
   if(Lsize < Lmins) Lsize = Lmins;
   if(Lsize > Lmaxs) Lsize = Lmaxs;
   //--
   double lotsize=NormalizeDouble(Lsize,LotDig(symbx));
   //--
   return(lotsize);
//----
  } //-end MLots()
//---------//

int MCEA::LotDig(const string symbx)
  {
//---
   double lots_step=SymbolInfoDouble(symbx,SYMBOL_VOLUME_STEP);
   //--
   if(lots_step==0.01)
      ldig=2;
   //--
   if(lots_step==0.1)
      ldig=1;
   //--
   if(lots_step==1.0)
      ldig=0;
     //---
     return(ldig);
//----
  } //-end LotDig()
//---------//

double MCEA::NonZeroDiv(double val1,double val2)
  {
//---
   double resval=0.0;
   if(val1==0.0 || val2==0.0) resval=0.00;
   else
   resval=val1/val2;
   //--
   return(resval);
//---
  } //-end NonZeroDiv()
//---------//

void MCEA::TradeInfo(void) // function: write comments on the chart
  {
//----
   Pips(Symbol());
   double spread=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD)/xpip;
   rem=zntm-TimeCurrent();
   string postime=PosTimeZone();
   string eawait=" - Waiting for active time..!";
   //--
   string comm="";
   TodayOrders();
   //--
   comm="\n     :: Server Date Time : "+string(ThisTime(year))+"."+string(ThisTime(mon))+"."+string(ThisTime(day))+ "   "+TimeToString(TimeCurrent(),TIME_SECONDS)+
        "\n     ------------------------------------------------------------"+
        "\n      :: Broker               :  "+ TerminalInfoString(TERMINAL_COMPANY)+
        "\n      :: Expert Name      :  "+ expname+
        "\n      :: Acc. Name         :  "+ mc_account.Name()+
        "\n      :: Acc. Number      :  "+ (string)mc_account.Login()+
        "\n      :: Acc. TradeMode :  "+ AccountMode()+
        "\n      :: Acc. Leverage    :  1 : "+ (string)mc_account.Leverage()+
        "\n      :: Acc. Equity       :  "+ DoubleToString(mc_account.Equity(),2)+
        "\n      :: Margin Mode     :  "+ (string)mc_account.MarginModeDescription()+
        "\n      :: Magic Number   :  "+ string(magicEA)+
        "\n      :: Trade on TF      :  "+ EnumToString(TFt)+
        "\n      :: Today Trading   :  "+ TradingDay()+" : "+hariini+
        "\n      :: Trading Session :  "+ tz_ses+
        "\n      :: Trading Time    :  "+ postime;
        if(TimeCurrent()<zntm)
          {
            comm=comm+
            "\n      :: Time Remaining :  "+(string)ReqTime(rem,hour)+":"+(string)ReqTime(rem,min)+":"+(string)ReqTime(rem,sec) + eawait;
          }
        comm=comm+
        "\n     ------------------------------------------------------------"+
        "\n      :: Trading Pairs     :  "+pairs+
        "\n      :: BUY Market      :  "+string(oBm)+
        "\n      :: SELL Market     :  "+string(oSm)+
        "\n      :: Total Order       :  "+string(oBm+oSm)+
        "\n      :: Order Profit      :  "+DoubleToString(floatprofit,2)+
        "\n      :: Fixed Profit       :  "+DoubleToString(fixclprofit,2)+
        "\n      :: Float Money     :  "+DoubleToString(floatprofit,2)+
        "\n      :: Nett Profit        :  "+DoubleToString(floatprofit+fixclprofit,2);
   //--
   Comment(comm);
   ChartRedraw(0);
   return;
//----
  } //-end TradeInfo()  
//---------//

string MCEA::PosTimeZone(void)
  {
//---
    string tzpos="";
    //--
    if(ReqTime(zntm,day)>ThisTime(day))
     {
       tzpos=tz_opn+ " Next day to " +tz_cls + " Next day";
     }
    else
    if(TimeCurrent()<znop)
      {
        if(ThisTime(day)==ReqTime(znop,day) && ThisTime(day)==ReqTime(zncl,day))
          tzpos=tz_opn+" to " +tz_cls+ " Today";
        //else
        if(ThisTime(day)==ReqTime(znop,day) && ThisTime(day)<ReqTime(zncl,day))
          tzpos=tz_opn+ " Today to " +tz_cls+ " Next day";
      }
    else
    if(TimeCurrent()>=znop && TimeCurrent()<zncl)
      {
        if(ThisTime(day)<ReqTime(zncl,day))
          tzpos=tz_opn+ " Today to " +tz_cls+ " Next day";
        else
        if(ThisTime(day)==ReqTime(zncl,day))
          tzpos=tz_opn+" to " +tz_cls+ " Today";
      }
    else
    if(ThisTime(day)==ReqTime(znop,day) && ThisTime(day)<ReqTime(zncl,day))
      {
        tzpos=tz_opn+" Today to " +tz_cls+ " Next day";
      }
    //--
    return(tzpos);
//----
  } //-end PosTimeZone()
//---------//

void MCEA::Set_Time_Zone(void)
  {
//---
    //-- Server Time==TimeCurrent()
    datetime TTS=TimeTradeServer();
    datetime GMT=TimeGMT();
    //--
    MqlDateTime svrtm,gmttm; 
    TimeToStruct(TTS,svrtm); 
    TimeToStruct(GMT,gmttm); 
    int svrhr=svrtm.hour;  // Server time hour
    int gmthr=gmttm.hour;  // GMT time hour
    int difhr=svrhr-gmthr; // Time difference Server time to GMT time
    //--
    int NZSGMT=12;  // New Zealand Session GMT/UTC+12
    int AUSGMT=10;  // Australia Sydney Session GMT/UTC+10
    int TOKGMT=9;   // Asia Tokyo Session GMT/UTC+9
    int EURGMT=0;   // Europe London Session GMT/UTC 0
    int USNGMT=-5;  // US New York Session GMT/UTC-5
    //--
    int NZSStm=8;   // New Zealand Session time start: 08:00 Local Time
    int NZSCtm=17;  // New Zealand Session time close: 17:00 Local Time 
    int AUSStm=7;   // Australia Sydney Session time start: 07:00 Local Time 
    int AUSCtm=17;  // Australia Sydney Session time close: 17:00 Local Time  
    int TOKStm=9;   // Asia Tokyo Session time start: 09:00 Local Time 
    int TOKCtm=18;  // Asia Tokyo Session time close: 18:00 Local Time  
    int EURStm=9;   // Europe London Session time start: 09:00 Local Time 
    int EURCtm=19;  // Europe London Session time close: 19:00 Local Time  
    int USNStm=8;   // US New York Session time start: 08:00 Local Time 
    int USNCtm=17;  // US New York Session time close: 17:00 Local Time  
    //--
    int nzo = (NZSStm+difhr-NZSGMT)<0 ? 24+(NZSStm+difhr-NZSGMT) : (NZSStm+difhr-NZSGMT);
    int nzc = (NZSCtm+difhr-NZSGMT)<0 ? 24+(NZSCtm+difhr-NZSGMT) : (NZSCtm+difhr-NZSGMT);
    //--
    int auo = (AUSStm+difhr-AUSGMT)<0 ? 24+(AUSStm+difhr-AUSGMT) : (AUSStm+difhr-AUSGMT);
    int auc = (AUSCtm+difhr-AUSGMT)<0 ? 24+(AUSCtm+difhr-AUSGMT) : (AUSCtm+difhr-AUSGMT);
    //--
    int tko = (TOKStm+difhr-TOKGMT)<0 ? 24+(TOKStm+difhr-TOKGMT) : (TOKStm+difhr-TOKGMT);
    int tkc = (TOKCtm+difhr-TOKGMT)<0 ? 24+(TOKCtm+difhr-TOKGMT) : (TOKCtm+difhr-TOKGMT);
    //--
    int euo = (EURStm+difhr-EURGMT)<0 ? 24+(EURStm+difhr-EURGMT) : (EURStm+difhr-EURGMT);
    int euc = (EURCtm+difhr-EURGMT)<0 ? 24+(EURCtm+difhr-EURGMT) : (EURCtm+difhr-EURGMT);
    //--
    int uso = (USNStm+difhr-USNGMT)<0 ? 24+(USNStm+difhr-USNGMT) : (USNStm+difhr-USNGMT);
    int usc = (USNCtm+difhr-USNGMT)<0 ? 24+(USNCtm+difhr-USNGMT) : (USNCtm+difhr-USNGMT);
    if(usc==0||usc==24) usc=23;
    //--
    //---Trading on Custom Session
    int _days00=ThisTime(day);
    int _days10=ThisTime(day);
    if(stsescuh>clsescuh) _days10=ThisTime(day)+1;
    tmopcu=ReqDate(_days00,stsescuh,stsescum); 
    tmclcu=ReqDate(_days10,clsescuh,clsescum); 
    //--
    //--Trading on New Zealand Session GMT/UTC+12
    int _days01=ThisTime(hour)<nzc ? ThisTime(day)-1 : ThisTime(day);
    int _days11=ThisTime(hour)<nzc ? ThisTime(day) : ThisTime(day)+1;
    tmop01=ReqDate(_days01,nzo,0);    // start: 08:00 Local Time == 20:00 GMT/UTC
    tmcl01=ReqDate(_days11,nzc-1,59); // close: 17:00 Local Time == 05:00 GMT/UTC
    //--
    //--Trading on Australia Sydney Session GMT/UTC+10
    int _days02=ThisTime(hour)<auc ? ThisTime(day)-1 : ThisTime(day);
    int _days12=ThisTime(hour)<auc ? ThisTime(day) : ThisTime(day)+1;
    tmop02=ReqDate(_days02,auo,0);    // start: 07:00 Local Time == 21:00 GMT/UTC
    tmcl02=ReqDate(_days12,auc-1,59); // close: 17:00 Local Time == 07:00 GMT/UTC
    //--
    //--Trading on Asia Tokyo Session GMT/UTC+9
    int _days03=ThisTime(hour)<tkc ? ThisTime(day) : ThisTime(day)+1;
    int _days13=ThisTime(hour)<tkc ? ThisTime(day) : ThisTime(day)+1;
    tmop03=ReqDate(_days03,tko,0);    // start: 09:00 Local Time == 00:00 GMT/UTC
    tmcl03=ReqDate(_days13,tkc-1,59); // close: 18:00 Local Time == 09:00 GMT/UTC
    //--
    //--Trading on Europe London Session GMT/UTC 00:00
    int _days04=ThisTime(hour)<euc ? ThisTime(day) : ThisTime(day)+1;
    int _days14=ThisTime(hour)<euc ? ThisTime(day) : ThisTime(day)+1;
    tmop04=ReqDate(_days04,euo,0);     // start: 09:00 Local Time == 09:00 GMT/UTC
    tmcl04=ReqDate(_days14,euc-1,59);  // close: 19:00 Local Time == 19:00 GMT/UTC
    //--
    //--Trading on US New York Session GMT/UTC-5
    int _days05=ThisTime(hour)<usc  ? ThisTime(day) : ThisTime(day)+1;
    int _days15=ThisTime(hour)<=usc ? ThisTime(day) : ThisTime(day)+1;
    tmop05=ReqDate(_days05,uso,0);  // start: 08:00 Local Time == 13:00 GMT/UTC
    tmcl05=ReqDate(_days15,usc,59); // close: 17:00 Local Time == 22:00 GMT/UTC
    //--
    //--Not Use Trading Time Zone
    if(trd_time_zone==No)
      {
        tmopno=ReqDate(ThisTime(day),0,15); 
        tmclno=ReqDate(ThisTime(day),23,59);
      }
    //--
    Time_Zone();
    //--
    return;
//---
  } //-end Set_Time_Zone()
//---------//

void MCEA::Time_Zone(void)
  {
//---
   //--
   tz_ses="";
   //--
   switch(session)
     {
       case Cus_Session:
         {
           SesCuOp=StringToTime(tmopcu);
           SesCuCl=StringToTime(tmclcu);
           zntm=SesCuOp;
           znop=SesCuOp;
           zncl=SesCuCl;
           tz_ses="Custom_Session";
           tz_opn=timehr(stsescuh,stsescum);
           tz_cls=timehr(clsescuh,clsescum);
           break;
         }
       case New_Zealand:
         {
           Ses01Op=StringToTime(tmop01);
           Ses01Cl=StringToTime(tmcl01);
           zntm=Ses01Op;
           znop=Ses01Op;
           zncl=Ses01Cl;
           tz_ses="New_Zealand/Oceania";
           tz_opn=timehr(ReqTime(Ses01Op,hour),ReqTime(Ses01Op,min));
           tz_cls=timehr(ReqTime(Ses01Cl,hour),ReqTime(Ses01Cl,min));
           break;
         }
       case Australia:
         {
           Ses02Op=StringToTime(tmop02);
           Ses02Cl=StringToTime(tmcl02);
           zntm=Ses02Op;
           znop=Ses02Op;
           zncl=Ses02Cl;
           tz_ses="Australia Sydney";
           tz_opn=timehr(ReqTime(Ses02Op,hour),ReqTime(Ses02Op,min));
           tz_cls=timehr(ReqTime(Ses02Cl,hour),ReqTime(Ses02Cl,min));
           break;
         }
       case Asia_Tokyo:
         {
           Ses03Op=StringToTime(tmop03);
           Ses03Cl=StringToTime(tmcl03);
           zntm=Ses03Op;
           znop=Ses03Op;
           zncl=Ses03Cl;
           tz_ses="Asia/Tokyo";
           tz_opn=timehr(ReqTime(Ses03Op,hour),ReqTime(Ses03Op,min));
           tz_cls=timehr(ReqTime(Ses03Cl,hour),ReqTime(Ses03Cl,min));
           break;
         }
       case Europe_London:
         {
           Ses04Op=StringToTime(tmop04);
           Ses04Cl=StringToTime(tmcl04);
           zntm=Ses04Op;
           znop=Ses04Op;
           zncl=Ses04Cl;
           tz_ses="Europe/London";
           tz_opn=timehr(ReqTime(Ses04Op,hour),ReqTime(Ses04Op,min));
           tz_cls=timehr(ReqTime(Ses04Cl,hour),ReqTime(Ses04Cl,min));
           break;
         }
       case US_New_York:
         {
           Ses05Op=StringToTime(tmop05);
           Ses05Cl=StringToTime(tmcl05);
           zntm=Ses05Op;
           znop=Ses05Op;
           zncl=Ses05Cl;
           tz_ses="US/New_York";
           tz_opn=timehr(ReqTime(Ses05Op,hour),ReqTime(Ses05Op,min));
           tz_cls=timehr(ReqTime(Ses05Cl,hour),ReqTime(Ses05Cl,min));
           break;
         }
     }
   //--
   if(trd_time_zone==No)
     {
       SesNoOp=StringToTime(tmopno);
       SesNoCl=StringToTime(tmclno);
       zntm=SesNoOp;
       znop=SesNoOp;
       zncl=SesNoCl;
       tz_ses="Not Use Time Zone";
       tz_opn=timehr(ReqTime(SesNoOp,hour),ReqTime(SesNoOp,min));
       tz_cls=timehr(ReqTime(SesNoCl,hour),ReqTime(SesNoCl,min));
     }
   //--
   return;
//---
  } //-end Time_Zone()
//---------//

bool MCEA::Trade_session(void)
  {
//---
   bool trd_ses=false;
   ishour=ThisTime(hour);
   if(ishour!=onhour) Set_Time_Zone();
   datetime tcurr=TimeCurrent(); // Server Time
   //--
   switch(session)
     {
       case Cus_Session:
         {
           if(tcurr>=SesCuOp && tcurr<=SesCuCl) trd_ses=true;
           break;
         }
       case New_Zealand:
         {
           if(tcurr>=Ses01Op && tcurr<=Ses01Cl) trd_ses=true;
           break;
         }
       case Australia:
         {
           if(tcurr>=Ses02Op && tcurr<=Ses02Cl) trd_ses=true;
           break;
         }
       case Asia_Tokyo:
         {
           if(tcurr>=Ses03Op && tcurr<=Ses03Cl) trd_ses=true;
           break;
         }
       case Europe_London:
         {
           if(tcurr>=Ses04Op && tcurr<=Ses04Cl) trd_ses=true;
           break;
         }
       case US_New_York:
         {
           if(tcurr>=Ses05Op && tcurr<=Ses05Cl) trd_ses=true;
           break;
         }
     }
   //--
   if(trd_time_zone==No) 
     {
      if(tcurr>=SesNoOp && tcurr<=SesNoCl) trd_ses=true;
     }
   //--
   onhour=ishour;
   //--
   return(trd_ses);
//---  
  } //-end Trade_session()
//---------//

string MCEA::TradingDay(void)
  {
//---
   int trdday=ThisTime(dow);
   switch(trdday)
     {
        case 0: daytrade="Sunday";    break;
        case 1: daytrade="Monday";    break;
        case 2: daytrade="Tuesday";   break;
        case 3: daytrade="Wednesday"; break;
        case 4: daytrade="Thursday";  break;
        case 5: daytrade="Friday";    break;
        case 6: daytrade="Saturday";  break;
     }
   return(daytrade);
//---
  } //-end TradingDay()  
//---------//

bool MCEA::TradingToday(void)
  {
//---
    bool tradetoday=false;
    int trdday=ThisTime(dow);
    hariini="No";
    //--
    int ttd[];
    ArrayResize(ttd,7);
    ttd[0]=ttd0;
    ttd[1]=ttd1;
    ttd[2]=ttd2;
    ttd[3]=ttd3;
    ttd[4]=ttd4;
    ttd[5]=ttd5;
    ttd[6]=ttd6;
    //--
    if(ttd[trdday]==Yes) {tradetoday=true; hariini="Yes";}
   //--
   return(tradetoday);
//---
  } //-end TradingToday()
//---------//

string MCEA::timehr(int hr,int mn)
  {
//---
    string scon="";
    string men=mn==0 ? "00" : string(mn);
    int shr=hr==24 ? 0 : hr;
    if(shr<10) scon="0"+string(shr)+":"+men;
    else scon=string(shr)+":"+men;
    //--
    return(scon);
//---
  } //-end timehr()
//---------//

string MCEA::ReqDate(int d,int h,int m) 
  { 
//---
   MqlDateTime mdt; 
   datetime t=TimeCurrent(mdt); 
   x_year=mdt.year; 
   x_mon=mdt.mon; 
   x_day=d; 
   x_hour=h; 
   x_min=m;
   x_sec=mdt.sec;
   //--
   string mdr=string(x_year)+"."+string(x_mon)+"."+string(x_day)+"   "+timehr(x_hour,x_min);
   return(mdr);
//---
  } //-end ReqDate()
//---------//

int MCEA::ThisTime(const int reqmode) 
  {
//---
    MqlDateTime tm;
    TimeCurrent(tm);
    int valtm=0;
    //--
    switch(reqmode)
      {
        case 0: valtm=tm.year; break;        // Return Year 
        case 1: valtm=tm.mon;  break;        // Return Month 
        case 2: valtm=tm.day;  break;        // Return Day 
        case 3: valtm=tm.hour; break;        // Return Hour 
        case 4: valtm=tm.min;  break;        // Return Minutes 
        case 5: valtm=tm.sec;  break;        // Return Seconds 
        case 6: valtm=tm.day_of_week; break; // Return Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
        case 7: valtm=tm.day_of_year; break; // Return Day number of the year (January 1st is assigned the number value of zero) 
      }
    //--
    return(valtm);
//---
  } //-end ThisTime()
//---------//

int MCEA::ReqTime(datetime reqtime,
                  const int reqmode) 
  {
    MqlDateTime tm;
    TimeToStruct(reqtime,tm);
    int valtm=0;
    //--
    switch(reqmode)
      {
        case 0: valtm=tm.year; break;        // Return Year 
        case 1: valtm=tm.mon;  break;        // Return Month 
        case 2: valtm=tm.day;  break;        // Return Day 
        case 3: valtm=tm.hour; break;        // Return Hour 
        case 4: valtm=tm.min;  break;        // Return Minutes 
        case 5: valtm=tm.sec;  break;        // Return Seconds 
        case 6: valtm=tm.day_of_week; break; // Return Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
        case 7: valtm=tm.day_of_year; break; // Return Day number of the year (January 1st is assigned the number value of zero) 
      }
    //--
    return(valtm);
//---
  } //-end ReqTime()
//---------//

string MCEA::AccountMode() // function: to known account trade mode
  {
//----
//--- Demo, Contest or Real account 
   ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
 //---
   trade_mode="";
   //--
   switch(account_type) 
     { 
      case  ACCOUNT_TRADE_MODE_DEMO: 
         trade_mode="Demo"; 
         break; 
      case  ACCOUNT_TRADE_MODE_CONTEST: 
         trade_mode="Contest"; 
         break; 
      default: 
         trade_mode="Real"; 
         break; 
     }
   //--
   return(trade_mode);
//----
  } //-end AccountMode()
//---------//

void MCEA::Do_Alerts(const string symbol,string msgText)
  {
//---
    //--
    Print("--- "+symbol+": "+msgText+
          "\n--- at: ",TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES));
    //--
    if(alerts==Yes)
      {
        Alert("--- "+symbol+": "+msgText+
              "--- at: ",TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES));
      }
    //--
    if(UseEmailAlert==Yes) 
      SendMail(expname,"--- "+symbol+" "+TF2Str(PERIOD_CURRENT)+": "+msgText+
                       "\n--- at: "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES));
    //--
    if(UseSendnotify==Yes) 
      SendNotification(expname+"--- "+symbol+" "+TF2Str(PERIOD_CURRENT)+": "+msgText+
                      "\n--- at: "+TimeToString(iTime(symbol,0,0),TIME_DATE|TIME_MINUTES));
    //--
    return;
    //--
//---
  } //-end Do_Alerts()
//---------//

string MCEA::TF2Str(ENUM_TIMEFRAMES period)
  {
//---
   switch(period)
     {
       //--
       case PERIOD_M1:   return("M1");
       case PERIOD_M2:   return("M2");
       case PERIOD_M3:   return("M3");
       case PERIOD_M4:   return("M4");
       case PERIOD_M5:   return("M5");
       case PERIOD_M6:   return("M6");
       case PERIOD_M10:  return("M10");
       case PERIOD_M12:  return("M12");
       case PERIOD_M15:  return("M15");
       case PERIOD_M20:  return("M20");
       case PERIOD_M30:  return("M30");
       case PERIOD_H1:   return("H1");
       case PERIOD_H2:   return("H2");
       case PERIOD_H3:   return("H3");
       case PERIOD_H4:   return("H4");
       case PERIOD_H6:   return("H6");
       case PERIOD_H8:   return("H8");
       case PERIOD_H12:  return("H12");
       case PERIOD_D1:   return("D1");
       case PERIOD_W1:   return("W1");
       case PERIOD_MN1:  return("MN1");
       //--
     }
   return(string(period));
//---
  } //-end TF2Str()
//---------//

string MCEA::getUninitReasonText(int reasonCode) 
  { 
//---
   string text=""; 
   //--- 
   switch(reasonCode) 
     { 
       case REASON_PROGRAM:
            text="The EA has stopped working calling by remove function."; break;
       case REASON_REMOVE: 
            text="Program "+__FILE__+" was removed from chart"; break;
       case REASON_RECOMPILE:
            text="Program recompiled."; break;    
       case REASON_CHARTCHANGE: 
            text="Symbol or timeframe was changed"; break;
       case REASON_CHARTCLOSE: 
            text="Chart was closed"; break; 
       case REASON_PARAMETERS: 
            text="Input-parameter was changed"; break;            
       case REASON_ACCOUNT: 
            text="Account was changed"; break; 
       case REASON_TEMPLATE: 
            text="New template was applied to chart"; break; 
       case REASON_INITFAILED:
            text="The OnInit() handler returned a non-zero value."; break;
       case REASON_CLOSE: 
            text="Terminal closed."; break;
       default: text="Another reason"; break;
     } 
   //--
   return text;
//---
  } //-end getUninitReasonText()
//---------//

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
//--- handling CHARTEVENT_CLICK event ("Clicking the chart")
   ResetLastError();
   //--
   ENUM_TIMEFRAMES CCS=mc.TFt;
   //--
   if(id==CHARTEVENT_OBJECT_CLICK) 
     {
       int lensymbol=StringLen(Symbol());
       int lensparam=StringLen(sparam);
       //--
       //--- if "Set SL All Orders" button is click
       if(sparam=="Set SL/TP All Orders") 
         { 
           mc.SetSLTPOrders();
           Alert("-- "+mc.expname+" -- ",Symbol()," -- Set SL/TP All Orders");
           //--- unpress the button 
           ObjectSetInteger(0,"Set SL/TP All Orders",OBJPROP_STATE,false);
           ObjectSetInteger(0,"Set SL/TP All Orders",OBJPROP_ZORDER,0);
           CreateManualPanel();
         }
       //--- if "Close All Order" button is click
       if(sparam=="Close All Order") 
         { 
           mc.CloseAllOrders();
           Alert("-- "+mc.expname+" -- ",Symbol()," -- Close All Orders");
           //--- unpress the button 
           ObjectSetInteger(0,"Close All Order",OBJPROP_STATE,false);
           ObjectSetInteger(0,"Close All Order",OBJPROP_ZORDER,0);
           CreateManualPanel();
         }
       //--- if "Close All Profit" button is click
       if(sparam=="Close All Profit") 
         { 
           mc.ManualCloseAllProfit();
           Alert("-- "+mc.expname+" -- ",Symbol()," -- Close All Profit");
           //--- unpress the button 
           ObjectSetInteger(0,"Close All Profit",OBJPROP_STATE,false);
           ObjectSetInteger(0,"Close All Profit",OBJPROP_ZORDER,0);
           CreateManualPanel();
         }
       //--- if "X" button is click
       if(sparam=="X") 
         { 
           ObjectsDeleteAll(0,0,OBJ_BUTTON);
           ObjectsDeleteAll(0,0,OBJ_LABEL);
           ObjectsDeleteAll(0,0,OBJ_RECTANGLE_LABEL);
           //--- unpress the button 
           ObjectSetInteger(0,"X",OBJPROP_STATE,false);
           ObjectSetInteger(0,"X",OBJPROP_ZORDER,0);
           //--
           DeleteButtonX();
           mc.PanelExtra=false;
           DisplayManualButton();
         }
       //--- if "M" button is click
       if(sparam=="M") 
         { 
           //--- unpress the button 
           ObjectSetInteger(0,"M",OBJPROP_STATE,false);
           ObjectSetInteger(0,"M",OBJPROP_ZORDER,0);
           mc.PanelExtra=true;
           CreateManualPanel();
         }
       //--- if "C" button is click
       if(sparam=="C") 
         { 
           //--- unpress the button 
           ObjectSetInteger(0,"C",OBJPROP_STATE,false);
           ObjectSetInteger(0,"C",OBJPROP_ZORDER,0);
           mc.PanelExtra=true;
           CreateSymbolPanel();
         }
       //--- if "R" button is click
       if(sparam=="R") 
         { 
           Alert("-- "+mc.expname+" -- ",Symbol()," -- expert advisor will be Remove from the chart.");
           ExpertRemove();
           //--- unpress the button 
           ObjectSetInteger(0,"R",OBJPROP_STATE,false);
           ObjectSetInteger(0,"R",OBJPROP_ZORDER,0);
           if(!ChartSetSymbolPeriod(0,Symbol(),Period()))
             ChartSetSymbolPeriod(0,Symbol(),Period());
           DeletePanelButton();
           ChartRedraw(0);
         }
       //--- if Symbol button is click
       if(lensparam==lensymbol)
         {
           int sx=mc.ValidatePairs(sparam);
           ChangeChartSymbol(mc.AS30[sx],CCS);
           mc.PanelExtra=false;
         }
       //--
     }
    //--
    return;
//---
  } //-end OnChartEvent()
//---------//

void ChangeChartSymbol(string c_symbol,ENUM_TIMEFRAMES cstf)
  {
//---
   //--- unpress the button 
   ObjectSetInteger(0,c_symbol,OBJPROP_STATE,false);
   ObjectSetInteger(0,c_symbol,OBJPROP_ZORDER,0);
   ObjectsDeleteAll(0,0,OBJ_BUTTON);
   ObjectsDeleteAll(0,0,OBJ_LABEL);
   ObjectsDeleteAll(0,0,OBJ_RECTANGLE_LABEL);
   //--
   ChartSetSymbolPeriod(0,c_symbol,cstf);
   //--
   ChartRedraw(0);
   //--
   return;
//---
  } //-end ChangeChartSymbol()
//---------//

int WS(int width) // Width Scaling factor wide button
  {
//---
    int res=0;
    int reswidth=0;
    //--- Calculating the scaling factor wide button on a screen
    int scale_factor=(TerminalInfoInteger(TERMINAL_SCREEN_DPI));
    //--- Use of the scaling factor 
    reswidth=(width * scale_factor) / 96;
    double res1=NormalizeDouble(reswidth*1.25,0);
    res=int(res1);
    //--
    return(res);
//---
  } //-end WS()
//---------//

void CreateManualPanel()
  {
//---
    //--
    CreateButtonTemplate(0,"TemplateSL",160,35,STYLE_SOLID,5,BORDER_RAISED,clrNONE,clrBurlyWood,clrWhite,CORNER_RIGHT_UPPER,170,45,true);
    CreateButtonTemplate(0,"TempStatSL",154,30,STYLE_SOLID,3,BORDER_RAISED,clrNONE,clrGreen,clrWhite,CORNER_RIGHT_UPPER,167,48,true);
    CreateButtonClick(0,"Set SL/TP All Orders",143,21,"Bodoni MT Black",10,BORDER_RAISED,"Set SL/TP All Orders",clrNONE,clrRed,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,162,56,true,"Set SL/TP All Orders");
//--
    CreateButtonTemplate(0,"TemplateS",160,35,STYLE_SOLID,5,BORDER_RAISED,clrNONE,clrBurlyWood,clrWhite,CORNER_RIGHT_UPPER,170,77,true);
    CreateButtonTemplate(0,"TempStats",154,30,STYLE_SOLID,3,BORDER_RAISED,clrNONE,clrGreen,clrWhite,CORNER_RIGHT_UPPER,167,79,true);
    CreateButtonClick(0,"Close All Order",143,21,"Bodoni MT Black",10,BORDER_RAISED,"Close All Order",clrNONE,clrRed,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,162,88,true,"Close All Order");
//--
    CreateButtonTemplate(0,"TemplateC",160,35,STYLE_SOLID,5,BORDER_RAISED,clrNONE,clrBurlyWood,clrWhite,CORNER_RIGHT_UPPER,170,109,true);
    CreateButtonTemplate(0,"TempStatC",154,30,STYLE_SOLID,3,BORDER_RAISED,clrNONE,clrGreen,clrWhite,CORNER_RIGHT_UPPER,167,111,true);
    CreateButtonClick(0,"Close All Profit",143,21,"Bodoni MT Black",10,BORDER_RAISED,"Close All Profit",clrNONE,clrRed,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,162,120,true,"Close All Profit");
//--
    DeletePanelButton();
    CreateButtonClick(0,"X",17,15,"Arial Black",12,BORDER_RAISED,"X",clrNONE,clrWhite,clrRed,ANCHOR_CENTER,CORNER_RIGHT_UPPER,27,31,true,"Close panel");
    //--
    ChartRedraw(0);
    //--
    return;
//---
   } //-end CreateManualPanel()
//---------//

void DisplayManualButton(void)
  {
//--
    DeleteButtonX();
    CreateButtonClick(0,"M",17,16,"Arial Black",11,BORDER_FLAT,"M",clrWhite,clrWhite,clrRed,ANCHOR_CENTER,CORNER_RIGHT_UPPER,61,21,true,"Open Manual Panel");
    CreateButtonClick(0,"C",17,16,"Arial Black",11,BORDER_FLAT,"C",clrWhite,clrWhite,clrRed,ANCHOR_CENTER,CORNER_RIGHT_UPPER,41,21,true,"Change Chart Symbol");
    CreateButtonClick(0,"R",17,16,"Arial Black",11,BORDER_FLAT,"R",clrWhite,clrWhite,clrRed,ANCHOR_CENTER,CORNER_RIGHT_UPPER,21,21,true,"Expert Remove");
    ChartRedraw(0);
    //--
    return;
//--
  } //-end DisplayManualButton()
//---------//

bool DisplayManualButton(string a,string b,string c)
  {
//--
   if(ObjectFind(0,a)<0 && ObjectFind(0,b)<0 && ObjectFind(0,c)<0 && !mc.PanelExtra)
      return(false);
   return(true);
//--
  } //-end DisplayManualButton()
//---------//

void DeleteButtonX(void)
  {
//--
    ObjectDelete(0,"X");
    //--
    ChartRedraw(0);
    //--
    return;
//--
  } //-end DeleteButtonX()
//---------//

void DeletePanelButton(void)
  {
//--
    ObjectDelete(0,"M");
    ObjectDelete(0,"C");
    ObjectDelete(0,"R");
    //--
    return;
//--
  } //-end DeletePanelButton()
//---------//

void CreateSymbolPanel()
  {
//---    
    //--
    ResetLastError();
    DeletePanelButton();
    int sydis=83;
    int tsatu=int(mc.sall/2);
    //--
    CreateButtonTemplate(0,"Template",180,367,STYLE_SOLID,5,BORDER_RAISED,clrYellow,clrBurlyWood,clrWhite,CORNER_RIGHT_UPPER,187,45,true);
    CreateButtonTemplate(0,"TempCCS",167,25,STYLE_SOLID,5,BORDER_RAISED,clrYellow,clrBlue,clrWhite,CORNER_RIGHT_UPPER,181,50,true);
    CreateButtonClick(0,"X",14,14,"Arial Black",10,BORDER_FLAT,"X",clrWhite,clrWhite,clrRed,ANCHOR_CENTER,CORNER_RIGHT_UPPER,22,48,true,"Close Symbol Panel");
    //--
    string chsym="Change SYMBOL";
    int cspos=int(181/2)+int(StringLen(chsym)/2);
    CreateButtontLable(0,"CCS","Bodoni MT Black",chsym,11,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,cspos,62,true,"Change Chart Symbol");
    //--
    for(int i=0; i<tsatu; i++)
      CreateButtonClick(0,mc.AS30[i],80,17,"Bodoni MT Black",8,BORDER_RAISED,mc.AS30[i],clrYellow,clrBlue,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,180,sydis+(i*22),true,"Change to "+mc.AS30[i]);
    //--
    for(int i=tsatu; i<mc.sall; i++)
      CreateButtonClick(0,mc.AS30[i],80,17,"Bodoni MT Black",8,BORDER_RAISED,mc.AS30[i],clrYellow,clrBlue,clrWhite,ANCHOR_CENTER,CORNER_RIGHT_UPPER,94,sydis+((i-15)*22),true,"Change to "+mc.AS30[i]);
    //--
    ChartRedraw(0);
    //--
    return;
//---
   } //-end CreateSymbolPanel()
//---------//

void CreateButtonClick(long   chartid, 
                       string button_name,
                       int    button_x_size,
                       int    button_y_size,
                       string button_font_model,
                       int    button_font_size,
                       int    button_border,
                       string button_name_text,
                       color  button_bord_color,
                       color  button_bg_color,
                       color  button_color,
                       int    button_anchor,
                       int    button_corner,
                       int    button_xdist,
                       int    button_ydist,
                       bool   button_hidden,
                       string tooltip)
  {
//---
    ObjectCreate(chartid,button_name,OBJ_BUTTON,0,0,0); // create button
    ObjectSetInteger(chartid,button_name,OBJPROP_XSIZE,WS(button_x_size)); 
    ObjectSetInteger(chartid,button_name,OBJPROP_YSIZE,button_y_size); 
    ObjectSetString(chartid,button_name,OBJPROP_TEXT,button_name_text); 
    ObjectSetString(chartid,button_name,OBJPROP_FONT,button_font_model);
    ObjectSetInteger(chartid,button_name,OBJPROP_FONTSIZE,button_font_size);
    ObjectSetInteger(chartid,button_name,OBJPROP_BORDER_TYPE,button_border);
    ObjectSetInteger(chartid,button_name,OBJPROP_BORDER_COLOR,button_bord_color);
    ObjectSetInteger(chartid,button_name,OBJPROP_BGCOLOR,button_bg_color); 
    ObjectSetInteger(chartid,button_name,OBJPROP_COLOR,button_color);
    ObjectSetInteger(chartid,button_name,OBJPROP_ANCHOR,button_anchor);
    ObjectSetInteger(chartid,button_name,OBJPROP_CORNER,button_corner); 
    ObjectSetInteger(chartid,button_name,OBJPROP_XDISTANCE,WS(button_xdist));
    ObjectSetInteger(chartid,button_name,OBJPROP_YDISTANCE,button_ydist);
    ObjectSetInteger(chartid,button_name,OBJPROP_HIDDEN,button_hidden);
    ObjectSetString(chartid,button_name,OBJPROP_TOOLTIP,tooltip);
    ChartRedraw(0);
    //--
    return;
//---
  } //-end CreateButtonClick()
//---------//

void CreateButtonTemplate(long chartid,
                          string obj_name,
                          int    x_size,
                          int    y_size,
                          int    style,
                          int    width,
                          int    border,
                          color  bordcolor,
                          color  bgcolor,
                          color  objcolor,
                          int    corner,
                          int    x_dist,
                          int    y_dist,
                          bool   hidden)
  {
//---
    ObjectCreate(chartid,obj_name,OBJ_RECTANGLE_LABEL,0,0,0); // create Rectangle Label
    ObjectSetInteger(chartid,obj_name,OBJPROP_XSIZE,WS(x_size)); 
    ObjectSetInteger(chartid,obj_name,OBJPROP_YSIZE,y_size);
    ObjectSetInteger(chartid,obj_name,OBJPROP_STYLE,style);
    ObjectSetInteger(chartid,obj_name,OBJPROP_WIDTH,width);
    ObjectSetInteger(chartid,obj_name,OBJPROP_BORDER_TYPE,border);
    ObjectSetInteger(chartid,obj_name,OBJPROP_BORDER_COLOR,bordcolor);
    ObjectSetInteger(chartid,obj_name,OBJPROP_BGCOLOR,bgcolor); 
    ObjectSetInteger(chartid,obj_name,OBJPROP_COLOR,objcolor);
    ObjectSetInteger(chartid,obj_name,OBJPROP_CORNER,corner); 
    ObjectSetInteger(chartid,obj_name,OBJPROP_XDISTANCE,WS(x_dist));
    ObjectSetInteger(chartid,obj_name,OBJPROP_YDISTANCE,y_dist);
    ObjectSetInteger(chartid,obj_name,OBJPROP_HIDDEN,hidden);
    ChartRedraw(0);
    //--
    return;
//---
   } //-end CreateButtonTemplate()
//---------//

void CreateButtontLable(long   chartid, 
                        string lable_name, 
                        string lable_font_model,
                        string lable_obj_text,
                        int    lable_font_size,
                        color  lable_color,
                        int    lable_anchor,
                        int    lable_corner,
                        int    lable_xdist,
                        int    lable_ydist,
                        bool   lable_hidden,
                        string tooltip)
  {  
//---
    ObjectDelete(chartid,lable_name);
    ObjectCreate(chartid,lable_name,OBJ_LABEL,0,0,0,0,0); // create Lable 
    ObjectSetInteger(chartid,lable_name,OBJPROP_FONTSIZE,lable_font_size); 
    ObjectSetString(chartid,lable_name,OBJPROP_FONT,lable_font_model);
    ObjectSetString(chartid,lable_name,OBJPROP_TEXT,lable_obj_text);
    ObjectSetInteger(chartid,lable_name,OBJPROP_COLOR,lable_color);
    ObjectSetInteger(chartid,lable_name,OBJPROP_ANCHOR,lable_anchor);
    ObjectSetInteger(chartid,lable_name,OBJPROP_CORNER,lable_corner);
    ObjectSetInteger(chartid,lable_name,OBJPROP_XDISTANCE,WS(lable_xdist));
    ObjectSetInteger(chartid,lable_name,OBJPROP_YDISTANCE,lable_ydist);
    ObjectSetInteger(chartid,lable_name,OBJPROP_HIDDEN,lable_hidden);
    ObjectSetString(chartid,lable_name,OBJPROP_TOOLTIP,tooltip);
    ChartRedraw(0);
    //--
    return;
//---
  } //-end CreateButtontLable()   
//---------//
//--------------------------------------------------------------------//