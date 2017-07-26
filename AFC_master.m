% --- clear in case there is previous history.
% --- Cannot access Arduino otherwise
clear; close all; clc; delete(instrfind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Call camera function here too connect and record        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run VC_WebcamRecording.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        establish global variables        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global sessionData ...  % store summary of session data here. 1 session encompasses multiple trials
    trialData;          % store trial per trial data here -- matrix form

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        establish Arduino Hardware communication        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- You cannot read and write to the same Arduino pins
% --- COM port = communication port and is from your computer's side;
%                e.g. USB

% --- 1 Connect to Arduino--- a = arduino('COM#','board type'); creates
% ----- this as an object thus you cannot also "serial read" it
% --- 2 establish serial connection between MATLAB & arduino
%       s = serial('COM#); arduino and serial must be diff boards/COM#s
% --- 3 open the serial connection--- fopen(s);
% --- NOTE --- % COM# for windows, /dev/# for mac/linux OS
objectArduino = arduino('COM4', 'Uno');          % 1  use when you need to directly trigger a pin

% --- connect the arduino object pins to the synonymous serial arduino pins
%     via breadboard

serialArduino = serial('COM5','BaudRate',9600);  % 2  only use when requiring serial communication

% --- For serial port objects, you can set Terminator to CR/LF or LF/CR. If
%     Terminator is CR/LF, the terminator is a carriage return followed by a
%     line feed. If Terminator is LF/CR, the terminator is a line feed followed
%     by a carriage return. Default is LF if you dont set the value.
set(serialArduino,'Terminator', 'CR/LF');

fopen(serialArduino);                            % 3


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        prompt to assign values to variables        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'mouse ID',...                           1 VC# (initials and mouse number)
    'session ID (#)',...                           2 track which session number the animal is on
    'minimum center hold time (ms)',...            3 unit in ms
    'maximum center hold time (ms)',...            4 unit in ms
    'LED side (left/right/random)',...             5 inputs: l || r || random
    'LED length (ms)',...                          6 unit in ms
    'reward length (ms)',...                       7 inputs: ms length to keep valve open for reward
    'free reward (yes/no)',...                     8 inputs: (y)=reward when correct finally chosen || (n)=reward only when correct 1st try
    'opto type (excitation/inhibition/none)',...   9 optogenetics--inputs: excitation||inhibition||none
    'opto probability (whole number %)',...        10 whole number % for laser probability
    'laser length (ms)',...                        11 unit in ms
    'maximum number of trials',...                 12 maximum number of trials
    'task type (pro/anti/blockswitch)',...         13 pro || anti || blockswitch
    'session length (min)',...                     14 unit in minutes
    'timeout length (s)'};                       % 15 timeout length unit in ms

% --- answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
prompt_title = '2AFC Behavior Trials';
num_lines = [1 45]; % [#OfLines  WidthOfUIField];

% --- default answers into the prompt. These can be modified per trial
def = {'VC_0',...               1 mouse ID
    '00',...                    2 session ID
    '50',...                    3 min HoldTime in ms
    '200',...                   4 max HoldTime in ms
    'random',...                5 LED Side
    '200',...                   6 LED Length in ms
    '50',...                    7 rewardLength in ms
    'yes',...                   8 free reward
    'none',...                  9 opto Trial: none || excitation || inhibition
    '50',...                    10 opto Prob shown as full number %
    '200',...                   11 laser Length in ms
    '5000',...                  12 maxTrials
    'pro',...                   13 taskType
    '70',...                    14 session length
    '5'};                     % 15 timeout length

% --- Create a dialog box; UI = user input
UI = inputdlg(prompt,prompt_title,num_lines,def);


% --- Initialize overall session data not in UI
%     Display time in this format Year-Month-Date Hour:Minute:Second AM/PM DayOfWeek
%     Structure arrays contain data in fields that you access by name.
sessionData = struct('trialTally',{0},...
    'correct',{0},...
    'wrong',{0},...
    'percentageCorrect',{0},...   does not include timeouts
    'reward',{0},...
    'timeoutTally',{0},...
    'trialDate',{datetime('now','TimeZone','local','Format','y-MMMM-dd HH:mm:ss a eeee')});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of overall session data        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Convert character array to a real number with str2double();
%     Convert character array to character with char();
sessionData=struct('mouseID',char(UI{1}),...
    'sessionID',str2double(UI{2}),...
    'minHoldTime',str2double(UI{3}),...
    'maxHoldTime',str2double(UI{4}),...
    'LEDSide',upper(char(UI{5})),...
    'LEDLength',str2double(UI{6}),...
    'rewardLength',str2double(UI{7}),...
    'freeReward',upper(char(UI{8})),...
    'optoTrial',upper(char(UI{9})),...
    'optoProbability',str2double(UI{10}),...
    'laserLength',str2double(UI{11}),...
    'maxTrials',str2double(UI{12}),...
    'taskType',upper(char(UI{13})),...
    'sessionLength',str2double(UI{14}),...
    'timeoutLength',str2double(UI{15}),...
    'trialDate',{sessionData.trialDate},...
    'trialTally',{sessionData.trialTally},...
    'correct',{sessionData.correct},...
    'wrong',{sessionData.wrong},...
    'reward',{sessionData.reward},...
    'percentageCorrect',{sessionData.percentageCorrect},...
    'timeoutTally',{sessionData.timeoutTally});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of trial outcome        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- store trial per trial data in a matrix
i=8;  % number of rows (# of parameters to keep track of)
j=0;  % initialize first column (each column represents the new data of each trial)

% --- prepopulate with NaN(rows, column) since it's faster than making an increasing matrix
trialData.matrix = NaN(i,sessionData.maxTrials);

% --- initialize trialData values
trialData=struct('taskType',{NaN},...
    'optoTrial',{NaN},...
    'LEDSide',{NaN},...
    'reward',{NaN},...
    'correct',{NaN},...
    'centerHoldTime',{NaN},...
    'timeout',{NaN},...
    'elapsedSessionTime',{NaN},...
    'matrix',{trialData.matrix});

% --- replace NaN with updating trial data
trialData=struct('taskType',{trialData.taskType},...
    'optoTrial',{trialData.optoTrial},...
    'LEDSide',{trialData.LEDSide},...
    'reward',{trialData.reward},...
    'correct',{trialData.correct},...
    'centerHoldTime',{trialData.centerHoldTime},...
    'timeout',{trialData.timeout},...
    'elapsedSessionTime',{trialData.elapsedSessionTime},...
    'matrix',{trialData.matrix});

% --- Session length
sessionStartTime = round(clock);
startSessionTimer = tic;
trialData.elapsedSessionTime = toc(startSessionTimer);
sessionData.sessionPeriod = 60.* sessionData.sessionLength; % (60 seconds)*(desired minutes) bc timer counts by seconds

% --- sessionEndTimer: timer to end the session after desired length of time
sessionEndTimer = timer('TimerFcn','sessionEnd = sessionData.sessionLength','StartDelay',sessionData.sessionPeriod);

% --- Timeout parameters: will execute the 'TimerFcn,' which is the timingOut variable after the
%                         timeoutLength has been reached.
timeoutTimer = timer('TimerFcn','timingOut = 1','StartDelay',sessionData.timeoutLength);


% --- FOR loop is useful when the number of iterations that a condition is known
%     WHILE loop is useful when the number of iterations is unknown.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        MAIN LOOP IS HERE        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start(sessionEndTimer);
while exist('sessionEnd','var') == 0 || j<sessionData.maxTrials
    
    % --- to increase column so every add column = new trial
    j=j+1;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Set initial center nose port holding time        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 randi(upperbound,upperbound) generates random integer with uniform distribution
    % --- 2 uint16(array) converts the elements of an array into unsigned 16-bit (2-byte) integers
    %       of class uint16.
    % --- 3 send answer variable content to arduino
    
    trialData.centerHoldTime = randi([sessionData.minHoldTime,sessionData.maxHoldTime]);  % 1
    
    trialData.centerHoldTime = uint16(trialData.centerHoldTime);  % 2
    centerHoldTime=trialData.centerHoldTime;
    
    
    % --- fprintf(), write data to text file
    %     fwrite(), write data to binary file
    % --- To be really precise, fprintf writes data in text, fwrite in binary format,
    %     but both functions can write to the same (mixed-type)file.
    % --- By default, data is written to the device synchronously and the command line
    %     is blocked until the operation completes. You can perform an synchronous write
    %     by configuring the mode input argument to be sync.
    fwrite(serialArduino,centerHoldTime,'uint8','sync');  % 3
    fprintf('CENTER HOLD TIME:  %i\n',centerHoldTime);
    pause(.07);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Trial initiation detected        %   &&   %        Timeout length        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- A = fscanf(obj) reads ASCII data from the device connected to the
    %         serial port object, obj, and returns it to A. The data is converted
    %         to text using the %c format.
    % --- For binary data, use fread().
    scanningSerialArduino = fscanf(serialArduino,'%s');
    readingSerialArduino = fread(serialArduino);
    
    if strcmpi(scanningSerialArduino,'trialInitiated') == 1
            sessionData.trialTally = sessionData.trialTally + 1;
            fprintf('TRIAL TALLY:  %i\n',sessionData.trialTally);
            disp('trialInitiated');
            start(timeoutTimer)
            timingOut = NaN;
                    while isnan(timingOut)
                        if exist('timingOut','var') == 0 && strcmpi(scanningSerialArduino,'CORRECT') == 1 && timingOut ~= 1
                            trialData.timeout = 0;
                            fprintf('TIMEOUT :  %i\n',trialData.timeout);
                            break
                        elseif exist('timingOut','var') == 0 && strcmpi(scanningSerialArduino,'WRONG') == 1 && timingOut ~= 1
                            trialData.timeout = 0;
                            fprintf('TIMEOUT :  %i\n',trialData.timeout);
                            break
                        elseif exist('timingOut','var') == 1 && timingOut == 1
                            trialData.timeout = 1;
                            fprintf('TIMEOUT :  %i\n',trialData.timeout);
                            break
                        end
                    end
                    clear timingOut
                    delete(timeoutTimer);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Trial type: pro || anti || blockswitch       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch sessionData.taskType
        case 'pro'
            trialData.taskType = 0;
            fprintf(serialArduino,'%s','p','sync');
            fprintf('TASK TYPE:  %i\n',trialData.taskType);
        case 'anti'
            trialData.taskType = 1;
            fprintf(serialArduino,'%s','a','sync');
            fprintf('TASK TYPE:  %i\n',trialData.taskType);
        case 'blockswitch'
            trialData.taskType = randi([0 1]);
            if trialData.taskType == 0
                fprintf(serialArduino,'%s','p','sync');
                fprintf('TASK TYPE:  %s',trialData.taskType);
            elseif trialData.taskType == 1
                fprintf(serialArduino,'%s','a','sync');
                fprintf('TASK TYPE:  %s',trialData.taskType);
            end
        otherwise
            disp('BAD INPUT FOR taskType');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        LEDSide input        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 strcmpi(x,y) compares x and y insensitive.
    % --- 2 char() converts the sessionData.LEDSide into a character vector
    % --- 3 this randomizes to either 1 or 3 to keep track of nose port
    %       (personal preference)...could also use 0s and 1s
    %       1 or 3 corresponds to LEFT or RIGHT, respectively
    
    % --- for LEDSide = random
    switch sessionData.LEDSide
        case {'rand','random'}
            trialData.LEDSide = 3.^(randi([0 1]));  % 3
            fprintf('LED SIDE:  %i\n',trialData.LEDSide);
            
            if trialData.LEDSide == 1
                % --- leftLED flash to arduino
                writePWMVoltage(objectArduino, 'D10', 0.5);
                pause(sessionData.LEDLength/1000);              % keep on for 200 ms
                writePWMVoltage(objectArduino,'D10',0);         % turn off LED
            elseif trialData.LEDSide == 3
                % --- rightLED flash to arduino
                writePWMVoltage(objectArduino,'D11', 0.5);
                pause(sessionData.LEDLength/1000);
                writePWMVoltage(objectArduino,'D11',0);
            end
            
            % --- for LEDSide = left
        case {'l','left'}
            trialData.LEDSide = 1;
            fprintf('LED SIDE:  %i\n',trialData.LEDSide);
            
            writePWMVoltage(objectArduino, 'D10', 0.5);
            pause(sessionData.LEDLength/1000);                  % keep on for 200 ms
            writePWMVoltage(objectArduino,'D10',0);             % turn off LED
            
            % --- for LEDSide = right
        case {'r','right'}
            trialData.LEDSide = 3;
            fprintf('LED SIDE:  %i\n',trialData.LEDSide);
            writePWMVoltage(objectArduino,'D11', 0.5);
            pause(sessionData.LEDLength/1000);                  % keep on for 200 ms
            writePWMVoltage(objectArduino,'D11',0);             % turn off LED
        otherwise
            disp('BAD INPUT FOR LEDSide');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        laser probability        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch sessionData.optoTrial
        % --- no opto laser
        case {'n','no','none'}
            sessionData.optoProbability = sessionData.optoProbability/100;
            trialData.optoTrial = 0;
            fprintf('OPTO TRIAL:  %i\n',trialData.optoTrial);
            
            % --- opto excitation
        case {'e','ex','excitation'}
            sessionData.optoProbability = sessionData.optoProbability/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProbability
                trialData.optoTrial = 1;
                fprintf('OPTO TRIAL:  %i\n',trialData.optoTrial);
                writePWMVoltage(objectArduino,'D3',5);
                pause(sessionData.laserLength);
                writePWMVoltage(objectArduino,'D3',0)
            elseif laserOnOff > sessionData.optoProbability
                trialData.optoTrial = 0;
                fprintf('OPTO TRIAL:  %i\n',trialData.optoTrial);
            end
            
            % --- opto inhibition
        case {'i','in','inhibition'}
            sessionData.optoProbability = sessionData.optoProbability/100;
            laserOnOff = rand;
            if laserOnOff <= sessionData.optoProbability
                trialData.optoTrial = 2;
                fprintf('OPTO TRIAL:  %i\n',trialData.optoTrial);
                writePWMVoltage(objectArduino,'D3',5);
                pause(sessionData.laserLength);
                writePWMVoltage(objectArduino,'D3',0)
            elseif laserOnOff > sessionData.optoProbability
                trialData.optoTrial = 0;
                fprintf('OPTO TRIAL:  %i\n',trialData.optoTrial);
            end
        otherwise
            disp('BAD INPUT FOR optoTrial');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Solenoid rewarding        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch sessionData.freeReward
        
        % --- FREE REWARD TRIALS
        case {'y','yes'}
            switch sessionData.taskType
                case 'pro'
                    % --- left-side trial
                    if trialData.LEDSide == 1
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            trialData.correct = 1;
                            % --- tally session correct
                            sessionData.correct = sessionData.correct + 1;
                            fprintf('CORRECT :  %i\n',sessionData.correct);
                            
                            % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
                            %     requires 12V but the max that arduino can output is 5V, use transistor
                            %     writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
                            writePWMVoltage(objectArduino, 'D5', 5);           % leftSolenoid
                            pause(sessionData.rewardLength/1000);              % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D5', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D5', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D5', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 1;
                                sessionData.reward = sessionData.reward + 1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            trialData.correct = 0;
                            sessionData.wrong = sessionData.wrong + 1;
                            if strcmpi(scanningSerialArduino,'CORRECT') == 1
                                writePWMVoltage(objectArduino, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D5', 0);
                                writePWMVoltage(objectArduino, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D5', 0);
                                if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                    trialData.reward = 1;
                                    sessionData.reward = sessionData.reward + 1;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                    trialData.reward = -1;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                end
                            end
                        end
                        sessionData.reward = sessionData.reward + 1;
                        fprintf('REWARD :  %i\n',trialData.reward);
                        
                    elseif trialData.LEDSide == 3
                        % --- right-side trials
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            writePWMVoltage(objectArduino, 'D6', 5);           % rightSolenoid
                            pause(sessionData.rewardLength/1000);              % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D6', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D6', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D6', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                            
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            if strcmpi(scanningSerialArduino,'CORRECT') == 1
                                writePWMVoltage(objectArduino, 'D6', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D6', 0);
                                writePWMVoltage(objectArduino, 'D6', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D6', 0);
                                sessionData.reward = sessionData.reward + 1;
                                trialData.reward = 3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        end
                    end
                case 'anti'
                    if trialData.LEDSide == 1
                        % --- left-side trials
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            writePWMVoltage(objectArduino, 'D6', 5);           % rightSolenoid
                            pause(sessionData.rewardLength/1000);              % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D6', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D6', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D6', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            sessionData.wrong = sessionData.wrong + 1;
                            trialData.correct = 0;
                            if strcmpi(scanningSerialArduino,'CORRECT') == 1
                                writePWMVoltage(objectArduino, 'D6', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D6', 0);
                                writePWMVoltage(objectArduino, 'D6', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D6', 0);
                                if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                    trialData.reward = 3;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                    trialData.reward = -3;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                end
                            end
                        end
                        
                    elseif trialData.LEDSide == 3
                        % --- right side trials
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            writePWMVoltage(objectArduino, 'D5', 5);           % leftSolenoid
                            pause(sessionData.rewardLength/1000);              % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D5', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D5', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D5', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            if strcmpi(scanningSerialArduino,'CORRECT') == 1
                                writePWMVoltage(objectArduino, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D5', 0);
                                writePWMVoltage(objectArduino, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMVoltage(objectArduino, 'D5', 0);
                                if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                    sessionData.reward = sessionData.reward + 1;
                                    trialData.reward = 1;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                    trialData.reward = -1;
                                    fprintf('REWARD :  %i\n',trialData.reward);
                                end
                            end
                        end
                    end
            end
            
            
            % --- NO FREE REWARD TRIALS
        case {'n','no','none'}
            switch sessionData.taskType
                case 'pro'
                    % --- left-side trials
                    if trialData.LEDSide == 1
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            
                            writePWMVoltage(objectArduino, 'D5', 5);           % leftSolenoid
                            pause(sessionData.rewardLength/1000);              % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D5', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D5', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D5', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            sessionData.wrong = sessionData.wrong + 1;
                            trialData.correct = 0;
                            trialData.reward = 0;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            fprintf('REWARD :  %i\n',trialData.reward);
                        end
                        
                        % --- right-side trials
                    elseif trialData.LEDSide == 3
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            
                            writePWMVoltage(objectArduino, 'D6', 5);           % rightSolenoid
                            pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D6', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D6', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D6', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            sessionData.wrong = sessionData.wrong + 1;
                            trialData.correct = 0;
                            trialData.reward = 0;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            fprintf('REWARD :  %i\n',trialData.reward);
                        end
                    end
                    
                    % --- left-side trials
                case 'anti'
                    if trialData.LEDSide == 1
                        if strcmpi(scanningSerialArduino,'CORRECT') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            
                            writePWMVoltage(objectArduino, 'D6', 5);           % rightSolenoid
                            pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D6', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D6', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D6', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -3;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            sessionData.wrong = sessionData.wrong + 1;
                            trialData.correct = 0;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                        end
                        
                        % --- right side trials
                    elseif trialData.LEDSide == 3
                        if strcmpi(scanningSerialArduino,'CORRECT)') == 1
                            sessionData.correct = sessionData.correct + 1;
                            trialData.correct = 1;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                            
                            writePWMVoltage(objectArduino, 'D5', 5);           % leftSolenoid
                            pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                            writePWMVoltage(objectArduino, 'D5', 0);           % close solenoid
                            writePWMVoltage(objectArduino, 'D5', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMVoltage(objectArduino, 'D5', 0);
                            
                            if strcmpi(scanningSerialArduino,'REWARDED') == 1
                                trialData.reward = 1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            elseif strcmpi(scanningSerialArduino,'CORRECT, but NOT REWARDED') == 1
                                trialData.reward = -1;
                                fprintf('REWARD :  %i\n',trialData.reward);
                            end
                        elseif strcmpi(scanningSerialArduino,'WRONG') == 1
                            sessionData.wrong = sessionData.wrong + 1;
                            trialData.correct = 0;
                            fprintf('CORRECT :  %i\n',trialData.correct);
                        end
                    end
            end
        otherwise
            disp('BAD INPUT FOR FREE REWARD');
    end
    
    
    % --- assign values to the columns of j=j+1 after obtaining them
    trialData.matrix(1,j)=trialData.taskType;           % either 0 or 1 for 'pro' or 'anti,' respectively
    trialData.matrix(2,j)=trialData.optoTrial;          % 0 = no opto, 1 = excitation, 2 = inhibition
    trialData.matrix(3,j)=trialData.LEDSide;            % either 1 or 3 for L or R, respectively for LED flash
    trialData.matrix(4,j)=trialData.reward;             % free reward: +/- 1 or +/- 3 || no free reward: 0 or 1 for no reward, rewarded
    trialData.matrix(5,j)=trialData.correct;            % correct = 1, wrong = 0
    trialData.matrix(6,j)=trialData.centerHoldTime;     % will autofill per trial
    trialData.matrix(7,j)=trialData.elapsedSessionTime; % track the elapsed session time here to relate back to video
    trialData.matrix(8,j)=trialData.timeout;            % timeout = 1, no timeout = 0
    
    
    % --- Sample elapsedTime at the end of each trial run for the while loop qualifier
    trialData.elapsedSessionTime = toc(startSessionTimer);
    trialData.elapsedSessionTime;
    fprintf('ELAPSED SESSION LENGTH:  %i\n',trialData.elapsedSessionTime/60);
    
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        End the trial session        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('sessionEnd','var') == 1 || sessionData.trialTally >= sessionData.maxTrials
    
    % --- display total trial info to see mouse progress
    trialEndTime = round(clock);
    session = (trialEndTime - sessionStartTime)/60;
    fprintf('\n %s\n', 'SESSION END', session);
    sessionData.percentageCorrect = sessionData.correct/(sessionData.trialTally-sessionData.timeoutTally);
    
    % --- message box function to easily see data without looking into the command window
    % --- sprintf() formats data into a string--utilizing this function for
    %     summary display
    % --- display goes to console and print goes to any sort of print output
    %     device. it is more generic. you can write code that prints to a
    %     PDF/Printer whereas display is more limited. Print has more features
    %     and variable names if you want to do more than just 'display'
    
    % --- Print Double-Precision Values as Integers
    %     %i\n explicitly converts double-precision values with fractions to
    %     integer values. %d in the formatSpec input prints each value in the
    %     vector, as a signed integer. %s is for character vector || string array
    % --- \n is a control character that starts a new line.
    
    sessionEnd = msgbox({'2AFC_SKINNER_BOX' '' ...
        sprintf('DATE: %s', sessionData.trialDate) '' ...
        sprintf('MOUSE ID: %s', sessionData.mouseID) '' ...
        sprintf('SESSION LENGTH: %i', sessionData.sessionLength) ...
        sprintf('SESSION ID: %i', sessionData.sessionID) ...
        sprintf('TOTAL NUMBER OF TRIALS: %i', sessionData.trialTally) ...
        sprintf('TOTAL PROBABILITY: %i', sessionData.percentageCorrect) ...
        sprintf('TOTAL CORRECT: %i', sessionData.correct) ...
        sprintf('TOTAL WRONG: %i', sessionData.wrong) ...
        sprintf('TOTAL TIMEOUTS: %i', sessionData.timeoutTally) ...
        sprintf('OPTOGENETICS: %s', sessionData.optoTrial)});
    
    % --- summary of session data
    fprintf('\n DATE:                    %s\n', sessionData.trialDate);
    fprintf(' MOUSE ID:                %s\n', sessionData.mouseID);
    fprintf(' SESSION LENGTH:          %i\n', sessionData.sessionLength);
    fprintf(' SESSION ID:              %i\n', sessionData.sessionID);
    fprintf(' TOTAL NUMBER OF TRIALS:  %i\n', sessionData.trialTally);
    fprintf(' TOTAL PROBABILITY:       %i\n', sessionData.percentageCorrect);
    fprintf(' TOTAL CORRECT:           %i\n', sessionData.correct);
    fprintf(' TOTAL WRONG:             %i\n', sessionData.wrong);
    fprintf(' TOTAL TIMEOUTS:          %i\n', sessionData.timeoutTally);
    fprintf(' OPTOGENETICS:            %s\n', sessionData.optoTrial);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        save data & export to file        % --- Saving workspace: sessionData and trialData
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- Makes "MouseID" folder in location of choice
    mouseIDParentFolder = fullfile('Desktop');
    if (exist(mouseIDParentFolder,'dir') == 0)
        mkdir (mouseIDParentFolder);
    end
    
    % --- Makes a folder within "MouseIDs" that's called the actual mouse's ID
    individualMouseIDFolder = fullfile(mouseIDParentFolder,num2str(sessionData.mouseID));
    if (exist(individualMouseIDFolder, 'dir') == 0)
        mkdir(individualMouseIDFolder);
    end
    
    % --- Generates a path within the mouse's ID folder
    sessionFile = fullfile(individualMouseIDFolder,num2str(sessionData.sessionID));
    
    % --- Saves workspace inside that folder
    save(sessionFile);
    saveData = msgbox({'' 'DATA SAVE:  COMPLETE' ''});
    
    
    % --- 1 Disconnect interface object from instrument i.e. Arduino
    % --- 2 Close file after writing video data
    % --- 3 Delete serial port objects from memory to MATLAB workspace
    fclose(serialArduino);          % 1
    fclose(appenderFile);
    close all;          % 2
    delete(instrfind);  % 3
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        AUTHOR INFORMATION        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AUTHOR: Victoria Cheung
% Tetrad PhD Program | University of California, San Francisco
% EMAIL: Victoria.Cheung@ucsf.edu
% MATRICULATION YEAR: Sept. 2015

% PRINCIPAL INVESTIGATOR: Evan H. Feinberg, PhD
% Department of Anatomy
% ADDRESS: 1500 4th St Box 2822, San Francisco, CA 94158
