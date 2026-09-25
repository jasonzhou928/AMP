function [markerJumplocs,markerJumpSet] = checkForJumpingMarkers(markerSet,markerStruct,markerStructRef,jumpThreshold,jumpSpeedThreshold,gap_len,clusters,verbose)
readable = struct();
markerJumplocs = {};
markerJumpSet = {};
for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
%     currentMarker = 'RSHO';
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
%         drop_loc = 630;
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
                        if abs(referenceLength - currentLength) > 11
        %                     disp('    Marker Jump Detected')
                            detectNum = detectNum + 1;
                        else
        %                     disp('    No Marker Jumps')
                            nodetectNum = nodetectNum + 1;
                        end
                    else
        %                 disp('    Marker NaN');
                    end
                else
                    continue
                end
            end
            if detectNum == 0 && nodetectNum == 0
    %             warning('   All Marker Missing')
            elseif detectNum + 1 >= nodetectNum && any(LengthList > 56)
    %             disp('  Marker Jump Detected by Voting!')
                drop_loc2 = drop_loc + startFrameOffset -1;
                droplist = [droplist;drop_loc2];
            else
    %             disp('  Marker Jump Not Detected by Voting!')
            end
        end
%         disp('-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=')
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
        markerSpeed = [markerIncrements;repmat(markerIncrements(end),gap,1)] - [repmat(markerIncrements(1),gap,1);markerIncrements]; % relative speed between marker frames
        markerSpeed = abs(markerSpeed(1:end-gap))./gap;
        
%         subplot(2,1,1)
%         sgtitle(currentMarker)
%         plot(markerIncrements)
%         subplot(2,1,2)
%         plot(markerSpeed)

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
        if verbose
        disp(['    MARKER JUMP: ',currentMarker,' starting at frame: ', num2str(unique(alllocs)')])
        end
        markerJumpSet = [markerJumpSet(:)',{currentMarker}];
        markerJumplocs = [markerJumplocs(:)',{alllocs'}];
        readable.(currentMarker) = unique(alllocs);
    end
end

end