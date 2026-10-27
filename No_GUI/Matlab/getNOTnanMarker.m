function chosenMarker = getNOTnanMarker(oneMarkerStruct, direc)
    if direc < 0
        chosenMarker = oneMarkerStruct(end,:);
    else
        chosenMarker = oneMarkerStruct(1,:);
    end

    %% go until you find non-nan marker
    count = 0;
    while isnan(chosenMarker.x) 
        count = count + 1;
        if count >= size(oneMarkerStruct) - 1
            break;
        else
            if direc < 0
                chosenMarker = oneMarkerStruct(end - count, :);
            else
                chosenMarker = oneMarkerStruct(1 + count, :);
            end
        end

    end

    %% Only check first 10 markers for NAN
    % len = size(oneMarkerStruct);
    % if (len(1) < 10)
    %     num = len(1);
    % else
    %     num = 10;
    % end
    % 
    % for count = 1:num
    %     if isnan(chosenMarker.x)
    %         if direc < 0
    %             chosenMarker = oneMarkerStruct(end - count, :);
    %         else
    %             chosenMarker = oneMarkerStruct(1 + count, :);
    %         end
    %     else
    %         break;
    %     end
    % end
end