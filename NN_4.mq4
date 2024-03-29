//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


// Объявление глобальных переменных
#define trainSize 30000 // размер обучающей выборки
#define numFeatures 4 // количество признаков
#define numHidden 50 // количество нейронов в скрытом слое
#define numOutput 1 // количество выходных нейронов
input double learningRate = 0.05; // коэффициент обучения
input double takeProfitMultiplier = 1.5;
input int stopLoss = 150;
input int TakeProfit = 100;

// Объявление переменных
int i, j, k;
double inputs[trainSize][numFeatures];
double output[trainSize][numOutput];
double hidden[numHidden];
double weights1[numFeatures][numHidden];
double weights2[numHidden][numOutput];
double bias1[numHidden];
double bias2[numOutput];
double error[numOutput];
double delta2[numOutput];
double delta1[numHidden];
double sum;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

// Инициализация весов и смещений
   for(i = 0; i < numFeatures; i++)
     {
      for(j = 0; j < numHidden; j++)
        {
         weights1[i][j] = RandomDouble(-1.0, 1.0);
        }
     }
   for(i = 0; i < numHidden; i++)
     {
      for(j = 0; j < numOutput; j++)
        {
         weights2[i][j] = RandomDouble(-1.0, 1.0);
        }
     }
   for(i = 0; i < numHidden; i++)
     {
      bias1[i] = RandomDouble(-1.0, 1.0);
     }
   for(i = 0; i < numOutput; i++)
     {
      bias2[i] = RandomDouble(-1.0, 1.0);
     }

// Получение и обработка исторических данных
   for(i = 0; i < trainSize; i++)
     {
      inputs[i][0] = iOpen(NULL, PERIOD_H1, i);
      inputs[i][1] = iHigh(NULL, PERIOD_H1, i);
      inputs[i][2] = iLow(NULL, PERIOD_H1, i);
      inputs[i][3] = iClose(NULL, PERIOD_H1, i);
      output[i][0] = iClose(NULL, PERIOD_H1, i + 1) - iClose(NULL, PERIOD_H1, i);
     }

   //TrainNeuralNetwork();

   return(INIT_SUCCEEDED);
  }



// Функция обучения нейронной сети
void TrainNeuralNetwork()
  {
   for(i = 0; i < trainSize; i++)
     {
      // Прямое распространение
      for(j = 0; j < numHidden; j++)
        {
         sum = 0.0;
         for(k = 0; k < numFeatures; k++)
           {
            sum += inputs[i][k] * weights1[k][j];
           }
         hidden[j] = Sigmoid(sum + bias1[j]);
        }
      sum = 0.0;
      for(j = 0; j < numHidden; j++)
        {
         sum += hidden[j] * weights2[j][0];
        }
      double predicted = Sigmoid(sum + bias2[0]);

      // Обратное распрост
      // Обратное распространение
      error[0] = predicted - output[i][0];
      delta2[0] = error[0] * SigmoidDerivative(predicted);
      for(j = 0; j < numHidden; j++)
        {
         delta1[j] = 0.0;
         for(k = 0; k < numOutput; k++)
           {
            delta1[j] += delta2[k] * weights2[j][k];
           }
         delta1[j] *= SigmoidDerivative(hidden[j]);
        }
      for(j = 0; j < numHidden; j++)
        {
         for(k = 0; k < numOutput; k++)
           {
            weights2[j][k] -= learningRate * delta2[k] * hidden[j];
           }
        }
      for(j = 0; j < numFeatures; j++)
        {
         for(k = 0; k < numHidden; k++)
           {
            weights1[j][k] -= learningRate * delta1[k] * inputs[i][j];
           }
        }
      for(j = 0; j < numOutput; j++)
        {
         bias2[j] -= learningRate * delta2[j];
        }
      for(j = 0; j < numHidden; j++)
        {
         bias1[j] -= learningRate * delta1[j];
        }

      //Print(error[0] + " === " + i);
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(OrdersTotal() == 0)
     {

      TrainNeuralNetwork();

      // Получение текущих ценовых данных
      double open = iOpen(NULL, PERIOD_H1, 0);
      double high = iHigh(NULL, PERIOD_H1, 0);
      double low = iLow(NULL, PERIOD_H1, 0);
      double close = iClose(NULL, PERIOD_H1, 0);

      // Получение предсказания нейронной сети для следующей свечи
      double inputo[numFeatures];
      inputo[0] = open;
      inputo[1] = high;
      inputo[2] = low;
      inputo[3] = close;
      double sum = 0.0;
      double hidden[numHidden];
      for(int j = 0; j < numHidden; j++)
        {
         sum = 0.0;
         for(int k = 0; k < numFeatures; k++)
           {
            sum += inputo[k] * weights1[k][j];
           }
         hidden[j] = Sigmoid(sum + bias1[j]);
        }
      sum = 0.0;
      for(j = 0; j < numHidden; j++)
        {
         sum += hidden[j] * weights2[j][0];
        }
      double predicted = Sigmoid(sum + bias2[0]);

      double predictedChange = predicted * (iClose(NULL, PERIOD_H1, 0) - iOpen(NULL, PERIOD_H1, 0)); // предсказанное изменение цены в пунктах
      double takeProfit = iClose(NULL, PERIOD_H1, 0) + predictedChange * takeProfitMultiplier; // расчет Take Profit на основе предсказанного изменения цены и множителя Take Profit
      //Print(takeProfit + " ===== TAKA PROFITA");
      // Выполнение торговых действий на основе предсказания нейронной сети
      if(predicted > 0.5)
        {
         // Открытие позиции на покупку

         bool buyOrder = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 3, Bid - stopLoss * _Point, Bid + TakeProfit * _Point, "Neural Network Trading", 888, 0, Green);
         if(!buyOrder)
           {
            Print("Error opening buy order: ", GetLastError());
           }
        }
      else
         if(predicted < 0.5)
           {
            // Открытие позиции на продажу


            bool sellOrder = OrderSend(Symbol(), OP_SELL, 0.1, Bid, 3, Ask + stopLoss * _Point, Ask - TakeProfit * _Point, "Neural Network Trading", 888, 0, Red);
            if(!sellOrder)
              {
               Print("Error opening sell order: ", GetLastError());
              }
           }
     }
  }

// Функция RandomDouble
double RandomDouble(double min, double max)
  {
   return min + (max - min) * MathRand() / 32767.0;
  }
//+------------------------------------------------------------------+

// Функция для вычисления значения sigmoid
double Sigmoid(double x)
  {
   return 1.0 / (1.0 + MathExp(-x));
  }

// Функция для вычисления производной sigmoid
double SigmoidDerivative(double y)
  {
   return y * (1.0 - y);
  }
//+------------------------------------------------------------------+
