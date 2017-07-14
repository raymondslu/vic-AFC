% --- clear in case there is previous history.
% --- Cannot access Arduino otherwise
clear all; close all; clc; delete(instrfind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Call camera function here too connect and record --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run VC_WebcamRecording.m


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- establish global variables --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global AFCdata;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- establish Arduino Hardware communication --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- You cannot read and write to the same Arduino pins
% --- COM port = communication port and is from your computer's side;
% -------------- e.g. USB

% --- 1 Connect to Arduino--- a = arduino('COM#','board type'); creates
% ----- this as an object thus you cannot also "serial read" it
% --- 2 this establishes the first line to read from Arduino to MATLAB
% --- 3 open the serial connection--- fopen(s);
% --- 4 establish serial connection between MATLAB & arduino
% ----- s = serial('COM#); arduino and serial must be diff boards/COM#s

Read = arduino('COM4', 'Uno'); % 1
readingArduino = fscanf(Read);  % 2

Write = serial('COM5');        % 3
fopen(Write);                  % 4



% --- Obtain information from these pins
readVoltage(Read,'A0'); %DETECTOR_TWO; middleDetector; initiation port
readVoltage(Read,'A1'); %DETECTOR_ONE; leftDetector
readVoltage(Read,'A2'); %DETECTOR_THREE; rightDetector


% --- This information is useful for photometry
readVoltage(Read,'A3'); %LED_TWO; middleLED
readVoltage(Read,'A4'); %LED_ONE; leftLED
readVoltage(Read,'A5'); %LED_THREE; rightLED


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- UI prompt to assign values to variables: --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- remember to declare these variables to Arduino

prompt = {'mouseID',...         1 VC____
    'minHoldTime',...           2 unit in ms
    'maxHoldTime',...           3 unit in ms
    'rewSide',...               4 inputs: pro || anti
    'LEDSide',...               5 inputs: l || r || random
    'LEDLength:',...            6 unit in ms
    'freeReward',...            7 inputs: (y)=reward when correct finally chosen || (n)=reward only when correct 1st try
    'laserProb',...             8 whole number %
    'laserLength',...           9 unit in ms
    'maxTrials',...             10 maximum number of trials
    'taskType',...              11 pro || anti && laser||no laser
    'sessionID',...             12 track which session number the animal is on
    'sessionLength'};         % 13 unit in minutes 

% --- answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
prompt_title = 'Pro_2AFC_laser:';
num_lines = [1 35]; % [#OfLines  WidthOfUIField];

% --- Defaultans into the UI prompt. These can be modified per trial
def = {'VC',...                 1 mouseID
    '50',...                    2 minHoldTime in ms
    '200',...                   3 maxHoldTime in ms
    'pro',...                   4 rewSide
    'random',...                5 LEDSide
    '200',...                   6 LEDLength in ms
    'y',...                     7 freeReward
    '50',...                    8 laserProb shown as full number %
    '1000',...                  9 laserLength in ms
    '10000',...                 10 maxTrials
    '2AFC_',...                 11 taskType
    '',...                      12 sessionID
    '70'};                    % 13

% --- Create a dialog box
answer = inputdlg(prompt,prompt_title,num_lines,def);

pause(0.2); % pause to not overload the system


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Run Trials for 70 minutes --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Control for trial length here

% --- Display time in this format Year-Month-Date Hour:Minute:Second AM/PM DayOfWeek

DateTime = datetime('now','TimeZone','local','Format','y-MMMM-dd HH:mm:ss a eeee');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Keep track of the UI inputs --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i=1;
AFCdata=struct('mouseID',answer{1}, ...
    'minHoldTime',answer{2}, ...
    'maxHoldTime',answer{3}, ...
    'centerHoldTime',answer{4}, ...
    'rewSide',answer{5}, ...
    'LEDSide',answer{6},...
    'LEDLength',answer{7},...
    'freeReward',answer{8}, ...
    'laserProb',answer{9}, ...
    'laserLength',answer{10},...
    'maxTrials',answer{11}, ...
    'taskType',answer{12}, ...
    'trial','0');

% --- display goes to console and print goes to any sort of print output
% --- device. it is more generic. you can write code that prints to a
% --- PDF/Printer whereas display is more limited. Print has more features
% --- and variable names if you want to do more than just 'display'

disp('mouseID', AFCdata.mouseID);            % 1
disp('minHoldTime', AFCdata.minHoldTime);    % 2
disp('maxHoldTime', AFCdata.maxHoldTime);    % 3
disp('rewSide', AFCdata.rewSide);            % 4
diso('LEDSide',AFCdata.LEDside);             % 5
disp('LEDLength',AFCdata.LEDLength);         % 6
disp('freeReward', AFCdata.freeReward);      % 7
disp('laserProb', AFCdata.laserProb);        % 8
disp('laserLength', AFCdata.laserLength);    % 9
disp('maxTrials', AFCdata.maxTrials);        % 10
disp('taskType', AFCdata.taskType);          % 11
disp('sessionID',AFCdata.sessionID);         % 12
disp('sessionLength',AFCdata.sessionLength); % 13
disp('trial', AFCdata.totalTrial);           % display # trials performed
disp('DateTime',AFCdata.DateTime);           % display Date&Time of session

% --- Print Double-Precision Values as Integers 
% --- %i\n explicitly converts double-precision values with fractions to 
% --- integer values. %d in the formatSpec input prints each value in the 
% --- vector, as a signed integer. 
% --- \n is a control character that starts a new line.
fprintf('Max trials: %i\n',str2double(AFCdata.maxTrials));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Keep track of trial outcome --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Initiate Trial tally
AFCdata.totalTrial = 0;
AFCdata.totalReward = 0;
AFCdata.totalIncorrect = 0;
AFCdata.totalProb

AFCdata.leftTrial = 0;
AFCdata.leftReward = 0;
AFCdata.leftIncorrect = 0;
AFCdata.leftProb = 0;

AFCdata.rightTrial = 0;
AFCdata.rightReward = 0;
AFCdata.rightIncorrect = 0;
AFCdata.rightProb = 0;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- MAIN LOOP IS HERE ---%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Assign and declare values for the conditions of main loop

% --- tentative timer
StartTimer = tic;
ElapsedTime = toc(StartTimer);
sessionLength = str2double(AFCdata.sessionLength); % number of minutes to make the trial
TrialLength = 60*sessionLength; % seconds*minutes

while ElapsedTime < TrialLength 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- set initial center nose port holding time --- %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 str2double(str) Convert a character vector to a real number.
    % --- 2 randi(lowerbound,upperbound) generates random integer with uniform distribution
    % --- 3 uint16(array) converts the elements of an array into unsigned 16-bit (2-byte) integers of class uint16.
    % --- 4 send answer variable content to arduino
   
    AFCdata.minHoldTime = str2double(AFCdata.minHoldTime);                      % 1
    AFCdata.maxHoldTime = str2double(AFCdata.maxHoldTime);
    
    AFCdata.centerHoldTime = randi([AFCdata.minHoldTime,AFCdata.maxHoldTime]);  % 2
    disp(AFCdata.centerHoldTime);
    
    AFCdata.centerHoldTime = uint16(AFCdata.centerHoldTime);                    % 3
    centerHoldTime=AFCdata.centerHoldTime;
    
    fwrite(s,centerHoldTime,'uint16');                                          % 4

        if readingArduino == 'TRIAL INITIATED'
  
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % --- Pick random nose port --- %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % --- this randomizes to either 1 or 3 to keep track of nose port
                % --- (personal preference)...could also use 0s and 1s
                % --- 1 or 3 corresponds to LEFT or RIGHT, respectively
              if strcmpi(char(AFCdata.LEDSide),'rand') || strcmpi(char(AFCdata.LEDSide),'random')  
                AFCdata.nosePort = 3.^(round(rand()));
                while AFCdata.nosePort == 1
                    AFCdata.leftTrial = 'l';
                    
                    % --- write leftLED flash to arduino
                    % --- PWM (Pulse-Width Modulation) is a modulation
                    % --- technique that controls the width of the pulse based
                    % --- on modulator signal information. PWM can be used to
                    % --- encode information for transmission or to control of
                    % --- the power supplied to electrical devices such as
                    % --- motors.
                    
                    readingArduino == '
                    
                    writePWMVoltage(aWrite, 'D10', 0.5); 
                    pause(0.2);                        % keep on for 200 ms
                    writePWMVoltage(aWrite,'D10',0);   % turn off LED
                   
                elseif AFCdata.nosePort == 3
                    AFCdata.rightTrial = 'r';
                    
                    % --- write to rightLED flash arduino
                    writePWMVoltage(aWrite,'D11', 0.5);
                    pause(0.2);
                    writePWMVoltage(aWrite,'D11',0);
                    
                end
                if strcmpi(char(AFCdata.LEDSide),'l') 
                    % --- left side trials only
                    % --- write leftLED flash to arduino
                    writePWMVoltage(aWrite, 'D10', 0.5); 
                    pause(0.2);                        % keep on for 200 ms
                    writePWMVoltage(aWrite,'D10',0);   % turn off LED
                    
                elseif strcmpi(char(AFCdata.LEDSide),'r')
                    % --- right trials only
                    % --- write to rightLED flash arduino
                    writePWMVoltage(aWrite,'D11', 0.5);
                    pause(0.2);
                    writePWMVoltage(aWrite,'D11',0);
      
            end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % --- Solenoid rewarding --- %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             

                    if strcmpi(char(AFCdata.freeReward),'y')
                        AFCdata.nosePort == 1 && readAnalogPin(Read, 'A1');
                    % --- Solenoid output to port 1 (left) in response to LED_ONE.
                    % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
                    % --- requires 12V but the max that arduino can output is 5V
                    % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
                    writePWMVoltage(aWrite, 'D5', 5); % leftSolenoid
                    disp('Left REWARDED');
                    % --- pause in number of seconds. Basically, this will stall the solenoid for this amount of time, essentially "pausing" it in a state of being open
                    pause(0.05);
                elseif AFCdata.nosePort == 1 && readAnalogPin(Read,'A2')
                    
                    disp('Left INCORRECT, but REWARDED')
                    % --- give reward when it chooses the correct side
                    writePWMVoltage(aWrite,'D9',0.5);    % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0.5);   % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0.5);   % right (LED_THREE)
                    pause(1);
                    writePWMVoltage(aWrite,'D9',0);      % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0);     % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0);     % right (LED_THREE)
                end
                
            end
                if AFCdata.nosePort == 3 && readAnalogPin(Read,'A2')
                    % --- Solenoid output to port 3 (right) in response to LED_THREE
                    writePWMVoltage(aWrite, 'D6', 5); % rightSolenoid
                    disp('Right REWARDED');
                    pause(0.05);
                elseif AFCdata.nosePort == 3 && readAnalogPin(Read,'A1')
                    disp('Right INCORRECT');
                    % --- all lights flash for incorrect trial
                    writePWMVoltage(aWrite,'D9',0.5);    % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0.5);   % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0.5);   % right (LED_THREE)
                    pause(1);
                    writePWMVoltage(aWrite,'D9',0);      % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0);     % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0);     % right (LED_THREE)
                end
                    elseif strcmpi(char(AFCdata.freeReward),'n')
                        AFCdata.nosePort == 1 && readAnalogPin(Read, 'A1');
                    % --- Solenoid output to port 1 (left) in response to LED_ONE.
                    % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
                    % --- requires 12V but the max that arduino can output is 5V
                    % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
                    writePWMVoltage(aWrite, 'D5', 5); % leftSolenoid
                    disp('Left REWARDED');
                    % --- pause in number of seconds. Basically, this will stall the solenoid for this amount of time, essentially "pausing" it in a state of being open
                    pause(0.05);
                elseif AFCdata.nosePort == 1 && readAnalogPin(Read,'A2')&& strcmp(
                    
                    disp('Left INCORRECT')
                    % --- all lights flash for incorrect trial
                    writePWMVoltage(aWrite,'D9',0.5);    % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0.5);   % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0.5);   % right (LED_THREE)
                    pause(1);
                    writePWMVoltage(aWrite,'D9',0);      % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0);     % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0);     % right (LED_THREE)
        end
                % --- sample ElapsedTime after each trial for time stamp
                % comparison to end trials
               ElapsedTime; 
            end
                if AFCdata.nosePort == 3 && readAnalogPin(Read,'A2')
                    % --- Solenoid output to port 3 (right) in response to LED_THREE
                    writePWMVoltage(aWrite, 'D6', 5); % rightSolenoid
                    disp('Right REWARDED');
                    pause(0.05);
                elseif AFCdata.nosePort == 3 && readAnalogPin(Read,'A1')
                    disp('Right INCORRECT');
                    % --- all lights flash for incorrect trial
                    writePWMVoltage(aWrite,'D9',0.5);    % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0.5);   % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0.5);   % right (LED_THREE)
                    pause(1);
                    writePWMVoltage(aWrite,'D9',0);      % middle (LED_TWO)
                    writePWMVoltage(aWrite,'D10',0);     % left (LED_ONE)
                    writePWMVoltage(aWrite,'D11',0);     % right (LED_THREE)
                end
                    else
                        errordlg('BAD INPUT FOR freeReward');
                    end

                 
                
                
            end
            
            
            
            
            
            
            
         
            
            
        end
        % --- Track total trial numbers
        AFCdata.totalTrial = AFCdata.totalTrial + 1;
        disp(['totalTrial:',num2str(AFCdata.totalTrial)])
        % --- Track number of correct trials
        if (contains('Left REWARDED')) || (contains('Right REWARDED'))
            AFCdata.totalReward = AFCdata.totalReward + 1;
            disp(['totalReward = ',num2str(AFCdata.totalReward)])
            % --- Track total incorrect trials
            if (contains('Left INCORRECT')) || (contains ('Right INCORRECT'))
                AFCdata.Incorrect = 1;
                AFCdata.Incorrect = AFCdata.Incorrect + 1;
                disp(['totalIncorrect = ',num2str(AFCdata.Incorrect)])
            end
            % --- Track left trials
            if (contains(AFCdata.leftTrial))
                AFCdata.leftTrial = AFCdata.leftTrial + 1;
                disp(['leftTrial = ',num2str(AFCdata.leftTrial)])
            end
            %Track correct left trials
            if (contains(newLine,'Left REWARDED'))
                AFCdata.leftReward = AFCdata.leftReward + 1;
                disp(['leftReward = ',num2str(AFCdata.Incorrect)])
            end
            % --- Track incorrect left trials
            if (contains('Left INCORRECT'))
                AFCdata.leftIncorrect = AFCdata.leftIncorrect + 1;
                disp(['leftIncorrect = ',num2str(AFCdata.leftIncorrect)])
                % --- Track left trial incorrect but rewarded
                'Left INCORRECT, but REWARDED'
            end
            % --- Track right trials
            if (contains(AFCdata.rightTrial))
                AFCdata.rightTrial = AFCdata.rightTrial + 1;
                disp(['rightTrial = ',num2str(AFCdata.rightTrial)])
            end
            % --- Track correct right trials
            
            if (contains(newLine,'Right REWARDED'))
                AFCdata.rightReward = AFCdata.rightReward + 1;
                disp(['rightReward = ',num2str(AFCdata.rightReward)])
            end
            % --- Track incorrect right trials
            
            if (contains('Right INCORRECT'))
                AFCdata.rightIncorrect = AFCdata.rightIncorrect + 1;
                disp(['rightIncorrect = ',num2str(AFCdata.rightIncorrect)])
            end
            % --- track right trial incorrect but rewarded
            'Right INCORRECT, but REWARDED'
            
            
            
            
            
            
            
            
            
        end
        
        
        
        disp('Incorrect:', num2str(AFCdata.Incorrect));
        disp('totalReward:', num2str(AFCdata.totalReward));
        AFCdata.corrTrProb = (AFCdata.trial - AFCdata.freeRewardNum)/AFCdata.trial;
        disp('corrTrProb:','num2str(AFCdata.corrTrProb)');
        AFCdata.leftProb = AFCdata.leftReward/AFCdata.leftTrial;
        disp('leftProb:', 'num2str(AFCdata.leftProb)');
        AFCdata.rightProb = AFCdata.rightReward/AFCdata.rightTrial;
        disp('rightProb:', 'num2str(AFCdata.rightProb)');
        minHoldTime = str2num(AFCdata.minHoldTime);
        maxHoldTime = str2num(AFCdata.maxHoldTime);
        
% --- End of trial tally
AFCdata.totalTrial = 0;
AFCdata.totalReward = 0;
AFCdata.totalIncorrect = 0;
AFCdata.totalProb

AFCdata.leftTrial = 0;
AFCdata.leftReward = 0;
AFCdata.leftIncorrect = 0;
AFCdata.leftProb = 0;

AFCdata.rightTrial = 0;
AFCdata.rightReward = 0;
AFCdata.rightIncorrect = 0;
AFCdata.rightProb = 0;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- laser probability ---%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
% --- separate connection from arduino. write to the TTL TDT
% --- rand spits out a (+)number below 1--> scale the number up by 10000x for length of time in ms for the laser to be on
coinLaser = round(10000 .* rand());
coinLaser = num2str(coinLaser);
laserProb = num2str(100 .* str2double(AFCdata.laserProb));
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- End the trial session --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ElapsedTime == TrialLength || AFCdata.trial >= str2double(AFCdata.maxTrials)
    disp('Ending Session');
    pause(1);
    
    % --- 1 Disconnect interface object from instrument i.e. Arduino
    % --- 2 Remove items from workspace, freeing up system memory
    % --- 3 Close file after writing video data
    % --- 4 Clear MATLAB command window
    % --- 5 Delete serial port objects from memory to MATLAB workspace
    fclose(Write);     % 1
    clear all;          % 2
    close all;          % 3
    clc;                % 4
    delete(instrfind);  % 5
end

fprint(
