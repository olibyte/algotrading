#include <Trade/Trade.mqh>

input bool initialPositionBuy = true;
input double buyTP = 15;
input double sellTP = 15;
input double buySellDiff = 15;
input double initialLotSize = 0.01;
input double lotSizeMultiplier = 2;



double A, B, C, D;
bool isPositionBuy;
bool hedgeCycleRunning = false;
double lastPositionLotSize;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
    return(INIT_SUCCEEDED);
   }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
    ObjectDelete(0, "A");
    ObjectDelete(0, "B");
    ObjectDelete(0, "C");
    ObjectDelete(0, "D");
   }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
    double _Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double _Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    if(!hedgeCycleRunning)
       {
        StartHedgeCycle();
       }

    if(_Bid <= C && !isPositionBuy)
       {
        double newPositionLotSize = NormalizeDouble(lastPositionLotSize * lotSizeMultiplier, 2);
        CTrade trade;
        trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, newPositionLotSize, _Bid, B, D);
        lastPositionLotSize = lastPositionLotSize * lotSizeMultiplier;
        isPositionBuy = isPositionBuy ? false : true;
       }
    
    if(_Ask >= B && isPositionBuy)
       {
        double newPositionLotSize = NormalizeDouble(lastPositionLotSize * lotSizeMultiplier, 2);
        CTrade trade;
        trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, newPositionLotSize, _Ask, C, A);
        lastPositionLotSize = lastPositionLotSize * lotSizeMultiplier;
        isPositionBuy = isPositionBuy ? false : true;
       }
    
if(_Bid >= A || _Ask <= D)
   {
    hedgeCycleRunning = false;
   }
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Hedge Cycle Intialization Function                               |
//+------------------------------------------------------------------+
void StartHedgeCycle()
   {
    isPositionBuy = initialPositionBuy;
    double initialPrice = isPositionBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    A = isPositionBuy ? initialPrice + buyTP * _Point * 10 : initialPrice + (buySellDiff + buyTP) * _Point * 10;
    B = isPositionBuy ? initialPrice : initialPrice + buySellDiff * _Point * 10;
    C = isPositionBuy ? initialPrice - buySellDiff * _Point * 10 : initialPrice;
    D = isPositionBuy ? initialPrice - (buySellDiff + sellTP) * _Point * 10 : initialPrice - sellTP * _Point * 10;

    ObjectCreate(0, "A", OBJ_HLINE, 0, 0, A);
    ObjectSetInteger(0, "A", OBJPROP_COLOR, clrGreen);
    ObjectCreate(0, "B", OBJ_HLINE, 0, 0, B);
    ObjectSetInteger(0, "B", OBJPROP_COLOR, clrGreen);
    ObjectCreate(0, "C", OBJ_HLINE, 0, 0, C);
    ObjectSetInteger(0, "C", OBJPROP_COLOR, clrGreen);
    ObjectCreate(0, "D", OBJ_HLINE, 0, 0, D);
    ObjectSetInteger(0, "D", OBJPROP_COLOR, clrGreen);

    ENUM_ORDER_TYPE positionType = isPositionBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    double SL = isPositionBuy ? C : B;
    double TP = isPositionBuy ? A : D;
    CTrade trade;
    trade.PositionOpen(_Symbol, positionType, initialLotSize, initialPrice, SL, TP);
    
    lastPositionLotSize = initialLotSize;
    if(trade.ResultRetcode() == 10009) hedgeCycleRunning = true;
    isPositionBuy = isPositionBuy ? false : true;
   }
//+------------------------------------------------------------------+
