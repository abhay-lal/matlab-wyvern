function url = serverUrl()
% WYVERN.UTIL.SERVERURL  Return the base URL of the Wyvern server
%
%   url = wyvern.util.serverUrl()   % returns "http://127.0.0.1:5173"
%
%   The port is read from a temp file written by wyvern.util.setServerPort.
%   Defaults to 5173 if no override has been set.

    port = 5173;
    configPath = fullfile(tempdir, 'wyvern_port.txt');
    if isfile(configPath)
        fid = fopen(configPath, 'r');
        val = fscanf(fid, '%d', 1);
        fclose(fid);
        if ~isempty(val) && val > 0
            port = val;
        end
    end
    url = sprintf("http://127.0.0.1:%d", port);
end
