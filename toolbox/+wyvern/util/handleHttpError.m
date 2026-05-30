function handleHttpError(err, endpoint)
% WYVERN.UTIL.HANDLEHTTPERROR  Translate HTTP/network errors to friendly messages
%
%   Internal helper called by postRequest when webwrite throws.

    arguments
        err       (1,1) MException
        endpoint  (1,1) string
    end

    msg = err.message;

    % Connection refused / server not started
    if contains(msg, 'Connection refused', 'IgnoreCase', true) || ...
       contains(msg, 'ECONNREFUSED',       'IgnoreCase', true) || ...
       contains(msg, 'Failed to connect',  'IgnoreCase', true)
        error('Wyvern:serverNotRunning', ...
            'Wyvern server is not running. Call wyvern.setup() to start it.');
    end

    % Parse HTTP status codes out of the error message
    statusMatch = regexp(msg, '(\d{3})', 'tokens', 'once');
    if ~isempty(statusMatch)
        code = str2double(statusMatch{1});
        switch code
            case 404
                detail = extractDetail(msg);
                error('Wyvern:notFound', ...
                    'Not found (%s): %s', endpoint, detail);
            case 422
                detail = extractDetail(msg);
                error('Wyvern:validationError', ...
                    'Invalid request (%s): %s', endpoint, detail);
            case 500
                detail = extractDetail(msg);
                error('Wyvern:serverError', ...
                    'Server error (%s): %s', endpoint, detail);
        end
    end

    % Fallback
    error('Wyvern:httpError', 'Request to %s failed: %s', endpoint, msg);
end

% ---------- private ----------

function detail = extractDetail(msg)
    % Try to pull the "detail" field out of a JSON error body.
    tok = regexp(msg, '"detail"\s*:\s*"([^"]+)"', 'tokens', 'once');
    if ~isempty(tok)
        detail = tok{1};
    else
        detail = msg;
    end
end
