function initialSetup(filePath)
    vicon = ViconNexus();
    allFiles = dir([filePath,'/*.x1d']);
    allFileNames = {allFiles(:).name};
    filenames = cellfun(@(x) x(1:end-4),allFileNames,'UniformOutput',false);
    for i = 1:length(filenames)
        filename = filenames{i};
        location = [filePath,filename];
        if ~contains(filename,'static','IgnoreCase',true)
            vicon.OpenTrial(location,30);
            vicon.RunPipeline('Reconstruct and Label',location,120);
            vicon.SaveTrial(30);
            vicon.CloseTrial(30);
        end
    end
end