function [markerStructCombined, distStruct] = combineTrialsSegments(markerStruct)

markerStructCombined = struct();

SegNums = fieldnames(markerStruct);
SegNums = SegNums{1};

distStruct = struct(markerStruct);

markerNames = fieldnames(markerStruct.(SegNums));
usefulMarkers = markerNames(~contains(markerNames,'C_'));
numUseful = length(usefulMarkers);

SegNums = fieldnames(markerStruct);

for j = 1:length(SegNums)
    SegName = SegNums{j};
    markerStructSeg = markerStruct.(SegName);

    for i = 1:numUseful
        markerName = usefulMarkers{i};
        % currMarker = markerStructSeg.()

        % lastMarkerCombined = markerStructSeg.(markerName)(end,:);

        if ~isfield(markerStructCombined,markerName)
            markerStructCombined.(markerName) = markerStructSeg.(markerName);

        else
            lastMarkerCombined = getNOTnanMarker(markerStructCombined.(markerName), -1);

            distArray = realmax .* ones(max(size(usefulMarkers)), 1);
            if j ~= 1
                for k = 1:numUseful                 
                    addMarker = getNOTnanMarker(markerStructSeg.(usefulMarkers{k}), 1);
                    distArray(k) = getMarkerDistance(lastMarkerCombined, addMarker);
                end
            end
            if i == 1
                distStruct.(SegName) = distArray';
            else
                distStruct.(SegName) = [distStruct.(SegName); distArray'];
            end
        end
    end
    
    if j ~= 1
        distCurrSeg = distStruct.(SegName);

        assignedComb = false(1, numUseful); % Markers already matched in segment 1
        assignedSeg = false(1, numUseful); % Markers already matched in segment 2

        % Flatten distance matrix with indices for sorting
        [distList, indList] = sort(distCurrSeg(:));
        [rowIndices, colIndices] = ind2sub(size(distCurrSeg), indList);
        
        % Perform greedy matching
        matchCount = 0;
        
        for h = 1:length(distList)
            m = rowIndices(h); % Marker index in segment 1
            n = colIndices(h); % Marker index in segment 2
            
            % Check if markers are already matched
            if ~assignedComb(m) && ~assignedSeg(n)
                matchCount = matchCount + 1;
                
                markerStructCombined.(usefulMarkers{m}) = vertcat(markerStructCombined.(usefulMarkers{m}), markerStructSeg.(usefulMarkers{n}));
                assignedComb(m) = true;
                assignedSeg(n) = true;
            end
            
            % Break if all markers are matched
            if matchCount == numUseful
                break;
            end
        end
    end
end

end

% function [markerStructCombined, distStruct] = combineTrialsSegments(markerStruct, firstInstanceStruct)
% 
% markerStructCombined = struct();
% distStruct = struct(markerStruct);
% 
% SegNums = fieldnames(markerStruct);
% SegNums = SegNums{1};
% 
% markerNames = fieldnames(markerStruct.(SegNums));
% usefulMarkers = markerNames(~contains(markerNames,'C_'));
% 
% SegNums = fieldnames(markerStruct);
% falses = false(max(size(usefulMarkers)), 1);
% 
% for j = 1:length(SegNums)
%     SegName = SegNums{j};
%     markerStructSeg = markerStruct.(SegName);
% 
%     segFlagStruct = cell2struct(num2cell(falses), usefulMarkers);
% 
%     for i = 1:length(usefulMarkers)
%         markerName = usefulMarkers{i};
%         % currMarker = markerStructSeg.()
% 
%         % lastMarkerCombined = markerStructSeg.(markerName)(end,:);
% 
%         if ~isfield(markerStructCombined,markerName)
%             markerStructCombined.(markerName) = markerStructSeg.(markerName);
% 
%         else
%             lastMarkerCombined = getNOTnanMarker(markerStructCombined.(markerName), -1);
% 
%             distArray = realmax .* ones(max(size(usefulMarkers)), 1);
%             if j ~= 1
%                 for k = 1:length(usefulMarkers)                        
%                     if ~segFlagStruct.(usefulMarkers{k})
%                         addMarker = getNOTnanMarker(markerStructSeg.(usefulMarkers{k}), 1);
%                         distArray(k) = getMarkerDistance(lastMarkerCombined, addMarker);
%                     end
%                 end
%             end
%             distStruct.(SegName).(markerName) = cell2struct(num2cell(distArray'), usefulMarkers);
% 
%             [~, minI] = min(distArray);
%             segmentMinHeader = markerStructSeg.(markerName).Header(1);
%             % markerFlagCheck = segFlagStruct.(markerNames{minI});
% 
%             % if(all(isnan(minI)))
%             if(isnan(all(markerStructCombined.(markerName).x)) || all(isnan(minI)) || firstInstanceStruct.(markerName) > segmentMinHeader)
%                 markerStructCombined.(markerName) = vertcat(markerStructCombined.(markerName), markerStructSeg.(markerName));
%                 % fprintf('%s: in seg %d\n', markerName, j);
%             else
%                 markerStructCombined.(markerName) = vertcat(markerStructCombined.(markerName), markerStructSeg.(markerNames{minI}));
%                 % Did NOT work: % markerStructCombined.(markerNames{minI}) = vertcat(markerStructCombined.(markerNames{minI}), markerStructSeg.(markerName));
%                 segFlagStruct.(markerNames{minI}) = true;
%             end
%         end
%     end
% end
% 
% end