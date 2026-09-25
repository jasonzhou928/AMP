function Main(folderList, staticFilePath, skipList, keepList, paramStruct, useVicon, app, clusters_jump_threshold, clusters, subjects)
    viconPath = getViconPath();
    %% Specify paths to folders where your data is stored
    
    % folderList = {
    %     %'C:\Users\rcasey9\GaTech Dropbox\Ryan Casey\DOE_Exos\Experiments\DOE_Task_Invariant_Protocol\GRAHAM_Collections\GR03\Biomechanics_data\DOE_TIA_GR_03_PROCESSED\New Session Demo',...
    %     'C:\Users\'
    %     };
    % error('f');
    tic

    clustersCfg = {};
    % skipList = {};
    % useVicon = false;
    autoParams = paramStruct.autoParams; 
    
    %% Specify your parameters
    % paramStruct.verbose = false; % Determines if low level functions will print information
    % paramStruct.cf = 200; % collection frequency = 200 Hz
    % paramStruct.lp = 6; % Lowpass filter cutoff freq (6 is standard, consider raising if you have high frequency tasks)
    % paramStruct.defaultJumpThreshold = 50; % How far does have to jump in a s ingle frame to be flagged?
    % paramStruct.jumpSpeedThreshold = 7.5; % How fast does have to jump in a single frame to be flagged?
    % paramStruct.gap_th = 15; % gap detection threshold
    paramStruct.check_th = 1;
    % paramStruct.patternCheckth = 5;
    paramStruct.direction = {'fw','bw'}; % gap detection direction
    paramStruct.gap_len = {1,2}; % gap detect frame lengths
    paramStruct.gap_len_pickup = {3,2,1};
    paramStruct.coordinates = {'x','y','z'};
    paramStruct.xbound = [-10000,10000]; % min & max coordinates for trajectories to appear
    paramStruct.ybound = [-10000,10000];
    paramStruct.zbound = [-10000,10000];
    paramStruct.multiSubs = false;
    % paramStruct.heavyProcessNum = 2; % number of times heavy relabelling processes will be done
    
    
    %% Check that folders are valid
    for i = 1:length(folderList)
        try
            folderPath = folderList{i};
        catch
            folderPath = folderList;
        end

        if ~exist(folderPath, 'dir')
            error(['Folder not found: ' newline folderPath])
        end
    end
    stopFlag = false;
    %% Processing
    for ii = 1:length(folderList)
    
        try
            folderPath = folderList{ii};
        catch
            folderPath = folderList;
            stopFlag = true;
        end
        checkMakeDir([folderPath '\Finished'])
        checkMakeDir([folderPath '\Working'])
        checkMakeDir([folderPath '\Failed'])
        checkMakeDir([folderPath '\Failed\Diagnostics'])
        moveMarkersetFiles(folderPath)
        if useVicon
            [clusters, clusters_jump_threshold, markerStructRef, subjects, multisubs] = getMarkerSet(folderPath, viconPath,custom_jump_thresholds,paramStruct.defaultJumpThreshold, staticFilePath); %get markerstruct and reference frame from static trial
            paramStruct.multiSubs = multisubs;
            trialList = getTrials(folderPath,skipList, keepList, staticFilePath, useVicon); % get trial list
            % trialList = folderPath;
            if autoParams
                clusters_jump_threshold = getAutoParams(clusters, markerStructRef, folderPath, trialList, viconPath, paramStruct, subjects, useVicon);
            end
            processTrials(clusters,clusters_jump_threshold, markerStructRef, folderPath, trialList, viconPath, paramStruct, subjects, useVicon, app)
        else
            markerStructRef = getMarkerStructRef(folderPath,paramStruct.multiSubs, staticFilePath);
            trialList = getTrials(folderPath,skipList, keepList, staticFilePath, useVicon); % get trial list
            
            % trialList = folderPath;
            if autoParams
                clusters_jump_threshold = getAutoParamsNoVicon(clusters, markerStructRef, folderPath, trialList, paramStruct, subjects, useVicon);
                % clusters_jump_threshold = cell(1, 16); 
                % clusters_jump_threshold(:) = {{100}}; 
            end
            if length(subjects) > 1
                paramStruct.multiSubs = true;
            end
            processTrialsNoVicon(clusters,clusters_jump_threshold, markerStructRef, folderPath, trialList, paramStruct, subjects, useVicon, app)
            
        end
    
        if stopFlag
            break;
        end
    end
    toc
    
    function checkMakeDir(directory)
        if ~exist(directory, 'dir')
           mkdir(directory)
        end
    end
end


