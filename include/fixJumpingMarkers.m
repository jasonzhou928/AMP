function markerStruct = fixJumpingMarkers(markerSet,markerStruct,jumpThreshold,gap_th)
markerjumpNum1 = 0;
fakeName = 200;
for mm = 1:length(markerSet) % loop through marker set
    currentMarker = markerSet{mm};
    if isfield(markerStruct,currentMarker)
        data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
    end
    dataNext = data(2:end,:);
    data = data(1:end-1,:);
    markerIncrements = (sum((dataNext-data).^2,2)).^0.5; % distance between marker frames
    if sum(markerIncrements>jumpThreshold)>0 % if there is a marker jump
        loc = find(markerIncrements>jumpThreshold);
        markerStructname = fieldnames(markerStruct);
        markerStructname = markerStructname{1};
        startFrameOffset = markerStruct.(markerStructname).Header(1);
        loc = loc + startFrameOffset;
        markerjumpNum1 = markerjumpNum1 + 1;
    end
end
disp(['TOTAL MARKER JUMPs: ' num2str(markerjumpNum1)])


markerjumpNum2 = 0;
while abs(markerjumpNum1 - markerjumpNum2) > 0 
    markerjumpNum1 = markerjumpNum2;
    for mm = 1:length(markerSet) % loop through marker set
        currentMarker = markerSet{mm};
        if isfield(markerStruct,currentMarker)
            data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
        end
        dataNext = data(2:end,:);
        data = data(1:end-1,:);
        markerIncrements = (sum((dataNext-data).^2,2)).^0.5; % distance between marker frames
        if sum(markerIncrements>jumpThreshold)>0 % if there is a marker jump
            disp('====================================')
            disp(['FIXING MARKER JUMP: ',currentMarker])
            loc = find(markerIncrements>jumpThreshold);
            markerStructname = fieldnames(markerStruct);
            markerStructname = markerStructname{1};
            startFrameOffset = markerStruct.(markerStructname).Header(1);
            for ii = 1:length(loc)
               jp_loc = loc(ii); 
               data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
               data = data(1:end-1,:);
               jp_marker = data(jp_loc,:);
               temp_markerSet = markerStruct;
               temp_markerSet_names = fieldnames(temp_markerSet);
               for jj = 1:length(temp_markerSet_names)
                   cmp_marker = temp_markerSet_names{jj};
                   cmp_data = [temp_markerSet.(cmp_marker).x(jp_loc+1), temp_markerSet.(cmp_marker).y(jp_loc+1),temp_markerSet.(cmp_marker).z(jp_loc+1)];
                   found = find((sum((cmp_data-jp_marker).^2,2)).^0.5 < gap_th);
                   if ~isempty(found)
                       if length(found)>1
                           warning('found several frames!')
                       end
                       loc_found = jp_loc + startFrameOffset;
                       disp(['FOUND at: ',cmp_marker,' at frame ',num2str(loc_found')])
                       disp(['Swapping ',cmp_marker,' with ',currentMarker])
                       NaNidxs = isnan(temp_markerSet.(cmp_marker).x);
                       NaNidx = find(NaNidxs == 1);
                       NaNframes = NaNidx(NaNidx > jp_loc);
                       if isempty(NaNframes)
                           nextframe = length(temp_markerSet.(cmp_marker).x);
                       else
                           nextframe = NaNframes(1);
                       end
                       pointTarget = [temp_markerSet.(cmp_marker).x(jp_loc+1:nextframe),temp_markerSet.(cmp_marker).y(jp_loc+1:nextframe),temp_markerSet.(cmp_marker).z(jp_loc+1:nextframe)];
                       markerStruct.(currentMarker).x(jp_loc+1:nextframe) = pointTarget(:,1); % save all new x
                       markerStruct.(currentMarker).y(jp_loc+1:nextframe) = pointTarget(:,2); % save all new y
                       markerStruct.(currentMarker).z(jp_loc+1:nextframe) = pointTarget(:,3); % save all new z
                       markerStruct.(cmp_marker).x(jp_loc+1:nextframe) = temp_markerSet.(currentMarker).x(jp_loc+1:nextframe); %save the jumped marker to new pos
                       markerStruct.(cmp_marker).y(jp_loc+1:nextframe) = temp_markerSet.(currentMarker).y(jp_loc+1:nextframe);
                       markerStruct.(cmp_marker).z(jp_loc+1:nextframe) = temp_markerSet.(currentMarker).z(jp_loc+1:nextframe);
                       break;
                   end
                   if jj == length(temp_markerSet_names)
                       loc_jp = jp_loc + startFrameOffset;
                       disp(['NOT FOUND from any markers. Erase marker at frame ',num2str(loc_jp)])
                       markerStruct.(['C_' num2str(fakeName)]) = markerStruct.(currentMarker);
                       markerStruct.(['C_' num2str(fakeName)]).x(1:length(markerStruct.(currentMarker).x)) = NaN;
                       markerStruct.(['C_' num2str(fakeName)]).y(1:length(markerStruct.(currentMarker).x)) = NaN;
                       markerStruct.(['C_' num2str(fakeName)]).z(1:length(markerStruct.(currentMarker).x)) = NaN;
                       markerStruct.(['C_' num2str(fakeName)]).x(jp_loc+1:end) = markerStruct.(currentMarker).x(jp_loc+1:end);
                       markerStruct.(['C_' num2str(fakeName)]).y(jp_loc+1:end) = markerStruct.(currentMarker).y(jp_loc+1:end);
                       markerStruct.(['C_' num2str(fakeName)]).z(jp_loc+1:end) = markerStruct.(currentMarker).z(jp_loc+1:end);
                       markerStruct.(currentMarker).x(jp_loc+1:end) = NaN; % save x
                       markerStruct.(currentMarker).y(jp_loc+1:end) = NaN; % save y
                       markerStruct.(currentMarker).z(jp_loc+1:end) = NaN; % save z
                       fakeName = fakeName + 1;
                   end
               end
            end
        end
    end
    markerjumpNum2 = 0;
    for mm = 1:length(markerSet) % loop through marker set
        currentMarker = markerSet{mm};
        if isfield(markerStruct,currentMarker)
            data = [markerStruct.(currentMarker).x, markerStruct.(currentMarker).y, markerStruct.(currentMarker).z];
        end
        dataNext = data(2:end,:);
        data = data(1:end-1,:);
        markerIncrements = (sum((dataNext-data).^2,2)).^0.5; % distance between marker frames
        if sum(markerIncrements>jumpThreshold)>0 % if there is a marker jump
            loc = find(markerIncrements>jumpThreshold);
            markerStructname = fieldnames(markerStruct);
            markerStructname = markerStructname{1};
            startFrameOffset = markerStruct.(markerStructname).Header(1);
            loc = loc + startFrameOffset;
            markerjumpNum2 = markerjumpNum2 + 1;
        end
    end
    disp(['MARKER JUMPs after Fix: ' num2str(markerjumpNum2)])
end
end