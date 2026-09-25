function [markerJumplocs,markerJumpSet] = checkForGapMarkers(markerSet,markerStruct,markerJumpThresholdSet,jumpThresholdList)
% find 
markerJumplocs = {};
markerJumpSet = {};
% jumpThreshold = 15;

markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
%     currentMarker = 'LDTIB';
    jumpMarkerIdx = strcmp(markerJumpThresholdSet,currentMarker);
    jumpThreshold = jumpThresholdList{jumpMarkerIdx};
    jumpThreshold = jumpThreshold(1);
    if ~isfield(markerStruct,currentMarker)
        continue
    end
    noNaNIdxs = find(~isnan(markerStruct.(currentMarker).x));
    if ~isempty(noNaNIdxs)
        noNaNStarts = noNaNIdxs(find(diff(noNaNIdxs) > 1)+1);
        noNaNStarts = [noNaNIdxs(1);noNaNStarts];
    else
        noNaNStarts = [];
    end

    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];

    dataFilled = fillmissing(data,'previous');
    dataNext = dataFilled(2:end,:);
    data = dataFilled(1:end-1,:);
    markerIncrements = ((sum((dataNext-data).^2,2)).^0.5);

    if sum(markerIncrements>jumpThreshold)>0 || any(isnan(markerStruct.(currentMarker).x))
        loc = find(markerIncrements>jumpThreshold) + 1;
        locsBefore = [];
        for ii = 1:length(loc)
            locBefore = noNaNIdxs(noNaNIdxs < loc(ii));
            locsBefore = [locsBefore;locBefore(end)];
        end
        locOffset = loc + startFrameOffset - 1;
%         disp(['    LARGE MARKER GAP: ',currentMarker,' at frames: ', num2str(locOffset')])
        markerJumpSet = [markerJumpSet(:)',{currentMarker}];
        loc = sort(unique([locsBefore;loc;noNaNStarts]));
        markerJumplocs = [markerJumplocs(:)',{loc}];
    end
end

end