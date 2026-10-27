function [jumped,frameLoc] = checkJumpUsingNeighborFrames(markerStruct,currentMarker,drop_loc,markerJumpThresholdSet,jumpThresholdList)            
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

jumpMarkerIdx = strcmp(markerJumpThresholdSet,currentMarker);
jumpThreshold = jumpThresholdList{jumpMarkerIdx};
jumpThreshold = jumpThreshold(1);

data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
frameLoc = [];

gap = 3;
if drop_loc+gap > length(data)
    gap = length(data) - drop_loc;
end
if drop_loc-gap <= 0
    gap = drop_loc - 1;
end
dataRange = data(drop_loc-gap:drop_loc+gap,:);
dataRangeFilled = fillmissing(dataRange,'linear');
% plot3(dataRange(:,1),dataRange(:,2),dataRange(:,3),'o-')
markerSpeedIncrement = sum(diff(dataRangeFilled).^2,2).^0.5;


% Assume Collection Rate is always 200Hz
if any(abs(diff(markerSpeedIncrement)) > 10) && any(markerSpeedIncrement > jumpThreshold) && length(markerSpeedIncrement) > 1
%     markerSpeedIncrement(isnan(dataRange(:,1)))=0;
    JumpLoc = transpose(find(markerSpeedIncrement > jumpThreshold));
    Jump1 = find(markerSpeedIncrement > jumpThreshold)-gap;
    Jump2 = find(abs(diff(markerSpeedIncrement)) > 10)-gap+1;
    LocNan = find(isnan(dataRange(:,1))) - gap - 1;
    LocCommon = intersect(Jump1,LocNan);
    Arr3 = setxor(Jump1,LocCommon);
%     jumpedFrame = unique([Jump1;Jump2]);
    frameLoc = drop_loc + Arr3;
%     JumpStart = intersect(Jump1,Jump2);
%     if isempty(JumpStart)
%         jumped = 0;
%         frameLoc = [];
%         return
%     end
%     JumpLoc = JumpLoc(JumpLoc >= JumpStart(1));
%     try
%         if any(diff(JumpLoc) == 1)
%             frameLoc = drop_loc + JumpLoc(1:2:end) - gap;
%         elseif numel(JumpLoc) == 1 && markerSpeedIncrement(JumpLoc+1)<jumpThreshold && ~markerSpeedIncrement(JumpLoc-1)
%             frameLoc = drop_loc + JumpLoc - gap - 1;
%         elseif numel(JumpLoc) == 1 && markerSpeedIncrement(JumpLoc-1)<jumpThreshold && ~markerSpeedIncrement(JumpLoc+1)
%             frameLoc = drop_loc + JumpLoc - gap;
%         else
% %             disp('Could Not Determine, Ignore now')
%         end
%     catch
% %         disp('Could Not Determine, Ignore now')
%     end
end

if numel(frameLoc) >= 1
    jumped = 1;
else
    jumped = 0;
end

end
