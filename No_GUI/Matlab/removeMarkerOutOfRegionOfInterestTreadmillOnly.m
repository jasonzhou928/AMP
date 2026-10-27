function markerStruct = removeMarkerOutOfRegionOfInterestTreadmillOnly(markerStruct,upperX,lowerX)
    disp('%%%%%Remove the markers outside of interest%%%%%')
    markerStructname = fieldnames(markerStruct);
    markerStructname = markerStructname{1};
    startFrameOffset = markerStruct.(markerStructname).Header(1);
    totalFrames = length(markerStruct.(markerStructname).Header);
    markerSet = fieldnames(markerStruct);
    for mm = 1:length(markerSet)
        currentMarker = markerSet{mm};
        removeIdx = find(markerStruct.(currentMarker).x < lowerX);
        markerStruct.(currentMarker).x(removeIdx) = nan;
        markerStruct.(currentMarker).y(removeIdx) = nan;
        markerStruct.(currentMarker).z(removeIdx) = nan;
        removeIdx = find(markerStruct.(currentMarker).x > upperX);
        markerStruct.(currentMarker).x(removeIdx) = nan;
        markerStruct.(currentMarker).y(removeIdx) = nan;
        markerStruct.(currentMarker).z(removeIdx) = nan;
    end
end