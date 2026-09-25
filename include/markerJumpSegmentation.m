function [markerDict,markerSegFlag] = markerJumpSegmentation(markerSet,markerSegDict,markerDict,GoodFrames,GoodFrames2,verbose)
if verbose
disp('%%%%%Segmenting Markers -- Generating Pseudo Markers%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
startFrameOffset = Frames(1,1);
totalFrames = size(Frames,1);

markerSet = markerStructnames;
markerSet = markerSet(~contains(markerSet,'C_'));

markerJumplocs = {};
markerJumpSet = {};
markerSegFlag = 0;

reverseStr = '';

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if verbose
    msg = sprintf('Processed Markers %d/%d\nGenerated Markers: %d \n', mm, length(markerSet),length(markerStructnames));
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    if contains(currentMarker,'C_')
        continue
    end

    % if contains(currentMarker,'RFIN2')
    %     disp('here')
    % end
    markerSegs = markerSegDict({currentMarker});
    markerSegs = markerSegs{:};
    
    data = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    for bb = 1:length(markerSegs)/2
        %%% find marker jumps within each segment using nearest neighbors
        segStart = markerSegs(bb*2-1);
        segEnd = markerSegs(bb*2);
        dataRange = data(segStart:segEnd,:);
        dataRangeAxis = diff(dataRange);
        % plot3(dataRange(:,1),dataRange(:,2),dataRange(:,3),'o-')
        
        markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
        if segEnd == segStart
            %%% Assume first labeled frame is always correct
            try
                GoodFrameLocs = GoodFrames2({currentMarker});
                GoodFrameLocs = GoodFrameLocs{:};
            catch 
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
                markerSegFlag = 1;
                continue
            end
            
            if all(~ismember(markerSet,currentMarker)) || ~any(ismember(GoodFrames,segStart:segEnd)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,segStart:segEnd))))
%                 markerStruct = assignCurrentMarker(currentMarker,markerStruct,data,segStart,segEnd);
%             else
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
                markerSegFlag = 1;
            end
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
                try
                    GoodFrameLocs = GoodFrames2({currentMarker});
                    GoodFrameLocs = GoodFrameLocs{:};
                catch 
                    markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,starting,ending);
                    markerSegFlag = 1;
                    continue
                end
                if all(~ismember(markerSet,currentMarker)) || ~any(ismember(GoodFrames,starting:ending)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,starting:ending))))
                    markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,starting,ending);
                    markerSegFlag = 1;
                end
            end
        elseif all(markerSpeedIncrement > 25)
            jumpSegs = segStart:segEnd;
            for ii = 1:length(jumpSegs)
                jumpSeg = jumpSegs(ii);
                try
                    GoodFrameLocs = GoodFrames2({currentMarker});
                    GoodFrameLocs = GoodFrameLocs{:};
                catch 
                    markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,jumpSeg,jumpSeg);
                    markerSegFlag = 1;
                    continue
                end
                if all(~ismember(markerSet,currentMarker)) || ~any(ismember(GoodFrames,jumpSeg:jumpSeg)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,jumpSeg:jumpSeg))))
                    markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,jumpSeg,jumpSeg);
                end
            end
        else
            try
                GoodFrameLocs = GoodFrames2({currentMarker});
                GoodFrameLocs = GoodFrameLocs{:};
            catch 
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
                markerSegFlag = 1;
                continue
            end
            if all(~ismember(markerSet,currentMarker)) || ~any(ismember(GoodFrames,segStart:segEnd)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,segStart:segEnd))))
                markerDict = assignFakeID(currentMarker,markerDict,markerSet,data,segStart,segEnd);
                markerSegFlag = 1;
            end
        end
    end
    currentMarkerCoord = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    if ~any(~isnan(currentMarkerCoord(:,1))) && ~ismember(currentMarker,markerSet)
        markerDict({currentMarker}) = [];
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