function markerSeglocs = segmentSingleMarker(markerDict,markerNames)
% find 
markerSet = markerNames;
markerSeglocs = cell(size(markerSet));

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    
    if ~isKey(markerDict,{currentMarker})
        continue
    end
    markerData = markerDict({currentMarker});
    markerData = markerData{:};
    occupied = ~isnan(markerData(:,2));
    transitions = diff([false; occupied; false]);
    starts = find(transitions == 1);
    ends = find(transitions == -1) - 1;
    markerSeglocs{mm} = reshape([starts, ends].', [], 1);
end

end