//+------------------------------------------------------------------+
//|                                                         NN_3.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


// объявляем константы
#define INPUT_SIZE 4   // размер входного слоя нейронной сети
#define HIDDEN_SIZE 4  // размер скрытого слоя нейронной сети
#define OUTPUT_SIZE 1  // размер выходного слоя нейронной сети
#define LEARNING_RATE 0.01  // скорость обучения нейронной сети

input int StopLoss = 150;

// объявляем глобальные переменные
double inputs[INPUT_SIZE];  // входные данные для нейронной сети
double hidden[HIDDEN_SIZE];  // выход скрытого слоя нейронной сети
double weights_ih[INPUT_SIZE][HIDDEN_SIZE];  // веса между входным и скрытым слоями нейронной сети
double weights_ho[HIDDEN_SIZE][OUTPUT_SIZE];  // веса между скрытым и выходным слоями нейронной сети
double bias_h[HIDDEN_SIZE];  // смещение для скрытого слоя нейронной сети
double bias_o[OUTPUT_SIZE];  // смещение для выходного слоя нейронной сети
double targets[OUTPUT_SIZE];  // целевые значения для нейронной сети
double outputs[OUTPUT_SIZE];  // выходные значения нейронной сети
double errors[OUTPUT_SIZE];  // ошибки нейронной сети
double delta_h[HIDDEN_SIZE];  // дельты для скрытого слоя нейронной сети
double delta_o[OUTPUT_SIZE];  // дельты для выходного слоя нейронной сети
double take_profit;  // уровень take profit

// функция инициализации нейронной сети
void init_neural_network()
  {
// инициализируем веса между входным и скрытым слоями нейронной сети
   for(int i = 0; i < INPUT_SIZE; i++)
     {
      for(int j = 0; j < HIDDEN_SIZE; j++)
        {
         weights_ih[i][j] = MathRandNormal(0, 1);
        }
     }

// инициализируем веса между скрытым и выходным слоями нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      for(int j = 0; j < OUTPUT_SIZE; j++)
        {
         weights_ho[i][j] = MathRandNormal(0, 1);
        }
     }



// инициализируем смещение для скрытого слоя нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      bias_h[i] = MathRandNormal(0, 1);
     }

// инициализируем смещение для выходного слоя нейронной сети
   for(int i = 0; i < OUTPUT_SIZE; i++)
     {
      bias_o[i] = MathRandNormal(0, 1);
     }


  }

// функция прямого распространения сигнала в нейронной сети
void feedforward()
  {
// прямое распространение сигнала от входного слоя к скрытому слою
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      double sum = 0;
      for(int j = 0; j < INPUT_SIZE; j++)
        {
         sum += inputs[j] * weights_ih[j][i];
        }
      sum += bias_h[i];
      hidden[i] = sigmoid(sum);
     }

// прямое распространение сигнала от скрытого слоя к выходному слою
   for(int i = 0; i < OUTPUT_SIZE; i++)
     {
      double sum = 0;
      for(int j = 0; j < HIDDEN_SIZE; j++)
        {
         sum += hidden[j] * weights_ho[j][i];
        }
      sum += bias_o[i];
      outputs[i] = sigmoid(sum);
     }

  }

// функция обратного распространения ошибки в нейронной сети
void backpropagation()
  {
// вычисляем ошибки выходного слоя нейронной сети
   for(int i = 0; i < OUTPUT_SIZE; i++)
     {
      errors[i] = targets[i] - outputs[i];
      delta_o[i] = errors[i] * d_sigmoid(outputs[i]);
     }

// вычисляем ошибки скрытого слоя нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      double error = 0;
      for(int j = 0; j < OUTPUT_SIZE; j++)
        {
         error += delta_o[j] * weights_ho[i][j];
        }
      delta_h[i] = error * d_sigmoid(hidden[i]);
     }

// обновляем веса между скрытым и выходным слоями нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      for(int j = 0; j < OUTPUT_SIZE; j++)
        {
         weights_ho[i][j] += hidden[i] * delta_o[j] * LEARNING_RATE;
        }
     }

// обновляем веса между входным и скрытым слоями нейронной сети
   for(int i = 0; i < INPUT_SIZE; i++)
     {
      for(int j = 0; j < HIDDEN_SIZE; j++)
        {
         weights_ih[i][j] += inputs[i] * delta_h[j] * LEARNING_RATE;
        }
     }

// обновляем смещения для выход
// обновляем смещения для выходного слоя нейронной сети
   for(int i = 0; i < OUTPUT_SIZE; i++)
     {
      bias_o[i] += errors[i] * LEARNING_RATE;
     }

// обновляем веса между скрытым и выходным слоями нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      for(int j = 0; j < OUTPUT_SIZE; j++)
        {
         weights_ho[i][j] += hidden[i] * errors[j] * LEARNING_RATE;
        }
     }

// обновляем дельты для скрытого слоя нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      delta_h[i] = 0.0;
      for(int j = 0; j < OUTPUT_SIZE; j++)
        {
         delta_h[i] += errors[j] * weights_ho[i][j];
        }
      delta_h[i] *= d_sigmoid(hidden[i]);
     }

// обновляем смещения для скрытого слоя нейронной сети
   for(int i = 0; i < HIDDEN_SIZE; i++)
     {
      bias_h[i] += delta_h[i] * LEARNING_RATE;
     }
     
     // обновляем смещения для выходного слоя нейронной сети
    for (int i = 0; i < OUTPUT_SIZE; i++) {
        bias_o[i] += LEARNING_RATE * delta_o[i];
    }

// обновляем веса между входным и скрытым слоями нейронной сети
   for(int i = 0; i < INPUT_SIZE; i++)
     {
      for(int j = 0; j < HIDDEN_SIZE; j++)
        {
         weights_ih[i][j] += inputs[i] * delta_h[j] * LEARNING_RATE;
        }
     }

  }

// функция для вычисления Take Profit на основе результатов выхода нейронной сети
double calculate_take_profit()
  {
// вычисляем Take Profit на основе выхода нейронной сети
   double output = outputs[0];
   double take_profit = output * 100;

// ограничиваем Take Profit до 3% от текущей цены
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double max_take_profit = price * 0.03;
   if(take_profit > max_take_profit)
     {
      take_profit = max_take_profit;
     }

   return take_profit;
  }



// основная функция торгового робота
void OnTick()
  {
// обновляем входные данные для нейронной сети
   inputs[0] = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   inputs[1] = iMA(NULL, 0, 100, 0, MODE_SMA, PRICE_CLOSE, 0);
   inputs[2] = iMA(NULL, 0, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   inputs[3] = iADX(NULL, 0, 14, PRICE_CLOSE, MODE_MAIN, 0);

// запускаем нейронную сеть
   feedforward();

// вычисляем Take Profit на основе результатов выхода нейронной сети
   take_profit = calculate_take_profit();

// открываем позицию, если нет открытых позиций
   if(OrdersTotal() == 0)
     {
      if(outputs[0] > 0)
        {
         OrderSend(Symbol(), OP_BUY, 0.1, Ask, 10, StopLoss, take_profit);
        }
      else
         if(outputs[0] < 0)
           {
            OrderSend(Symbol(), OP_SELL, 0.1, Bid, 10, StopLoss, take_profit);
           }
     }
  }
//+------------------------------------------------------------------+

double MathRandNormal(double mean, double stddev)
  {
   static double n2 = 0.0;
   static int n2_cached = 0;
   if(!n2_cached)
     {
      double x, y, r;
      do
        {
         x = 2.0 * MathRand() / 32767.0 - 1;
         y = 2.0 * MathRand() / 32767.0 - 1;
         r = x * x + y * y;
        }
      while(r == 0.0 || r > 1.0);
      double d = sqrt(-2.0 * log(r) / r);
      double n1 = x * d;
      n2 = y * d;
      double result = n1 * stddev + mean;
      n2_cached = 1;
      return result;
     }
   else
     {
      n2_cached = 0;
      return n2 * stddev + mean;
     }
  }
  
  
  // Функция для вычисления значения sigmoid
double sigmoid(double x)
  {
   return 1.0 / (1.0 + MathExp(-x));
  }

// Функция для вычисления производной sigmoid
double d_sigmoid(double y)
  {
   return y * (1.0 - y);
  }

