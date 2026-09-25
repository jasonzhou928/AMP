classdef GUI_Tool_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TabGroup                        matlab.ui.container.TabGroup
        FileSetupTab                    matlab.ui.container.Tab
        AutoParamsDropDown              matlab.ui.control.DropDown
        AutoParamsDropDownLabel         matlab.ui.control.Label
        FalseAutoParamLabel             matlab.ui.control.Label
        AddCustomThresholds             matlab.ui.control.Button
        StaticFilePathEditField         matlab.ui.control.EditField
        FilePathLabel                   matlab.ui.control.Label
        EnterKeywordStaticEditField     matlab.ui.control.EditField
        EnterKeywordEditField_2Label    matlab.ui.control.Label
        EnterKeywordSkipEditField       matlab.ui.control.EditField
        EnterKeywordEditFieldLabel      matlab.ui.control.Label
        C3DFolderPathEditField          matlab.ui.control.EditField
        FolderPathEditFieldLabel        matlab.ui.control.Label
        ErrorLabel                      matlab.ui.control.Label
        StaticFilePathsTable            matlab.ui.control.Table
        AddStaticFilePathButton         matlab.ui.control.Button
        ORLabel_3                       matlab.ui.control.Label
        SelectC3DFilestoSkipButton      matlab.ui.control.Button
        C3DstoProcessUploadLabel_2      matlab.ui.control.Label
        AddC3DFolderPathButton          matlab.ui.control.Button
        C3DFolderPathsTable             matlab.ui.control.Table
        ButtonGroup                     matlab.ui.container.ButtonGroup
        ViconFreeProcessingButton       matlab.ui.control.RadioButton
        HaveastaticfileandhavealreadyrunthereconstructpipelineButton  matlab.ui.control.RadioButton
        CurrentlyProcessingLabel        matlab.ui.control.Label
        Gauge                           matlab.ui.control.LinearGauge
        ProgressBarsLabel               matlab.ui.control.Label
        Label_3                         matlab.ui.control.Label
        RunScriptButton                 matlab.ui.control.Button
        ConfigurationsLabel             matlab.ui.control.Label
        Label_2                         matlab.ui.control.Label
        ORLabel_2                       matlab.ui.control.Label
        StaticFileUploadonlydooneoffileselectorpastethefilepathLabel  matlab.ui.control.Label
        ORLabel                         matlab.ui.control.Label
        C3DstoProcessUploadLabel        matlab.ui.control.Label
        SelectC3DFilesButton            matlab.ui.control.Button
        Label                           matlab.ui.control.Label
        ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel  matlab.ui.control.Label
        WelcometoAMPLabel               matlab.ui.control.Label
        ConfigurationParametersTab      matlab.ui.container.Tab
        MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel  matlab.ui.control.Label
        Image                           matlab.ui.control.Image
        NumberofTimestoHeavyProcessEditField  matlab.ui.control.NumericEditField
        NumberofTimestoHeavyProcessEditFieldLabel  matlab.ui.control.Label
        PatternCheckThresholdEditField  matlab.ui.control.NumericEditField
        PatternCheckThresholdEditFieldLabel  matlab.ui.control.Label
        GapDetectionThresholdEditField  matlab.ui.control.NumericEditField
        GapDetectionThresholdEditFieldLabel  matlab.ui.control.Label
        JumpSpeedThresholdEditField     matlab.ui.control.NumericEditField
        JumpSpeedThresholdEditFieldLabel  matlab.ui.control.Label
        DefaultJumpThresholdEditField   matlab.ui.control.NumericEditField
        DefaultJumpThresholdEditFieldLabel  matlab.ui.control.Label
        LowpassFilterCutoffEditField    matlab.ui.control.NumericEditField
        LowpassFilterCutoffEditFieldLabel  matlab.ui.control.Label
        CollectionFrequencyHzEditField  matlab.ui.control.NumericEditField
        CollectionFrequencyHzEditFieldLabel  matlab.ui.control.Label
        VerboseDropDown                 matlab.ui.control.DropDown
        VerboseDropDownLabel            matlab.ui.control.Label
        PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel  matlab.ui.control.Label
        C3DContextMenu                  matlab.ui.container.ContextMenu
        RemoveMenu                      matlab.ui.container.Menu
        StaticContextMenu               matlab.ui.container.ContextMenu
        RemoveMenu_2                    matlab.ui.container.Menu
    end

    
    properties (Access = private)
        % selectedOutputFolder = [];
        selectedC3DFiles = {};
        selectedC3DPath = {};
        % selectedCombinedC3Dfilepathname = {};

        % selectedStaticFile = {};
        % selectedStaticPath = {};

        folderPathList = {};
        keepList = {};
        skipList = {};
        % c3dFilePaths = {};  % Initialize empty cell array

        selectedSkipFiles = {};
        selectedSkipPath = {};

        staticFilePathList = {};
        customThresholdsList = {};
        customClusters = {};
        subjects = {};
        
        % C3DsToRun = {};

        % outputFolderPath = {};

        paramStruct = struct();
        useVicon = true;
        ENFfiles = {};
        VSKfiles = {};
        otherFilePaths = {};
    end
    
    methods (Access = private)
        % function filterC3DFiles(app, inputC3Ds)
        %     % inputC3Ds: cell array of full file paths (e.g., from getAllC3DFiles)
        % 
        %     % Get keyword and files to skip
        %     keyword = strtrim(app.EnterKeywordSkipEditField.Value);
        %     if isequal(app.selectedSkipFiles, 0) || isempty(app.selectedSkipFiles)
        %         filesToSkip = {};
        %     else
        %         filesToSkip = combineC3DPathAndName(app, app.selectedSkipPath, app.selectedSkipFiles);  % Full paths
        %     end
        %     filteredList = inputC3Ds;
        % 
        %     % --- Case 1: Skip by keyword (match against filename only) ---
        %     if ~isempty(keyword)
        %         matchIdx = cellfun(@(x) contains(getFileName(app, x), keyword, 'IgnoreCase', true), filteredList);
        %         filteredList = filteredList(~matchIdx);
        % 
        %     % --- Case 2: Skip by selected files (full path match) ---
        %     elseif ~isempty(filesToSkip)
        %         filteredList = setdiff(filteredList, filesToSkip);
        %     end
        % 
        %     % --- Case 3: Skip static files (full path match) ---
        %     if ~isempty(app.staticFilePathList)
        %         filteredList = setdiff(filteredList, app.staticFilePathList);
        %     end
        % 
        %     % Update internal list
        %     app.C3DsToRun = filteredList;
        % end
        
        % Helper function to extract filename from full path
        % function name = getFileName(~, fullPath)
        %     [~, name, ext] = fileparts(fullPath);
        %     name = [name, ext];  % Reconstruct filename with extension
        % end

        % function c3dFilePaths = getAllC3DFiles(app)
        %     c3dFilePaths = {};
        %     % app.ENFfiles = {};
        %     for i = 1:length(app.folderPathList)
        %         folder = app.folderPathList{i};
        % 
        %         % Get all .c3d files in the folder
        %         files = dir(fullfile(folder, '*.c3d'));
        % 
        %         % Build full paths and append
        %         for j = 1:length(files)
        %             fullPath = fullfile(folder, files(j).name);
        %             c3dFilePaths{end+1} = fullPath;
        %         end
        % 
        %         % Get all .enf files
        %         enfFiles = dir(fullfile(folder, '*.enf'));
        %         for j = 1:length(enfFiles)
        %             fullPath = fullfile(enfFiles(j).folder, enfFiles(j).name);
        %             app.ENFfiles{end+1} = fullPath;
        %         end
        % 
        %         % Get all .vsk files
        %         vskFiles = dir(fullfile(folder, '*.vsk'));
        %         for j = 1:length(vskFiles)
        %             fullPath = fullfile(enfFiles(j).folder, vskFiles(j).name);
        %             app.VSKfiles{end+1} = fullPath;
        %         end
        %     end
        % end

        function CombinedFilepathname = combineC3DPathAndName(~, pathString, fileList)
            if ischar(fileList)
                CombinedFilepathname = {[pathString, fileList]};
            else
                for k = 1:length(fileList)
                    CombinedFilepathname(k) = {[pathString, fileList{k}]};
                end
            end
        end

        function staticMatches = findStaticFiles(app, folderPaths)
            staticMatches = {};  % Initialize output list

            keyword = strtrim(app.EnterKeywordStaticEditField.Value); 
            stopFlag = false;

            for i = 1:length(folderPaths)
                try
                    c3dFiles = dir(fullfile(folderPaths{i}, '*.c3d'));
                catch
                    c3dFiles = dir(fullfile(folderPaths, '*.c3d'));
                    stopFlag = true;
                end
                name = {c3dFiles.name};
                fold = {c3dFiles.folder};
                for k = 1:length(name)
                    % [~, name, ext] = fileparts(c3dFiles);
                    % filename = [name, ext];  % Reconstruct filename

                    if contains(name{k}, keyword, 'IgnoreCase', true)
                        staticMatches{end+1} = [fold{k} '\' name{k}];
                    end
                end
                if stopFlag
                    break;
                end
            end
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            Setup();
        end

        % Button pushed function: SelectC3DFilesButton
        function SelectC3DFilesButtonPushed(app, event)
            [app.selectedC3DFiles, app.selectedC3DPath] = uigetfile('MultiSelect', 'on', '*.*');
            % disp(app.selectedC3DFiles);

            if isempty(app.selectedC3DFiles)
                figure(app.UIFigure);
                app.SelectC3DFilestoSkipButton.BackgroundColor = 'white';
                return;
            end

            if ~isequal(app.selectedC3DFiles, 0)
                app.SelectC3DFilesButton.BackgroundColor = 'green';
                % files = dir(fullfile(app.selectedC3DPath, '*.enf'));
                % app.ENFfiles = fullfile({files.folder}, {files.name});
                % 
                % files = dir(fullfile(app.selectedC3DPath, '*.vsk'));
                % app.VSKfiles = fullfile({files.folder}, {files.name});
            end

            figure(app.UIFigure);
        end

        % Button pushed function: RunScriptButton
        function RunScriptButtonPushed(app, event)
            % Setup();
            % app.ErrorLabel.Text = '';
            % drawnow;
            % testTimeApp(app);

            app.Gauge.Value = 0;
            app.ErrorLabel.Text = '';
            app.CurrentlyProcessingLabel.Text = 'Currently Processing: Started';
            drawnow;

            % if we are adding to the C3Ds to process table
            if ~isempty(app.folderPathList)
                % left blank intentionally

            else % if we are using the file select

                % if no files were selected 
                if isequal(app.selectedC3DFiles, false) || isempty(app.selectedC3DFiles)
                    app.folderPathList = {}; 
                else
                    % app.selectedCombinedC3Dfilepathname = combineC3DPathAndName(app, app.selectedC3DPath, app.selectedC3DFiles);
                    % inputC3Ds = app.selectedCombinedC3Dfilepathname;
                    app.folderPathList = app.selectedC3DPath;
                    app.keepList = app.selectedC3DFiles;
                end
            end
            % strStatic = {};

            % if using the keyword function to find a static file
            if isempty(app.staticFilePathList) && ~isempty(strtrim(app.EnterKeywordStaticEditField.Value))
                app.staticFilePathList = findStaticFiles(app, app.folderPathList);
            end

            % Get keyword and files to skip
            keyword = strtrim(app.EnterKeywordSkipEditField.Value);
            if ~isempty(keyword)
                app.skipList = keyword;
            else
                if isequal(app.selectedSkipFiles, 0) || isempty(app.selectedSkipFiles)
                    app.skipList = {};
                else
                    app.skipList = combineC3DPathAndName(app, app.selectedSkipPath, app.selectedSkipFiles);  % Full paths
                end
            end
            
             if strcmpi(app.AutoParamsDropDown.Value, 'True')
                app.paramStruct.autoParams = true;
            else
                app.paramStruct.autoParams = false;
            end

            if strcmpi(app.VerboseDropDown.Value, 'True')
                app.paramStruct.verbose = true;
            else
                app.paramStruct.verbose = false;
            end

            app.paramStruct.cf = app.CollectionFrequencyHzEditField.Value;
            app.paramStruct.lp = app.LowpassFilterCutoffEditField.Value;

            app.paramStruct.defaultJumpThreshold = app.DefaultJumpThresholdEditField.Value; % How far does have to jump in a s ingle frame to be flagged?
            app.paramStruct.jumpSpeedThreshold = app.JumpSpeedThresholdEditField.Value; % How fast does have to jump in a single frame to be flagged?
            app.paramStruct.gap_th = app.GapDetectionThresholdEditField.Value; % gap detection threshold

            app.paramStruct.patternCheckth = app.PatternCheckThresholdEditField.Value;

            app.paramStruct.heavyProcessNum = app.NumberofTimestoHeavyProcessEditField.Value;

            try
                % RunMeCropped(app.selectedC3DFiles, app.selectedC3DPath, ...
                %     [app.selectedStaticPath,app.selectedStaticFile],...
                %     app.JumpThresholdEditField.Value, app.JumpSpeedThresholdEditField.Value, ...
                %     app.GapThresholdEditField.Value, app.CheckThresholdEditField.Value, ...
                %     app.PatternCheckThresholdEditField.Value);
                if length(app.folderPathList) <= 0 
                    app.ErrorLabel.Text = 'No Files To Run';

                    app.CurrentlyProcessingLabel.Text = 'Error!';
                    drawnow;
                elseif isempty(app.staticFilePathList)
                    app.ErrorLabel.Text = 'Please add static file information';

                    app.CurrentlyProcessingLabel.Text = 'Error!';
                    drawnow;
                else
                    app.ErrorLabel.Text = '';

                    app.CurrentlyProcessingLabel.Text = 'Currently Processing: Started';
                    drawnow;

                    Main(app.folderPathList, app.staticFilePathList, app.skipList, app.keepList, app.paramStruct, app.useVicon, app, app.customThresholdsList, app.customClusters, app.subjects)
                    
                    app.Gauge.Value = 100;
                    app.CurrentlyProcessingLabel.Text = 'Finished Processing!';
                    drawnow;
                end

            catch ME
                disp(ME.message);
                for k = 1:length(ME.stack)
                    fprintf('Error in %s at line %d in file %s\n', ...
                        ME.stack(k).name, ME.stack(k).line, ME.stack(k).file);
                end

                errordlg(ME.message);
                app.ErrorLabel.Text = 'ERROR';

            end
        end

        % Button pushed function: AddC3DFolderPathButton
        function AddC3DFolderPathButtonPushed(app, event)
            app.folderPathList = [app.folderPathList, app.C3DFolderPathEditField.Value];
            app.C3DFolderPathsTable.Data = app.folderPathList';
        end

        % Button pushed function: SelectC3DFilestoSkipButton
        function SelectC3DFilestoSkipButtonPushed(app, event)
            [app.selectedSkipFiles, app.selectedSkipPath] = uigetfile('MultiSelect', 'on', '*.*');

            if isempty(app.selectedSkipFiles)
                figure(app.UIFigure);
                app.SelectC3DFilestoSkipButton.BackgroundColor = 'white';
                return;
            end
            if ~isequal(app.selectedSkipFiles, 0)
                app.SelectC3DFilestoSkipButton.BackgroundColor = 'green';
            end

            % disp('g');
            figure(app.UIFigure);
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            selectedButton = app.ButtonGroup.SelectedObject;

            selectedText = selectedButton.Text;
            % disp(selectedText);
            % errordlg(selectedButton);

            if strcmp(selectedText, 'Vicon Free Processing')
                app.useVicon = false;
            else
                app.useVicon = true;
            end
        end

        % Button pushed function: AddStaticFilePathButton
        function AddStaticFilePathButtonPushed(app, event)
            app.staticFilePathList = [app.staticFilePathList, app.StaticFilePathEditField.Value];
            app.StaticFilePathsTable.Data = app.staticFilePathList';
        end

        % Menu selected function: RemoveMenu
        function RemoveMenuSelectedC3D(app, event)
            % Get selected row index
            selectedRow = app.C3DFolderPathsTable.Selection;
            
            if ~isempty(selectedRow)
                rowIdx = selectedRow(1);  % Only care about row index
        
                % Remove from folderPathList
                app.folderPathList(rowIdx) = [];
        
                % Update table
                app.C3DFolderPathsTable.Data = app.folderPathList';
            end
        end

        % Menu selected function: RemoveMenu_2
        function RemoveMenuSelectedStatic(app, event)
            % Get selected row index
            selectedRow = app.StaticFilePathsTable.Selection;
            
            if ~isempty(selectedRow)
                rowIdx = selectedRow(1);  % Only care about row index
        
                % Remove from folderPathList
                app.staticFilePathList(rowIdx) = [];
        
                % Update table
                app.StaticFilePathsTable.Data = app.staticFilePathList';
            end
        end

        % Button pushed function: AddCustomThresholds
        function AddCustomThresholdsButtonPushed(app, event)
            [app.customThresholdsList] = uigetfile('*.*');
            fileText = fileread(app.customThresholdsList);
            eval(fileText);

            [app.customThresholdsList] = custom_jump_thresholds;
            [app.customClusters]  = custom_clusters;
            [app.subjects] = subjects;

            if isempty(app.customThresholdsList)
                figure(app.UIFigure);
                app.AddCustomThresholds.BackgroundColor = 'white';
                return;
            end
            if ~isequal(app.customThresholdsList, 0)
                app.AddCustomThresholds.BackgroundColor = 'green';
            end

            % disp('g');
            figure(app.UIFigure);
        end

        % Clicked callback: AutoParamsDropDown
        function AutoParamsDropDownClicked(app, event)
            item = event.InteractionInformation.Item;
            
            if strcmpi(app.AutoParamsDropDown.Value, 'True')
                app.paramStruct.autoParams = true;

                app.FalseAutoParamLabel.Visible = false;
                app.AddCustomThresholds.Visible = false;
            else
                app.paramStruct.autoParams = false;

                app.FalseAutoParamLabel.Visible = true;
                app.AddCustomThresholds.Visible = true;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.749 0.8196 0.8706];
            app.UIFigure.Position = [100 50 649 743];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 649 742];

            % Create FileSetupTab
            app.FileSetupTab = uitab(app.TabGroup);
            app.FileSetupTab.Title = 'File Setup';
            app.FileSetupTab.BackgroundColor = [0.749 0.8196 0.8706];

            % Create WelcometoAMPLabel
            app.WelcometoAMPLabel = uilabel(app.FileSetupTab);
            app.WelcometoAMPLabel.HorizontalAlignment = 'center';
            app.WelcometoAMPLabel.FontSize = 18;
            app.WelcometoAMPLabel.Position = [123 686 403 33];
            app.WelcometoAMPLabel.Text = 'Welcome to AMP!';

            % Create ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel = uilabel(app.FileSetupTab);
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.HorizontalAlignment = 'center';
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.VerticalAlignment = 'top';
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.WordWrap = 'on';
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.FontWeight = 'bold';
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.Position = [10 656 637 35];
            app.ThisistheAutomaticMoCapPipelinedesignedtoincreaseLabel.Text = {'This is the Automatic MoCap Pipeline designed to efficiently and easily process your motion capture data and repair any gaps or mislabeling. Please follow the prompts below and hover over feautres for more details:'; ''};

            % Create Label
            app.Label = uilabel(app.FileSetupTab);
            app.Label.Position = [15 652 617 15];
            app.Label.Text = '------------------------------------------------------------------------------------------------------------------------------------------------------';

            % Create SelectC3DFilesButton
            app.SelectC3DFilesButton = uibutton(app.FileSetupTab, 'push');
            app.SelectC3DFilesButton.ButtonPushedFcn = createCallbackFcn(app, @SelectC3DFilesButtonPushed, true);
            app.SelectC3DFilesButton.Tooltip = {'Selected files must be from the same folder.'};
            app.SelectC3DFilesButton.Position = [12 567 129 23];
            app.SelectC3DFilesButton.Text = 'Select C3D Files';

            % Create C3DstoProcessUploadLabel
            app.C3DstoProcessUploadLabel = uilabel(app.FileSetupTab);
            app.C3DstoProcessUploadLabel.FontSize = 14;
            app.C3DstoProcessUploadLabel.FontWeight = 'bold';
            app.C3DstoProcessUploadLabel.Position = [16 595 521 25];
            app.C3DstoProcessUploadLabel.Text = 'C3Ds to Process Upload (only do one of file select or paste the folder paths)';

            % Create ORLabel
            app.ORLabel = uilabel(app.FileSetupTab);
            app.ORLabel.HorizontalAlignment = 'center';
            app.ORLabel.FontSize = 14;
            app.ORLabel.FontWeight = 'bold';
            app.ORLabel.Position = [139 568 46 22];
            app.ORLabel.Text = 'OR';

            % Create StaticFileUploadonlydooneoffileselectorpastethefilepathLabel
            app.StaticFileUploadonlydooneoffileselectorpastethefilepathLabel = uilabel(app.FileSetupTab);
            app.StaticFileUploadonlydooneoffileselectorpastethefilepathLabel.FontSize = 14;
            app.StaticFileUploadonlydooneoffileselectorpastethefilepathLabel.FontWeight = 'bold';
            app.StaticFileUploadonlydooneoffileselectorpastethefilepathLabel.Position = [12 379 509 25];
            app.StaticFileUploadonlydooneoffileselectorpastethefilepathLabel.Text = 'Static File Upload (only do one of keyword detection or paste the file path)';

            % Create ORLabel_2
            app.ORLabel_2 = uilabel(app.FileSetupTab);
            app.ORLabel_2.HorizontalAlignment = 'center';
            app.ORLabel_2.FontSize = 14;
            app.ORLabel_2.FontWeight = 'bold';
            app.ORLabel_2.Position = [241 352 46 22];
            app.ORLabel_2.Text = 'OR';

            % Create Label_2
            app.Label_2 = uilabel(app.FileSetupTab);
            app.Label_2.Position = [11 240 617 15];
            app.Label_2.Text = '------------------------------------------------------------------------------------------------------------------------------------------------------';

            % Create ConfigurationsLabel
            app.ConfigurationsLabel = uilabel(app.FileSetupTab);
            app.ConfigurationsLabel.FontSize = 14;
            app.ConfigurationsLabel.FontWeight = 'bold';
            app.ConfigurationsLabel.Position = [8 216 122 25];
            app.ConfigurationsLabel.Text = 'Configurations';

            % Create RunScriptButton
            app.RunScriptButton = uibutton(app.FileSetupTab, 'push');
            app.RunScriptButton.ButtonPushedFcn = createCallbackFcn(app, @RunScriptButtonPushed, true);
            app.RunScriptButton.Position = [276 90 100 23];
            app.RunScriptButton.Text = 'Run Script';

            % Create Label_3
            app.Label_3 = uilabel(app.FileSetupTab);
            app.Label_3.Position = [12 76 617 15];
            app.Label_3.Text = '------------------------------------------------------------------------------------------------------------------------------------------------------';

            % Create ProgressBarsLabel
            app.ProgressBarsLabel = uilabel(app.FileSetupTab);
            app.ProgressBarsLabel.FontSize = 14;
            app.ProgressBarsLabel.FontWeight = 'bold';
            app.ProgressBarsLabel.Position = [12 52 122 25];
            app.ProgressBarsLabel.Text = 'Progress Bars';

            % Create Gauge
            app.Gauge = uigauge(app.FileSetupTab, 'linear');
            app.Gauge.Position = [159 12 415 41];

            % Create CurrentlyProcessingLabel
            app.CurrentlyProcessingLabel = uilabel(app.FileSetupTab);
            app.CurrentlyProcessingLabel.FontSize = 18;
            app.CurrentlyProcessingLabel.Position = [159 52 486 23];
            app.CurrentlyProcessingLabel.Text = 'Currently Processing: ';

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.FileSetupTab);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.Position = [16 620 612 34];

            % Create HaveastaticfileandhavealreadyrunthereconstructpipelineButton
            app.HaveastaticfileandhavealreadyrunthereconstructpipelineButton = uiradiobutton(app.ButtonGroup);
            app.HaveastaticfileandhavealreadyrunthereconstructpipelineButton.Text = 'Have a static file and have already run the reconstruct pipeline';
            app.HaveastaticfileandhavealreadyrunthereconstructpipelineButton.Position = [17 5 359 22];
            app.HaveastaticfileandhavealreadyrunthereconstructpipelineButton.Value = true;

            % Create ViconFreeProcessingButton
            app.ViconFreeProcessingButton = uiradiobutton(app.ButtonGroup);
            app.ViconFreeProcessingButton.Text = 'Vicon Free Processing';
            app.ViconFreeProcessingButton.Position = [448 5 143 22];

            % Create C3DFolderPathsTable
            app.C3DFolderPathsTable = uitable(app.FileSetupTab);
            app.C3DFolderPathsTable.ColumnName = {'Folder Paths'};
            app.C3DFolderPathsTable.RowName = {};
            app.C3DFolderPathsTable.Position = [158 464 470 91];

            % Create AddC3DFolderPathButton
            app.AddC3DFolderPathButton = uibutton(app.FileSetupTab, 'push');
            app.AddC3DFolderPathButton.ButtonPushedFcn = createCallbackFcn(app, @AddC3DFolderPathButtonPushed, true);
            app.AddC3DFolderPathButton.Position = [525 567 102 23];
            app.AddC3DFolderPathButton.Text = 'Add Folder Path';

            % Create C3DstoProcessUploadLabel_2
            app.C3DstoProcessUploadLabel_2 = uilabel(app.FileSetupTab);
            app.C3DstoProcessUploadLabel_2.FontSize = 14;
            app.C3DstoProcessUploadLabel_2.FontWeight = 'bold';
            app.C3DstoProcessUploadLabel_2.Position = [12 440 521 25];
            app.C3DstoProcessUploadLabel_2.Text = 'C3Ds to Skip (only do one of file select or keyword detection)';

            % Create SelectC3DFilestoSkipButton
            app.SelectC3DFilestoSkipButton = uibutton(app.FileSetupTab, 'push');
            app.SelectC3DFilestoSkipButton.ButtonPushedFcn = createCallbackFcn(app, @SelectC3DFilestoSkipButtonPushed, true);
            app.SelectC3DFilestoSkipButton.Tooltip = {'Selected files must be from the same folder.'};
            app.SelectC3DFilestoSkipButton.Position = [7 412 144 23];
            app.SelectC3DFilestoSkipButton.Text = 'Select C3D Files to Skip';

            % Create ORLabel_3
            app.ORLabel_3 = uilabel(app.FileSetupTab);
            app.ORLabel_3.HorizontalAlignment = 'center';
            app.ORLabel_3.FontSize = 14;
            app.ORLabel_3.FontWeight = 'bold';
            app.ORLabel_3.Position = [159 413 46 22];
            app.ORLabel_3.Text = 'OR';

            % Create AddStaticFilePathButton
            app.AddStaticFilePathButton = uibutton(app.FileSetupTab, 'push');
            app.AddStaticFilePathButton.ButtonPushedFcn = createCallbackFcn(app, @AddStaticFilePathButtonPushed, true);
            app.AddStaticFilePathButton.Position = [528 351 100 23];
            app.AddStaticFilePathButton.Text = 'Add File Path';

            % Create StaticFilePathsTable
            app.StaticFilePathsTable = uitable(app.FileSetupTab);
            app.StaticFilePathsTable.ColumnName = {'File Paths'};
            app.StaticFilePathsTable.RowName = {};
            app.StaticFilePathsTable.Position = [158 254 470 91];

            % Create ErrorLabel
            app.ErrorLabel = uilabel(app.FileSetupTab);
            app.ErrorLabel.WordWrap = 'on';
            app.ErrorLabel.Position = [15 12 129 31];
            app.ErrorLabel.Text = '';

            % Create FolderPathEditFieldLabel
            app.FolderPathEditFieldLabel = uilabel(app.FileSetupTab);
            app.FolderPathEditFieldLabel.HorizontalAlignment = 'right';
            app.FolderPathEditFieldLabel.Position = [177 567 67 22];
            app.FolderPathEditFieldLabel.Text = 'Folder Path';

            % Create C3DFolderPathEditField
            app.C3DFolderPathEditField = uieditfield(app.FileSetupTab, 'text');
            app.C3DFolderPathEditField.Tooltip = {'Enter a folder path and hit add between entries. If there is an entry in this field, the file select will be ignored. '};
            app.C3DFolderPathEditField.Position = [259 567 254 22];

            % Create EnterKeywordEditFieldLabel
            app.EnterKeywordEditFieldLabel = uilabel(app.FileSetupTab);
            app.EnterKeywordEditFieldLabel.HorizontalAlignment = 'right';
            app.EnterKeywordEditFieldLabel.Position = [221 413 87 22];
            app.EnterKeywordEditFieldLabel.Text = 'Enter Keyword ';

            % Create EnterKeywordSkipEditField
            app.EnterKeywordSkipEditField = uieditfield(app.FileSetupTab, 'text');
            app.EnterKeywordSkipEditField.Tooltip = {'If there is a consistent substring that occurs in files you want to skip, enter it into this field. If there is an entry in this field, the file select will be ignored. '};
            app.EnterKeywordSkipEditField.Position = [323 413 190 22];

            % Create EnterKeywordEditField_2Label
            app.EnterKeywordEditField_2Label = uilabel(app.FileSetupTab);
            app.EnterKeywordEditField_2Label.HorizontalAlignment = 'right';
            app.EnterKeywordEditField_2Label.Position = [17 352 87 22];
            app.EnterKeywordEditField_2Label.Text = 'Enter Keyword ';

            % Create EnterKeywordStaticEditField
            app.EnterKeywordStaticEditField = uieditfield(app.FileSetupTab, 'text');
            app.EnterKeywordStaticEditField.Tooltip = {'If there is a consistent substring that occurs in static files, enter it into this field. '};
            app.EnterKeywordStaticEditField.Position = [119 352 123 22];

            % Create FilePathLabel
            app.FilePathLabel = uilabel(app.FileSetupTab);
            app.FilePathLabel.HorizontalAlignment = 'right';
            app.FilePathLabel.Position = [285 352 52 22];
            app.FilePathLabel.Text = 'File Path';

            % Create StaticFilePathEditField
            app.StaticFilePathEditField = uieditfield(app.FileSetupTab, 'text');
            app.StaticFilePathEditField.Tooltip = {'Enter a folder path and hit add between entries. If there is an entry in this field, the keyword will be ignored. '};
            app.StaticFilePathEditField.Position = [352 352 168 22];

            % Create AddCustomThresholds
            app.AddCustomThresholds = uibutton(app.FileSetupTab, 'push');
            app.AddCustomThresholds.ButtonPushedFcn = createCallbackFcn(app, @AddCustomThresholdsButtonPushed, true);
            app.AddCustomThresholds.Visible = 'off';
            app.AddCustomThresholds.Position = [392 138 144 23];
            app.AddCustomThresholds.Text = 'Add Custom Thresholds';

            % Create FalseAutoParamLabel
            app.FalseAutoParamLabel = uilabel(app.FileSetupTab);
            app.FalseAutoParamLabel.HorizontalAlignment = 'center';
            app.FalseAutoParamLabel.WordWrap = 'on';
            app.FalseAutoParamLabel.Visible = 'off';
            app.FalseAutoParamLabel.Position = [353 164 222 44];
            app.FalseAutoParamLabel.Text = 'If you selected false for Auto Params, please upload your .txt file of your custom thresholds.';

            % Create AutoParamsDropDownLabel
            app.AutoParamsDropDownLabel = uilabel(app.FileSetupTab);
            app.AutoParamsDropDownLabel.Position = [18 187 91 22];
            app.AutoParamsDropDownLabel.Text = 'Auto Params';

            % Create AutoParamsDropDown
            app.AutoParamsDropDown = uidropdown(app.FileSetupTab);
            app.AutoParamsDropDown.Items = {'False', 'True'};
            app.AutoParamsDropDown.Tooltip = {'Set to True if you want to automatically detect cluster jump thresholds.'};
            app.AutoParamsDropDown.ClickedFcn = createCallbackFcn(app, @AutoParamsDropDownClicked, true);
            app.AutoParamsDropDown.Position = [126 187 77 22];
            app.AutoParamsDropDown.Value = 'True';

            % Create ConfigurationParametersTab
            app.ConfigurationParametersTab = uitab(app.TabGroup);
            app.ConfigurationParametersTab.Title = 'Configuration Parameters';
            app.ConfigurationParametersTab.BackgroundColor = [0.749 0.8196 0.8706];

            % Create PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel = uilabel(app.ConfigurationParametersTab);
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel.HorizontalAlignment = 'center';
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel.WordWrap = 'on';
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel.FontWeight = 'bold';
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel.Position = [59 665 531 38];
            app.PleasechangeanyconfigurationparametersyouwantorleaveasisHoveroverthelabelsofeachparametertolearnmoreLabel.Text = 'Please change any configuration parameters you want or leave as is. Hover over the labels of each parameter to learn more.';

            % Create VerboseDropDownLabel
            app.VerboseDropDownLabel = uilabel(app.ConfigurationParametersTab);
            app.VerboseDropDownLabel.Position = [33 600 91 22];
            app.VerboseDropDownLabel.Text = 'Verbose';

            % Create VerboseDropDown
            app.VerboseDropDown = uidropdown(app.ConfigurationParametersTab);
            app.VerboseDropDown.Items = {'False', 'True'};
            app.VerboseDropDown.Tooltip = {'Set to True if you want to see all processing steps (useful for debugging)'};
            app.VerboseDropDown.Position = [141 600 77 22];
            app.VerboseDropDown.Value = 'False';

            % Create CollectionFrequencyHzEditFieldLabel
            app.CollectionFrequencyHzEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.CollectionFrequencyHzEditFieldLabel.VerticalAlignment = 'top';
            app.CollectionFrequencyHzEditFieldLabel.WordWrap = 'on';
            app.CollectionFrequencyHzEditFieldLabel.Position = [32 542 94 47];
            app.CollectionFrequencyHzEditFieldLabel.Text = 'Collection Frequency (Hz)';

            % Create CollectionFrequencyHzEditField
            app.CollectionFrequencyHzEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.CollectionFrequencyHzEditField.Tooltip = {'Input the collection frequency of your MoCap'};
            app.CollectionFrequencyHzEditField.Position = [140 567 77 22];
            app.CollectionFrequencyHzEditField.Value = 200;

            % Create LowpassFilterCutoffEditFieldLabel
            app.LowpassFilterCutoffEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.LowpassFilterCutoffEditFieldLabel.VerticalAlignment = 'top';
            app.LowpassFilterCutoffEditFieldLabel.WordWrap = 'on';
            app.LowpassFilterCutoffEditFieldLabel.Position = [33 496 93 47];
            app.LowpassFilterCutoffEditFieldLabel.Text = 'Lowpass Filter Cutoff';

            % Create LowpassFilterCutoffEditField
            app.LowpassFilterCutoffEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.LowpassFilterCutoffEditField.Tooltip = {'Lowpass filter cutoff frequency (6 is standard, consider raising if you have high frequency tasks)'};
            app.LowpassFilterCutoffEditField.Position = [139 521 79 22];
            app.LowpassFilterCutoffEditField.Value = 6;

            % Create DefaultJumpThresholdEditFieldLabel
            app.DefaultJumpThresholdEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.DefaultJumpThresholdEditFieldLabel.VerticalAlignment = 'top';
            app.DefaultJumpThresholdEditFieldLabel.WordWrap = 'on';
            app.DefaultJumpThresholdEditFieldLabel.Position = [33 450 93 47];
            app.DefaultJumpThresholdEditFieldLabel.Text = 'Default Jump Threshold';

            % Create DefaultJumpThresholdEditField
            app.DefaultJumpThresholdEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.DefaultJumpThresholdEditField.Tooltip = {'How far does marker have to jump in a single frame to be flagged?'};
            app.DefaultJumpThresholdEditField.Position = [138 475 80 22];
            app.DefaultJumpThresholdEditField.Value = 50;

            % Create JumpSpeedThresholdEditFieldLabel
            app.JumpSpeedThresholdEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.JumpSpeedThresholdEditFieldLabel.VerticalAlignment = 'top';
            app.JumpSpeedThresholdEditFieldLabel.WordWrap = 'on';
            app.JumpSpeedThresholdEditFieldLabel.Position = [31 408 93 47];
            app.JumpSpeedThresholdEditFieldLabel.Text = 'Jump Speed Threshold';

            % Create JumpSpeedThresholdEditField
            app.JumpSpeedThresholdEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.JumpSpeedThresholdEditField.Tooltip = {'How fast does marker have to jump in a single frame to be flagged?'};
            app.JumpSpeedThresholdEditField.Position = [138 433 78 22];
            app.JumpSpeedThresholdEditField.Value = 7.5;

            % Create GapDetectionThresholdEditFieldLabel
            app.GapDetectionThresholdEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.GapDetectionThresholdEditFieldLabel.VerticalAlignment = 'top';
            app.GapDetectionThresholdEditFieldLabel.WordWrap = 'on';
            app.GapDetectionThresholdEditFieldLabel.Position = [31 367 93 47];
            app.GapDetectionThresholdEditFieldLabel.Text = 'Gap Detection Threshold';

            % Create GapDetectionThresholdEditField
            app.GapDetectionThresholdEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.GapDetectionThresholdEditField.Tooltip = {''};
            app.GapDetectionThresholdEditField.Position = [139 392 77 22];
            app.GapDetectionThresholdEditField.Value = 15;

            % Create PatternCheckThresholdEditFieldLabel
            app.PatternCheckThresholdEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.PatternCheckThresholdEditFieldLabel.VerticalAlignment = 'top';
            app.PatternCheckThresholdEditFieldLabel.WordWrap = 'on';
            app.PatternCheckThresholdEditFieldLabel.Position = [31 327 93 47];
            app.PatternCheckThresholdEditFieldLabel.Text = 'Pattern Check Threshold';

            % Create PatternCheckThresholdEditField
            app.PatternCheckThresholdEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.PatternCheckThresholdEditField.Position = [138 352 78 22];
            app.PatternCheckThresholdEditField.Value = 5;

            % Create NumberofTimestoHeavyProcessEditFieldLabel
            app.NumberofTimestoHeavyProcessEditFieldLabel = uilabel(app.ConfigurationParametersTab);
            app.NumberofTimestoHeavyProcessEditFieldLabel.VerticalAlignment = 'top';
            app.NumberofTimestoHeavyProcessEditFieldLabel.WordWrap = 'on';
            app.NumberofTimestoHeavyProcessEditFieldLabel.Position = [31 286 98 47];
            app.NumberofTimestoHeavyProcessEditFieldLabel.Text = 'Number of Times to Heavy Process ';

            % Create NumberofTimestoHeavyProcessEditField
            app.NumberofTimestoHeavyProcessEditField = uieditfield(app.ConfigurationParametersTab, 'numeric');
            app.NumberofTimestoHeavyProcessEditField.Tooltip = {'Number of times heavy relabelling processes will be done'};
            app.NumberofTimestoHeavyProcessEditField.Position = [142 311 73 22];
            app.NumberofTimestoHeavyProcessEditField.Value = 2;

            % Create Image
            app.Image = uiimage(app.ConfigurationParametersTab);
            app.Image.Position = [204 124 250 196];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'epic pic.png');

            % Create MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel
            app.MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel = uilabel(app.ConfigurationParametersTab);
            app.MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel.FontWeight = 'bold';
            app.MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel.Position = [143 116 392 22];
            app.MadebySixuJasonZhouRyanCaseyandJosephJoeyWalterLabel.Text = 'Made by Sixu (Jason) Zhou, Ryan Casey, and Joseph (Joey) Walter';

            % Create C3DContextMenu
            app.C3DContextMenu = uicontextmenu(app.UIFigure);

            % Create RemoveMenu
            app.RemoveMenu = uimenu(app.C3DContextMenu);
            app.RemoveMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveMenuSelectedC3D, true);
            app.RemoveMenu.Text = 'Remove';
            
            % Assign app.C3DContextMenu
            app.C3DFolderPathsTable.ContextMenu = app.C3DContextMenu;

            % Create StaticContextMenu
            app.StaticContextMenu = uicontextmenu(app.UIFigure);

            % Create RemoveMenu_2
            app.RemoveMenu_2 = uimenu(app.StaticContextMenu);
            app.RemoveMenu_2.MenuSelectedFcn = createCallbackFcn(app, @RemoveMenuSelectedStatic, true);
            app.RemoveMenu_2.Text = 'Remove';
            
            % Assign app.StaticContextMenu
            app.StaticFilePathsTable.ContextMenu = app.StaticContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI_Tool_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end