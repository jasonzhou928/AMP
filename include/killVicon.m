function killVicon(viconPath)

    try
    system('TASKKILL -f -im "Nexus.exe"');
    catch
    end
    pause(15)
    system([viconPath ' &']);

end