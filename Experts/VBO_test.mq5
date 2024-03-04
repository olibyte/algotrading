#property description "Example of placing pending orders based on Bollinger Bands and Keltner Channel"
#property script_show_inputs
input ENUM_ORDER_TYPE orderType=ORDER_TYPE_BUY_STOP;   // order type

#define EXPERT_MAGIC 123456                             // MagicNumber of the expert
input int bbLength = 20;
input int bbStdDev = 2;
input int kcLength = 20;
input float kcMult = 1.5;
input int atrLength = 20;
input float fund = 1000000.0;
input float risk_limit = 1.5;
input string original_sl_type = "Close Price";
input int dist_from_compression = 10;
input int dist_from_expansion = 5;
input float exit_1_pft_pct = 1.0;
input float exit_1_qty_pct = 50.0;
input float exit_2_pft_pct = 1.5;
input float exit_2_qty_pct = 25.0;
input float sl_trail_pct = 0.5;
input bool plotBB = true;
input bool plotKC = true;
input bool plotSignals = true;
input bool fillKC = true;
input bool showLevels = false;
input int Input1;

// strategy conditions
double mBB0, uBB0, lBB0, mKC0, uKC0, lKC0;
int bb_within_kc, bb_kc_count, outside_bb_count;
bool closed_above_bb, closed_below_bb, long_entry, short_entry, risk_reward_ok, sl_hit_flag;
double entry_price, sl_price, sl_size, tsl_size, hold_high, hold_low, exit_1_price, exit_2_price;
int qty, exit_1_qty, exit_2_qty, exit_3_qty;
// Enumeration for order types

// get current candle BB and KC values
// Function to calculate Bollinger Bands
void calculateBB(int length, double stdDev, double &middleBand, double &upperBand, double &lowerBand)
{
    //--- Calculate Bollinger Bands
    //--- Calculate Bollinger Bands
    middleBand = iMA(_Symbol, 0, length, 0, MODE_SMA, PRICE_CLOSE);
    double stdDeviation = iStdDev(_Symbol, 0, length, 0, MODE_SMA, PRICE_CLOSE);
    upperBand = middleBand + stdDev * stdDeviation;
    lowerBand = middleBand - stdDev * stdDeviation;
}

// Function to calculate Keltner Channel
void calculateKC(int length, double multiplier, double &middleChannel, double &upperChannel, double &lowerChannel)
{
    //--- Calculate Keltner Channel
    middleChannel = iMA(_Symbol, 0, length, 0, MODE_SMA, PRICE_CLOSE);
    double range = multiplier * iATR(_Symbol, 0, length);
    upperChannel = middleChannel + range;
    lowerChannel = middleChannel - range;
}
// check if BB is within KC
// Function to check if BB is within KC
void checkBBWithinKC(double &bb_within_kc, int &bb_kc_count, int &outside_bb_count, int bbLength, int kcLength, float kcMult, int atrLength)
{
    double uBB0, lBB0, uKC0, lKC0, mBB0, mKC0;

    // Calculate Bollinger Bands
    calculateBB(bbLength, 2, mBB0, uBB0, lBB0);

    // Calculate Keltner Channel
    calculateKC(kcLength, kcMult, mKC0, uKC0, lKC0);

    // Check if BB is within KC
    if (uBB0 < uKC0 || lBB0 > lKC0)
    {
        bb_within_kc = true;
        bb_kc_count = 0;
        outside_bb_count = 0;
    }
}
// keep a candle count after last bb within kc
// Function to update candle count after last BB within KC
void updateCandleCount(bool bb_within_kc, double uBB0, double uKC0, double lBB0, double lKC0, int &bb_kc_count)
{
    if (bb_within_kc && uBB0 > uKC0 && lBB0 < lKC0)
    {
        bb_kc_count++;
    }
}
// if candle count after last bb within kc is greater than N then mark the set up as invalid
// Function to check and mark the setup as invalid
void checkInvalidSetup(int bb_kc_count, int dist_from_compression, bool &bb_within_kc)
{
    if (bb_kc_count > dist_from_compression)
    {
        bb_within_kc = false;
    }
}
// check if a candle closes above BB and KC
// Function to check if a candle closes above BB and KC
void checkClosedAboveBBKC(bool bb_within_kc, double close, double uKC0, double uBB0, bool &closed_above_bb, bool &closed_below_bb)
{
    if (bb_within_kc && close > uKC0 && close > uBB0)
    {
        closed_above_bb = true;
        closed_below_bb = false; // avoid overlapping signals
    }
}
// check if a candle closes below BB and KC
// Function to check if a candle closes below BB and KC
void checkClosedBelowBBKC(bool bb_within_kc, double close, double lKC0, double lBB0, bool &closed_below_bb, bool &closed_above_bb)
{
    if (bb_within_kc && close < lKC0 && close < lBB0)
    {
        closed_below_bb = true;
        closed_above_bb = false; // avoid overlapping signals
    }
}
// if candle keeps closing outside BB and KC for continuous N candles then mark the set up as invalid
// Function to check if candles keep closing outside BB and KC for continuous N candles
void checkOutsideBBKCContinuous(int dist_from_expansion, bool &bb_within_kc, bool &closed_above_bb, bool &closed_below_bb, int &outside_bb_count)
{
    if (closed_above_bb || closed_below_bb)
    {
        outside_bb_count = outside_bb_count + 1;

        if (outside_bb_count > dist_from_expansion)
        {
            bb_within_kc = false;
            closed_above_bb = false;
            closed_below_bb = false;
        }
    }
}

// Function to check if Bollinger Bands are inside Keltner Channel
bool CheckBollingerInsideKeltner()
{
    double bb_within_kc = false;
    int bb_kc_count = 0;
    int outside_bb_count = 0;
    int bbLength = 20;    // Set your parameters
    int kcLength = 20;    // Set your parameters
    float kcMult = 2.0;   // Set your parameters
    int atrLength = 14;   // Set your parameters

    double uBB0, lBB0, uKC0, lKC0, mBB0, mKC0;

    // Calculate Bollinger Bands
    calculateBB(bbLength, 2, mBB0, uBB0, lBB0);

    // Calculate Keltner Channel
    calculateKC(kcLength, kcMult, mKC0, uKC0, lKC0);

    // Check if BB is within KC
    if (uBB0 < uKC0 || lBB0 > lKC0)
    {
        bb_within_kc = true;
        bb_kc_count = 0;
        outside_bb_count = 0;
    }

    return bb_within_kc;
}

// Function to check if the bar has closed outside Bollinger Bands and Keltner Channel
bool CheckClosedOutsideBands()
{
    bool closed_above_bb = false;
    bool closed_below_bb = false;
    int outside_bb_count = 0;
    bool bb_within_kc = CheckBollingerInsideKeltner();
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    double uKC0, uBB0, lKC0, lBB0;

    // Calculate Bollinger Bands
    calculateBB(20, 2, mBB0, uBB0, lBB0);

    // Calculate Keltner Channel
    calculateKC(20, 2.0, mKC0, uKC0, lKC0);

    // Check if a candle closes above BB and KC
    checkClosedAboveBBKC(bb_within_kc, close, uKC0, uBB0, closed_above_bb, closed_below_bb);

    // Check if a candle closes below BB and KC
    checkClosedBelowBBKC(bb_within_kc, close, lKC0, lBB0, closed_below_bb, closed_above_bb);

    // Check if candles keep closing outside BB and KC for continuous N candles
    checkOutsideBBKCContinuous(5, bb_within_kc, closed_above_bb, closed_below_bb, outside_bb_count);

    return (closed_above_bb || closed_below_bb);
}

//+------------------------------------------------------------------+
//| Placing pending orders based on Bollinger Bands and Keltner Channel|
//+------------------------------------------------------------------+
void OnStart()
{
    //--- declare and initialize the trade request and result of the trade request
    MqlTradeRequest request = {};
    MqlTradeResult result = {};

    // Additional conditions to place pending orders
    if (CheckClosedOutsideBands())
    {
        //--- parameters to place a pending order
        request.action = TRADE_ACTION_PENDING;                             // type of trade operation
        request.symbol = Symbol();                                         // symbol
        request.volume = 0.1;                                              // volume of 0.1 lot
        request.deviation = 2;                                             // allowed deviation from the price
        request.magic = EXPERT_MAGIC;                                      // MagicNumber of the order

        int offset = 50;                                                   // offset from the current price to place the order, in points
        double price;                                                      // order triggering price
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);            // value of point
        int digits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);            // number of decimal places (precision)

        // Check the type of order
        if (orderType == ORDER_TYPE_BUY_STOP)
        {
            // Place Buy Stop order
            request.type = ORDER_TYPE_BUY_STOP;
            price = SymbolInfoDouble(Symbol(), SYMBOL_ASK) + offset * point;
            request.price = NormalizeDouble(price, digits);

            //--- send the request
            if (!OrderSend(request, result))
                PrintFormat("Buy OrderSend error %d", GetLastError());

            //--- information about the operation
            PrintFormat("Buy Order: retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

            // Place Take Profit orders
            double takeProfit1 = price + (exit_1_pft_pct / 100.0) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double takeProfit2 = price + (exit_2_pft_pct / 100.0) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

            PlaceTakeProfitOrder(request, takeProfit1);
            PlaceTakeProfitOrder(request, takeProfit2);
        }
        else if (orderType == ORDER_TYPE_SELL_STOP)
        {
            // Place Sell Stop order
            request.type = ORDER_TYPE_SELL_STOP;
            price = SymbolInfoDouble(Symbol(), SYMBOL_ASK) - offset * point;
            request.price = NormalizeDouble(price, digits);

            //--- send the request
            if (!OrderSend(request, result))
                PrintFormat("Sell OrderSend error %d", GetLastError());

            //--- information about the operation
            PrintFormat("Sell Order: retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

            // Place Take Profit orders
            double takeProfit1 = price - (exit_1_pft_pct / 100.0) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double takeProfit2 = price - (exit_2_pft_pct / 100.0) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

            PlaceTakeProfitOrder(request, takeProfit1);
            PlaceTakeProfitOrder(request, takeProfit2);
        }
        else
        {
            Alert("This example is only for placing pending orders");
        }
    }
}

// Function to place Take Profit order
void PlaceTakeProfitOrder(MqlTradeRequest &request, double takeProfit)
{
    request.type = ORDER_TYPE_BUY_LIMIT;  // Default to Buy Limit order type for take profit

    // Set the order type based on the original order type
    if (request.type == ORDER_TYPE_BUY_STOP)
        request.type = ORDER_TYPE_BUY_LIMIT;
    else if (request.type == ORDER_TYPE_SELL_STOP)
        request.type = ORDER_TYPE_SELL_LIMIT;

    // Set the price for the take profit order
    request.price = NormalizeDouble(takeProfit, SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));

    //--- send the request
    MqlTradeResult result = {};
    if (!OrderSend(request, result))
        PrintFormat("Take Profit OrderSend error %d", GetLastError());

    //--- information about the operation
    PrintFormat("Take Profit Order: retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
}
