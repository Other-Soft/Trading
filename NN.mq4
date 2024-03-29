// Step 1: Define neural network architecture
int input_size = 3;
int hidden_size = 5;
int output_size = 1;
double inputs[];
double weights1[][5];//hidden size
double biases1[];
double hidden[];
double weights2[][1];// output_size
double biases2[];

int ticket;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   ArrayResize(inputs, input_size);
   ArrayResize(weights1, input_size);
   ArrayResize(biases1, hidden_size);
   ArrayResize(hidden, hidden_size);
   ArrayResize(weights2, hidden_size);
   ArrayResize(biases2, output_size);

// Step 2: Initialize weights and biases
   for(int i = 0; i < input_size; i++)
     {
      for(int j = 0; j < hidden_size; j++)
        {
         weights1[i][j] = MathRand() - 0.5;
        }
     }
   for(i = 0; i < hidden_size; i++)
     {
      biases1[i] = MathRand() - 0.5;
     }
   for(i = 0; i < hidden_size; i++)
     {
      for(j = 0; j < output_size; j++)
        {
         weights2[i][j] = MathRand() - 0.5;
        }
     }
   for(i = 0; i < output_size; i++)
     {
      biases2[i] = MathRand() - 0.5;
     }

   Train();

   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Train()
  {
// Step 3: Load historical data and prepare input/output pairs
   const int data_size = 1000;
   double inputs_data[1000][3];//input_size
   double targets_data[1000][1];
   for(int i = 0; i < data_size; i++)
     {
      inputs_data[i][0] = iOpen("EURUSD", PERIOD_M15, i);
      inputs_data[i][1] = iMA("EURUSD", PERIOD_M15, 200, 0, MODE_SMA, PRICE_CLOSE, i);
      inputs_data[i][2] = iVolume("EURUSD", PERIOD_M15, i);
      targets_data[i][0] = iClose("EURUSD", PERIOD_M15, i + 1) - iClose("EURUSD", PERIOD_M15, i);
     }


////////////////////////////////////////////////////
// Step 4: Train the neural network
   const int epochs = 5000;
   double learning_rate = 0.1;
   for(int epoch = 0; epoch < epochs; epoch++)
     {
      double error = 0.0;
      for(i = 0; i < data_size - 1; i++)
        {
         // Forward pass
         inputs[0] = inputs_data[i][0];
         inputs[1] = inputs_data[i][1];
         inputs[2] = inputs_data[i][2];
         for(int j = 0; j < hidden_size; j++)
           {
            double sum = 0.0;
            for(int k = 0; k < input_size; k++)
              {
               sum += inputs[k] * weights1[k][j];
              }
            hidden[j] = sigmoid(sum + biases1[j]);
           }
         double output = 0.0;
         for(j = 0; j < output_size; j++)
           {
            sum = 0.0;
            for(k = 0; k < hidden_size; k++)
              {
               sum += hidden[k] * weights2[k][j];
              }
            output = sigmoid(sum + biases2[j]);
           }

         // Backward pass
         double target = targets_data[i][0];
         double error_i = target - output;

         //+------------------------------------------------------------------+

         //+------------------------------------------------------------------+

         //+------------------------------------------------------------------+
         for(j = 0; j < output_size; j++)
           {
            double delta2 = error_i * dsigmoid(output) * hidden[j];
            biases2[j] += learning_rate * delta2;
            for(k = 0; k < hidden_size; k++)
              {
               weights2[k][j] += learning_rate * delta2 * hidden[k];
              }
           }
         for(j = 0; j < hidden_size; j++)
           {
            sum = 0.0;
            for(k = 0; k < output_size; k++)
              {
               sum += weights2[j][k] * error_i * dsigmoid(output) * hidden[j];
              }
            double delta1 = dsigmoid(hidden[j]) * sum;
            biases1[j] += learning_rate * delta1;
            for(k = 0; k < input_size; k++)
              {
               weights1[k][j] += learning_rate * delta1 * inputs[k];
              }
           }
         error += error_i * error_i;
        }
      error /= data_size;
      if(epoch % 100 == 0)
        {
         Print("Epoch: ", epoch, ", Error: ", error);
        }
     }

   Ebat();

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double sigmoid(double x)
  {
   return 1.0 / (1.0 + MathExp(-x));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dsigmoid(double y)
  {
// y - это значение, возвращаемое функцией sigmoid
   return y * (1.0 - y);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ebat()
  {

// Step 5: Make trading decisions based on the neural network output
   int lot_size = 0.1;
   while(true)
     {
      inputs[0] = iOpen("EURUSD", PERIOD_M15, 0);
      inputs[1] = iMA("EURUSD", PERIOD_M15, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
      inputs[2] = iVolume("EURUSD", PERIOD_M15, 0);
      for(int j = 0; j < hidden_size; j++)
        {
         double sum = 0.0;
         for(int k = 0; k < input_size; k++)
           {
            sum += inputs[k] * weights1[k][j];
           }
         hidden[j] = sigmoid(sum + biases1[j]);
        }
      double output = 0.0;
      for(j = 0; j < output_size; j++)
        {
         sum = 0.0;
         for(k = 0; k < hidden_size; k++)
           {
            sum += hidden[k] * weights2[k][j];
           }
         output = sigmoid(sum + biases2[j]);
        }
      if(output > 0.5)
        {
         // Buy EURUSD
         double open_price = Ask;
         double stop_loss = 100;
         double take_profit = 100;
         //OrderSend("EURUSD", OP_BUY, 0.1, open_price, 0, stop_loss, take_profit, "Neural Network", 0, 0, Green);
         ticket = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 3, Bid - stop_loss * Point, Bid + take_profit * Point, "Buy order", 0, 0, Green);
        }
      else
         if(output < 0.5)
           {
            // Sell EURUSD
            open_price = Bid;
            stop_loss = 100;
            take_profit = 100;
            //OrderSend("EURUSD", OP_SELL, 0.1, open_price, 0, stop_loss, take_profit, "Neural Network", 0, 0, Red);
            ticket = OrderSend(Symbol(), OP_SELL, 0.1, Bid, 3, Ask + stop_loss * Point, Ask - take_profit * Point, "Sell order", 0, 0, Red);
           }
      Sleep(1000 * 60 * 15); // Wait for 15 minutes
      ClosePosition();
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePosition()
  {
   // закрываем позицию
        if(OrderType() == OP_BUY)
        {
            if(!OrderClose(ticket, 0.1, Bid, 3, Red))
            {
               Print("PIZDEC");
            }
        }
        else if(OrderType() == OP_SELL)
        {
            if(!OrderClose(ticket, 0.1, Ask, 3, Green))
            {
               Print("PIZDEC");
            }
        }
  }
