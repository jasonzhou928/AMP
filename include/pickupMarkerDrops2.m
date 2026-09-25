function markerStruct = pickupMarkerDrops2(markerSet,markerStruct,markerStructRef,clusters,gap_th,check_th,patternCheckth,direction,gap_len,iter,markerJumpThresholdSet,jumpThresholdList)
%% Re-organize the order by the number of the NaNs
nanMarkerNumbers = [];
localIter = 0;
foundFlag = 1;
for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    nanMarkerNumbers(mm) = sum(isnan(markerStruct.(currentMarker).x));
end
[~,I] = sort(nanMarkerNumbers);
markerSet = markerSet(I);
%% Start loop
while foundFlag
    foundFlag = 0;
    foundMarkerSet = {};
    for mm = 1:length(markerSet) % loop through marker set
        currentMarker = markerSet{mm};
%         currentMarker = 'RSHO';
        jumpMarkerIdx = strcmp(markerJumpThresholdSet,currentMarker);
        jumpThreshold = jumpThresholdList{jumpMarkerIdx};
        jumpThreshold = jumpThreshold(3);
        gap_th = jumpThreshold(1);

        disp('=========================================')
        disp(['Iteration: ', num2str(iter), '.', num2str(localIter),' Searching Markers for: ', currentMarker])
    
        currentClusters = {};
        for aa = 1:length(clusters) % look at all of the defined clusters
            if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
                currentCluster = clusters{aa}; % keep that cluster
                idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                currentCluster(idx) = []; % delete current marker from cluster
                currentClusters(end+1) ={currentCluster};
            end
        end
        found_fw_a = [];
        found_bw_a = [];
        for kk = 1:length(direction)
            for hh = 1:length(gap_len)
                gap = gap_len{hh};
                if isfield(markerStruct,currentMarker)
                    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
                end
                markerDrops = find(isnan(data(1+gap:end-gap,1)))+gap;
                dir = direction{kk};
                if strcmp(dir,'fw')
                    itr_dir = 1:length(markerDrops);
                else
                    itr_dir = length(markerDrops):-1:1;
                end
                for ii = itr_dir
                    loc = markerDrops(ii);
                    temp_markerSet = rmfield(markerStruct,currentMarker);
                    temp_markerSet_names = fieldnames(temp_markerSet);
                    temp_markerSet_names = temp_markerSet_names(contains(temp_markerSet_names,'C_'));
    
                    markerStructname = fieldnames(markerStruct);
                    markerStructname = markerStructname{1};
                    startFrameOffset = markerStruct.(markerStructname).Header(1);
                    
                    disp(['Iteration: ', num2str(iter), '.', num2str(localIter), ' ' ,currentMarker ' at frame: ',num2str(loc+startFrameOffset-1),' with gap length: ',num2str(gap)]);
    
                    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
                    notnanidx = find(~isnan(markerStruct.(currentMarker).x));
                    jp_marker_range = data(loc-gap:loc+gap,:);
                    if sum(isnan(jp_marker_range(:,1))) <=1 && gap ~= 1
                        continue
                    end
                    jp_marker_fw = data(loc+gap,:);
                    jp_marker_bw = data(loc-gap,:);
    
                    if isnan(jp_marker_fw) & isnan(jp_marker_bw)
    %                     currentCluster = unique(currentClusters);
                        found = 0;
                        nofound = 0;
                        found_marker = {};
                        found_data = {};
                        found_dist = {};
    %                     disp(['  Searching: ',currentMarker,' at frame: ',num2str(loc+startFrameOffset-gap)]);
                        for ccs = 1:length(currentClusters)
                            currentCluster = currentClusters{ccs};
                            LengthList = [];
                            for cc = 1:length(currentCluster)
                                currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
        %                         disp(['     Comparing with: ',currentClusterMarker,' at frame: ',num2str(loc+startFrameOffset-gap)]);
                                if ~isnan(markerStruct.(currentClusterMarker).x(loc))
                                    currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                                    currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                                    referenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                                    currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(loc); markerStruct.(currentClusterMarker).y(loc); markerStruct.(currentClusterMarker).z(loc)];
                                    for dd = 1:length(temp_markerSet_names)
                                        cmp_marker = temp_markerSet_names{dd};
                                        cmp_data = [markerStruct.(cmp_marker).x(loc);markerStruct.(cmp_marker).y(loc);markerStruct.(cmp_marker).z(loc)];
                                        if isnan(cmp_data)
                                            continue;
                                        end
                                        currentLength = (sum((cmp_data-currentClusterMarkerCoordinate).^2)).^0.5;
                                        LengthList = [abs(referenceLength - currentLength),LengthList];
                                        if abs(referenceLength - currentLength) > jumpThreshold
        %                                     disp(['          Not Found at:',cmp_marker])
                                        else
        %                                     disp(['          Found at: ',cmp_marker])
                                            false_flag = 2;
                                            doubleCheckedNum = 0;
                                            for ee = 1:length(currentCluster)
                                                currentClusterMarker = currentCluster{ee}; % cluster marker that we're looking at
                                                if ~isnan(markerStruct.(currentClusterMarker).x(loc))
                                                    currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                                                    currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                                                    cmpReferenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                                                    currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(loc); markerStruct.(currentClusterMarker).y(loc); markerStruct.(currentClusterMarker).z(loc)];
                                                    currentcmpMarkerCoordinate = [markerStruct.(cmp_marker).x(loc); markerStruct.(cmp_marker).y(loc); markerStruct.(cmp_marker).z(loc)];
                                                    cmpCurrentLength = (sum((currentcmpMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                                                    if abs(cmpReferenceLength - cmpCurrentLength) > jumpThreshold
    %                                                     disp('False Alarm')
                                                        false_flag = 1;
                                                        break;
                                                    else
    %                                                     disp('Double Checked!')
                                                        doubleCheckedNum = doubleCheckedNum + 1;
                                                        false_flag = 0;
                                                    end
                                                end
                                            end
                                            if false_flag == 0 && doubleCheckedNum >= 3
                                                found = found + 1;
                                                found_marker{end+1} = cmp_marker;
                                                found_data{end+1} = cmp_data;
                                                found_dist{end+1} = abs(referenceLength - currentLength);
                                            end                                    
                                        end
                                        if dd == length(temp_markerSet_names)
        %                                     disp('Not Found from any Markers')
                                            nofound = nofound + 1;
                                        end
                                    end
                                end
                            end
                        end
    
                        if found == 0
                            findStart = find(notnanidx < loc);
                            findEnd = find(notnanidx > loc);
                            if ~isempty(findStart) && ~isempty(findEnd)
                                startFrame = notnanidx(findStart(end)) + startFrameOffset - 1;
                                endFrame = notnanidx(findEnd(1))+ startFrameOffset - 1;
                                try
                                    PatternMarkerStruct = Vicon.PatternFill(markerStruct,currentMarker,currentCluster, startFrame, endFrame);
                                catch
                                    PatternMarkerStruct = Vicon.SplineFill(markerStruct,currentMarker,startFrame,endFrame,'MaxError',30);
                                end
                                PatternCurrentMarkerCoordinate = [PatternMarkerStruct.(currentMarker).x(loc);PatternMarkerStruct.(currentMarker).y(loc);PatternMarkerStruct.(currentMarker).z(loc)];
                                if ~isnan(PatternCurrentMarkerCoordinate)
                                    for dd = 1:length(temp_markerSet_names)
                                        cmp_marker = temp_markerSet_names{dd};
                                        cmp_data = [markerStruct.(cmp_marker).x(loc);markerStruct.(cmp_marker).y(loc);markerStruct.(cmp_marker).z(loc)];
                                        if isnan(cmp_data)
                                            continue;
                                        end
                                        MarkerCoordinateError = (sum((cmp_data-PatternCurrentMarkerCoordinate).^2)).^0.5;
        %                                 dist = [dist,abs(referenceLength - currentLength)];
                                        if MarkerCoordinateError >= patternCheckth
        %                                     disp(['          Not Found at:',cmp_marker])
                                        else
                                            disp(['          Potentially Found using Pattern Fill Reference at: ',cmp_marker])
                                            false_flag = 2;
                                            doubleCheckedNum = 0;
                                            for ee = 1:length(currentCluster)
                                                currentClusterMarker = currentCluster{ee}; % cluster marker that we're looking at
                                                if ~isnan(markerStruct.(currentClusterMarker).x(loc))
                                                    currentClusterMarkerReference = [markerStructRef.(currentClusterMarker).x(1); markerStructRef.(currentClusterMarker).y(1); markerStructRef.(currentClusterMarker).z(1)];
                                                    currentMarkerReference = [markerStructRef.(currentMarker).x(1); markerStructRef.(currentMarker).y(1); markerStructRef.(currentMarker).z(1)];
                                                    cmpReferenceLength = (sum((currentMarkerReference-currentClusterMarkerReference).^2)).^0.5;
                                                    currentClusterMarkerCoordinate = [markerStruct.(currentClusterMarker).x(loc); markerStruct.(currentClusterMarker).y(loc); markerStruct.(currentClusterMarker).z(loc)];
                                                    currentcmpMarkerCoordinate = [markerStruct.(cmp_marker).x(loc); markerStruct.(cmp_marker).y(loc); markerStruct.(cmp_marker).z(loc)];
                                                    cmpCurrentLength = (sum((currentcmpMarkerCoordinate-currentClusterMarkerCoordinate).^2)).^0.5;
                                                    if abs(cmpReferenceLength - cmpCurrentLength) > jumpThreshold
        %                                                     disp('False Alarm')
                                                        false_flag = 1;
                                                        break;
                                                    else
        %                                                     disp('Double Checked!')
                                                        doubleCheckedNum = doubleCheckedNum + 1;
                                                        false_flag = 0;
                                                    end
                                                end
                                            end
                                            if false_flag == 0 && doubleCheckedNum >= 2
                                                found = found + 1;
                                                found_marker{end+1} = cmp_marker;
                                                found_data{end+1} = cmp_data;
                                                found_dist{end+1} = abs(referenceLength - currentLength);

                                                foundMarkerSet = [foundMarkerSet(:)',{currentMarker}];
                                                foundFlag = 1;
                                            end                                    
                                        end
                                        if dd == length(temp_markerSet_names)
        %                                     disp('Not Found from any Markers')
                                            nofound = nofound + 1;
                                        end
                                    end
                                end
                            end
                        end
    
                        if found >= 1
                            foundMarker = unique(found_marker);
                            if length(foundMarker) > 1
                                warning('Found Multiple Markers')
                                continue;
                            end
                            disp(['     FOUND at: ',foundMarker{:},' at frame ',num2str(loc+startFrameOffset-1)])
                            foundMarkerSet = [foundMarkerSet(:)',{currentMarker}];
                            foundFlag = 1;
                            pointTarget = found_data{1};
                            markerStruct.(currentMarker).x(loc) = pointTarget(1); % save x
                            markerStruct.(currentMarker).y(loc) = pointTarget(2); % save y
                            markerStruct.(currentMarker).z(loc) = pointTarget(3); % save z
                            markerStruct.(foundMarker{:}).x(loc) = NaN;
                            markerStruct.(foundMarker{:}).y(loc) = NaN;
                            markerStruct.(foundMarker{:}).z(loc) = NaN;
                            if ~any(~isnan(markerStruct.(foundMarker{:}).x))
                                markerStruct = rmfield(markerStruct,foundMarker{:});
                            end
                        end
                    else
                        for jj = 1:length(temp_markerSet_names)
                            cmp_marker = temp_markerSet_names{jj};
                            cmp_data = [markerStruct.(cmp_marker).x(loc), markerStruct.(cmp_marker).y(loc),markerStruct.(cmp_marker).z(loc)];             
%                             found_fw = find((sum((cmp_data-jp_marker_fw).^2,2)).^0.5 < gap_th*gap);
%                             found_bw = find((sum((cmp_data-jp_marker_bw).^2,2)).^0.5 < gap_th*gap);
%                             found = [found_fw found_bw];
%                             if ~isempty(found)
                            if any(isnan(cmp_data))
                                continue
                            end
                            dataRange = data(loc-gap:loc+gap,:);
                            dataRange(gap+1,:) = cmp_data;
                            markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
                            if ~any(abs(diff(markerSpeedIncrement)) > 10) && ~any(markerSpeedIncrement > jumpThreshold) && any(~isnan(markerSpeedIncrement(gap:gap+1)))
                                loc_found = loc + startFrameOffset - 1;
                                disp(['     FOUND at: ',cmp_marker,' at frame ',num2str(loc_found')])
                                foundMarkerSet = [foundMarkerSet(:)',{currentMarker}];
                                foundFlag = 1;
                                pointTarget = cmp_data;
                                markerStruct.(currentMarker).x(loc) = pointTarget(1); % save x
                                markerStruct.(currentMarker).y(loc) = pointTarget(2); % save y
                                markerStruct.(currentMarker).z(loc) = pointTarget(3); % save z
                                markerStruct.(cmp_marker).x(loc) = NaN;
                                markerStruct.(cmp_marker).y(loc) = NaN;
                                markerStruct.(cmp_marker).z(loc) = NaN;
                                if ~any(~isnan(markerStruct.(cmp_marker).x))
                                    markerStruct = rmfield(markerStruct,cmp_marker);
                                end
                                break;
                            end
                            if jj == length(temp_markerSet_names)
                                
        %                         loc_jp = loc + startFrameOffset - 1;
            %                     disp(['NO FOUND at any marker for: ',currentMarker,' Missing marker at frame ',num2str(loc_jp)])
                            end
                        end
                    end
                end
            end
        end
    end
markerSet = unique(foundMarkerSet);
localIter = localIter + 1;
end
end