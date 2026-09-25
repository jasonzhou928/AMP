function markerStructCombined = combineTrialsSegments(markerStruct)

markerStructCombined = struct();

SegNums = fieldnames(markerStruct);
SegNums = SegNums{1};

markerNames = fieldnames(markerStruct.(SegNums));
usefulMarkers = markerNames(~contains(markerNames,'C_'));

SegNums = fieldnames(markerStruct);

for i = 1:length(usefulMarkers)
    markerName = usefulMarkers{i};
    for j = 1:length(SegNums)
        SegName = SegNums{j};
        markerStructSeg = markerStruct.(SegName);
        if ~isfield(markerStructCombined,markerName)
            markerStructCombined.(markerName) = markerStructSeg.(markerName);
        else
            markerStructCombined.(markerName) = vertcat(markerStructCombined.(markerName),markerStructSeg.(markerName));
        end
    end
end

for si = 1:length(SegNums)
    SegName = SegNums{si};
    markerStructSeg = markerStruct.(SegName);
    markerNames = fieldnames(markerStructSeg);
    CMarkers = markerNames(contains(markerNames,'C_'));
    for i = 1:length(CMarkers)
        markerName = CMarkers{i};

        markerSet = fieldnames(markerStructCombined);
        data = markerStructSeg.(markerName);
        segStart = markerStructSeg.(markerName).Header(1);
        segEnd = markerStructSeg.(markerName).Header(end);
        markerStructCombined = assignFakeID(markerStructCombined,markerSet,data,segStart,segEnd);
    end
end

end


function markerStruct = assignFakeID(markerStruct,markerSet,data,segStart,segEnd)
    dataRange = data;
    markerID = length(fieldnames(markerStruct));
    fakeID = ['C_' num2str(markerID)];
    while any(strcmp(fieldnames(markerStruct),fakeID)) || any(strcmp(markerSet,fakeID))
        markerID = markerID + 1;
        fakeID = ['C_' num2str(markerID)];
    end
    nonCMarker = fieldnames(markerStruct);
    nonCMarker = nonCMarker{1};

    fakeID_arr = markerStruct.(nonCMarker);
    fakeID_arr.x(1:end) = NaN;
    fakeID_arr.y(1:end) = NaN;
    fakeID_arr.z(1:end) = NaN;
    segStart_i = find(fakeID_arr.Header == segStart);
    segEnd_i = find(fakeID_arr.Header == segEnd);
    fakeID_arr.x(segStart_i:segEnd_i) = dataRange.x(:);
    fakeID_arr.y(segStart_i:segEnd_i) = dataRange.y(:);
    fakeID_arr.z(segStart_i:segEnd_i) = dataRange.z(:);
    markerStruct.(fakeID) = fakeID_arr;
end