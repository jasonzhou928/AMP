function missing = checkForMissingMarkers(markerStruct, markerSet,verbose)
missing = 0;
missingFrames = Vicon.findGaps(markerStruct); % find missing frames
for mm = 1:length(markerSet)
    currentMarker = markerSet{mm};
    if isempty(missingFrames.(currentMarker))==0 && contains(currentMarker,'C_')==0
        if verbose
        disp(['    MISSING:',currentMarker])
        end
        missing = 1;
    end
end

end