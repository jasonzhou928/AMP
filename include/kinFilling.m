function markerStruct = kinFilling(markerStruct,markerStructRef,trial,viconPath,folderPath)
    %add artificial first and last frame to trial
    markers = fields(markerStructRef);
    trialMarkers = fields(markerStruct);
    frames = length(markerStruct.(trialMarkers{1}).Header);
    ts = markerStruct.(trialMarkers{1}).Header(1);
    tl = markerStruct.(trialMarkers{1}).Header(end);
    for m = 1:length(markers)
        marker = markers{m};
        
        if ~any(contains(trialMarkers,marker))

            headTemp = [ts:tl+2]';
            NaNpad = NaN(frames,1);
            %arr = table2array(markerStruct.(marker));
            
            xTemp = [markerStructRef.(marker).x(1); NaNpad; markerStructRef.(marker).x(1)];
            yTemp = [markerStructRef.(marker).y(1); NaNpad; markerStructRef.(marker).y(1)];
            zTemp = [markerStructRef.(marker).z(1); NaNpad; markerStructRef.(marker).z(1)];
            markerStruct.(marker) = array2table([headTemp,xTemp,yTemp,zTemp],'VariableNames',{'Header','x','y','z'});
        else             
            markerStruct.(marker).Header = markerStruct.(marker).Header + 1;
            
            %arr = table2array(markerStruct.(marker));
            t1 = markerStruct.(marker).Header(1) -1;
            tf = markerStruct.(marker).Header(end) + 1;
            headTemp = [t1; markerStruct.(marker).Header; tf];
            xTemp = [markerStructRef.(marker).x(1); markerStruct.(marker).x; markerStructRef.(marker).x(1)];
            yTemp = [markerStructRef.(marker).y(1); markerStruct.(marker).y; markerStructRef.(marker).y(1)];
            zTemp = [markerStructRef.(marker).z(1); markerStruct.(marker).z; markerStructRef.(marker).z(1)];

            markerStruct.(marker) = array2table([headTemp,xTemp,yTemp,zTemp],'VariableNames',{'Header','x','y','z'});
        
        end
    end
    for m = 1:length(trialMarkers)
        marker = trialMarkers{m};
        if strcmp(marker(1:2),'C_')
        markerStruct = rmfield(markerStruct,marker);
        end
    end
    %write new file
    c3dFile = [trial '.c3d'];
    kinc3d = [trial '_kinematic_filling.c3d'];
    Vicon.markerstoC3D(markerStruct,c3dFile,kinc3d)

    
    createEndnoteFilter(folderPath,[trial '_kinematic_filling']);
    checkVicon(viconPath)
    vicon = ViconNexus();
    doing_vicon_operations = true;
    %Perform kinematic filling (in vicon)
     while doing_vicon_operations 
        try   
        vicon.OpenTrial([trial '_kinematic_filling'], 60);
        vicon.RunPipeline('KinFill', '', 200);
        vicon.RunPipeline('ExportC3D', '', 100);
        vicon.SaveTrial(60);
        vicon.CloseTrial(60);
        catch e


            if strcmpi(e.message, 'Host application failed to respond to the information request.')
                warning('Kinematic Fill Failed')
                killVicon(viconPath);
                checkReopenVicon(viconPath);
                Vicon_Openned = false;
                while ~Vicon_Openned
                try
                vicon = ViconNexus();
                catch 
                    pause(3)
                    continue
                end
                Vicon_Openned = true;
                end
           
                doing_vicon_operations = false;
                break
                
            end
            createEndnoteFilter(folderPath,[trial '_kinematic_filling'])
            warning('Problem communicating with Vicon... Attempting to reconnect')
            checkReopenVicon(viconPath);
            Vicon_Openned = false;
            while ~Vicon_Openned
            try
            vicon = ViconNexus();
            catch 
                pause(3)
                continue
            end
            Vicon_Openned = true;
            end
            continue

        end
        doing_vicon_operations = false;
     end
     % Pull data back in and remove artificial frames
     
     markerStruct = Vicon.ExtractMarkers([trial '_kinematic_filling.c3d']);
     
     markers = fields(markerStruct);
     for m = 1:length(markers)
        marker = markers{m};
        headTemp = markerStruct.(marker).Header(2:end -1);
        headTemp = headTemp - 1;
        xTemp = markerStruct.(marker).x(2:end-1);
        yTemp = markerStruct.(marker).y(2:end-1);
        zTemp = markerStruct.(marker).z(2:end-1);
        markerStruct.(marker) = array2table([headTemp,xTemp,yTemp,zTemp],'VariableNames',{'Header','x','y','z'});
     end     
     Vicon.markerstoC3D(markerStruct,c3dFile,c3dFile)
     files = dir(fullfile([folderPath '\Working\'],'*kinematic_filling*'));
     for ff = 1:length(files)
         delete([files(ff).folder '\' files(ff).name])
     end
     files = dir(fullfile([folderPath '\Failed\'],'*kinematic_filling*'));
     for ff = 1:length(files)
         delete([files(ff).folder '\' files(ff).name])
     end
     

end