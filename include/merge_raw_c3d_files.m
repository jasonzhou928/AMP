function merge_raw_c3d_files_with_analog(fileA, fileB, outputFile)
    % Load the first C3D file (File A)
    acqA = btkReadAcquisition(fileA);

    % Load the second C3D file (File B)
    acqB = btkReadAcquisition(fileB);

    % Extract marker values
    markerValuesA = btkGetMarkersValues(acqA);
    markerValuesB = btkGetMarkersValues(acqB);

    % Ensure both files have the same number of markers
    numMarkersA = size(markerValuesA, 2) / 3;
    numMarkersB = size(markerValuesB, 2) / 3;

    % Concatenate marker values
    mergedMarkerValues = [markerValuesA, markerValuesB];

    % Create a new acquisition with concatenated marker and analog data
    numMarkers = numMarkersA+numMarkersB;
    totalFrames = size(mergedMarkerValues, 1);

    mergedAcq = btkCloneAcquisition(acqA);
    btkSetFrameNumber(mergedAcq, totalFrames);
    btkSetPointNumber(mergedAcq, numMarkers);

    % Assign generic labels to markers
    genericMarkerNames = arrayfun(@(i) sprintf('Marker%d', i), 1:numMarkers, 'UniformOutput', false);
    markerLabel_info = btkMetaDataInfo('Char', genericMarkerNames);
    btkSetMetaData(mergedAcq, 'POINT', 'LABELS', markerLabel_info);

    % Set the merged marker values
    btkSetMarkersValues(mergedAcq, mergedMarkerValues);

    % Write the merged C3D file
    btkWriteAcquisition(mergedAcq, outputFile);
    btkCloseAcquisition(mergedAcq);
    btkCloseAcquisition(acqA);
    btkCloseAcquisition(acqB);
    fprintf('Merged C3D file with analog data saved to: %s\n', outputFile);
end


% Example usage
path = 'C:\Users\szhou357\GaTech Dropbox\Sixu Zhou\Ossur Teaming\Data\CAREN\Hanjun\02_17_25\';
fileA = 'Static_fullbody.c3d';
fileB = 'platform.c3d';
outputFile = 'Static_combined.c3d';
fileAPath = [path fileA];
fileBPath = [path fileB];
outputFilePath = [path outputFile];

merge_raw_c3d_files_with_analog(fileAPath, fileBPath, outputFilePath);