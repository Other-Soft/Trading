//+------------------------------------------------------------------+
//|                                                     RSI_OpTA.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                     scalp_robot.mq4|
//|                                      Copyright 2021, Your Name  |
//|                                        https://www.example.com   |
//+------------------------------------------------------------------+
#property copyright "2021, Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property strict

extern int Rsi_Thresold = 50;
extern int Sto_Thresold = 50;
extern int RsiPeriod = 14;
extern int StoPeriod = 14;
extern int StoSlowing = 3;
extern int MaPeriod = 200;
extern double LotSize = 0.01;
extern double StopLoss = 50;
extern double TakeProfit = 100;

double ma_buffer[];
int prev_calculated;

void OnInit()
{
   SetIndexBuffer(0, ma_buffer, INDICATOR_DATA);
    SetIndexStyle(0, DRAW_LINE);
    SetIndexDrawBegin(0, MaPeriod);
}


int start()
{
    int ticket;
    double rsi, stoch, ma;

    // Calculate the moving average
    if (Bars <= MaPeriod)
        return (0);

    int limit = Bars - prev_calculated;
    if (limit > MaPeriod)
        limit = MaPeriod;

    ma = iMA(NULL, 0, MaPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
    for (int i = 0; i < ArraySize(ma_buffer); i++)
        ma_buffer[i] = ma;
    prev_calculated = Bars;

    // Calculate the RSI and Stochastic indicators
    rsi = iRSI(NULL, 0, RsiPeriod, PRICE_CLOSE, 0);
    stoch = iStochastic(NULL, 0, StoPeriod, StoSlowing, 0, MODE_SMA, 0, MODE_SMA, 0);

    // Check for buy signal
    if (rsi > Rsi_Thresold && stoch > Sto_Thresold && Close[1] < ma)
    {
        // Check if there are no open orders
        if (OrdersTotal() == 0)
        {
            // Place a buy order
            ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 10, Bid - StopLoss * Point, Bid + TakeProfit * Point, "Buy", 0, 0, Green);
            if (ticket > 0)
                Print("Buy order opened with ticket #", ticket);
            else
                Print("Error opening buy order. Error code = ", GetLastError());
        }
    }
    // Check for sell signal
    else if (rsi < Rsi_Thresold && stoch < Sto_Thresold && Close[1] > ma)
    {
        // Check if there are no open orders
        if (OrdersTotal() == 0)
        {
            // Place a sell order
            ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 10, Ask + StopLoss * Point, Ask - TakeProfit * Point, "Sell", 0, 0, Red);
            if (ticket > 0)
                Print("Sell order opened with ticket #", ticket);
            else
                Print("Error opening sell order. Error code = ", GetLastError());
        }
    }

    return (0);
}



void OnTick()
  {
//---
   start();
  }
//+------------------------------------------------------------------+
