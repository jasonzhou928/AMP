%%  GAP FILLING AND NEW C3D GENERATION
close all; clear; clc;
%%  FILE INFORMATION
filePath = 'C:\Users\jojob\Documents\EPIC LAB\Pipeline Improvements Case\02_08';
skiplist = {};
preprocessed_flag = 0;

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
% 
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
% {20}; % left thigh
% {20}; % left shank
% {15}; % left tibia1
% {15}; % left tibia2
% {30}; % left foot1
% {25}; % left foot2
% {20}; % right thigh
% {20}; % right shank
% {15}; % right tibia1
% {15}; % right tibia2
% {30}; % right foot1
% {25}; % right foot2
% {40}; % pelvis
% {20}; % head
% {70}; % header with C7
% {70};
% {70};
% {70};
% {70};
% {70};
% {70};
};
clusters = {
{'C7', 'SSTRN', 'RSCAP','ISTRN'}; % OSL torso
% {'RPSIS', 'LASIS', 'RASIS', 'LPSIS'};
% {'LPTHI', 'LSTHI','LATHI','LLKNEE', 'LMKNEE'};
% {'LLANK','LMANK','LLKNEE', 'LMKNEE', 'LSTIB','LPTIB','LATIB'};
% {'LHEEL', 'LLTOE','LMSTOE','LMTOE'};
% {'RPTHI', 'RSTHI','RATHI','RLKNEE', 'RMKNEE'};
% {'RPANK','RLPANK','RLSANK','RLKNEE', 'RMKNEE', 'RPSHANK','RASHANK'};
% {'RLTOE','RMSTOE','RMTOE','RHEEL'};
};
% clusters = {
% {'C7', 'SSTRN', 'RSCAP','ISTRN'}; % OSL torso
% {'RPSIS', 'LASIS', 'RASIS', 'LPSIS'};
% {'LPTHI', 'LSTHI','LATHI','LLKNEE', 'LMKNEE'};
% {'RLANK','RMANK','RLKNEE', 'RMKNEE', 'RSTIB','RPTIB','RATIB'};
% {'LHEEL', 'LLTOE','LMSTOE','LMTOE'};
% {'RPTHI', 'RSTHI','RATHI','RLKNEE', 'RMKNEE'};
% {'LPANK','LLPANK','LLSANK','LLKNEE', 'LMKNEE', 'LPSHANK','LASHANK'};
% {'RLTOE','RMSTOE','RMTOE','RHEEL'};
% };
% load(WBAM_Markerset)
WBAM_Markerset = unique([clusters{:}]);
clustersOriginal = clusters;
% Marker_ignore_list = {'T10'};
% WBAM_Markerset = 

%% ***Initial Setup to Generate C3D Files
% initialSetup(filePath);

%% ***GENERATE MARKER JUMP DETECTION THRESHOLD 
% markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
% fileName = 'ramp3_11.c3d';
% c3dFile = [filePath,'\',fileName];
% markerStruct = Vicon.ExtractMarkers(c3dFile);
% 
% [markerJumpThresholdSet,jumpThresholdList] = generateJumpThresholdList(WBAM_Markerset,markerStruct,markerStructRef,clusters);
% save("MarkerJumpThresholdListOSL.mat",'markerJumpThresholdSet','jumpThresholdList')

%% ***LOAD MARKER JUMP DETECT THRESHOLD LIST
load("MarkerJumpThresholdListOSL.mat")

%%  ***CHECK FOR MARKER JUMPS - SLOPES

% allFiles = dir([filePath,'/*.c3d']);
% allFileNames = {allFiles(:).name};
% allFileNames = setdiff(allFileNames,skiplist);
% markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
% jp_flag = 0;
% 
% preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
% preprocessedFileName = split(preprocessedFileName,'_');
% preprocessedFileName = reshape(preprocessedFileName,[],2);
% preprocessedFileName = preprocessedFileName(:,1);
% filledFileName = allFileNames(contains(allFileNames,'filled'));
% filledFileName = split(filledFileName,'_');
% filledFileName = reshape(filledFileName,[],2);
% filledFileName = filledFileName(:,1);
% 
% if isempty(preprocessedFileName)
%     preprocessedFileName = '';
% end
% if isempty(filledFileName)
%     filledFileName = '';
% end
% 
% for j = 1:length(allFileNames)
%     fileName = allFileNames{j};
%     c3dFile = [filePath,'\',fileName];
%     markerStruct = Vicon.ExtractMarkers(c3dFile);
% 
%     fileName = split(fileName,'.');
%     fileName = fileName{1};
%     fileName2 = split(fileName,'_');
%     fileName2 = fileName2(1);
% 
%     if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0)
%         disp('==============');
%         disp(fileName) % display file name in command window
% %         [markerGaplocs,markerGapSet] = checkForGapMarkers(WBAM_Markerset,markerStruct,markerJumpThresholdSet,jumpThresholdList);
% %         [markerSeglocs,markerSegSet] = segmentMarkers(WBAM_Markerset,markerStruct);
% %         markerStruct = markerJumpSegmentation(markerSegSet,markerSeglocs,markerStruct,markerJumpThresholdSet,jumpThresholdList);
% %         checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
% %         disp(' ')
%     end
% end
% 
% % if jp_flag
% %     warning('Marker Jump Detected')
% % else
% %     preprocessed_flag = 1;
% % end
% 
% %% ***Preprocessing -- Remove Jumping Markers + PickUp
% jp_flag = 1;
% if jp_flag
%     disp('%%%%%GETTING FILE NAMES FROM DIR%%%%%')
%     allFiles = dir([filePath,'/*.c3d']);
%     allFileNames = {allFiles(:).name};
%     allFileNames = setdiff(allFileNames,skiplist);
%     markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
%     markerDictRef = markerStruct2dict(markerStructRef);
%     preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
%     if ~isempty(preprocessedFileName)
%         preprocessedFileName = cellfun(@(x) x(1:end-17),preprocessedFileName,'UniformOutput',false);
%     end
%     filledFileName = allFileNames(contains(allFileNames,'filled'));
%     if ~isempty(filledFileName)
%         filledFileName = cellfun(@(x) x(1:end-11),filledFileName,'UniformOutput',false);
%     end
% 
%     if isempty(preprocessedFileName)
%         preprocessedFileName = '';
%     end
%     if isempty(filledFileName)
%         filledFileName = '';
%     end
%     %%
%     for j = 1:length(allFileNames)
%         fileName = allFileNames{j};
% %         fileName = 'nbwt05.c3d';
%         c3dFile = [filePath,'\',fileName];
% 
%         fileName = split(fileName,'.');
%         fileName = fileName{1};
%         if contains(fileName,'filled')
%             fileName2 = fileName(1:end-7);
%         elseif contains(fileName,'preprocessed')
%             fileName2 = fileName(1:end-13);
%         else
%             fileName2 = fileName;
%         end
% 
%         if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0) && ~any(contains(skiplist,fileName2)>0)
%             disp('==============');
%             disp(fileName) % display file name in command window
% 
%             markerStruct = Vicon.ExtractMarkers(c3dFile);
%             debugFlag = 1;
% 
%             jump_threshold = clusters_jump_threshold;
%             markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,840.7,279.4,nan,nan);
% %             [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
% 
%             markerDict = markerStruct2dict(markerStruct);
%             [GoodFrames,~] = FindAGoodFrame(markerDict,WBAM_Markerset,markerDictRef,clusters,jump_threshold);
%             [GoodFrames2,~,missingFlag] = FindAGoodFrameByCluster(markerDict,WBAM_Markerset,markerDictRef,clusters,jump_threshold,GoodFrames);
% 
%             if isempty(GoodFrames) && isempty(keys(GoodFrames2))
%                 warning('Could not find any good frame')
%                 continue
%             end
% 
% %             if any(structfun(@isempty,GoodFrames2))
% %                 GoodFrames2Markers = fieldnames(GoodFrames2);
% %                 markersMissing = GoodFrames2Markers(structfun(@isempty,GoodFrames2));
% %                 markersMissing = cellfun(@(x) cell2mat(strcat(x,{' '})),markersMissing,'UniformOutput',false);
% %                 disp(['Please Double Check These Markers: ',markersMissing{:}])
% %                 continue
% %             end
% 
%             %% Remove the marker from the cluster if the marker is missing all the time
%             if missingFlag
%                 GoodFrames2Markers = keys(GoodFrames2);
%                 GoodFrames2Locs = values(GoodFrames2);
%                 markersMissing = GoodFrames2Markers(cellfun(@isempty,GoodFrames2Locs));
%                 for m = 1:length(markersMissing)
%                     marker = markersMissing{m};
%                     for n = 1:length(clusters)
%                         cluster = clusters{n};
%                         cluster(strcmp(cluster,marker)==1)=[];
%                         clusters{n} = cluster;
%                     end
%                 end
%                 cellfun(@(x) disp(['Please Double Check These Markers: ',x]), markersMissing, 'UniformOutput',false);
% %                 continue
%             end
%         end
%     end
% 
%             markerDict = CmarkerJumpSegmentation(markerDict);
%             markerSegDict = segmentMarkers(markerDict);
%             [markerDict,~] = markerJumpSegmentation(WBAM_Markerset,markerSegDict,markerDict,markerJumpThresholdSet,jumpThresholdList,GoodFrames,GoodFrames2);
% 
%             %% Relink Normal Markers
%             relinkedFlag = 1;
%             markerSetToLink = WBAM_Markerset;
%             while relinkedFlag
%                 [markerDict,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerDict,markerDictRef,clusters,5,debugFlag);
%             end
% 
%             % Relink Cmarkers
%            relinkedFlag = 1;
%            markerSet = keys(markerDict);
%            temp_names=markerSet(contains(markerSet,'C_'));
%            markerSetToLink = temp_names;
%            while relinkedFlag
%                [markerDict,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerDict,markerDictRef,clusters,2.5,debugFlag);
%            end
% 
%             markerStructAfterNormalRelink = CombineUnlabeledMarkers(markerStruct);
%             Vicon.markerstoC3D(markerStructAfterNormalRelink, c3dFile, [filePath,'\',fileName,'_AfterNormalRelink.c3d']);       
% 
% 
%             % relinked markerStruct will be too much for Vicon.markertoC3D
%             % need to trim the data and only save the markers with long
%             % frames. Markers with short frames will be save to a different
%             % .mat file. Max size to save to C3D is 255.
% 
%             % MarkerStructRecycled are saved for later pattern fill
%             % matching
%         end
            %% Relabel
%             tic;
%             timelimit = 180; %Time limit to 180mins
%             fillFlag = 1;
%             markerDictTrimmed = markerDict;
% %             relinkedFlag3 = 0;
% %             markersetToFill3 = {};
% 
%             [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
%             [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
%             [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clusters,WBAM_Markerset,debugFlag);
%             t = toc;
%             while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit   
%                 t = toc;
%                 while (relinkedFlag1 || relinkedFlag2 || relinkedFlag3) && t < 60*timelimit  
%                     markersetToFill = unique([markersetToFill1(:)',markersetToFill2(:)',markersetToFill3(:)']);
%                     [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clusters,markersetToFill,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
%                     [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clusters,markersetToFill,jump_threshold,debugFlag);
%                     [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clusters,markersetToFill,debugFlag);
%                 end
%                 [markerDictTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerDictTrimmed,clusters,WBAM_Markerset,debugFlag);
%                 [markerDictTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerDictTrimmed,markerDictRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2,jump_threshold,debugFlag);
%                 [markerDictTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerDictTrimmed,markerDictRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
%                 t = toc;
%             end
%             markerDict = markerDictTrimmed;
            %%
            % Next GOAL: need to work on use pattern fill to find small segments
            %% save markerStruct for later debug
%             save(['debugMat\',fileName,'_preprocessed.mat'],"markerStruct")
            %%
            % markerDict = CombineUnlabeledMarkers(markerDict);
%             if length(fieldnames(markerDict)) > 255
%                 disp('Too Many Marker to save file -- Trimming Trials')
%                 TrimThreshold = 1; 
%                 markerDictTrimmed = markerDict;
%                 % Markers with least 100 frames, this can be changed as long as Trimmed version has less than 255 size
%                 while length(fieldnames(markerDictTrimmed)) > 255
%                     markerDictTrimmed = markerDict;
%                     markerDictRecycled = markerDict;
%                     for mi = 1:length(fieldnames(markerDict))
%                         names = fieldnames(markerDict);
%                         marker = names{mi};
%                         markerdata = markerDict.(marker).x;
%                         if sum(~isnan(markerdata)) < TrimThreshold && any(contains(marker,'C_'))
%                             markerDictTrimmed = rmfield(markerDictTrimmed,marker);
%                         else
%                             markerDictRecycled = rmfield(markerDictRecycled,marker);
%                         end
%                     end
%                     if length(fieldnames(markerDictTrimmed)) > 255
%                         TrimThreshold = TrimThreshold + 1;
%                     end
%                 end
%                 disp([' Trimmed Length to: ',num2str(TrimThreshold)])
%                 markerDict = markerDictTrimmed;
%             end

            %%
    %         Save data
    %         markerStruct = markerdict2struct(markerDict);
    %         if contains(fileName,'preprocessed')
    %             filledC3D = ([filePath,'\',fileName,'.c3d']);
    %         else
    %             filledC3D = ([filePath,'\',fileName,'_preprocessed.c3d']);
    %         end
    %         disp('    Writing new C3D file...')
    %         markerSet_names = fieldnames(markerStruct);
    %         markerSet_names = markerSet_names(contains(markerSet_names,'C_'));
    %         for zz = 1:length(markerSet_names)
    %             checkMarker = markerSet_names{zz};
    %             if ~any(~isnan(markerStruct.(checkMarker).x))
    %                 markerStruct = rmfield(markerStruct,checkMarker);
    %             end
    %         end
    %         try
    %             Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
    %         catch
    %             markerSetStruct = rmfield(markerStruct,markerSet_names);
    %             warning(['File: ',c3dFile,' Removed all unlabeled Markers'])
    %             Vicon.markerstoC3D(markerSetStruct, c3dFile, filledC3D);
    %         end
    %     end
    % end
% end

%%  ***GAP FILLING AND EXPORTING
% TODO: add cyclic fill to methods

% exportStanding = 1; %change exportStanding to 1 to save the filled files
% 
% allFiles = dir([filePath,'/*.c3d']);
% allFileNames = {allFiles(:).name};
% allFileNames = setdiff(allFileNames,skiplist);
% markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
% preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
% if ~isempty(preprocessedFileName)
%     preprocessedFileName = cellfun(@(x) x(1:end-17),preprocessedFileName,'UniformOutput',false);
% end
% filledFileName = allFileNames(contains(allFileNames,'filled'));
% if ~isempty(filledFileName)
%     filledFileName = cellfun(@(x) x(1:end-11),filledFileName,'UniformOutput',false);
% end
% 
% if isempty(preprocessedFileName)
%     preprocessedFileName = '';
% end
% if isempty(filledFileName)
%     filledFileName = '';
% end
% 
% for j = 1:length(allFileNames)
%     fileName = allFileNames{j};
%     c3dFile = [filePath,'\',fileName];
% 
%     fileName = split(fileName,'.');
%     fileName = fileName{1};
%     if contains(fileName,'filled')
%         fileName2 = fileName(1:end-7);
%     elseif contains(fileName,'preprocessed')
%         fileName2 = fileName(1:end-13);
%     else
%         fileName2 = fileName;
%     end
% 
%     if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0) && ~any(contains(skiplist,fileName2)>0)
%         disp('==============');
%         disp(fileName) % display file name in command window
%         markerStruct = Vicon.ExtractMarkers(c3dFile);
% 
%         [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
%         if ~isempty(markerJumpSet)
%             warning('Marker Jump Need to Fix')
%         end
%         markerStruct = fixJumpingMarkers(WBAM_Markerset,markerStruct,jumpThreshold,gap_th);
% 
%         %Fill missing first/last and final rigid body fill
% %         [starting,ending] = Find_First_And_Last_Frames(WBAM_Markerset, markerStruct, markerStructRef, clusters);
%         clusters = clustersOriginal;
%         markerStruct = Find_Missing_First_And_Last_FramesV2(WBAM_Markerset, markerStruct, markerStructRef, clusters);
%         markerStruct = Rigid_Body_Fill_All_Gaps(WBAM_Markerset, markerStruct, clusters);
%         markerStruct = Rigid_Body_Fill_All_Gaps(WBAM_Markerset, markerStruct, clusters);
% %         missingFilled = Vicon.findGaps(markerStruct);
%         %Check for jumping markers
%         checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
% 
%         %Check for missing markers (should all be filled)
%         checkForMissingMarkers(markerStruct, WBAM_Markerset)       
% 
%         %Save data
%         if contains(fileName,'preprocessed')
%             fileName = fileName(1:end-13);
%         end
%         if exportStanding==1
%             filledC3D = ([filePath,'\',fileName,'_filled.c3d']);
%             disp('    Writing new C3D file...')
%             Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
%         end
%     end
% end
% 
% %%  ***Double check marker jumps after fill
% 
% allFiles = dir([filePath,'/*.c3d']);
% allFileNames = {allFiles(:).name};
% allFileNames = setdiff(allFileNames,skiplist);
% 
% for j = 1:length(allFileNames)
%     fileName = allFileNames{j};
%     c3dFile = [filePath,'\',fileName];
%     markerStruct = Vicon.ExtractMarkers(c3dFile);
% 
%     fileName = split(fileName,'.');
%     fileName = fileName{1};
% 
%     if contains(fileName,'filled')
%         disp('==============');
%         disp(fileName) % display file name in command window
% 
%         %Check for jumping markers
%         checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
% 
%         %Check for missing markers (should all be filled)
%         checkForMissingMarkers(markerStruct, WBAM_Markerset)       
%     end
% end

%% ***Only Pickup Markers
allFiles = dir([filePath,'/*.c3d']);
allFileNames = {allFiles(:).name};
allFileNames = setdiff(allFileNames, skiplist);
markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
markerStructRef = markerStruct2dict(markerStructRef);
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

%%% Only Process this cluster %%%
% clusters = {
% {'RLTOE','RSTOE','RMTOE','RHEE','RLANK','RMANK'};
% {'RSTHI','RPTHI','RATHI','RMKNEE','RLKNEE'};
% {'LUTHI','LPTHI','LDTHI','LLKNE'};
% {'LASIS','LPSIS','RASIS','RPSIS'};
% {'SSTRN'};
% };

% clusters_jump_threshold = {
% {35};
% {25};
% {25};
% {35};
% };

% WBAM_Markerset = unique([clusters{:}]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for j = 1:length(allFileNames)
    fileName = allFileNames{j};
%         fileName = 'nbwt05.c3d';
    c3dFile = [filePath,'\',fileName];
    markerStruct = Vicon.ExtractMarkers(c3dFile);
    debugFlag = 1;

    fileName = split(fileName,'.');
    fileName = fileName{1};
    if contains(fileName,'filled')
        fileName2 = fileName(1:end-7);
    elseif contains(fileName,'preprocessed')
        fileName2 = fileName(1:end-13);
    else
        fileName2 = fileName;
    end

    if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0) && ~any(contains(fileName2,skiplist)>0)
        disp('==============');
        disp(fileName) % display file name in command window

        markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,-4900,-5550,nan,nan);

        GoodFrames = [];
        GoodFrames2 = [];
        jump_threshold = cell2mat([clusters_jump_threshold{:}]);

        GoodFrames2Markers = fieldnames(markerStruct);
        markersMissing = setdiff(WBAM_Markerset,GoodFrames2Markers);
        for m = 1:length(markersMissing)
            marker = markersMissing{m};
            for n = 1:length(clusters)
                cluster = clusters{n};
                cluster(strcmp(cluster,marker)==1)=[];
                clusters{n} = cluster;
            end
        end

        markerDict = markerStruct2dict(markerStruct);
        markerStruct = CmarkerJumpSegmentation(markerDict);

        relinkedFlag = 1;
        debugFlag = 1;
        markerSetToLink = WBAM_Markerset;
        while relinkedFlag
            [markerStruct,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSetToLink,markerStruct,markerStructRef,clusters,jump_threshold,debugFlag);
        end
%         markerStructname = fieldnames(markerStruct);
%         CMarkerSet=markerStructname(contains(markerStructname,'C_'));
%         [markerStruct,~,~] = relinkTrimmedMarkerSegmentationNeighbor(markerStruct,markerStructRef,clusters,CMarkerSet,jump_threshold,debugFlag);
%         relinkedFlag3 = 0;
        markerStructTrimmed = markerStruct;
        [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
        [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2, num2cell(jump_threshold),debugFlag);
        [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,WBAM_Markerset,debugFlag);

        while relinkedFlag1 || relinkedFlag2 || relinkedFlag3    
            while relinkedFlag1 || relinkedFlag2 || relinkedFlag3  
                markersetToFill = unique([markersetToFill1(:)',markersetToFill2(:)',markersetToFill3(:)']);
                [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,markersetToFill,GoodFrames,GoodFrames2,num2cell(jump_threshold),debugFlag);
                [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,markersetToFill,jump_threshold,debugFlag);
                [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,WBAM_Markerset,debugFlag);
            end
            [markerStructTrimmed,markersetToFill2,relinkedFlag2] = relinkTrimmedMarkerSegmentationNeighbor(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,jump_threshold,debugFlag);
            [markerStructTrimmed,markersetToFill1,relinkedFlag1] = relinkTrimmedMarkerSegmentationRigidBody(markerStructTrimmed,markerStructRef,clusters,WBAM_Markerset,GoodFrames,GoodFrames2,num2cell(jump_threshold),debugFlag);
            [markerStructTrimmed,markersetToFill3,relinkedFlag3] = relinkTrimmedMarkerSegmentationPattern2(markerStructTrimmed,clusters,WBAM_Markerset,debugFlag);
        end

        markerStruct = markerStructTrimmed;
%         TrimThreshold = 1; 
%         % Markers with least 100 frames, this can be changed as long as Trimmed version has less than 255 size
%         while length(fieldnames(markerStructTrimmed)) > 255
%             markerStructTrimmed = markerStruct;
%             markerStructRecycled = markerStruct;
%             for mi = 1:length(fieldnames(markerStruct))
%                 names = fieldnames(markerStruct);
%                 marker = names{mi};
%                 markerdata = markerStruct.(marker).x;
%                 if sum(~isnan(markerdata)) < TrimThreshold && any(contains(marker,'C_'))
%                     markerStructTrimmed = rmfield(markerStructTrimmed,marker);
%                 else
%                     markerStructRecycled = rmfield(markerStructRecycled,marker);
%                 end
%             end
%             if length(fieldnames(markerStructTrimmed)) > 255
%                 TrimThreshold = TrimThreshold + 1;
%             end
%         end
% 
%         markerStruct = markerStructTrimmed;

        markerStruct = CombineUnlabeledMarkers(markerStruct);
        markerStruct = markerdict2struct(markerStruct);

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

% %%  ***Check Marker Jumps Only
% 
% allFiles = dir([filePath,'/*.c3d']);
% allFileNames = {allFiles(:).name};
% allFileNames = setdiff(allFileNames,skiplist);
% markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
% jump_threshold = clusters_jump_threshold;
% 
% for j = 1:length(allFileNames)
%     fileName = allFileNames{j};
%     c3dFile = [filePath,'\',fileName];
%     markerStruct = Vicon.ExtractMarkers(c3dFile);
% 
%     fileName = split(fileName,'.');
%     fileName = fileName{1};
% 
%     if contains(fileName,'preprocessed')
%         disp('==============');
%         disp(fileName) % display file name in command window
% 
%         %Check for jumping markers
%         [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
% %         checkForJumpingMarkersAndUnlabelThem(markerStruct,WBAM_Markerset,markerStructRef,clusters,jump_threshold);
% 
% %         filledC3D = ([filePath,'\',fileName,'.c3d']);
% % 
% %         disp('    Writing new C3D file...')
% %         markerSet_names = fieldnames(markerStruct);
% %         markerSet_names = markerSet_names(contains(markerSet_names,'C_'));
% %         for zz = 1:length(markerSet_names)
% %             checkMarker = markerSet_names{zz};
% %             if ~any(~isnan(markerStruct.(checkMarker).x))
% %                 markerStruct = rmfield(markerStruct,checkMarker);
% %             end
% %         end
% %         try
% %             Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
% %         catch
% %             markerSetStruct = rmfield(markerStruct,markerSet_names);
% %             warning(['File: ',c3dFile,' Removed all unlabeled Markers'])
% %             Vicon.markerstoC3D(markerSetStruct, c3dFile, filledC3D);
% %         end
%     end
% end

% %%  ***Check Marker Jumps and Compare with GoodFrames for Pre-fix Marker Jumps
% 
% allFiles = dir([filePath,'/*.c3d']);
% allFileNames = {allFiles(:).name};
% allFileNames = setdiff(allFileNames,skiplist);
% markerStructRef = Vicon.ExtractMarkers([filePath,'\Static.c3d']);
% preprocessedFileName = allFileNames(contains(allFileNames,'preprocessed'));
% preprocessedFileName = split(preprocessedFileName,'_');
% preprocessedFileName = reshape(preprocessedFileName,[],2);
% preprocessedFileName = preprocessedFileName(:,1);
% filledFileName = allFileNames(contains(allFileNames,'filled'));
% filledFileName = split(filledFileName,'_');
% filledFileName = reshape(filledFileName,[],2);
% filledFileName = filledFileName(:,1);
% 
% if isempty(preprocessedFileName)
%     preprocessedFileName = '';
% end
% if isempty(filledFileName)
%     filledFileName = '';
% end
% 
% for j = 1:length(allFileNames)
%     fileName = allFileNames{j};
%     c3dFile = [filePath,'\',fileName];
%     markerStruct = Vicon.ExtractMarkers(c3dFile);
%     
%     fileName = split(fileName,'.');
%     fileName = fileName{1};
%     fileName2 = split(fileName,'_');
%     fileName2 = fileName2(1);
% 
%     if ~any(contains(lower(fileName2),'static')>0) && ~any(contains(filledFileName,fileName2)>0) && ~any(contains(preprocessedFileName,fileName)>0)
%         disp('==============');
%         disp(fileName) % display file name in command window
%         jump_threshold = clusters_jump_threshold;
%         [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(WBAM_Markerset,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters);
%         [GoodFrames,~] = FindAGoodFrame(markerStruct,WBAM_Markerset,markerStructRef,clusters,jump_threshold);
%         [GoodFrames2,~] = FindAGoodFrameByCluster(markerStruct,WBAM_Markerset,markerStructRef,clusters,jump_threshold,GoodFrames);
%         %Check for jumping markers
%         if ~isempty(markerJumpSet)
%             for jj = 1:length(markerJumpSet)
%                 checkMarker = markerJumpSet{jj};
%                 checkMarkerLoc = markerJumplocs{jj};
%                 checkGoodFrame = GoodFrames2.(checkMarker);
%                 [jumpedCheck,~] = intersect(checkMarkerLoc,checkGoodFrame);
%                 if ~isempty(jumpedCheck)
%                     disp(['    MARKER JUMP NEED MANUAL FIX: ',checkMarker,' at frame: ', num2str(unique(jumpedCheck))])
%                 end
%             end
%         end
%     end
% end
