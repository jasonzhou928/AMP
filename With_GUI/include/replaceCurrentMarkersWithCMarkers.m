function markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_data_range)

cmp_data_range_cord = getMarkerCoordinates(markerDict,cmp_marker,cmp_data_range)';
if isKey(markerDict,{currentMarker})
    currentMarkerCord = markerDict({currentMarker});
else
    currentMarkerCord = markerDict({cmp_marker});
    markerDict({currentMarker}) = currentMarkerCord;     
end
currentMarkerCord = currentMarkerCord{:};
currentMarkerCord(cmp_data_range,2) = cmp_data_range_cord(:,1);
currentMarkerCord(cmp_data_range,3) = cmp_data_range_cord(:,2);
currentMarkerCord(cmp_data_range,4) = cmp_data_range_cord(:,3);

markerDict({currentMarker}) = {currentMarkerCord};                            
end