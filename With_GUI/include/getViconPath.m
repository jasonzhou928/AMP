function viconPath = getViconPath()
viconPath = [];
%% Check for saved ViconPath
if isfile('viconPath.mat') 
    load('viconPath.mat')
    if ~isfile(viconPath)
        viconPath = [];
    end
end
%% Look for viconPath in common places
if isempty(viconPath)   
files = dir('C:\Program Files\Vicon');
for ii = length(files):-1:1
    folder = files(ii).name;
    if contains(folder,'Nexus2')
        viconPath = ['C:\Program Files\Vicon\' folder '\Nexus.exe'];
        break
    end
end

files = dir('C:\Program Files (x86)\Vicon');
for ii = length(files):-1:1
    folder = files(ii).name;
    if contains(folder,'Nexus2')
        viconPath = ['C:\Program Files (x86)\Vicon\' folder '\Nexus.exe'];
        break
    end
end
end
%% User inputs vicon Path if Nothing else works
if isempty(viconPath) 
    warning('Nexus.exe Object not found.');
    while true
        viconPath = input(['Please input the path to your Nexus.exe file (No Quotes):' newline], 's');
        if isfile(viconPath)
            break
        else
        warning('Incorrect Path');    
        end
    end
end
save viconPath viconPath
end

