function start(options)
% WYVERN.START  Start the Wyvern FastAPI server as a background process
%
%   wyvern.start()
%   wyvern.start(port=5174)
%
%   The server process is started silently in the background.
%   Its PID is saved to a temp file so wyvern.stop() can terminate it.
%   Server output is written to server/server.log.

    arguments
        options.port (1,1) double {mustBeInteger, mustBePositive} = 5173
    end

    toolboxRoot = wyvern.util.toolboxRoot();
    serverDir   = fullfile(toolboxRoot, 'server');
    logFile     = fullfile(serverDir, 'server.log');
    mainScript  = fullfile(toolboxRoot, 'server', 'main.py');

    wyvern.util.setServerPort(options.port);

    % Find python executable
    pythonExe = findPython();
    if pythonExe == ""
        error('Wyvern:pythonNotFound', ...
            'Python 3.10+ not found. Run wyvern.setup() first.');
    end

    % Build platform-appropriate launch command
    portStr = num2str(options.port);
    if ispc()
        % Windows: use 'start /B' to launch without a console window
        cmd = sprintf( ...
            'start /B "Wyvern" cmd /C "cd /d "%s" && "%s" -m server.main --port %s > "%s" 2>&1"', ...
            toolboxRoot, pythonExe, portStr, logFile);
        [rc, ~] = system(cmd);
    else
        % macOS / Linux
        cmd = sprintf( ...
            'cd "%s" && "%s" -m server.main --port %s > "%s" 2>&1 & echo $!', ...
            toolboxRoot, pythonExe, portStr, logFile);
        [rc, out] = system(cmd);
        if rc == 0
            pid = strtrim(out);
            savePid(pid);
        end
    end

    if rc ~= 0
        error('Wyvern:startFailed', ...
            'Failed to start Wyvern server. Check server.log at: %s', logFile);
    end

    fprintf('Wyvern server starting on port %d...\n', options.port);
end

% ---------- private ----------

function pythonExe = findPython()
    for candidate = ["python3", "python"]
        [s, ~] = system(sprintf('"%s" --version 2>&1', candidate));
        if s == 0
            pythonExe = candidate;
            return
        end
    end
    pythonExe = "";
end

function savePid(pid)
    pidFile = fullfile(tempdir, 'wyvern_server.pid');
    fid = fopen(pidFile, 'w');
    fprintf(fid, '%s', pid);
    fclose(fid);
end
