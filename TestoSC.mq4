//+------------------------------------------------------------------+
//|                                                      TestoSC.mq4 |
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
// Инициализация переменных
double last_tick = 0;
int ticket = 0;
int slippage = 3; // Допустимый проскальзывание в пунктах
input int stop_loss = 50; // Размер стоп-лосса в пунктах
input int take_profit = 50; // Размер тейк-профита в пунктах

// Функция проверки цены
bool CheckPrice() {
  double current_price = MarketInfo(Symbol(), MODE_BID);
  if (current_price > last_tick) {
    // Цена выросла, открываем длинную позицию
    ticket = OrderSend(Symbol(), OP_BUY, 0.1, current_price, slippage, current_price - stop_loss * Point, current_price + take_profit * Point, "Scalping", 0, 0, Green);
    last_tick = current_price;
    if (ticket > 0) {
      Print("Открыта длинная позиция ", ticket);
      return true;
    } else {
      Print("Ошибка открытия длинной позиции ", GetLastError());
      return false;
    }
  } else if (current_price < last_tick) {
    // Цена упала, открываем короткую позицию
    ticket = OrderSend(Symbol(), OP_SELL, 0.1, current_price, slippage, current_price + stop_loss * Point, current_price - take_profit * Point, "Scalping", 0, 0, Red);
    last_tick = current_price;
    if (ticket > 0) {
      Print("Открыта короткая позиция ", ticket);
      return true;
    } else {
      Print("Ошибка открытия короткой позиции ", GetLastError());
      return false;
    }
  } else {
    // Цена не изменилась, не открываем позицию
    return false;
  }
}

// Функция закрытия позиции
bool ClosePosition() {
  if (OrderClose(ticket, OrderLots(), MarketInfo(ticket, MODE_BID), slippage, White)) {
    Print("Позиция ", ticket, " закрыта");
    return true;
  } else {
    Print("Ошибка закрытия позиции ", GetLastError());
    return false;
  }
}

// Функция OnTick
void OnTick() {
  if (0 == OrderTicket()) {
    // Позиция не открыта, проверяем цену
    CheckPrice();
  } else {
    // Позиция открыта, проверяем стоп-лосс и тейк-профит
    double current_price = MarketInfo(Symbol(), MODE_BID);
    double open_price = OrderOpenPrice();
    if (OrderType() == OP_BUY && (current_price - open_price) >= take_profit * Point) {
      // Длинная позиция достигла тейк-профита
      ClosePosition();
    } else if (OrderType() == OP_BUY && (open_price - current_price) >= stop_loss * Point) {
      // Длинная позиция достигла стоп-лосса
      ClosePosition();
    } else if (OrderType() == OP_SELL && (open_price - current_price) >= take_profit * Point) {
      // Короткая позиция достигла тейк-профита
      ClosePosition();
    } else if (OrderType() == OP_SELL && (current_price - open_price) >= stop_loss * Point) {
      // Короткая позиция достигла стоп-лосса
      ClosePosition();
    }
  }
}

// Функция OnInit
void OnInit() {
  last_tick = MarketInfo(Symbol(), MODE_BID);
}

// Функция OnDeinit
void OnDeinit(const int reason) {
  if (ticket > 0) {
    // Закрываем открытую позицию при завершении работы торгового робота
    ClosePosition();
  }
}

// Функция OnStart
void OnStart() {
  // Ничего не делаем, все операции выполняются в функции OnTick
}