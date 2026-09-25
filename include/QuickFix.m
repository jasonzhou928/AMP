function [newMarkStruct] = QuickFix(markerStruct)
    fn = fieldnames(markerStruct);

    for cat_i = 1:length(fn)
        cat_name = fn{cat_i};
        count_NaN = sum(isnan(markerStruct.(cat_name).x));
        
        if count_NaN == 0 
            continue;
        end

        for i = 2:length(markerStruct.(cat_name).x) - 1
            if isnan(markerStruct.(cat_name).x(i)) && (~isnan(markerStruct.(cat_name).x(i - 1)) && isnan(markerStruct.(cat_name).x(i + 1)))
                markerStruct.(cat_name).x(i) = mean([markerStruct.(cat_name).x(i - 1), markerStruct.(cat_name).x(i + 1)]);
                markerStruct.(cat_name).y(i) = mean([markerStruct.(cat_name).y(i - 1), markerStruct.(cat_name).y(i + 1)]);
                markerStruct.(cat_name).z(i) = mean([markerStruct.(cat_name).z(i - 1), markerStruct.(cat_name).z(i + 1)]);
            end
        end
    end
newMarkStruct = markerStruct;
