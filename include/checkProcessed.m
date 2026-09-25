function missing = checkProcessed(clusters,markerDict,markerStructRef,cf,lp,textFileName)
markerDictRef = markerStruct2dict(markerStructRef);
missing = false;
totalMessage = [];
markerErrors = [];
markerErrorNames = {};
try
for cc = 1:length(clusters)
    cluster = clusters{cc};
    for mm = 1:length(cluster)
        marker = cluster(mm);
        maxErrThresh = 75;
        errThresh = 60;
        if contains(marker{1},caseInsensitivePattern('THI')) % Special case for thigh markers (prone to higher errors)
            maxErrThresh = 130;
            errThresh = 120;
        elseif contains(marker{1},caseInsensitivePattern('MELB')) % Special case for thigh markers (prone to higher errors)
            maxErrThresh = 130;
            errThresh = 120;      
        elseif contains(marker{1},caseInsensitivePattern('SHO')) % Special case for thigh markers (prone to higher errors)
            maxErrThresh = 130;
            errThresh = 120;
        end
        
        ind = strcmp(marker,cluster);
        otherMarkers = cluster(~ind);
        
        arr = lookup(markerDict,marker);
        arr = arr{1}(:,2:4);
        arrRef = lookup(markerDictRef,marker);
        arrRef = arrRef{1};
        arrRef = [arrRef(1,2:4)]';
        donorArr = zeros(length(arr),3,length(otherMarkers));
        targArr = zeros(3,length(otherMarkers));
        for om = 1:length(otherMarkers)
            otherMarker = otherMarkers(om);
            temp = lookup(markerDict,otherMarker);
            donorArr(:,:,om) = temp{1}(:,2:4);
            temp = lookup(markerDictRef,otherMarker);
            targArr(:,om) = [temp{1}(1,2:4)]';
        end
        mErr = NaN(length(arr),1);
        
        % for i = 1:length(arr)
        % donorTraj = [];
        % targetTraj = [];
        %     if ~isnan(arr(i,2))
        %     for j = 1:length(otherMarkers)
        %         if ~isnan(donorArr(i,1,j))
        %             donorTraj(1:3,end+1) = squeeze(donorArr(i,1:3,j));
        %             targetTraj(1:3,end+1) = targArr(1:3,j);
        % 
        %         end
        % 
        %     end
        %     if size(donorTraj,2) >= 3
        % 
        %     p = absor(targetTraj,donorTraj);
        % 
        %     M = p.R * arrRef + p.t;
        %     mErr(i) = sqrt((M(1) - arr(i,1)).^2 + (M(2) - arr(i,2)).^2 + (M(3) - arr(i,3)).^2);
        % 
        % 
        %     end
        % 
        %     end
        % 
        % end

        for i = 1:length(arr)
        donorTraj = [];
        targetTraj = [];
            donorTraj = [];
            targetTraj = [];
            if ~isnan(arr(i,2))
            for j = 1:length(otherMarkers)
                if ~isnan(donorArr(i,1,j))
                    donorTraj(1:3,end+1) = squeeze(donorArr(i,1:3,j));
                    targetTraj(1:3,end+1) = targArr(1:3,j);

                for j = 1:length(otherMarkers)
                    if ~isnan(donorArr(i,1,j))
                        % Fix: Use reshape instead of squeeze for consistent dimensions
                        donorTraj(:,end+1) = reshape(donorArr(i,1:3,j), 3, 1);
                        targetTraj(:,end+1) = targArr(:,j);
                    end
                end
                
                if size(donorTraj,2) >= 3
                    p = absor(targetTraj, donorTraj);
                    
                    % Fix: Ensure p.t is a column vector
                    M = p.R * arrRef + p.t(:);
                    
                    % More robust distance calculation
                    diff_vec = M - arr(i,1:3)';
                    mErr(i) = norm(diff_vec);
                end
            end
            if size(donorTraj,2) >= 3

            p = absor(targetTraj,donorTraj);
                            
            M = p.R * arrRef + p.t;
            mErr(i) = sqrt((M(1) - arr(i,1)).^2 + (M(2) - arr(i,2)).^2 + (M(3) - arr(i,3)).^2);
            

            end

            end
            
            end
        end
        fs = cf; %low pass filter
        fn=(fs/2); %nyquist freq. (1/2 the sample rate)
        fc=lp; %cutoff freq.
        [b,a]=butter(4,fc/fn); %4th order butterworth filter
        filtMErr = filtfilt(b,a,mErr);

       if max(mErr) > maxErrThresh
            if isempty(markerErrorNames)
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            elseif ~any(contains(markerErrorNames,marker{1}))
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            end
            disp([marker{1} ' has too much peak marker error: ' num2str(max(mErr)) ' at frame: ' num2str(find(mErr == max(mErr)))])
            totalMessage = [totalMessage ;{[marker{1} ' has too much peak marker error: ' num2str(max(mErr)) ' at frame: ' num2str(find(mErr == max(mErr)))]}];
            disp(['Cluster: ' cluster]);
            missing = true;
       elseif rmse(zeros(length(filtMErr),1),filtMErr) > errThresh
            if isempty(markerErrorNames)
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            elseif ~any(contains(markerErrorNames,marker{1}))
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            end
            missing = true;
            disp([marker{1} ' has too much total marker error: ' num2str(rmse(zeros(length(filtMErr),1),filtMErr))])
            totalMessage = [totalMessage; {[marker{1} ' has too much total marker error: ' num2str(rmse(zeros(length(filtMErr),1),filtMErr))]}];
            disp(['Cluster: ' cluster]);
       end
       mErr = sort(mErr);
       if max(diff(mErr)) > 50
            if isempty(markerErrorNames)
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            elseif ~any(contains(markerErrorNames,marker{1}))
            markerErrorNames{end+1} = marker{1};
            markerErrors = [markerErrors, mErr];
            end
            missing = true;
            warning([marker{1} ' has large discontinuities'])
            totalMessage = [totalMessage ; {[marker{1} ' has large discontinuities']}];
            disp(['Cluster: ' cluster]);
            
       end
        
    end
end
catch

    warning('Problem with Trial')
    missing = true;

end
if ~isempty(totalMessage)
    T = array2table(markerErrors,'VariableNames',markerErrorNames);
    save([textFileName(1:end-4) '_MarkerErrors.mat'],'T')
    fileID = fopen(textFileName, 'w');
    for fi = 1:size(totalMessage,1)
fprintf(fileID, '%s\n', totalMessage{fi});
    end
fclose('all');
pause(2)
end
end