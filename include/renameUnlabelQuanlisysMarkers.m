function markerStruct = renameUnlabelQuanlisysMarkers(markerStruct,qualisys_flag)
    if qualisys_flag
        markers = fieldnames(markerStruct);

        pattern = '^U(\d+)$';
        
        for i = 1:length(markers)
            marker = markers{i};
            tokens = regexp(marker, pattern, 'tokens', 'once');
            if ~isempty(tokens)
                idx = tokens{1};
                newName = ['C_' idx];
                markerStruct.(newName) = markerStruct.(marker);
                markerStruct = rmfield(markerStruct,marker);
            end
        end
    end
end