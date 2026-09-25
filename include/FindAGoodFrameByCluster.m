function [GoodFrames,diffLengths,missingFlag] = FindAGoodFrameByCluster(markerDict, markerSet, markerDictRef,clusters,cluster_jump_threshold,GoodFrameRef,verbose)
if verbose
disp('%%%%%Finding Good Segment Frame from Trial%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);
GoodFrames = [];
diffLengths = [];
diffMax = [0,0];
markerGoodlocs2 = dictionary();
reverseStr = '';
modifiedClusters = {};

missingFlag = 0;

for mi = 1:length(clusters)
    if length(clusters{mi}) >= 4
        modifiedClusters{end+1} = clusters{mi};
    end
end

for tt = 1:totalFrames
    markerGoodlocs = dictionary();
    loc = tt;
    % if loc == 30 %for debug
    %     disp(' ')
    % end
    if verbose
    msg = sprintf('Processed Frame %d/%d\n', loc, totalFrames);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    for ccs = 1:length(clusters)
        rigidDiffs = [];
        rigidDiffs2 = [];
        rigidDiffsName = {};
        currentCluster = clusters{ccs};
        jump_threshold = cell2mat(cluster_jump_threshold{ccs});
        if length(currentCluster) < 4 && isempty(GoodFrameRef)
            for mm = 1:length(currentCluster)
                currentMarker = currentCluster{mm};
                if ~isConfigured(markerGoodlocs2) || ~isKey(markerGoodlocs2,{currentMarker})
                    markerGoodlocs2({currentMarker}) = [];
                end
            end

            continue
        end
        currentClusters = currentCluster;
        for aa = 1:length(currentCluster) % look at all of the defined clusters
            currentClusterMarker = currentCluster{aa};
            % coord = getMarkerCoordinates(markerDict,currentClusterMarker,loc);
            try
                coord = getMarkerCoordinates(markerDict,currentClusterMarker,loc);
            catch
                currentClusters=setdiff(currentClusters,currentClusterMarker);
                continue;  
            end
            if ~isKey(markerDict,{currentClusterMarker}) || any(isnan(coord(1,:))) % if the cluster contains the marker that we're currently looking at
                currentClusters=setdiff(currentClusters,currentClusterMarker);
            end
        end
        currentCluster=currentClusters;
        if length(currentCluster) >= 4
            markerRemoveIdx = [];
            for cc = 1:length(currentCluster)
                currentClusterMarker = currentCluster{cc};
                % currentClusterMarkerCoordinate = getMarkerCoordinates(markerDict,currentClusterMarker,loc);
                try
                    currentClusterMarkerCoordinate = getMarkerCoordinates(markerDict,currentClusterMarker,loc);
                catch
                    markerRemoveIdx(end+1) = cc;
                    continue;
                end
                
                temp_cluster = currentCluster;
                idx = strcmp(temp_cluster, currentClusterMarker);
                temp_cluster(idx) = [];
                otherClusterMarkers = temp_cluster;
        
                donorTarget = [];
                donorFullStatic = [];
        
                for cci = 1:length(otherClusterMarkers)
                    currentDonor = otherClusterMarkers{cci};
                    % currentCoordinate = getMarkerCoordinates(markerDict,currentDonor,loc);

                    try
                        currentCoordinate = getMarkerCoordinates(markerDict,currentDonor,loc);
                    catch
                        continue;
                    end
                    donorTarget(:, end + 1) = currentCoordinate;
                    currentCoordinate = getMarkerCoordinates(markerDictRef,currentDonor,1);
                    donorFullStatic(:, end + 1) = currentCoordinate;
                end
        
        
                donorFull = donorFullStatic;
                pointFull = getMarkerCoordinates(markerDictRef,currentClusterMarker,1);

                try
                    [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
                catch
                    continue
                end
                transformationMatrix = regParams.M; % pull out transformation matrix
                pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation
    
                pointTarget = transformationMatrix*pointToTransform; % transform marker
                rigidbodyComputed = pointTarget(1:3);
                rigidDiff = (sum((rigidbodyComputed-currentClusterMarkerCoordinate).^2)).^0.5;
                if rigidDiff < jump_threshold
                    jumped = 0;
                else
                    jumped = 1;
                end
                rigidDiffs = vertcat(rigidDiffs,jumped);
                rigidDiffs2 = vertcat(rigidDiffs2,rigidDiff);
                rigidDiffsName{end+1} = currentClusterMarker;
            end

            if cc == length(currentCluster)
                % diffMax = vertcat(diffMax,[loc,max(rigidDiffs)]);
                if ~max(rigidDiffs) || sum(rigidDiffs == 0) >= 3
                    for mm = 1:length(currentCluster)
                        currentMarker = currentCluster{mm};
                        rigidIdx = strcmp(currentMarker,rigidDiffsName);
                        if rigidDiffs(rigidIdx)
                            continue
                        end
                        currentMarkerFreq = sum(cell2mat(cellfun(@(x) any(strcmp(x,currentMarker)), modifiedClusters, 'UniformOutput', false)));
                        if ~isConfigured(markerGoodlocs) || ~isKey(markerGoodlocs,{currentMarker})
                            markerGoodlocs({currentMarker}) = {[loc,1]};
                        else
                            CurrentMarkerGoodlocs = markerGoodlocs({currentMarker});
                            CurrentMarkerGoodlocs = CurrentMarkerGoodlocs{:};
                            rowI = CurrentMarkerGoodlocs(:,1) == loc;
                            CurrentMarkerGoodlocs(rowI,2) = CurrentMarkerGoodlocs(rowI,2) + 1;
                            markerGoodlocs({currentMarker}) = {CurrentMarkerGoodlocs};
                        end

                        CurrentMarkerGoodlocs = markerGoodlocs({currentMarker});
                        CurrentMarkerGoodlocs = CurrentMarkerGoodlocs{:};
                        rowI = CurrentMarkerGoodlocs(:,1) == loc;
                        % if CurrentMarkerGoodlocs(rowI,2) == currentMarkerFreq
                        if CurrentMarkerGoodlocs(rowI,2) == currentMarkerFreq || CurrentMarkerGoodlocs(rowI,2) >= 2 %% temp set to 2 instead of the occurence of marker existing in clusters
                            if ~isConfigured(markerGoodlocs2) || ~isKey(markerGoodlocs2,{currentMarker})
                                markerGoodlocs2({currentMarker}) = {loc};
                            else
                                locs = markerGoodlocs2({currentMarker});
                                locs = locs{:};
                                markerGoodlocs2({currentMarker}) = {unique([locs,loc])};
                            end
                        end
                    end
                end
            end
        end
    end
end

%% This section deals with markers that has no good frames
if ~isConfigured(markerGoodlocs2) || length(keys(markerGoodlocs2)) < length(markerSet)
    if ~isConfigured(markerGoodlocs2)
        diffNames = markerSet;
    else
        diffNames = setdiff(markerSet,keys(markerGoodlocs2));
    end
    for gg = 1:length(diffNames)
        currentMissingMarker = diffNames{gg};
        if ~isKey(markerDict,{currentMissingMarker})
            markerGoodlocs2({currentMissingMarker}) = [];
            missingFlag = 1;
%         else
%             %% here assume the first frame is correct, which is wrong in parfor now. Thus, this section is disabled
%             currentMissingMarkerCoordinate = getMarkerCoordinates(markerDict,currentMissingMarker,1:totalFrames);
%             noNanLoc = find(~isnan(currentMissingMarkerCoordinate(1,:)));
%             if isempty(noNanLoc)
% %                 markerGoodlocs2({currentMissingMarker}) = [];
%                 missingFlag = 1;
%             else
%                 noNanLoc = noNanLoc(1);
%                 markerGoodlocs2({currentMissingMarker}) = {noNanLoc};
%             end
        end
    end
end
GoodFrames = markerGoodlocs2;
if verbose
if isempty(GoodFrames)
    disp('No Frame Found with Segment Markers')
else
    disp('Found Frame with Segment Markers')
end
end
end
