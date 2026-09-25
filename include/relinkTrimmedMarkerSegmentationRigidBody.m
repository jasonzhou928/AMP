function [markerDict,markersetToFill,relinkedFlag] = relinkTrimmedMarkerSegmentationRigidBody(markerDict,markerDictRef,clusters,refmarkerset,GoodFrames,GoodFrames2,cluster_jump_threshold,debugFlag,verbose)
if verbose
disp('%%%%%Relink Trimmed Marker Segments Using Rigid Body%%%%%')
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

direction = {'fw','bw'};
% [markerSeglocs,markerSegSet] = segmentMarkers(markerStruct);
relinkedFlag = 0;
markersetToFill = {};
% get all markerset from refmarkerset in the cluster
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
    
    % if ~isKey(markerDict,{currentMarker})
    %     continue
    % end
    reverseFlag = 0;
    GoodFrameFound = 1;
    if ~isempty(GoodFrames)
        GoodFrame = GoodFrames(1);
    else
        try
            GoodFrame = GoodFrames2({currentMarker});
            GoodFrame = GoodFrame{:};
            GoodFrame = GoodFrame(1);
        catch
            if verbose
            disp('   No Good Frame Found for this Marker - Using Static Trial Instead')
            end
            GoodFrameFound = 0;
        end

    end
    if verbose
    disp(['Searching for: ', currentMarker])
    end
    % get segment start and end frame
    currentClusters = {};
    currentClustersThresholds = {};
    cord = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    NaNIdxs = find(isnan(cord(:,1)));
    for aa = 1:length(clusters) % look at all of the defined clusters
        if any(strcmp(clusters{aa},currentMarker)) % if the cluster contains the marker that we're currently looking at
            currentCluster = clusters{aa}; % keep that cluster
            jump_threshold = cluster_jump_threshold{aa};
            idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
            currentCluster(idx) = []; % delete current marker from cluster
            currentClusters(end+1) ={currentCluster};
            currentClustersThresholds(end+1) ={jump_threshold};
        end
    end
    
    for kk = 1:length(direction)

        dir = direction{kk};
        if strcmp(dir,'fw')
            itr_dir = NaNIdxs;
        else
            itr_dir = flip(NaNIdxs);
        end
        
        for ii = 1:length(itr_dir)
            checkLoc = itr_dir(ii);
            
            foundFlag = 0;
            cord = getMarkerCoordinates(markerDict,currentMarker,checkLoc)';
            if ~isnan(cord(:,1))
                continue
            end
            % get the rigid body computed coordinate
            for ccs = 1:length(currentClusters)
                currentCluster = currentClusters{ccs};
                jump_threshold = currentClustersThresholds{ccs};
                donorFull = []; % initiate
                donorTarget = []; % initiate
                donorFullStatic = []; % initiate
                
                currentClusterRemovedNaNs = [];
                for cci = 1:length(currentCluster) % loop through cluster markers
                    currentDonor = currentCluster{cci}; % look at specific donor marker   
                    currentCoordinate = getMarkerCoordinates(markerDict,currentDonor,checkLoc);
                    if any(isnan(currentCoordinate(:)))
                        currentClusterRemovedNaNs(end+1)=cci;
                        continue
                    end
                    donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
                    if GoodFrameFound
                        currentCoordinate = getMarkerCoordinates(markerDict,currentDonor,GoodFrame);
                        donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix
                        pointFull = getMarkerCoordinates(markerDict,currentMarker,GoodFrame);
                    else
                        currentCoordinate = getMarkerCoordinates(markerDict,currentDonor,1);
                        donorFull = [donorFull, currentCoordinate];
                        pointFull = getMarkerCoordinates(markerDict,currentMarker,1);
                        donorFull = []; % I think we should avoid using the first frame as the reference b/c it could be wrong
                    end
                end
                currentClusterRemoved = currentCluster;
                currentClusterRemoved(currentClusterRemovedNaNs) = [];
                
                if ~isempty(donorTarget) && (isempty(donorFull) || any(isnan(donorFull(:))))
                    for ccr = 1:length(currentClusterRemoved) % loop through cluster markers
                        currentDonor = currentClusterRemoved{ccr}; % look at specific donor marker
                        currentCoordinate = getMarkerCoordinates(markerDictRef,currentDonor,1);
                        donorFullStatic = [donorFullStatic, currentCoordinate]; % save coordinates in full data matrix
                    end
                    donorFull = donorFullStatic;
                    pointFull = getMarkerCoordinates(markerDictRef,currentMarker,1);
                end

                if size(donorFull,2) < 3
                    continue
                end
                
                try
                    [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
                catch
                    continue
                end
                transformationMatrix = regParams.M; % pull out transformation matrix
                pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation
                
                pointTarget = transformationMatrix*pointToTransform; % transform marker
                rigidbodyComputed = transpose(pointTarget(1:3));
                
                markerSet = keys(markerDict);
                temp_names=markerSet(contains(markerSet,'C_'));
                for jj = 1:length(temp_names)
                    cmp_marker = temp_names{jj};
                    cmp_data = getMarkerCoordinates(markerDict,cmp_marker,checkLoc)';           
                    
                    if any(isnan(cmp_data(:,1))) 
                        continue
                    end
                    
                    cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                    currentX = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
                    
                    hasIntersection = any(~isnan(cmpX(:,1)) & ~isnan(currentX(:,1)));
                
                    if hasIntersection || ~isKey(markerDict,{cmp_marker}) || strcmp(currentMarker,cmp_marker)
                        continue
                    end
                    referenceDiff = (sum((rigidbodyComputed-cmp_data).^2)).^0.5;
                    if referenceDiff < [jump_threshold{:}]    %for RunMeCropped
                    % if referenceDiff < jump_threshold           %for RunMe
                        cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                        cmp_data_range = find(~isnan(cmpX(:,1)));
                        cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                        if verbose
                        disp(['     RigidBody Found(',num2str(referenceDiff,3),') : ', currentMarker,' with ',cmp_marker, ' at frames: ',num2str(cmp_data_range(1)+startFrameOffset-1),' - ',num2str(cmp_data_range(end)+startFrameOffset-1)])
                        end
                        markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_data_range);
                        markerDict({cmp_marker}) = [];
                        
                        markersetToFill = [markersetToFill(:)',currentMarker];
                        relinkedFlag = 1;
                        foundFlag = 1;
                        % For Debug
                        if debugFlag
                            currentMarkerCord = markerDict({currentMarker});
                            currentMarkerCord = currentMarkerCord{:};
                            figure(1)
                            clf
                            title(currentMarker)
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
                        
                        %
                        break
                    end
                end
                if foundFlag
                    break
                end
            end
        end
    end
% if debugFlag
%     saveas(gcf,['debugFig\',currentMarker,'_RigidBody.png'])
% end
clf
end
markersetToFill = unique(markersetToFill);
end