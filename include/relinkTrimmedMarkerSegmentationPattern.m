function [markerStruct,markersetToFill,relinkedFlag] = relinkTrimmedMarkerSegmentationPattern(markerStruct,clusters,refmarkerset,debugFlag)
disp('%%%%%Relink Trimmed Marker Segments Using PatternFill%%%%%')
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);
totalFrames = length(markerStruct.(markerStructname).Header);
markerSet = fieldnames(markerStruct);
CmarkerSet = markerSet(contains(markerSet,'C_'));
[markerSeglocs,markerSegSet] = segmentMarkers(markerStruct);
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
    if ~isfield(markerStruct,currentMarker)
        continue
    end
    disp(['Searching for: ', currentMarker])
    
%     markerStructname = fieldnames(markerStruct);
%     current_temp_names=markerStructname(contains(markerStructname,'C_'));
%     temp_names = {};
%     for jj = 1:length(current_temp_names)
%         cmp_marker = current_temp_names{jj};
%         cmp_noNaNIdxs = find(~isnan(markerStruct.(cmp_marker).x));
%         current_noNaNidxs = find(~isnan(markerStruct.(currentMarker).x));
%         [commonVals,~] = intersect(cmp_noNaNIdxs,current_noNaNidxs);
%         if isempty(commonVals)
%             temp_names = [temp_names(:)',{cmp_marker}];
%         end
%     end
    
    markerSeg = markerSeglocs{contains(markerSegSet,currentMarker)};


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
            data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    
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
                filledFlag = 0;
                try
                    PatternMarkerStruct = Vicon.PatternFill(markerStruct,currentMarker,currentCluster, starting, ending);
                    PatternMarkerFilled = [PatternMarkerStruct.(currentMarker).x, PatternMarkerStruct.(currentMarker).y, PatternMarkerStruct.(currentMarker).z];
                    filledFlag = 1;
                catch
                    PatternMarkerFilled = data;
                    for cci = 1:length(currentCluster) % loop through cluster markers
                        currentDonor = currentCluster{cci}; % look at specific donor marker
                        currentCoordinate = [markerStruct.(currentDonor).x, markerStruct.(currentDonor).y, markerStruct.(currentDonor).z];
                        if ~any(isnan(currentCoordinate(starting:ending,1)))
                            patternDiff = currentCoordinate - currentCoordinate(checkLoc,:);
                            PatternMarkerFilled(starting:ending,:) = data(checkLoc,:) + patternDiff(starting:ending,:);
                            filledFlag = 1;
                            break;
                        end
                    end
                end
            end
            if ~filledFlag
                continue
            end
    
            markerSet = fieldnames(markerStruct);
            temp_names=markerSet(contains(markerSet,'C_'));
    
            for jj = 1:length(temp_names)
                currentFound = 0;
                cmp_marker = temp_names{jj};
                cmp_data = [markerStruct.(cmp_marker).x(starting:ending), markerStruct.(cmp_marker).y(starting:ending),markerStruct.(cmp_marker).z(starting:ending)];             
                if any(~isnan(cmp_data(:,1))) 
                    noNaNIdxs =~isnan(markerStruct.(cmp_marker).x);
                    currentMarkerCoordinate = PatternMarkerFilled(noNaNIdxs,:);
                    if any(isnan(currentMarkerCoordinate))
                        continue
                    end
                    cmp_noNaNIdxs = find(~isnan(markerStruct.(cmp_marker).x));
                    current_noNaNidxs = find(~isnan(markerStruct.(currentMarker).x));
                    [commonVals,~] = intersect(cmp_noNaNIdxs,current_noNaNidxs);
                    if ~isempty(commonVals) || ~isfield(markerStruct,cmp_marker) || strcmp(currentMarker,cmp_marker)
                        continue
                    end
                    cmpMarkerCoordinate = [markerStruct.(cmp_marker).x(cmp_noNaNIdxs), markerStruct.(cmp_marker).y(cmp_noNaNIdxs),markerStruct.(cmp_marker).z(cmp_noNaNIdxs)];
                    referenceDiff = (sum((currentMarkerCoordinate-cmpMarkerCoordinate).^2,2)).^0.5;
                    
                    if (length(referenceDiff) == 1 && referenceDiff < 10 && ending - starting <= 150) || all(referenceDiff <= 15)
                        cmp_data_range = find(~isnan(markerStruct.(cmp_marker).x));
%                         if strcmp(cmp_marker,'C_959')
%                             disp('pause')
%                         end
                        cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                        disp(['     PatternFill Found(',num2str(max(referenceDiff),3),') : ', currentMarker,' with ',cmp_marker, ' at frames: ',num2str(cmp_data_range(1)+startFrameOffset-1),' - ',num2str(cmp_data_range(end)+startFrameOffset-1)])
                        
                        markerStruct.(currentMarker).x(cmp_data_range) = markerStruct.(cmp_marker).x(cmp_data_range); % save x
                        markerStruct.(currentMarker).y(cmp_data_range) = markerStruct.(cmp_marker).y(cmp_data_range); % save y
                        markerStruct.(currentMarker).z(cmp_data_range) = markerStruct.(cmp_marker).z(cmp_data_range); % save z
                        markerStruct = rmfield(markerStruct,cmp_marker);
                        markersetToFill = [markersetToFill(:)',currentMarker];
                        relinkedFlag = 1;
                        foundFlag = 1;
                        currentFound = 1;
                        % For Debug
                        if debugFlag
                            figure(1)
                            clf
                            title(currentMarker)
                            subplot(3,1,1)
                            plot(markerStruct.(currentMarker).Header,markerStruct.(currentMarker).x,'b.-')
                            hold on
                            subplot(3,1,2)
                            plot(markerStruct.(currentMarker).Header,markerStruct.(currentMarker).y,'b.-')
                            hold on
                            subplot(3,1,3)
                            plot(markerStruct.(currentMarker).Header,markerStruct.(currentMarker).z,'b.-')
                            hold on
                            subplot(3,1,1)
                            plot(markerStruct.(currentMarker).Header(cmp_data_range),markerStruct.(currentMarker).x(cmp_data_range),'r.-')
                            subplot(3,1,2)
                            plot(markerStruct.(currentMarker).Header(cmp_data_range),markerStruct.(currentMarker).y(cmp_data_range),'r.-')
                            subplot(3,1,3)
                            plot(markerStruct.(currentMarker).Header(cmp_data_range),markerStruct.(currentMarker).z(cmp_data_range),'r.-')
                            pause(1)
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
% if debugFlag
%     saveas(gcf,['debugFig\',currentMarker,'_PatternFill.png'])
% end
clf
end
end