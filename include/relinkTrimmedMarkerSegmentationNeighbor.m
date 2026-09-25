
function [markerDict,markersetToFill,relinkedFlag] = relinkTrimmedMarkerSegmentationNeighbor(markerDict,markerDictRef,clusters,refmarkerset,cluster_jump_threshold,debugFlag,verbose)
if verbose
disp('%%%%%Relink Trimmed Marker Segments Using Neighbor Frame%%%%%')
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
gaps = {1,2,3,4,5,6,7,8,9,10};
segRangeMax = max(cell2mat(gaps));
reverseStr = '';
markersetToFill = {};
msg = '';

for mm = 1:length(refmarkerset) % loop through marker set
    currentMarker = refmarkerset{mm};
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    if verbose
    disp(['Searching for: ', currentMarker])
    
    if strcmp(currentMarker,'RMT5') %for debug
        disp('')
    end
    end
    markerSeg = markerSegDict({currentMarker});
    markerSeg = markerSeg{:};
    reverseStr = '';
    for ii = 1:length(markerSeg)
        segLoc = markerSeg(ii);
        foundFlag = 1;
        if verbose
        msg = sprintf('Segments To Go: %d\n', length(markerSeg) - ii);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        end
        while foundFlag
            foundFlag = 0;
            data = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
            markerSet = keys(markerDict);
            temp_names=markerSet(contains(markerSet,'C_'));
            for jj = 1:length(temp_names)
                currentFound = 0;
                cmp_marker = temp_names{jj};
                cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                currentX = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
                
                hasIntersection = any(~isnan(cmpX(:,1)) & ~isnan(currentX(:,1)));
                if hasIntersection || ~isKey(markerDict,{cmp_marker}) || strcmp(currentMarker,cmp_marker)
                    continue
                end




                for gg = 1:length(gaps)
                    gap = gaps{gg};
                    if mod(ii,2)
                        checkLoc = segLoc-gap;
                        segRange = segLoc:segLoc+segRangeMax;
                    else
                        checkLoc = segLoc+gap;
                        segRange = segLoc-segRangeMax:segLoc;
                    end
                    if checkLoc < 1 || checkLoc > totalFrames || ~isnan(data(checkLoc,1))
                        continue
                    end
                    if any(segRange < 1)
                        segRange = 1:segLoc;
                    elseif any(segRange > totalFrames)
                        segRange = segLoc:totalFrames;
                    end
                    CmarkerSeg = markerSegDict({cmp_marker});
                    CmarkerSeg = CmarkerSeg{:};
                    cmp_data = getMarkerCoordinates(markerDict,cmp_marker,checkLoc)';           
                    if ~any(isnan(cmp_data)) && any(ismember(checkLoc,CmarkerSeg))
                        % currentMarkerCoordinate = data(segLoc,:);
                        % if any(segRange<1) || any(segRange>totalFrames) || any(isnan(data(segRange,1))) || length(segRange)<2
                        %     referenceVel = 1;
                        % else
                        %     referenceVel = mean(sum(diff(data(segRange,:)).^2,2).^0.5);
                        % end
                        % referenceDiff = (sum((currentMarkerCoordinate-cmp_data).^2)).^0.5;
                        % referenceDiffAxis = currentMarkerCoordinate-cmp_data;
                        %% this section tries to predict where markers could be using velocity * gap
%                         % this computes the linear velocity of the currenmarker
%                         % in segRange
%                         referenceVelAxis = mean((diff(fillmissing(data(segRange,:),'linear',1))),'omitnan');
%                         if any(isnan(referenceVelAxis)) || length(segRange) == 1
%                             % disp('          No Reference Vel, Set to default value')
%                             referenceVelAxis = [1,1,1];
%                         end
% %                         if referenceDiff <= (referenceVel*gap+5)
% 
%                         if mod(ii,2)
%                             thresholdCheck = -referenceDiffAxis + referenceVelAxis*gap;
%                         else
%                             thresholdCheck = referenceDiffAxis + referenceVelAxis*gap;
%                         end
                        %% this section tries to use Kalman filter to predict the location of marker
                        inputData = data(segRange,:);
                        if mod(ii,2)
                            inputData = flip(inputData);
                        end
                        predicted_position = predictFuturePositions(inputData, 1,gap);
                        referenceDiff = (sum((predicted_position-cmp_data).^2,2)).^0.5;
                        %% check the relative distance between the prediction and the C_xx markers (unlabeled markers)
                        % if all(abs(thresholdCheck) < 20) && all(referenceDiff < 25)
                        if mean(referenceDiff) <= 25
%                             check = all(abs(referenceDiffAxis-referenceVelAxis*gap) < 10);
%                             check = abs(referenceDiffAxis-referenceVelAxis*gap) < 10;
                            cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
                            cmp_data_range = find(~isnan(cmpX(:,1)));
                            starting = cmp_data_range(1);
                            ending = cmp_data_range(end);
                            cmp_data_range = cmp_data_range(1):cmp_data_range(end);
                            % msg = ['     NeighborFrame Found(',num2str(thresholdCheck,3),') : ', currentMarker,' with ',cmp_marker, ' at frames: ',num2str(cmp_data_range(1)+startFrameOffset-1),' - ',num2str(cmp_data_range(end)+startFrameOffset-1)];
                            msg = ['     NeighborFrame Found(',num2str(mean(referenceDiff)),') : ', currentMarker,' with ',cmp_marker, ' at frames: ',num2str(cmp_data_range(1)+startFrameOffset-1),' - ',num2str(cmp_data_range(end)+startFrameOffset-1)];
                            if verbose
                            disp(msg)
                            end
                            markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_data_range);

                            jumped = 0;
                            if jumped
                                markerStruct = markerStructBefore;
                                if verbose
                                disp('     Relink Incorrectly, Revert Back')
                                end
                            else
                                markerDict({cmp_marker}) = [];
                                relinkedFlag = 1;
                                markersetToFill = [markersetToFill(:)',currentMarker];
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
                end

                if currentFound
                    break
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
        if ~contains(msg,'Segment')
            msg = newline;
            if verbose
            fprintf(msg);
            end
        end
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end

% if debugFlag
%     saveas(gcf,['debugFig\',currentMarker,'_Neighbor.png'])
% end
end
markersetToFill = unique(markersetToFill);
end

function predicted_positions = predictFuturePositions(positions, delta_t, num_steps)
    % Predicts future positions using a Kalman filter.
    % Handles missing data (NaNs) in the input positions.
    %
    % Parameters:
    %   positions   - An Nx3 matrix of observed positions (x, y, z) over N frames.
    %   delta_t     - Time interval between frames.
    %   num_steps   - Number of future positions to predict.
    %
    % Returns:
    %   predicted_positions - An Mx3 matrix of predicted positions, where M is num_steps.

    % Number of observations
    num_observations = size(positions, 1);

    % State vector: [x; y; z; vx; vy; vz; ax; ay; az]
    % Initial position (first non-NaN observation)
    valid_idx = find(~any(isnan(positions), 2), 1);
    if isempty(valid_idx)
        error('All position data are NaN.');
    end
    initial_position = positions(valid_idx, :)';

    % Initial velocity and acceleration (assumed to be zero)
    initial_velocity = zeros(3, 1);
    initial_acceleration = zeros(3, 1);

    % Initial state vector
    x = [initial_position; initial_velocity; initial_acceleration];

    % State transition matrix (F)
    F = [eye(3), delta_t * eye(3), 0.5 * delta_t^2 * eye(3);
         zeros(3), eye(3), delta_t * eye(3);
         zeros(3), zeros(3), eye(3)];

    % Observation matrix (H) - we only observe positions
    H = [eye(3), zeros(3, 6)];

    % Process noise covariance (Q)
    q = 0.01; % Process noise scalar
    G = [0.5 * delta_t^2 * eye(3); delta_t * eye(3); eye(3)];
    Q = q * (G * G');

    % Measurement noise covariance (R)
    r = 0.1; % Measurement noise scalar
    R = r * eye(3);

    % Initial estimate covariance (P)
    P = eye(9);

    % Iterate over each observation
    for k = 2:num_observations
        % Prediction step
        x = F * x;
        P = F * P * F' + Q;

        % Check if the current position is NaN
        if any(isnan(positions(k, :)))
            % Measurement is missing; skip the update step
            continue;
        else
            % Measurement update
            z = positions(k, :)';
            y = z - H * x; % Innovation
            S = H * P * H' + R; % Innovation covariance
            K = P * H' / S; % Kalman gain

            % Update state estimate and covariance
            x = x + K * y;
            P = (eye(9) - K * H) * P;
        end
    end

    % Predict future positions
    predicted_positions = zeros(num_steps, 3);
    for i = 1:num_steps
        x = F * x;
        predicted_positions(i, :) = x(1:3)';
    end
end
