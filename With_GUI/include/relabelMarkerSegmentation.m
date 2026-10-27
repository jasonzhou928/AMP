function markerStruct = relabelMarkerSegmentation(markerStruct,markerSet)

disp('%%%%%Relabel Marker Segments%%%%%')
% Use the rigid body and pattern fill method to relabel the markers. First
% find the nearest available unlabeled markers from the markerset, then use
% rigid body 
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);
totalFrames = length(markerStruct.(markerStructname).Header);
direction = {'fw','bw'};

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    reverseFlag = 0;
    % get segment start and end frame
    if ~isfield(markerStruct,currentMarker)
        error('No Marker Found')
    end
    noNaNIdxs = find(~isnan(markerStruct.(currentMarker).x));
    starting = noNaNIdxs(1);
    ending = noNaNIdxs(end);

    for kk = 1:length(direction)
        if isfield(markerStruct,currentMarker)
            data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
        end
        dir = direction{kk};
        if strcmp(dir,'fw')
            itr_dir = ending+1:totalFrames;
            locs = ending:totalFrames-1;
        else
            itr_dir = starting-1:-1:1;
            locs = starting:-1:2;
        end

        for ii = 1:length(itr_dir)
            checkLoc = itr_dir(ii);
            currentLoc = locs(ii);
            temp_markerSet = rmfield(markerStruct,currentMarker);
            temp_markerSet_names = fieldnames(temp_markerSet);
            found_num = 0;
            for jj = 1:length(temp_markerSet_names)
                cmp_marker = temp_markerSet_names{jj};
                cmp_data = [markerStruct.(cmp_marker).x(checkLoc), markerStruct.(cmp_marker).y(checkLoc),markerStruct.(cmp_marker).z(checkLoc)];             
                if any(isnan(cmp_data))
                    continue
                end
                dataRange = data(currentLoc,:);
                dataRange(2,:) = cmp_data;
                markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
                if markerSpeedIncrement < 40
                    cmp_data_range = find(~isnan(markerStruct.(cmp_marker).x));
                    cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                    loc_found = cmp_data_range + startFrameOffset - 1;
                    markerStruct.(currentMarker).x(cmp_data_range) = markerStruct.(cmp_marker).x(cmp_data_range); % save x
                    markerStruct.(currentMarker).y(cmp_data_range) = markerStruct.(cmp_marker).y(cmp_data_range); % save y
                    markerStruct.(currentMarker).z(cmp_data_range) = markerStruct.(cmp_marker).z(cmp_data_range); % save z
                    
                    if ~contains(cmp_marker,'C_')
                        cmp_data_range = find(~isnan(markerStruct.(currentMarker).x));
                        cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                        loc_found = cmp_data_range + startFrameOffset - 1;
                        markerStruct.(cmp_marker).x(cmp_data_range) = markerStruct.(currentMarker).x(cmp_data_range); % save x
                        markerStruct.(cmp_marker).y(cmp_data_range) = markerStruct.(currentMarker).y(cmp_data_range); % save y
                        markerStruct.(cmp_marker).z(cmp_data_range) = markerStruct.(currentMarker).z(cmp_data_range); % save z
                        disp(['     Relink: ',cmp_marker,' with ',currentMarker,' at frames ',num2str(loc_found(1)),' - ',num2str(loc_found(end)),' with direction: ',dir])
                        markerStruct = rmfield(markerStruct,currentMarker);
                        reverseFlag = 1;
                        break;
                    else
                        disp(['     Relink: ',currentMarker,' with ',cmp_marker,' at frames ',num2str(loc_found(1)),' - ',num2str(loc_found(end)),' with direction: ',dir])
                        markerStruct = rmfield(markerStruct,cmp_marker);
                    end
%                     break;
                    found_num = found_num + 1;
                    relinkedFlag = 1;
                end
            end
%             disp(['Total Found Number for: ',currentMarker,'=',num2str(found_num),' with direction: ',dir])
            if ~found_num
                break;
            end
        end
        if reverseFlag
            break;
        end
    end
end
end