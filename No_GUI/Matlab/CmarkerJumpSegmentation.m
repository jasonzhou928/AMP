function markerDict = CmarkerJumpSegmentation(markerDict,verbose)
if nargin < 2
    verbose = true;
end
if verbose
    disp('%%%%%Segmenting CMarkers -- Generating Pseudo Markers%%%%%')
end
markerStructnames = keys(markerDict);
markerSet = markerStructnames;
markerSet = markerSet(contains(markerSet,'C_'));
reverseStr = '';
nextMarkerID = length(markerStructnames);
usedNames = markerStructnames;

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if verbose
        msg = sprintf('Processed C Markers %d/%d\nGenerated Markers: %d \n', mm, length(markerSet),length(markerStructnames));
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    
    source = markerDict({currentMarker});
    source = source{:};
    data = source(:,2:4);
    occupied = ~isnan(data(:,1));
    transitions = diff([false; occupied; false]);
    starts = find(transitions == 1);
    ends = find(transitions == -1) - 1;
    markerSegs = reshape([starts, ends].', [], 1);
    fragmentRanges = zeros(0,2);
    
    for bb = 1:length(markerSegs)/2
        %%% find marker jumps within each segment using nearest neighbors
        segStart = markerSegs(bb*2-1);
        segEnd = markerSegs(bb*2);
        dataRange = data(segStart:segEnd,:);
        dataRangeAxis = diff(dataRange);
        
        markerSpeedIncrement = sum(diff(dataRange).^2,2).^0.5;
        if segEnd == segStart
            fragmentRanges(end+1,:) = [segStart,segEnd];
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
                fragmentRanges(end+1,:) = [starting,ending];
            end
        elseif all(markerSpeedIncrement > 25)
            jumpSegs = segStart:segEnd;
            for ii = 1:length(jumpSegs)
                jumpSeg = jumpSegs(ii);
                fragmentRanges(end+1,:) = [jumpSeg,jumpSeg];
            end
        else
            fragmentRanges(end+1,:) = [segStart,segEnd];
        end
    end
    
    nFragments = size(fragmentRanges,1);
    if nFragments > 0
        fragmentNames = cell(nFragments,1);
        fragmentValues = cell(nFragments,1);
        emptyMarker = source;
        emptyMarker(:,2:4) = NaN;
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
            fragment = emptyMarker;
            starting = fragmentRanges(ii,1);
            ending = fragmentRanges(ii,2);
            fragment(starting:ending,2:4) = data(starting:ending,:);
            fragmentValues{ii} = fragment;
        end
        markerDict(fragmentNames) = fragmentValues;
    end
    markerDict({currentMarker}) = [];
end
totalMarkers = length(keys(markerDict));
if verbose
    disp(['  Generated in total of ',num2str(totalMarkers),' Markers']);
end
end
