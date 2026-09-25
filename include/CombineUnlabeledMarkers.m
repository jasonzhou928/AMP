function markerDict = CombineUnlabeledMarkers(markerDict,verbose)
if verbose
disp('%%%%%Combining Unlabeled Markers%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

markerSet = markerStructnames;
markerSet = markerSet(contains(markerSet,'C_'));

markerStructnameNum = length(markerStructnames);
if verbose
disp(['Total Markers Before Combining: ',num2str(markerStructnameNum)])
end

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if ~isKey(markerDict,{currentMarker})
        continue
    end

    markerStructname = keys(markerDict);
    current_temp_names=markerStructname(contains(markerStructname,'C_'));
    current_temp_names = setdiff(current_temp_names,currentMarker);

    for jj = 1:length(current_temp_names)
        cmp_marker = current_temp_names{jj};
        cmpX = getMarkerCoordinates(markerDict,cmp_marker,1:totalFrames)';
        cmp_noNaNIdxs = find(~isnan(cmpX(:,1)));
        currentX = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
        hasIntersection = any(~isnan(cmpX(:,1)) & ~isnan(currentX(:,1)));
        if ~hasIntersection
            markerDict = replaceCurrentMarkersWithCMarkers(markerDict,currentMarker,cmp_marker,cmp_noNaNIdxs);
            markerDict({cmp_marker}) = [];
        end
    end


end

markerStructname = keys(markerDict);
markerStructnameNum = length(markerStructname);
if verbose
disp(['Total Markers After Combining: ',num2str(markerStructnameNum)])
end