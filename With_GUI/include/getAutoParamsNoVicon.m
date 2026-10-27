function [clusters_jump_threshold] = getAutoParamsNoVicon(clusters, markerStructRef, folderPath, trialList, paramStruct, subjects, useVicon)
markerDictRef = markerStruct2dict(markerStructRef);
debugFlag = 0; %debugFlag enables plotting


%%  PARAMETERS
multiSubs = paramStruct.multiSubs;
verbose = paramStruct.verbose;
cf = paramStruct.cf;
lp = paramStruct.lp;
jumpThreshold = paramStruct.defaultJumpThreshold;
jumpSpeedThreshold = paramStruct.jumpSpeedThreshold;
gap_th = paramStruct.gap_th;
check_th = paramStruct.check_th;
patternCheckth = paramStruct.patternCheckth;
direction = paramStruct.direction;
gap_len = paramStruct.gap_len;
gap_len_pickup = paramStruct.gap_len_pickup;
coordinates = paramStruct.coordinates;
xbound = paramStruct.xbound; % min & max coordinates for trajectories to appear
ybound = paramStruct.ybound;
zbound = paramStruct.zbound;
heavyProcessNum = paramStruct.heavyProcessNum;
multiSubs = paramStruct.multiSubs;


markerSet = unique([clusters{:}]);
thresholdArr = [];




%% Get trial subset
trialNum = floor(length(trialList)*.5)+1;
if trialNum > 5
    trialNum = 5;
end
trialInds = floor(linspace(1,length(trialList),trialNum));


%% ***LOAD MARKER JUMP DETECT THRESHOLD LIST
load("MarkerJumpThresholdListOSL.mat")
currentTrialInd = 0;
for i = trialInds
    currentTrialInd = currentTrialInd+ 1;
    %%  Set Initial Clusters to default value (15)
    clusters_jump_threshold = {};
    for ci = 1:length(clusters)
        clusters_jump_threshold{ci} = {15};
        previous_jump_thresholds{ci} = {15};
        lower_bound_thresholds{ci} = {15};
        enforce_high_thresholds{ci} = 0;
    end
    fprintf(['\n\n\n Using Trial ~' trialList{i} '~ to Determine Jump Thresholds \n\n\n\n'])
    copyfile([folderPath '\' trialList{i} '.c3d'],[folderPath '\Working\' trialList{i} '.c3d'])
    for opt = 1:6
    
    c3dFile = [folderPath '\Working\' trialList{i} '.c3d'];
    [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);
    debugFlag = 0; %debugFlag enables plotting
    resetFlag = 0;

    %crop markerStruct to middle 200 frames if trial is long (prevents unnecessary
    %time spent tuning)

    names = fieldnames(markerStruct);
    if height(markerStruct.(names{1})) > 202
        midpoint = round(height(markerStruct.(names{1}))/2);
        sI = midpoint -100;
        eI = midpoint + 99;
        for mn = 1:length(names)
            markerStruct.(names{mn}) = markerStruct.(names{mn})(sI:eI,:);
        end
    end

    jump_threshold = clusters_jump_threshold;
    markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,xbound(2),xbound(1),zbound(2),zbound(1),verbose); % for trials in Treadmill region keep this
    % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4900,-5500,nan,nan); % for trials in Stair region keep this

    % The crop length is determined by the largest gap length
    markerDict = markerStruct2dict(markerStruct);

    disp(['%%%%%%%%%%%%%%%%% Iteration ' num2str(opt) ' %%%%%%%%%%%%%%%%'])
    cropLength = 301;
            stepLength = 150;


            
            processCounter = 1;
            preprocessedFound = 1;

            missingFlag = 0;
            
            % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,840.7,279.4,nan,nan); % for trials in Treadmill region keep this
            % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4900,-5500,nan,nan); % for trials in Stair region keep this
                

            while preprocessedFound
                jump_threshold = clusters_jump_threshold;

                % 
                markerStructTemp = cropTrialsSegments(markerStruct,markerSet,cropLength);
                
                % Iterate through each small ones and process
                SegLength = length(fieldnames(markerStructTemp));
    
                % Find first instance of each marker in markerStruct
                [firstInstanceStruct] = firstInstOfMarker(markerStruct);

                clear markerStruct;

                processFoundList = zeros(SegLength,1);
                
                markerCellPreprocessedTemp = cell(SegLength,1);
                % addAttachedFiles(gcp,["isKey"])
                %% parallel processing segments
                parfor iii = 1:SegLength
                % for iii = 1:SegLength
                % for iii = 1:SegLength %for debug
                    currentSegName = ['Seg_',num2str(iii)];
                    markerStruct = markerStructTemp.(currentSegName);
                    clustertemp = clusters;
                    markerDict = markerStruct2dict(markerStruct);                
                    
                    %%
                    %find GoodFrames where all markers exisiting and correctly
                    %labeled
                    [GoodFrames,~] = FindAGoodFrame(markerDict,markerSet,markerDictRef,clustertemp,jump_threshold,verbose);
                    %find GoodFramesByCluster where markers from each rigidbody is
                    %correctly labeled
                    [GoodFramesByCluster,~,~] = FindAGoodFrameByCluster(markerDict,markerSet,markerDictRef,clustertemp,jump_threshold,GoodFrames,verbose);


                    markerDict = CmarkerJumpSegmentation(markerDict,verbose);
                    markerSegDict = segmentMarkers(markerDict,verbose);
                    % markerJumpSegmentation is to determine each continuous
                    % marker trajectories. It includes the starting and ending
                    % frame number for each trajectory segment. This can allow
                    % us to drop any jumps which can be picked later on
                    if processCounter <= heavyProcessNum || resetFlag == 1
                        [markerDict,~] = markerJumpSegmentation(markerSet,markerSegDict,markerDict,GoodFrames,GoodFramesByCluster,verbose);
                    end
                    %% Relink Normal Markers
                    relinkedFlag = 1;
                    markerSetToLink = markerSet;
                    % relink marker is a direct way to relabel the marker in
                    % adjacent frames using least squared means
                    while relinkedFlag
                        [markerDict,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerDict,markerDictRef,clusters,10,debugFlag,verbose);
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
                    [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markerSet,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag,verbose);
                    [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markerSet,jump_threshold,debugFlag,verbose);
                    [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markerSet,debugFlag,verbose);
                    t = toc;

                    while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit
                        processFoundList(iii) = processFoundList(iii) + 1;
                        t = toc;
                        while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit  
                            markersetToFill = unique([markersetToFill1(:)',markersetToFill2(:)',markersetToFill3(:)']);
                            [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markersetToFill,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag,verbose);
                            [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markersetToFill,jump_threshold,debugFlag,verbose);
                            [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markersetToFill,debugFlag,verbose);
                        end
                        [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clustertemp,markerSet,debugFlag,verbose);
                        [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clustertemp,markerSet,GoodFrames,GoodFramesByCluster,jump_threshold,debugFlag,verbose);
                        [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clustertemp,markerSet,jump_threshold,debugFlag,verbose);
                        t = toc;
                    end
                    markerDict = markerDictTrimmed;
                    %%
                    % Next GOAL: need to work on use pattern fill to find small segments
                    %% save markerStruct for later debug
        %             save(['debugMat\',fileName,'_preprocessed.mat'],"markerStruct")
                    %%
                    markerDict = CombineUnlabeledMarkers(markerDict,verbose);
                    markerStruct = markerdict2struct(markerDict);
                    % markerStruct = QuickFix(markerStruct);
                    markerCellPreprocessedTemp{iii} = markerStruct;
                    
                end

                markerStructPreprocessedTemp = struct();
                for iii = 1:SegLength
                    currentSegName = ['Seg_',num2str(iii)];
                    markerStructPreprocessedTemp.(currentSegName) = markerCellPreprocessedTemp{iii};
                end
    
                %Combine the small segments back to original length
                % [markerStruct, distStruct] = combineTrialsSegments2(markerStructPreprocessedTemp);
                clear markerDict markerDictTrimmed;
                markerStruct = combineTrialsSegments(markerStructPreprocessedTemp);
                clear markerStructPreprocessedTemp;
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
                    [missingFlag,~] = checkForMissingClusters(markerStruct, clusters);
                    if missingFlag
                        break;
                    end
                end

                
            end

    %% Check preprocessed outcome
    markerDict = markerStruct2dict(markerStruct);
    [previous_jump_thresholds, clusters_jump_threshold, lower_bound_thresholds, enforce_high_thresholds] = checkThresholds(clusters, clusters_jump_threshold, previous_jump_thresholds, lower_bound_thresholds, enforce_high_thresholds, markerDict);

    

    end

    for cc = 1:length(clusters)
       
        if previous_jump_thresholds{cc}{1} < 10
            thresholdArr(cc,currentTrialInd) = 10; %min jump thresh
        else    
        thresholdArr(cc,currentTrialInd) = previous_jump_thresholds{cc}{1};
        end
        if enforce_high_thresholds{cc} == 1
            thresholdArr(cc,currentTrialInd) = previous_jump_thresholds{cc}{1} *1.8;
            if thresholdArr(cc,currentTrialInd) < 40
                thresholdArr(cc,currentTrialInd) = 40;
            end
        end
    end
end

for aa = 1:length(thresholdArr)
    clusters_jump_threshold{aa}{1} = max(thresholdArr(aa,:))*1.1;
    if clusters_jump_threshold{aa}{1} > 60
        warning('Cluster requires abnormally high threshold for auto labelling')
        disp(clusters{aa})
    end
end
fprintf('\n\n\n Jump Thresholds Determined \n\n\n\n')
end