classdef WebWid < handle
    properties (Hidden)
        Docked = false;
        WaitForIsVisible = true;
        ShowDebugMessages = false;
        WebWindowObject;
        pPosition = [100, 100, 1200, 800];
    end
    
    methods
        function show(this)
            % Simplified show method
            name = 'My Web Window';
            URL = 'https://www.mathworks.com';
            
            if ~usejava('jvm') || ~usejava('awt')
                error('JVM or AWT is not available.');
            end
            
            if isempty(this.WebWindowObject)
                % Create a simple web window using MATLAB's web function
                webWindow = web(URL, '-new', '-noaddressbox');
                this.WebWindowObject = webWindow;
            end
            
            if this.ShowDebugMessages
                disp('Web window shown.');
            end
        end
        
        function hide(this)
            % Simplified hide method
            if ~isempty(this.WebWindowObject)
                close(this.WebWindowObject);
                this.WebWindowObject = [];
            end
        end
    end
end
