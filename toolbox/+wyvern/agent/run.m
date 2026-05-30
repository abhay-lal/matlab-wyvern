function result = run(agentId, message, options)
% WYVERN.AGENT.RUN  Invoke a LangGraph agent and return its response
%
%   response = wyvern.agent.run("analyst", "Explain this FFT output")
%   result   = wyvern.agent.run("analyst", "Analyse this", verbose=true)
%   result   = wyvern.agent.run("analyst", "What is X?", context=myStruct)
%
% Arguments:
%   agentId  - string, previously created agent
%   message  - string, user message / prompt
%   context  - struct, optional extra context merged into the request
%   verbose  - logical, if true return struct instead of string (default: false)
%
% Returns (verbose=false, default):
%   result  - string, the agent's answer
%
% Returns (verbose=true):
%   result.response    - string
%   result.steps       - struct array of intermediate reasoning steps
%   result.tokensUsed  - integer

    arguments
        agentId         (1,1) string
        message         (1,1) string
        options.context struct  = struct()
        options.verbose (1,1) logical = false
    end

    wyvern.util.checkServer();

    payload.agent_id = agentId;
    payload.message  = message;

    if ~isempty(fieldnames(options.context))
        payload.context = options.context;
    else
        payload.context = [];
    end

    resp = wyvern.util.postRequest("/agent/run", payload);

    if options.verbose
        result.response   = string(resp.response);
        result.steps      = resp.steps;
        result.tokensUsed = resp.tokens_used;
    else
        result = string(resp.response);
    end
end
