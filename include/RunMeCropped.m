 %%  GAP FILLING AND NEW C3D GENERATION
close all; clear; clc;
%%  FILE INFORMATION
filePath = 'C:\Users\szhou357\GaTech Dropbox\Sixu Zhou\Ossur Teaming\Data\CAREN\PKP04\05_29_25\mocap';
% filePath = 'C:\Users\szhou357\GaTech Dropbox\Sixu Zhou\Ossur Teaming\Data\CAREN\PKP05\PKP05_06_06_25\mocap';
StaticTrialName = 'Static03.c3d';
skiplist = {''};

jp_flag = 1; %flag to trigger preprocess section - where fix labels and jumps
progressBarEnable = 1; %flag to turn on progress bar; if you want to use this, you need to install "Instrument Control" Add-Ons
multiSubs = 1; %flag if you have more than one subject in the trial
SubjectName = 'PK_L';

%%  DEFINE FILES TO PROCESS

% Conditions
% walking_slopes = {'ascend', 'descend'};

%%  METHOD OF WORKING THROUGH MISSING MARKERS

% 1. Manually check first and last frames to be sure they're labeled correctly.
% 2. Fix jumping markers (aided by script).
% 3. Fill first/last frames and all gaps (aided by script).
% 4. Final check on any markers that are still weird.

%%  PARAMETERS

cf = 200; % collection frequency = 200 Hz
jumpThreshold = 12; % How far does have to jump in a s ingle frame to be flagged?
jumpSpeedThreshold = 7.5; % How fast does have to jump in a single frame to be flagged?
gap_th = 15; % gap detection threshold
check_th = 1;
patternCheckth = 5;
direction = {'fw','bw'}; % gap detection direction
gap_len = {1,2}; % gap detect frame lengths
gap_len_pickup = {3,2,1};
coordinates = {'x','y','z'};

%%  DEFINE RIGID BODY MARKER CLUSTERS

% % RIGHTY PK FULLBODY CLUSTERS
% clusters = {
%     {'C7', 'SSTRN', 'RSCAP','CLAV','T10','LSHO','RSHO'}; % torso
%     {'RPSIS', 'LASIS', 'RASIS', 'LPSIS','LGSIS','RGSIS'}; % pelvis
% 
%     {'LLARM','LLELB','LMELB','LMARM','LSHO'}; % left upper arm
%     {'LLFARM','LLELB','LMELB','LLWST'}; % left forearm arm1
%     {'LMFARM','LLELB','LMELB','LMWST'}; % left forearm arm2
%     {'LMFARM','LLFARM','LLWST','LMWST'}; % left forearm arm3
%     {'LFIN2','LFIN5','LMWST','LLWST'}; % left hand
% 
%     {'RLARM','RLELB','RMELB','RMARM','RSHO'}; % left upper arm
%     {'RLFARM','RLELB','RMELB','RLWST'}; % right forearm arm1
%     {'RMFARM','RLELB','RMELB','RMWST'}; % right forearm arm2
%     {'RLFARM','RMFARM','RLWST','RMWST'}; % right forearm arm3
%     {'RFIN2','RFIN5','RMWST','RLWST'}; % right hand
% 
%     {'LPTHI', 'LDTHI','LATHI','LLKNE', 'LMKNE'}; %  left femur
%     {'LPTIB', 'LDTIB','LATIB','LMANK','LLANK'}; % left tibia
%     {'LHEE', 'LMT0','LMT1','LMT2','LMT5'}; %left foot
% 
%     {'RPTHI', 'RDTHI','RATHI','RLKNE', 'RMKNE'}; %  right femur
%     {'RLKNE', 'RMKNE','RSHANK','RMANK','RLANK'}; % right tibia
%     {'RHEE', 'RMT0','RMT1','RMT2','RMT5'}; %right foot
% 
%     {'platform1','platform2','platform3','platform4','platform5'}; % platform
% };


% % RIGHTY PK FULLBODY CLUSTERS
% clusters = {
%     {'C7', 'SSTRN', 'RSCAP','CLAV','T10','LSHO','RSHO'}; % torso
%     {'RPSIS', 'LASIS', 'RASIS', 'LPSIS','LGSIS','RGSIS'}; % pelvis
% 
%     {'LLUARM','LLELB','LMELB','LMUARM','LSHO'}; % left upper arm
%     {'LLFARM','LLELB','LMELB','LLWST'}; % left forearm arm1
%     {'LMFARM','LLELB','LMELB','LMWST'}; % left forearm arm2
%     {'LFIN2','LFIN5','LMWST','LLWST'}; % left hand
% 
%     {'RLUARM','RLELB','RMELB','RMUARM','RSHO'}; % left upper arm
%     {'RLFARM','RLELB','RMELB','RLWST'}; % right forearm arm1
%     {'RMFARM','RLELB','RMELB','RMWST'}; % right forearm arm2
%     {'RFIN2','RFIN5','RMWST','RLWST'}; % right hand
% 
%     {'LPTHI', 'LDTHI','LATHI','LLKNE', 'LMKNE'}; %  left femur
%     {'LPTIB', 'LDTIB','LATIB','LMANK','LLANK'}; % left tibia
%     {'LHEE','LMT1','LMT2','LMT5'}; %left foot
%     {'LHEE','LMT1','LMT2','LMT5','LLANK','LMANK'}; %left foot
% 
%     {'RPTHI', 'RDTHI','RATHI','RLKNE', 'RMKNE'}; %  right femur
%     {'RLKNE', 'RMKNE','RPTIB','RDTIB','RMANK','RLANK'}; % right tibia
%     {'RHEE','RMT1','RMT2','RMT5'}; %right foot
%     {'RHEE','RMT1','RMT2','RMT5','RLANK','RMANK'}; %right foot
% 
%     {'platform1','platform2','platform3','platform4','platform5'}; % platform
% };

% LEFTY PK FULLBODY CLUSTERS
clusters = {
    {'C7', 'SSTRN', 'RSCAP','CLAV','T10','LSHO','RSHO'}; % torso
    {'RPSIS', 'LASIS', 'RASIS', 'LPSIS','LGSIS','RGSIS'}; % pelvis
    {'LFHD','RFHD','LBHD','RBHD','C7'}; % head

    {'LLUARM','LDUARM','LLELB','LMELB','LMUARM','LSHO'}; % left upper arm
    {'LLFARM','LLELB','LMELB','LLWST'}; % left forearm arm1
    {'LLFARM','LMFARM','LMWST','LLWST','LLELB'}; % left forearm arm3
    {'LMFARM','LLELB','LMELB','LMWST'}; % left forearm arm2
    {'LFIN2','LFIN5','LFIN0','LMWST','LLWST'}; % left hand

    {'RLUARM','RDUARM','RLELB','RMELB','RMUARM','RSHO'}; % left upper arm
    {'RLFARM','RLELB','RMELB','RLWST'}; % right forearm arm1
    {'RMFARM','RLELB','RMELB','RMWST'}; % right forearm arm2
    {'RFIN2','RFIN5','RFIN0','RMWST','RLWST'}; % right hand

    {'LPTHI', 'LDTHI','LATHI','LLKNE', 'LMKNE','LGSIS'}; %  left femur
    {'LPTIB', 'LDTIB','LMANK','LLANK','LLKNE', 'LMKNE'}; % left tibia
    % {'LHEE','LMT1','LMT2','LMT5'}; %left foot
    {'LHEE','LMT1','LMT2','LMT5','LLANK','LMANK'}; %left foot

    {'RPTHI', 'RDTHI','RATHI','RLKNE', 'RMKNE','RGSIS'}; %  right femur
    {'RLKNE', 'RMKNE','RATIB','RPTIB','RDTIB','RMANK','RLANK'}; % right tibia
    % {'RHEE','RMT1','RMT2','RMT5'}; %right foot
    {'RHEE','RMT1','RMT2','RMT5','RLANK','RMANK'}; %right foot

    {'platform1','platform2','platform3','platform4','platform5'}; % platform
};

% % RIGHTY PK FULLBODY CLUSTERS
% clusters = {
%     {'C7', 'SSTRN', 'RSCAP','CLAV','T10','LSHO','RSHO'}; % torso
%     {'RPSIS', 'LASIS', 'RASIS', 'LPSIS','LGSIS','RGSIS'}; % pelvis
%     {'LFHD','RFHD','LBHD','RBHD','C7'}; % head
% 
%     {'LLUARM','LDUARM','LLELB','LMELB','LMUARM','LSHO'}; % left upper arm
%     {'LLFARM','LLELB','LMELB','LLWST'}; % left forearm arm1
%     {'LMFARM','LLELB','LMELB','LMWST'}; % left forearm arm2
%     {'LFIN2','LFIN5','LFIN0','LMWST','LLWST'}; % left hand
% 
%     {'RLUARM','RDUARM','RLELB','RMELB','RMUARM','RSHO'}; % left upper arm
%     {'RLFARM','RLELB','RMELB','RLWST'}; % right forearm arm1
%     {'RMFARM','RLELB','RMELB','RMWST'}; % right forearm arm2
%     {'RFIN2','RFIN5','RFIN0','RMWST','RLWST'}; % right hand
% 
%     {'LPTHI', 'LDTHI','LATHI','LLKNE', 'LMKNE','LGSIS'}; %  left femur
%     {'LATIB','LPTIB', 'LDTIB','LMANK','LLANK','LLKNE', 'LMKNE'}; % left tibia
%     {'LHEE','LMT1','LMT2','LMT5','LLANK','LMANK'}; %left foot
% 
%     {'RPTHI', 'RDTHI','RATHI','RLKNE', 'RMKNE','RGSIS'}; %  right femur
%     {'RLKNE', 'RMKNE','RPTIB','RDTIB','RMANK','RLANK'}; % right tibia
%     {'RHEE','RMT1','RMT2','RMT5','RLANK','RMANK'}; %right foot
% 
%     {'platform1','platform2','platform3','platform4','platform5'}; % platform
% };


clusters_jump_threshold = {
    {60}; % torso 
    {50}; % pelvis
    {50}; % head

    {40}; % left upper arm
    {30}; % left forearm arm1
    {30}; % left forearm arm3
    {30}; % left forearm arm2
    {30}; % left hand

    {40}; % right upper arm
    {30}; % right forearm arm1
    {30}; % right forearm arm2
    {30}; % right hand

    {30}; %  left femur
    {30}; % left tibia
    {30}; %left foot
    {30}; %left foot

    {30}; %  right femur
    {30}; % right tibia
    {30}; %right foot
    {30}; %left foot

    {25}; % platform
};

markerSet = unique([clusters{:}]);
clustersOriginal = clusters;

%% ***Preprocessing -- Remove Jumping Markers + PickUp
if jp_flag
    disp('%%%%%GETTING FILE NAMES FROM DIR%%%%%')
    % read all the files from the path. Determine what are raw,
    % preprocessed and filled files
    allFiles = dir([filePath,'/*.c3d']);
    allFileNames = {allFiles(:).name};
    allFileNames = setdiff(allFileNames,skiplist);
    [markerStructRef, ~] = Vicon.ExtractMarkers_multiSubs([filePath,'\' StaticTrialName],multiSubs);
    markerDictRef = markerStruct2dict(markerStructRef);
    preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
    if ~isempty(preprocessedFileName)
        preprocessedFileName = cellfun(@(x) x(1:end-17),preprocessedFileName,'UniformOutput',false);
    end
    filledFileName = allFileNames(contains(allFileNames,'filled'));
    if ~isempty(filledFileName)
        filledFileName = cellfun(@(x) x(1:end-11),filledFileName,'UniformOutput',false);
    end

    if isempty(preprocessedFileName)
        preprocessedFileName = '';
    end
    if isempty(filledFileName)
        filledFileName = '';
    end

    checkFileList = {};
    %%
    for j = 1:length(allFileNames)
        fileName = allFileNames{j};
        c3dFile = [filePath,'\',fileName];
        
        fileName = split(fileName,'.');
        fileName = fileName{1};
        if contains(fileName,'filled')
            fileName2 = fileName(1:end-7);
        elseif contains(fileName,'preprocessed')
            fileName2 = fileName(1:end-13);
        else
            fileName2 = fileName;
        end

        if ~any(contains(lower(fileName2),'static')>0) && ~any(strcmp(filledFileName,fileName2)>0) && ~any(strcmp(preprocessedFileName,fileName2)>0) && ~any(contains(skiplist,fileName2)>0)
        % if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && any(contains(preprocessedFileName,fileName2)>0) && ~any(contains(skiplist,fileName2)>0)
            disp('==============');
            disp(fileName) % display file name in command window
                           
            [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);
            markerStructRaw = markerStruct;
            debugFlag = 0; %debugFlag enables plotting
            resetFlag = 0;
            heavyProcessNum = 2; %usually 2 is good since raw trials can be really bad in some cases and not having enough information to detect markers
            
            % markerDict = markerStruct2dict(markerStruct);   
            % TrialLength = getTrialLength(markerDict);
            % parforProperties = parcluster;
            % numWorkers = parforProperties.NumWorkers;
            % cropLength = ceil((1/numWorkers/2)*TrialLength); % utlize the workers
            % if cropLength > 1001
            %     cropLength = 1001; %set max croplength to 1001 to avoid overload on memory
            % end
            % stepLength = ceil(cropLength/2);

            % if you don't like these crop length and step length, you can
            % manually change them

            cropLength = 301;
            stepLength = 150;


            processCounter = 1;
            preprocessedFound = 1;

            missingFlag = 0;
            
            % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,840.7,279.4,nan,nan); % for trials in Treadmill region keep this
            % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4900,-5500,nan,nan); % for trials in Stair region keep this
                

            while preprocessedFound
                jump_threshold = clusters_jump_threshold;

                % Crop the trials to small ones
                disp(['%%%%%Crop Length: ',num2str(cropLength),'%%%%%'])
                markerStructTemp = cropTrialsSegments(markerStruct,markerSet,cropLength);
                
                % Iterate through each small ones and process
                SegLength = length(fieldnames(markerStructTemp));
    
                % Find first instance of each marker in markerStruct
                [firstInstanceStruct] = firstInstOfMarker(markerStruct);

                clear markerStruct;

                processFoundList = zeros(SegLength,1);
                
                markerCellPreprocessedTemp = cell(SegLength,1);
                % addAttachedFiles(gcp,["isKey"])
                %% Progress Bar
                if progressBarEnable
                    try
                        ppm = ParforProgressbar(SegLength,'showWorkerProgress', true,'progressBarUpdatePeriod', 1, 'title', [ ...
                            fileName ': Process Iteration: ' num2str(processCounter) ' CropLength= ' num2str(cropLength)]);
                    catch ME
                        if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
                            fprintf('\nMissing ''Instrument Control Toolbox'' Addons for ProgressBar functionality\nPlease install it from Matlab Add-Ons Tab\n\n');
                        end
                        rethrow(ME)
                    end
                end
                %% parallel processing segments
                parfor iii = 1:SegLength
                % for iii = 1:SegLength %for debug
                    currentSegName = ['Seg_',num2str(iii)];
                    markerStruct = markerStructTemp.(currentSegName);
                    clustertemp = clusters;
                    markerDict = markerStruct2dict(markerStruct);                
                    
                    %%
                    %find GoodFrames where all markers exisiting and correctly
                    %labeled
                    [GoodFrames,~] = FindAGoodFrame(markerDict,markerSet,markerDictRef,clustertemp,jump_threshold);
                    %find GoodFramesByCluster where markers from each rigidbody is
                    %correctly labeled
                    [GoodFramesByCluster,~,~] = FindAGoodFrameByCluster(markerDict,markerSet,markerDictRef,clustertemp,jump_threshold,GoodFrames);

                    %% Remove the marker from the cluster if the marker is missing all the time
                    % this section is to avoid script error when some markers
                    % are completely missing throughout the trial

    %                 if missingFlag
    %                     if isConfigured(GoodFramesByCluster)
    %                         GoodFrames2Markers = keys(GoodFramesByCluster);
    %                         GoodFrames2Locs = values(GoodFramesByCluster);
    %                     else
    %                         GoodFrames2Markers = {};
    %                         GoodFrames2Locs = {};
    %                     end
    % %                     markersMissing = GoodFrames2Markers(cellfun(@isempty,GoodFrames2Locs));
    %                     markersMissing = setdiff(markerSet,GoodFrames2Markers);
    %                     for m = 1:length(markersMissing)
    %                         marker = markersMissing{m};
    %                         for n = 1:length(clustertemp)
    %                             cluster = clustertemp{n};
    %                             cluster(strcmp(cluster,marker)==1)=[];
    %                             clustertemp{n} = cluster;
    %                         end
    %                     end
    %                     cellfun(@(x) disp(['Please Double Check These Markers: ',x]), markersMissing, 'UniformOutput',false);
    %     %                 continue
    %                 end
                    
                    % Cmarker is the unlabeled markers
                    markerDict = CmarkerJumpSegmentation(markerDict);
                    markerSegDict = segmentMarkers(markerDict);
                    % markerJumpSegmentation is to determine each continuous
                    % marker trajectories. It includes the starting and ending
                    % frame number for each trajectory segment. This can allow
                    % us to drop any jumps which can be picked later on
                    if processCounter <= heavyProcessNum || resetFlag == 1
                        [markerDict,~] = markerJumpSegmentation(markerSet,markerSegDict,markerDict,GoodFrames,GoodFramesByCluster);
                    end
                    %% Relink Normal Markers
                    relinkedFlag = 1;
                    markerSetToLink = markerSet;
                    % relink marker is a direct way to relabel the marker in
                    % adjacent frames using least squared means
                    while relinkedFlag
                        [markerDict,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerDict,markerDictRef,clusters,10,debugFlag);
                        processFoundList(iii) = processFoundList(iii) + 1;
                    end
        
                    %% Relabel
                    tic;
                    timelimit = 30; %Time limit to 30mins
                    fillFlag = 1;
                    markerDictTrimmed = markerDict;
        %             relinkedFlag3 = 0;
        %             markersetToFill3 = {};
                    % this section is to label the markers using three
                    % different methods: rigidbody fill, nearest neighbor
                    % search, and pattern fill
                    [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markerSet,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag);
                    [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markerSet,jump_threshold,debugFlag);
                    [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markerSet,debugFlag);
                    t = toc;

                    while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit
                        processFoundList(iii) = processFoundList(iii) + 1;
                        t = toc;
                        while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit  
                            markersetToFill = unique([markersetToFill1(:)',markersetToFill2(:)',markersetToFill3(:)']);
                            [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markersetToFill,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag);
                            [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markersetToFill,jump_threshold,debugFlag);
                            [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markersetToFill,debugFlag);
                        end
                        [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markerSet,debugFlag);
                        [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markerSet,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag);
                        [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markerSet,jump_threshold,debugFlag);
                        t = toc;
                    end
                    markerDict = markerDictTrimmed;
                    %%
                    % Next GOAL: need to work on use pattern fill to find small segments
                    %% save markerStruct for later debug
        %             save(['debugMat\',fileName,'_preprocessed.mat'],"markerStruct")
                    %%
                    markerDict = CombineUnlabeledMarkers(markerDict);
                    markerStruct = markerdict2struct(markerDict);
                    % markerStruct = QuickFix(markerStruct);
                    markerCellPreprocessedTemp{iii} = markerStruct;
                    if progressBarEnable
                        pause(0.1);
                        ppm.increment();
                    end
                end
                if progressBarEnable
                    delete(ppm);
                end
                %% RUN SECTION HERE TO TEST combineTrialsSegments (debug purpose)
                markerStructPreprocessedTemp = struct();
                for iii = 1:SegLength
                    currentSegName = ['Seg_',num2str(iii)];
                    markerStructPreprocessedTemp.(currentSegName) = markerCellPreprocessedTemp{iii};
                end
    
                %Combine the small segments back to original length
                % [markerStruct, distStruct] = combineTrialsSegments2(markerStructPreprocessedTemp);
                clear markerDict markerDictTrimmed
                markerStruct = combineTrialsSegments(markerStructPreprocessedTemp);
                clear markerStructPreprocessedTemp
                %% next iteration
                cropLength = cropLength + stepLength;
                if any(processFoundList > 1) || processCounter == 1
                    preprocessedFound = 1;
                    processCounter = processCounter + 1;
                else
                    preprocessedFound = 0;
                end

                %% Check if markers are missing after two iterations.
                if processCounter > 2 || preprocessedFound == 0
                    [missingFlag,missingClusters] = checkForMissingClusters(markerStruct, clusters);
                    if missingFlag
                        break;
                    end
                end

                %% save small trials for debugging (debug purpose)
                % if contains(fileName,'preprocessed')
                %     filledC3D = ([filePath,'\',fileName,'.c3d']);
                % else
                %     filledC3D = ([filePath,'\',fileName,'_preprocessed',num2str(processCounter),'.c3d']);
                % end
                % disp('    Writing new C3D file...')
                % 
                % markerStructTemp = markerStruct;
                % markerStruct = restoreOriginalMarkerNames(markerStruct,markerOriginalNames);
                % markerDict = markerStruct2dict(markerStruct);
                % markerDict = CombineUnlabeledMarkers(markerDict);
                % markerStruct = markerdict2struct(markerDict);
                % Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, filledC3D);
                % markerStruct = markerStructTemp;

                 %% temp functions to fix the jumped markers without enough donors (debug purpose)
                % if((~isfield(markerStruct,'RLELB')&&~isfield(markerStruct,'RMELB')) || (all(isnan(markerStruct.RLELB.x)) && all(isnan(markerStruct.RMELB.x))))
                % 
                % % if processCounter == 2 && ((~isfield(markerStruct,'RFIN2')&&~isfield(markerStruct,'RFIN5')) || (all(isnan(markerStruct.RFIN2.x)) && all(isnan(markerStruct.RFIN5.x))))
                %     markerStruct = markerStructRaw;
                %     markerStruct.RLELB.x = markerStructRaw.RMELB.x;
                %     markerStruct.RLELB.y = markerStructRaw.RMELB.y;
                %     markerStruct.RLELB.z = markerStructRaw.RMELB.z;
                % 
                %     markerStruct.RMELB.x = markerStructRaw.RLELB.x;
                %     markerStruct.RMELB.y = markerStructRaw.RLELB.y;
                %     markerStruct.RMELB.z = markerStructRaw.RLELB.z;
                %     resetFlag = 1;
                % else
                %     resetFlag = 0;
                % end
                
            end
            %% Check there is any errors in preprocessing step
            if missingFlag
                checkFileList{end + 1,1} = fileName;
                checkFileList{end,2} = missingClusters{:};
                continue
            end

            %Save data
%             markerStruct = markerdict2struct(markerDict);
            if contains(fileName,'preprocessed')
                filledC3D = ([filePath,'\',fileName,'.c3d']);
            else
                filledC3D = ([filePath,'\',fileName,'_preprocessed.c3d']);
            end
            disp('    Writing new C3D file...')
            %% this seciton removes the unlabeled markers
            markerSet_names = fieldnames(markerStruct);
            markerSet_names = markerSet_names(contains(markerSet_names,'C_'));
            for zz = 1:length(markerSet_names)
                checkMarker = markerSet_names{zz};
                if ~any(~isnan(markerStruct.(checkMarker).x))
                    markerStruct = rmfield(markerStruct,checkMarker);
                end
            end
            markerStruct
            if multiSubs
                markerStruct = restoreOriginalMarkerNames(markerStruct,markerOriginalNames,'DefaultName',SubjectName);
            end
            markerDict = markerStruct2dict(markerStruct);
            markerDict = CombineUnlabeledMarkers(markerDict);
            markerStruct = markerdict2struct(markerDict);
            try
            if multiSubs
                Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, filledC3D);
            else
                Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            end
            catch
                markerSetStruct = rmfield(markerStruct,markerSet_names);
                warning(['File: ',c3dFile,' Removed all unlabeled Markers'])
                Vicon.markerstoC3D(markerSetStruct, c3dFile, filledC3D);
            end
        end
    end
    if ~isempty(checkFileList)
        disp('%%%Trials Failed Preprocessing. Need Manual Check of Trials%%%')
        checkList = cell2table(checkFileList);
        checkList.Properties.VariableNames = {'Trial Name','Cluster Name'};
        disp(checkList)
        error('Check Trials Before Gap Fill; Check their adjacent clusters as well!')
    end
end

%%  ***GAP FILLING AND EXPORTING
% TODO: add cyclic fill to methods

exportStanding = 1; %change exportStanding to 1 to save the filled files

allFiles = dir([filePath,'/*.c3d']);
allFileNames = {allFiles(:).name};
allFileNames = setdiff(allFileNames,skiplist);
[markerStructRef,~] = Vicon.ExtractMarkers_multiSubs([filePath,'\' StaticTrialName],multiSubs);
preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
if ~isempty(preprocessedFileName)
    preprocessedFileName = cellfun(@(x) x(1:end-17),preprocessedFileName,'UniformOutput',false);
end
filledFileName = allFileNames(contains(allFileNames,'filled'));
if ~isempty(filledFileName)
    filledFileName = cellfun(@(x) x(1:end-11),filledFileName,'UniformOutput',false);
end

if isempty(preprocessedFileName)
    preprocessedFileName = '';
end
if isempty(filledFileName)
    filledFileName = '';
end

if progressBarEnable
    progressbar;
end

for j = 1:length(allFileNames)
    fileName = allFileNames{j};
    c3dFile = [filePath,'\',fileName];
    
    fileName = split(fileName,'.');
    fileName = fileName{1};
    if contains(fileName,'filled')
        fileName2 = fileName(1:end-7);
    elseif contains(fileName,'preprocessed')
        fileName2 = fileName(1:end-13);
    else
        fileName2 = fileName;
    end

    if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0) && ~any(contains(skiplist,fileName2)>0)
    % if ~any(contains(lower(fileName2),'static')>0) && ~any(strcmp(filledFileName,fileName2)>0) && any(strcmp(preprocessedFileName,fileName2)>0) && ~any(strcmp(preprocessedFileName,fileName)>0) && ~any(contains(skiplist,fileName2)>0)
        
        disp('==============');
        disp(fileName) % display file name in command window
        [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);

        % [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
        % if ~isempty(markerJumpSet)
        %     warning('Marker Jump Need to Fix')
        % end
%         markerStruct = fixJumpingMarkers(markerSet,markerStruct,jumpThreshold,gap_th);

        %Fill missing first/last and final rigid body fill
%         [starting,ending] = Find_First_And_Last_Frames(markerSet, markerStruct, markerStructRef, clusters);
        clusters = clustersOriginal;
        % markerStruct = Find_Missing_First_And_Last_FramesV2(markerSet, markerStruct, markerStructRef, clusters);
        filled = 1;
        while filled
            markerStruct = Find_Missing_First_And_Last_FramesV2(markerSet, markerStruct, markerStructRef, clusters);
            [markerStruct, filled] = Rigid_Body_Fill_All_Gaps(markerSet, markerStruct, clusters);
        end
%         missingFilled = Vicon.findGaps(markerStruct);
        %Check for jumping markers
        % checkForJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);

        %Check for missing markers (should all be filled)
        % checkForMissingMarkers(markerStruct, markerSet) 
        if multiSubs
            markerStruct = restoreOriginalMarkerNames(markerStruct,markerOriginalNames,'DefaultName',SubjectName);
        end

        %Save data
        if contains(fileName,'preprocessed')
            fileName = fileName(1:end-13);
        end
        if exportStanding==1
            filledC3D = ([filePath,'\',fileName,'_filled.c3d']);
            disp('    Writing new C3D file...')
            if multiSubs
                Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, filledC3D);
            else
                Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            end
        end
        if progressBarEnable
            pause(0.01) % Do something important
            progressbar(j/length(allFileNames)) % Update progress bar
        end
    end
end
% RunMeCropped;

%%  ***FINAL CHECK OF ALL PROCESSED TRIALS

allFiles = dir([filePath,'/*.c3d']);
allFileNames = {allFiles(:).name};
allFileNames = setdiff(allFileNames,skiplist);
[markerStructRef,~] = Vicon.ExtractMarkers_multiSubs([filePath,'\' StaticTrialName],multiSubs);
preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
if ~isempty(preprocessedFileName)
    preprocessedFileName = cellfun(@(x) x(1:end-17),preprocessedFileName,'UniformOutput',false);
end
filledFileName = allFileNames(contains(allFileNames,'filled'));
if ~isempty(filledFileName)
    filledFileName = cellfun(@(x) x(1:end-11),filledFileName,'UniformOutput',false);
end

if isempty(preprocessedFileName)
    preprocessedFileName = '';
end
if isempty(filledFileName)
    filledFileName = '';
end

FoundCheck = 0;

disp('%%%%Final Check of all filled files%%%%')
if progressBarEnable
    progressbar;
end

for j = 1:length(filledFileName)
    fileName = filledFileName{j};
    c3dFile = [filePath,'\',fileName, '_filled.c3d'];
    [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);

    NonFilledFileMarkerList = {};
    for m = 1:length(markerSet)
        markerName = markerSet{m};
        try
            dataX = markerStruct.(markerName).x;
        catch
            dataX = NaN;
        end
        if any(isnan(dataX))
            NonFilledFileMarkerList{end + 1} = markerName;
        end
    end

    if ~isempty(NonFilledFileMarkerList)
        FoundCheck = 1;
        disp(['Not Fully Filled Trial: ', fileName])
    end
    if progressBarEnable
        pause(0.01) % Do something important
        progressbar(j/length(filledFileName)) % Update progress bar
    end
end

if ~FoundCheck
    disp('%%%%All Trials are Processed!%%%%')
else
    disp('%%%% Trials not fully filled require manual fix. Please use Vicon Nexus to fix these trials%%%%')
end
            
        
        