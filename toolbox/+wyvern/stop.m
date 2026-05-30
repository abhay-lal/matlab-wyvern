function stop()
% WYVERN.STOP  Gracefully stop the Wyvern FastAPI server
%
%   wyvern.stop()
%
%   Reads the PID saved by wyvern.start() and sends a termination signal.
%   On Windows, uses taskkill; on Unix, sends SIGTERM.

    pidFile = fullfile(tempdir, 'wyvern_server.pid');

    if ~isfile(pidFile)
        fprintf('No Wyvern server PID file found. Server may not be running.\n');
        return
    end

    fid = fopen(pidFile, 'r');
    pid = strtrim(fscanf(fid, '%s', 1));
    fclose(fid);

    if isempty(pid)
        fprintf('PID file is empty. Nothing to stop.\n');
        delete(pidFile);
        return
    end

    if ispc()
        cmd = sprintf('taskkill /PID %s /F /T', pid);
    else
        cmd = sprintf('kill -TERM %s 2>/dev/null || kill -KILL %s 2>/dev/null', pid, pid);
    end

    [rc, ~] = system(cmd);
    delete(pidFile);

    if rc == 0
        fprintf('Wyvern server (PID %s) stopped.\n', pid);
    else
        fprintf('Could not stop process %s — it may have already exited.\n', pid);
    end

    % Also remove the port config so next start uses the default
    portFile = fullfile(tempdir, 'wyvern_port.txt');
    if isfile(portFile)
        delete(portFile);
    end
end
