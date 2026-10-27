clc; clear; close all;
viconPath = getViconPath();
%% Specify paths to folders where your data is stored

folderList = {'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR03\Biomechanics_data\DOE_TIA_GR_03_PROCESSED\New Session',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR03\Biomechanics_data\DOE_TIA_GR_03_PROCESSED\New Session Exo',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR03\Biomechanics_data\DOE_TIA_GR_03_PROCESSED\New Session LC',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR04\Biomechanics_data\DOE_TIA_GR_04_PROCESSED\New Session',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR04\Biomechanics_data\DOE_TIA_GR_04_PROCESSED\New Session Exo',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR04\Biomechanics_data\DOE_TIA_GR_04_PROCESSED\New Session LC',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR05\Biomechanics_data\DOE_TIA_GR_05_PROCESSED\New Session',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR05\Biomechanics_data\DOE_TIA_GR_05_PROCESSED\New Session Exo',...
    'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR05\Biomechanics_data\DOE_TIA_GR_05_PROCESSED\New Session LC',...
    };
skiplist = {};
%% Specify your parameters
paramStruct.verbose = false; % Determines if low level functions will print information
paramStruct.cf = 200; % collection frequency = 200 Hz
paramStruct.lp = 6; % Lowpass filter cutoff freq (6 is standard, consider raising if you have high frequency tasks)
paramStruct.jumpThreshold = 12; % How far does have to jump in a s ingle frame to be flagged?
paramStruct.jumpSpeedThreshold = 7.5; % How fast does have to jump in a single frame to be flagged?
paramStruct.gap_th = 15; % gap detection threshold
paramStruct.check_th = 1;
paramStruct.patternCheckth = 5;
paramStruct.direction = {'fw','bw'}; % gap detection direction
paramStruct.gap_len = {1,2}; % gap detect frame lengths
paramStruct.gap_len_pickup = {3,2,1};
paramStruct.coordinates = {'x','y','z'};
paramStruct.xbound = [-10000,10000]; % min & max coordinates for trajectories to appear
paramStruct.ybound = [-10000,10000];
paramStruct.zbound = [-10000,10000];

%% (OPTIONAL) Put custom jump thresholds on segments (Default = 20) (name must match segment in Vicon (case insensitive)) 
custom_jump_thresholds = {
    {'Torso',60};
    {'Pelvis',40};
    {'LeftTib',15};
    {'RightTib',15};
    {'LeftFoot',30};
    {'RightFoot',30};
    {'LeftHand',30};
    {'RightHand',30};
    % {'torso1',60};
    % {'torso2',50};
    % {'left thigh',20};
    % {'left shank',20};
    % {'left tibia1',15};
    % {'left tibia2',15};
    % {'left foot1',30};
    % {'left foot2',25};
    % {'right thigh',20};
    % {'right shank',20};
    % {'right tibia1',15};
    % {'right tibia2',15};
    % {'right foot1',30};
    % {'right foot2',25};
    % {'pelvis',40};
};


%% Check that folders are valid
for i = 1:length(folderList)
    folderPath = [folderList{i} '\Failed'];
    if ~exist(folderPath, 'dir')
    error(['Folder not found: ' newline folderPath])
    end
end
%% Processing
for ii = 1:length(folderList)

    folderPath = folderList{ii};

    [clusters, clusters_jump_threshold, markerStructRef] = getMarkerSet(folderPath, viconPath,custom_jump_thresholds); %get markerstruct and reference frame from static trial
    trialList = getFailedTrials(folderPath); % get trial list
    cleanupTrials(clusters, markerStructRef,folderPath, trialList, viconPath, paramStruct);
    finishedtrialList = getFinishedTrials(folderPath);
    if ~strcmp(folderPath(end-2:end), ' LC')
    T10_relocate(folderPath,finishedtrialList)
    end
    
    % Endnote_Pass(filePath)

end

