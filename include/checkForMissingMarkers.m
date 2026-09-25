function checkForMissingMarkers(markerStruct, markerSet)

missingFrames = Vicon.findGaps(markerStruct); % find missing frames
for mm = 1:length(markerSet)
    currentMarker = markerSet{mm};
    if isempty(missingFrames.(currentMarker))==0 && contains(currentMarker,'C_')==0
        disp(['    MISSING:',currentMarker])
    end
end

end