function [markerDict,markerSetToLink,relinkedFlag] = relinkMarkerSegmentation(markerSet,markerDict,markerDictRef,clusters,jp_threshold,debugFlag,verbose)
if verbose
disp('%%%%%Relink Marker Segments%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

% markerSet = fieldnames(markerStruct);
markerSetToLink = {};
relinkedFlag = 0;
% [markerSeglocs,markerSegSet] = segmentMarkers(markerStruct);
% debugFlag = 1;

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    % get segment start and end frame
    if verbose
    disp(['  Current Marker: ',currentMarker])
    end
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    
    foundFlag = 1;
    while foundFlag
        foundFlag = 0;

        markerSegDict = segmentSingleMarker(markerDict,{currentMarker});
%         markerSeg = markerSegDict({currentMarker});
%         markerSeg = markerSeg{:};
        markerSeg = markerSegDict{:};

        for ii = 1:length(markerSeg)
            if mod(ii,2)
                checkLoc = markerSeg(ii)-1;
            else
                checkLoc = markerSeg(ii)+1;
            end
            if checkLoc < 1 || checkLoc > totalFrames
                continue
            end
            currentLoc = markerSeg(ii);
            found_markers = {};
            found_diffs = [];
            markerSetTemp = keys(markerDict);
            temp_names=markerSetTemp(contains(markerSetTemp,'C_'));
            CmarkerSet = temp_names;
            for jj = 1:length(CmarkerSet)
                cmp_marker = CmarkerSet{jj};
                cmp_data = getIfMarkerCoordinateNaN(markerDict,cmp_marker,checkLoc);
                cmp_data_range = getIfMarkerCoordinateNaN(markerDict,cmp_marker,currentLoc);
                if cmp_data || ~cmp_data_range
                    continue
                end
%                 cmp_noNaNIdxs = find(~isnan(markerStruct.(cmp_marker).x));
%                 current_noNaNidxs = find(~isnan(markerStruct.(currentMarker).x));
%                 [commonVals,~] = intersect(cmp_noNaNIdxs,current_noNaNidxs);
                cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                currentX = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
                
                hasIntersection = any(~isnan(cmpX(:,1)) & ~isnan(currentX(:,1)));
                if hasIntersection || ~isKey(markerDict,{cmp_marker}) || strcmp(currentMarker,cmp_marker)
                    continue
                end
                
                data = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
                dataRange = data(currentLoc,:);
                dataRange(2,:) = getMarkerCoordinates(markerDict,cmp_marker,checkLoc)';
                markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
                if markerSpeedIncrement < jp_threshold
                    found_markers = [found_markers(:)',{cmp_marker}];
                    found_diffs = [found_diffs,markerSpeedIncrement];
                    break;
                end
            end
            if length(found_markers) >= 1
                if length(found_markers) > 1
                    [~,found_idx] = min(found_diffs);
                    cmp_marker = found_markers{found_idx};
                    if verbose
                    disp('   Found Multiple Markers')
                    end
                else
                    cmp_marker = found_markers{:};
                end
                cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                cmp_data_range = find(~isnan(cmpX(:,1)));
                starting = cmp_data_range(1);
                ending = cmp_data_range(end);
                loc_found = cmp_data_range + startFrameOffset - 1;
                if verbose
                disp(['     Normal Relink: ',currentMarker,' with ',cmp_marker,' at frames ',num2str(loc_found(1)),' - ',num2str(loc_found(end))])
                end
                markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_data_range);

    %             jumped = checkRigidBodyJump(markerStruct,currentMarker,markerStructRef,clusters,cluster_jump_threshold,starting,ending);
                if debugFlag
                    currentMarkerCord = markerDict({currentMarker});
                    currentMarkerCord = currentMarkerCord{:};
    
                    figure(1)
                    clf
                    sgtitle(currentMarker)
                    subplot(3,1,1)
                    plot(currentMarkerCord(:,1),currentMarkerCord(:,2),'b.-')
                    hold on
                    subplot(3,1,2)
                    plot(currentMarkerCord(:,1),currentMarkerCord(:,3),'b.-')
                    hold on
                    subplot(3,1,3)
                    plot(currentMarkerCord(:,1),currentMarkerCord(:,4),'b.-')
                    hold on
                    subplot(3,1,1)
                    plot(currentMarkerCord(cmp_data_range,1),currentMarkerCord(cmp_data_range,2),'r.-')
                    subplot(3,1,2)
                    plot(currentMarkerCord(cmp_data_range,1),currentMarkerCord(cmp_data_range,3),'r.-')
                    subplot(3,1,3)
                    plot(currentMarkerCord(cmp_data_range,1),currentMarkerCord(cmp_data_range,4),'r.-')
                end
                jumped = 0;
                if jumped
                    markerStruct = markerStructBefore;
                    if verbose
                    disp('     Normal Relink Incorrectly, Revert Back')
                    end
                else
                    markerDict({cmp_marker}) = [];
                    relinkedFlag = 1;
                    foundFlag = 1;
                    markerSetToLink = [markerSetToLink(:)',currentMarker];
                end
            end
        end
    end
    clf
end
markerSetToLink = unique(markerSetToLink);
end