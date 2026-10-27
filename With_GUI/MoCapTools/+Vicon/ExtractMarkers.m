function markerData = ExtractMarkers(c3dFile)
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
    firstFrame=btkGetFirstFrame(h);
    btkCloseAcquisition(h);
    markers = fieldnames(markerData);
    markerData2 = struct();
    
    for idx = 1:length(markers)
        marker = markers{idx};
        markerName = split(marker,'_');
        if ~strcmp(markerName{1},'C') && length(markerName) > 1
            marker2 = markerName{2};
        else
            marker2 = marker;
        end
        a=markerData.(marker);
        a(a==0)=nan;
        a=Vicon.transform(a, 'OsimXYZ');
        header=(firstFrame-1)+(1:size(a,1))';
        markerData2.(marker2) = array2table([header,a],'VariableNames',{'Header','x','y','z'});
    end

    markerData = markerData2;
end
