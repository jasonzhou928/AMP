% filename = 'RA_StanceFlexion_50_filled.c3d';
% filename = 'Static.c3d';
filePath = 'D:\GaTech Dropbox\Sixu Zhou\Jason_ResearchStuff\Vicon Data\Processed\PK12\PowerKnee\11_21_23\C3D';

fileNames = dir(filePath);
for i = 1:length(fileNames)
    filename = fileNames(i).name;
    if ~any(strcmp(filename,{'.','..'}))
        
        c3dFile = [filePath,'\',filename];
        [markerStruct, markerOriginalNames] = Vicon.ExtractMarkers_multiSubs(c3dFile,0);
        oldNames = {'LPTHI','LDTHI','LUTHI','RPTHI','RDTHI','RUTHI','LPTIB','LDTIB','LUTIB','RPTIB','RDTIB','RUTIB','LMTOE','LSTOE','LLTOE','RMTOE','RSTOE','RLTOE','SSTRN','ISTRN'};
        newNames = {'LATHI','LPTHI','LDTHI','RATHI','RPTHI','RDTHI','LATIB','LPTIB','LDTIB','RATIB','RPTIB','RDTIB','LMT1','LMT2','LMT5','RMT1','RMT2','RMT5','CLAV','SSTRN'};
        
        for i = 1:length(oldNames)
            oldName = oldNames{i};
            newName = newNames{i};
            markerStruct.(newName) = markerStruct.(oldName);
            markerStruct = rmfield(markerStruct,oldName);
        end
        
        Vicon.markerstoC3D(markerStruct, c3dFile, c3dFile);
        fprintf("%s Done\n",filename)
    end
end