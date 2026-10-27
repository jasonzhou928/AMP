function jumped = checkRigidBodyJump(markerStruct,currentMarker,markerStructRef,clusters,cluster_jump_threshold,starting,ending)

markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);
totalFrames = length(markerStruct.(markerStructname).Header);
GoodFrames = [];
diffLengths = [];
diffMax = [0,0];

jumped = 0;

markersetCluster = {};
markersetClusterIdx = [];

for aa = 1:length(clusters) % look at all of the defined clusters
    if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
        markersetCluster = [markersetCluster(:)',{clusters{aa}}];
        markersetClusterIdx = [markersetClusterIdx,aa];
    end
end


for tt = starting:ending
    loc = tt;
    
    for ccs = 1:length(markersetCluster)
        rigidDiffs = [];
        currentCluster = markersetCluster{ccs};
        currentClusterIdx = markersetClusterIdx(ccs);
        jump_threshold = cell2mat(cluster_jump_threshold{currentClusterIdx});
        
        currentClusters = currentCluster;
        for aa = 1:length(currentCluster) % look at all of the defined clusters
            currentClusterMarker = currentCluster{aa};
            if any(isnan(markerStruct.(currentClusterMarker).x(loc))) % if the cluster contains the marker that we're currently looking at
                currentClusters=setdiff(currentClusters,currentClusterMarker);
            end
        end
        currentCluster=currentClusters;
        
        if length(currentCluster) >= 4
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
                if rigidDiff > jump_threshold
                    jumped = 1;
                    break;
                end
            end
        end
        if jumped
            break;
        end
    end
    if jumped
        break;
    end
end
end