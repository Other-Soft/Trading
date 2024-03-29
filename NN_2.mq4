//+------------------------------------------------------------------+
//|                                                         NN_2.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#define num_history 300
#define num_inputs 50
#define num_hidden 12
#define num_outputs 1

input int num_epoch = 3000;
input int StopLoss = 100;
input int TakeProfit = 100;

int ticket;

// Функция для вычисления значения sigmoid
double sigmoid(double x)
  {
   return 1.0 / (1.0 + MathExp(-x));
  }

// Функция для вычисления производной sigmoid
double dsigmoid(double y)
  {
   return y * (1.0 - y);
  }

// Главная функция
void OnTick()
  {

   if(fNewBar() && OrdersTotal() < 15)
     {

      // Загрузка исторических данных
      double history[num_history];
      int history_size = CopyClose(_Symbol, PERIOD_H1, 0, num_history, history);

      // Настройка нейронной сети
      
      
      double learning_rate = 0.05;

      // Инициализация весов
      double w_ih[num_inputs][num_hidden];
      double w_ho[num_hidden][1];
      for(int i = 0; i < num_inputs; i++)
        {
         for(int j = 0; j < num_hidden; j++)
           {
            w_ih[i][j] = MathRandNormal(0.0, 1.0);
           }
        }
      for(int i = 0; i < num_hidden; i++)
        {
         for(int j = 0; j < num_outputs; j++)
           {
            w_ho[i][j] = MathRandNormal(0.0, 1.0);
           }
        }

      // Обучение нейронной сети
      for(int epoch = 0; epoch < num_epoch; epoch++)
        {
        double error[1];
         for(int i = 0; i < history_size - num_inputs - num_outputs; i++)
           {
            // Входной слой
            double inputs[num_inputs];
            for(int j = 0; j < num_inputs; j++)
              {
               inputs[j] = history[i + j];
              }

            // Скрытый слой
            double hidden[num_hidden];
            for(int j = 0; j < num_hidden; j++)
              {
               double sum = 0.0;
               for(int k = 0; k < num_inputs; k++)
                 {
                  sum += inputs[k] * w_ih[k][j];
                 }
               hidden[j] = sigmoid(sum);
              }

            // Выходной слой
            double output[1];
            for(int j = 0; j < num_outputs; j++)
              {
               double sum = 0.0;
               for(int k = 0; k < num_hidden; k++)
                 {
                  sum += hidden[k] * w_ho[k][j];
                 }
               output[j] = sigmoid(sum);
              }

            // Вычисление ошибки
            double target[1];
            target[0] = history[i + num_inputs + num_outputs] > history[i + num_inputs] ? 1.0 : 0.0; // Если цена закрытия через n периодов выше, то 1, иначе 0
            
            for(int j = 0; j < num_outputs; j++)
              {
               error[j] = target[j] - output[j];
              }

            // Обратное распространение ошибки
            double delta_ho[num_hidden][1];
            for(int j = 0; j < num_outputs; j++)
              {
               for(int k = 0; k < num_hidden; k++)
                 {
                  delta_ho[k][j] = error[j] * dsigmoid(output[j]) * hidden[k];
                 }
              }

            double delta_ih[num_inputs][num_hidden];
            for(int j = 0; j < num_hidden; j++)
              {
               double sum = 0.0;
               for(int k = 0; k < num_outputs; k++)
                 {
                  sum += error[k] * dsigmoid(output[k]) * w_ho[j][k];
                 }
               for(int i = 0; i < num_inputs; i++)
                 {
                  delta_ih[i][j] = dsigmoid(hidden[j]) * inputs[i] * sum;
                 }
              }

            // Обновление весов
            for(int j = 0; j < num_hidden; j++)
              {
               for(int k = 0; k < num_outputs; k++)
                 {
                  w_ho[j][k] += learning_rate * delta_ho[j][k];
                 }
              }
            for(int j = 0; j < num_inputs; j++)
              {
               for(int k = 0; k < num_hidden; k++)
                 {
                  w_ih[j][k] += learning_rate * delta_ih[j][k];
                 }
              }
            

           }
           if(epoch % 100 == 0)
              {
               Print("Epoch: ", epoch, ", Error: ", error[0]);
              }

        }

      // Торговля с использованием нейронной сети
      double inputs[num_inputs];
      for(int i = 0; i < num_inputs; i++)
        {
         inputs[i] = history[history_size - num_inputs + i];
        }

      double hidden[num_hidden];
      for(int j = 0; j < num_hidden; j++)
        {
         double sum = 0.0;
         for(int k = 0; k < num_inputs; k++)
           {
            sum += inputs[k] * w_ih[k][j];
           }
         hidden[j] = sigmoid(sum);
        }

      double output[1];
      for(int j = 0; j < num_outputs; j++)
        {
         double sum = 0.0;
         for(int k = 0; k < num_hidden; k++)
           {
            sum += hidden[k] * w_ho[k][j];
           }
         output[j] = sigmoid(sum);
        }


      // Размещение ордера на покупку или продажу в зависимости от выхода нейронной сети
      if(OrdersTotal() < 15)
        {
         if(output[0] >= 0.5)
           {
            ticket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 10, Bid - StopLoss * _Point, Bid + TakeProfit * _Point);
           }
         else
           {
            ticket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 10, Ask + StopLoss * _Point, Ask - TakeProfit * _Point);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool fNewBar()
  {
   static datetime NewTime=0;
   if(NewTime!=Time[0])
     {
      if(NewTime==0)
        {
         NewTime=Time[0];
         return(false);
        }
      NewTime=Time[0];
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
