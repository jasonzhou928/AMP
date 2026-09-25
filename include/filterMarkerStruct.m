function [markerStruct] = filterMarkerStruct(markerStruct, cf,lp)

% SET UP FILTER
fs = cf; %low pass filter
fn=(fs/2); %nyquist freq. (1/2 the sample rate)
fc=lp; %cutoff freq.
[b,a]=butter(8,fc/fn); %4th order butterworth filter
    
% FILTER INPUT DATA
markers = fields(markerStruct);
for mm = 1:length(markers)
    
    marker = markers{mm};
    if ~strcmp(marker(1:2),'C_')

    markerStruct.(marker).x = filtfilt(b,a,markerStruct.(marker).x);

    markerStruct.(marker).y = filtfilt(b,a,markerStruct.(marker).y);

    markerStruct.(marker).z = filtfilt(b,a,markerStruct.(marker).z);
    end
end
end