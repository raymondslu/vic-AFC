int middleLED = 9;
int leftLED = 10;
int rightLED = 11;

int middleDetector = A0;
int leftDetector = A1;
int rightDetector = A2;

long initialTime = 0;
long currentTime;
long elapsedTime;

long onesecond;

void setup() {
Serial.begin(9600);

pinMode(middleLED,OUTPUT);
pinMode(leftLED,OUTPUT);
pinMode(rightLED,OUTPUT);

pinMode(middleDetector,INPUT);
pinMode(leftDetector,INPUT);
pinMode(rightDetector,INPUT);
}

void loop(){
  if (digitalRead(middleDetector)==HIGH)
  {
    currentTime = millis();
    initialTime = currentTime;
    Serial.println("SDJFLSDJFLSDKJFLSDKJFSLDKJF");
    while (digitalRead(middleDetector)==HIGH)
    {
       currentTime = millis();
       Serial.println("CURRENT_TIME");
       Serial.println(currentTime);
       elapsedTime = currentTime-initialTime;
       Serial.println("ELAPSED_TIME");
       Serial.println(elapsedTime);
       digitalWrite(middleLED,HIGH);
       if (elapsedTime >= 1000)
       {
          digitalWrite(middleLED,LOW);
          Serial.println("~~~~~INITIAL_TIME~~~~~!!!!!!!!!!!!!!!");
          Serial.println(initialTime);
          break;
       }
     while (digitalRead(middleDetector)==LOW)
     {
      (digitalWrite(middleLED,LOW));
      break;
     }
    }
  }
}
