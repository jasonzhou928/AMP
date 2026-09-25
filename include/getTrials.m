function trialList = getTrials(folderPath,skipList, keepList, staticFilePath, useVicon)
    % if useVicon
        % pat = '.x1d';
    % else
        pat = '.c3d';
    % end
    % rmPattern = {'Static','static','STATIC','fjc','FJC','Fjc'}; 
    rmPattern = {};
    statPattern = {};
    if ~iscell(skipList)
        rmPattern = {skipList}; %Remove trials with these substrings
    else
        for l = 1:length(skipList)
            % rmPattern{end + 1} = skipList;
            [skipFolder, skipName] = fileparts(skipList);
            if ~contains(folderPath, skipFolder{1}, 'IgnoreCase', true)
                rmPattern = '';
                break;
            else
                rmPattern{end + 1} = skipName; % Add each skipList file name to rmPattern
            end
        end
    end
    [staticFolder, staticName] = fileparts(staticFilePath);
    statPattern{end + 1} = staticName;

    files = dir(folderPath);
    L = length(files);
    index = false(1, L);
    for k = 1:L
        M = length(files(k).name);
        if M > 4 && contains(files(k).name, pat) 
            index(k) = true;
        end
    end
    files = files(index);
    trialList = {};
    for ii = 1:length(files)
        file = files(ii).name;    
        keep = true;
        for kk = 1:length(statPattern)
            if contains(upper(file),upper(statPattern{kk}))
                keep = false;
            end
        end

        for jj = 1:length(rmPattern)
            if strcmpi(file,rmPattern{jj})
                keep = false;
            end
        end
        if keep
            trialList{end +1} = file(1:end -4);
        end
    end
    
    temp = {};
    if ~isempty(keepList)
        for q = 1:length(trialList)
            file = trialList{q};
            % keep = true;
            if iscell(keepList)
                for pp = 1:length(keepList)
                    if contains(file, keepList{pp}(1:end-4))
                        % keep = false;
                        temp{end + 1} = keepList{pp}(1:end-4);
                    end
                end
            else
                if contains(file, keepList(1:end-4))
                    % keep = false;
                    temp = keepList(1:end-4);
                end
            end
        end
        trialList = temp;
        if ~iscell(trialList)
            trialList = {trialList}; % Ensure trialList is a cell array
        end
    end
end