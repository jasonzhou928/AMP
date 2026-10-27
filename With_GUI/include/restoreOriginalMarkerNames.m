function markerData = restoreOriginalMarkerNames(markerData,markerOriginalNames,varargin)

    p = inputParser;
    addParameter(p,'DefaultName','',@ischar);

	parse(p,varargin{:});
    defaultName = p.Results.DefaultName;

    markers = fieldnames(markerData);
    markerDataTemp = struct();
    
    for idx = 1:length(markers)
        marker = markers{idx};
        try
            markerOriginalName = markerOriginalNames.(marker);
        catch
            if contains(marker,'C_')
                markerOriginalName = strcat(marker);
            else
                markerOriginalName = strcat(defaultName,'_',marker);
            end
        end
        markerDataTemp.(markerOriginalName) = markerData.(marker);
    end
    markerData = markerDataTemp;
end