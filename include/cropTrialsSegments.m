function  markerStructLists = cropTrialsSegments(markerStruct,markerSet,cropLength)
% To crop the trials to small ones and later combine them together

markerStructLists = struct();

tempMarker = fieldnames(markerStruct);
tempMarker = tempMarker{1};
markerHeader = markerStruct.(tempMarker).Header;
totalLength = length(markerHeader);
markerTableTemp = markerStruct.(tempMarker);

numSegments = ceil(totalLength/cropLength);

for i = 1:numSegments
    i_start = (i-1)*cropLength+1;
    if i ~= numSegments
        i_end = i*cropLength;
    else
        i_end = totalLength;
    end

    SegName = ['Seg_',num2str(i)];
    markerStructLists.(SegName) = markerStruct;
    markerNames = fieldnames(markerStructLists.(SegName));
    markerNamesDiff = setdiff(markerSet,markerNames);
    markerNamesAll = [markerNames;markerNamesDiff'];

    for j = 1:length(markerNamesAll)
        markerName = markerNamesAll{j};
        if any(strcmp(markerNames,markerName))
            markerTable = markerStructLists.(SegName).(markerName);
            markerTable = markerTable(i_start:i_end,:);
            markerStructLists.(SegName).(markerName) = markerTable;
        else
            markerTable = markerTableTemp;
            markerTable = markerTable(i_start:i_end,:);
            markerTable.x = nan(height(markerTable), 1);
            markerTable.y = nan(height(markerTable), 1);
            markerTable.z = nan(height(markerTable), 1);
            markerStructLists.(SegName).(markerName) = markerTable;
        end
    end
end




end