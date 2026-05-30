function stream(agentId, message)
% WYVERN.AGENT.STREAM  Invoke an agent and print tokens as they arrive
%
%   wyvern.agent.stream("analyst", "Explain wavelet transforms in detail")
%
%   Tokens are printed to the console as they stream in.
%   The full response is also returned when complete.
%
% Arguments:
%   agentId  - string, previously created agent
%   message  - string, user message

    arguments
        agentId  (1,1) string
        message  (1,1) string
    end

    wyvern.util.checkServer();

    baseUrl  = wyvern.util.serverUrl();
    fullUrl  = baseUrl + "/agent/stream";

    payload.agent_id = agentId;
    payload.message  = message;

    % MATLAB's webwrite does not natively stream SSE.
    % We send the request and collect the full SSE response, then
    % print each data line progressively.
    opts = weboptions( ...
        'MediaType',     'application/json', ...
        'ContentType',   'text', ...
        'Timeout',       300, ...
        'RequestMethod', 'post' ...
    );

    try
        rawResponse = webwrite(fullUrl, payload, opts);
    catch err
        wyvern.util.handleHttpError(err, "/agent/stream");
        return
    end

    % Parse and display SSE lines
    lines = strsplit(rawResponse, newline);
    fprintf('\n');
    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if startsWith(line, 'data: ')
            token = extractAfter(line, 'data: ');
            if token == "[DONE]"
                break
            elseif startsWith(token, "[ERROR]")
                error('Wyvern:streamError', '%s', extractAfter(token, "[ERROR] "));
            else
                fprintf('%s', token);
            end
        end
    end
    fprintf('\n');
end
