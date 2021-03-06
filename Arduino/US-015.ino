/* 
* Arduino Mega 2560 v3e
* US-015超声波测距模块 + 3色LED灯珠; 用于距离近就亮红灯, 距离中就亮绿灯, 距离远就亮蓝灯
* Len_mm = (Time_Echo_us * 0.34mm/us / 100) / 2 
* Len_cm = (Time_Echo_us * 0.34mm/us / 1000) / 2 
*/

const int EchoPin = 24;           // connect Pin 2(Arduino digital io) to Echo at US-015
const int TrigPin = 22;           // connect Pin 3(Arduino digital io) to Trig at US-015
unsigned long Time_Echo_us = 0;
unsigned long Len_cm  = 0;

const int RedLedPin = 48;       
const int GreenLedPin = 50;
const int BlueLedPin = 52;

void setup()
{  //Initialize
    Serial.begin(9600);                        //Serial: output result to Serial monitor
    pinMode(EchoPin, INPUT);                    //Set EchoPin as input, to receive measure result from US-015
    pinMode(TrigPin, OUTPUT);                   //Set TrigPin as output, used to send high pusle to trig measurement (>10us)

    pinMode(RedLedPin, OUTPUT);
    pinMode(GreenLedPin, OUTPUT);
    pinMode(BlueLedPin, OUTPUT);
}

void loop()
{
    digitalWrite(TrigPin, HIGH);              //begin to send a high pulse, then US-015 begin to measure the distance
    delayMicroseconds(20);                    //set this high pulse width as 20us (>10us)
    digitalWrite(TrigPin, LOW);               //end this high pulse

    digitalWrite(RedLedPin, LOW);   
    digitalWrite(GreenLedPin, LOW);   
    
    Time_Echo_us = pulseIn(EchoPin, HIGH);               // calculate the pulse width at EchoPin, 
    if((Time_Echo_us < 60000) && (Time_Echo_us > 1))     // a valid pulse width should be between (1, 60000).
      {
        Len_cm = (Time_Echo_us*34/1000)/2;      // calculate the distance by pulse width, Len_mm = (Time_Echo_us * 0.34mm/us) / 2 (mm)
        Serial.print("Present Distance is: ");  // output result to Serial monitor
        Serial.print(Len_cm, DEC);            // output result to Serial monitor 
        Serial.println(" cm");                 // output result to Serial monitor
      }
    if((Len_cm <= 30) && (Len_cm > 0))
      {
        digitalWrite(GreenLedPin,LOW);
        digitalWrite(BlueLedPin,LOW);
        digitalWrite(RedLedPin,HIGH);
        Serial.println("RedLed is turn on");
        }
    else if ((Len_cm > 30) && (Len_cm <=50))
      {
        digitalWrite(GreenLedPin,LOW);
        digitalWrite(BlueLedPin,HIGH);
        digitalWrite(RedLedPin,HIGH);
        }
    else if ((Len_cm > 50) && (Len_cm <= 80))
      {
        digitalWrite(RedLedPin,LOW);
        digitalWrite(BlueLedPin,LOW);
        digitalWrite(GreenLedPin,HIGH);
        Serial.println("GreenLed is turn on");
        }
     else if ((Len_cm > 80) && (Len_cm <=100))
      {
        digitalWrite(GreenLedPin,HIGH);
        digitalWrite(BlueLedPin,HIGH);
        digitalWrite(RedLedPin,HIGH);
        }  
     else if ((Len_cm > 100) && (Len_cm <= 120))
      {
        digitalWrite(RedLedPin,LOW);
        digitalWrite(GreenLedPin,LOW);
        digitalWrite(BlueLedPin,HIGH);
        Serial.println("BlueLed is turn on");
        }
      else if (Len_cm > 120)
        {
          digitalWrite(RedLedPin,HIGH);
          digitalWrite(GreenLedPin,HIGH);
          digitalWrite(BlueLedPin,HIGH);
          }
     else 
       {
        digitalWrite(RedLedPin,LOW);
        digitalWrite(GreenLedPin,LOW);
        digitalWrite(BlueLedPin,LOW);
        }
     delay(800);          // take a measurement every second 
     Len_cm = 0;          // 检测完清零,防止未检测时长亮
}
