function checkForJumpingMarkersAndUnlabelThem(markerStruct, markerSet, markerStructRef,clusters,cluster_jump_threshold)
disp('%%%%%Finding Good Segment Frame from Trial%%%%%')
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);
totalFrames = length(markerStruct.(markerStructname).Header);
GoodFrames = [];
diffLengths = [];
diffMax = [0,0];
% markerStructRef = markerStruct;
markerGoodlocs = struct();
reverseStr = '';

for tt = 1:totalFrames
    loc = tt;
    for ccs = 1:length(clusters)
        rigidDiffs = [];
        rigidDiffs2 = [];
        currentCluster = clusters{ccs};
        jump_threshold = cell2mat(cluster_jump_threshold{ccs});
        
        currentClusters = currentCluster;
        for aa = 1:length(currentCluster) % look at all of the defined clusters
            currentClusterMarker = currentCluster{aa};
            if any(isnan(markerStruct.(currentClusterMarker).x(loc))) % if the cluster contains the marker that we're currently looking at
                currentClusters=setdiff(currentClusters,currentClusterMarker);
            end
        end
        currentCluster=currentClusters;
        if length(currentCluster) >= 4
            jumpList = {};
            for cc = 1:length(currentCluster)
                currentClusterMarker = currentCluster{cc};
                currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(loc); markerStruct.(currentClusterMarker).y(loc); markerStruct.(currentClusterMarker).z(loc)];
                temp_cluster = currentCluster;
                idx = strcmp(temp_cluster,currentClusterMarker); % find where current marker is in cluster
                temp_cluster(idx) = [];
                otherClusterMarkers = temp_cluster;
    
                donorFull = []; % initiate
                donorTarget = []; % initiate
                donorFullStatic = []; % initiate
    
    
                for cci = 1:length(otherClusterMarkers) % loop through cluster markers
                    currentDonor = otherClusterMarkers{cci}; % look at specific donor marker
                    currentCoordinate = [markerStruct.(currentDonor).x(loc); markerStruct.(currentDonor).y(loc); markerStruct.(currentDonor).z(loc)]; % find marker coordinates in first frame (missing) of data (!!!!!!!!!!!!!!!!!)
                    donorTarget = [donorTarget, currentCoordinate]; 
                end
    
                for ccr = 1:length(otherClusterMarkers) % loop through cluster markers
                    currentDonor = otherClusterMarkers{ccr}; % look at specific donor marker
                    currentCoordinate = [markerStructRef.(currentDonor).x(1); markerStructRef.(currentDonor).y(1); markerStructRef.(currentDonor).z(1)]; % find marker coordinates in first full frames of from Static Trial
                    donorFullStatic = [donorFullStatic, currentCoordinate]; % save coordinates in full data matrix
                end
                donorFull = donorFullStatic;
                pointFull = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)]; % gap marker coordinate in first full frame
                
%                 if loc == 58 && strcmp(currentClusterMarker,'LUTIB')
%                     disp('here')
%                 end

%                 plane = donorTarget;
%                 point = currentClusterMarkerCoordinate;
%                 [A,B,C,D] = Plane_3Points(plane(:,1),plane(:,2),plane(:,3));
%                 distance = abs(A*point(1)+B*point(2)+C*point(3)+D)/sqrt(A^2+B^2+C^2);
%                 if distance < 15
%                     continue
%                 end
    
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
%                 if ccs == length(clusters) || ccs == 7 || ccs == 13
%                     figure(ccs)
%                     plot(tt,rigidDiff,'o')
%                     hold on
%                 end
                if rigidDiff < jump_threshold
                    jumped = 0;
                else
                    jumped = 1;
%                     jumpList = [jumpList;{currentClusterMarker,rigidDiff}];
                end
                rigidDiffs = vertcat(rigidDiffs,jumped);
                rigidDiffs2 = vertcat(rigidDiffs2,rigidDiff);
            end
            if cc == length(currentCluster)
                if ~isempty(jumpList)
                    [~,dropI] = max([jumpList{:,2}]);
                    dropName = jumpList{dropI,1};
                    data = [markerStruct.(dropName).x, markerStruct.(dropName).y, markerStruct.(dropName).z];
                    markerStruct = assignFakeID(dropName,markerStruct,markerSet,data,tt,tt);
                    disp(['Removing: ',dropName,' at frame: ',num2str(tt)])
                end
            end
        end
    end
%     msg = sprintf('Processed Frame %d/%d\n', loc, totalFrames);
%     fprintf([reverseStr, msg]);
%     reverseStr = repmat(sprintf('\b'), 1, length(msg));
end
% if length(fieldnames(markerGoodlocs)) < length(markerSet)
%     diffNames = setdiff(markerSet,fieldnames(markerGoodlocs));
%     for gg = 1:length(diffNames)
%         currentMissingMarker = diffNames{gg};
%         noNanLoc = find(~isnan(markerStruct.(currentMissingMarker).x));
%         noNanLoc = noNanLoc(1);
%         markerGoodlocs.(currentMissingMarker) = noNanLoc;
%     end
% end

% markerStruct = CombineUnlabeledMarkers(markerStruct);

end

function markerStruct = assignFakeID(currentMarker,markerStruct,markerSet,data,segStart,segEnd)
    dataRange = data(segStart:segEnd,:);
    markerID = length(fieldnames(markerStruct));
    fakeID = ['C_' num2str(markerID)];
    while any(strcmp(fieldnames(markerStruct),fakeID)) || any(strcmp(markerSet,fakeID))
        markerID = markerID + 1;
        fakeID = ['C_' num2str(markerID)];
    end
%     if markerID == 1234
%         disp('here')
%     end
    markerStruct.(fakeID) = markerStruct.(currentMarker);
    markerStruct.(fakeID).x(1:end) = NaN;
    markerStruct.(fakeID).y(1:end) = NaN;
    markerStruct.(fakeID).z(1:end) = NaN;
    markerStruct.(fakeID).x(segStart:segEnd) = dataRange(:,1);
    markerStruct.(fakeID).y(segStart:segEnd) = dataRange(:,2);
    markerStruct.(fakeID).z(segStart:segEnd) = dataRange(:,3);
    markerStruct.(currentMarker).x(segStart:segEnd) = NaN;
    markerStruct.(currentMarker).y(segStart:segEnd) = NaN;
    markerStruct.(currentMarker).z(segStart:segEnd) = NaN;
end