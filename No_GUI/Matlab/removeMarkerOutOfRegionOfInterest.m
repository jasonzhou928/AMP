function markerStruct = removeMarkerOutOfRegionOfInterest(markerStruct,upperX,lowerX,upperZ,lowerZ)
%%% Treadmill - upperX:840.7, lowerX:279.4
%%% Stairs - upperX:
    disp('%%%%%Remove the markers outside of interest%%%%%')
    
    markerSet = fieldnames(markerStruct);
    for mm = 1:length(markerSet)
        currentMarker = markerSet{mm};
        if ~isnan(lowerX)
            removeIdx = find(markerStruct.(currentMarker).x < lowerX);
            markerStruct.(currentMarker).x(removeIdx) = nan;
            markerStruct.(currentMarker).y(removeIdx) = nan;
            markerStruct.(currentMarker).z(removeIdx) = nan;
        end

        if ~isnan(upperX)
            removeIdx = find(markerStruct.(currentMarker).x > upperX);
            markerStruct.(currentMarker).x(removeIdx) = nan;
            markerStruct.(currentMarker).y(removeIdx) = nan;
            markerStruct.(currentMarker).z(removeIdx) = nan;
        end

        if ~isnan(lowerZ)
            removeIdx = find(markerStruct.(currentMarker).z < lowerZ);
            markerStruct.(currentMarker).x(removeIdx) = nan;
            markerStruct.(currentMarker).y(removeIdx) = nan;
            markerStruct.(currentMarker).z(removeIdx) = nan;
        end

        if ~isnan(upperZ)
            removeIdx = find(markerStruct.(currentMarker).z > upperZ);
            markerStruct.(currentMarker).x(removeIdx) = nan;
            markerStruct.(currentMarker).y(removeIdx) = nan;
            markerStruct.(currentMarker).z(removeIdx) = nan;
        end
    end
end