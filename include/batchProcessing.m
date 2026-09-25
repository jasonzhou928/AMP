%%  GAP FILLING AND NEW C3D GENERATION
close all; clear; clc;
%%  FILE INFORMATION

filePath = 'E:\Dropbox (GaTech)\CDMRP Experiment Docs and Data\Vicon Data\CDMRP\OSL TODO';
skiplist = {};
preprocessed_flag = 0;
load('SubjectInfo.mat');

%%  PARAMETERS

cf = 200; % collection frequency = 200 Hz
jumpThreshold = 12; % How far does have to jump in a single frame to be flagged?
jumpSpeedThreshold = 7.5; % How fast does have to jump in a single frame to be flagged?
gap_th = 15; % gap detection threshold
check_th = 1;
patternCheckth = 5;
direction = {'fw','bw'}; % gap detection direction
gap_len = {1,2}; % gap detect frame lengths
gap_len_pickup = {3,2,1};
coordinates = {'x','y','z'};

%%  DEFINE RIGID BODY MARKER CLUSTERS
% WBAM_Markerset = 'WBAM_Passive_MarkerSet';

% clusters = {
% {'C7', 'STRN', 'RSCAP','CLAV','T10','LSHO','RSHO'}; % torso1
% {'C7', 'STRN', 'RSCAP','CLAV','T10'}; % torso2
% {'C7', 'SSTRN', 'RSCAP','ISTRN'}; % torso2
% {'LPTHI', 'LUTHI','LDTHI','LLKNE', 'LMKNE'}; % left thigh
% {'LLANK','LMANK','LLKNE', 'LMKNE', 'LUTIB','LPTIB','LDTIB'}; % left shank
% {'LLKNE','LMKNE','LUTIB','LPTIB','LDTIB'}; % left tibia1
% {'LLANK','LMANK','LUTIB','LPTIB','LDTIB'}; % left tibia2
% {'LHEE', 'LLTOE','LSTOE','LMTOE','LLANK','LMANK'}; % left foot1
% {'LHEE', 'LLTOE','LSTOE','LMTOE'}; % left foot2
% {'RPTHI', 'RUTHI','RDTHI','RLKNE', 'RMKNE'}; % right thigh
% {'RLANK','RMANK','RLKNE', 'RMKNE', 'RUTIB','RPTIB','RDTIB'}; % right shank
% % {'RLANK','RMANK','RLKNE', 'RMKNE'}; % right shank
% {'RLKNE','RMKNE','RUTIB','RPTIB','RDTIB'}; % right tibia1
% {'RLANK','RMANK', 'RUTIB','RPTIB','RDTIB'}; % right tibia2
% {'RLTOE','RSTOE','RMTOE','RHEE','RLANK','RMANK'}; % right foot1
% {'RLTOE','RSTOE','RMTOE','RHEE'}; % right foot2
% {'RPSIS', 'LASIS', 'RASIS', 'LPSIS'}; % pelvis
% {'RFHD','LFHD','RBHD','LBHD'}; % head
% {'RFHD','LFHD','RBHD','LBHD','C7'}; % head
% {'RELB','RWRB','RWRA'};
% {'LELB','LWRB','LWRA'};
% {'LUPA','LSHO','LELB'};
% {'RUPA','RSHO','RELB'};
% {'RELB','RWRB','RWRA','RUPA'};
% {'LELB','LWRB','LWRA','LUPA'};
% };

clusters_jump_threshold = {
{60}; % torso1
% {50}; % torso2
{20}; % left thigh
{20}; % left shank
{15}; % left tibia1
{15}; % left tibia2
{30}; % left foot1
{25}; % left foot2
{20}; % right thigh
{20}; % right shank
{15}; % right tibia1
{15}; % right tibia2
{30}; % right foot1
{25}; % right foot2
{40}; % pelvis
% {20}; % head
% {70}; % header with C7
% {70};
% {70};
% {70};
% {70};
% {70};
% {70};
};
clusters_r = {
{'C7', 'SSTRN', 'RSCAP','ISTRN'}; % OSL torso
{'RPSIS', 'LASIS', 'RASIS', 'LPSIS'};
{'LPTHI', 'LSTHI','LATHI','LLKNEE', 'LMKNEE'};
{'LLANK','LMANK','LLKNEE', 'LMKNEE', 'LSTIB','LPTIB','LATIB'};
{'LHEEL', 'LLTOE','LMSTOE','LMTOE'};
{'RPTHI', 'RSTHI','RATHI','RLKNEE', 'RMKNEE'};
{'RPANK','RLPANK','RLSANK','RLKNEE', 'RMKNEE', 'RPSHANK','RASHANK'};
{'RLTOE','RMSTOE','RMTOE','RHEEL'};
};
clusters_l = {
{'C7', 'SSTRN', 'RSCAP','ISTRN'}; % OSL torso
{'RPSIS', 'LASIS', 'RASIS', 'LPSIS'};
{'LPTHI', 'LSTHI','LATHI','LLKNEE', 'LMKNEE'};
{'RLANK','RMANK','RLKNEE', 'RMKNEE', 'RSTIB','RPTIB','RATIB'};
{'LHEEL', 'LLTOE','LMSTOE','LMTOE'};
{'RPTHI', 'RSTHI','RATHI','RLKNEE', 'RMKNEE'};
{'LPANK','LLPANK','LLSANK','LLKNEE', 'LMKNEE', 'LPSHANK','LASHANK'};
{'RLTOE','RMSTOE','RMTOE','RHEEL'};
};
% load(WBAM_Markerset)



%% ***LOAD MARKER JUMP DETECT THRESHOLD LIST
load("MarkerJumpThresholdListOSL.mat")

%% ***Preprocessing -- Remove Jumping Markers + PickUp
subjects = dir([filePath,'/MPK*']);
for s = 1:length(subjects)
    subject = subjects(s).name;
    filePath = subjects(s).folder;
    filePath = [filePath,'\',subject,'\'];
    
    side = SubjectInfo.(subject).side;
    
    if strcmp(side,'r')
        clusters = clusters_r;
    elseif strcmp(side,'l')
        clusters = clusters_l;
    end

    WBAM_Markerset = unique([clusters{:}]);
    clustersOriginal = clusters;
    
    jp_flag = 0;
    if jp_flag
        disp('%%%%%GETTING FILE NAMES FROM DIR%%%%%')
        allFiles = dir([filePath,'/*.c3d']);
        allFileNames = {allFiles(:).name};
        allFileNames = setdiff(allFileNames,skiplist);
        markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
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
        %%
        for j = 1:length(allFileNames)
            fileName = allFileNames{j};
    %         fileName = 'nbwt05.c3d';
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
                disp('==============');
                disp(fileName) % display file name in command window
                
                markerStruct = Vicon.ExtractMarkers(c3dFile);
                debugFlag = 1;
                
                jump_threshold = clusters_jump_threshold;
    %             markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4800,-5550,nan,nan);
                [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
                [GoodFrames,~] = FindAGoodFrame(markerStruct,WBAM_Markerset,markerStructRef,clusters,jump_threshold);
                [GoodFrames2,~] = FindAGoodFrameByCluster(markerStruct,WBAM_Markerset,markerStructRef,clusters,jump_threshold,GoodFrames);
                
                if isempty(GoodFrames) && isempty(fieldnames(GoodFrames2))
                    warning('Could not find any good frame')
                    continue
                end
    
    %             if any(structfun(@isempty,GoodFrames2))
    %                 GoodFrames2Markers = fieldnames(GoodFrames2);
    %                 markersMissing = GoodFrames2Markers(structfun(@isempty,GoodFrames2));
    %                 markersMissing = cellfun(@(x) cell2mat(strcat(x,{' '})),markersMissing,'UniformOutput',false);
    %                 disp(['Please Double Check These Markers: ',markersMissing{:}])
    %                 continue
    %             end
    
                %% Remove the marker from the cluster if the marker is missing all the time
                if any(structfun(@isempty,GoodFrames2))
                    GoodFrames2Markers = fieldnames(GoodFrames2);
                    markersMissing = GoodFrames2Markers(structfun(@isempty,GoodFrames2));
                    for m = 1:length(markersMissing)
                        marker = markersMissing{m};
                        for n = 1:length(clusters)
                            cluster = clusters{n};
                            cluster(strcmp(cluster,marker)==1)=[];
                            clusters{n} = cluster;
                        end
                    end
                    cellfun(@(x) disp(['Please Double Check These Markers: ',x]), markersMissing, 'UniformOutput',false);
    %                 continue
                end
    
                markerStruct = CmarkerJumpSegmentation(markerStruct);
                [markerSeglocs,markerSegSet] = segmentMarkers(markerStruct);
                [markerStruct,~] = markerJumpSegmentation(WBAM_Markerset,markerSegSet,markerSeglocs,markerStruct,markerJumpThresholdSet,jumpThresholdList,GoodFrames,GoodFrames2);
    
                %% Relink Normal Markers
                relinkedFlag = 1;
                markerSetToLink = WBAM_Markerset;
                while relinkedFlag
                    [markerStruct,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerStruct,markerStructRef,clusters,jump_threshold);
                end
    
                %% Relink Cmarkers
                relinkedFlag = 1;
                markerStructname = fieldnames(markerStruct);
                CMarkerSet=markerStructname(contains(markerStructname,'C_'));
                markerSetToLink = CMarkerSet;
                while relinkedFlag
                    [markerStruct,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerStruct,markerStructRef,clusters,jump_threshold);
                end
                
    %             markerStructAfterNormalRelink = CombineUnlabeledMarkers(markerStruct);
    %             Vicon.markerstoC3D(markerStructAfterNormalRelink, c3dFile, [filePath,'\',fileName,'_AfterNormalRelink.c3d']);       
    
    
                % relinked markerStruct will be too much for Vicon.markertoC3D
                % need to trim the data and only save the markers with long
                % frames. Markers with short frames will be save to a different
                % .mat file. Max size to save to C3D is 255.
                % 
                % MarkerStructRecycled are saved for later pattern fill
                % matching
                %% Relabel
                tic;
                timelimit = 180; %Time limit to 180mins
                fillFlag = 1;
                markerStructTrimmed = markerStruct;
    %             relinkedFlag3 = 0;
    %             markersetToFill3 = {};
    
                [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
                [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
                [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,WBAM_Markerset,debugFlag);
    
                while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && toc < 60*timelimit   
                    while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && toc < 60*timelimit  
                        markersetToFill = unique([markersetToFill1(:)',markersetToFill2(:)',markersetToFill3(:)']);
                        [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,markersetToFill,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
                        [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,markersetToFill,jump_threshold,debugFlag);
                        [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,markersetToFill,debugFlag);
                    end
                    [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,WBAM_Markerset,debugFlag);
                    [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
                    [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
                end
                markerStruct = markerStructTrimmed;
                %%
                % Next GOAL: need to work on use pattern fill to find small segments
                %% save markerStruct for later debug
    %             save(['debugMat\',fileName,'_preprocessed.mat'],"markerStruct")
                %%
                markerStruct = CombineUnlabeledMarkers(markerStruct);
                if length(fieldnames(markerStruct)) > 255
                    disp('Too Many Marker to save file -- Trimming Trials')
                    TrimThreshold = 1; 
                    markerStructTrimmed = markerStruct;
                    % Markers with least 100 frames, this can be changed as long as Trimmed version has less than 255 size
                    while length(fieldnames(markerStructTrimmed)) > 255
                        markerStructTrimmed = markerStruct;
                        markerStructRecycled = markerStruct;
                        for mi = 1:length(fieldnames(markerStruct))
                            names = fieldnames(markerStruct);
                            marker = names{mi};
                            markerdata = markerStruct.(marker).x;
                            if sum(~isnan(markerdata)) < TrimThreshold && any(contains(marker,'C_'))
                                markerStructTrimmed = rmfield(markerStructTrimmed,marker);
                            else
                                markerStructRecycled = rmfield(markerStructRecycled,marker);
                            end
                        end
                        if length(fieldnames(markerStructTrimmed)) > 255
                            TrimThreshold = TrimThreshold + 1;
                        end
                    end
                    disp([' Trimmed Length to: ',num2str(TrimThreshold)])
                    markerStruct = markerStructTrimmed;
                end
    
                %%
                %Save data
                if contains(fileName,'preprocessed')
                    filledC3D = ([filePath,'\',fileName,'.c3d']);
                else
                    filledC3D = ([filePath,'\',fileName,'_preprocessed.c3d']);
                end
                disp('    Writing new C3D file...')
                markerSet_names = fieldnames(markerStruct);
                markerSet_names = markerSet_names(contains(markerSet_names,'C_'));
                for zz = 1:length(markerSet_names)
                    checkMarker = markerSet_names{zz};
                    if ~any(~isnan(markerStruct.(checkMarker).x))
                        markerStruct = rmfield(markerStruct,checkMarker);
                    end
                end
                try
                    Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
                catch
                    markerSetStruct = rmfield(markerStruct,markerSet_names);
                    warning(['File: ',c3dFile,' Removed all unlabeled Markers'])
                    Vicon.markerstoC3D(markerSetStruct, c3dFile, filledC3D);
                end
            end
        end
    end
    
    %%  ***GAP FILLING AND EXPORTING
    % TODO: add cyclic fill to methods
    
    exportStanding = 1; %change exportStanding to 1 to save the filled files
    
    allFiles = dir([filePath,'/*.c3d']);
    allFileNames = {allFiles(:).name};
    allFileNames = setdiff(allFileNames,skiplist);
    markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
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
            disp('==============');
            disp(fileName) % display file name in command window
            markerStruct = Vicon.ExtractMarkers(c3dFile);
    
            [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
            if ~isempty(markerJumpSet)
                warning('Marker Jump Need to Fix')
            end
    %         markerStruct = fixJumpingMarkers(WBAM_Markerset,markerStruct,jumpThreshold,gap_th);
    
            %Fill missing first/last and final rigid body fill
    %         [starting,ending] = Find_First_And_Last_Frames(WBAM_Markerset, markerStruct, markerStructRef, clusters);
            clusters = clustersOriginal;
            markerStruct = Find_Missing_First_And_Last_FramesV2(WBAM_Markerset, markerStruct, markerStructRef, clusters);
            markerStruct = Rigid_Body_Fill_All_Gaps(WBAM_Markerset, markerStruct, clusters);
            markerStruct = Rigid_Body_Fill_All_Gaps(WBAM_Markerset, markerStruct, clusters);
    %         missingFilled = Vicon.findGaps(markerStruct);
            %Check for jumping markers
            checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
    
            %Check for missing markers (should all be filled)
            checkForMissingMarkers(markerStruct, WBAM_Markerset)       
    
            %Save data
            if contains(fileName,'preprocessed')
                fileName = fileName(1:end-13);
            end
            if exportStanding==1
                filledC3D = ([filePath,'\',fileName,'_filled.c3d']);
                disp('    Writing new C3D file...')
                Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            end
        end
    end
end