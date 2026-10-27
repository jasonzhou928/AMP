function  markerStructLists = cropTrialsSegments(markerStruct,markerSet,cropLength)
% To crop the trials to small ones and later combine them together

markerStructLists = struct();

tempMarker = fieldnames(markerStruct);
tempMarker = tempMarker{1};
markerHeader = markerStruct.(tempMarker).Header;
totalLength = length(markerHeader);
markerTableTemp = markerStruct.(tempMarker);

numSegments = ceil(totalLength/cropLength);
markerNames = fieldnames(markerStruct);
markerNamesDiff = setdiff(markerSet(:),markerNames);
markerNamesAll = [markerNames;markerNamesDiff];
nMarkers = numel(markerNamesAll);
markerExists = ismember(markerNamesAll, markerNames);

for i = 1:numSegments
    i_start = (i-1)*cropLength+1;
    if i ~= numSegments
        i_end = i*cropLength;
    else
        i_end = totalLength;
    end

    SegName = ['Seg_',num2str(i)];
    segmentValues = cell(nMarkers,1);
    for j = 1:nMarkers
        markerName = markerNamesAll{j};
        if markerExists(j)
            segmentValues{j} = markerStruct.(markerName)(i_start:i_end,:);
        else
            markerTable = markerTableTemp(i_start:i_end,:);
            markerTable{:,2:4} = NaN;
            segmentValues{j} = markerTable;
        end
    end
    markerStructLists.(SegName) = cell2struct(segmentValues,markerNamesAll,1);
end




end