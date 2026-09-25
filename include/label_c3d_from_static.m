function labeledMarkers = label_c3d_from_static(staticFile, dynamicFile)

    % Load static and dynamic C3D files
    staticAcq = btkReadAcquisition(staticFile);
    dynamicAcq = btkReadAcquisition(dynamicFile);

    % Extract markers
    staticMarkers = btkGetMarkers(staticAcq);
    dynamicMarkers = btkGetMarkers(dynamicAcq);

    staticNames = fieldnames(staticMarkers);
    dynamicNames = fieldnames(dynamicMarkers);

    numStatic = length(staticNames);
    numDynamic = length(dynamicNames);

    exampleData = dynamicMarkers.(dynamicNames{1});
    trialLength = size(exampleData,1);

    markerStructOriginal = Vicon.ExtractMarkers_multiSubs(dynamicFile,1);
    markerStructLabeled = markerStructOriginal;

    % Compute mean positions (can change to specific frame if desired)
    staticPos = zeros(numStatic, 3);
    for i = 1:numStatic
        data = staticMarkers.(staticNames{i});
        staticPos(i, :) = nanmean(data, 1);
    end

    for f = 1:trialLength
        dynamicPos = zeros(numDynamic, 3);
        for i = 1:numDynamic
            data = dynamicMarkers.(dynamicNames{i})(f,:);
            dynamicPos(i, :) = nanmean(data, 1);
        end
    
        % Build cost matrix (Euclidean distance)
        costMat = zeros(numDynamic, numStatic);
        for i = 1:numDynamic
            for j = 1:numStatic
                costMat(i,j) = norm(dynamicPos(i,:) - staticPos(j,:));
            end
        end
    
        % Hungarian algorithm for optimal one-to-one assignment
        [idxDyn, ~] = matchpairs(costMat, 1000);
    
        % Rename dynamic markers using matched labels
        labeledMarkers = struct();
        for k = 1:length(idxDyn)
            dynIdx = idxDyn(k,1);
            statIdx = idxDyn(k,2);
            oldName = dynamicNames{dynIdx};
            newName = staticNames{statIdx};
            
            if ~isfield(markerStructLabeled,newName)
                markerStructLabeled.(newName) = markerStructLabeled.(oldName);
                markerStructLabeled.(newName)(:,:) = [];
            end
            
            markerStructLabeled.(newName)(f,:) = markerStructLabeled.(oldName)(f,:);
            markerStructLabeled.(oldName)(f,:) = array2table([table2array(markerStructLabeled.(oldName)(f,1)),nan(1,3)]);
        end
    end

    markerDict = markerStruct2dict(markerStructLabeled);
    markerDict = CombineUnlabeledMarkers(markerDict);
    markerStructLabeled = markerdict2struct(markerDict);
    
    filledC3D = [dynamicFile(1:end-4) '_labeled.c3d'];
    Vicon.markerstoC3D_multiSubs(markerStructLabeled, dynamicFile, filledC3D);

end
