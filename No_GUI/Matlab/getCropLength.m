function cropLength = getCropLength(markerDict)
% find max crop length

markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);


markerSet = markerStructnames(~contains(markerStructnames,'C_'));

NaNLengthLists = zeros(length(markerSet),1);

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    cord = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames);
    
    D = diff([false,isnan(cord(1,:)),false]);
    if all(D==0)
        L = 0;
    else
        L = find(D<0)-find(D>0);
    end
    NaNLengthLists(mm) = max(L);
end
cropLength = max(NaNLengthLists)+1;
if cropLength <= 50
    cropLength = 51;
end
end