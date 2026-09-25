function [markerData,markerNames] = ExtractMarkers_multiSubs(c3dFile,multiSubs)
% ExtractMarkers returns a struct where the fieldnames are the markers
% and each field contains an nx3 array of point data for n frames. Any
% missing marker data is represented as NaN instead of with zeros.
% markerData = Vicon.ExtractMarkers(c3dFile)
% 
% By default ExtractMarkers provides coordinates in OsimXYZ convention. Use
% Vicon.transform to change the coordinate frames.
%
% See also Vicon.transform

    h = btkReadAcquisition(c3dFile);
    markerData = btkGetMarkers(h);
    markerLabels = btkGetMetaData(h,'POINT','LABELS');
    markerLabels = markerLabels.info.values;
    firstFrame=btkGetFirstFrame(h);
    btkCloseAcquisition(h);
    markers = fieldnames(markerData);
    if multiSubs
        markersParsed = cellfun(@(x) split(x,':'),markerLabels,'UniformOutput',false);
        markersParsed = cellfun(@(x) x{end},markersParsed,'UniformOutput',false);
        markersParsed = cellfun(@(x) strrep(x, '*', 'C_'),markersParsed,'UniformOutput',false);
    end
    markerData2 = struct();
    markerNames = struct();
    
    for idx = 1:length(markers)
        marker = markers{idx};
        markerName = split(marker,'_');
        if length(markerName) > 1 && ~strcmp(markerName{1},'C') && multiSubs
            marker2 = markersParsed{idx};
        else
            marker2 = marker;
        end
        a=markerData.(marker);
        a(a==0)=nan;
        a=Vicon.transform(a, 'OsimXYZ');
        header=(firstFrame-1)+(1:size(a,1))';
        markerData2.(marker2) = array2table([header,a],'VariableNames',{'Header','x','y','z'});
        markerNames.(marker2) = marker;
    end

    markerData = markerData2;
end
