function [markerStruct, filled] = Rigid_Body_Fill_All_Gaps(allMarkerNames, markerStruct,clusters, varargin)
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
filled = 0;

missingFrames = Vicon.findGaps(markerStruct); % find all missing frames in data
for mm = 1:length(allMarkerNames) % loop through all markers
    currentMarker = allMarkerNames{mm}; % define current marker
    if isempty(missingFrames.(currentMarker)) == 0 % if there are missing markers
        
        if plotResults == 1
            figure; hold on;
            plot(markerStruct.(currentMarker).Header, markerStruct.(currentMarker).x, 'ro')
        end
        
        %Find other markers to drive the fix
        for ii = 1:length(clusters) % look at all of the defined clusters
            foundFlag = 0;
            if any(strcmp(clusters{ii},currentMarker)) % if the cluster contains the marker that we're currently looking at
                currentCluster = clusters{ii}; % keep that cluster
                idx = strcmp(currentCluster,currentMarker); % find where current marker is in cluster
                currentCluster(idx) = []; % delete current marker from cluster
                foundFlag = 1;
                % May need to add functionality if there aren't enough
                % markers in the cluster
            end
        
            if foundFlag
                [a,~] = size(missingFrames.(currentMarker)); % define the number of gaps
                for ii = 1:a
                    startFrame = missingFrames.(currentMarker)(ii,1); % start frame of gap
                    endFrame = missingFrames.(currentMarker)(ii,2); % end frame of gap
                    try
                        markerStruct = Vicon.RigidBodyFill(markerStruct, currentMarker, currentCluster, startFrame, endFrame); % fill the gap
                        disp(['RigidBody Gap Filling:',currentMarker,' starting at frame: ', num2str(startFrame),'-', num2str(endFrame)])
                        filled = 1;
                    catch
                        if endFrame - startFrame <= 10
                            try
                                [markerStruct, unfilled] = Vicon.SplineFill(markerStruct,currentMarker,startFrame,endFrame,'MaxError',30);
                                if ~unfilled
                                    disp(['Spline Gap Filling:',currentMarker,' starting at frame: ', num2str(startFrame),'-', num2str(endFrame)])
                                    filled = 1;
                                    continue
                                end
                            catch
                                warning('Spline Fill Failed. Please Manually Check. Skipped For now')
                            end
                        end
                        if endFrame - startFrame <= 30 && endFrame - startFrame > 10
                            try
                                markerStruct = Vicon.PatternFill(markerStruct,currentMarker,currentCluster, startFrame, endFrame);
                                disp(['Pattern Gap Filling:',currentMarker,' starting at frame: ', num2str(startFrame),'-', num2str(endFrame)])
                                filled = 1;
                                continue
                            catch
                                warning('Pattern Fill Failed. Please Manually Check. Skipped For now')
                            end
                        end
                        if endFrame - startFrame <= 3
                            try
                                markerStruct = Vicon.LinearFill(markerStruct,currentMarker,startFrame,endFrame);
                                disp(['Linear Gap Filling:',currentMarker,' starting at frame: ', num2str(startFrame),'-', num2str(endFrame)])
                                filled = 1;
                                continue
                            catch
                                warning('Linear Fill Failed. Please Manually Check. Skipped For now')
                            end
                        end
                        warning('Gap Length is too long. Please Manually Check. Skipped For now')
                        continue

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
            missingFrames = Vicon.findGaps(markerStruct);
            if isempty(missingFrames.(currentMarker))
                break
            end
        end
    end
end
end