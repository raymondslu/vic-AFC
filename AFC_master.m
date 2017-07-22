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

a = arduino('COM4', 'Uno'); % 1  use when you need to directly trigger a pin
readingArduino = fscanf(a); % 2

s = serial('COM5');         % 3  only use when requiring serial communication
fopen(s);                   % 4


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        prompt to assign values to variables        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'mouse ID',...                           1 VC# (initials and mouse number)
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
def = {'VC_0',...                 1 mouse ID
    '50',...                    2 min HoldTime in ms
    '200',...                   3 max HoldTime in ms
    'random',...                4 LED Side
    '200',...                   5 LED Length in ms
    '50',...                    6 rewardLength in ms
    'yes',...                   7 free reward
    'none',...                  8 opto Trial: none || excitation || inhibition
    '50',...                    9 opto Prob shown as full number %
    '1000',...                  10 laser Length in ms
    '5000',...                  11 maxTrials
    'pro',...                   12 taskType
    '00',...                    13 sessionID
    '70',...                    14 session length
    'no'...                     15 timeout
    '5'};                     % 16 timeout length

% --- Create a dialog box; UI = user input
UI = inputdlg(prompt,prompt_title,num_lines,def);

% --- Initialize overall session data not in UI
% --- Display time in this format Year-Month-Date Hour:Minute:Second AM/PM DayOfWeek
% --- Structure arrays contain data in fields that you access by name.
sessionData = struct('trialTally',{0},...
    'correct',{0},...
    'wrong',{0},...
    'percentageCorrect',{0},...   does not include timeouts
    'timeoutTally',{0},...
    'dateTime',{datetime('now','TimeZone','local','Format','y-MMMM-dd HH:mm:ss a eeee')},...
    'folderDate',{datestr(now, 'yyyy_mm_dd')});  % for file saving


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of overall session data        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Convert character array to a real number with str2double();
% --- Convert character array to character with char();
sessionData=struct('mouseID',char(UI{1}), ...
    'minHoldTime',str2double(UI{2}),...
    'maxHoldTime',str2double(UI{3}),...
    'LEDSide',char(UI{4}),...
    'LEDLength',str2double(UI{5}),...
    'rewardLength',str2double(UI{6}),...
    'freereward',char(UI{7}),...
    'optoTrial',char(UI{8}),...
    'optoProb',str2double(UI{9}),...
    'laserLength',str2double(UI{10}),...
    'maxTrials',str2double(UI{11}),...
    'taskType',char(UI{12}),...
    'sessionID',str2double(UI{13}),...
    'length',str2double(UI{14}),...
    'timeout',char(UI{15}),...
    'timeoutLength',str2double(UI{16}),...
    'dateTime',{sessionData.dateTime},...
    'trialTally',{sessionData.trialTally},...
    'correct',{sessionData.correct},...
    'wrong',{sessionData.wrong},...
    'percentageCorrect',{sessionData.percentageCorrect},...
    'timeoutTally',{sessionData.timeoutTally});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Keep track of trial outcome        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- store trial per trial data in a matrix
i=7;  % number of rows (# of parameters to keep track of)
j=1;  % initialize first column (each column represents the new data of each trial)

% --- prepopulate with NaN(rows, column) since it's faster than making an increasing matrix
trialData.matrix = NaN(i,sessionData.maxTrials);

% --- initialize trialData values
trialData=struct('trialType',{NaN},...
    'optoTrial',{NaN},...
    'LEDSide',{NaN},...
    'reward',{NaN},...
    'correct',{NaN},...
    'centerHoldTime',{NaN},...
    'timeout',{NaN},...
    'matrix',{trialData.matrix});

% --- replace NaN with updating trial data
trialData=struct('trialType',{trialData.trialType},...
    'optoTrial',{trialData.optoTrial},...
    'LEDSide',{trialData.LEDSide},...
    'reward',{trialData.reward},...
    'correct',{trialData.correct},...
    'centerHoldTime',{trialData.centerHoldTime},...
    'timeout',{trialData.timeout},...
    'matrix',{trialData.matrix});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        MAIN LOOP IS HERE        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Session length
startTimer = tic;
elapsedTime = toc(startTimer);
sessionData.length = 60.* str2double(sessionData.length); % (60 seconds)*(desired minutes) bc timer counts by seconds

% --- Timeout parameters: will execute the 'TimerFcn,' which is the chktime variable after the
% ----------------------- timeoutLength has been reached.
timeoutTimer = timer('TimerFcn','timingOut = 1','StartDelay',sessionData.timeoutLength);

while j<=sessionData.maxTrials || elapsedTime <= sessionData.length
    % --- assign values to the columns of j=j+1
    trialData.matrix(1,j)=trialData.trialType;          % either 0 or 1 for 'pro' or 'anti,' respectively
    trialData.matrix(2,j)=trialData.optoTrial;          % 0 = no opto, 1 = excitation, 2 = inhibition
    trialData.matrix(3,j)=trialData.LEDSide;            % either 1 or 3 for L or R, respectively for LED flash
    trialData.matrix(4,j)=trialData.reward;             % free reward: +/- 1 or +/- 3 || no free reward: 0 or 1 for no reward, rewarded
    trialData.matrix(5,j)=trialData.correct;            % correct = 1, wrong = 0
    trialData.matrix(6,j)=trialData.centerHoldTime;     % will autofill per trial
    trialData.matrix(7,j)=trialData.timeout;            % timeout = 1, no timeout = 0
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Set initial center nose port holding time        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- 1 randi(lowerbound,upperbound) generates random integer with uniform distribution
    % --- 2 uint16(array) converts the elements of an array into unsigned 16-bit (2-byte) integers
    % ----- of class uint16.
    % --- 3 send answer variable content to arduino
    
    trialData.centerHoldTime = randi([sessionData.minHoldTime,sessionData.maxHoldTime]);  % 1
    disp(trialData.centerHoldTime);
    
    trialData.centerHoldTime = uint16(trialData.centerHoldTime);  % 2
    centerHoldTime=trialData.centerHoldTime;
    
    fwrite(s,centerHoldTime,'uint16');  % 3
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        Trial initiation detected        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if readingArduino == 'TRIAL INITIATED'
        sessionData.trialTally = sessionData.trialTally + 1;
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        Timeout options        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- if timeout exists, carry out timeout here.
        switch sessionData.timeout
            case strcmpi(sessionData.timeout,'y') || strcmpi(sessionData.timeout,'yes')
                start(timeoutTimer)
                timingOut = NaN;
                while isnan(timingOut)
                    if exist('timingOut','var') == 1 && readingArduino == 'wrong'
                        trialData.timeout = 0;
                        break
                    end
                    
                    if exist('timingOut','var') == 1 && readingArduino == 'correct'
                        trialData.timeout = 0;
                        break
                    end
                    
                    if exist('timingOut','var') == 1 && timingOut == 1
                        trialData.timeout = 1;
                        break
                    end
                end
                clear timingOut
                delete(timeoutTimer);
                
            case strcmpi(sessionData.timeout,'n') || strcmpi(sessionData.timeout,'no')
                trialData.timeout = NaN;
                sessionData.timeoutTally = NaN;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        Trial type: anti || pro || blockswitch       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        switch sessionData.trialType
            case strcmpi(sessionData.trialType,'pro')
                trialData.trialType = 0;
                fwrite(s,'pro',char);
            case strcmpi(sessionData.trialType,'anti')
                trialData.trialType = 1;
                fwrite(s,'anti',char);
            case strcmpi(sessionData.trialType, 'blockswitch')
                trialData.trialType = randi([0 1]);
                if trialData.trialType == 0
                    fwrite(s,'pro',char);
                end
                if trialData.trialType == 1
                    fwrite(s,'anti',char);
                end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        LEDSide input        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- 1 strcmpi(x,y) compares x and y insensitive.
        % --- 2 char() converts the sessionData.LEDSide into a character vector
        % --- 3 this randomizes to either 1 or 3 to keep track of nose port
        % ----- (personal preference)...could also use 0s and 1s
        % ----- 1 or 3 corresponds to LEFT or RIGHT, respectively
        
        switch sessionData.LEDSide
            % --- for LEDSide = random
            case strcmpi(sessionData.LEDSide,'rand') || strcmpi(sessionData.LEDSide,'random')  % 1, 2
                trialData.LEDSide = 3.^(randi([0 1]));  % 3
                if trialData.LEDSide == 1
                    % --- leftLED flash to arduino
                    writePWMvoltage(a, 'D10', 0.5);
                    pause(sessionData.LEDLength/1000);  % keep on for 200 ms
                    writePWMvoltage(a,'D10',0);         % turn off LED
                end
                if trialData.LEDSide == 3
                    % --- rightLED flash to arduino
                    writePWMvoltage(a,'D11', 0.5);
                    pause(sessionData.LEDLength/1000);
                    writePWMvoltage(a,'D11',0);
                end
                
                % --- for LEDSide = left
            case strcmpi(sessionData.LEDSide,'l') || strcmpi (sessionData.LEDSide,'left')
                trialData.LEDSide = 1;
                if readingArduino == 'TRIAL INITIATED'
                    writePWMvoltage(a, 'D10', 0.5);
                    pause(sessionData.LEDLength/1000);  % keep on for 200 ms
                    writePWMvoltage(a,'D10',0);         % turn off LED
                end
                
                % --- for LEDSide = right
            case strcmpi(sessionData.LEDSide,'r')|| strcmpi(sessionData.LEDSide,'right')
                trialData.LEDSide = 3;
                if readingArduino == 'TRIAL INITIATED'
                    writePWMvoltage(a,'D11', 0.5);
                    pause(sessionData.LEDLength/1000);
                    writePWMvoltage(a,'D11',0);
                end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        laser probability        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        switch sessionData.optoTrial
            
            % --- no opto laser
            case strcmpi(sessionData.optoTrial,'none')
                sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                trialData.optoTrial = 0;
                
                % --- opto excitation
            case strcmpi(sessionData.optoTrial,'excitation')
                sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                laserOnOff = rand;
                if laserOnOff <= sessionData.optoProb
                    trialData.optoTrial = 1;
                    fwrite(s,'excitation',char);
                    if readingArduino == 'EXCITATION ON'
                    end
                end
                if laserOnOff > sessionData.optoProb
                    trialData.optoTrial = 0;
                end
                
                % --- opto inhibition
            case strcmpi(sessionData.optoTrial,'inhibition')
                sessionData.optoProb = (str2double(sessionData.optoProb))/100;
                laserOnOff = rand;
                if laserOnOff <= sessionData.optoProb
                    trialData.optoTrial = 2;
                    fwrite(s,'inhibition',char);
                    if readingArduino == 'INHIBITION ON'
                    end
                end
                if laserOnOff > sessionData.optoProb
                    trialData.optoTrial = 0;
                end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        Solenoid rewarding        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- FREE reward TRIALS
        switch sessionData.freereward
            case strcmpi(sessionData.freereward,'y')
                switch sessionData.trialType
                    case strcmpi(sessionData.trialType,'pro')
                        switch trialData.LEDSide
                            % --- left-side trials
                            case trialData.LEDSide == 1
                                if readingArduino == 'CORRECT'
                                    
                                    % --- tally session correct
                                    sessionData.correct = sessionData.correct + 1;
                                    
                                    % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
                                    % --- requires 12V but the max that arduino can output is 5V, use transistor
                                    % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
                                    writePWMvoltage(a, 'D5', 5);           % leftSolenoid
                                    pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                    writePWMvoltage(a, 'D5', 0);           % close solenoid
                                    writePWMvoltage(a, 'D5', 5);           % 2 clicks for correct
                                    pause(sessionData.rewardLength/1000);
                                    writePWMvoltage(a, 'D5', 0);
                                    
                                    if readingArduino == 'REWARDED'
                                        trialData.reward = 1;
                                    end
                                    if readingArduino == 'CORRECT, but NOT REWARDED'
                                        trialData.reward = -1;
                                    end
                                end
                                if readingArduino == 'WRONG'
                                    if readingArduino == 'CORRECT'
                                        writePWMvoltage(a, 'D5', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D5', 0);
                                        writePWMvoltage(a, 'D5', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D5', 0);
                                    end
                                end
                                
                            case trialData.LEDSide == 3
                                % --- right-side trials
                                if readingArduino == 'CORRECT'
                                    sessionData.correct = sessionData.correct + 1;
                                    writePWMvoltage(a, 'D6', 5);           % rightSolenoid
                                    pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                    writePWMvoltage(a, 'D6', 0);           % close solenoid
                                    writePWMvoltage(a, 'D6', 5);           % 2 clicks for correct
                                    pause(sessionData.rewardLength/1000);
                                    writePWMvoltage(a, 'D6', 0);
                                    
                                    if readingArduino == 'REWARDED'
                                        trialData.reward = 3;
                                    end
                                    if readingArduino == 'CORRECT, but NOT REWARDED'
                                        trialData.reward = -3;
                                    end
                                end
                                if readingArduino == 'WRONG'
                                    if readingArduino == 'CORRECT'
                                        writePWMvoltage(a, 'D6', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D6', 0);
                                        writePWMvoltage(a, 'D6', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D6', 0);
                                    end
                                end
                        end
                        
                    case strcmpi(sessionData.trialType,'anti')
                        switch trialData.LEDSide
                            case trialData.LEDSide == 1
                                % --- left-side trials
                                if readingArduino == 'CORRECT'
                                    writePWMvoltage(a, 'D6', 5);           % rightSolenoid
                                    pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                    writePWMvoltage(a, 'D6', 0);           % close solenoid
                                    writePWMvoltage(a, 'D6', 5);           % 2 clicks for correct
                                    pause(sessionData.rewardLength/1000);
                                    writePWMvoltage(a, 'D6', 0);
                                    
                                    if readingArduino == 'REWARDED'
                                        trialData.reward = 3;
                                    end
                                    if readingArduino == 'CORRECT, but NOT REWARDED'
                                        trialData.reward = -3;
                                    end
                                end
                                if readingArduino == 'WRONG'
                                    if readingArduino == 'CORRECT'
                                        writePWMvoltage(a, 'D6', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D6', 0);
                                        writePWMvoltage(a, 'D6', 5);
                                        pause(sessionData.rewardLength/1000);
                                        writePWMvoltage(a, 'D6', 0);
                                    end
                                end
                        end
                        
                    case trialData.LEDSide == 3
                        % --- right side trials
                        if readingArduino == 'CORRECT'
                            sessionData.correct = sessionData.correct + 1;
                            writePWMvoltage(a, 'D5', 5);           % leftSolenoid
                            pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                            writePWMvoltage(a, 'D5', 0);           % close solenoid
                            writePWMvoltage(a, 'D5', 5);           % 2 clicks for correct
                            pause(sessionData.rewardLength/1000);
                            writePWMvoltage(a, 'D5', 0);
                            
                            if readingArduino == 'REWARDED'
                                trialData.reward = 1;
                            end
                            if readingArduino == 'CORRECT, but NOT REWARDED'
                                trialData.reward = -1;
                            end
                        end
                        if readingArduino == 'WRONG'
                            if readingArduino == 'CORRECT'
                                writePWMvoltage(a, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D5', 0);
                                writePWMvoltage(a, 'D5', 5);
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D5', 0);
                            end
                        end
                end
        
        % --- NO FREE reward TRIALS
        case strcmpi(sessionData.freereward,'n')
            switch sessionData.trialType
                case strcmpi(sessionData.trialType,'pro')
                    switch trialData.LEDSide
                        % --- left-side trials
                        case trialData.LEDSide == 1
                            if readingArduino == 'CORRECT'
                                
                                % --- tally session correct
                                sessionData.correct = sessionData.correct + 1;
                                
                                % --- use writePWMVoltage instead of writeDigitalPin since the solenoid
                                % --- requires 12V but the max that arduino can output is 5V, use transistor
                                % --- writePWMVoltage(arduino, pin number, voltage output between 0 and 5V)
                                
                                writePWMvoltage(a, 'D5', 5);           % leftSolenoid
                                pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                writePWMvoltage(a, 'D5', 0);           % close solenoid
                                writePWMvoltage(a, 'D5', 5);           % 2 clicks for correct
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D5', 0);
                                
                                if readingArduino == 'REWARDED'
                                    trialData.reward = 1;
                                end
                                if readingArduino == 'CORRECT, but NOT REWARDED'
                                    trialData.reward = -1;
                                end
                            end
                            if readingArduino == 'WRONG'
                                sessionData.wrong = sessionData.wrong + 1;
                            end
                            
                        case trialData.LEDSide == 3
                            % --- right-side trials
                            if readingArduino == 'CORRECT'
                                sessionData.correct = sessionData.correct + 1;
                                writePWMvoltage(a, 'D6', 5);           % rightSolenoid
                                pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                writePWMvoltage(a, 'D6', 0);           % close solenoid
                                writePWMvoltage(a, 'D6', 5);           % 2 clicks for correct
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D6', 0);
                                
                                if readingArduino == 'REWARDED'
                                    trialData.reward = 3;
                                end
                                if readingArduino == 'CORRECT, but NOT REWARDED'
                                    trialData.reward = -3;
                                end
                            end
                            if readingArduino == 'WRONG'
                                sessionData.wrong = sessionData.wrong + 1;
                            end
                    end
                    
                    
                case strcmpi(sessionData.trialType,'anti')
                    switch trialData.LEDSide
                        case trialData.LEDSide == 1
                            % --- left-side trials
                            if readingArduino == 'CORRECT'
                                writePWMvoltage(a, 'D6', 5);           % rightSolenoid
                                pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                writePWMvoltage(a, 'D6', 0);           % close solenoid
                                writePWMvoltage(a, 'D6', 5);           % 2 clicks for correct
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D6', 0);
                                
                                if readingArduino == 'REWARDED'
                                    trialData.reward = 3;
                                end
                                if readingArduino == 'CORRECT, but NOT REWARDED'
                                    trialData.reward = -3;
                                end
                            end
                            if readingArduino == 'WRONG'
                                if readingArduino == 'CORRECT'
                                    sessionData.wrong = sessionData.wrong + 1;
                                end
                            end
                            
                        case trialData.LEDSide == 3
                            % --- right side trials
                            if readingArduino == 'CORRECT'
                                sessionData.correct = sessionData.correct + 1;
                                writePWMvoltage(a, 'D5', 5);           % leftSolenoid
                                pause(sessionData.rewardLength/1000);  % valve is open for .05s = 50ms
                                writePWMvoltage(a, 'D5', 0);           % close solenoid
                                writePWMvoltage(a, 'D5', 5);           % 2 clicks for correct
                                pause(sessionData.rewardLength/1000);
                                writePWMvoltage(a, 'D5', 0);
                                
                                if readingArduino == 'REWARDED'
                                    trialData.reward = 1;
                                end
                                if readingArduino == 'CORRECT, but NOT REWARDED'
                                    trialData.reward = -1;
                                end
                            end
                            if readingArduino == 'WRONG'
                                sessionData.wrong = sessionData.wrong + 1;
                            end
                    end
            end
        end
    end
    
    
    % --- to increase column so every add column = new trial
    j=j+1;
    
    % --- Sample elapsedTime at the end of each trial run for the while loop
    % ---------- qualifier
    elapsedTime;
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        End the trial session        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if elapsedTime > sessionData.length || sessionData.trial >= str2double(sessionData.maxTrials)
    
    % --- display total trial info to see mouse progress
    disp('SESSION END');
    sessionData.percentageCorrect = sessionData.correct/(sessionData.trialTally-sessionData.timeoutTally);
    
    % --- message box function to easily see data without looking into the
    % command window or txt file
    % --- sprintf() formats data into a string--utilizing this function for
    % ------------- summary display
    % --- display goes to console and print goes to any sort of print output
    % --- device. it is more generic. you can write code that prints to a
    % --- PDF/Printer whereas display is more limited. Print has more features
    % --- and variable names if you want to do more than just 'display'
    
    % --- Print Double-Precision Values as Integers
    % --- %i\n explicitly converts double-precision values with fractions to
    % --- integer values. %d in the formatSpec input prints each value in the
    % --- vector, as a signed integer. %s is for character vector || string array
    % --- \n is a control character that starts a new line.
    
    sessionEnd = msgbox({'2AFC_SKINNER_BOX' '' ...
        sprintf('DATE: %s', sessionData.dateTime) '' ...
        sprintf('MOUSE ID: %s', sessionData.mouseID) '' ...
        sprintf('SESSION LENGTH: %i', sessionData.length) ...
        sprintf('SESSION ID: %i', sessionData.sessionID) ...
        sprintf('TOTAL NUMBER OF TRIALS: %i', sessionData.trialTally) ...
        sprintf('TOTAL PROBABILITY: %i', sessionData.percentageCorrect) ...
        sprintf('TOTAL CORRECT: %i', sessionData.correct) ...
        sprintf('TOTAL WRONG: %i', sessionData.wrong) ...
        sprintf('TOTAL TIMEOUTS: %i', sessionData.timeoutTally) ...
        sprintf('OPTOGENETICS: %s', sessionData.optoTrial)});
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %        save data & export to file using fprintf()        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- summary of session data
    fprintf('\n DATE:                    %s\n', sessionData.dateTime);
    fprintf(' MOUSE ID:                %s\n', sessionData.mouseID);
    fprintf(' SESSION LENGTH:          %i\n', sessionData.length);
    fprintf(' SESSION ID:              %i\n', sessionData.sessionID);
    fprintf(' TOTAL NUMBER OF TRIALS:  %i\n', sessionData.trialTally);
    fprintf(' TOTAL PROBABILITY:       %i\n', sessionData.percentageCorrect);
    fprintf(' TOTAL CORRECT:           %i\n', sessionData.correct);
    fprintf(' TOTAL WRONG:             %i\n', sessionData.wrong);
    fprintf(' TOTAL TIMEOUTS:          %i\n', sessionData.timeoutTally);
    fprintf(' OPTOGENETICS:            %s\n', sessionData.optoTrial);
    
    % --- trial data figure out how to save matrix or something or print to
    % txt file and autosave
    fprintf(matrix)
    
    disp('SAVING DATA TO FILE');
    AFC_saveData(sessionData.mouseID,sessionData.sessionID,sessionData.folderDate);
    saveData = msgbox({'' 'DATA SAVE:  COMPLETE' ''});
    
    
    
    
    % --- 1 Disconnect interface object from instrument i.e. Arduino
    % --- 2 Close file after writing video data
    % --- 3 Clear MATLAB command window
    % --- 4 Delete serial port objects from memory to MATLAB workspace
    fclose(s);          % 1
    close all;          % 2
    clc;                % 3
    delete(instrfind);  % 4
end


