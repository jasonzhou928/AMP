function markerSegDict = segmentMarkers(markerDict,verbose)
% find 
if nargin < 2
    verbose = true;
end
if verbose
    disp('%%%%%Segmenting Marker non-NaN Indexses%%%%%')
end

markerStructnames = keys(markerDict);
markerSet = markerStructnames;
markerSeglocs = cell(size(markerSet));

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    markerData = markerDict({currentMarker});
    markerData = markerData{:};
    occupied = ~isnan(markerData(:,2));
    transitions = diff([false; occupied; false]);
    starts = find(transitions == 1);
    ends = find(transitions == -1) - 1;
    markerSeglocs{mm} = reshape([starts, ends].', [], 1);
end
markerSegDict = dictionary(markerSet,markerSeglocs);
end