function setServerPort(port)
% WYVERN.UTIL.SETSERVERPORT  Override the default server port (5173)
%
%   wyvern.util.setServerPort(5174)
%
%   Updates the cached URL used by all Wyvern HTTP calls.
%   Called automatically by wyvern.start() when a custom port is specified.

    arguments
        port (1,1) double {mustBeInteger, mustBePositive}
    end

    % Overwrite the cached URL by clearing the persistent and re-entering.
    % We store the URL in a shared config file under tempdir so all callers
    % pick it up via serverUrl.m reading it on the next call.
    configPath = fullfile(tempdir, 'wyvern_port.txt');
    fid = fopen(configPath, 'w');
    fprintf(fid, '%d', port);
    fclose(fid);

    % Patch the cached value in serverUrl by clearing it
    clear wyvern.util.serverUrl
end
