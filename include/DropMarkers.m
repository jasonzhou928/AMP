function markerStruct = DropMarkers(markerSet,markerStruct,markerStructRef,clusters, jumpThreshold, gap_th)

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    NaNidxs = isnan(markerStruct.(currentMarker).x);
    NaNidxs = find(NaNidxs == 1);
    markerDrops = NaNidxs(diff(NaNidxs) > 1)+1;

    markerStructname = fieldnames(markerStruct);
    markerStructname = markerStructname{1};
    startFrameOffset = markerStruct.(markerStructname).Header(1);
    currentClusters = {};
    droplist = [];

    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
            currentCluster = clusters{aa}; % keep that cluster
            idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
            currentCluster(idx) = []; % delete current marker from cluster
            currentClusters = [currentClusters,currentCluster];
        end
    end
    currentCluster = unique(currentClusters);

    for bb = 1:length(markerDrops)
        drop_loc = markerDrops(bb);
        disp('-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=')
        disp(['Marker Drop: ',currentMarker,' at frame: ', num2str(drop_loc+startFrameOffset-1)])
        detectNum = 0;
        nodetectNum = 0;
        for cc = 1:length(currentCluster)
            currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
            disp(['  Comparing with: ',currentClusterMarker]);
            if ~isnan(markerStruct.(currentClusterMarker).x(drop_loc))
                currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                referenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(drop_loc); markerStruct.(currentClusterMarker).y(drop_loc); markerStruct.(currentClusterMarker).z(drop_loc)];
                currentMarkerCoordinate = [markerStruct.(currentMarker).x(drop_loc); markerStruct.(currentMarker).y(drop_loc); markerStruct.(currentMarker).z(drop_loc)];
                currentLength = (sum((currentMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                if abs(referenceLength - currentLength) > gap_th
%                     disp('    Marker Jump Detected')
                    detectNum = detectNum + 1;
                else
%                     disp('    No Marker Jumps')
                    nodetectNum = nodetectNum + 1;
                end
            else
%                 disp('    Marker NaN');
            end
        end
        if detectNum == 0 && nodetectNum == 0
            warning('   All Marker Missing')
        elseif detectNum > nodetectNum
            disp('  Marker Jump Detected by Voting!')
            droplist = [droplist;drop_loc];
        else
            disp('  Marker Jump Not Detected by Voting!')
        end
        disp('-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=')
    end

    if isfield(markerStruct,currentMarker)
        data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    end
    dataNext = data(2:end,:);
    data = data(1:end-1,:);
    markerIncrements = (sum((dataNext-data).^2,2)).^0.5; % distance between marker frames
    if sum(markerIncrements>jumpThreshold)>0 % if there is a marker jump
        disp('------------------------------------')
        disp([' DROP MARKER JUMP: ',currentMarker])
        loc = find(markerIncrements>jumpThreshold);
        loc = sort([loc;droplist]);
        markerStructname = fieldnames(markerStruct);
        fakeName = length(markerStructname);
        markerStructname = markerStructname{1};
        startFrameOffset = markerStruct.(markerStructname).Header(1);
        for ii = 1:length(loc)
           jp_loc = loc(ii);
           loc_found = jp_loc + startFrameOffset;
           NaNidxs = isnan(markerStruct.(currentMarker).x);
           NaNidx = find(NaNidxs == 1);
           NaNframes = NaNidx(NaNidx > jp_loc);
           if isempty(NaNframes)
               nextframe = length(markerStruct.(currentMarker).x);
           else
               nextframe = NaNframes(1);
           end
           disp(['      Erasing frame: ',num2str(loc_found),' to ',num2str(nextframe+startFrameOffset-1)])
           markerStruct.(['C_' num2str(fakeName)]) = markerStruct.(currentMarker);
           markerStruct.(['C_' num2str(fakeName)]).x(1:end) = NaN;
           markerStruct.(['C_' num2str(fakeName)]).y(1:end) = NaN;
           markerStruct.(['C_' num2str(fakeName)]).z(1:end) = NaN;
           markerStruct.(['C_' num2str(fakeName)]).x(jp_loc:nextframe) = markerStruct.(currentMarker).x(jp_loc:nextframe);
           markerStruct.(['C_' num2str(fakeName)]).y(jp_loc:nextframe) = markerStruct.(currentMarker).y(jp_loc:nextframe);
           markerStruct.(['C_' num2str(fakeName)]).z(jp_loc:nextframe) = markerStruct.(currentMarker).z(jp_loc:nextframe);
           markerStruct.(currentMarker).x(jp_loc:nextframe) = NaN; % save all new x
           markerStruct.(currentMarker).y(jp_loc:nextframe) = NaN; % save all new y
           markerStruct.(currentMarker).z(jp_loc:nextframe) = NaN; % save all new z
           fakeName = fakeName + 1;
        end
    end
end
end