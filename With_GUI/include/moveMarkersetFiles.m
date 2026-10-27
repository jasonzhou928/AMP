function moveMarkersetFiles(filePath)
finishedDir = [filePath '\Finished'];
workingDir = [filePath '\Working'];
failedDir = [filePath '\Failed'];
files = dir(filePath);
L = length(files);
index = false(1, L);
for k = 1:L
    M = length(files(k).name);
    if M > 4 && strcmp(files(k).name(M-3:M), '.c3d') && (contains(files(k).name, 'Static') || contains(files(k).name, 'static') || contains(files(k).name, 'STATIC'))
        index(k) = true;
    end
end

files = files(index);
for ii = 1:length(files)



File = files(ii).name;
%Copy Static c3d
copyfile ([filePath '\' File], [finishedDir '\' File],'f')
copyfile ([filePath '\' File], [workingDir '\' File],'f')
copyfile ([filePath '\' File], [failedDir '\' File],'f')
%Copy Static Endnote Filter too
try
copyfile ([filePath '\' File(1:end-3) 'Trial.enf'], [finishedDir '\' File(1:end-3) 'Trial.enf'],'f')
copyfile ([filePath '\' File(1:end-3) 'Trial.enf'], [workingDir '\' File(1:end-3) 'Trial.enf'],'f')
copyfile ([filePath '\' File(1:end-3) 'Trial.enf'], [failedDir '\' File(1:end-3) 'Trial.enf'],'f')
catch
    disp('No endnote filter found for static. Creating one ...')
    createEndnoteFilter(filePath,[filePath '\' File(1:end-4)])
    createEndnoteFilter(filePath,[finishedDir '\' File(1:end-4)])
    createEndnoteFilter(filePath,[workingDir '\' File(1:end-4)])
    createEndnoteFilter(filePath,[failedDir '\' File(1:end-4)])
end

files = dir(filePath);
L = length(files);
index = false(1, L);
for k = 1:L
    M = length(files(k).name);
    if M > 4 && strcmp(files(k).name(M-2:M), '.mp')
        index(k) = true;
    end
end

files = files(index);
for ii = 1:length(files)



File = files(ii).name;
copyfile ([filePath '\' File], [finishedDir '\' File],'f')
copyfile ([filePath '\' File], [workingDir '\' File],'f')
copyfile ([filePath '\' File], [failedDir '\' File],'f')
end


files = dir(filePath);
L = length(files);
index = false(1, L);
for k = 1:L
    M = length(files(k).name);
    if M > 4 && strcmp(files(k).name(M-3:M), '.vsk')
        index(k) = true;
    end
end

files = files(index);
for ii = 1:length(files)



File = files(ii).name;
copyfile ([filePath '\' File], [finishedDir '\' File],'f')
copyfile ([filePath '\' File], [workingDir '\' File],'f')
copyfile ([filePath '\' File], [failedDir '\' File],'f')
end


end
