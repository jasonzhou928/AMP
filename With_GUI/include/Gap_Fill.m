function markerStruct = Gap_Fill(markerSet,markerStruct,staticStruct,clusters)

                    markerList = {};
                    for cc = 1:length(clusters)
                        cluster = clusters{cc};
                        for mm = 1:length(cluster)
                            marker = cluster{mm};
                            if ~any(strcmp(markerList,marker))
                                markerList{end+1} = marker;
                            end
                        end
                    end
                   
                    % Loop through all markers
                    markerStruct = checkForAbsentMarkers(markerSet,markerStruct,clusters,staticStruct);              



                    % Rigid body fill
                    markerStruct = Rigid_Body_Fill_All_Gaps(markerList, markerStruct, clusters,false);
                   
                    % Fill missing first/last and final rigid body fill
                    markerStruct = Find_Missing_First_And_Last_Frames(markerList, markerStruct, clusters);
                    markerStruct = Rigid_Body_Fill_All_Gaps(markerList, markerStruct, clusters,false);
                    markerStruct = Rigid_Body_Fill_All_Gaps(markerList, markerStruct, clusters,true);
                    markerStruct = Rigid_Body_Fill_All_Gaps(markerList, markerStruct, clusters,true);
                    
                    
                    
                  

end


%% FUNCTIONS

function markerStruct = Rigid_Body_Fill_All_Gaps(allMarkerNames, markerStruct, clusters, allowNonRigidFill, varargin)
%RIGID BODY FILL ALL GAPS
%   This uses Jonathan's toolbox to do the rigid body gap filling for
%   markers.  The only additional functionality that this function adds is
%   it iterates through all markers in a data set and fills everything that
%   it is able to.  This relies on a cell containing each rigid body
%   segment.  The markers defined in this cluster will be used to fill the
%   other gaps in the segment markers.

lengthVarargin = length(varargin);
if lengthVarargin == 1
    if contains(varargin{1},'plot')
        plotResults = 1;
    else
        error('Did not enter correct varargin')
    end
else
    plotResults = 0;
end


% FILL GAPS

missingFrames = Vicon.findGaps(markerStruct); % find all missing frames in data
for mm = 1:length(allMarkerNames) % loop through all markers
    currentMarker = allMarkerNames{mm}; % define current marker
    if isempty(missingFrames.(currentMarker)) == 0 % if there are missing markers
        
        %Find other markers to drive the fix
        for ii = 1:length(clusters) % look at all of the defined clusters
            if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                currentCluster = clusters{ii}; % keep that cluster
                idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                currentCluster(idx) = []; % delete current marker from cluster
                
                % May need to add functionality if there aren't enough
                % markers in the cluster
            end
        end
        
        [a,~] = size(missingFrames.(currentMarker)); % define the number of gaps
        
        for ii = 1:a
            startFrame = missingFrames.(currentMarker)(ii,1); % start frame of gap
            endFrame = missingFrames.(currentMarker)(ii,2); % end frame of gap
            try
                markerStruct = Vicon.RigidBodyFill(markerStruct, currentMarker, currentCluster, startFrame, endFrame); % fill the gap
            catch
                if allowNonRigidFill
            %warning(['Not enough donors to rigid body fill for ' currentMarker ' at frames ' num2str(startFrame) ' through ' num2str(endFrame) '. Spline filling Instead.' ])
            try
            markerStruct = Vicon.SplineFill(markerStruct, currentMarker, currentCluster, startFrame, endFrame);
            catch
            %warning(['Not enough donors to spline fill for ' currentMarker ' at frames ' num2str(startFrame) ' through ' num2str(endFrame) '. Pattern filling Instead.' ])
            markerStruct = Vicon.PatternFill(markerStruct, currentMarker, currentCluster, startFrame, endFrame);
            end
                else
                    continue
                end
            end
        end
        
        if plotResults == 1
            plot(markerStruct.(currentMarker).Header, markerStruct.(currentMarker).x, 'k-')
            title(currentMarker)
            xlabel('Windows')
            ylabel('Position (m)')
            legend('original points', 'filled')
        end
     end
end
end


function checkForJumpingMarkers(markerSet,markerStruct,jumpThreshold)

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    dataNext = data(2:end,:);
    data = data(1:end-1,:);
    markerIncrements = (sum((dataNext-data).^2,2)).^0.5; % distance between marker frames
    if sum(markerIncrements>jumpThreshold)>0 % if there is a marker jump
        loc = find(markerIncrements>jumpThreshold);
        %disp(['    MARKER JUMP: ',currentMarker,' starting at frame: ', num2str(loc')])
    end
end

end

% -------------------------------------------------------------------------

function markerStruct = Find_Missing_First_And_Last_Frames(allMarkerNames, markerStruct, clusters, varargin)
% FILL THE FIRST AND LAST FRAMES IN A C3D FILE
%   C3D files may contain marker trajectories that have the first and last
%   data points missing due to the inability of Vicon to deal with missing
%   edge trajectories.  This function uses absolute orientation (Horn's
%   method) to estimate the marker position in the first and last frames
%   based on donor data, consisting of marker data from markers on the same
%   rigid body.  This will only fill the first and last frames so that
%   other gap filling tools can be used.

% INPUTS:

% varargin: If you want to fill both starting and ending frames, do not
% enter anything.  To fill just the first frame, enter 'first'.  To fill
% just the last frame, enter 'last'.


numberVarargins = length(varargin);
if numberVarargins == 0
    fillBoth = 1;
else
    fillBoth = 0;
end

if numberVarargins == 1
    if contains(varargin{1},'first')
        fillFirst = 1;
        fillLast = 0;
    elseif contains(varargin{1},'last')
        fillFirst = 0;
        fillLast = 1;
    else
        error('Did not enter correct varargin')
    end
end

% FILL FIRST FRAME
if fillBoth == 1 || fillFirst == 1
    for mm = 1:length(allMarkerNames)
        currentMarker = allMarkerNames{mm}; % checking the frames for this marker
        
        firstFrame = 0; % resetting variable
        startLooking = 1; % start looking for first good frame at this point (!!!!!!!!!!)
        
        if isnan(markerStruct.(currentMarker).x(1)) % if first frame is missing (!!!!!!!!!)
            % Find first full frame of data
            currentMarker
            while isnan(markerStruct.(currentMarker).x(startLooking)) % look until data is not NaN
                startLooking = startLooking + 1;
            end
            firstFrame = startLooking; % this is the first frame where there is data
            
            %Find other markers to drive the fix
            for ii = 1:length(clusters) % look at all of the defined clusters
              
                if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                    currentCluster = clusters{ii}; % keep that cluster
                    idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                    currentCluster(idx) = []; % delete current marker from cluster

                    
                    % Check that all markers in cluster also exist
                    cc = 1;
                    while cc <= length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        deleteThese = [];
                        if isnan(markerStruct.(currentClusterMarker).x(1)) % if the cluster marker is missing in the first frame (!!!!!!!!!!!!!!)
                            % disp(['Current cluster: ', currentCluster])
                            % disp(['Current marker: ', currentMarker])
                            % %disp(['TARGET MARKER: ', currentMarker])
                            % disp(['OTHER MISSING: ',currentClusterMarker])
                            idx = strcmp(currentCluster,currentClusterMarker); % find where current marker is in cluster
                            currentCluster(idx) = []; % delete current marker from cluster
                        elseif isnan(markerStruct.(currentClusterMarker).x(firstFrame)) % if the cluster marker is missing in the first frame (!!!!!!!!!!!!!!)
                            % disp(['Current cluster: ', currentCluster])
                            % disp(['Current marker: ', currentMarker])
                            % %disp(['TARGET MARKER: ', currentMarker])
                            % disp(['OTHER MISSING: ',currentClusterMarker])
                            idx = strcmp(currentCluster,currentClusterMarker); % find where current marker is in cluster
                            currentCluster(idx) = []; % delete current marker from cluster
                        else
                           cc = cc+1;
                        end
                        %disp(['Cluster before: ', currentCluster])
                        %currentCluster(deleteThese) = []; % delete current marker from cluster
                        %disp(['Delete these: ', deleteThese])
                        %disp(['Cluster after: ', currentCluster])
                    end
                end
            end
            
            % Get donor coordinates
            donorFull = []; % initiate
            donorTarget = []; % initiate
            
            
            pointFull = [markerStruct.(currentMarker).x(firstFrame); markerStruct.(currentMarker).y(firstFrame); markerStruct.(currentMarker).z(firstFrame)]; % gap marker coordinate in first full frame
            ii = 1;

            while ii <= length(currentCluster) % loop through cluster markers
                currentDonor = currentCluster{ii}; % look at specific donor marker
                if ~isnan(markerStruct.(currentDonor).x(firstFrame)) && ~isnan(markerStruct.(currentDonor).y(firstFrame)) && ~isnan(markerStruct.(currentDonor).z(firstFrame)) && ~isnan(markerStruct.(currentDonor).x(1)) && ~isnan(markerStruct.(currentDonor).y(1)) && ~isnan(markerStruct.(currentDonor).z(1))
                currentCoordinate = [markerStruct.(currentDonor).x(firstFrame); markerStruct.(currentDonor).y(firstFrame); markerStruct.(currentDonor).z(firstFrame)]; % find marker coordinates in first full frames of data
                
                donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix
                end
                if ~isnan(markerStruct.(currentDonor).x(firstFrame)) && ~isnan(markerStruct.(currentDonor).y(firstFrame)) && ~isnan(markerStruct.(currentDonor).z(firstFrame)) && ~isnan(markerStruct.(currentDonor).x(1)) && ~isnan(markerStruct.(currentDonor).y(1)) && ~isnan(markerStruct.(currentDonor).z(1))
                currentCoordinate = [markerStruct.(currentDonor).x(1); markerStruct.(currentDonor).y(1); markerStruct.(currentDonor).z(1)]; % find marker coordinates in first frame (missing) of data (!!!!!!!!!!!!!!!!!)
               
                donorTarget = [donorTarget, currentCoordinate];
                end% save coordinates in first (missing) data matrix
                ii = ii+1;
            end
           
            [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
            transformationMatrix = regParams.M; % pull out transformation matrix
            pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation
            
            pointTarget = transformationMatrix*pointToTransform; % transform marker
            markerStruct.(currentMarker).x(1) = pointTarget(1); % save x
            markerStruct.(currentMarker).y(1) = pointTarget(2); % save y
            markerStruct.(currentMarker).z(1) = pointTarget(3); % save z
        end
    end
end

% FILL LAST FRAME

if fillBoth == 1 || fillLast == 1
    for mm = 1:length(allMarkerNames)
        currentMarker = allMarkerNames{mm}; % checking the frames for this marker
        
        lastFrame = 0; % resetting variable
        lengthData = length(markerStruct.(currentMarker).x);
        startLooking = lengthData; % start looking for last good frame at this point (end of data vector)
        
        if isnan(markerStruct.(currentMarker).x(startLooking)) % if last frame is missing
            % Find first full frame of data
            while isnan(markerStruct.(currentMarker).x(startLooking)) % look until data is not NaN
                startLooking = startLooking - 1;
            end
            lastFrame = startLooking; % this is the last frame where there is data
            
            %Find other markers to drive the fix
            for ii = 1:length(clusters) % look at all of the defined clusters
                if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                    currentCluster = clusters{ii}; % keep that cluster
                    idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                    currentCluster(idx) = []; % delete current marker from cluster
                    
                    % Check that all markers in cluster also exist with data
                    cc = 1;
                    while cc <= length(currentCluster)
                        currentClusterMarker = currentCluster{cc}; % cluster marker that we're looking at
                        if isnan(markerStruct.(currentClusterMarker).x(lengthData)) % if the cluster marker is missing in the last frame
                            idx = strcmp(currentCluster,currentClusterMarker); % find where current marker is in cluster
                            currentCluster(idx) = []; % delete current marker from cluster
                        elseif isnan(markerStruct.(currentClusterMarker).x(lastFrame)) % if the cluster marker is missing in the last frame
                             idx = strcmp(currentCluster,currentClusterMarker); % find where current marker is in cluster
                            currentCluster(idx) = []; % delete current marker from cluster
                        else   
                            cc = cc+1;
                        end
                    end
                end
            end
            
            % Get donor coordinates
            donorFull = []; % initiate
            donorTarget = []; % initiate
            
            pointFull = [markerStruct.(currentMarker).x(lastFrame); markerStruct.(currentMarker).y(lastFrame); markerStruct.(currentMarker).z(lastFrame)]; % gap marker coordinate in last full frame
            for ii = 1:length(currentCluster) % loop through cluster markers
                currentDonor = currentCluster{ii}; % look at specific donor marker
                currentCoordinate = [markerStruct.(currentDonor).x(lastFrame); markerStruct.(currentDonor).y(lastFrame); markerStruct.(currentDonor).z(lastFrame)]; % find marker coordinates in last full frames of data
                donorFull = [donorFull, currentCoordinate]; % save coordinates in full data matrix
                currentCoordinate = [markerStruct.(currentDonor).x(lengthData); markerStruct.(currentDonor).y(lengthData); markerStruct.(currentDonor).z(lengthData)]; % find marker coordinates in last frame (missing) of data
                donorTarget = [donorTarget, currentCoordinate]; % save coordinates in first (missing) data matrix
            end
            [regParams,~,~]=absor(donorFull,donorTarget); % find absolute orientation based on body rotation
            transformationMatrix = regParams.M; % pull out transformation matrix
            pointToTransform = [pointFull;1]; % set up first data point of missing marker for transformation
            
            pointTarget = transformationMatrix*pointToTransform; % transform marker
            markerStruct.(currentMarker).x(lengthData) = pointTarget(1); % save x
            markerStruct.(currentMarker).y(lengthData) = pointTarget(2); % save y
            markerStruct.(currentMarker).z(lengthData) = pointTarget(3); % save z
        end
    end
end

end

% -------------------------------------------------------------------------

function checkForMissingMarkers(markerStruct, markerSet)
missingFrames = Vicon.findGaps(markerStruct); % find missing frames
for mm = 1:length(markerSet)
    currentMarker = markerSet{mm};
    if isempty(missingFrames.(currentMarker))==0 && contains(currentMarker,'C_')==0
        disp(['    MISSING:',currentMarker])
    end
end
end
% ----------------------------------------------------------------------------
function markerStruct = checkForAbsentMarkers(markerSet,markerStruct,clusters,staticStruct)
    fields = fieldnames(markerStruct);
    frames = length(markerStruct.(fields{1}).x);
    for mm = 1:length(clusters)
        markernames = clusters{mm};
        Names = {};
        for ll = 1:length(markernames)
            Names{end + 1} = markernames{ll};
        end
        for ll = 1:length(markernames)
            markerName = markernames{ll};
        coords = [];
        if ~any(strcmp(fields,markerName))
            idx = strcmp(Names,markerName);
            markerStruct.(markerName) = table;
            markerStruct.(markerName).Header(1:frames) = [1:frames]';
            markerStruct.(markerName).x(1:frames) = NaN;
            markerStruct.(markerName).y(1:frames) = NaN;
            markerStruct.(markerName).z(1:frames) = NaN;
            otherMarkers = Names;
            staticCoord =  [staticStruct.(markerName).x(1);staticStruct.(markerName).y(1);staticStruct.(markerName).z(1)];
            staticCoords = [];
            otherMarkers(idx) = [];
            rr = 0;
            for qq = 1:length(otherMarkers)
                otherMarkerName = otherMarkers{qq};
                if isfield(markerStruct, otherMarkerName)
                    rr = rr+1;
                coords(1,rr,1:frames) = markerStruct.(otherMarkerName).x;
                coords(2,rr,1:frames) = markerStruct.(otherMarkerName).y;
                coords(3,rr,1:frames) = markerStruct.(otherMarkerName).z;
                staticCoords(1,rr) = staticStruct.(otherMarkerName).x(1);
                staticCoords(2,rr) = staticStruct.(otherMarkerName).y(1);
                staticCoords(3,rr) = staticStruct.(otherMarkerName).z(1);
                end
            end
            disp(['Injecting Marker: ' markerName])
           
            for ff = 1:frames

                    if ~any(isnan([coords(:,:,ff)]))
                    p = absor([staticCoords],[coords(:,:,ff)]);
                    M = p.R * staticCoord + p.t;
                    markerStruct.(markerName).x(ff) = M(1);
                    markerStruct.(markerName).y(ff) = M(2);
                    markerStruct.(markerName).z(ff) = M(3);
                    end


            end
            
            fields = fieldnames(markerStruct);
        end
        end
    end


end