
extern int MA1Period = 10; // период первой скользящей средней
extern int MA2Period = 20; // период второй скользящей средней
extern int MA3Period = 30; // период третьей скользящей средней
extern int MA4Period = 50; // период четвертой скользящей средней
extern int MA5Period = 100; // период пятой скользящей средней

input int stopLoss = 100;
input int takeProfit = 100;

double lotSize = 0.1;
// Переменные
int MagicNumber = 12345; // уникальный идентификатор для ордеров


// Функция OnTick
void OnTick()
  {
// Проверяем, есть ли уже открытая позиция
   if(OrdersTotal() > 0)
     {
      return;
     }


// Вычисляем значения скользящих средних
   double MA1 = iMA(NULL, 0, MA1Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA2 = iMA(NULL, 0, MA2Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA3 = iMA(NULL, 0, MA3Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA4 = iMA(NULL, 0, MA4Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA5 = iMA(NULL, 0, MA5Period, 0, MODE_SMA, PRICE_CLOSE, 0);

// Проверяем, происходит ли кроссинг скользящих средних
   if(MA1 > MA2 && MA2 > MA3 && MA3 > MA4 && MA4 > MA5)
     {
      // Определяем направление тренда (1 - восходящий, -1 - нисходящий)
      int trendDirection = 0;
      if(Ask > MA5)
        {
         trendDirection = 1;
        }
      else
         if(Bid < MA5)
           {
            trendDirection = -1;
           }
         else
           {
            return; // нет явного тренда
           }

      // Открываем позицию на покупку
      // Открываем позицию на покупку
      if(trendDirection == 1)
        {
         
  

         // Открываем позицию на покупку с учетом размера позиции и тейк-профита
         bool buyOrder = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 5, Bid - takeProfit * _Point, Bid + stopLoss * _Point, "Scalping Buy", MagicNumber, 0, Blue);
         if(buyOrder)
           {
            Print("Buy order opened: ", lotSize, " lots at ", Ask);
           }
         else
           {
            Print("Error opening buy order: ", GetLastError());
           }
        }
      // Открываем позицию на продажу
      else
         if(trendDirection == -1)
           {
            // Открываем позицию на продажу с учетом размера позиции и тейк-профита
            bool sellOrder = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 5, Ask + takeProfit * _Point, Ask - stopLoss * _Point, "Scalping Sell", MagicNumber, 0, Red);
            if(sellOrder)
              {
               Print("Sell order opened: ", lotSize, " lots at ", Bid);
              }
            else
              {
               Print("Error opening sell order: ", GetLastError());
              }
           }
         // Нет явного тренда, не открываем позицию
         else
           {
            return;
           }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
