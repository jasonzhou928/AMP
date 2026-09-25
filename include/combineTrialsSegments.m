function markerStructCombined = combineTrialsSegments(markerStruct)

SegNums = fieldnames(markerStruct);
nSeg = numel(SegNums);

firstSeg = markerStruct.(SegNums{1});
markerNames = fieldnames(firstSeg);
usefulMarkers = markerNames(~contains(markerNames,'C_'));
nUseful = numel(usefulMarkers);

markerStructCombined = struct();
for i = 1:nUseful
    markerName = usefulMarkers{i};
    parts = cell(nSeg, 1);
    for j = 1:nSeg
        parts{j} = markerStruct.(SegNums{j}).(markerName);
    end
    markerStructCombined.(markerName) = vertcat(parts{:});
end

ref = markerStructCombined.(usefulMarkers{1});
header = ref.Header;
nFrames = height(ref);

headerMin = min(header);
headerMax = max(header);
headerSpan = headerMax - headerMin + 1;
useMap = headerSpan >= 1 && headerSpan <= max(2*nFrames,1024) && ...
    all(header == round(header));
if useMap
    headerIndex = zeros(headerSpan, 1);
    headerIndex(header - headerMin + 1) = (1:nFrames)';
end

capacity = 64;
cX = cell(capacity, 1);
cY = cell(capacity, 1);
cZ = cell(capacity, 1);
cOcc = cell(capacity, 1);
nC = 0;

for si = 1:nSeg
    seg = markerStruct.(SegNums{si});
    segNames = fieldnames(seg);
    CMarkers = segNames(contains(segNames,'C_'));
    for i = 1:numel(CMarkers)
        data = seg.(CMarkers{i});
        valid = ~isnan(data.x);
        if ~any(valid)
            continue
        end
        segHeader = data.Header(valid);
        valsx = data.x(valid);
        valsy = data.y(valid);
        valsz = data.z(valid);
        if useMap
            rows = headerIndex(segHeader - headerMin + 1);
        else
            [~, rows] = ismember(segHeader, header);
        end
        keep = rows > 0;
        if ~any(keep)
            continue
        end
        rows = rows(keep);
        valsx = valsx(keep);
        valsy = valsy(keep);
        valsz = valsz(keep);

        placed = false;
        for k = 1:nC
            if ~any(cOcc{k}(rows))
                cX{k}(rows) = valsx;
                cY{k}(rows) = valsy;
                cZ{k}(rows) = valsz;
                cOcc{k}(rows) = true;
                placed = true;
                break
            end
        end
        if ~placed
            nC = nC + 1;
            if nC > capacity
                capacity = capacity * 2;
                cX{capacity} = [];
                cY{capacity} = [];
                cZ{capacity} = [];
                cOcc{capacity} = [];
            end
            x = nan(nFrames, 1);
            y = nan(nFrames, 1);
            z = nan(nFrames, 1);
            occ = false(nFrames, 1);
            x(rows) = valsx;
            y(rows) = valsy;
            z(rows) = valsz;
            occ(rows) = true;
            cX{nC} = x;
            cY{nC} = y;
            cZ{nC} = z;
            cOcc{nC} = occ;
        end
    end
end

if nC == 0
    return
end

cNames = cell(nC, 1);
cTables = cell(nC, 1);
nextID = nUseful;
for k = 1:nC
    fakeID = sprintf('C_%d', nextID);
    while any(strcmp(usefulMarkers, fakeID))
        nextID = nextID + 1;
        fakeID = sprintf('C_%d', nextID);
    end
    cNames{k} = fakeID;
    nextID = nextID + 1;
    cTables{k} = table(header, cX{k}, cY{k}, cZ{k}, ...
        'VariableNames', {'Header','x','y','z'});
end

allNames = [usefulMarkers; cNames];
allVals = [struct2cell(markerStructCombined); cTables];
markerStructCombined = cell2struct(allVals, allNames, 1);

end
