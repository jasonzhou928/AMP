function processTrials(clusters,clusters_jump_threshold, markerStructRef, folderPath, trialList, viconPath,paramStruct, subjects, useVicon, app)
markerDictRef = markerStruct2dict(markerStructRef);
debugFlag = 0; %debugFlag enables plotting

checkVicon(viconPath)
vicon = ViconNexus();

try
    gaugeInc = 100 / length(trialList);
catch
    gaugeInc = 0;
end
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

%%  DEFINE RIGID BODY MARKER CLUSTERS

markerSet = unique([clusters{:}]);
clustersOriginal = clusters;


%% ***LOAD MARKER JUMP DETECT THRESHOLD LIST
load("MarkerJumpThresholdListOSL.mat")

for i = 1:length(trialList)
    fprintf(['\n\n\n\n\tProcessing Trial ' trialList{i} '\n\n\n\n\n'])
    app.CurrentlyProcessingLabel.Text = ['Currently Processing: ' trialList{i}];
    app.Gauge.Value = app.Gauge.Value + gaugeInc;
    drawnow;

    doneWithTrial = false;
    kinFillStart = 0;
    skipLabelAdjust = 0;
    labelingIssue = 0;
    combinedProcessingPipeline = 'Reconstruct And Label';
    while ~doneWithTrial %replace with while loop later    
    baseFile = [folderPath '\' trialList{i}];
    %% Attempt all Vicon Operations for this Pass
    doing_vicon_operations = true;
    heavyOps = false;
    if strcmpi(combinedProcessingPipeline,'Failed')
        doneWithTrial = true;
        warning(['Trial: ' trialList{i} ' failed... moving on'])
        copyfile([folderPath '\Working\' trialList{i} '.c3d'],[folderPath '\Failed\' trialList{i} '.c3d'])
        copyfile([folderPath '\Working\' trialList{i} '.trial.enf'],[folderPath '\Failed\' trialList{i} '.trial.enf'])
        delete([folderPath '\Working\' trialList{i} '.c3d'])
        delete([folderPath '\Working\' trialList{i} '.trial.enf'])
        continue
    end
    while doing_vicon_operations 
        try   
        vicon.OpenTrial(baseFile, 60);
        for sb = 1:length(subjects)
            subj = subjects{sb};
            vicon.SetSubjectActive(subj, '1');
        end
        vicon.RunPipeline(combinedProcessingPipeline, '', 300);
        
        vicon.RunPipeline('ExportC3D', '', 100);
        vicon.SaveTrial(60);
        vicon.CloseTrial(60);
        catch

            createEndnoteFilter(folderPath,baseFile)
            warning('Problem communicating with Vicon... Attempting to reconnect')
            checkReopenVicon(viconPath);
            Vicon_Openned = false;
            while ~Vicon_Openned
            try
            vicon = ViconNexus();
            catch 
                pause(5)
                continue
            end
            Vicon_Openned = true;
            end
            continue

        end
        doing_vicon_operations = false;
        copyfile([baseFile '.c3d'],[folderPath '\Working\' trialList{i} '.c3d']);
        createEndnoteFilter(folderPath,[folderPath '\Working\' trialList{i}]);
    end
    %%
    c3dFile = [folderPath '\Working\' trialList{i} '.c3d'];
    [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);
    debugFlag = 0; %debugFlag enables plotting
    resetFlag = 0;
    if kinFillStart
            markerStruct = kinFilling(markerStruct,markerStructRef,[folderPath '\Working\' trialList{i}],viconPath,folderPath);
            heavyOps = true;
    end
    

    jump_threshold = clusters_jump_threshold;
    markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,xbound(2),xbound(1),zbound(2),zbound(1),verbose); % for trials in Treadmill region keep this
    % markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4900,-5500,nan,nan); % for trials in Stair region keep this

    % The crop length is determined by the largest gap length
    markerDict = markerStruct2dict(markerStruct);
    if ~skipLabelAdjust
     disp('%%%%%%%%%%% Adjusting Marker Labels %%%%%%%%%%%')   
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

                %% RUN SECTION HERE TO TEST combineTrialsSegments (debug purpose)
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

    %% Check preprocessed outcome
    markerDict = markerStruct2dict(markerStruct);
    labelingIssue = checkPreprocessed(clusters,markerDict,markerStructRef);
    end
    if labelingIssue
        if kinFillStart == 1
            kinFillStart = 0;
            skipLabelAdjust = 1;
            fprintf('\n\n')
            warning('Label Adjustments failed.. trying again without them')
            fprintf('\n\n')
            combinedProcessingPipeline = 'Reconstruct And Label';
        else
        combinedProcessingPipeline = handleFailedTrial(2,combinedProcessingPipeline);
        warning('Problem labeling trial... Starting over')
        if strcmpi(combinedProcessingPipeline,'Reconstruct and Label Least Filtered')
            kinFillStart = 1;
        end
        continue
        end
    end

    %Save data
%             markerStruct = markerdict2struct(markerDict);
    
    preppedC3D = ([c3dFile(1:end-4) '_preprocessed.c3d']);
    
    disp('    Writing preprocessed C3D file...')
    %% this seciton removes the unlabeled markers
    markerSet_names = fieldnames(markerStruct);
    markerSet_names = markerSet_names(contains(markerSet_names,'C_'));
    for zz = 1:length(markerSet_names)
        checkMarker = markerSet_names{zz};
        if ~any(~isnan(markerStruct.(checkMarker).x))
            markerStruct = rmfield(markerStruct,checkMarker);
        end
    end

    if multiSubs
        markerStruct = restoreOriginalMarkerNames(markerStruct,markerOriginalNames,'DefaultName',subjects{1});
    end
    markerDict = markerStruct2dict(markerStruct);
    markerDict = CombineUnlabeledMarkers(markerDict,verbose);
    markerStruct = markerdict2struct(markerDict);

    %try
    if multiSubs
        Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, preppedC3D);
    else
        Vicon.markerstoC3D(markerStruct, c3dFile, preppedC3D);
    end
    % catch
    %     markerSetStruct = rmfield(markerStruct,markerSet_names);
    %     warning(['File: ',c3dFile,' Removed all unlabeled Markers'])
    %     Vicon.markerstoC3D(markerSetStruct, c3dFile, filledC3D);
    % end


%%  ***GAP FILLING AND EXPORTING
% TODO: add cyclic fill to methods

exportStanding = 1; %change exportStanding to 1 to save the filled files


allFiles = dir([folderPath '\Working\' trialList{i} '_preprocessed.c3*']);
allFileNames = {allFiles(:).name};
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

for j = 1:length(allFileNames)
    fileName = allFileNames{j};
    c3dFile = [folderPath,'\Working\',fileName];
    
    fileName = split(fileName,'.');
    fileName = fileName{1};
    if contains(fileName,'filled')
        fileName2 = fileName(1:end-7);
    elseif contains(fileName,'preprocessed')
        fileName2 = fileName(1:end-13);
    else
        fileName2 = fileName;
    end

    if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0) 
        %disp('==============');
        %disp(fileName) % display file name in command window
        [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,multiSubs);
        

        [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters,verbose);
        if ~isempty(markerJumpSet)
            %warning('Marker Jump Need to Fix')
        end
%         markerStruct = fixJumpingMarkers(WBAM_Markerset,markerStruct,jumpThreshold,gap_th);

        %Fill missing first/last and final rigid body fill
%         [starting,ending] = Find_First_And_Last_Frames(WBAM_Markerset, markerStruct, markerStructRef, clusters);
        clusters = clustersOriginal;
        %try
         
        % if strcmpi(combinedProcessingPipeline,'Reconstruct and Label Least Filtered')
        % end
        disp('%%%%%%%%%%%%%%%%% Gap Filling %%%%%%%%%%%%%%%%%')
        try

        markerStruct = Rigid_Body_Fill_All_Gaps(markerSet, markerStruct, clusters,verbose);
        markerStruct = Rigid_Body_Fill_All_Gaps(markerSet, markerStruct, clusters,verbose);

        markerStruct = Gap_Fill(markerSet, markerStruct, markerStructRef, clusters);

        
        
%         missingFilled = Vicon.findGaps(markerStruct);
        %Check for jumping markers
        checkForJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters,verbose);

        %Check for missing markers (should all be filled)
        missing = checkForMissingMarkers(markerStruct, markerSet,verbose);

        

         catch
            
            if kinFillStart
                doneWithTrial = true;
                warning(['Failed to Gap fill Trial: ' trialList{i} '.  Check for issues with the jump thresholds, missing markers, or other major issues in mocap data.'])
                continue
            end
            warning(['Problem Gap Filing Trial: ' trialList{i} '... restarting process'])
            kinFillStart = 1;
            combinedProcessingPipeline = handleFailedTrial(2,combinedProcessingPipeline);
            continue
       end
        if missing
            heavyOps = true;checkProc
            
            markerStruct = kinFilling(markerStruct,markerStructRef,[folderPath '\Working\' trialList{i}],viconPath,folderPath);
            
        end
        
        
       missing = checkForMissingMarkers(markerStruct, markerSet, verbose);
       % catch
       %      missing = true;
       %  end
       
       if ~missing 
           disp('Filtering...')
            markerStruct = filterMarkerStruct(markerStruct,cf,lp);

            disp('% Validating that Trial Quality was Preserved %')
            markerDict = markerStruct2dict(markerStruct); 
            missing = checkProcessed(clusters,markerDict,markerStructRef,cf,lp,[folderPath '\Failed\Diagnostics\' trialList{i} '.txt']);
       end


       if multiSubs
            markerStruct = restoreOriginalMarkerNames(markerStruct,markerOriginalNames,'DefaultName',subjects{1});
       end


       if ~missing

        %Save data

            
            filledC3D = [folderPath '\Finished\' trialList{i} '.c3d'];
            fprintf('\n\n\nSuccess... Writing C3D File to Finished Folder\n\n\n\n')
            if multiSubs
                Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, filledC3D);
            else
                Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            end
            createEndnoteFilter(folderPath,[filledC3D(1:end-4)]);
            delete([folderPath '\Working\' trialList{i} '.c3d'])
            delete([folderPath '\Working\' trialList{i} '.trial.enf'])
            if exist([folderPath '\Failed\' trialList{i} '.c3d'],'file')
                delete([folderPath '\Failed\' trialList{i} '.c3d'])
            end
            if exist([folderPath '\Failed\' trialList{i} '.trial.enf'],'file')
                delete([folderPath '\Failed\' trialList{i} '.trial.enf'])
            end
            if exist([folderPath '\Failed\Diagnostics\' trialList{i} '.txt'],'file')
                delete([folderPath '\Failed\Diagnostics\' trialList{i} '.txt'])
            end
            if exist([folderPath '\Failed\Diagnostics\' trialList{i} '_MarkerErrors.mat'],'file')
                delete([folderPath '\Failed\Diagnostics\' trialList{i} '_MarkerErrors.mat'])
            end
            delete(preppedC3D)
            delete([preppedC3D(1:end-4) '.trial.enf'])
            doneWithTrial = true;
       else
           filledC3D = [folderPath '\Working\' trialList{i} '.c3d'];
           % disp('    Writing new C3D file...')
            if multiSubs
                Vicon.markerstoC3D_multiSubs(markerStruct, c3dFile, filledC3D);
            else
                Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            end
            delete(preppedC3D)
            delete([preppedC3D(1:end-4) '.trial.enf'])
            combinedProcessingPipeline = handleFailedTrial(2,combinedProcessingPipeline);
            if strcmpi(combinedProcessingPipeline,'Failed')
                copyfile([folderPath '\Working\' trialList{i} '.c3d'],[folderPath '\Failed\' trialList{i} '.c3d'])
                copyfile([folderPath '\Working\' trialList{i} '.trial.enf'],[folderPath '\Failed\' trialList{i} '.trial.enf'])
                delete([folderPath '\Working\' trialList{i} '.c3d'])
                delete([folderPath '\Working\' trialList{i} '.trial.enf'])
                doneWithTrial = true;
            end
       end
    end
end
% RunMeCropped;
    end
end
end