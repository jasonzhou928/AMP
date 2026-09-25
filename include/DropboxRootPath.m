function path=DropboxRootPath()
% DROPBOCROOTPATH Returns the location of the Dropbox directory
% path=DropboxRootPath()
% Reads the systems info.json file to locate Dropbox.
% Limitations: only works with one account on the computer, personel or business
% For more information, see <a href="matlab: 
% web('https://www.dropbox.com/help/4584')">the Dropbox article</a>.
%
% Phil Birch 2015
jsonFileName=fullfile('Dropbox','info.json');
if ispc
   
    appDataPath=getenv('APPDATA');
    localDataPath=getenv('LOCALAPPDATA');
    if exist(fullfile(appDataPath,jsonFileName),'file')==2
        json=fileread(fullfile(appDataPath,jsonFileName));
    elseif exist(fullfile(localDataPath,jsonFileName),'file')==2
        json=fileread(fullfile(localDataPath,jsonFileName));
    else
        error('DBR:missingFile','Cannot locate the Dropbox info.json file')
    end
else  %mac or linux
    json=fileread('~/.dropbox/info.json');
end
    %split the file by locating ""
    jsonSplit=regexp(json,'\"(.+?)\"','match');
    %find the path
    ind=find(strcmp(jsonSplit,'"path"'));
    path=jsonSplit{ind+1};
    %remove the extra ""
    path(regexp(path,'\"'))=[];
    %remove the extra \\
    path(regexp(path,'\\{2}'))=[];

