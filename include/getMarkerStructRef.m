function markerStructRef = getMarkerStructRef(folderPath,multisubs, staticFilePath)

files = dir(folderPath);
L = length(files);
index = false(1, L);
for k = 1:L
    M = length(files(k).name);
    if M > 4 && contains(files(k).name, '.c3d')
        index(k) = true;
    end
end
files = files(index);
L = length(files);
index = false(1, L);
% for k = 1:L
%     M = length(files(k).name);
%     if (contains(files(k).name, 'static') || contains(files(k).name, 'Static') || contains(files(k).name, 'STATIC'))
%         index(k) = true;
%     end
% end
% staticFiles = files(index);
% if isempty(staticFiles)
%     error(['No Static Trial Found in Folder: ' newline folderPath newline])
% end
% 
% File = staticFiles(1).name;
% filename = [folderPath '\' File];
% [~, File, ~] = fileparts(staticFilePath);
filename = staticFilePath{1};

markerStructRef = Vicon.ExtractMarkers_multiSubs(filename,multisubs);
end