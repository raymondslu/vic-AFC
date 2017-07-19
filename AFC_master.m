% --- clear in case there is previous history.
% --- Cannot access Arduino otherwise
clear; close all; clc; delete(instrfind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Call camera function here too connect and record --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run VC_WebcamRecording.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- establish global variables --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global AFCdata trialInfo;

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

Read = arduino('COM4', 'Uno'); % 1  use Read when you need to directly trigger a pin, for non "true" writing to arduino
readingArduino = fscanf(Read); % 2

Write = serial('COM5');        % 3  only use Write when sending non-direct pin triggers, for "true" writing to arduino
fopen(Write);                  % 4


% % --- Obtain information from these pins
% readVoltage(Read,'A0'); %DETECTOR_TWO; middleDetector; initiation port
% readVoltage(Read,'A1'); %DETECTOR_ONE; leftDetector
% readVoltage(Read,'A2'); %DETECTOR_THREE; rightDetector
%
%
% % --- This information is useful for photometry
% readVoltage(Read,'A3'); %LED_TWO; middleLED
% readVoltage(Read,'A4'); %LED_ONE; leftLED
% readVoltage(Read,'A5'); %LED_THREE; rightLED


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- UI prompt to assign values to variables: --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'mouseID',...         1 VC____
    'minHoldTime',...           2 unit in ms
    'maxHoldTime',...           3 unit in ms
    'rewSide',...               4 inputs: pro || anti
    'LEDSide',...               5 inputs: l || r || random
    'LEDLength',...             6 unit in ms
    'rewardLength',...          7 inputs: ms length to keep valve open for reward
    'freeReward',...            8 inputs: (y)=reward when correct finally chosen || (n)=reward only when correct 1st try
    'optoTrial',...           9 optogenetics--inputs: excitation||inhibition||none
    'optoProb',...             10 whole number % for laser probability
    'laserLength',...           11 unit in ms
    'maxTrials',...             12 maximum number of trials
    'taskType',...              13 pro || anti || blockswitch
    'sessionID',...             14 track which session number the animal is on
    'sessionLength'};         % 15 unit in minutes

% --- answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
prompt_title = '2AFC Behavior Trials';
num_lines = [1 35]; % [#OfLines  WidthOfUIField];

% --- default answers into the UI prompt. These can be modified per trial
def = {'VC',...                 1 mouseID
    '50',...                    2 minHoldTime in ms
    '200',...                   3 maxHoldTime in ms
    'pro',...                   4 rewSide
    'random',...                5 LEDSide
    '200',...                   6 LEDLength in ms
    '50',...                    7 rewardLength in ms
    'y',...                     8 freeReward
    'n',...                     9
    '50',...                    10 optoProb shown as full number %
    '1000',...                  11 laserLength in ms
    '10000',...                 12 maxTrials
    'pro',...                   13 taskType
    '',...                      14 sessionID
    '70'};                    % 15

% --- Create a dialog box
answer = inputdlg(prompt,prompt_title,num_lines,def);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Run Trials for 70 minutes --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Control for trial length here
% --- Display time in this format Year-Month-Date Hour:Minute:Second AM/PM DayOfWeek
DateTime = datetime('now','TimeZone','local','Format','y-MMMM-dd HH:mm:ss a eeee');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Keep track of the UI inputs --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Structure arrays contain data in fields that you access by name.
AFCdata=struct('mouseID',answer{1}, ...
    'minHoldTime',answer{2}, ...
    'maxHoldTime',answer{3}, ...
    'rewSide',answer{5}, ...
    'LEDSide',answer{6},...
    'LEDLength',answer{7},...
    'rewardLength',answer{8},...
    'freeReward',answer{9}, ...
    'optoTrial',answer{10},...         keep track of the number of opto trials
    'optoProb',answer{11}, ...
    'laserLength',answer{12},...
    'maxTrials',answer{13}, ...
    'taskType',answer{14}, ...
    'DateTime','',...
    'totalTrial','0');

% --- Convert character vector to a real number with str2double();
AFCdata.minHoldTime = str2double(AFCdata.minHoldTime);
AFCdata.maxHoldTime = str2double(AFCdata.maxHoldTime);
AFCdata.LEDLength = str2double(AFCdata.LEDLength);
AFCdata.rewardLength = str2double(AFCdata.rewardLength);
AFCdata.optoProb = str2double(AFCdata.optoProb);
AFCdata.laserLength = str2double(AFCdata.laserLength);
AFCdata.maxTrials = str2double(AFCdata.maxTrials);
AFCdata.sessionID = str2double(AFCdata.sessionID);
AFCdata.sessionLength = str2double(AFCdata.sessionLength);

% --- display goes to console and print goes to any sort of print output
% --- device. it is more generic. you can write code that prints to a
% --- PDF/Printer whereas display is more limited. Print has more features
% --- and variable names if you want to do more than just 'display'

% --- Print Double-Precision Values as Integers
% --- %i\n explicitly converts double-precision values with fractions to
% --- integer values. %d in the formatSpec input prints each value in the
% --- vector, as a signed integer.
% --- \n is a control character that starts a new line.
fprintf('Max trials: %i\n',str2double(AFCdata.maxTrials));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Keep track of trial outcome --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Cell arrays contain data in cells that you access by numeric indexing.
% --- Common applications of cell arrays include storing separate pieces of
% ---------- text and storing heterogeneous data from spreadsheets.
i=1;
i=i+1;
trialInfo=struct('trialType',answer{1},...
                 'optoTrial',answer{2},...
                 'LEDLeft',answer{3},...
                 'LEDRight',answer{4},...
                 'REWARD',answer{5},...
                 'CORRECT',answer{6},...
                 'WRONG',answer{7},...
                 'centerHoldTime',answer{8},...
                 'timeout',answer{9});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- MAIN LOOP IS HERE ---%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Assign and declare values for the conditions of main loop

% --- Timer
StartTimer = tic;
ElapsedTime = toc(StartTimer);
sessionLength = str2double(AFCdata.sessionLength); % number of minutes to make the trial
TrialLength = 60.*sessionLength;                   % 60seconds* how many minutes to run the session = total seconds

while ElapsedTime < TrialLength
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- set initial center nose port holding time --- %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 randi(lowerbound,upperbound) generates random integer with uniform distribution
    % --- 2 uint16(array) converts the elements of an array into unsigned 16-bit (2-byte) integers
    % ----- of class uint16.
    % --- 3 send answer variable content to arduino
    
    AFCdata.centerHoldTime = randi([AFCdata.minHoldTime,AFCdata.maxHoldTime]);  % 1
    disp(AFCdata.centerHoldTime);
    
    AFCdata.centerHoldTime = uint16(AFCdata.centerHoldTime);                    % 2
    centerHoldTime=AFCdata.centerHoldTime;
    
    fwrite(Write,centerHoldTime,'uint16');                                      % 3
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % --- LEDSide input --- %
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % --- 1 strcmpi(x,y) compares x and y insensitive.
    % --- 2 char() converts the AFCdata.LEDSide into a character vector
    % --- 3 this randomizes to either 1 or 3 to keep track of nose port
    % ----- (personal preference)...could also use 0s and 1s
    % ----- 1 or 3 corresponds to LEFT or RIGHT, respectively
    
    % --- for LEDSide = random
    if strcmpi(char(AFCdata.LEDSide),'rand') || strcmpi(char(AFCdata.LEDSide),'random')  % 1, 2
        
        % --- Trial Initiation detected
        if readingArduino == 'TRIAL INITIATED'
            AFCdata.nosePort = 3.^(randi([0 1]));                                               % 3
            
            if AFCdata.nosePort == 1
                AFCdata.leftTrial = 'l';
                
                if strcmpi(char(AFCdata.trialType),'pro')
                    disp('pro-Left INITIATED')
                end
                
                if strcmpi(char(AFCdata.trialType),'anti')
                    disp('anti-Left INITIATED')
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
                pause(AFCdata.LEDLength/1000);
                writePWMvoltage(Read,'D10',0);       % turn off LED
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % --- laser probability ---%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % --- no opto laser
                if strcmpi(char(AFCdata.optoTrial),'none')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                end
                
                % --- opto excitation
                if strcmpi(char(AFCdata.optoTrial),'excitation')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                    AFCdata.laserOnOff = rand;
                    if laserOnOff <= AFCdata.optoProb
                        fwrite(Write,'excitation',char);
                        if readingArduino == 'EXCITATION ON'
                            disp('EXCITATION ON');
                        end
                    end
                end
                
                % --- opto inhibition
                if strcmpi(char(AFCdata.optoTrial),'inhibition')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                    AFCdata.laserOnOff = rand;
                    if laserOnOff <= AFCdata.optoProb
                        fwrite(Write,'inhibition',char);
                        if readingArduino == 'INHIBITION ON'
                            disp('INHIBITION ON');
                        end
                    end
                end
            end
            
            
            if AFCdata.nosePort == 3
                AFCdata.rightTrial = 'r';
                
                % --- identify trialType here & write to arduino
                if strcmpi(char(AFCdata.trialType),'pro')
                    disp('pro-Right INITIATED')
                    fwrite(Write,'pro',char);
                end
                
                if strcmpi(char(AFCdata.trialType),'anti')
                    disp('anti-Right INITIATED')
                    fwrite(Write,'anti',char);
                end
                
                % --- rightLED flash
                writePWMvoltage(Read,'D11', 0.5);
                pause(AFCdata.LEDLength/1000);
                writePWMvoltage(Read,'D11',0);
                
                % --- no opto laser
                if strcmpi(char(AFCdata.optoTrial),'none')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                end
                
                % --- opto excitation
                if strcmpi(char(AFCdata.optoTrial),'excitation')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                    AFCdata.laserOnOff = rand;
                    if laserOnOff <= AFCdata.optoProb
                        fwrite(Write,'excitation',char);
                        if readingArduino == 'EXCITATION ON'
                            disp('EXCITATION ON');
                        end
                    end
                end
                
                % --- opto inhibition
                if strcmpi(char(AFCdata.optoTrial),'inhibition')
                    AFCdata.optoProb = (str2double(AFCdata.optoProb))/100;
                    AFCdata.laserOnOff = rand;
                    if laserOnOff <= AFCdata.optoProb
                        fwrite(Write,'inhibition',char);
                        if readingArduino == 'INHIBITION ON'
                            disp('INHIBITION ON');
                        end
                    end
                end
            end
        end
    end
    
    % --- for LEDSide on the LEFT only
    if strcmpi(char(AFCdata.LEDSide),'l') || strcmpi (char(AFCdata.LEDSide),'left')
        % --- left side trials only
        % --- write leftLED flash to arduino
        if readingArduino == 'TRIAL INITIATED'
            writePWMvoltage(Read, 'D10', 0.5);
            pause(AFCdata.LEDLength/1000);         % keep on for 200 ms
            writePWMvoltage(Read,'D10',0);         % turn off LED
        end
    end
    
    % --- for LEDSide on the RIGHT only
    if strcmpi(char(AFCdata.LEDSide),'r')|| strcmpi(char(AFCdata.LEDSide),'right')
        % --- right trials only
        % --- write to rightLED flash arduino
        if readingArduino == 'TRIAL INITIATED'
            writePWMvoltage(Read,'D11', 0.5);
            pause(AFCdata.LEDLength/1000);
            writePWMvoltage(Read,'D11',0);
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- Solenoid rewarding --- % %%note: find alternative to pause
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- FREE REWARD TRIALS
    if strcmpi(char(AFCdata.freeReward),'y')
        
        % --- left-side trials
        if readingArduino == 'pro-Left CORRECT'
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D5', 5); % leftSolenoid
            pause(AFCdata.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D5', 0); %close solenoid
            writePWMvoltage(Read, 'D5', 5); % 2 clicks for correct
            pause(AFCdata.rewardLength/1000);
            writePWMvoltage(Read, 'D5', 0);
            
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left REWARDED');
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Left WRONG'
            writePWMvoltage(Read,'D10',0.5); % flash the light on correct side
            pause(AFCdata.LEDlength/1000);
            writePWMvoltage(Read,'D10',0);
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left WRONG, but REWARDED');
            end
            disp('END TRIAL');
        end
        
        % --- right-side trials
        if readingArduino == 'pro-Right CORRECT'
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D6', 5); % leftSolenoid
            pause(AFCdata.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D6', 0); %close solenoid
            writePWMvoltage(Read, 'D6', 5); % 2 clicks for correct
            pause(AFCdata.rewardLength/1000);
            writePWMvoltage(Read, 'D6', 0);
            
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right REWARDED');
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Right WRONG'
            writePWMvoltage(Read,'D11',0.5); % flash the light on correct side
            pause(AFCdata.LEDlength/1000);
            writePWMvoltage(Read,'D11',0);
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right WRONG, but REWARDED');
            end
            disp('END TRIAL');
        end
    end
    
    % --- NO FREE REWARD TRIALS
    if strcmpi(char(AFCdata.freeReward),'n')
        % --- left-side trials
        if readingArduino == 'pro-Left CORRECT'
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D5', 5); % leftSolenoid
            pause(AFCdata.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D5', 0); %close solenoid
            writePWMvoltage(Read, 'D5', 5); % 2 clicks for correct
            pause(AFCdata.rewardLength/1000);
            writePWMvoltage(Read, 'D5', 0);
            
            if readingArduino == 'pro-Left REWARDED'
                disp('pro-Left REWARDED');
            end
            disp('END TRIAL');
        end
        
        if readingArduino == 'pro-Left WRONG'
            % --- light flash 2x for Wrong
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
            % --- Solenoid output to port 1 (left) in response to LED_ONE.
            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
            % --- requires 12V but the max that arduino can output is 5V
            % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
            writePWMvoltage(Read, 'D6', 5); % leftSolenoid
            pause(AFCdata.rewardLength/1000); % valve is open for .05s = 50ms
            writePWMvoltage(Read, 'D6', 0); %close solenoid
            writePWMvoltage(Read, 'D6', 5); % 2 clicks for correct
            pause(AFCdata.rewardLength/1000);
            writePWMvoltage(Read, 'D6', 0);
            
            if readingArduino == 'pro-Right REWARDED'
                disp('pro-Right REWARDED');
            end
        end
        
        if readingArduino == 'pro-Left WRONG'
            % --- light flash 2x for Wrong
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- Track trials here --- %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
trialInfo.proLeftTrial = 0;
trialInfo.antiLeftTrial = 0;
trialInfo.leftTrial = 0;
trialInfo.proLeftCorrect = 0;
trialInfo.antiLeftCorrect = 0;
trialInfo.totalLeftCorrect = 0;
trialInfo.proLeftReward = 0;
trialInfo.antiLeftReward = 0;
trialInfo.totalLeftReward = 0;
trialInfo.proLeftWrong = 0;
trialInfo.antiLeftWrong = 0;
trialInfo.totalLeftWrong = 0;
trialInfo.proLeftProb = 0;
trialInfo.antiLeftProb = 0;
trialInfo.totalLeftProb = 0;

trialInfo.proRightTrial = 0;
trialInfo.antiRightTrial = 0;
trialInfo.rightTrial = 0;
trialInfo.proRightCorrect = 0;
trialInfo.antiRightCorrect = 0;
trialInfo.totalRightCorrect = 0;
trialInfo.proRightReward = 0;
trialInfo.antiRightReward = 0;
trialInfo.totalRightReward = 0;
trialInfo.proRightWrong = 0;
trialInfo.antiRightWrong = 0;
trialInfo.totalRightWrong = 0;
trialInfo.proRightProb = 0;
trialInfo.antiRightProb = 0;
trialInfo.totalRightProb = 0;

trialInfo.optoExcitation = 0;
trialInfo.optoProExcitation = 0;
trialInfo.optoAntiExcitation = 0;
trialInfo.optoProExcitationReward = 0;
trialInfo.optoAntiExcitationReward = 0;
trialInfo.optoExcitationReward = 0;
trialInfo.optoProExcitationCorrect = 0;
trialInfo.optoAntiExcitationCorrect = 0;
trialInfo.optoExcitationCorrect = 0;
trialInfo.optoProExcitationWrong = 0;
trialInfo.optoAntiExcitationWrong = 0;
trialInfo.optoExcitationWrong = 0;
trialInfo.optoProExcitationProb = 0;
trialInfo.optoAntiExcitationProb = 0;
trialInfo.optoExcitationProb = 0;

trialInfo.optoInhibition = 0;
trialInfo.optoProInhibition = 0;
trialInfo.optoAntiInhibition = 0;
trialInfo.optoProInhibitionReward = 0;
trialInfo.optoAntiInhibitionReward = 0;
trialInfo.optoInhibitionReward = 0;
trialInfo.optoProInhibitionCorrect = 0;
trialInfo.optoAntiInhibitionCorrect = 0;
trialInfo.optoInhibitionCorrect = 0;
trialInfo.optoProInhibitionWrong = 0;
trialInfo.optoAntiInhibitionWrong = 0;
trialInfo.optoInhibitionWrong = 0;
trialInfo.optoProInhibitionProb = 0;
trialInfo.optoAntiInhibitionProb = 0;
trialInfo.optoInhibitionProb = 0;

    % --- total trial tally
    disp('TOTAL TRIAL INFO');
    if contains('END TRIAL')
       trialInfo.totalTrial = trialInfo.totalTrial + 1;
    end
    
    if contains('pro-Left REWARDED') || ...
       contains('pro-Right REWARDED')|| ...
       contains('anti-Left REWARDED')|| ...
       contains('anti-Right REWARDED')
       trialInfo.totalReward = trialInfo.totalReward + 1;
    end
    
    if contains('pro-Left WRONG') || ...
       contains('pro-Right WRONG')|| ...
       contains('anti-Left WRONG')|| ...
       contains('anti-Right WRONG')
       trialInfo.totalWrong = AFCdata.totalWrong + 1;
    end
    
        
    trialInfo.totalProb = ((trialInfo.totalCorrect)/trialInfo.trial);
trialInfo.totalCorrect = 0;
trialInfo.totalReward = 0;
trialInfo.totalWrong = 0;
trialInfo.totalProb = 0;

% --- track total opto trial info
    disp('TOTAL OPTO TRIAL INFO');
    if contains('EXCITATION ON') || contains('INHIBITION ON')
       trialInfo.totalOptoTrial = trialInfo.totalOptoTrial + 1;
    
        if contains('pro-Left CORRECT') || ...
           contains('pro-Right CORRECT')|| ...
           contains('anti-Left CORRECT')|| ...
           contains('anti-Right CORRECT')
           trialInfo.totalOptoCorrect = trialInfo.totalOptoCorrect + 1;
            
            if contains('pro-Left REWARDED') || ...
               contains('pro-Right REWARDED')|| ...
               contains('anti-Left REWARDED')|| ...
               contains('anti-Right REWARDED')
               trialInfo.totalOptoReward = trialInfo.totalOptoReward + 1;
            end
        end
            
        if contains('pro-Left WRONG') || ...
           contains('pro-Right WRONG')|| ...
           contains('anti-Left WRONG')|| ...
           contains('anti-Right WRONG')
           trialInfo.totalOptoWrong = trialInfo.totalOptoWrong + 1;
        end
    trialInfo.totalOptoProb = trialInfo.totalOptoCorrect/trialInfo.totalOptoTrial;
    end


    
    % --- Sample ElapsedTime at the end of each trial run for the while loop
    % ---------- qualifier
    ElapsedTime;
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- End the trial session --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ElapsedTime >= TrialLength || AFCdata.trial >= str2double(AFCdata.maxTrials)
    disp('ENDING SESSION');
    pause(1);
    
    % --- send all file information to a text file using fprintf()--- %
    
    
    
    % --- 1 Disconnect interface object from instrument i.e. Arduino
    % --- 2 Close file after writing video data
    % --- 3 Clear MATLAB command window
    % --- 4 Delete serial port objects from memory to MATLAB workspace
    fclose(Write);      % 1
    close all;          % 2
    clc;                % 3
    delete(instrfind);  % 4
end


