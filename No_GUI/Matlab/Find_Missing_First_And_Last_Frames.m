function markerStruct = Find_Missing_First_And_Last_Frames(allMarkerNames, markerStruct, markerStructRef, clusters, varargin)
% FILL THE FIRST AND LAST FRAMES IN A C3D FILE
%   C3D files may contain marker trajectories that have the first and last
%   data points missing due to the inability of Vicon to deal with missing
%   edge trajectories.  This function uses absolute orientation (Horn's
%   method) to estimate the marker position in the first and last frames
%   based on donor data, consisting of marker data from markers on the same
%   rigid body.  This will only fill the first and last frames so that
%   other gap filling tools can be used.

% INPUTS:

% varargin: If you want to fill both starting and ending frames, do not
% enter anything.  To fill just the first frame, enter 'first'.  To fill
% just the last frame, enter 'last'.


numberVarargins = length(varargin);
if numberVarargins == 0
    fillBoth = 1;
else
    fillBoth = 0;
end

if numberVarargins == 1
    if contains(varargin{1},'first')
        fillFirst = 1;
        fillLast = 0;
    elseif contains(varargin{1},'last')
        fillFirst = 0;
        fillLast = 1;
    else
        error('Did not enter correct varargin')
    end
end

% FILL FIRST FRAME
if fillBoth == 1 || fillFirst == 1
    for mm = 1:length(allMarkerNames)
        currentMarker = allMarkerNames{mm}; % checking the frames for this marker
        
        firstFrame = 1; % resetting variable
        startLooking = 1; % start looking for first good frame at this point (!!!!!!!!!!)
        
        if isfield(markerStruct,currentMarker) && sum(~isnan(markerStruct.(currentMarker).x)) > 1 
            if isnan(markerStruct.(currentMarker).x(1)) % if first frame is missing (!!!!!!!!!)
                % Find first full frame of data
                while isnan(markerStruct.(currentMarker).x(startLooking)) % look until data is not NaN
                    startLooking = startLooking + 1;
                end
                firstFrame = startLooking; % this is the first frame where there is data
%                 firstFrame = 1;
                currentClusterMarkers = {};
                currentClusterMarkersAll = {};
                %Find other markers to drive the fix
                for ii = 1:length(clusters) % look at all of the defined clusters
                    if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                        currentCluster = clusters{ii}; % keep that cluster
                        idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                        currentCluster(idx) = []; % delete current marker from cluster

                        % Check that all markers in cluster also exist
                        currentClusters = currentCluster;
                        for cc = 1:length(currentCluster)
                            currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                            deleteThese = [];
                            if ~isfield(markerStruct,currentClusterMarker) || isnan(markerStruct.(currentClusterMarker).x(1)) % if the cluster marker is missing in the first frame (!!!!!!!!!!!!!!)
%                                 disp(['Current cluster: ', currentCluster])
                                %disp(['TARGET MARKER: ', currentMarker])
%                                 disp(['OTHER MISSING: ',currentClusterMarker])
                                idx = strcmp(currentClusters,currentClusterMarker); % find where current marker is in cluster
                                %deleteThese = [deleteThese, idx];
                                %disp(['IDX: ',idx])
                                currentClusters(idx) = []; % delete current marker from cluster
                            end
                            %disp(['Cluster before: ', currentCluster])
                            %currentCluster(deleteThese) = []; % delete current marker from cluster
                            %disp(['Delete these: ', deleteThese])
                            %disp(['Cluster after: ', currentCluster])
                        end
                        currentClusterMarkers = [currentClusterMarkers;{currentClusters}];
                        currentClusterMarkersAll = [currentClusterMarkersAll(:)',currentClusters];
                    end
                end
                currentClustersAll = unique(currentClusterMarkersAll);
                currentClusters = currentClusterMarkers;
                if sum(cell2mat(cellfun(@(x) length(x)<3, currentClusters, 'UniformOutput',false))) > 0
                    currentClusters = {currentClustersAll};
                end
                for ci = 1:length(currentClusters)
                    currentCluster = currentClusters{ci};
                    % Get donor coordinates
                    donorFull = []; % initiate
                    donorTarget = []; % initiate
                    donorFullStatic = []; % initiate

                    disp(['Filling First Frame: ', currentMarker])
                    pointFull = [markerStruct.(currentMarker).x(firstFrame); markerStruct.(currentMarker).y(firstFrame); markerStruct.(currentMarker).z(firstFrame)]; % gap marker coordinate in first full frame
                    for ii = 1:length(currentCluster) % loop through cluster markers
                        currentDonor = currentCluster{ii}; % look at specific donor marker
                        currentCoordinate = [markerStruct.(currentDonor).x(firstFrame); markerStruct.(currentDonor).y(firstFrame); markerStruct.(currentDonor).z(firstFrame)]; % find marker coordinates in first full frames of data
                        donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix

                        currentCoordinate = [markerStruct.(currentDonor).x(1); markerStruct.(currentDonor).y(1); markerStruct.(currentDonor).z(1)]; % find marker coordinates in first frame (missing) of data (!!!!!!!!!!!!!!!!!)
                        donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
                    end

                    if any(isnan(donorFull(:))) || size(donorFull,2) < 3
                        for ii = 1:length(currentCluster) % loop through cluster markers
                            currentDonor = currentCluster{ii}; % look at specific donor marker
                            currentCoordinate = [markerStructRef.(currentDonor).x(1); markerStructRef.(currentDonor).y(1); markerStructRef.(currentDonor).z(1)]; % find marker coordinates in first full frames of from Static Trial
                            donorFullStatic = [donorFullStatic, currentCoordinate]; % save coordinates in full data matrix
                        end
                        donorFull = donorFullStatic;
                        pointFull = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)]; % gap marker coordinate in first full frame
                    end
                    try
                        [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
                        transformationMatrix = regParams.M; % pull out transformation matrix
                        pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation

                        pointTarget = transformationMatrix*pointToTransform; % transform marker
                        markerStruct.(currentMarker).x(1) = pointTarget(1); % save x
                        markerStruct.(currentMarker).y(1) = pointTarget(2); % save y
                        markerStruct.(currentMarker).z(1) = pointTarget(3); % save z
                        break;
                    catch
                        warning('Could not fill first frame, skipped for now')
                    end
                end
            end
        else
            disp(['Marker Missing in the First Frame: ',currentMarker])

            %Find other markers to drive the fix
            for ii = 1:length(clusters) % look at all of the defined clusters
                if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                    currentCluster = clusters{ii}; % keep that cluster
                    idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                    currentCluster(idx) = []; % delete current marker from cluster

                    % Check that all markers in cluster also exist
                    currentClusters = currentCluster;
                    checkRigidBody = [];
                    for cc = 1:length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        idx = find(~isnan(markerStruct.(currentClusterMarker).x));
                        if isempty(checkRigidBody)
                            checkRigidBody = [idx,ones(length(idx),1)];
                        else
                            rowI = ismember(checkRigidBody(:,1),idx);
                            checkRigidBody(rowI,2) = checkRigidBody(rowI,2)+1;
                        end
                    end
                    goodRigidBody = checkRigidBody(checkRigidBody(:,2)>=3);
                    firstFrame = min(goodRigidBody);
                    for cc = 1:length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        deleteThese = [];
                        if ~isfield(markerStruct,currentClusterMarker) || isnan(markerStruct.(currentClusterMarker).x(firstFrame)) % if the cluster marker is missing in the first frame (!!!!!!!!!!!!!!)
                            disp(['Current cluster: ', currentCluster])
                            %disp(['TARGET MARKER: ', currentMarker])
                            disp(['OTHER MISSING: ',currentClusterMarker])
                            idx = strcmp(currentClusters,currentClusterMarker); % find where current marker is in cluster
                            %deleteThese = [deleteThese, idx];
                            %disp(['IDX: ',idx])
                            currentClusters(idx) = []; % delete current marker from cluster
                        end
                        %disp(['Cluster before: ', currentCluster])
                        %currentCluster(deleteThese) = []; % delete current marker from cluster
                        %disp(['Delete these: ', deleteThese])
                        %disp(['Cluster after: ', currentCluster])
                    end
                    currentCluster = currentClusters;
                end
            end

            % Get donor coordinates
            donorFull = []; % initiate
            donorTarget = []; % initiate
            
            disp(['Filling First Frame: ', currentMarker])
            pointFull = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)]; % gap marker coordinate in first full frame
            for ii = 1:length(currentCluster) % loop through cluster markers
                currentDonor = currentCluster{ii}; % look at specific donor marker
                currentCoordinate = [markerStructRef.(currentDonor).x(1); markerStructRef.(currentDonor).y(1); markerStructRef.(currentDonor).z(1)]; % find marker coordinates in first full frames of data
                donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix

                currentCoordinate = [markerStruct.(currentDonor).x(firstFrame); markerStruct.(currentDonor).y(firstFrame); markerStruct.(currentDonor).z(firstFrame)]; % find marker coordinates in first frame (missing) of data (!!!!!!!!!!!!!!!!!)
                donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
            end

            [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
            transformationMatrix = regParams.M; % pull out transformation matrix
            pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation

            pointTarget = transformationMatrix*pointToTransform; % transform marker
            markerStruct.(currentMarker) = markerStruct.(currentDonor);
            markerStruct.(currentMarker).x(1:end) = NaN;
            markerStruct.(currentMarker).y(1:end) = NaN;
            markerStruct.(currentMarker).z(1:end) = NaN;
            markerStruct.(currentMarker).x(firstFrame) = pointTarget(1); % save x
            markerStruct.(currentMarker).y(firstFrame) = pointTarget(2); % save y
            markerStruct.(currentMarker).z(firstFrame) = pointTarget(3); % save z
        end
    end
end

% FILL LAST FRAME

if fillBoth == 1 || fillLast == 1
    for mm = 1:length(allMarkerNames)
        currentMarker = allMarkerNames{mm}; % checking the frames for this marker
        if isfield(markerStruct,currentMarker) && sum(~isnan(markerStruct.(currentMarker).x)) > 1 
%             lastFrame = 0; % resetting variable
            lengthData = length(markerStruct.(currentMarker).x);
            startLooking = lengthData; % start looking for last good frame at this point (end of data vector)
            if isnan(markerStruct.(currentMarker).x(startLooking)) % if last frame is missing
%                 Find first full frame of data
                while isnan(markerStruct.(currentMarker).x(startLooking)) % look until data is not NaN
                    startLooking = startLooking - 1;
                end
                lastFrame = startLooking; % this is the last frame where there is data
%                 lastFrame = ending;

                %Find other markers to drive the fix
                for ii = 1:length(clusters) % look at all of the defined clusters
                    if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                        currentCluster = clusters{ii}; % keep that cluster
                        idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                        currentCluster(idx) = []; % delete current marker from cluster

                        % Check that all markers in cluster also exist with data
                        currentClusters = currentCluster;
                        for cc = 1:length(currentCluster)
                            currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                            if isnan(markerStruct.(currentClusterMarker).x(lastFrame)) % if the cluster marker is missing in the last frame
                                idx = strcmp(currentClusters,currentClusterMarker); % find where current marker is in cluster
                                currentClusters(idx) = []; % delete current marker from cluster
                            end
                        end
                        currentCluster = currentClusters;
                    end
                end

                % Get donor coordinates
                donorFull = []; % initiate
                donorTarget = []; % initiate
                donorFullStatic = []; % initiate
                
                disp(['Filling Last Frame: ', currentMarker])
                pointFull = [markerStruct.(currentMarker).x(lastFrame); markerStruct.(currentMarker).y(lastFrame); markerStruct.(currentMarker).z(lastFrame)]; % gap marker coordinate in last full frame
                for ii = 1:length(currentCluster) % loop through cluster markers
                    currentDonor = currentCluster{ii}; % look at specific donor marker
                    currentCoordinate = [markerStruct.(currentDonor).x(lastFrame); markerStruct.(currentDonor).y(lastFrame); markerStruct.(currentDonor).z(lastFrame)]; % find marker coordinates in last full frames of data
                    donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix

                    currentCoordinate = [markerStruct.(currentDonor).x(lengthData); markerStruct.(currentDonor).y(lengthData); markerStruct.(currentDonor).z(lengthData)]; % find marker coordinates in last frame (missing) of data
                    donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
                end
                
                if any(isnan(donorFull(:))) || size(donorFull,2) < 3
                    for ii = 1:length(currentCluster) % loop through cluster markers
                        currentDonor = currentCluster{ii}; % look at specific donor marker
                        currentCoordinate = [markerStructRef.(currentDonor).x(1); markerStructRef.(currentDonor).y(1); markerStructRef.(currentDonor).z(1)]; % find marker coordinates in first full frames of data
                        donorFullStatic = [donorFullStatic, currentCoordinate]; % save coordinates in full data matrix
                    end
                    donorFull = donorFullStatic;
                    pointFull = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)]; % gap marker coordinate in first full frame
                end
                
                try
                    [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
                    transformationMatrix = regParams.M; % pull out transformation matrix
                    pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation
    
                    pointTarget = transformationMatrix*pointToTransform; % transform marker
                    markerStruct.(currentMarker).x(end) = pointTarget(1); % save x
                    markerStruct.(currentMarker).y(end) = pointTarget(2); % save y
                    markerStruct.(currentMarker).z(end) = pointTarget(3); % save z
                catch
                    warning('Could not fill last frame, skipped for now')
                end
            end
        else
            disp(['Marker Missing in the Last Frame: ',currentMarker])
            
            %Find other markers to drive the fix
            for ii = 1:length(clusters) % look at all of the defined clusters
                if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                    currentCluster = clusters{ii}; % keep that cluster
                    idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                    currentCluster(idx) = []; % delete current marker from cluster

                    % Check that all markers in cluster also exist with data
                    currentClusters = currentCluster;
                    checkRigidBody = [];
                    for cc = 1:length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        idx = find(~isnan(markerStruct.(currentClusterMarker).x));
                        if isempty(checkRigidBody)
                            checkRigidBody = [idx,ones(length(idx),1)];
                        else
                            rowI = ismember(checkRigidBody(:,1),idx);
                            checkRigidBody(rowI,2) = checkRigidBody(rowI,2)+1;
                        end
                    end
                    goodRigidBody = checkRigidBody(checkRigidBody(:,2)>=3);
                    lastFrame = max(goodRigidBody);
                    for cc = 1:length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        if isnan(markerStruct.(currentClusterMarker).x(lastFrame)) % if the cluster marker is missing in the last frame
                            idx = strcmp(currentClusters,currentClusterMarker); % find where current marker is in cluster
                            currentClusters(idx) = []; % delete current marker from cluster
                        end
                    end
                    currentCluster = currentClusters;
                end
            end

            % Get donor coordinates
            donorFull = []; % initiate
            donorTarget = []; % initiate
            
            disp(['Filling Last Frame: ', currentMarker])
            pointFull = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)]; % gap marker coordinate in first full frame
            for ii = 1:length(currentCluster) % loop through cluster markers
                currentDonor = currentCluster{ii}; % look at specific donor marker
                currentCoordinate = [markerStructRef.(currentDonor).x(1); markerStructRef.(currentDonor).y(1); markerStructRef.(currentDonor).z(1)]; % find marker coordinates in first full frames of data
                donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix

                currentCoordinate = [markerStruct.(currentDonor).x(lastFrame); markerStruct.(currentDonor).y(lastFrame); markerStruct.(currentDonor).z(lastFrame)]; % find marker coordinates in first frame (missing) of data (!!!!!!!!!!!!!!!!!)
                donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
            end

            [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
            transformationMatrix = regParams.M; % pull out transformation matrix
            pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation

            pointTarget = transformationMatrix*pointToTransform; % transform marker
            markerStruct.(currentMarker).x(lastFrame) = pointTarget(1); % save x
            markerStruct.(currentMarker).y(lastFrame) = pointTarget(2); % save y
            markerStruct.(currentMarker).z(lastFrame) = pointTarget(3); % save z
        end
    end
end

end
