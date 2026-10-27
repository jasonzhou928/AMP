function checkReopenVicon(viconPath)
%Return status of Vicon executable
[~,status_result] = system('tasklist /FI "imagename eq nexus.exe" /fo table /nh');
%Check if Vicon is Running
if ~contains(status_result, 'Nexus.exe')
    %Open Vicon if it isn't running
    system([viconPath ' &']);
    pause(35)
    %Wait for Vicon to Reopen
else
    try
    system('TASKKILL -f -im "Nexus.exe"');
    catch
    end
    pause(20)
    system([viconPath ' &']);
    %Wait for Vicon to Reopen
end

end