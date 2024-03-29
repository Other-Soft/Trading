// определение переменных
input double lotSize = 0.1;
input double stopLoss = 20;
input double takeProfit = 30;
input int RSI_period = 14;
input int RSI_level = 50;
input int stoch_period = 14;
input int stoch_k = 3;
input int stoch_d = 3;
input int stoch_slowing = 3;
input int stoch_level_low = 20;
input int stoch_level_high = 80;

void OnTick()
{
   start();
}

// функция для определения точки входа
int openPosition()
{
    double RSI = iRSI(NULL, 0, RSI_period, PRICE_CLOSE, 0);
    double stoch_main = iStochastic(NULL, 0, stoch_period, stoch_k, stoch_d, MODE_SMA, STO_LOWHIGH, 0, MODE_SIGNAL);
    double stoch_signal = iStochastic(NULL, 0, stoch_period, stoch_k, stoch_d, MODE_SMA, STO_CLOSECLOSE, stoch_slowing, MODE_SIGNAL);
    int ticket;
    if(RSI > RSI_level && stoch_main > stoch_level_high && stoch_signal > stoch_level_high)
    {
        // если RSI выше уровня, а оба индикатора Stochastic Oscillator также выше уровня, открываем позицию на покупку
        ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Bid - stopLoss * Point, Bid + takeProfit * Point, "Buy order", 0, 0, Green);
        return(ticket);
    }
    else if(RSI < RSI_level && stoch_main < stoch_level_low && stoch_signal < stoch_level_low)
    {
        // если RSI ниже уровня, а оба индикатора Stochastic Oscillator также ниже уровня, открываем позицию на продажу
        ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Ask + stopLoss * Point, Ask - takeProfit * Point, "Sell order", 0, 0, Red);
        return(ticket);
    }
    return(0);
}

// функция для определения точки выхода
void closePosition(int ticket)
{
    if(ticket > 0)
    {
        // закрываем позицию
        if(OrderType() == OP_BUY)
        {
            OrderClose(ticket, lotSize, Bid, 3, Red);
        }
        else if(OrderType() == OP_SELL)
        {
            OrderClose(ticket, lotSize, Ask, 3, Green);
        }
    }
}

// основная функция
void start()
{
    // определяем текущую позицию
    int ticket = OrderTicket();
    
    // если нет открытых позиций, открываем новую
    if(ticket == 0)
    {
        ticket = openPosition();
    }
    // если есть открытая
    else
    {
        // если есть открытая позиция, проверяем необходимость закрытия
        closePosition(ticket);
    }
}