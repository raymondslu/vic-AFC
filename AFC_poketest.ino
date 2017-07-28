int middleLED = 9;
int leftLED = 10;
int rightLED = 11;

int middleDetector = A0;
int leftDetector = A1;
int rightDetector = A2;

void setup() {
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
     digitalWrite(middleLED,HIGH);
     digitalWrite(leftLED,HIGH);
     digitalWrite(rightLED,HIGH);
  }
  if (digitalRead(middleDetector)==LOW)
  {
     digitalWrite(middleLED,LOW);
     digitalWrite(leftLED,LOW);
     digitalWrite(rightLED,LOW);
  }
}
