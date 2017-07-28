//SETUP: Declare and assign variables/values
int middleLED = 9;                                  // middle led connects to input 9
int leftLED = 10;                                   // left led connects to input 10
int rightLED = 11;                                  // right led connects to input 11

int middleDetector = A0;                            // middle detector connects to analog input A0
int leftDetector = A1;                              // left detector connects to analog input A1
int rightDetector = A2;                             // right detector connects to analog input A2

int leftSolenoid = 5;                               // solenoid reward for the left-side trials
int rightSolenoid = 6;                              // solenoid reward for the right-side trials
 
// Generally, you should use "unsigned long" for variables that hold time
// The value will quickly become too large for an int to store
unsigned long HoldTime;
unsigned long centerHoldTime;
int taskType;                                       // read from MATLAB if pro||anti (p/a in arduino)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void setup() {
  Serial.begin(9600);                              // same baud as computer
    
  pinMode(middleDetector, INPUT);                  // sets middle detector as an input, read from Arduino to MATLAB
  pinMode(leftDetector, INPUT);                    // sets left detector as an input, read from Arduino to MATLAB
  pinMode(rightDetector, INPUT);                   // sets right detector as an input, read from Arduino to MATLAB
  
  pinMode(middleLED, OUTPUT);                      // sets middle led as an output, write to Arduino from MATLAB
  pinMode(leftLED, OUTPUT);                        // sets left led as an output, write to Arduino from MATLAB
  pinMode(rightLED, OUTPUT);                       // sets right led as output, write to Arduino from MATLAB

  pinMode(leftSolenoid, OUTPUT);                   // sets leftSolenoid as output, write to Arduino from MATLAB
  pinMode(rightSolenoid, OUTPUT);                  // sets rightSolenoid as output, write to Arduino from MATLAB
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void loop() {
// start trial here with HoldTime  
HoldTime= pulseIn(middleDetector,HIGH)/1000;        // pulseIn establishes micosecond counter in the detector to count HIGH
centerHoldTime = Serial.read();                    // read from MATLAB's centerHoldTime

// read that middleDetector is high for self initiation
// while HIGH, if the HoldTime is achieved then initiate trial
  if(digitalRead(middleDetector) == HIGH && HoldTime == centerHoldTime)
  {
    Serial.println(F("trialInitiated"));

    taskType = Serial.read();                     // either pro||anti for same stimulus same side vs stimulus and reward on opp side

if (taskType == 'p')                              // read from MATLAB UI dialog box
{
  ///////////////////////////
 // Left trial parameters //
///////////////////////////
  if (digitalRead(leftLED) == HIGH)
  {
    if (digitalRead(leftDetector) == HIGH)
    {
      Serial.println("CORRECT");
      if (digitalRead(leftSolenoid) == HIGH)
      {
        Serial.println("REWARDED");
      }
      else
      {
        Serial.println("CORRECT, but NOT REWARDED");
      }
    } 
      else if (digitalRead(rightDetector) == HIGH)
      {
        (Serial.println("INCORRECT"));
      }
  }

  ////////////////////////////
 // Right trial parameters //
////////////////////////////
  if (digitalRead(rightLED) == HIGH)
  {
    if (digitalRead(rightDetector) == HIGH)
    {
      Serial.println("CORRECT");
      if (digitalRead(rightSolenoid)== HIGH)
      {
        Serial.println("REWARDED");
      }
      else
      {
        Serial.println("CORRECT, but NOT REWARDED");
      }
    } 
    else if (digitalRead(leftDetector) == HIGH)
      {
        (Serial.println("INCORRECT"));
      }
  }
}

if (taskType == 'a')
{
  ///////////////////////////
 // Left trial parameters //
///////////////////////////
  if (digitalRead(leftLED) == HIGH)
  {
    if (digitalRead(rightDetector) == HIGH)
    {
      Serial.println("CORRECT");
      if (digitalRead(rightSolenoid) == HIGH)
      {
        Serial.println("REWARDED");
      }
      else
      {
        Serial.println("CORRECT, but NOT REWARDED");
      }
    } 
      else if (digitalRead(leftDetector) == HIGH)
      {
        (Serial.println("INCORRECT"));
      }
  }

  ////////////////////////////
 // Right trial parameters //
////////////////////////////
  if (digitalRead(rightLED) == HIGH)
  {
    if (digitalRead(leftDetector) == HIGH)
    {
      Serial.println("CORRECT");
      if (digitalRead(leftSolenoid)== HIGH)
      {
        Serial.println("REWARDED");
      }
      else
      {
        Serial.println("CORRECT, but NOT REWARDED");
      }
    } 
    else if (digitalRead(rightDetector) == HIGH)
      {
        (Serial.println("INCORRECT"));
      }
  }
}
  }
}                 
