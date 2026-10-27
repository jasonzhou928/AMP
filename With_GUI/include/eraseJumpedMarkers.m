function markerStruct = eraseJumpedMarkers(markerSet,markerLocs,markerGaplocs,markerGapSet,markerStruct,markerStructRef,markerJumpThresholdSet,jumpThresholdList,clusters)

markerStructname = fieldnames(markerStruct);
markerStructname = markerStructname{1};
startFrameOffset = markerStruct.(markerStructname).Header(1);

for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
%     if strcmp(currentMarker,'LWRA')
%         disp('here')
%     end
    markerDrops = markerLocs{mm};
    markerDropsRef = markerDrops{2};
    markerDrops = [markerDrops{1},markerDrops{3}];
    NoRGFoundflag = 0;
    if isempty(markerDrops) && ~isempty(markerDropsRef)
        markerDrops = markerDropsRef;
        NoRGFoundflag = 1;
    end
    for dropi = 1:length(markerDrops)
        dropStart = markerDrops(dropi);
%         
        
%         if dropi ~= length(markerDrops)
%             dropEnd = markerDrops(dropi + 1);
%         else
%             dropEnd = length(markerStruct.(markerStructname).Header);
%         end
%         if ~isempty(markerDropsRef)
%             if ~any(markerDropsRef>dropStart)
%                 dropEnd = length(markerStruct.(markerStructname).Header);
%             else
%                 dropEnd = markerDropsRef(markerDropsRef>dropStart)-1;
%                 dropEnd = dropEnd(1);
%             end
%         else
        Gaplocs = markerGaplocs{contains(markerGapSet,currentMarker)};
        dropEnds = Gaplocs(Gaplocs > dropStart);
        i = 1;
        if isempty(dropEnds)
            dropEnd = length(markerStruct.(markerStructname).Header);
        else
            dropEnd = dropEnds(i);
        end
        dispFlag = 0;
        [markerJumplocs,~] = checkForJumpedMarkers({currentMarker},{dropEnd},markerStruct,markerStructRef,markerJumpThresholdSet,jumpThresholdList,clusters,dispFlag);
        if isempty(markerJumplocs)
            markerJumps = [];
        else
            markerJumps = [markerJumplocs{:}{1}];
        end
        while ~isempty(markerJumps) && ~isempty(dropEnds)
            i = i+1;
            if i == length(dropEnds)
                dropEnd = length(markerStruct.(markerStructname).Header)+1;
                break;
            else
                dropEnd = dropEnds(i);
            end
            [markerJumplocs,~] = checkForJumpedMarkers({currentMarker},{dropEnd},markerStruct,markerStructRef,markerJumpThresholdSet,jumpThresholdList,clusters,dispFlag);
            if isempty(markerJumplocs)
                break;
            else
                markerJumps = [markerJumplocs{:}{1}];
            end
        end
%         end
        if isempty(dropEnds)
            dropEnd = dropEnd;
        else
            dropEnd = dropEnd - 1;
        end
        if NoRGFoundflag
            dropEnd = markerDropsRef(markerDropsRef>dropStart);
            if isempty(dropEnd)
                dropEnd = length(markerStruct.(markerStructname).Header);
            else
                dropEnd = dropEnd(1) - 1;
            end
        end
        markerID = length(fieldnames(markerStruct));
        fakeID = ['C_' num2str(markerID)];
        while any(strcmp(fieldnames(markerStruct),fakeID))
            markerID = markerID + 1;
            fakeID = ['C_' num2str(markerID)];
        end
    
        disp(['         ERASE MARKER JUMP: ',currentMarker,' starting at frame: ', num2str(dropStart + startFrameOffset - 1) ' to ' num2str(dropEnd + startFrameOffset - 1)])
    
        markerStruct.(fakeID) = markerStruct.(currentMarker);
    
        markerStruct.(fakeID).x(1:end) = NaN;
        markerStruct.(fakeID).y(1:end) = NaN;
        markerStruct.(fakeID).z(1:end) = NaN;
    
        markerStruct.(fakeID).x(dropStart:dropEnd) = markerStruct.(currentMarker).x(dropStart:dropEnd);
        markerStruct.(fakeID).y(dropStart:dropEnd) = markerStruct.(currentMarker).y(dropStart:dropEnd);
        markerStruct.(fakeID).z(dropStart:dropEnd) = markerStruct.(currentMarker).z(dropStart:dropEnd);
    
        markerStruct.(currentMarker).x(dropStart:dropEnd) = NaN;
        markerStruct.(currentMarker).y(dropStart:dropEnd) = NaN;
        markerStruct.(currentMarker).z(dropStart:dropEnd) = NaN;
    end
end

end