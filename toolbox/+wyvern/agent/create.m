function agentId = create(agentId, options)
% WYVERN.AGENT.CREATE  Create a LangGraph agent with tools and memory
%
%   wyvern.agent.create("analyst")
%   wyvern.agent.create("analyst", model="claude-sonnet-4-6", systemPrompt="You are a DSP expert")
%   wyvern.agent.create("analyst", tools=["web_search","calculator"], memory=true)
%
% Arguments:
%   agentId      - string, unique name for this agent
%   model        - string, LLM model name (default: "gpt-4o")
%   apiKey       - string, API key (default: reads from server/.env)
%   systemPrompt - string, agent persona / instructions
%   tools        - string array of built-in tool names:
%                    "web_search"  DuckDuckGo web search
%                    "calculator"  safe math expression evaluator
%   memory       - logical, persist conversation history (default: true)
%
% Returns:
%   agentId  - the same string, for call chaining

    arguments
        agentId              (1,1) string
        options.model        (1,1) string  = "gpt-4o"
        options.apiKey       (1,1) string  = ""
        options.systemPrompt (1,1) string  = "You are a helpful assistant."
        options.tools        string        = string.empty
        options.memory       (1,1) logical = true
    end

    wyvern.util.checkServer();

    payload.agent_id      = agentId;
    payload.model         = options.model;
    payload.system_prompt = options.systemPrompt;
    payload.tools         = cellstr(options.tools);
    payload.memory        = options.memory;

    if options.apiKey ~= ""
        payload.api_key = options.apiKey;
    else
        payload.api_key = [];
    end

    resp = wyvern.util.postRequest("/agent/create", payload);
    fprintf('Agent "%s" created (model: %s, memory: %d).\n', ...
        resp.agent_id, options.model, options.memory);
end
