function dist = getMarkerDistance(markerA, markerB)
    coordsA = table2array(markerA(1, 2:end));
    coordsB = table2array(markerB(1, 2:end));

    dist = sqrt(sum((coordsB - coordsA).^2));