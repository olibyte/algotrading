//+------------------------------------------------------------------+
//|                                                    FVBO_test.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
//--- input parameters
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
// decide entry price SL and target price
// Function for Short Entry
void calculateShortEntryParams(double &entry_price, double &sl_price, double &sl_size, double &tsl_size)
{
    if (PositionGetDouble(POSITION_VOLUME) == 0 && closed_above_bb)
    {
        short_entry = true;
        entry_price = PRICE_LOW;
        sl_price = PRICE_HIGH;
        sl_size = MathAbs(entry_price - sl_price);
        tsl_size = sl_size * sl_trail_pct;
    }
}
// Function for Long Entry
void calculateLongEntryParams(double &entry_price, double &sl_price, double &sl_size, double &tsl_size)
{
    if (PositionGetDouble(POSITION_VOLUME) == 0 && closed_below_bb)
    {
        long_entry = true;
        entry_price = PRICE_HIGH;
        sl_price = PRICE_LOW;
        sl_size = MathAbs(entry_price - sl_price);
        tsl_size = sl_size * sl_trail_pct;
    }
}
// risk evaluation to check Risk:Reward based on values mentioned in settings
// entry level to middle BB distance should be N times of sl size where N is controllable from settings
// Function for Risk Evaluation
bool checkRiskReward(double entry_price, double sl_price, double mBB0, bool long_entry, bool short_entry, double reward_limit)
{
    if (long_entry)
    {
        return (mBB0 - entry_price) >= ((entry_price - sl_price) * reward_limit);
    }
    else if (short_entry)
    {
        return (entry_price - mBB0) >= ((sl_price - entry_price) * reward_limit);
    }

    return false;
}
// if Risk:Reward is not as per defined value then do not place order
// Function to check Risk:Reward and disable entry if not met
void checkRiskRewardAndDisable(bool &long_entry, bool &short_entry, double entry_price, double sl_price, double mBB0, double reward_limit)
{
    // Check risk:reward
    bool risk_reward_ok = checkRiskReward(entry_price, sl_price, mBB0, long_entry, short_entry, reward_limit);

    // Disable entry if risk:reward is not met
    if (!risk_reward_ok)
    {
        long_entry  = false;
        short_entry = false;
    }
}
// Function to send a trade request using MqlTradeRequest structure
void OpenPositionRequest(double requestedVolume, double requestedPrice, double sl, double tp)
{
    // Create MqlTradeRequest and MqlTradeResult structures
    MqlTradeRequest request = { };
    MqlTradeResult result = { };

    // Fill in the necessary fields for opening a position
    request.action = ENUM_TRADE_REQUEST_ACTIONS::TRADE_ACTION_DEAL; // Open position
    request.symbol = Symbol(); // Symbol name
    request.volume = requestedVolume; // Requested volume in lots
    request.price = requestedPrice; // Requested price
    request.sl = sl; // Stop Loss level
    request.tp = tp; // Take Profit level
    request.deviation = 5; // Maximal possible deviation from the requested price in points
    request.type = ENUM_ORDER_TYPE::ORDER_TYPE_BUY; // Order type (Buy in this case)
    request.type_filling = ENUM_ORDER_TYPE_FILLING::ORDER_FILLING_FOK; // Order execution type (Fill or Kill)

    // Send the trade request
    if (OrderSend(request, result))
    {
        // Trade request was successful
        Print("Trade request sent successfully. Order ticket: ", result.order);
    }
    else
    {
        // Trade request failed, print error information
        Print("Trade request failed. Error code: ", GetLastError());
    }
}

// Function to calculate Long Entry parameters and send trade request
void calculateAndEnterLong(int qty, double &entry_price, double &sl_price, double &sl_size, double &tsl_size)
{
// Check if a new position can be opened for a Long Entry
    if (PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE::POSITION_TYPE_BUY && closed_below_bb)
    {
        // Set Long Entry flag and calculate entry parameters
        long_entry = true;
        entry_price = PRICE_HIGH;
        sl_price = PRICE_LOW;
        sl_size = MathAbs(entry_price - sl_price);
        tsl_size = sl_size * sl_trail_pct;

        // Send the trade request for Long Entry
        OpenPositionRequest(qty, entry_price, sl_price, entry_price + tsl_size);
    }
}

// Function to calculate Short Entry parameters and send trade request
void calculateAndEnterShort(int qty, double &entry_price, double &sl_price, double &sl_size, double &tsl_size)
{
    // Check if a new position can be opened for a Short Entry
    if (PositionGetDouble(POSITION_VOLUME) == 0 && closed_above_bb)
    {
        // Set Short Entry flag and calculate entry parameters
        short_entry = true;
        entry_price = PRICE_LOW;
        sl_price = PRICE_HIGH;
        sl_size = MathAbs(entry_price - sl_price);
        tsl_size = sl_size * sl_trail_pct;

        // Send the trade request for Short Entry
        OpenPositionRequest(qty, entry_price, sl_price, entry_price - tsl_size);
    }
}


// Function to calculate position size and exit prices for both Long and Short entries
void calculatePositionAndExits(
    bool long_entry, bool short_entry,                       // Flags indicating Long and Short entries
    double entry_price, double sl_price, double sl_size,     // Entry and Stop Loss prices, Stop Loss size
    double exit_1_pft_pct, double exit_2_pft_pct,            // Profit percentages for Exit 1 and Exit 2
    double exit_1_qty_pct, double exit_2_qty_pct,            // Quantity percentages for Exit 1 and Exit 2
    double fund, double risk_limit,                          // Available fund and risk limit percentage
    double &qty, double &exit_1_qty, double &exit_2_qty, double &exit_3_qty,  // Output: Position size and Exit quantities
    double &exit_1_price, double &exit_2_price)              // Output: Exit prices
{
    // Check if a new position can be opened
    if ((long_entry || short_entry) && PositionGetDouble(POSITION_VOLUME) == 0)
    {
        // Calculate position size based on fund, risk limit, and price difference
        qty = floor((fund * (risk_limit / 100)) / ((MathAbs(entry_price - sl_price)) * SymbolInfoDouble(_Symbol, SYMBOL_POINT)));
        
        // Calculate exit quantities based on position size and specified percentages
        exit_1_qty = MathRound(qty * (exit_1_qty_pct / 100));
        exit_2_qty = MathRound(qty * (exit_2_qty_pct / 100));
        exit_3_qty = qty - (exit_1_qty + exit_2_qty);

        // Calculate exit prices based on entry price, Stop Loss size, and profit percentages
        if (long_entry)
        {
            exit_1_price = entry_price + (sl_size * exit_1_pft_pct);
            exit_2_price = entry_price + (sl_size * exit_2_pft_pct);
        }
        else if (short_entry)
        {
            exit_1_price = entry_price - (sl_size * exit_1_pft_pct);
            exit_2_price = entry_price - (sl_size * exit_2_pft_pct);
        }
    }
}


// Function to check quantity and disable trades if qty < 1
void checkQuantity(double qty, bool &long_entry, bool &short_entry)
{
    if (qty < 1)
    {
        long_entry = false;
        short_entry = false;
    }
}
// Function to trail stop loss after 1st target is hit
void trailSLAfterTarget(double &hold_high, double &hold_low, double tsl_size, double &sl_price, double high, double low)
{
    // Check if there is an open position
    if (PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE::POSITION_TYPE_BUY && high > sl_price && MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty)
    {
        // Reset hold_high and hold_low when no open position
        if (MathAbs(PositionGetDouble(POSITION_VOLUME)) == 0)
        {
            hold_high = 0;
            hold_low = 0;
        }

        // Update hold_high if the current high is greater than the stored hold_high or it's the first update
        if (high > hold_high || hold_high == 0)
            hold_high = high;

        // Adjust stop loss to trail the high
        sl_price = hold_high - tsl_size;
    }
    // Check if the position is a Sell and the current low is less than the stop loss
    else if (PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE::POSITION_TYPE_SELL && low < sl_price && MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty)
    {
        // Reset hold_high and hold_low when no open position
        if (MathAbs(PositionGetDouble(POSITION_VOLUME)) == 0)
        {
            hold_high = 0;
            hold_low = 0;
        }

        // Update hold_low if the current low is less than the stored hold_low or it's the first update
        if (low < hold_low || hold_low == 0)
            hold_low = low;

        // Adjust stop loss to trail the low
        sl_price = hold_low + tsl_size;
    }
}


// Function to handle long position exit logic
void handleLongExit(double &hold_high, double &sl_price, double tsl_size, double exit_1_price, double high, int qty)
{
    // Check if the position is a Buy, there is an open position, the current high is greater than the first exit price, and the position size is less than 'qty'
    if (PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE::POSITION_TYPE_BUY && PositionGetDouble(POSITION_VOLUME) > 0 && high > exit_1_price && MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty)
    {
        // Update hold_high if the current high is greater than the stored hold_high or it's the first update
        if (high > hold_high || hold_high == 0)
            hold_high = high;

        // Adjust stop loss to trail the high
        sl_price = hold_high - tsl_size;
    }
}

// Function to handle short position exit logic
void handleShortExit(double &hold_low, double &sl_price, double tsl_size, double exit_1_price, double low, int qty)
{
    // Check if the position is a Sell, there is an open position, the current low is less than the first exit price, and the position size is less than 'qty'
    if (PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE::POSITION_TYPE_SELL && PositionGetDouble(POSITION_VOLUME) > 0 && low < exit_1_price && MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty)
    {
        // Update hold_low if the current low is less than the stored hold_low or it's the first update
        if (low < hold_low || hold_low == 0)
            hold_low = low;

        // Adjust stop loss to trail the low
        sl_price = hold_low + tsl_size;
    }
}


// Function for Long Entry
void EnterLong(int qty, double entry_price)
{
    // Check if it's a valid long entry and there is no open position
    if (long_entry && PositionGetDouble(POSITION_VOLUME) == 0)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel any existing "BUY" orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "BUY"
            if (magic == EXPERT_MAGIC && StringFind(OrderSymbol(), "BUY") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new long order with specified quantity and stop loss at the entry price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = qty;  // Requested volume in lots
        request.price = entry_price;  // Requested price
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_BUY;  // Order type (Buy in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "BUY @ " + DoubleToString(entry_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }
}


// Function for Short Entry
void EnterShort(int qty, double entry_price)
{
    // Check if it's a valid short entry and there is no open position
    if (short_entry && PositionGetDouble(POSITION_VOLUME) == 0)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel any existing "SELL" orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "SELL"
            if (magic == EXPERT_MAGIC && StringFind(OrderSymbol(), "SELL") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new short order with specified quantity and stop loss at the entry price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = qty;  // Requested volume in lots
        request.price = entry_price;  // Requested price
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_SELL;  // Order type (Sell in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "SELL @ " + DoubleToString(entry_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }
}


// exit at SL
// Function to Set SL Hit Flag to False
void resetSLHitFlag()
{
    sl_hit_flag = false;
}
// Function to Handle Exit at SL for Long Position
void ExitAtSLForLong()
{
    // Check if there is a long position, and the original SL type is "Last Traded Price"
    if (PositionGetDouble(POSITION_TYPE) == POSITION_BUY && PositionGetDouble(POSITION_VOLUME) > 0 && original_sl_type == "Last Traded Price")
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel any existing "EXIT at SL" orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT at SL"
            if (magic == EXPERT_MAGIC && StringFind(OrderSymbol(), "EXIT at SL") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new short order to exit at SL with the position size and SL price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = MathAbs(PositionGetDouble(POSITION_VOLUME));  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = sl_price;  // Stop Loss level
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_SELL;  // Order type (Sell in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT SL @ " + DoubleToString(sl_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to Handle Exit at SL for Short Position
void ExitAtSLForShort()
{
    // Check if there is a short position, and the original SL type is "Last Traded Price"
    if (PositionGetDouble(POSITION_TYPE) == POSITION_SELL && PositionGetDouble(POSITION_VOLUME) < 0 && original_sl_type == "Last Traded Price")
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel any existing "EXIT at SL" orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT at SL"
            if (magic == EXPERT_MAGIC && StringFind(OrderSymbol(), "EXIT at SL") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new long order to exit at SL with the position size and SL price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = MathAbs(PositionGetDouble(POSITION_VOLUME));  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = sl_price;  // Stop Loss level
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_BUY;  // Order type (Buy in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT SL @ " + DoubleToString(sl_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to Handle Exit at SL for Long Position based on Close Price
void ExitAtSLForLongClosePrice()
{
    // Check if there is a long position, the original SL type is "Close Price," and close price is below SL
    if (PositionGetDouble(POSITION_TYPE) == POSITION_BUY &&
        PositionGetDouble(POSITION_VOLUME) > 0 &&
        original_sl_type == "Close Price" &&
        close < sl_price)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel other pending exit orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 1" or "EXIT 2"
            if (magic == EXPERT_MAGIC && (StringFind(OrderSymbol(), "EXIT 1") != -1 || StringFind(OrderSymbol(), "EXIT 2") != -1))
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new short order to exit at SL with the position size and SL price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = MathAbs(PositionGetDouble(POSITION_VOLUME));  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = sl_price;  // Stop Loss level
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_SELL;  // Order type (Sell in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT SL @ " + DoubleToString(sl_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
        sl_hit_flag = true;
    }
}


// Function to Handle Exit at SL for Short Position based on Close Price
void ExitAtSLForShortClosePrice()
{
    // Check if there is a short position, the original SL type is "Close Price," and close price is above SL
    if (PositionGetDouble(POSITION_TYPE) == POSITION_SELL &&
        PositionGetDouble(POSITION_VOLUME) < 0 &&
        original_sl_type == "Close Price" &&
        close > sl_price)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Cancel other pending exit orders
        int total = OrdersHistoryTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 1" or "EXIT 2"
            if (magic == EXPERT_MAGIC && (StringFind(OrderSymbol(), "EXIT 1") != -1 || StringFind(OrderSymbol(), "EXIT 2") != -1))
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new long order to exit at SL with the position size and SL price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = MathAbs(PositionGetDouble(POSITION_VOLUME));  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = sl_price;  // Stop Loss level
        request.tp = 0;  // Take Profit level (0 for market order)
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_BUY;  // Order type (Buy in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT SL @ " + DoubleToString(sl_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
        sl_hit_flag = true;
    }
}


//exit at target
// Function to Handle Exit at Target for Long Position
void ExitAtTargetForLong()
{
    // Check if there is a long position with the full position size and SL has not been hit
    if (PositionGetDouble(POSITION_TYPE) == POSITION_BUY &&
        PositionGetDouble(POSITION_VOLUME) > 0 &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) == qty &&
        !sl_hit_flag)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Get the total number of placed pending orders
        int total = OrdersHistoryTotal();

        // Iterate over all placed pending orders
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 1"
            if (magic == EXPERT_MAGIC && OrderType() == ORDER_TYPE_SELL && StringFind(OrderSymbol(), "EXIT 1") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new short order to exit at Target 1 with the specified quantity and limit price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = exit_1_qty;  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = exit_1_price;  // Take Profit level
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_SELL;  // Order type (Sell in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT TG1 @ " + DoubleToString(exit_1_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to Handle Exit at Target 2 for Long Position
void ExitAtTarget2ForLong()
{
    // Check if there is a long position with a partial position size between Target 2 and SL has not been hit
    if (PositionGetDouble(POSITION_TYPE) == POSITION_BUY &&
        PositionGetDouble(POSITION_VOLUME) > 0 &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) > exit_3_qty &&
        !sl_hit_flag)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Get the total number of placed pending orders
        int total = OrdersHistoryTotal();

        // Iterate over all placed pending orders
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 2"
            if (magic == EXPERT_MAGIC && OrderType() == ORDER_TYPE_SELL && StringFind(OrderSymbol(), "EXIT 2") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new short order to exit at Target 2 with the specified quantity and limit price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = exit_2_qty;  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = exit_2_price;  // Take Profit level
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_SELL;  // Order type (Sell in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT TG2 @ " + DoubleToString(exit_2_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to Handle Exit at Target 1 for Short Position
void ExitAtTarget1ForShort()
{
    // Check if there is a short position with the full position size and SL has not been hit
    if (PositionGetDouble(POSITION_TYPE) == POSITION_SELL &&
        PositionGetDouble(POSITION_VOLUME) < 0 &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) == qty &&
        !sl_hit_flag)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Get the total number of placed pending orders
        int total = OrdersHistoryTotal();

        // Iterate over all placed pending orders
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 1"
            if (magic == EXPERT_MAGIC && OrderType() == ORDER_TYPE_BUY && StringFind(OrderSymbol(), "EXIT 1") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new long order to exit at Target 1 with the specified quantity and limit price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = exit_1_qty;  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = exit_1_price;  // Take Profit level
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_BUY;  // Order type (Buy in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT TG1 @ " + DoubleToString(exit_1_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to Handle Exit at Target 2 for Short Position
void ExitAtTarget2ForShort()
{
    // Check if there is a short position with a partial position size between Target 2 and SL has not been hit
    if (PositionGetDouble(POSITION_TYPE) == POSITION_SELL &&
        PositionGetDouble(POSITION_VOLUME) < 0 &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) < qty &&
        MathAbs(PositionGetDouble(POSITION_VOLUME)) > exit_3_qty &&
        !sl_hit_flag)
    {
        // Declare and initialize the trade request and result of the trade request
        MqlTradeRequest request = { };
        MqlTradeResult result = { };

        // Get the total number of placed pending orders
        int total = OrdersHistoryTotal();

        // Iterate over all placed pending orders
        for (int i = total - 1; i >= 0; i--)
        {
            ulong order_ticket = OrderGetTicket(i);  // Order ticket
            ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

            // If the MagicNumber matches and the order is of type "EXIT 2"
            if (magic == EXPERT_MAGIC && OrderType() == ORDER_TYPE_BUY && StringFind(OrderSymbol(), "EXIT 2") != -1)
            {
                // Zeroing the request and result values
                ZeroMemory(request);
                ZeroMemory(result);

                // Setting the operation parameters
                request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
                request.order = order_ticket;  // Order ticket

                // Send the request
                if (!OrderSend(request, result))
                    PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

                // Information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
            }
        }

        // Place a new long order to exit at Target 2 with the specified quantity and limit price
        request.action = TRADE_ACTION_DEAL;  // Open position
        request.symbol = Symbol();  // Symbol name
        request.volume = exit_2_qty;  // Requested volume in lots
        request.price = 0;  // Requested price (0 for market order)
        request.sl = 0;  // Stop Loss level (0 for market order)
        request.tp = exit_2_price;  // Take Profit level
        request.deviation = 5;  // Maximal possible deviation from the requested price in points
        request.type = ORDER_TYPE_BUY;  // Order type (Buy in this case)
        request.type_filling = ORDER_FILLING_FOK;  // Order execution type (Fill or Kill)
        request.comment = "EXIT TG2 @ " + DoubleToString(exit_2_price, _Digits);

        // Send the trade request
        if (!OrderSend(request, result))
            PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

        // Information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);

        // Reset flags for conditions related to closing positions
        closed_above_bb = false;
        closed_below_bb = false;
    }
}


// Function to cancel all pending "SELL" orders
void CancelShortOrders()
{
    // Declare and initialize the trade request and result of the trade request
    MqlTradeRequest request = { };
    MqlTradeResult result = { };

    // Get the total number of placed pending orders
    int total = OrdersHistoryTotal();

    // Iterate over all placed pending orders
    for (int i = total - 1; i >= 0; i--)
    {
        ulong order_ticket = OrderGetTicket(i);  // Order ticket
        ulong magic = OrderGetInteger(ORDER_MAGIC);  // MagicNumber of the order

        // If the MagicNumber matches and the order is of type "SELL"
        if (magic == EXPERT_MAGIC && OrderType() == ORDER_TYPE_SELL)
        {
            // Zeroing the request and result values
            ZeroMemory(request);
            ZeroMemory(result);

            // Setting the operation parameters
            request.action = TRADE_ACTION_REMOVE;  // Type of trade operation
            request.order = order_ticket;  // Order ticket

            // Send the request
            if (!OrderSend(request, result))
                PrintFormat("OrderSend error %d", GetLastError());  // If unable to send the request, output the error code

            // Information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
        }
    }
}
