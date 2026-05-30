function checkServer()
% WYVERN.UTIL.CHECKSERVER  Verify the Wyvern server is reachable
%
%   Throws Wyvern:serverNotRunning if the /health endpoint does not respond.
%   Call this at the top of any user-facing function that needs the server.

    url = wyvern.util.serverUrl() + "/health";
    opts = weboptions('Timeout', 5, 'ContentType', 'json');
    try
        resp = webread(url, opts);
        if ~isstruct(resp) || ~isfield(resp, 'status') || ~strcmp(resp.status, 'ok')
            error('Wyvern:serverNotRunning', ...
                'Wyvern server returned unexpected health response. Try wyvern.setup().');
        end
    catch err
        if strcmp(err.identifier, 'Wyvern:serverNotRunning')
            rethrow(err);
        end
        error('Wyvern:serverNotRunning', ...
            'Wyvern server is not running. Call wyvern.setup() to start it.');
    end
end
