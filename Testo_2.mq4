
// Переменные для настроек
extern int rsiPeriod = 14;            // Период RSI
extern double oversoldLevel = 30;     // Уровень перепроданности
extern double overboughtLevel = 70;   // Уровень перекупленности
extern double riskPercent = 2.0;      // Процент риска на одну сделку

// Параметры для открытия позиции
//extern double stopLoss = 50;          // Уровень стоп-лосса в пунктах
extern double takeProfit = 100;       // Уровень тейк-профита в пунктах

double lotSize = 0.1;
int magicNumber = 1234;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
// Проверяем возможность открытия позиций
   checkOpenPosition();

// Проверяем возможность закрытия позиций
   checkClosePosition();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkOpenPosition()
  {
// Проверяем, есть ли уже открытая позиция
   if(OrdersTotal() > 0)
     {
      return;
     }

// Вычисляем значение индикатора RSI
   double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);

// Проверяем, превышает ли RSI значение уровня oversold
   if(rsiValue < oversoldLevel)
     {
      // Вычисляем размер лота на основе текущего баланса
      //double lotSize = NormalizeDouble(AccountBalance() * riskPercent / 100 / (stopLoss * Point), 2);

      // Открываем позицию на покупку
      OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Bid - takeProfit * Point, Bid + takeProfit * Point, "My Order", 16384, Green);
     }
   else
      if(rsiValue > overboughtLevel)
        {
         // Вычисляем размер лота на основе текущего баланса
         //double lotSize = NormalizeDouble(AccountBalance() * riskPercent / 100 / (stopLoss * Point), 2);

         // Открываем позицию на продажу
         OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Ask + takeProfit * Point, Ask - takeProfit * Point, "My Order", 16384, Red);
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkClosePosition()
  {
  
// Проверяем, есть ли открытая позиция на покупку
   if(OrderType() == OP_BUY)
     {
      // Вычисляем значение индикатора RSI
      double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);

      // Проверяем, пересекает ли RSI уровень overbought снизу вверх
      if(rsiValue > overboughtLevel)
        {
         // Закрываем позицию на покупку
         OrderClose(OrderTicket(), OrderLots(), Bid, 3, Green);
        }
     }

// Проверяем, есть ли открытая позиция на продажу
   if(OrderType() == OP_SELL)
     {
      // Вычисляем значение индикатора RSI
      rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);

      // Проверяем, пересекает ли RSI уровень oversold сверху вниз
      if(rsiValue < oversoldLevel)
        {
         // Закрываем позицию на продажу
         OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);
        }
     }
  }
//+------------------------------------------------------------------+
