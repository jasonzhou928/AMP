function [combinedProcessingPipeline] = handleFailedTrial(reason,combinedProcessingPipeline)
if reason == 2
    if strcmp(combinedProcessingPipeline, 'Reconstruct And Label')
        combinedProcessingPipeline = 'Reconstruct and Label Less Filtered';
    elseif strcmp(combinedProcessingPipeline, 'Reconstruct and Label Less Filtered')
        combinedProcessingPipeline = 'Reconstruct and Label Least Filtered';
    elseif strcmp(combinedProcessingPipeline, 'Reconstruct and Label Least Filtered')
        combinedProcessingPipeline = 'Failed';
        warning('Trial Failed... Moving on to next Trial')
    end
end

end