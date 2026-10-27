function NaNFlag = getIfMarkerCoordinateNaN(markerDict,markerName,frameNums)

coordinate = markerDict({markerName});
coordinate = coordinate{:};
if any(isnan(coordinate(frameNums,:)))
    NaNFlag = 1;
else
    NaNFlag = 0;
end

end