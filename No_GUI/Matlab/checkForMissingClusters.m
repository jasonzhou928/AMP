function [missingFlag,missingClusters] = checkForMissingClusters(markerStruct, clusters)
missingFlag = 0;
missingClusters = {};
for mm = 1:length(clusters)
    currentCluster = clusters{mm};
    missingCount = 0;
    for nn = 1:length(currentCluster)
        currentMarker = currentCluster{nn};
        if ~isfield(markerStruct,currentMarker) || all(isnan(markerStruct.(currentMarker).x))
            missingCount = missingCount + 1;
        end
    end
    if missingCount == length(currentCluster) || (length(currentCluster) > 4 && length(currentCluster) - missingCount <= 2)
        missingFlag = 1;
        missingCluster = currentCluster;
        missingClusters{end + 1,1} = missingCluster;
    end
end

end
