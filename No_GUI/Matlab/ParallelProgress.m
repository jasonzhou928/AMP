function ParallelProgress(action,varargin)
%PARALLELPROGRESS Print one client-side progress line for a parfor loop.

persistent completed total label active lastLength

switch lower(action)
    case 'start'
        total = varargin{1};
        label = char(varargin{2});
        completed = 0;
        active = true;
        lastLength = 0;
        printProgress();

    case 'increment'
        if isempty(active) || ~active
            return
        end
        completed = min(completed + 1,total);
        printProgress();

    case 'finish'
        if isempty(active) || ~active
            return
        end
        completed = total;
        printProgress();
        fprintf('\n');
        active = false;
        lastLength = 0;

    otherwise
        error('ParallelProgress:UnknownAction', ...
            'Unknown progress action: %s',action);
end

    function printProgress()
        if total > 0
            percent = 100 * completed / total;
        else
            percent = 100;
        end
        message = sprintf('%s | segments %d/%d (%3.0f%%)', ...
            label,completed,total,percent);
        padding = repmat(' ',1,max(0,lastLength-length(message)));
        fprintf('\r%s%s',message,padding);
        lastLength = length(message);
    end
end
