function totalFrames = getTrialLength(markerDict)

markerStructnames = keys(markerDict);
markerStructname = markerStructnames{1};
Frames = markerDict({markerStructname});
Frames = Frames{:};
totalFrames = size(Frames,1);

end