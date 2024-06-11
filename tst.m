% Create an instance of the WebWindow class
ww = WebWid();

try
    % Show the web window
    ww.show();
    
    % Optionally, set additional properties or debug
    ww.setName('My Web Window');
    if ww.isVisible()
        disp('Web window is now visible.');
    else
        disp('Web window is not visible.');
    end
    
    % Uncomment to debug the web window if needed
    % ww.debug();

catch ME
    % Handle any errors that occur during the show process
    disp('An error occurred while showing the web window:');
    disp(ME.message);
end
