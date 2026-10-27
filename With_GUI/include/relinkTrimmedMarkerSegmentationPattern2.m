function [markerDict,markersetToFill,relinkedFlag] = relinkTrimmedMarkerSegmentationPattern2(markerDict,clusters,refmarkerset,debugFlag,verbose)
if nargin < 5
    verbose = true;
end
if verbose
    disp('%%%%%Relink Trimmed Marker Segments Using PatternFill%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

markerSet = markerStructnames;
CmarkerSet = markerSet(contains(markerSet,'C_'));
markerSegDict = segmentMarkers(markerDict,verbose);

relinkedFlag = 0;
foundFlag = 0;
markersetToFill = {};
markersetCluster = {};
for mm = 1:length(refmarkerset)
    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},refmarkerset{mm})) % if the cluster contains the marker that we're currently looking at
            markersetCluster = [markersetCluster(:)',clusters{aa}];
        end
    end
end
refmarkerset = unique(markersetCluster);

for mm = 1:length(refmarkerset) % loop through marker set
    currentMarker = refmarkerset{mm};
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    if verbose
        disp(['Searching for: ', currentMarker])
    end
    
    markerSeg = markerSegDict({currentMarker});
    markerSeg = markerSeg{:};


    currentClusters = {};
    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
            currentCluster = clusters{aa}; % keep that cluster
            idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
            currentCluster(idx) = []; % delete current marker from cluster
            currentClusters(end+1) ={currentCluster};
        end
    end
    
    for ii = 1:length(markerSeg)
        segLoc = markerSeg(ii);
        foundFlag = 1;
        while foundFlag
            foundFlag = 0;
            currentArr = markerDict({currentMarker});
            currentArr = currentArr{:};
            data = currentArr(:,2:4);
            currentOccupied = ~isnan(currentArr(:,2));
            if mod(ii,2)
                checkLoc = segLoc;
                ending = checkLoc-1;
                if ii == 1
                    starting = 1;
                else
                    starting = markerSeg(ii-1)+1;
                end
%                 if ending - starting > 100
%                     starting = ending - 100;
%                 end
            else
                checkLoc = segLoc;
                starting = checkLoc+1;
                if ii == length(markerSeg)
                    ending = totalFrames;
                else
                    ending = markerSeg(ii+1)-1;
                end
%                 if ending - starting > 100
%                     ending = starting + 100;
%                 end
            end
            if ending < starting
                continue;
            end
            
            for ccs = 1:length(currentClusters)
                currentCluster = currentClusters{ccs};
                PatternMarkerFilled = data;
                for cci = 1:length(currentCluster) % loop through cluster markers
                    currentDonor = currentCluster{cci}; % look at specific donor marker
                    donorArr = markerDict({currentDonor});
                    donorArr = donorArr{:};
                    currentCoordinate = donorArr(:,2:4);
                    if ~all(isnan(currentCoordinate(:,1))) && ~all(isnan(currentCoordinate(starting:ending,1)))
                        patternDiff = currentCoordinate - currentCoordinate(checkLoc,:);
                        PatternMarkerFilled(starting:ending,:) = data(checkLoc,:) + patternDiff(starting:ending,:);

                        markerSet = keys(markerDict);
                        temp_names=markerSet(contains(markerSet,'C_'));

                        for jj = 1:length(temp_names)
                            currentFound = 0;
                            cmp_marker = temp_names{jj};
                            cmpArr = markerDict({cmp_marker});
                            cmpArr = cmpArr{:};
                            cmp_data = cmpArr(starting:ending,2:4);
                            if any(~isnan(cmp_data(:,1))) 
                                cmpOccupied = ~isnan(cmpArr(:,2));
                                noNaNIdxs = cmpOccupied;
                                currentMarkerCoordinate = PatternMarkerFilled(noNaNIdxs,:);
                                if any(isnan(currentMarkerCoordinate))
                                    continue
                                end
                                if any(cmpOccupied & currentOccupied) || strcmp(currentMarker,cmp_marker)
                                    continue
                                end

                                cmpMarkerCoordinate = cmpArr(noNaNIdxs,2:4);
                                referenceDiff = (sum((currentMarkerCoordinate-cmpMarkerCoordinate).^2,2)).^0.5;

                                if (length(referenceDiff) == 1 && referenceDiff < 5 && ending - starting <= 150) || all(referenceDiff <= 10)
                                    cmp_data_range = find(cmpOccupied);
                                    cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                                    if verbose
                                        disp(['     PatternFill Found(',num2str(max(referenceDiff),3),') : ', currentMarker,' with ',cmp_marker, ' at frames: ',num2str(cmp_data_range(1)+startFrameOffset-1),' - ',num2str(cmp_data_range(end)+startFrameOffset-1)])
                                    end
                                    
                                    markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_data_range);
                                    markerDict({cmp_marker}) = [];
                                    markersetToFill = [markersetToFill(:)',currentMarker];
                                    relinkedFlag = 1;
                                    foundFlag = 1;
                                    currentFound = 1;
                                    % For Debug
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
                                    break;
                                end
                            end
                        end
                        if mod(ii,2) && foundFlag
                            segLoc = cmp_data_range(1);
                        elseif ~mod(ii,2) && foundFlag
                            segLoc = cmp_data_range(end);
                        end
                        if segLoc < 1 || segLoc > totalFrames
                            foundFlag = 0;
                        end
                    end
                end
            end
        end
    end
% if debugFlag
%     saveas(gcf,['debugFig\',currentMarker,'_PatternFill.png'])
% end
% clf
end
end