function [markerSeglocs,markerSegSet] = segmentOneMarker(markerStruct,markerName)
% find 
% disp('%%%%%Segmenting Marker non-NaN Indexses%%%%%')
markerSeglocs = {};
markerSegSet = {};

markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
totalFrames = length(markerStruct.(markerStructname).Header);

currentMarker = markerName;

noNaNIdxs = find(~isnan(markerStruct.(currentMarker).x));
if ~isempty(noNaNIdxs)
    noNaNStarts = noNaNIdxs(find(diff(noNaNIdxs) > 1)+1);
    noNaNStarts = [noNaNIdxs(1);noNaNStarts];
else
    noNaNStarts = [];
end

NanIdxs = find(isnan(markerStruct.(currentMarker).x));
noNaNEnds = [];
if ~isempty(NanIdxs)
    for nn = 1:length(noNaNStarts)
        NaNStart = find(NanIdxs > noNaNStarts(nn));
        if isempty(NaNStart) && nn == length(noNaNStarts)
            noNaNEnds = [noNaNEnds;noNaNIdxs(end)];
        else
            noNaNEnds = [noNaNEnds;NanIdxs(NaNStart(1))-1];
        end
    end
else
    noNaNEnds = totalFrames;
end

noNaNSegments = sort(vertcat(noNaNStarts,noNaNEnds));
if mod(length(noNaNSegments),2)
    error('Segmentation Fault')
end
markerSegSet = [markerSegSet(:)',{currentMarker}];
markerSeglocs = [markerSeglocs(:)',{noNaNSegments}];

end