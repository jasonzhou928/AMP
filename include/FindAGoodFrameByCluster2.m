function [GoodFrames,diffLengths] = FindAGoodFrameByCluster2(markerStruct, markerSet, markerStructRef,clusters,cluster_jump_threshold,GoodFrameRef)
disp('%%%%%Finding Good Segment Frame from Trial%%%%%')
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);
totalFrames = length(markerStruct.(markerStructname).Header);
GoodFrames = [];
diffLengths = [];
diffMax = [0,0];
markerGoodlocs = struct();
reverseStr = '';

for tt = 1:totalFrames
    loc = tt;
    msg = sprintf('Processed Frame %d/%d\n', loc, totalFrames);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    for ccs = 1:length(clusters)
        rigidDiffs = [];
        currentCluster = clusters{ccs};
        jump_threshold = cell2mat(cluster_jump_threshold{ccs});
        
        for mm = 1:length(currentCluster)
            currentMarker = currentCluster{mm};
            if ~isfield(markerGoodlocs,currentMarker)
                noNanLoc = find(~isnan(markerStruct.(currentMarker).x));
                noNanLoc = noNanLoc(1);
                markerGoodlocs.(currentMarker) = noNanLoc;
            end
        end

    end
       
end
if length(fieldnames(markerGoodlocs)) < length(markerSet)
    diffNames = setdiff(markerSet,fieldnames(markerGoodlocs));
    for gg = 1:length(diffNames)
        currentMissingMarker = diffNames{gg};
        noNanLoc = find(~isnan(markerStruct.(currentMissingMarker).x));
        noNanLoc = noNanLoc(1);
        markerGoodlocs.(currentMissingMarker) = noNanLoc;
    end
end
GoodFrames = markerGoodlocs;

% if isempty(GoodFrames)
%     disp('No Frame Found with Segment Markers')
% else
%     disp('Found Frame with Segment Markers')
% end

end