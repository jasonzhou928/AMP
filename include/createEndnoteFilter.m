function createEndnoteFilter(donorFilePath,filename)

donorFiles = dir(fullfile(donorFilePath,'*.Trial.enf'));
donorFile = donorFiles(1);
if ~isfile([filename '.Trial.enf'])
copyfile ([donorFilePath '\' donorFile.name], [filename '.Trial.enf'],'f')
end
end