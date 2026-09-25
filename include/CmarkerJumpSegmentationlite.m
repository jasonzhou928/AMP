function markerStruct = CmarkerJumpSegmentationlite(markerStruct)
disp('%%%%%Segmenting CMarkers -- Generating Pseudo Markers%%%%%')
markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

markerJumplocs = {};
markerJumpSet = {};

markerSet = fieldnames(markerStruct);
[markerSeglocs,markerSegSet] = segmentMarkers(markerStruct);
markerSet = markerSet(contains(markerSet,'C_'));

reverseStr = '';

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    msg = sprintf('Processed C Markers %d/%d\nGenerated Markers: %d \n', mm, length(markerSet),length(fieldnames(markerStruct)));
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    
    markerSegs = markerSeglocs{contains(markerSegSet,currentMarker)};

    data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];

    for bb = 1:length(markerSegs)/2
        %%% find marker jumps within each segment using nearest neighbors
        segStart = markerSegs(bb*2-1);
        segEnd = markerSegs(bb*2);
        dataRange = data(segStart:segEnd,:);
%         if segStart == 5292
%             disp('here')
%         end

        % plot3(dataRange(:,1),dataRange(:,2),dataRange(:,3),'o-')
        
        markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
        if segEnd == segStart
            markerStruct = assignFakeID(currentMarker,markerStruct,markerSet,data,segStart,segEnd);
        elseif any(abs(diff(markerSpeedIncrement)) > 10) && any(markerSpeedIncrement > 20) && length(markerSpeedIncrement) > 1
            JumpPosLoc = find(markerSpeedIncrement' > 20);
            jumpLoc = [];
            for cc = 1:length(JumpPosLoc)
                loc = JumpPosLoc(cc);
                speedcheck = [markerSpeedIncrement(1),markerSpeedIncrement',markerSpeedIncrement(end)];
                velDiff = abs(diff(speedcheck(loc:end)));
                if any(velDiff > 10)
                    jumpLoc = [jumpLoc,loc];
                end
            end
            jumpLoc = jumpLoc + segStart;
            jumpLocs = sort([segStart,jumpLoc-1,jumpLoc,segEnd]);
            for ii = 1:length(jumpLocs)/2
                starting = jumpLocs(ii*2-1);
                ending = jumpLocs(ii*2);
                markerStruct = assignFakeID(currentMarker,markerStruct,markerSet,data,starting,ending);
            end
        else
            markerStruct = assignFakeID(currentMarker,markerStruct,markerSet,data,segStart,segEnd);
        end
    end
    if ~any(~isnan(markerStruct.(currentMarker).x))
        markerStruct = rmfield(markerStruct,currentMarker);
    end
end
totalMarkers = length(fieldnames(markerStruct));
disp(['  Generated in total of ',num2str(totalMarkers),' Markers']);
end

function markerStruct = assignFakeID(currentMarker,markerStruct,markerSet,data,segStart,segEnd)
    dataRange = data(segStart:segEnd,:);
    markerID = length(fieldnames(markerStruct));
    fakeID = ['C_' num2str(markerID)];
    while any(strcmp(fieldnames(markerStruct),fakeID)) || any(strcmp(markerSet,fakeID))
        markerID = markerID + 1;
        fakeID = ['C_' num2str(markerID)];
    end

    markerStruct.(fakeID).x(1:segEnd-segStart+1) = dataRange(:,1);
    markerStruct.(fakeID).y(1:segEnd-segStart+1) = dataRange(:,2);
    markerStruct.(fakeID).z(1:segEnd-segStart+1) = dataRange(:,3);
    markerStruct.(fakeID).Header(1:segEnd-segStart+1) = segStart:segEnd;
    markerStruct.(currentMarker).x(segStart:segEnd) = NaN;
    markerStruct.(currentMarker).y(segStart:segEnd) = NaN;
    markerStruct.(currentMarker).z(segStart:segEnd) = NaN;
end
