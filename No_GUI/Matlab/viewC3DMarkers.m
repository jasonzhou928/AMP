function fig = viewC3DMarkers(c3dFile)
%VIEWC3DMARKERS Interactively inspect labeled C3D markers over time.
%
%   viewC3DMarkers
%   viewC3DMarkers("trial_preprocessed.c3d")
%
% The left axes animate marker positions and labels. Select a marker in the
% list to show its X/Y/Z trajectories on the right.

rootDir = fileparts(mfilename('fullpath'));
if exist('Vicon.ExtractMarkers_multiSubs','file') == 0
    addpath(genpath(fullfile(rootDir,'MoCapTools')));
end

if nargin < 1 || isempty(c3dFile)
    [fileName,filePath] = uigetfile('*.c3d','Select a C3D file');
    if isequal(fileName,0)
        fig = [];
        return
    end
    c3dFile = fullfile(filePath,fileName);
end
c3dFile = char(c3dFile);

markerNames = {};
X = [];
Y = [];
Z = [];
headers = [];
time = [];
frequency = 1;
currentFrame = 1;
playing = false;
labelHandles = gobjects(0);
labelIndices = [];
labelVisible = false(0,1);
playTimer = [];
isUpdating = false;
sliderDragging = false;
playPeriod = 0.033;
playAnchorFrame = 1;
playClock = tic;

fig = uifigure('Name','C3D Marker Viewer', ...
    'Position',[80 80 1450 820], ...
    'Color',[0.97 0.97 0.97]);
fig.CloseRequestFcn = @closeViewer;
fig.DeleteFcn = @cleanupViewer;

mainGrid = uigridlayout(fig,[2 3]);
mainGrid.ColumnWidth = {'3x','2x',240};
mainGrid.RowHeight = {'1x',96};
mainGrid.Padding = [10 10 10 10];
mainGrid.RowSpacing = 8;
mainGrid.ColumnSpacing = 8;

ax3d = uiaxes(mainGrid);
ax3d.Layout.Row = 1;
ax3d.Layout.Column = 1;
hold(ax3d,'on');
grid(ax3d,'on');
axis(ax3d,'equal');
view(ax3d,3);
xlabel(ax3d,'X (mm)');
ylabel(ax3d,'Y (mm)');
zlabel(ax3d,'Z (mm)');

axTime = uiaxes(mainGrid);
axTime.Layout.Row = 1;
axTime.Layout.Column = 2;
hold(axTime,'on');
grid(axTime,'on');
xlabel(axTime,'Time (s)');
ylabel(axTime,'Position (mm)');

sidePanel = uipanel(mainGrid,'Title','Markers');
sidePanel.Layout.Row = 1;
sidePanel.Layout.Column = 3;
sideGrid = uigridlayout(sidePanel,[9 1]);
sideGrid.RowHeight = {24,30,24,30,'1x',24,24,24,30};
sideGrid.Padding = [8 8 8 8];

fileLabel = uilabel(sideGrid,'Text','No file loaded', ...
    'Interpreter','none','FontWeight','bold');

openButton = uibutton(sideGrid,'Text','Open C3D...', ...
    'ButtonPushedFcn',@openFile);

searchLabel = uilabel(sideGrid,'Text','Filter marker names');

searchField = uieditfield(sideGrid,'text', ...
    'Placeholder','e.g. R_TH', ...
    'ValueChangedFcn',@refreshMarkerList);

markerList = uilistbox(sideGrid, ...
    'ValueChangedFcn',@markerSelectionChanged);

showLabelsBox = uicheckbox(sideGrid,'Text','Show marker labels', ...
    'Value',true,'ValueChangedFcn',@labelOptionsChanged);

showUnlabeledBox = uicheckbox(sideGrid,'Text','Show unlabeled C_/U markers', ...
    'Value',false,'ValueChangedFcn',@unlabeledOptionChanged);

trailBox = uicheckbox(sideGrid,'Text','Show selected marker trail', ...
    'Value',true,'ValueChangedFcn',@updateFrame);

trailGrid = uigridlayout(sideGrid,[1 2]);
trailGrid.ColumnWidth = {'1x',75};
trailGrid.Padding = [0 0 0 0];
uilabel(trailGrid,'Text','Trail frames');
trailSpinner = uispinner(trailGrid,'Limits',[1 1000], ...
    'Step',10,'Value',100,'ValueChangedFcn',@updateFrame);

bottomPanel = uipanel(mainGrid);
bottomPanel.Layout.Row = 2;
bottomPanel.Layout.Column = [1 3];
bottomGrid = uigridlayout(bottomPanel,[2 7]);
bottomGrid.ColumnWidth = {72,72,'1x',100,75,95,180};
bottomGrid.RowHeight = {32,28};
bottomGrid.Padding = [8 5 8 5];

playButton = uibutton(bottomGrid,'Text','Play', ...
    'ButtonPushedFcn',@togglePlay);
playButton.Layout.Row = 1;
playButton.Layout.Column = 1;

stepBackButton = uibutton(bottomGrid,'Text','< Frame', ...
    'ButtonPushedFcn',@(~,~) stepFrame(-1));
stepBackButton.Layout.Row = 1;
stepBackButton.Layout.Column = 2;

frameSlider = uislider(bottomGrid,'Limits',[1 2],'Value',1, ...
    'MajorTicks',[],'ValueChangingFcn',@sliderMoving, ...
    'ValueChangedFcn',@sliderChanged);
frameSlider.Layout.Row = 1;
frameSlider.Layout.Column = 3;

frameSpinner = uispinner(bottomGrid,'Limits',[1 2], ...
    'RoundFractionalValues','on','Step',1,'Value',1, ...
    'ValueChangedFcn',@spinnerChanged);
frameSpinner.Layout.Row = 1;
frameSpinner.Layout.Column = 4;

stepForwardButton = uibutton(bottomGrid,'Text','Frame >', ...
    'ButtonPushedFcn',@(~,~) stepFrame(1));
stepForwardButton.Layout.Row = 1;
stepForwardButton.Layout.Column = 5;

speedDropDown = uidropdown(bottomGrid, ...
    'Items',{'0.25x','0.5x','1x','2x','4x'}, ...
    'ItemsData',[0.25 0.5 1 2 4],'Value',1, ...
    'ValueChangedFcn',@speedChanged);
speedDropDown.Layout.Row = 1;
speedDropDown.Layout.Column = 6;

frameLabel = uilabel(bottomGrid,'Text','Frame - | Time -', ...
    'HorizontalAlignment','right');
frameLabel.Layout.Row = 1;
frameLabel.Layout.Column = 7;

statusLabel = uilabel(bottomGrid,'Text','', ...
    'Interpreter','none','FontColor',[0.25 0.25 0.25]);
statusLabel.Layout.Row = 2;
statusLabel.Layout.Column = [1 7];

labeledScatter = scatter3(ax3d,nan,nan,nan,35, ...
    [0.10 0.45 0.90],'filled','DisplayName','Labeled');
unlabeledScatter = scatter3(ax3d,nan,nan,nan,25, ...
    [0.95 0.55 0.10],'filled','DisplayName','Unlabeled');
selectedScatter = scatter3(ax3d,nan,nan,nan,90, ...
    [0.90 0.10 0.15],'LineWidth',1.5,'DisplayName','Selected');
trailLine = plot3(ax3d,nan,nan,nan,'-','Color',[0.90 0.10 0.15], ...
    'LineWidth',1.5,'DisplayName','Trail');
legend(ax3d,'Location','northeast');

timeLineX = plot(axTime,nan,nan,'LineWidth',1.1,'DisplayName','X');
timeLineY = plot(axTime,nan,nan,'LineWidth',1.1,'DisplayName','Y');
timeLineZ = plot(axTime,nan,nan,'LineWidth',1.1,'DisplayName','Z');
timeCursor = xline(axTime,0,'k--','LineWidth',1);
legend(axTime,[timeLineX timeLineY timeLineZ],'Location','northeast');
title(axTime,'Select a marker');

loadFile(c3dFile);

    function loadFile(filePath)
        stopPlaying();
        statusLabel.Text = ['Loading ' filePath ' ...'];
        drawnow;
        try
            h = btkReadAcquisition(filePath);
            frequency = btkGetPointFrequency(h);
            btkCloseAcquisition(h);
            markerStruct = Vicon.ExtractMarkers_multiSubs(filePath,false);
        catch ME
            statusLabel.Text = 'Unable to load C3D file.';
            uialert(fig,ME.message,'C3D load failed');
            return
        end

        names = fieldnames(markerStruct);
        if isempty(names)
            statusLabel.Text = 'The C3D contains no markers.';
            uialert(fig,'The selected C3D contains no markers.','No marker data');
            return
        end

        nFrames = height(markerStruct.(names{1}));
        newX = nan(nFrames,numel(names));
        newY = nan(nFrames,numel(names));
        newZ = nan(nFrames,numel(names));
        for markerIndex = 1:numel(names)
            markerTable = markerStruct.(names{markerIndex});
            newX(:,markerIndex) = markerTable.x;
            newY(:,markerIndex) = markerTable.y;
            newZ(:,markerIndex) = markerTable.z;
        end

        hasData = any(~isnan(newX),1);
        markerNames = names(hasData);
        X = newX(:,hasData);
        Y = newY(:,hasData);
        Z = newZ(:,hasData);
        headers = markerStruct.(names{1}).Header;
        time = (headers - headers(1)) / frequency;
        currentFrame = 1;

        [~,shortName,extension] = fileparts(filePath);
        fileLabel.Text = [shortName extension];
        fig.Name = ['C3D Marker Viewer - ' shortName extension];

        % Values are reset before Limits because a Value outside the new
        % Limits is rejected by the component.
        frameSlider.Value = 1;
        frameSlider.Limits = [1 max(2,nFrames)];
        frameSpinner.Value = 1;
        frameSpinner.Limits = [1 max(2,nFrames)];
        trailSpinner.Value = 1;
        trailSpinner.Limits = [1 max(2,nFrames)];
        trailSpinner.Value = max(1,min(100,nFrames));

        setAxisLimits();
        rebuildLabels();
        refreshMarkerList();
        updateTimePlot();
        updateFrame();
        statusLabel.Text = sprintf('%d frames | %.2f Hz | %d markers', ...
            nFrames,frequency,numel(markerNames));
    end

    function openFile(~,~)
        [fileName,filePath] = uigetfile('*.c3d','Select a C3D file');
        if ~isequal(fileName,0)
            loadFile(fullfile(filePath,fileName));
        end
    end

    function refreshMarkerList(~,~)
        if isempty(markerNames)
            markerList.Items = {};
            return
        end
        allowed = true(size(markerNames));
        if ~showUnlabeledBox.Value
            allowed = ~isUnlabeled(markerNames);
        end
        filterText = strtrim(searchField.Value);
        if ~isempty(filterText)
            allowed = allowed & contains(markerNames,filterText,'IgnoreCase',true);
        end
        displayedNames = markerNames(allowed);
        previousValue = markerList.Value;
        markerList.Items = displayedNames;
        if isempty(displayedNames)
            markerList.Value = {};
        elseif isempty(previousValue) || ~any(strcmp(displayedNames,previousValue))
            markerList.Value = displayedNames{1};
        else
            markerList.Value = previousValue;
        end
        if ~isequal(markerList.Value,previousValue)
            updateTimePlot();
            updateFrame();
        end
    end

    function markerSelectionChanged(~,~)
        updateTimePlot();
        updateFrame();
    end

    function unlabeledOptionChanged(~,~)
        refreshMarkerList();
        rebuildLabels();
        updateTimePlot();
        updateFrame();
    end

    function labelOptionsChanged(~,~)
        rebuildLabels();
        updateFrame();
    end

    function rebuildLabels()
        delete(labelHandles(isgraphics(labelHandles)));
        labelHandles = gobjects(0);
        labelIndices = [];
        labelVisible = false(0,1);
        if isempty(markerNames) || ~showLabelsBox.Value
            return
        end
        visibleMarkers = ~isUnlabeled(markerNames) | showUnlabeledBox.Value;
        labelIndices = find(visibleMarkers);
        labelHandles = gobjects(numel(labelIndices),1);
        labelVisible = true(numel(labelIndices),1);
        for labelIndex = 1:numel(labelIndices)
            markerIndex = labelIndices(labelIndex);
            labelHandles(labelIndex) = text(ax3d,nan,nan,nan, ...
                markerNames{markerIndex},'Interpreter','none', ...
                'FontSize',8,'Color',[0.10 0.10 0.10], ...
                'PickableParts','none','HitTest','off');
        end
    end

    function updateFrame(varargin)
        if isempty(X) || ~isvalid(fig) || isUpdating
            return
        end
        isUpdating = true;
        try
            drawFrame();
        catch ME
            isUpdating = false;
            rethrow(ME);
        end
        isUpdating = false;
    end

    function drawFrame()
        currentFrame = max(1,min(size(X,1),round(currentFrame)));
        if ~sliderDragging
            frameSlider.Value = currentFrame;
        end
        frameSpinner.Value = currentFrame;

        % Reshaped to a row so it cannot implicitly expand against valid.
        unlabeled = reshape(isUnlabeled(markerNames),1,[]);
        valid = ~isnan(X(currentFrame,:));
        labeledNow = valid & ~unlabeled;
        if showUnlabeledBox.Value
            unlabeledNow = valid & unlabeled;
        else
            unlabeledNow = false(size(valid));
        end

        setPoints(labeledScatter,labeledNow);
        setPoints(unlabeledScatter,unlabeledNow);

        selectedIndex = selectedMarkerIndex();
        if isempty(selectedIndex) || ~valid(selectedIndex)
            set(selectedScatter,'XData',nan,'YData',nan,'ZData',nan);
        else
            set(selectedScatter, ...
                'XData',X(currentFrame,selectedIndex), ...
                'YData',Y(currentFrame,selectedIndex), ...
                'ZData',Z(currentFrame,selectedIndex));
        end

        if trailBox.Value && ~isempty(selectedIndex)
            firstTrailFrame = max(1,currentFrame-round(trailSpinner.Value)+1);
            trailFrames = firstTrailFrame:currentFrame;
            set(trailLine, ...
                'XData',X(trailFrames,selectedIndex), ...
                'YData',Y(trailFrames,selectedIndex), ...
                'ZData',Z(trailFrames,selectedIndex));
        else
            set(trailLine,'XData',nan,'YData',nan,'ZData',nan);
        end

        if numel(labelIndices) ~= numel(labelHandles) || ...
                (~isempty(labelIndices) && max(labelIndices) > numel(valid))
            rebuildLabels();
        end
        for labelIndex = 1:numel(labelHandles)
            markerIndex = labelIndices(labelIndex);
            if valid(markerIndex)
                labelHandles(labelIndex).Position = [ ...
                    X(currentFrame,markerIndex), ...
                    Y(currentFrame,markerIndex), ...
                    Z(currentFrame,markerIndex)];
                if ~labelVisible(labelIndex)
                    labelHandles(labelIndex).Visible = 'on';
                    labelVisible(labelIndex) = true;
                end
            elseif labelVisible(labelIndex)
                labelHandles(labelIndex).Visible = 'off';
                labelVisible(labelIndex) = false;
            end
        end

        if isgraphics(timeCursor)
            timeCursor.Value = time(currentFrame);
        end
        frameLabel.Text = sprintf('Frame %d (%g) | %.3f s | visible %d', ...
            currentFrame,headers(currentFrame),time(currentFrame), ...
            sum(labeledNow | unlabeledNow));
        drawnow limitrate;
    end

    function setPoints(scatterHandle,mask)
        set(scatterHandle, ...
            'XData',X(currentFrame,mask), ...
            'YData',Y(currentFrame,mask), ...
            'ZData',Z(currentFrame,mask));
    end

    function updateTimePlot()
        selectedIndex = selectedMarkerIndex();
        if isempty(selectedIndex) || isempty(X)
            set(timeLineX,'XData',nan,'YData',nan);
            set(timeLineY,'XData',nan,'YData',nan);
            set(timeLineZ,'XData',nan,'YData',nan);
            title(axTime,'Select a marker');
            return
        end
        set(timeLineX,'XData',time,'YData',X(:,selectedIndex));
        set(timeLineY,'XData',time,'YData',Y(:,selectedIndex));
        set(timeLineZ,'XData',time,'YData',Z(:,selectedIndex));
        if isgraphics(timeCursor)
            timeCursor.Value = time(currentFrame);
        end
        title(axTime,markerNames{selectedIndex},'Interpreter','none');
    end

    function setAxisLimits()
        labeled = ~isUnlabeled(markerNames);
        if ~any(labeled)
            labeled = true(size(markerNames));
        end
        xlim(ax3d,dataLimits(X(:,labeled)));
        ylim(ax3d,dataLimits(Y(:,labeled)));
        zlim(ax3d,dataLimits(Z(:,labeled)));
    end

    function limits = dataLimits(values)
        low = min(values,[],'all','omitnan');
        high = max(values,[],'all','omitnan');
        if isempty(low) || isnan(low) || isempty(high) || isnan(high)
            low = -1;
            high = 1;
        end
        span = high-low;
        if span == 0
            span = max(1,abs(high)*0.1);
        end
        padding = 0.05*span;
        limits = [low-padding high+padding];
    end

    function index = selectedMarkerIndex()
        if isempty(markerNames) || isempty(markerList.Value)
            index = [];
        else
            index = find(strcmp(markerNames,markerList.Value),1);
        end
    end

    function sliderMoving(~,event)
        stopPlaying();
        sliderDragging = true;
        currentFrame = round(event.Value);
        updateFrame();
    end

    function sliderChanged(~,event)
        sliderDragging = false;
        currentFrame = round(event.Value);
        updateFrame();
    end

    function spinnerChanged(~,event)
        stopPlaying();
        currentFrame = round(event.Value);
        updateFrame();
    end

    function stepFrame(amount)
        stopPlaying();
        currentFrame = currentFrame + amount;
        updateFrame();
    end

    function togglePlay(~,~)
        if playing
            stopPlaying();
        else
            startPlaying();
        end
    end

    function startPlaying()
        if isempty(X) || size(X,1) < 2
            return
        end
        if currentFrame >= size(X,1)
            currentFrame = 1;
        end
        playing = true;
        playButton.Text = 'Pause';
        anchorPlayback();
        if isempty(playTimer) || ~isvalid(playTimer)
            playTimer = timer('ExecutionMode','fixedSpacing', ...
                'Period',playPeriod,'BusyMode','drop', ...
                'TimerFcn',@(~,~) advancePlayback());
        end
        if strcmp(playTimer.Running,'off')
            start(playTimer);
        end
    end

    function anchorPlayback()
        playAnchorFrame = currentFrame;
        playClock = tic;
    end

    function speedChanged(~,~)
        if playing
            anchorPlayback();
        end
    end

    function advancePlayback()
        if ~playing || ~isvalid(fig) || isempty(X)
            stopPlaying();
            return
        end
        % updateFrame calls drawnow, which lets this timer re-enter. Frame
        % position is derived from elapsed time rather than accumulated per
        % tick so playback stays real-time regardless of tick jitter.
        if isUpdating
            return
        end
        targetFrame = playAnchorFrame + ...
            round(toc(playClock)*frequency*speedDropDown.Value);
        if targetFrame <= currentFrame
            return
        end
        currentFrame = min(size(X,1),targetFrame);
        atEnd = currentFrame >= size(X,1);
        updateFrame();
        if atEnd
            stopPlaying();
        end
    end

    function stopPlaying()
        playing = false;
        if ~isempty(playTimer) && isvalid(playTimer) && ...
                strcmp(playTimer.Running,'on')
            stop(playTimer);
        end
        if isvalid(playButton)
            playButton.Text = 'Play';
        end
    end

    function closeViewer(~,~)
        playing = false;
        delete(fig);
    end

    function cleanupViewer(~,~)
        playing = false;
        if ~isempty(playTimer) && isvalid(playTimer)
            stop(playTimer);
            delete(playTimer);
            playTimer = [];
        end
    end
end

function tf = isUnlabeled(names)
tf = startsWith(names,'C_') | ...
    ~cellfun(@isempty,regexp(names,'^U\d+$','once'));
end
