function [GoodFrames,diffLengths] = FindAGoodFrame(markerDict, markerSet, markerDictRef,clusters,cluster_jump_threshold,verbose)
if verbose
disp('%%%%%Finding Good Frame from Trial%%%%%')
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
reverseStr = '';
for tt = 1:totalFrames
    loc = tt;
    if verbose
    msg = sprintf('Processed Frame %d/%d\n', loc, totalFrames);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    rigidDiffs = [];
    for mm = 1:length(markerSet) % loop through marker set
        currentMarker = markerSet{mm};
        if ~any(contains(markerStructnames,currentMarker))
            break;
        end
        data = getMarkerCoordinates(markerDict,currentMarker,loc);
        if any(isnan(data))
            break;
        end
        if mm == length(markerSet)
            for ccs = 1:length(clusters)
                rigidDiffList = [];
                currentCluster = clusters{ccs};
                jump_threshold = cell2mat(cluster_jump_threshold{ccs});
                if length(currentCluster) < 4
                    continue
                end
                for cc = 1:length(currentCluster)
                    currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                    temp_cluster = currentCluster;
                    idx = strcmp(temp_cluster,currentClusterMarker); % find where current marker is in cluster
                    temp_cluster(idx) = [];
                    otherClusterMarkers = temp_cluster;
% 
%                     if loc > 4440 && strcmp(currentClusterMarker,'LPTHI')
%                         disp('here')
%                     end
%                     for cmi = 1:length(otherClusterMarkers)
%                         cmpMarker = otherClusterMarkers{cmi};
% 
%                         otherClusterMarkerReference = [markerStructRef.(cmpMarker).x(1); markerStructRef.(cmpMarker).y(1); markerStructRef.(cmpMarker).z(1)];
%                         currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
%                         
%                         otherClusterMarkerCoordinate = [markerStruct.(cmpMarker).x(loc); markerStruct.(cmpMarker).y(loc); markerStruct.(cmpMarker).z(loc)];
%                         currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(loc); markerStruct.(currentClusterMarker).y(loc); markerStruct.(currentClusterMarker).z(loc)];
%                         
%                         referenceLength = (sum((otherClusterMarkerReference-currentClusterMarkerReference).^2)).^0.5;
%                         currentLength = (sum((otherClusterMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
%                         diffLength = abs(referenceLength - currentLength);
%                         diffLengths = vertcat(diffLengths,diffLength);
%                         if diffLength > 50
%                             break;
%                         end
%                     end
                    % Preallocate memory for x, y, and z arrays
                    x = zeros(1, length(otherClusterMarkers));
                    y = zeros(1, length(otherClusterMarkers));
                    z = zeros(1, length(otherClusterMarkers));
                    
                    for cci = 1:length(otherClusterMarkers)
                        currentDonor = otherClusterMarkers{cci};
                        currentMarkerStruct = getMarkerCoordinates(markerDict,currentDonor,loc);
                        x(cci) = currentMarkerStruct(1,:);
                        y(cci) = currentMarkerStruct(2,:);
                        z(cci) = currentMarkerStruct(3,:);
                    end
                    
                    % Combine x, y, and z into donorTarget
                    donorTarget = [x; y; z];
        
                    % Preallocate memory for donorFullStatic
                    donorFullStatic = zeros(3, length(otherClusterMarkers)); % Assuming 3D coordinates
                    
                    for ccr = 1:length(otherClusterMarkers)
                        currentDonor = otherClusterMarkers{ccr};
                        donorFullStatic(:, ccr) = getMarkerCoordinates(markerDictRef,currentDonor,1);
                    end
                    
                    % Assign donorFullStatic to donorFull
                    donorFull = donorFullStatic;
                    
                    % Extract pointFull outside the loop
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
                    currentClusterMarkerCoordinate = getMarkerCoordinates(markerDict,currentClusterMarker,loc);
                    rigidDiff = (sum((rigidbodyComputed-currentClusterMarkerCoordinate).^2)).^0.5;
                    if rigidDiff < jump_threshold
                        jumped = 0;
                    else
                        jumped = 1;
                    end
                    rigidDiffs = vertcat(rigidDiffs,jumped);
                    rigidDiffList = vertcat(rigidDiffList,rigidDiff);
                end
            end
            diffMax = vertcat(diffMax,[loc,max(rigidDiffs)]);
            if ~max(rigidDiffs)
                GoodFrames = vertcat(GoodFrames,loc);
            end
        end
    end
end
if verbose
if isempty(GoodFrames)
    disp('No Frame Found with Full Markers')
else
    disp('Found Frame with Full Markers')
end
end
end