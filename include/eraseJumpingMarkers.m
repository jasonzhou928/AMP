function markerStruct = eraseJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters)

loc_check = [];
for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if ~isfield(markerStruct,currentMarker)
        continue
    end
    NaNidxs = find(isnan(markerStruct.(currentMarker).x));
    markerDrops = NaNidxs(diff(NaNidxs) > 1)+1;

    markerStructname = fieldnames(markerStruct);
    markerStructname = markerStructname{1};
    startFrameOffset = markerStruct.(markerStructname).Header(1);
    currentClusters = {};
    droplist = [];
    
    currentClusters = {};
    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
            currentCluster = clusters{aa}; % keep that cluster
            idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
            currentCluster(idx) = []; % delete current marker from cluster
            currentClusters(end+1) ={currentCluster};
        end
    end

    for bb = 1:length(markerDrops)
        drop_loc = markerDrops(bb);
        detectNum = 0;
        nodetectNum = 0;
        for ccs = 1:length(currentClusters)
            currentCluster = currentClusters{ccs};
            LengthList = [];
            for cc = 1:length(currentCluster)
                currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
    %             disp(['  Comparing with: ',currentClusterMarker]);
                if isfield(markerStruct,currentClusterMarker)
                    if ~isnan(markerStruct.(currentClusterMarker).x(drop_loc))
                        currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                        currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                        referenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                        currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(drop_loc); markerStruct.(currentClusterMarker).y(drop_loc); markerStruct.(currentClusterMarker).z(drop_loc)];
                        currentMarkerCoordinate = [markerStruct.(currentMarker).x(drop_loc); markerStruct.(currentMarker).y(drop_loc); markerStruct.(currentMarker).z(drop_loc)];
                        currentLength = (sum((currentMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                        LengthList = [abs(referenceLength - currentLength),LengthList];
                        if abs(referenceLength - currentLength) > 40
                            detectNum = detectNum + 1;
                        else
                            nodetectNum = nodetectNum + 1;
                        end
                    end
                else
                    continue
                end
            end
            if detectNum + 1 >= nodetectNum && any(LengthList > 56)
    %             disp('  Marker Jump Detected by Voting!')
                drop_loc = drop_loc + startFrameOffset -1;
                droplist = [droplist;drop_loc];
            end
        end
    end

    if isfield(markerStruct,currentMarker)
        data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    end
    locs = [];
    for hh = 1:length(gap_len)
        gap = gap_len{hh};
        dataNext = data(1+gap:end,:);
        data = data(1:end-gap,:);
        markerIncrements = ((sum((dataNext-data).^2,2)).^0.5)./gap; % distance between marker frames
        markerSpeed = [markerIncrements;zeros(gap,1)] - [zeros(gap,1);markerIncrements]; % relative speed between marker frames
        markerSpeed = abs(markerSpeed(gap+1:end))./gap;

        if sum(markerIncrements>jumpThreshold/gap)>0 && sum(markerSpeed>jumpSpeedThreshold/gap)>0 % if there is a marker jump
%             loc = find(markerIncrements>jumpThreshold);
            loc = find(markerIncrements>jumpThreshold/gap & markerSpeed>jumpSpeedThreshold/gap);
            markerStructname = fieldnames(markerStruct);
            markerStructname = markerStructname{1};
            startFrameOffset = markerStruct.(markerStructname).Header(1);
            loc = loc + startFrameOffset - 1 + gap;
            loc = loc(diff([0;loc])~=1);
            locs = [locs;loc];
        end
    end
    alllocs = sort([locs;droplist]);
    if ~isempty(alllocs)
        dropMarkerLocs = unique(alllocs);
        for dropi = 1:length(dropMarkerLocs)
            drop = dropMarkerLocs(dropi) - startFrameOffset + 1;
            
            noNans = find(~isnan(markerStruct.(currentMarker).x));
            dropNext = noNans(noNans > drop);
            if ~isempty(dropNext)
                dropNext = dropNext(1);
                dropNextjumped = checkJumpUsingRigidBodyClusters(markerStruct,markerStructRef,currentClusters,currentMarker,dropNext);
            else
                dropNextjumped = 1;
            end
            
            dropLast = noNans(noNans < drop);
            if ~isempty(dropLast)
                dropLast = dropLast(end);
                dropLastjumped = checkJumpUsingRigidBodyClusters(markerStruct,markerStructRef,currentClusters,currentMarker,dropLast);
            else
                dropLastjumped = 1;
            end

            if dropNextjumped == 0 && dropLastjumped == 0
                dropStart = dropLast + 1;
                dropEnd = dropNext - 1;
            elseif dropNextjumped == 1 && dropLastjumped == 0 && dropi ~= length(dropMarkerLocs)
                dropStart = drop;
                dropEnd =  dropMarkerLocs(dropi + 1);
            elseif dropNextjumped == 1 && dropLastjumped == 0 && dropi == length(dropMarkerLocs)
                dropStart = drop;
                dropEnd = length(markerStruct.(currentMarker).x);
            elseif dropNextjumped == 0 && dropLastjumped == 1 && dropi == 1
                dropStart = 1;
                if isempty(dropLast)
                    dropEnd = drop;
                else
                    dropEnd = dropLast;
                end
            elseif dropNextjumped == 0 && dropLastjumped == 1 && dropi ~= 1
                dropStart = drop;
                dropEnd = dropMarkerLocs(dropi - 1);
            elseif dropNextjumped == 1 && dropLastjumped == 1
                dropStart = 1;
                dropNext = noNans(noNans > drop);
                for dropNi = 1:length(dropNext)
                    dropNexti = dropNext(dropNi);
                    dropNextjumped = checkJumpUsingRigidBodyClusters(markerStruct,markerStructRef,currentClusters,currentMarker,dropNexti);
                    if ~dropNextjumped
                        break
                    end
                end
                if isempty(dropNext)
                    dropEnd = length(markerStruct.(currentMarker).x);
                else
                    dropEnd = dropNexti;
                end
            else
                disp('Unknown Case')
            end

            
            markerID = length(fieldnames(markerStruct));
            fakeID = ['C_' num2str(markerID)];
            while any(strcmp(fieldnames(markerStruct),fakeID))
                markerID = markerID + 1;
                fakeID = ['C_' num2str(markerID)];
            end

            disp(['         ERASE MARKER JUMP: ',currentMarker,' starting at frame: ', num2str(dropStart + startFrameOffset - 1) ' to ' num2str(dropEnd + startFrameOffset - 1)])

            markerStruct.(fakeID) = markerStruct.(currentMarker);

            markerStruct.(fakeID).x(1:end) = NaN;
            markerStruct.(fakeID).y(1:end) = NaN;
            markerStruct.(fakeID).z(1:end) = NaN;

            markerStruct.(fakeID).x(dropStart:dropEnd) = markerStruct.(currentMarker).x(dropStart:dropEnd);
            markerStruct.(fakeID).y(dropStart:dropEnd) = markerStruct.(currentMarker).y(dropStart:dropEnd);
            markerStruct.(fakeID).z(dropStart:dropEnd) = markerStruct.(currentMarker).z(dropStart:dropEnd);

            markerStruct.(currentMarker).x(dropStart:dropEnd) = NaN;
            markerStruct.(currentMarker).y(dropStart:dropEnd) = NaN;
            markerStruct.(currentMarker).z(dropStart:dropEnd) = NaN;
        end
    end
end

end