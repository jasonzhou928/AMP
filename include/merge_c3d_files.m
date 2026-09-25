function merge_c3d_files_with_analog(fileA, fileB, outputFile)
    % Load the first C3D file (File A)
    acqA = btkReadAcquisition(fileA);

    % Load the second C3D file (File B)
    acqB = btkReadAcquisition(fileB);

    % Get marker labels
    markerNamesA = btkGetMetaData(acqA, 'POINT', 'LABELS').info.values;

    % Filter out markers containing "*"
    validMarkers = ~contains(markerNamesA, '*'); % Logical array for valid markers
    filteredMarkerNames = markerNamesA(validMarkers);

    % Extract and filter marker values
    markerValuesA = btkGetMarkersValues(acqA);
    markerValuesB = btkGetMarkersValues(acqB);
    markerIndices = find(validMarkers);
    filteredMarkerValuesA = extractMarkerValues(markerValuesA, markerIndices);
    filteredMarkerValuesB = extractMarkerValues(markerValuesB, markerIndices);

    % Concatenate marker values
    mergedMarkerValues = [filteredMarkerValuesA; filteredMarkerValuesB];

    % Extract and concatenate analog data
    analogValuesA = btkGetAnalogsValues(acqA);
    analogValuesB = btkGetAnalogsValues(acqB);
    mergedAnalogValues = [analogValuesA; analogValuesB];

    % Extract analog channel labels
    analogLabelsA = btkGetMetaData(acqA, 'ANALOG', 'LABELS').info.values;
    analogLabelsB = btkGetMetaData(acqB, 'ANALOG', 'LABELS').info.values;

    % Verify analog consistency
    if ~isequal(analogLabelsA, analogLabelsB)
        error('The two files must have the same analog channels.');
    end
    
    % Create a new acquisition with filtered markers and concatenated analog data
    numFilteredMarkers = length(filteredMarkerNames);
    numAnalogChannels = length(analogLabelsA);
    totalFrames = size(mergedMarkerValues, 1);

    mergedAcq = btkCloneAcquisition(acqA);
    btkSetFrameNumber(mergedAcq,totalFrames);
    btkSetPointNumber(mergedAcq, numFilteredMarkers);

    markerLabel_info=btkMetaDataInfo('Char',filteredMarkerNames);
    btkSetMetaData(mergedAcq, 'POINT', 'LABELS', markerLabel_info);

    analogLabel_info=btkMetaDataInfo('Char',analogLabelsA);
    btkSetMetaData(mergedAcq, 'ANALOG', 'LABELS', analogLabel_info);

    % Set the merged marker values
    btkSetMarkersValues(mergedAcq, mergedMarkerValues);

    % Set the merged analog data
    btkSetAnalogsValues(mergedAcq, mergedAnalogValues);

    % Write the merged C3D file
    btkWriteAcquisition(mergedAcq, outputFile);
    btkCloseAcquisition(mergedAcq);
    btkCloseAcquisition(acqA);
    btkCloseAcquisition(acqB);
    fprintf('Merged C3D file with analog data saved to: %s\n', outputFile);
end

% Helper function to extract values for valid markers
function filteredValues = extractMarkerValues(markerValues, validIndices)
    % Each marker has 3 columns (X, Y, Z)
    validCols = arrayfun(@(i) (3 * i - 2):(3 * i), validIndices, 'UniformOutput', false);
    validCols = horzcat(validCols{:}); % Combine all valid columns
    filteredValues = markerValues(:, validCols);
end

% Example usage
path = 'C:\Users\szhou357\GaTech Dropbox\Sixu Zhou\Ossur Teaming\Data\CAREN\Hanjun\02_17_25\';
fileA = 'Static_fullbody.c3d';
fileB = 'platform.c3d';
outputFile = 'Static_combined.c3d';
fileAPath = [path fileA];
fileBPath = [path fileB];
outputFilePath = [path outputFile];

merge_c3d_files_with_analog(fileAPath, fileBPath, outputFilePath);