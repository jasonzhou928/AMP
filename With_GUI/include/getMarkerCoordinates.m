function coordinate = getMarkerCoordinates(markerDict,markerName,frameNums)
if isKey(markerDict,{markerName})
    coordinate = markerDict({markerName});
    coordinate = coordinate{:};
    coordinate = [coordinate(frameNums,2)'; coordinate(frameNums,3)'; coordinate(frameNums,4)'];
else
    coordinate = [NaN;NaN;NaN];
end