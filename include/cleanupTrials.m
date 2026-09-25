function cleanupTrials(clusters, markerStructRef, folderPath, trialList, viconPath,paramStruct)
markerDictRef = markerStruct2dict(markerStructRef);
debugFlag = 0; %debugFlag enables plotting


%%  PARAMETERS
verbose = paramStruct.verbose;
cf = paramStruct.cf;
lp = paramStruct.lp;
jumpThreshold = paramStruct.jumpThreshold;
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

%%  DEFINE RIGID BODY MARKER CLUSTERS

markerSet = unique([clusters{:}]);
clustersOriginal = clusters;


%% ***LOAD MARKER JUMP DETECT THRESHOLD LIST

for i = 1:length(trialList)
    fprintf(['\n\n\n\n\tCleaning up Trial ' trialList{i} '\n\n\n\n\n'])
   
        disp('%%%%%%%%%%%%%%%%% Gap Filling %%%%%%%%%%%%%%%%%')
        %try
        c3dFile = [folderPath '\Failed\' trialList{i} '.c3d'];
        markerStruct = Vicon.ExtractMarkers(c3dFile);
        %try
        markerStruct = Gap_Fill(markerSet, markerStruct, markerStructRef, clusters);
        markerStruct = Rigid_Body_Fill_All_Gaps(markerSet, markerStruct, clusters,verbose);
        markerStruct = Rigid_Body_Fill_All_Gaps(markerSet, markerStruct, clusters,verbose);

        missing = checkForMissingMarkers(markerStruct, markerSet,verbose);
        %catch
            %missing = true;
        %end
        if missing
            markerStruct = kinFilling(markerStruct,markerStructRef,[folderPath '\Failed\' trialList{i}],viconPath,folderPath);

        end
        missing = checkForMissingMarkers(markerStruct, markerSet,verbose);
        
       if ~missing            
            markerStruct = filterMarkerStruct(markerStruct,cf,lp);
       end
       if ~missing

        %Save data

            
            filledC3D = [folderPath '\Finished\' trialList{i} '.c3d'];
            fprintf('\n\n\nSuccess... Writing C3D File to Finished Folder\n\n\n\n')
            
            Vicon.markerstoC3D(markerStruct, c3dFile, filledC3D);
            
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

       else
           disp(['Could not fix trial: ' trialList{i}])
       end
        % catch
        %     disp(['Could not fix trial: ' trialList{i}])
        %     continue
        % end
end
end
