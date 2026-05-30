function setup(options)
% WYVERN.SETUP  One-time setup: install Python deps and start the server
%
%   wyvern.setup()
%   wyvern.setup(port=5174)
%   wyvern.setup(apiKey="sk-...")
%
%   Steps performed:
%     1. Verify Python >= 3.10 is on PATH
%     2. Install server/requirements.txt via pip
%     3. Write API key to server/.env if provided
%     4. Start the FastAPI server as a background process
%     5. Poll /health until ready (max 30 s)
%
%   After success, prints a quick-start example.

    arguments
        options.port    (1,1) double  {mustBeInteger, mustBePositive} = 5173
        options.apiKey  (1,1) string  = ""
        options.force   (1,1) logical = false   % restart even if already running
    end

    % ---- 1. Check Python version ----------------------------------------
    fprintf('Checking Python installation...\n');
    [status, pythonExe] = findPython();
    if status ~= 0
        error('Wyvern:pythonNotFound', ...
            'Python 3.10+ is required. Install from python.org and re-run wyvern.setup().');
    end
    fprintf('  Found Python: %s\n', pythonExe);

    % ---- 2. Install requirements ----------------------------------------
    toolboxRoot = wyvern.util.toolboxRoot();
    reqFile     = fullfile(toolboxRoot, 'server', 'requirements.txt');
    if ~isfile(reqFile)
        error('Wyvern:missingFile', ...
            'requirements.txt not found at: %s', reqFile);
    end

    fprintf('Installing Python dependencies (this may take a moment)...\n');
    cmd = sprintf('"%s" -m pip install -r "%s" --quiet', pythonExe, reqFile);
    [rc, out] = system(cmd);
    if rc ~= 0
        error('Wyvern:pipFailed', ...
            'pip install failed:\n%s', out);
    end
    fprintf('  Dependencies installed.\n');

    % ---- 3. Write .env if API key provided ------------------------------
    envPath = fullfile(toolboxRoot, 'server', '.env');
    if options.apiKey ~= ""
        writeEnvFile(envPath, options.apiKey);
        fprintf('  API key written to server/.env\n');
    end

    % ---- 4. Start the server --------------------------------------------
    wyvern.util.setServerPort(options.port);

    if ~options.force
        try
            wyvern.util.checkServer();
            fprintf('  Wyvern server already running on port %d.\n', options.port);
            printQuickStart(options.port);
            return
        catch
            % Not running — continue to start it
        end
    end

    wyvern.start('port', options.port);

    % ---- 5. Poll health -------------------------------------------------
    fprintf('Waiting for server to start');
    maxWait = 30;
    started = false;
    for i = 1:maxWait
        pause(1);
        fprintf('.');
        try
            wyvern.util.checkServer();
            started = true;
            break
        catch
            % still starting...
        end
    end
    fprintf('\n');

    if ~started
        logPath = fullfile(toolboxRoot, 'server', 'server.log');
        error('Wyvern:startupTimeout', ...
            ['Server did not respond within %d seconds.\n' ...
             'Check logs: %s'], maxWait, logPath);
    end

    fprintf('\n✓ Wyvern server running on localhost:%d\n\n', options.port);
    printQuickStart(options.port);
end

% ---------- private helpers ----------

function [status, pythonExe] = findPython()
    % Prefer python3, fall back to python
    for candidate = ["python3", "python"]
        [s, out] = system(sprintf('"%s" --version 2>&1', candidate));
        if s == 0
            verMatch = regexp(out, '(\d+)\.(\d+)', 'tokens', 'once');
            if ~isempty(verMatch)
                major = str2double(verMatch{1});
                minor = str2double(verMatch{2});
                if major > 3 || (major == 3 && minor >= 10)
                    status = 0;
                    pythonExe = candidate;
                    return
                end
            end
        end
    end
    status = 1;
    pythonExe = "";
end

function writeEnvFile(envPath, apiKey)
    % Write (or append) API key entries to the .env file.
    % Detect provider by key prefix.
    fid = fopen(envPath, 'w');
    if startsWith(apiKey, "sk-ant")
        fprintf(fid, 'ANTHROPIC_API_KEY=%s\n', apiKey);
    elseif startsWith(apiKey, "hf_")
        fprintf(fid, 'HUGGINGFACE_API_KEY=%s\n', apiKey);
    else
        fprintf(fid, 'OPENAI_API_KEY=%s\n', apiKey);
    end
    fclose(fid);
end

function printQuickStart(port)
    fprintf('Quick start:\n');
    fprintf('  wyvern.agent.create("myAgent", model="gpt-4o", systemPrompt="You are a helpful assistant")\n');
    fprintf('  response = wyvern.agent.run("myAgent", "Hello!")\n');
    fprintf('  wyvern.rag.loadDocs("myDocs", "/path/to/docs/")\n');
    fprintf('  answer = wyvern.rag.ask("myDocs", "What is the main topic?")\n');
    fprintf('  E = wyvern.hf.embed("all-MiniLM-L6-v2", {"sentence one", "sentence two"})\n\n');
    fprintf('Type "help wyvern" for full API reference.\n');
end
