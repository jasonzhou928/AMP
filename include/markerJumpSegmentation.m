function [markerDict,markerSegFlag] = markerJumpSegmentation(WBAM_Markerset,markerSegDict,markerDict,GoodFrames,GoodFrames2,verbose)
if nargin < 6
    verbose = true;
end
if verbose
    disp('%%%%%Segmenting Markers -- Generating Pseudo Markers%%%%%')
end
markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
totalFrames = size(Frames,1);

markerSet = markerStructnames(~contains(markerStructnames,'C_'));
markerSegFlag = 0;

reverseStr = '';
nextMarkerID = length(markerStructnames);
usedNames = markerStructnames;

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    
    if verbose
        msg = sprintf('Processed Markers %d/%d\nGenerated Markers: %d \n', mm, length(markerSet),length(markerStructnames));
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    
    % if contains(currentMarker,'RFIN2')
    %     disp('here')
    % end
    markerSegs = markerSegDict({currentMarker});
    markerSegs = markerSegs{:};
    
    data = getMarkerCoordinates(markerDict,currentMarker,1:totalFrames)';
    fragmentRanges = zeros(0,2);
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
                fragmentRanges(end+1,:) = [segStart,segEnd];
                markerSegFlag = 1;
                continue
            end
            
            if all(~ismember(WBAM_Markerset,currentMarker)) || ~any(ismember(GoodFrames,segStart:segEnd)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,segStart:segEnd))))
%                 markerStruct = assignCurrentMarker(currentMarker,markerStruct,data,segStart,segEnd);
%             else
                fragmentRanges(end+1,:) = [segStart,segEnd];
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
                    fragmentRanges(end+1,:) = [starting,ending];
                    markerSegFlag = 1;
                    continue
                end
                if all(~ismember(WBAM_Markerset,currentMarker)) || ~any(ismember(GoodFrames,starting:ending)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,starting:ending))))
                    fragmentRanges(end+1,:) = [starting,ending];
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
                    fragmentRanges(end+1,:) = [jumpSeg,jumpSeg];
                    markerSegFlag = 1;
                    continue
                end
                if all(~ismember(WBAM_Markerset,currentMarker)) || ~any(ismember(GoodFrames,jumpSeg:jumpSeg)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,jumpSeg:jumpSeg))))
                    fragmentRanges(end+1,:) = [jumpSeg,jumpSeg];
                    markerSegFlag = 1;
                end
            end
        else
            try
                GoodFrameLocs = GoodFrames2({currentMarker});
                GoodFrameLocs = GoodFrameLocs{:};
            catch 
                fragmentRanges(end+1,:) = [segStart,segEnd];
                markerSegFlag = 1;
                continue
            end
            if all(~ismember(WBAM_Markerset,currentMarker)) || ~any(ismember(GoodFrames,segStart:segEnd)) && (~isKey(GoodFrames2,{currentMarker}) || (isKey(GoodFrames2,{currentMarker}) && ~any(ismember(GoodFrameLocs,segStart:segEnd))))
                fragmentRanges(end+1,:) = [segStart,segEnd];
                markerSegFlag = 1;
            end
        end
    end
    
    nFragments = size(fragmentRanges,1);
    if nFragments > 0
        source = markerDict({currentMarker});
        source = source{:};
        emptyMarker = source;
        emptyMarker(:,2:4) = NaN;
        fragmentNames = cell(nFragments,1);
        fragmentValues = cell(nFragments,1);
        removeRows = false(totalFrames,1);
        for ii = 1:nFragments
            while true
                fakeID = ['C_' num2str(nextMarkerID)];
                nextMarkerID = nextMarkerID + 1;
                if ~any(strcmp(usedNames,fakeID))
                    break
                end
            end
            usedNames{end+1} = fakeID;
            fragmentNames{ii} = fakeID;
            starting = fragmentRanges(ii,1);
            ending = fragmentRanges(ii,2);
            fragment = emptyMarker;
            fragment(starting:ending,2:4) = data(starting:ending,:);
            fragmentValues{ii} = fragment;
            removeRows(starting:ending) = true;
        end
        markerDict(fragmentNames) = fragmentValues;
        source(removeRows,2:4) = NaN;
        if ~any(~isnan(source(:,2))) && ~ismember(currentMarker,WBAM_Markerset)
            markerDict({currentMarker}) = [];
        else
            markerDict({currentMarker}) = {source};
        end
    elseif ~ismember(currentMarker,WBAM_Markerset)
        source = markerDict({currentMarker});
        source = source{:};
        if ~any(~isnan(source(:,2)))
            markerDict({currentMarker}) = [];
        end
    end
end
totalMarkers = length(keys(markerDict));
if verbose
    disp(['  Generated in total of ',num2str(totalMarkers),' Markers']);
end
end