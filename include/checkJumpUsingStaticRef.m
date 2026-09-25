function [jumped,frameLoc] = checkJumpUsingStaticRef(markerStruct,markerStructRef,currentClusters,currentMarker,excludedMarker,drop_loc,markerJumpThresholdSet,jumpThresholdList)
jumpMarkerIdx = strcmp(markerJumpThresholdSet,currentMarker);
jumpThreshold = jumpThresholdList{jumpMarkerIdx};
jumpThreshold = jumpThreshold(3);

detectNum = 0;
nodetectNum = 0;
detectMarker = {};
nodetectMarker = {};

for ccs = 1:length(currentClusters)
    currentCluster = currentClusters{ccs};
    idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
    currentCluster(idx) = []; % delete current marker from cluster
    LengthList = [];
    for cc = 1:length(currentCluster)
        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
        if isfield(markerStruct,currentClusterMarker)
            if ~isnan(markerStruct.(currentClusterMarker).x(drop_loc)) && ~strcmp(currentClusterMarker,excludedMarker)
                currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                referenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(drop_loc); markerStruct.(currentClusterMarker).y(drop_loc); markerStruct.(currentClusterMarker).z(drop_loc)];
                currentMarkerCoordinate = [markerStruct.(currentMarker).x(drop_loc); markerStruct.(currentMarker).y(drop_loc); markerStruct.(currentMarker).z(drop_loc)];
                currentLength = (sum((currentMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                LengthList = [abs(referenceLength - currentLength),LengthList];
                if abs(referenceLength - currentLength) > jumpThreshold
                    detectNum = detectNum + 1;
                    detectMarker = [detectMarker{:},{currentClusterMarker}];
                else
                    nodetectNum = nodetectNum + 1;
                    nodetectMarker = [nodetectMarker{:},{currentClusterMarker}];
                end
            end
        else
            continue
        end
    end
    if nodetectNum < detectNum || any(LengthList > jumpThreshold + 15)
        jumped = 1;
        frameLoc = drop_loc;
        disp(['    MARKER JUMP USING STATIC TRIAL: ',currentMarker,' at frames: ', num2str(drop_loc+startFrameOffset-1)])
    elseif nodetectNum>= detectNum
        jumped = 0;
        frameLoc = [];
    end
end
end