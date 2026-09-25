function markerSeglocs = segmentSingleMarker(markerDict,markerNames)
% find 
markerSeglocs = {};

markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

markerSet = markerNames;

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    cord = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames);
    noNaNIdxs = find(~isnan(cord(1,:)))';
    if ~isempty(noNaNIdxs)
        noNaNStarts = noNaNIdxs(find(diff(noNaNIdxs) > 1)+1);
        noNaNStarts = [noNaNIdxs(1);noNaNStarts];
    else
        noNaNStarts = [];
    end

    NanIdxs = find(isnan(cord(1,:)))';
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
    markerSeglocs = [markerSeglocs(:)',{noNaNSegments}];
end

end