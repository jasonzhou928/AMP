function [firstInstanceStruct] = firstInstOfMarker(markerStruct)
    fn = fieldnames(markerStruct);
    firstInstance = zeros([1, max(size(fn))])';

    for i = 1:length(firstInstance)
        markerName = fn{i};
        oneMarkerStruct = markerStruct.(markerName).x;

        for j = 1:max(size(oneMarkerStruct))
            if ~isnan(oneMarkerStruct(j, 1))
                firstInstance(i) = j;
                break;
            end
        end
    end

    firstInstance = num2cell(firstInstance);
    firstInstanceStruct = cell2struct(firstInstance, fn);
end