function [markerJumpThresholdSet,jumpThresholdList] = generateJumpThresholdList(markerSet,markerStruct,markerStructRef,clusters)
disp('Generating Marker Jump Threshold List')
markerJumpThresholdSet = {};
jumpThresholdList = {};
for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    disp(['Jump Threshold List for: ',currentMarker])
    if ~isfield(markerStruct,currentMarker)
        continue
    end
    %% Threshold of Continuous Frames
    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    dataNext = data(2:end,:);
    data = data(1:end-1,:);
    markerIncrements = ((sum((dataNext-data).^2,2)).^0.5);
    [M,I] = max(markerIncrements);
    markerJumpThresholdSet = [markerJumpThresholdSet(:)',{currentMarker}];
%     jumpThresholdList = [jumpThresholdList(:)',{[M,I]}];

    %% Threshold of Marker Clusters
    currentClusters = {};
    droplist = [];
    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
            currentCluster = clusters{aa}; % keep that cluster
            idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
            currentCluster(idx) = []; % delete current marker from cluster
            currentClusters(end+1) ={currentCluster};
        end
    end

    for ccs = 1:length(currentClusters)
        currentCluster = currentClusters{ccs};
        LengthList = [];
        for cc = 1:length(currentCluster)
            currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
            if isfield(markerStruct,currentClusterMarker)
                for ii = 1:length(markerStruct.(currentMarker).x)
                    drop_loc = ii;
                    if ~isnan(markerStruct.(currentClusterMarker).x(drop_loc))
                        currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                        currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                        referenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                        currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(drop_loc); markerStruct.(currentClusterMarker).y(drop_loc); markerStruct.(currentClusterMarker).z(drop_loc)];
                        currentMarkerCoordinate = [markerStruct.(currentMarker).x(drop_loc); markerStruct.(currentMarker).y(drop_loc); markerStruct.(currentMarker).z(drop_loc)];
                        currentLength = (sum((currentMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                        LengthList = [abs(referenceLength - currentLength),LengthList];
                    end
                end
            end
        end
    end
    max2 = max(LengthList);

    jumpThresholdList = [jumpThresholdList(:)',{[M,I,max2]}];
end

end