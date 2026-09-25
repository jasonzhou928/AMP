function [previous_jump_thresholds,clusters_jump_threshold,lower_bound_thresholds, enforce_high_thresholds] = checkThresholds(clusters, clusters_jump_threshold, previous_jump_thresholds, lower_bound_thresholds, enforce_high_thresholds, markerDict)

for cc = 1:length(clusters)
    cluster = clusters{cc};
    clusterArr = [];
    for mm = 1:length(cluster)
        marker = cluster(mm);
        
        arr = lookup(markerDict,marker);
        arr = arr{1}(:,2);
        clusterArr = [clusterArr arr];
    end

    clusterNum1 = floor(length(cluster)*.75); % Single frame max number of nan markers
    clusterNum2 = round(length(cluster)*.5); % 25 percent of trial max number of nan markers
    clusterNum3 = 2; % 50 percent of trial max number of nan markers

    keep = true;
    badFrameType1 = 0;
    badFrameType2 = 0;
    %Enforce a high threshold if one marker can't be found (can't be
    %determined if this is due to marker missing or threshold issue)
    badFrameType3 = 0;
    enforceHighThresh = false;
    for ca = 1:length(clusterArr)
        if sum(isnan(clusterArr(ca,:))) >= clusterNum1
            
            keep = false;
            break
        end
        if sum(isnan(clusterArr(ca,:))) >= clusterNum2
            
            badFrameType1 = badFrameType1 + 1;
        end
        if sum(isnan(clusterArr(ca,:))) >= clusterNum3
            
            badFrameType2 = badFrameType2 + 1;
        end
        if sum(isnan(clusterArr(ca,:))) >= 1
            badFrameType3 = badFrameType3 + 1;
        end
    end

    if badFrameType3 >= length(clusterArr)

    enforceHighThresh = true;
    end
    if badFrameType1 > .25*length(clusterArr)
        keep = false;
    elseif badFrameType2 > .6*length(clusterArr)
        keep = false;
    end

    if keep
        previous_jump_thresholds{cc}{1} = clusters_jump_threshold{cc}{1};
        if isnan(lower_bound_thresholds{cc}{1})   
        clusters_jump_threshold{cc}{1} = previous_jump_thresholds{cc}{1}/2;
        else
        clusters_jump_threshold{cc}{1} = lower_bound_thresholds{cc}{1}/2 + clusters_jump_threshold{cc}{1}/2;
        end
        if enforceHighThresh
            enforce_high_thresholds{cc} = 1;
        end
    elseif isnan(previous_jump_thresholds{cc}{1})
        if isnan(lower_bound_thresholds{cc}{1})
            lower_bound_thresholds{cc}{1} = clusters_jump_threshold{cc}{1};
        elseif lower_bound_thresholds{cc}{1} < clusters_jump_threshold{cc}{1}
             lower_bound_thresholds{cc}{1} = clusters_jump_threshold{cc}{1};
        end

        clusters_jump_threshold{cc}{1} = clusters_jump_threshold{cc}{1} *2;
        
    else
        if isnan(lower_bound_thresholds{cc}{1})
            lower_bound_thresholds{cc}{1} = clusters_jump_threshold{cc}{1};
        elseif lower_bound_thresholds{cc}{1} < clusters_jump_threshold{cc}{1}
             lower_bound_thresholds{cc}{1} = clusters_jump_threshold{cc}{1};
        end

        clusters_jump_threshold{cc}{1} = previous_jump_thresholds{cc}{1}/2 + clusters_jump_threshold{cc}{1}/2;
        
    end
end
end