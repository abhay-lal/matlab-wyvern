function response = postRequest(endpoint, payload)
% WYVERN.UTIL.POSTREQUEST  Internal HTTP POST helper for Wyvern
%
%   response = wyvern.util.postRequest('/agent/run', struct(...))
%
%   Sends a JSON POST to the Wyvern server and returns the parsed
%   response as a MATLAB struct.  Translates HTTP and connection errors
%   into human-readable Wyvern errors.

    arguments
        endpoint  (1,1) string
        payload             % struct, or anything encodable to JSON
    end

    baseUrl  = wyvern.util.serverUrl();
    fullUrl  = baseUrl + endpoint;

    opts = weboptions( ...
        'MediaType',     'application/json', ...
        'ContentType',   'json', ...
        'Timeout',       120, ...
        'RequestMethod', 'post' ...
    );

    try
        response = webwrite(fullUrl, payload, opts);
    catch err
        wyvern.util.handleHttpError(err, endpoint);
    end
end
