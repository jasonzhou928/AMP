function [jumped,frameLoc] = checkJumpUsingRigidBodyClusters2(markerStruct,markerStructRef,currentClusters,currentMarker,drop_loc,markerDrops,markerJumpThresholdSet,jumpThresholdList,previousJumped)            
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

detectNum = 0;
nodetectNum = 0;
detectMarker = {};
nodetectMarker = {};

% if drop_loc == 457
%     disp('here')
% end
%             
bw_gap = 3;
fw_gap = 3;
if drop_loc-bw_gap < 1
    bw_gap = drop_loc - 1;
elseif drop_loc+fw_gap > length(markerStruct.(markerStructname).Header)
    fw_gap = length(markerStruct.(markerStructname).Header) - drop_loc;
end

for ccs = 1:length(currentClusters)
    currentCluster = currentClusters{ccs};
    for cc = 1:length(currentCluster)
        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
        if isfield(markerStruct,currentClusterMarker)
            if sum(isnan(markerStruct.(currentClusterMarker).x(drop_loc-bw_gap:drop_loc+fw_gap))) < 2
                currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(drop_loc-bw_gap:drop_loc+fw_gap),markerStruct.(currentClusterMarker).y(drop_loc-bw_gap:drop_loc+fw_gap),markerStruct.(currentClusterMarker).z(drop_loc-bw_gap:drop_loc+fw_gap)];
                currentMarkerCoordinate = [markerStruct.(currentMarker).x(drop_loc-bw_gap:drop_loc+fw_gap),markerStruct.(currentMarker).y(drop_loc-bw_gap:drop_loc+fw_gap),markerStruct.(currentMarker).z(drop_loc-bw_gap:drop_loc+fw_gap)];
                LengthList = currentMarkerCoordinate-currentClusterMarkerCoordinate;
                LengthList = fillmissing(LengthList,'linear');
                [Idxs,~] = find(abs(diff(diff(LengthList))) > 11);
                [Idxs2,~] = find(abs(diff(LengthList)) > 11);
%                 if drop_loc == 1979
%                     disp('here')
%                 end
                if (~isempty(Idxs) && any(Idxs2 == bw_gap) && any(Idxs == bw_gap) && (isempty(previousJumped) || drop_loc-previousJumped > bw_gap)) || (~isempty(previousJumped) && ~isempty(Idxs) && ~any(Idxs2 == bw_gap) && drop_loc-previousJumped <= bw_gap)
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
    elseif nodetectNum < detectNum
        jumped = 1;
        frameLoc = drop_loc;
    elseif nodetectNum>= detectNum
        jumped = 0;
        frameLoc = [];
    end
end
end