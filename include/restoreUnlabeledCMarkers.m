function markerStruct = restoreUnlabeledCMarkers(markerStruct,qualisys_flag)
    if qualisys_flag
        markers = fieldnames(markerStruct);
        pattern = '^C_(\d+)$';
        tokens = regexp(markers, pattern, 'tokens', 'once');
        rename = ~cellfun(@isempty, tokens);
        if any(rename)
            markers(rename) = cellfun(@(t) ['U' t{1}], tokens(rename), 'UniformOutput', false);
            markerStruct = cell2struct(struct2cell(markerStruct), markers, 1);
        end
    end
end