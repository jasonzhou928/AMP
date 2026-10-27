function [jumped,frameLoc] = checkJumpUsingRigidBodyClusters(markerStruct,markerStructRef,currentClusters,currentMarker,drop_loc,markerDrops,markerJumpThresholdSet,jumpThresholdList)            
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

detectNum = 0;
nodetectNum = 0;
detectMarker = {};
nodetectMarker = {};

jumpMarkerIdx = strcmp(markerJumpThresholdSet,currentMarker);
jumpThreshold = jumpThresholdList{jumpMarkerIdx};
jumpThreshold = jumpThreshold(3);

% if drop_loc == 457
%     disp('here')
% end
%             
for ccs = 1:length(currentClusters)
    currentCluster = currentClusters{ccs};
    LengthList = [];
    for cc = 1:length(currentCluster)
        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
        if isfield(markerStruct,currentClusterMarker)
            if ~isnan(markerStruct.(currentClusterMarker).x(drop_loc))
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
%                     [jumped,frameLoc] = checkJumpUsingStaticRef(markerStruct,markerStructRef,currentClusters,currentClusterMarker,currentMarker,drop_loc,markerJumpThresholdSet,jumpThresholdList);
                else
                    nodetectNum = nodetectNum + 1;
                    nodetectMarker = [nodetectMarker{:},{currentClusterMarker}];
                end
            end
        else
            continue
        end
    end
%     if nodetectNum + 1 >= detectNum && ~any(LengthList > jumpThreshold)
    if nodetectNum + detectNum < 3
        dropRange = markerDrops(markerDrops > drop_loc);
        if ~isempty(dropRange)
            dropRange = dropRange(1);
            Nextjumped = 2;
            for ii = drop_loc+1:dropRange
                dropNext = ii;
                donorNum = 0;
                for cc = 1:length(currentCluster)
                    currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                    if ~isnan(markerStruct.(currentClusterMarker).x(dropNext))
                        donorNum = donorNum + 1;
                    end
                end
                if donorNum < 3
                    continue
                else
                    [Nextjumped,~] = checkJumpUsingRigidBodyClusters(markerStruct,markerStructRef,currentClusters,currentMarker,dropNext,markerDrops,markerJumpThresholdSet,jumpThresholdList);
                    if Nextjumped
                        jumped = 1;
                        frameLoc = drop_loc;
                    else
                        jumped = 0;
                        frameLoc = [];
                    end
                    break;
                end
            end
            if Nextjumped == 2
                jumped = 0;
                frameLoc = [];
            end
        else
            jumped = 0;
            frameLoc = [];
        end
    elseif nodetectNum < detectNum || any(LengthList > jumpThreshold + 15)
        jumped = 1;
        frameLoc = drop_loc;
    elseif nodetectNum>= detectNum
        jumped = 0;
        frameLoc = [];
    end
end
end