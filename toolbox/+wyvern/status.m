function info = status()
% WYVERN.STATUS  Show Wyvern server status and recent log output
%
%   wyvern.status()       — prints status and last 20 log lines
%   info = wyvern.status() — also returns a struct with fields:
%                             .running       logical
%                             .toolboxVersion string
%                             .serverVersion  string  (empty if not running)
%                             .pythonVersion  string
%                             .url            string
%                             .logTail        string  (last 20 log lines)

    toolboxVer = wyvern.version();
    url        = wyvern.util.serverUrl();

    % --- Check health ---
    running       = false;
    serverVersion = "";
    opts = weboptions('Timeout', 5, 'ContentType', 'json');
    try
        resp = webread(url + "/health", opts);
        if isstruct(resp) && isfield(resp, 'status') && strcmp(resp.status, 'ok')
            running = true;
            if isfield(resp, 'version')
                serverVersion = string(resp.version);
            end
        end
    catch
        % not running
    end

    % --- Get Python version ---
    pythonVer = "";
    for candidate = ["python3", "python"]
        [s, out] = system(sprintf('"%s" --version 2>&1', candidate));
        if s == 0
            tok = regexp(strtrim(out), '(\d+\.\d+\.\d+)', 'tokens', 'once');
            if ~isempty(tok)
                pythonVer = string(tok{1});
                break
            end
        end
    end

    % --- Tail the log file ---
    toolboxRoot = wyvern.util.toolboxRoot();
    logFile     = fullfile(toolboxRoot, 'server', 'server.log');
    logTail     = "";
    if isfile(logFile)
        logTail = tailFile(logFile, 20);
    end

    % --- Print summary ---
    if running
        fprintf('✓ Wyvern v%s | Server running on %s | Python %s\n', ...
            toolboxVer, url, pythonVer);
        fprintf('  Server version : %s\n', serverVersion);
    else
        fprintf('✗ Wyvern v%s | Server NOT running\n', toolboxVer);
        fprintf('  Run wyvern.setup() or wyvern.start() to start it.\n');
        if pythonVer ~= ""
            fprintf('  Python %s detected.\n', pythonVer);
        end
    end

    if logTail ~= ""
        fprintf('\n--- Last 20 lines of server.log ---\n');
        fprintf('%s\n', logTail);
        fprintf('-----------------------------------\n');
    end

    if nargout > 0
        info.running        = running;
        info.toolboxVersion = toolboxVer;
        info.serverVersion  = serverVersion;
        info.pythonVersion  = pythonVer;
        info.url            = string(url);
        info.logTail        = logTail;
    end
end

% ---------- private ----------

function tail = tailFile(filePath, nLines)
    fid = fopen(filePath, 'r');
    lines = {};
    tline = fgetl(fid);
    while ischar(tline)
        lines{end+1} = tline; %#ok<AGROW>
        tline = fgetl(fid);
    end
    fclose(fid);

    startIdx = max(1, numel(lines) - nLines + 1);
    tail = strjoin(lines(startIdx:end), newline);
end
