function markerDict = CmarkerJumpSegmentation(markerDict,verbose)
if verbose
disp('%%%%%Segmenting CMarkers -- Generating Pseudo Markers%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

markerJumplocs = {};
markerJumpSet = {};

markerSet = keys(markerDict);
markerSet = markerSet(contains(markerSet,'C_'));

reverseStr = '';

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if verbose
    msg = sprintf('Processed C Markers %d/%d\nGenerated Markers: %d \n', mm, length(markerSet),length(markerStructnames));
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    markerSegs = segmentSingleMarker(markerDict,{currentMarker});
    markerSegs = markerSegs{:};

    data = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    for bb = 1:length(markerSegs)/2
        %%% find marker jumps within each segment using nearest neighbors
        segStart = markerSegs(bb*2-1);
        segEnd = markerSegs(bb*2);
        dataRange = data(segStart:segEnd,:);
        dataRangeAxis = diff(dataRange);
        
        markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
        if segEnd == segStart
            markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
        elseif any(abs(diff(markerSpeedIncrement)) > 10) && any(markerSpeedIncrement > 20) && length(markerSpeedIncrement) > 1
            JumpPosLoc = find(markerSpeedIncrement' > 20);
            jumpLoc = [];
            for cc = 1:length(JumpPosLoc)
                loc = JumpPosLoc(cc);
%                 speedcheck = [markerSpeedIncrement(1),markerSpeedIncrement',markerSpeedIncrement(end)];
%                 velDiff = abs(diff(speedcheck(loc:end)));
%                 if any(velDiff > 10)
%                     jumpLoc = [jumpLoc,loc];
%                 end
                speedcheck = [dataRangeAxis(1,:);dataRangeAxis;dataRangeAxis(end,:)];
                velDiff = abs(diff(speedcheck(loc:end,:)));
                if any(velDiff(:) > 10)
                    jumpLoc = [jumpLoc,loc];
                end
            end
            jumpLoc = jumpLoc + segStart;
            jumpLocs = sort([segStart,jumpLoc-1,jumpLoc,segEnd]);
            for ii = 1:length(jumpLocs)/2
                starting = jumpLocs(ii*2-1);
                ending = jumpLocs(ii*2);
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,starting,ending);
            end
        elseif all(markerSpeedIncrement > 25)
            jumpSegs = segStart:segEnd;
            for ii = 1:length(jumpSegs)
                jumpSeg = jumpSegs(ii);
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,jumpSeg,jumpSeg);
            end
        else
            markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
        end
    end
    currentMarkerCoord = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    if ~any(~isnan(currentMarkerCoord(:,1)))
        markerDict({'currentMarker'}) = [];
    end
end
totalMarkers = length(keys(markerDict));
if verbose
disp(['  Generated in total of ',num2str(totalMarkers),' Markers']);
end
end

function markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd)
    dataRange = data(segStart:segEnd,:);
    markerID = length(keys(markerDict));
    fakeID = ['C_' num2str(markerID)];
    while any(strcmp(keys(markerDict),fakeID)) || any(strcmp(markerSet,fakeID))
        markerID = markerID + 1;
        fakeID = ['C_' num2str(markerID)];
    end
    fakeID_arr = markerDict({currentMarker});
    fakeID_arr = fakeID_arr{:};
    fakeID_arr(1:end,2) = NaN;
    fakeID_arr(1:end,3) = NaN;
    fakeID_arr(1:end,4) = NaN;
    fakeID_arr(segStart:segEnd,2) = dataRange(:,1);
    fakeID_arr(segStart:segEnd,3) = dataRange(:,2);
    fakeID_arr(segStart:segEnd,4) = dataRange(:,3);
    markerDict({fakeID}) = {fakeID_arr};

    current_arr = markerDict({currentMarker});
    current_arr = current_arr{:};
    current_arr(segStart:segEnd,2) = NaN;
    current_arr(segStart:segEnd,3) = NaN;
    current_arr(segStart:segEnd,4) = NaN;
    markerDict({currentMarker}) = {current_arr};
end
