//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

// Параметры
extern int rsiPeriod = 14; // период RSI
extern double oversoldLevel = 30; // уровень перекупленности
extern double overboughtLevel = 70; // уровень перепроданности
extern double riskPercent = 2; // процент риска на одну сделку
//extern double stopLoss = 2; // множитель для расчета стоп-лосса
extern double takeProfit = 100; // множитель для расчета тейк-профита
extern int trendPeriod = 50; // период скользящей средней для определения тренда
//extern double minTrendStrength = 0.8; // минимальная сила тренда для открытия позиции

double lotSize = 0.1;

// Переменные
int magicNumber = 12345; // уникальный идентификатор для ордеров
int trendDirection = 0; // направление тренда (1 - восходящий, -1 - нисходящий)

// Функция OnTick
void OnTick()
  {
// Проверяем, есть ли уже открытая позиция
   if(OrdersTotal() > 0)
     {
      return;
     }

// Определяем направление тренда
   double trendMA = iMA(NULL, 0, trendPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   double trendStrength = iStdDev(NULL, 0, trendPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   if(Ask > trendMA + trendStrength && Bid > trendMA + trendStrength)
     {
      trendDirection = 1;
     }
   else
      if(Ask < trendMA - trendStrength && Bid < trendMA - trendStrength)
        {
         trendDirection = -1;
        }
      else
        {
         return; // нет явного тренда
        }

// Вычисляем значение индикатора RSI
   double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);

// Проверяем, превышает ли RSI значение уровня oversold или overbought
   if(trendDirection == 1 && rsiValue < oversoldLevel)
     {
      // Вычисляем размер лота на основе текущего баланса
      //double lotSize = NormalizeDouble(AccountBalance() * riskPercent / 100 / (stopLossMultiplier * Point), 2);

      // Вычисляем стоп-лосс и тейк-профит
      //double stopLoss = stopLossMultiplier * Point;
      //double takeProfit = takeProfitMultiplier * Point;

      // Открываем позицию на покупку
      // Открываем позицию на покупку
      //int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, (Ask - stopLoss, Digits), NormalizeDouble(Ask + takeProfit, Digits), "Buy", magicNumber, 0, Green);
      int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Bid - takeProfit * Point, Bid + takeProfit * Point, "My Order", 16384, Green);
      
      // Проверяем, удалось ли открыть ордер
      if(ticket > 0)
        {
         Print("Order opened: ", OrderTicket());
        }
      else
        {
         Print("Order error: ", GetLastError());
        }
     }
   else
      if(trendDirection == -1 && rsiValue > overboughtLevel)
        {
         // Вычисляем размер лота на основе текущего баланса
         //double lotSize = NormalizeDouble(AccountBalance() * riskPercent / 100 / (stopLossMultiplier * Point), 2);

         // Вычисляем стоп-лосс и тейк-профит
         //stopLoss = stopLossMultiplier * Point;
         //takeProfit = takeProfitMultiplier * Point;

         // Открываем позицию на продажу
         //ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, NormalizeDouble(Bid + stopLoss, Digits), NormalizeDouble(Bid - takeProfit, Digits), "Sell", magicNumber, 0, Red);
         ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Ask + takeProfit * Point, Ask - takeProfit * Point, "My Order", 16384, Red);
         // Проверяем, удалось ли открыть ордер
         if(ticket > 0)
           {
            Print("Order opened: ", OrderTicket());
           }
         else
           {
            Print("Order error: ", GetLastError());
           }
        }
  }

// Функция OnInit
void OnInit()
  {
// Устанавливаем магический номер для ордеров
   if(magicNumber == 0)
     {
      magicNumber = MathRand();
     }
  }



// Функция OnTimer
void OnTimer()
  {
// Обновляем магический номер для ордеров каждые 5 минут
   if(TimeMinute(TimeCurrent()) % 5 == 0)
     {
      magicNumber = MathRand();
     }
  }


// Функция для нормализации числа с учетом точности символа
//double NormalizeDouble(double value, int digits)
  //{
   //return MathRound(value * MathPow(10, digits)) / MathPow(10, digits);
  //}
//+------------------------------------------------------------------+
