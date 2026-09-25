function trialList = getFinishedTrials(folderPath)
rmPattern = {'fjc','FJC','Fjc'}; %Remove trials with these substrings
files = dir([folderPath '\Finished']);
L = length(files);
index = false(1, L);
for k = 1:L
    M = length(files(k).name);
    if M > 4 && contains(files(k).name, '.c3d') 
        index(k) = true;
    end
end
files = files(index);
trialList = {};
for ii = 1:length(files)
    file = files(ii).name;
    keep = true;
    for jj = 1:length(rmPattern)
        if contains(file,rmPattern{jj})
            keep = false;
        end
    end
    if keep
        trialList{end +1} = file(1:end -4);
    end

end