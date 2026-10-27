function markerStruct = markerdict2struct(markerDict)
markerStruct = struct();
markerNames = keys(markerDict);
for i = 1:length(markerNames)
    markerName = markerNames{i};
    markerVal = markerDict({markerName});
    markerVal = markerVal{:};
    markerVal = array2table(markerVal,'VariableNames',{'Header','x','y','z'});
    markerStruct.(markerName) = markerVal;
end

end