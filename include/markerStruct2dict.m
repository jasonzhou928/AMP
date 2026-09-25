function dict = markerStruct2dict(markerStruct)

markerNames = fieldnames(markerStruct);
markerCoordinateTable = struct2cell(markerStruct);
markerCoordinateArray = cellfun(@(x) table2array(x),markerCoordinateTable,'UniformOutput',false);

dict = dictionary(markerNames,markerCoordinateArray);
end