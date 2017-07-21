% --- clear in case there is previous history.
% --- Cannot access Arduino otherwise
clear; close all; clc; delete(instrfind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Call camera function here too connect and record        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run VC_WebcamRecording.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        establish global variables        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global sessionData ...  % store summary of session data here. 1 session encompasses multiple trials
       trialData;       % store trial per trial data here -- matrix form

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        establish Arduino Hardware communication        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- You cannot read and write to the same Arduino pins
% --- COM port = communication port and is from your computer's side;
% -------------- e.g. USB

% --- 1 Connect to Arduino--- a = arduino('COM#','board type'); creates
% ----- this as an object thus you cannot also "serial read" it
% --- 2 this establishes the first line to read from Arduino to MATLAB
% --- 3 open the serial connection--- fopen(s);
% --- 4 establish serial connection between MATLAB & arduino
% ----- s = serial('COM#); arduino and serial must be diff boards/COM#s

Read = arduino('COM4', 'Uno'); % 1  use Read when you need to directly trigger a pin, for non "true" writing to arduino
readingArduino = fscanf(Read); % 2

Write = serial('COM5');        % 3  only use Write when sending non-direct pin triggers, for "true" writing to arduino
fopen(Write);                  % 4


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        prompt to assign values to variables        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'mouse ID',...                           1 VC#
    'minimum center hold time (ms)',...            2 unit in ms
    'maximum center hold time (ms)',...            3 unit in ms
    'LED side (left/right/random)',...             4 inputs: l || r || random
    'LED length (ms)',...                          5 unit in ms
    'reward length (ms)',...                       6 inputs: ms length to keep valve open for reward
    'free reward (yes/no)',...                     7 inputs: (y)=reward when correct finally chosen || (n)=reward only when correct 1st try
    'opto type (excitation/inhibition/none)',...   8 optogenetics--inputs: excitation||inhibition||none
    'opto probability (whole number %)',...        9 whole number % for laser probability
    'laser length (ms)',...                        10 unit in ms
    'maximum number of trials',...                 11 maximum number of trials
    'task type (pro/anti/blockswitch)',...         12 pro || anti || blockswitch
    'session ID (#)',...                           13 track which session number the animal is on
    'session length (min)',...                     14 unit in minutes
    'timeout (yes/no)',...                         15 inputs: yes || no
    'timeout length (s)'};                       % 16 timeout length unit in ms

% --- answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
prompt_title = '2AFC Behavior Trials';
num_lines = [1 45]; % [#OfLines  WidthOfUIField];

% --- default answers into the prompt. These can be modified per trial
def = {'VC',...                 1 mouse ID
    '50',...                    2 min HoldTime in ms
    '200',...                   3 max HoldTime in ms
    'random',...                4 LED Side
    '200',...                   5 LED Length in ms
    '50',...                    6 rewardLength in ms
    'yes',...                   7 free reward
    'none',...                  8 opto Trial: none || excitation || inhibition
    '50',...                    9 opto Prob shown as full number %
    '1000',...                  10 laser Length in ms
    '10000',...                 11 maxTrials
    'pro',...                   12 taskType
    '',...                      13 sessionID
    '70',...                    14 session length
    'no'...                     15 timeout
    '5'};                     % 16 timeout length

% --- Create a dialog box; UI = user input
UI = inputdlg(prompt,prompt_title,num_lines,def);

% --- Display time in this format Year-Month-Date Hour:Minute:Second AM/PM DayOfWeek
% --- For display at the end of the session
sessionData.dateTime = datetime('now','TimeZone','local','Format','y-MMMM-dd HH:mm:ss a eeee');

% --- for file saving
sessionData.fileDate = datestr(now, 'yyyy_mm_dd');

% --- Convert character vector to a real number with str2double();
sessionData.minHoldTime = str2double(sessionData.minHoldTime);
sessionData.maxHoldTime = str2double(sessionData.maxHoldTime);
sessionData.LEDLength = str2double(sessionData.LEDLength);
sessionData.rewardLength = str2double(sessionData.rewardLength);
sessionData.optoProb = str2double(sessionData.optoProb);
sessionData.laserLength = str2double(sessionData.laserLength);
sessionData.maxTrials = str2double(sessionData.maxTrials);
sessionData.sessionID = str2double(sessionData.sessionID);
sessionData.length = str2double(sessionData.length);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of user inputs (UI)        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialize session info for sessionEnd message box
sessionData.trialTally = 0;
sessionData.correct = 0;
sessionData.wrong = 0;
sessionData.percentageCorrect = 0;
sessionData.timeoutTally = 0;

% --- Structure arrays contain data in fields that you access by name.
sessionData=struct('mouseID',UI{1}, ...
    'minHoldTime',UI{2}, ...
    'maxHoldTime',UI{3}, ...
    'LEDSide',UI{4},...
    'LEDLength',UI{5},...
    'rewardLength',UI{6},...
    'freereward',UI{7}, ...
    'optoTrial',UI{8},...
    'optoProb',UI{9}, ...
    'laserLength',UI{10},...
    'maxTrials',UI{11}, ...
    'taskType',UI{12}, ...
    'sessionID',UI{13},...
    'length',UI{14},...
    'timeout',UI{15},...
    'timeoutLength',UI{16},...
    'dateTime',{sessionData.dateTime},...
    'trialTally',{sessionData.trialTally},...
    'correct',{sessionData.correct},...
    'wrong',{sessionData.wrong},...
    'percentageCorrect',{sessionData.percentageCorrect},...
    'timeoutTally',{sessionData.timeoutTally});


% --- display goes to console and print goes to any sort of print output
% --- device. it is more generic. you can write code that prints to a
% --- PDF/Printer whereas display is more limited. Print has more features
% --- and variable names if you want to do more than just 'display'

% --- Print Double-Precision Values as Integers
% --- %i\n explicitly converts double-precision values with fractions to
% --- integer values. %d in the formatSpec input prints each value in the
% --- vector, as a signed integer.
% --- \n is a control character that starts a new line.
fprintf('Max trials: %i\n',str2double(sessionData.maxTrials));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of trial outcome        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i=7;  % number of rows
j=1;  % initialize first column

data = NaN(7,sessionData.maxTrials);  % prepopulate with NaN(rows, column)

trialData=struct('trialType',{trialData.trialType},...
    'optoTrial',{trialData.optoTrial},...
    'LEDSide',{trialData.LEDSide},...
    'reward',{trialData.reward},...
    'correct',{trialData.correct},...
    'centerHoldTime',{trialData.centerHoldTime},...
    'timeout',{trialData.timeout});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        MAIN LOOP IS HERE        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Session length
StartTimer = tic;
ElapsedTime = toc(StartTimer);
sessionData.length = 60.* str2double(sessionData.length); % (60 seconds)*(desired minutes) bc timer counts by seconds 

% --- Timeout parameters 
timeoutTimer = timer;
timeoutTimer.StartFcn = @(~,thisEvent)disp([thisEvent.Type '  TIMEOUT START:  '...
    datestr(thisEvent.Data.time,'dd-mmm-yyyy HH:MM:SS.FFF')]);
timeoutTimer.ErrorFcn = 'error';
timeoutTimer.ExecutionMode= 'singleShot';
timeoutTimer.TasksToExecute = 1;
timeoutTimer.Period = sessionData.timeoutLength;
timeoutTimer.TimerFcn = @(myTimerObj, thisEvent)disp('END TRIAL');
start(timeoutTimer)

while j<=sessionData.maxTrials || ElapsedTime <= sessionData.length
  
    % --- assign values to the columns of j=j+1
    data(1,j)=trialData.trialType;          % either 0 or 1 for 'pro' or 'anti,' respectively
    data(2,j)=trialData.optoTrial;          % 0 = no opto, 1 = excitation, 2 = inhibition
    data(3,j)=trialData.LEDSide;            % either 1 or 3 for L or R, respectively for LED flash
    data(4,j)=trialData.reward;             % free reward: +/- 1 or +/- 3 || no free reward: 0 or 1 for no reward, rewarded
    data(5,j)=trialData.correct;            % correct = 1, wrong = 0
    data(6,j)=trialData.centerHoldTime;     % will autofill per trial
    data(7,j)=trialData.timeout;            % timeout = 1, no timeout = 0
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        set initial center nose port holding time        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 randi(lowerbound,upperbound) generates random integer with uniform distribution
    % --- 2 uint16(array) converts the elements of an array into unsigned 16-bit (2-byte) integers
    % ----- of class uint16.
    % --- 3 send answer variable content to arduino
    
    trialData.centerHoldTime = randi([sessionData.minHoldTime,sessionData.maxHoldTime]);  % 1
    disp(trialData.centerHoldTime);
    
    trialData.centerHoldTime = uint16(trialData.centerHoldTime);  % 2
    centerHoldTime=trialData.centerHoldTime;
    
    fwrite(Write,centerHoldTime,'uint16');  % 3

    % --- Trial Initiation detected
    if readingArduino == 'TRIAL INITIATED'
        
       sessionData.trialTally = sessionData.trialTally + 1;
    
        if strcmpi(char(sessionData.timeout),'y') || strcmpi(char(sessionData.timeout),'yes')
 
           
            if done within sessionData.timeoutLength
            delete(timeoutTimer)
            trialData.timeout = 0;
            sessionData.timeoutTally = sessionData.timeoutTally + 1;
            end
        end
        
        if no nose poke within sessionData.timeoutLength, restart trial
            delete(timeoutTimer)
            trialData.timeout = 1;
        end
        
    if strcmpi(char(sessionData.timeout),'n') || strcmpi(char(sessionData.timeout),'no')
        trialData.timeout = NaN;
        sessionData.timeoutTally = 0;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        LEDSide input        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 strcmpi(x,y) compares x and y insensitive.
    % --- 2 char() converts the sessionData.LEDSide into a character vector
    % --- 3 this randomizes to either 1 or 3 to keep track of nose port
    % ----- (personal preference)...could also use 0s and 1s
    % ----- 1 or 3 corresponds to LEFT or RIGHT, respectively
    
    % --- for LEDSide = random
    if strcmpi(char(sessionData.LEDSide),'rand') || strcmpi(char(sessionData.LEDSide),'random')  % 1, 2
       trialData.LEDSide = 3.^(randi([0 1]));  % 3
            
            if trialData.LEDSide == 1
                
                if strcmpi(char(sessionData.trialType),'pro')
                    disp('pro-Left INITIATED')
                    trialData.trialType = 0;
                    fwrite(Write,'pro',char);
                end
                
                if strcmpi(char(sessionData.trialType),'anti')
                    disp('anti-Left INITIATED')
                    trialData.trialType = 1;
                    fwrite(Write,'anti',char);
                end
                
                % --- write leftLED flash to arduino
                % --- PWM (Pulse-Width Modulation) is a modulation
                % --- technique that controls the width of the pulse based
                % --- on modulator signal information. PWM can be used to
                % --- encode information for transmission or to control of
                % --- the power supplied to electrical devices such as
                % --- motors.
                
                % leftLED flash
                writePWMvoltage(Read, 'D10', 0.5);
                pause(sessionData.LEDLength/1000);
                writePWMvoltage(Read,'D10',0);       % turn off LED
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %        laser probability        %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % --- no opto laser
                if strcmpi(char(sessionData.optoTrial),'none')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    trialData.optoTrial = 0;
                end
                
                % --- opto excitation
                if strcmpi(char(sessionData.optoTrial),'excitation')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    laserOnOff = rand;
                    if laserOnOff <= sessionData.optoProb
                        trialData.optoTrial = 1;
                        fwrite(Write,'excitation',char);
                        if readingArduino == 'EXCITATION ON'
                            disp('EXCITATION ON');
                        end
                    end
                    if laserOnOff > sessionData.optoProb
                        trialData.optoTrial = 0;
                        disp('EXCITATION OFF');
                    end
                end
                
                % --- opto inhibition
                if strcmpi(char(sessionData.optoTrial),'inhibition')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    laserOnOff = rand;
                    if laserOnOff <= sessionData.optoProb
                        trialData.optoTrial = 2;
                        fwrite(Write,'inhibition',char);
                        if readingArduino == 'INHIBITION ON'
                            disp('INHIBITION ON');
                        end
                    end
                    if laserOnOff > sessionData.optoProb
                        trialData.optoTrial = 0;
                        disp('INHIBITION OFF');
                    end
                end
            end
            
            
            if trialData.LEDSide == 3
                
                % --- identify trialType here & write to arduino
                if strcmpi(char(sessionData.trialType),'pro')
                    disp('pro-Right INITIATED')
                    trialData.trialType = 0;
                    fwrite(Write,'pro',char);
                end
                
                if strcmpi(char(sessionData.trialType),'anti')
                    disp('anti-Right INITIATED')
                    fwrite(Write,'anti',char);
                end
                
                % --- rightLED flash
                writePWMvoltage(Read,'D11', 0.5);
                pause(sessionData.LEDLength/1000);
                writePWMvoltage(Read,'D11',0);
                
                % --- no opto laser
                if strcmpi(char(sessionData.optoTrial),'none')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    trialData.optoTrial = 0;
                end
                
                % --- opto excitation
                if strcmpi(char(sessionData.optoTrial),'excitation')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    laserOnOff = rand;
                    if laserOnOff <= sessionData.optoProb
                        trialData.optoTrial = 1;
                        fwrite(Write,'excitation',char);
                        if readingArduino == 'EXCITATION ON'
                            disp('EXCITATION ON');
                        end
                    end
                    if laserOnOff > sessionData.optoProb
                        trialData.optoTrial = 0;
                        disp('EXCITATION OFF');
                    end
                end
                
                % --- opto inhibition
                if strcmpi(char(sessionData.optoTrial),'inhibition')
                    sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                    laserOnOff = rand;
                    if laserOnOff <= sessionData.optoProb
                        trialData.optoTrial = 2;
                        fwrite(Write,'inhibition',char);
                        if readingArduino == 'INHIBITION ON'
                            disp('INHIBITION ON');
                        end
                    end
                    if laserOnOff > sessionData.optoProb
                        trialData.optoTrial = 0;
                        disp('INHIBITION OFF');
                    end
                end
            end
        end
    end
    
    % --- for LEDSide on the LEFT only
    if strcmpi(char(sessionData.LEDSide),'l') || strcmpi (char(sessionData.LEDSide),'left')
        % --- left side trials only
        % --- write leftLED flash to arduino
        trialData.LEDSide = 1;
        if readingArduino == 'TRIAL INITIATED'
            writePWMvoltage(Read, 'D10', 0.5);
            pause(sessionData.LEDLength/1000);         % keep on for 200 ms
            writePWMvoltage(Read,'D10',0);         % turn off LED
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        laser probability        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- no opto laser
        if strcmpi(char(sessionData.optoTrial),'none')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            trialData.optoTrial = 0;
        end
        
        % --- opto excitation
        if strcmpi(char(sessionData.optoTrial),'excitation')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProb
                trialData.optoTrial = 1;
                fwrite(Write,'excitation',char);
                if readingArduino == 'EXCITATION ON'
                    disp('EXCITATION ON');
                end
            end
            if laserOnOff > sessionData.optoProb
                trialData.optoTrial = 0;
                disp('EXCITATION OFF');
            end
        end
        
        % --- opto inhibition
        if strcmpi(char(sessionData.optoTrial),'inhibition')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProb
                trialData.optoTrial = 1;
                fwrite(Write,'inhibition',char);
                if readingArduino == 'INHIBITION ON'
                    disp('INHIBITION ON');
                end
            end
            if laserOnOff > sessionData.optoProb
                trialData.optoTrial = 0;
                disp('INHIBITION OFF');
            end
        end
    end
    
    % --- for LEDSide on the RIGHT only
    if strcmpi(char(sessionData.LEDSide),'r')|| strcmpi(char(sessionData.LEDSide),'right')
        % --- right trials only
        % --- write to rightLED flash arduino
        trialData.LEDSide = 3;
        if readingArduino == 'TRIAL INITIATED'
            writePWMvoltage(Read,'D11', 0.5);
            pause(sessionData.LEDLength/1000);
            writePWMvoltage(Read,'D11',0);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        laser probability        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- no opto laser
        if strcmpi(char(sessionData.optoTrial),'none')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            trialData.optoTrial = 0;
        end
        
        % --- opto excitation
        if strcmpi(char(sessionData.optoTrial),'excitation')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProb
                trialData.optoTrial = 1;
                fwrite(Write,'excitation',char);
                if readingArduino == 'EXCITATION ON'
                    disp('EXCITATION ON');
                end
            end
            if laserOnOff > sessionData.optoProb
                trialData.optoTrial = 0;
                disp('EXCITATION OFF');
            end
        end
        
        % --- opto inhibition
        if strcmpi(char(sessionData.optoTrial),'inhibition')
            sessionData.optoProb = (str2double(sessionData.optoProb))/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProb
                trialData.optoTrial = 1;
                fwrite(Write,'inhibition',char);
                if readingArduino == 'INHIBITION ON'
                    disp('INHIBITION ON');
                end
            end
            if laserOnOff > sessionData.optoProb
                trialData.optoTrial = 0;
                disp('INHIBITION OFF');
            end
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Solenoid rewarding        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- FREE reward TRIALS
    if strcmpi(char(sessionData.freereward),'y')
        
        % --- left-side trials
        if readingArduino == 'pro-Left CORRECT'
            
            % --- tally session correct
            sessionData.correct = sessionData.correct + 1;
            
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D5', 5); % leftSolenoid
            pause(sessionData.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D5', 0); %close solenoid
            writePWMvoltage(Read, 'D5', 5); % 2 clicks for correct
            pause(sessionData.rewardLength/1000);
            writePWMvoltage(Read, 'D5', 0);
            

            
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left REWARDED');
                trialData.reward = 1;
            else trialData.reward = -1;
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Left WRONG'
            sessionData.wrong = sessionData.wrong + 1;
            writePWMvoltage(Read,'D10',0.5); % flash the light on correct side
            pause(sessionData.LEDlength/1000);
            writePWMvoltage(Read,'D10',0);
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left wrong, but REWARDED');
                trialData.reward = 1;
            else trialData.reward = -1;
            end
            disp('END TRIAL');
        end
        
        % --- right-side trials
        if readingArduino == 'pro-Right CORRECT'
            
            sessionData.correct = sessionData.correct + 1;
            
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D6', 5); % leftSolenoid
            pause(sessionData.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D6', 0); %close solenoid
            writePWMvoltage(Read, 'D6', 5); % 2 clicks for correct
            pause(sessionData.rewardLength/1000);
            writePWMvoltage(Read, 'D6', 0);
            
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right REWARDED');
                trialData.reward = 3;
            else trialData.reward = -3;
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Right WRONG'
            
            sessionData.wrong = sessionData.wrong + 1;
            
            writePWMvoltage(Read,'D11',0.5); % flash the light on correct side
            pause(sessionData.LEDlength/1000);
            writePWMvoltage(Read,'D11',0);
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right wrong, but REWARDED');
                trialData.reward = 3;
            else trialData.reward = -3;
            end
            disp('END TRIAL');
        end
    end
    
    % --- NO FREE reward TRIALS
    if strcmpi(char(sessionData.freereward),'n')
        % --- left-side trials
        if readingArduino == 'pro-Left CORRECT'
            
            sessionData.correct = sessionData.correct + 1;
            
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D5', 5); % leftSolenoid
            pause(sessionData.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D5', 0); %close solenoid
            writePWMvoltage(Read, 'D5', 5); % 2 clicks for correct
            pause(sessionData.rewardLength/1000);
            writePWMvoltage(Read, 'D5', 0);
            
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left REWARDED');
                trialData.REWARDED = 1;
            else trialData.REWARDED = 0;
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Left WRONG'
            
            sessionData.wrong = sessionData.wrong + 1;
            trialData.reward = 0;
            
            % --- light flash 2x for wrong
            writePWMvoltage(Read,'D9',0.5);    % middle (LED_TWO)
            writePWMvoltage(Read,'D10',0.5);   % left (LED_ONE)
            writePWMvoltage(Read,'D11',0.5);   % right (LED_THREE)
            pause(0.2);
            writePWMvoltage(Read,'D9',0);
            writePWMvoltage(Read,'D10',0);
            writePWMvoltage(Read,'D11',0);
            
            writePWMvoltage(Read,'D9',0.5);
            writePWMvoltage(Read,'D10',0.5);
            writePWMvoltage(Read,'D11',0.5);
            pause(0.2);
            writePWMvoltage(Read,'D9',0);
            writePWMvoltage(Read,'D10',0);
            writePWMvoltage(Read,'D11',0);
            
            disp('END TRIAL');
        end
        
        % --- right-side trials
        if readingArduino == 'pro-Right CORRECT'
            
            sessionData.correct = sessionData.correct + 1;
            
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D6', 5); % leftSolenoid
            pause(sessionData.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D6', 0); %close solenoid
            writePWMvoltage(Read, 'D6', 5); % 2 clicks for correct
            pause(sessionData.rewardLength/1000);
            writePWMvoltage(Read, 'D6', 0);
            
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right REWARDED');
                trialData.reward = 3;
            else trialData.reward = 0;
            end
        end
        
        if readingArduino == 'pro-Right WRONG'
            
            sessionData.wrong = sessionData.wrong + 1;
            trialData.reward = 0;
            % --- light flash 2x for wrong
            writePWMvoltage(Read,'D9',0.5);    % middle (LED_TWO)
            writePWMvoltage(Read,'D10',0.5);   % left (LED_ONE)
            writePWMvoltage(Read,'D11',0.5);   % right (LED_THREE)
            pause(0.2);
            writePWMvoltage(Read,'D9',0);
            writePWMvoltage(Read,'D10',0);
            writePWMvoltage(Read,'D11',0);
            
            writePWMvoltage(Read,'D9',0.5);
            writePWMvoltage(Read,'D10',0.5);
            writePWMvoltage(Read,'D11',0.5);
            pause(0.2);
            writePWMvoltage(Read,'D9',0);
            writePWMvoltage(Read,'D10',0);
            writePWMvoltage(Read,'D11',0);
            
            disp('END TRIAL');
        end
    end
    
    % --- to increase column so every add column = new trial
    j=j+1;
    
    % --- Sample ElapsedTime at the end of each trial run for the while loop
    % ---------- qualifier
    ElapsedTime;
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        End the trial session        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ElapsedTime > sessionData.length || sessionData.trial >= str2double(sessionData.maxTrials)
    
    % --- display total trial info to see mouse progress
    disp('SESSION END');
    sessionData.percentageCorrect = sessionData.correct/(sessionData.trialTally-sessionData.timeoutTally);
    sessionEnd = msgbox({'2AFC_SKINNER_BOX' '' ...
                          sessionData.dateTime '' ...
                         'SESSION LENGTH:' sessionData.length '' ...
                         'TOTAL NUMBER OF TRIALS:' sessionData.trialTally '' ...
                         'TOTAL PROBABILITY:' sessionData.percentageCorrect '' ...
                         'TOTAL CORRECT:' sessionData.correct '' ...
                         'TOTAL WRONG:' sessionData.wrong '' ...
                         'TOTAL TIMEOUTS:' sessionData.timeoutTally '' ...
                         'OPTOGENETICS:' sessionData.optoTrial ''});
                     
    % --- save data & export to file using fprintf()
    disp('SAVING DATA TO FILE');
    AFC_saveData(sessionData.mouseID,sessionData.fileDate);
    saveData = msgbox({'' 'DATA SAVE:  COMPLETE' ''});
    
    
    
    
    % --- 1 Disconnect interface object from instrument i.e. Arduino
    % --- 2 Close file after writing video data
    % --- 3 Clear MATLAB command window
    % --- 4 Delete serial port objects from memory to MATLAB workspace
    fclose(Write);      % 1
    close all;          % 2
    clc;                % 3
    delete(instrfind);  % 4
end


