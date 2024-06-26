classdef WebWindow < matlab.internal.language.Snapshottable & handle
    
    %
        
    % Copyright 2018-2020 The MathWorks, Inc.
    
    %#function matlab.internal.language.Snapshottable
    properties (Hidden)
        Docked = false;
        ContainerKey = getString(message('Spcuilib:scopes:SystemObjectContainerKey'));
        ContainerTile = 0;
        WaitForIsVisible = true;
        ShowDebugMessages = false;
    end
    
    properties (Access = protected)
        pPosition = getWebWindowPosition;
        ScopeComponentListener
    end
    
    properties (SetAccess = protected, Hidden)
        WebWindowObject;
    end
    
    methods
        function show(this)
            name = getName(this);
            if ~usejava('jvm') || ~usejava('awt')
                error(message('Spcuilib:application:ErrorNoJVMNoDisplay', name));
            end
            
            connector.ensureServiceOn;
            feature = getDebugLevel(this);
            
            % 0 - Off from UE, debug/chrome
            % 1 - Shown in UE, debug/chrome
            % 2 - Shown in UE, release/chrome
            % 3 - Shown in UE, release/CEF
            % 4 - Shown in UE, debug/CEF
            % 5 - For Testability
            if matlabshared.scopes.container.Application.isInstance(this.ContainerKey)
                container = matlabshared.scopes.container.Container.getInstance(this.ContainerKey);
                if container.DockOnOpen
                    this.Docked = true;
                end
            end
            if this.Docked
                container = matlabshared.scopes.container.Container.getInstance(this.ContainerKey);
                isAlreadyOpen = isOpen(container);
                if ~isAlreadyOpen
                    
                    open(container);
                end
                component = addScope(container, this);
                this.ScopeComponentListener = event.listener(component, 'ToolstripEvent', @this.onScopeComponentToolstripEvent);
                if container.VisibleAtOpen
                    container.Visible = true;
                end
                return;
            end
            
            URL = getFullUrl(this);
            
            % Only use CEF for final flag.
            if feature > 2 && feature < 5
                hWebWindow = this.WebWindowObject;
                isObjectValid = isa(hWebWindow,'matlab.internal.webwindow') && isvalid(hWebWindow);
                if ~(isObjectValid && hWebWindow.isWindowValid)
                    % If the object is valid but window is invalid, the web window
                    % process might have been terminated. In this case, delete the
                    % object on the coreblock before creating and assigning a new one.
                    if isObjectValid
                        delete(hWebWindow);
                    end
                    
                    % We never created a web window for this Logic Analyzer or it was
                    % destroyed. Therefore, create a new one and initialize it.
                    % Adding remote debugging port to allow tests to use the CEF window
                    % launched by the product
                    hWebWindow = matlab.internal.webwindow(URL,matlab.internal.getDebugPort, ...
                        'Position', getWindowPosition(this));
                    this.WebWindowObject = hWebWindow;
                    
                    % Title
                    hWebWindow.Title = char(name);
                    % Icon
                    iconFile = getIconFile(this);
                    if ~isempty(iconFile)
                        hWebWindow.Icon = iconFile;
                    end
                    
                    % Custom close callback. By default, closing deletes the webwindow and
                    % invalidates it. We only need to hide it. Web window is closed and
                    % deleted by the LogicAnalyzer coreblock.
                    hWebWindow.CustomWindowClosingCallback = @(evt,src)hide(hWebWindow);
                    if this.ShowDebugMessages
                        hWebWindow.MATLABWindowExitedCallback = @(evt, src) disp('MATLAB Crash Detected');
                    end
                end
                if ~hWebWindow.isVisible
                    notifyOutputChanged(this);
                end
                
                hWebWindow.show;
                hWebWindow.bringToFront;
                
                [str, id] = lastwarn;
                w = warning('off');
                c = onCleanup(@() cleanupWarning(w, str, id));
                if this.WaitForIsVisible
                    t = tic;
                    while toc(t) < 10 && isvalid(hWebWindow) && ~isVisible(hWebWindow)
                        drawnow limitrate;
                    end
                end
            elseif feature <= 2
                if strcmpi(computer,'maci64')
                    system(['open -a Google\ Chrome "', URL, '" --args --incognito']);
                elseif strcmpi(computer,'pcwin64')
                    system(['start chrome "', URL, '" --incognito']);
                elseif strcmpi(computer,'glnxa64')
                    system(['chromium "', URL, '"&']);
                end
            end
        end
        
        function hide(this)
            if isVisible(this)
                if this.Docked
                    % Cannot currently be done cleanly, the scope must be
                    % removed and readded.
                    container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
                    if ~isempty(container)
                        hideScope(container, this);
                    end                
                else
                    hWebWindow = this.WebWindowObject;
                    hWebWindow.hide;
                    if this.WaitForIsVisible
                        matlabshared.application.waitfor(hWebWindow, 'isVisible', false, 'Timeout', 10);
                    end
                end
            end
        end
        
        function b = isVisible(this)
            if this.Docked
                b = false;
                container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
                if ~isempty(container) && container.Visible
                    scope = getScope(container, this);
                    b = ~isempty(scope) && scope.Document.Visible;
                end
            else
                try
                    b = isWindowLaunched(this) && ...
                        this.WebWindowObject.isVisible;
                catch me %#ok
                    % It is possible for the isWindowOpen to return true and
                    % for the window to be closed before calling isVisible
                    % (which needs an opened window)
                    delete(this.WebWindowObject);
                    this.WebWindowObject = [];
                    b = false;
                end
            end
        end
        
        function delete(this)
            close(this);
        end
        
        function set.Docked(this, newDock)
            oldDock = this.Docked;
            
            if newDock == oldDock
                this.Docked = newDock;
                return;
            end
            
            isOpen = isWindowLaunched(this);
            % If the window is open move it from a webwindow to a docked
            % object or vice versa.
            if isOpen
                isVis = isVisible(this);
                hide(this);
                % Set after close so that close knows the previous value.
                this.Docked = newDock;
                if isVis
                    show(this);
                end
            else
                this.Docked = newDock;
            end
        end
    end
    
    methods (Hidden)
        
        function close(this)
            container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
            if ~isempty(container)
                removeScope(container, this);
            end

            ww = this.WebWindowObject;
            if isempty(ww) || ~isvalid(ww)
                return;
            end
            try
                close(ww);
                delete(ww);
                this.WebWindowObject = [];
            catch ME %#ok<NASGU>
                % NO OP, possible for ww to become invalid before close is
                % called.  Do nothing.
            end
        end
        
        function t = createToolstripTabs(~, ~)
            % By default, no tabs are added.
            t = [];
        end
        
        function im = getImageDataForSnapshot(this)
            if ~this.isVisible()
                im = [];
                return
            end
            forceSynchronous(this);
            msg = this.MessageHandler;
            [im, t, r] = getSnapshot(msg);
            
            if isempty(im)
                
                ww = this.WebWindowObject;
                isObjectValid = isa(ww,'matlab.internal.webwindow') && isvalid(ww);
                if ~this.Docked && isObjectValid && ww.isWindowValid
                    forceOntoScreen(ww);
                    im = getScreenshot(ww);
                end
                
                % If the webwindow's getScreenshot fails we're most likely
                % in matlabonline which has a sporadic issue returning the
                % data, call again.
                if isempty(im)
                    im = getSnapshot(msg);
                end
                
                % Always throw a warning if no screenshot could be
                % generated for the live editor.
                if isempty(im)
                    % Throw a warning when publishing with diagnostic
                    % information
                    if isempty(getenv('IS_PUBLISHING'))
                        warning(getString(message('Spcuilib:scopes:PublishingEmptyDataWarning', getName(this))));
                    else
                        warning(getString(message('Spcuilib:scopes:PublishingDomSnapshotWarning', ...
                            getName(this), mat2str(t), mat2str(r), mat2str(isWebWindowValid(this)), sprintf('%s %s', msg.SnapshotStatus, msg.SnapshotResult))));
                    end
                end
            end
        end
        
        function valid = isWebWindowValid(this)
            valid = false;
            %             if this.Docked
            %                 container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
            %                 if isempty(container)
            %                     valid = false;
            %                 else
            %                     valid = ~isempty(getScope(container, this));
            %                 end
            %             else
            if ~isempty(this.WebWindowObject)
                valid = this.WebWindowObject.isWindowValid;
            end
        end
        
        function forceSynchronous(this)
            t = this.LastWriteTime;
            if this.Docked
                waitTime = 2;
            else
                waitTime = 0.250;
            end
            while toc(t) < waitTime
                % Use drawnow and yield to make sure that events flush
                drawnow;
                matlab.internal.yield;
            end
        end
        
        
        function print(this)
            %PRINT Print the scope
            fig = printToFigure(this);
            if isempty(fig)
                return;
            end
            try
                printdlg(fig);
            catch ME %#ok
                % NO OP, print issues error on cancel
            end
            delete(fig);
        end
        
        function fig = printToFigure(this)
            fig = [];
            if ~isWindowLaunched(this)
                return;
            end
            ss = getImageDataForSnapshot(this);
            if isempty(ss)
                return;
            end
            ss = flipud(ss);
            fig = figure('HandleVisibility', 'off', ...
                'Visible', 'off', ...
                'Tag', 'WebScopePrintToFigure', ...
                'Position', [1 1 size(ss, [2 1])]);
            a = axes('Parent', fig, ...
                'Position', [0 0 1 1]);
            img = image('Parent', a, ...
                'CData', ss);
            
            xLim = a.XLim;
            yLim = a.YLim;
            
            img.XData = [1, xLim(2) - 1];
            img.YData = [1, yLim(2) - 1];
        end
        
        function copyToClipboard(this)
            fig = printToFigure(this);
            if isempty(fig)
                return;
            end
            print(fig, '-clipboard', '-dbitmap');
            delete(fig);
        end
        
        function setName(this, name)
            if this.Docked
                container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
                if ~isempty(container)
                    scope = getScope(container, this);
                    if ~isempty(scope)
                        scope.Name = name;
                    end
                end
            elseif isWindowLaunched(this)
                this.WebWindowObject.Title = name;
            end
        end
        
        function debug(this)
            
            if ~isempty(this.WebWindowObject)
                URL = sprintf('http://localhost:%d', this.WebWindowObject.RemoteDebuggingPort);
                if strcmpi(computer,'maci64')
                    system(['open -a Google\ Chrome "', URL, '" --args --incognito']);
                elseif strcmpi(computer,'pcwin64')
                    system(['start chrome "', URL, '" --incognito']);
                elseif strcmpi(computer,'glnxa64')
                    web(URL, "-browser");
                end
            end
        end
        
        function url = getFullUrl(this, varargin)
            % Convert partial URL, debug flag and query string into the
            % full URL.
            
            % Get the incomplete url
            url = getPartialUrl(this);
            
            % Add the debug flag if debug level specifies
            if any(getDebugLevel(this) == [0 1 4])
                url = [url '-debug'];
            end
            
            % Add .html
            url = [url '.html'];
            
            % Add any query strings if there are any.
            qStr = getQueryString(this, varargin{:});
            if ~isempty(qStr)
                url = [url '?' qStr];
            end
            url = connector.getUrl(url);
        end
        
        function str = getQueryString(varargin)
            % Must be concrete because it doesn't have to be overloaded.
            str = '';
        end
        
        function b = isWindowLaunched(this)
            if this.Docked
                container = matlabshared.scopes.container.Application.getInstance(this.ContainerKey);
                if isempty(container)
                    b = false;
                else
                    b = ~isempty(getScope(container, this));
                end
            else
                hWebWindow = this.WebWindowObject;
                b = ~isempty(hWebWindow) && ...
                    isvalid(hWebWindow) && ...
                    hWebWindow.isWindowValid;
            end
        end
        
        function varargout = setDebugLevel(this, ~)
            % Must be overloaded to allow for non 3
            if nargout > 0
                varargout{1} = getDebugLevel(this);
            end
        end
        
        function level = getDebugLevel(~)
            level = 3;
        end
        
        function pos = getWindowPosition(this)
            if ~this.Docked && isWindowLaunched(this) && isWebWindowValid(this)
                pos = this.WebWindowObject.Position;
            else
                pos = this.pPosition;
            end
        end
        
        function setWindowPosition(this, pos)
            if isWindowLaunched(this) && isWebWindowValid(this)
                this.WebWindowObject.Position = pos;
            end
            this.pPosition = pos;
        end

        function onScopeComponentToolstripEvent(this, ~, ev)
            if isa(ev, 'matlabshared.application.ButtonPressedEventData')
                if any(strcmp(ev.ButtonName, {'UndockAll' 'Undock'}))
                    this.Docked = false;
                end
            end
        end
    end
    
    methods (Abstract, Hidden)
        url = getPartialUrl(this)
    end
end

function cleanupWarning(w, str, id)
warning(w);
lastwarn(str, id);
end

function ret = getWebWindowPosition

width = 1200;
height = 800;

r = groot;
screenWidth = r.ScreenSize(3);
screenHeight = r.ScreenSize(4);
maxWidth = 0.8 * screenWidth;
maxHeight = 0.8 * screenHeight;
if maxWidth > 0 && width > maxWidth
    width = maxWidth;
end
if maxHeight > 0 && height > maxHeight
    height = maxHeight;
end

xOffset = (screenWidth - width) / 2;
yOffset = (screenHeight - height) / 2;

ret = [xOffset yOffset width height];

end

function forceOntoScreen(ww)
sz = get(0, 'ScreenSize');
wwPos = ww.Position;

if wwPos(1) < 1
    wwPos(1) = 1;
elseif wwPos(1) + wwPos(3) > sz(3)
    wwPos(1) = sz(3) - wwPos(3) - 1;
end
if wwPos(2) < 1
    wwPos(2) = 1;
elseif wwPos(2) + wwPos(4) > sz(4)
    wwPos(2) = sz(4) - wwPos(4) - 1;
end
ww.Position = wwPos;

end

% [EOF]