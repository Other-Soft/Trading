//+------------------------------------------------------------------+
//|                                                         NN_5.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define p 64//64
#define countHiddenNeuron 24//24
#define trainSize 1024
#define predictBars 49

input double tpMultiplier = 1.0;
input bool readInitData = false;
input int takeProfit = 100;
input int stopLoss = 150;
input int orderThresold = 80;
input int pass = 30;
int maxTeach = 1000;
input int tradeTeachThresold = 100;
input int countPredictAnalysys = 6;
int maxEbala = 888;
input int predictShift = 3;

double wRange = 0.28;//0.9;

double weightsHidden[countHiddenNeuron][p];
double thresoldsHidden[countHiddenNeuron];
double weightedSums[countHiddenNeuron];
double outputsHidden[countHiddenNeuron];
double weightsOutputLayer[countHiddenNeuron];
double thresoldOutputLayer;
double yValues[trainSize - p];
double etalons[trainSize];

double offsetY = 0;// 0.195;
int countTeaches = 0;
double errIncrease = 0;

int ticket;
bool ebobo;
bool nonTeacheble;
double errGlobal;
int countTryed;
double tradeErrThresold = 0.235;//0.13
double teachErrThresold = 3.5;

double predictValues[predictBars];

//int lineIds[trainSize - p];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   InitBars();
//InitSin();
   InitWeights();

//DrawLines();
//Train();

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitWeights()
  {
   countTeaches = 0;
   errGlobal = 999;

   if(readInitData)
     {
      string strWeightsHidden;
      int handle;
      handle = FileOpen("weightsHidden.txt", FILE_TXT|FILE_READ);
      if(handle > 0)
        {
         strWeightsHidden = FileReadString(handle);
         Print(StringReplace(strWeightsHidden, "|=|", "=") + " Было произведено замен");
         string sep = "=";                // разделитель в виде символа
         ushort u_sep;                  // код символа разделителя
         string result[];               // массив для получения строк
         //--- получим код разделителя
         u_sep = StringGetCharacter(sep,0);
         //--- разобьем строку на подстроки
         int k = StringSplit(strWeightsHidden, u_sep, result) - 1;
         
         
         if(k != countHiddenNeuron * p)
           {
            Print("!!!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!!");
           }
         else
           {
            int idxRead = 0;
            for(int i=0; i < countHiddenNeuron; i++)
              {
               for(int j=0; j < p; j++)
                 {
                  weightsHidden[i][j] = StrToDouble(result[idxRead]);
                  idxRead++;
                 }
              }
           }
        }
      else
        {
         Print("Ebala Syet ************ " + GetLastError());
        }
      
      //==============================================================================
      string strThresoldsHidden;
      
      handle = FileOpen("thresoldsHidden.txt", FILE_TXT|FILE_READ);
      if(handle > 0)
      {
         strThresoldsHidden = FileReadString(handle);
         Print(StringReplace(strThresoldsHidden, "|=|", "=") + " Было произведено замен");
         string result[];
         int k = StringSplit(strThresoldsHidden, StringGetCharacter("=", 0), result) - 1;
         
         if(k != countHiddenNeuron)
         {
            Print("!!!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!!");
         }
         else
         {
            int idxRead = 0;
            for(int i=0; i<countHiddenNeuron; i++)
            {
               thresoldsHidden[i] = StrToDouble(result[idxRead]);
               idxRead++;
            }
         }
      }
      
      //==============================================================================
      string strWeightsOutputLayer;
      handle = FileOpen("weightsOutputLayer.txt", FILE_TXT|FILE_READ);
      if(handle > 0)
      {
         strWeightsOutputLayer = FileReadString(handle);
         Print(StringReplace(strWeightsOutputLayer, "|=|", "=") + " Было произведено замен");
         string result[];
         int k = StringSplit(strWeightsOutputLayer, StringGetCharacter("=", 0), result) - 1;
         
         if(k != countHiddenNeuron)
         {
            Print("!!!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!! ПИЗДЕЦ !!!!!!!!!!!!");
         }
         else
         {
            int idxRead = 0;
            for(int i=0; i<countHiddenNeuron; i++)
            {
               weightsOutputLayer[i] = StrToDouble(result[idxRead]);
               idxRead++;
            }
         }
      }
      
      
     }
   else
     {
      string opta = "";
      for(int i=0; i<countHiddenNeuron; i++)
      {
         for(int j=0; j<p; j++)
         {
            weightsHidden[i][j] = RandomDouble(-wRange, wRange);
            opta += weightsHidden[i][j] + "|=|";
         }
         thresoldsHidden[i] = RandomDouble(-wRange, wRange);
         weightsOutputLayer[i] = RandomDouble(-wRange, wRange);
      }

      WriteToFile(opta, "weightsHidden.txt");
   
      SaveThresoldsHidden();
      SaveWeightsOutputLayer();
      Print("======================================= Веса Инициализированы ===================================");
      
     }

//Print(opta);
  }

//----------------------------------------------------------------------
void SaveThresoldsHidden()
{
   string data = "";
   
   for(int i=0;i<countHiddenNeuron;i++)
     {
      data += thresoldsHidden[i] + "|=|";
     }
     
   WriteToFile(data, "thresoldsHidden.txt");
}
//-----------------------------------------------------------------------

void SaveWeightsOutputLayer()
{
   string data = "";
   
   for(int i=0;i<countHiddenNeuron;i++)
     {
      data += weightsOutputLayer[i] + "|=|";
     }
     
   WriteToFile(data, "weightsOutputLayer.txt");  
}

//-----------------------------------------------------------------------
void WriteToFile(string data, string fileName)
{
   FileDelete(fileName);
   int strLength = StringLen(data);
   int handle;
   handle = FileOpen(fileName, FILE_TXT|FILE_READ|FILE_WRITE,';');
   if(handle<1)
     {
      Print(fileName, " Файл не обнаружен, последняя ошибка ", GetLastError());
     }
   else
     {
      FileWriteString(handle, data, strLength);
      FileClose(handle);
      Print("Данные успешно записаны в файл ", fileName);
     }  
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitSin()
  {
   for(int i = 0; i < trainSize; i++)
     {

      float x = i;
      //float y = 1.8f * Mathf.Sin(1.3f * i);// + 0.5f;
      float y = 0.005f * MathSin(0.5f * x) + 1.096f;
      //y = Mathf.Clamp01(y);


      etalons[i] = y;
      //Print(etalons[i]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitBars()
  {

   for(int i=0; i<trainSize; i++)
     {
      int id = trainSize - i;// + predictBars;
      //etalons[i] = iClose(NULL, 0, id);
      etalons[i] = iMA(NULL,0,1,id,MODE_SMA,PRICE_CLOSE,0);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Train()
  {

// TEMP
   if(countTeaches > maxTeach)
     {
      //return;
     }

   if(errGlobal < tradeErrThresold)
     {
      //return;
     }

   for(int pox=0; pox < pass; pox++)

     {
      countTeaches++;

      //Print("Итерация " + countTeaches);

      errGlobal = 0;

      for(int iSample=0; iSample<trainSize-p; iSample++)
        {
         for(int i=0; i<countHiddenNeuron; i++)
           {
            double wSum = 0;
            for(int j=0; j<p; j++)
            {
               double x = etalons[j+iSample];
               wSum += weightsHidden[i][j] * x;
               //Print(weightsHidden[i][j]);
            }
            wSum -= thresoldsHidden[i];
            weightedSums[i] = wSum;
            outputsHidden[i] = Sigmoid(wSum);
           }

         double weightedSumOutputLayer = 0;
         for(int i=0; i<countHiddenNeuron; i++)
           {
            double x = outputsHidden[i];
            weightedSumOutputLayer += weightsOutputLayer[i] * x;
           }
         weightedSumOutputLayer -= thresoldOutputLayer;
         double outputMain = Sigmoid(weightedSumOutputLayer);

         yValues[iSample] = outputMain;


         // Change Weights and Bias
         double a = 0.08;//0.01
         double errOutput = outputMain - etalons[iSample + p];
         errGlobal += errOutput * errOutput;
         double errHiden[countHiddenNeuron];
         for(int i=0; i<countHiddenNeuron; i++)
           {
            errHiden[i] = errOutput * SigmoidDerivative(weightedSumOutputLayer) * weightsOutputLayer[i];
           }

         for(int i=0; i<countHiddenNeuron; i++)
           {
            double w = weightsOutputLayer[i] - a * errOutput * SigmoidDerivative(weightedSumOutputLayer) * outputsHidden[i];
           }

         thresoldOutputLayer = thresoldOutputLayer + a * errOutput * SigmoidDerivative(weightedSumOutputLayer);

         for(int i=0; i<countHiddenNeuron; i++)
           {
            for(int j=0; j<p; j++)
              {
               double w = weightsHidden[i][j];
               double x = etalons[j + iSample];
               w = w - a * errHiden[i] * SigmoidDerivative(weightedSums[i]) * x;
               weightsHidden[i][j] = w;
              }
            thresoldsHidden[i] = thresoldsHidden[i] + a * errHiden[i] * SigmoidDerivative(weightedSums[i]);
           }


         //Print(errOutput + " =====");
        }

      errGlobal *= 100;
      //Print("Итерация " + countTeaches + " === Ошибко " + errGlobal + " Шифт ошибки " + errIncrease);
     }

   Print("Итерация " + countTeaches + " === Ошибко " + errGlobal + " Попытка " + countTryed);

   if(errGlobal > teachErrThresold)// && countTryed < 100)
     {
      InitWeights();
      countTryed++;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Predict()
  {

   for(int pre=0; pre<predictBars; pre++)
     {

      double outH[countHiddenNeuron];
      for(int i=0; i<countHiddenNeuron; i++)
        {
         double wSum = 0;
         for(int j=0; j<p; j++)
           {
            double x = 0;
            int id = trainSize - p + j + pre;
            if(id >= trainSize)
              {
               x = predictValues[pre-1];
              }
            else
              {
               x = etalons[id];
              }

            wSum += weightsHidden[i][j] * x;
           }
         wSum -= thresoldsHidden[i];
         outH[i] = Sigmoid(wSum);
        }

      double weightedSumOutputLayer = 0;
      for(int i=0; i<countHiddenNeuron; i++)
        {
         double x = outH[i];
         weightedSumOutputLayer += weightsOutputLayer[i] * x;
        }
      weightedSumOutputLayer -= thresoldOutputLayer;
      double outputMain = Sigmoid(weightedSumOutputLayer);

      predictValues[pre] = outputMain;
     }


   if(errGlobal < tradeErrThresold)
      //if(countTeaches >= tradeTeachThresold)
     {
      Trade();
      //Print("================================");
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade()
  {

   if(OrdersTotal() > 0)
     {
      //return;
     }

   double curPrice = yValues[trainSize - p - 1];//iMA(NULL,0,1,0,MODE_SMA,PRICE_CLOSE,0);//yValues[trainSize - p -1];
   if(predictShift > 0)
     {
      curPrice = predictValues[predictShift - 1];
     }

   double sumLow = 0;
   double sumHigh = 0;
   int countLow = 0;
   int countHigh = 0;

   int total = predictBars > countPredictAnalysys ? countPredictAnalysys : predictBars;

   for(int i=0; i<total; i++)
     {
      if(predictValues[i + predictShift] > curPrice)
        {
         countHigh++;
         sumHigh += predictValues[i + predictShift];
        }
      else
        {
         countLow++;
         sumLow += predictValues[i + predictShift];
        }
     }

   int pipsHigh = 0;
   int pipsLow = 0;

   if(countHigh > 0)
     {
      double averageHigh = sumHigh / (double)countHigh;
      //Print(((averageHigh - curPrice) / _Point) + " +-+-+-+-+-+-+-+-+- ERR " + errGlobal);
      pipsHigh = (averageHigh - curPrice) / _Point;
     }
   if(countLow > 0)
     {
      double averageLow = sumLow / (double)countLow;
      //Print(((curPrice - averageLow) / _Point) + " ------------------ ERR " + errGlobal);
      pipsLow = (curPrice - averageLow) / _Point;
     }


   

   ebobo = false;
   if(pipsHigh - pipsLow > orderThresold)// && pipsHigh > takeProfit) // Оч важно
     {
      int t = pipsHigh > takeProfit ? takeProfit : pipsHigh * tpMultiplier;
      int s = pipsLow < stopLoss ? stopLoss : pipsLow;
      double sl = Bid - s * _Point;
      double tp = Bid + t *_Point;

      ticket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, sl, tp, "");
      //ticket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, tp, sl, "");
      ebobo = false;
     }
   else
      if(pipsLow - pipsHigh > orderThresold)// && pipsLow > takeProfit)
        {
         int t = pipsLow > takeProfit ? takeProfit : pipsLow * tpMultiplier;
         int s = pipsHigh < stopLoss ? stopLoss : pipsHigh;
         double sl = Ask + s * _Point;
         double tp = Ask - t *_Point;

         //ticket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, tp, sl, "");
         ticket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, sl, tp, "");
         ebobo = false;
        }

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(IsNewBar())
     {
      errGlobal = 999;
      countTryed = 0;
      nonTeacheble = false;
      ebobo = true;
      InitBars();
      if(countTeaches > maxTeach)
        {
         //InitWeights();
        }
     }

   if(ebobo && !nonTeacheble)
      //if(OrdersTotal() == 0 && ebobo && !nonTeacheble)
     {
      Train();
      Predict();
      DrawLines();
      DrawLinesNN();
      DrawLinesPredict();
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLines()
  {
   ObjectsDeleteAll();
//ClearChart();

   for(int i=0; i<trainSize-1; i++)
     {
      double x1 = Time[trainSize - i + predictBars];
      double y1 = etalons[i] + offsetY;
      double x2 = Time[trainSize - i + predictBars-1];
      double y2 = etalons[i+1] + offsetY;

      int id = ObjectCreate("Ebat" + i, OBJ_TREND, 0, x1, y1, x2, y2);
      if(id == 0)
        {
         Print(GetLastError());
        }

      ObjectSetString(0, "Ebat" + i, OBJPROP_TEXT, id);
      ObjectSet("Ebat" + i, OBJPROP_COLOR, clrBlue);
      ObjectSet("Ebat" + i, OBJPROP_WIDTH, 5);
      ObjectSet("Ebat" + i, OBJPROP_RAY, 0);

      //Print("рисуем, хуль.."+ id);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLinesNN()
  {

//ClearChart();
   int pass = trainSize-p-1;

   for(int i=0; i<pass; i++)
     {
      double x1 = Time[trainSize - i - p + predictBars];
      double y1 = yValues[i] + offsetY;
      double x2 = Time[trainSize - i - p + predictBars - 1];
      double y2 = yValues[i+1] + offsetY;

      int id = ObjectCreate("NN" + i, OBJ_TREND, 0, x1, y1, x2, y2);
      if(id == 0)
        {
         Print("Не удалось создать линию " + GetLastError());
        }

      ObjectSetString(0, "NN" + i, OBJPROP_TEXT, id);
      ObjectSet("NN" + i, OBJPROP_COLOR, clrYellow);
      ObjectSet("NN" + i, OBJPROP_WIDTH, 3);
      ObjectSet("NN" + i, OBJPROP_RAY, 0);

      //Print("рисуем, хуль.."+ id);
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLinesPredict()
  {
   for(int i=0; i<predictBars; i++)
     {

      double x1 = Time[predictBars - i +1];
      double y1 = i-1 < 0 ? yValues[trainSize - p -1] : predictValues[i-1];
      double x2 = Time[predictBars - i];
      double y2 = predictValues[i];

      int id = ObjectCreate("Predict" + i, OBJ_TREND, 0, x1, y1, x2, y2);
      if(id == 0)
        {
         Print("Не удалось создать линию " + GetLastError());
        }

      ObjectSetString(0, "Predict" + i, OBJPROP_TEXT, id);
      ObjectSet("Predict" + i, OBJPROP_COLOR, clrLimeGreen);
      ObjectSet("Predict" + i, OBJPROP_WIDTH, 3);
      ObjectSet("Predict" + i, OBJPROP_RAY, 0);

      //Print("рисуем, хуль.."+ id);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearChart()
  {
   for(int i=0; i<trainSize - p; i++)
     {
      int id = ObjectFind("Ebat"+i);
      Print("Удаляем обжект " + id + " =-=- " + GetLastError());
      if(id != 0)
        {
         ObjectDelete(id);
        }


     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RandomDouble(double min, double max)
  {
   return min + (max - min) * MathRand() / 32767.0;

  }
//+------------------------------------------------------------------+
// Функция для вычисления значения sigmoid
double Sigmoid(double x)
  {
//return 1.0 / (1.0 + MathExp(-x));
   if(x > 0)
      return x;
   else
      return 0.0001f;
  }

// Функция для вычисления производной sigmoid
double SigmoidDerivative(double y)
  {
//return y * (1.0 - y);
   if(y > 0)
      return 1;
   else
      return 0.0001f;
  }
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static int nBars = 0;
   if(nBars != Bars)
     {
      nBars = Bars;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+

//public static float ReLUActivation(float weightedSum)
//   {
//        if (weightedSum > 0)
//            return weightedSum;
//        else
//            return 0.01f;
//   }

//    float DerivativeReLU(float weightedSum)
//    {
//       if (weightedSum > 0)
//           return 1;
//       else
//           return 0.01f;
//   }
