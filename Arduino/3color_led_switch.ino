
const int RedPin = 5;
const int GreenPin = 6;
const int BluePin = 7;
const int TouchPin = 8;
int TouchPinStatusOld = 0;
int TouchPinStatusNew;

// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(9600);
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(RedPin, OUTPUT);
  pinMode(GreenPin, OUTPUT);
  pinMode(BluePin, OUTPUT);
  pinMode(TouchPin, INPUT);
}

int a = 1;
// the loop function runs over and over again forever
void loop() {
  
  TouchPinStatusNew = digitalRead(TouchPin);
  if(TouchPinStatusNew != TouchPinStatusOld)
  {
    TouchPinStatusOld = TouchPinStatusNew;
    // 初始化LED
    digitalWrite(RedPin,LOW);
    digitalWrite(GreenPin,LOW);
    digitalWrite(BluePin,LOW);
    
    switch(a)
    {
      case 1:
        digitalWrite(RedPin,HIGH);
        Serial.print("RedLED is turn on 1 seconds; status : ");
        Serial.println(digitalRead(RedPin));
        delay(1000);
        digitalWrite(RedPin,LOW);
        a++;
        break;
      case 2:
        digitalWrite(GreenPin,HIGH);
        Serial.println("GreenPin is turn on 2 seconds");
        delay(2000);
        digitalWrite(GreenPin,LOW);
        a++;
        break;
      case 3:
        digitalWrite(BluePin,HIGH);
        Serial.println("BluePin is turn on 3 seconds");
        delay(3000);
        digitalWrite(BluePin,LOW);
        a++;
        break;
      default :
        a = 1;
        break;
    }
    delay(100);
  }
}
