function [clusters, clusters_jump_threshold, markerStructRef, names, multisubs] = getMarkerSet(folderPath,viconPath,custom_jump_thresholds,defaultThresh, staticFilePath)
fprintf('\n \n  %%%%%% GETTING MARKERSET %%%%%% \n \n');
 if ~exist(folderPath, 'dir')
       error(['Folder Does Not Exist: ' newline folderPath newline])
end
[~,status_result] = system('tasklist /FI "imagename eq nexus.exe" /fo table /nh');
%Check if Vicon is Running
if ~contains(status_result, 'Nexus.exe')
    %Open Vicon if it isn't running
    system([viconPath ' &'])
    pause(20)
end
vicon = ViconNexus();

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

% File = staticFiles(1).name;
% filename = [folderPath '\' File(1:length(File)-4)];
[~, File, ~] = fileparts(staticFilePath);
filename = staticFilePath{1}(1:end-4);

disp(['Using: ' File])
doing_vicon_operations = true;
while doing_vicon_operations
try   
vicon.OpenTrial(filename, 60);
vicon.RunPipeline('ExportC3D', '', 200);
vicon.SaveTrial(60);
clusters = {};

[ names, ~, active ] = vicon.GetSubjectInfo();
clusterNum = 0; %start with 0 clusters
segLengths = [];
multisubs = true;
if length(active) < 2
    multisubs = false;
end
  
for a = 1:length(active) %iterate through subjects
subject = names{a};
disp(['Found Subject: ' subject])
if multisubs
markerStructRef = Vicon.ExtractMarkers_multiSubs([filename,'.c3d'],multisubs);
else
  markerStructRef = Vicon.ExtractMarkers([filename,'.c3d']);  
end
segments = vicon.GetSegmentNames(subject);
segLengths(a) = length(segments);
for qq = 1:length(segments)
    segment = segments{qq};
    clusterNum = clusterNum +1;
    [parent, ~, markers] = vicon.GetSegmentDetails(subject, segment);
    jj = 1;
    %%Check if marker has been detached or isn't labeled
    while jj <= length(markers)
        marker = markers{jj};
        try
            check = markerStructRef.(marker).x(1);
        catch 
            markers(jj) = [];
            continue
        end
        if isnan(check)
             markers(jj) = [];
             continue
        end
        jj = jj+1;
    end
    if length(markers) < 4
        diff = 4-length(markers);

        [~, ~, parentMarkers] = vicon.GetSegmentDetails(subject, parent);
        clusterCenter = [0;0;0];
        markerString = [];
        for ll = 1:length(markers)
            marker = markers{ll};
            markerString = [markerString marker ','];
            clusterCenter = clusterCenter + [markerStructRef.(marker).x(1);markerStructRef.(marker).y(1);markerStructRef.(marker).z(1)]./length(markers);
        end
        dists = [];
        for pm = 1:length(parentMarkers)
            parentMarker = parentMarkers{pm};
            dists(end+1) = sqrt((clusterCenter(1)-markerStructRef.(parentMarker).x(1)).^2 + (clusterCenter(2)-markerStructRef.(parentMarker).y(1)).^2 + (clusterCenter(3)-markerStructRef.(parentMarker).z(1)).^2);
        end
        [~,inds] = sort(dists,'ascend');
        for jj = 1:diff
            ind = inds(jj);
          markers{end + 1} = parentMarkers{ind};
          disp(['Adding ' parentMarkers{ind} ' to cluster: ' markerString])
        end  
    end
    clusters{clusterNum} = markers;
    clusters_jump_threshold{clusterNum} = {defaultThresh};
    for cl = 1:length(custom_jump_thresholds)
        if strcmpi(segment,custom_jump_thresholds{cl}{1})
            clusters_jump_threshold{clusterNum} = custom_jump_thresholds{cl}(2);
        end
    end
end
end
% Make subject with most segments the default

[~, inds] = sort(segLengths,'descend');
names = names(inds);
vicon.CloseTrial(60);
catch ME

    disp(ME.message);
    for k = 1:length(ME.stack)
        fprintf('Error in %s at line %d in file %s\n', ...
            ME.stack(k).name, ME.stack(k).line, ME.stack(k).file);
    end

    % createEndnoteFilter(folderPath,filename)
    warning('Problem communicating with Vicon... Attempting to reconnect')
    checkReopenVicon(viconPath);
    Vicon_Openned = false;
    while ~Vicon_Openned
    try
    vicon = ViconNexus();
    catch 
        pause(10)
        continue
    end
    Vicon_Openned = true;
    end
    continue

end
doing_vicon_operations = false;
end

end
