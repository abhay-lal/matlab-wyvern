function reset(agentId)
% WYVERN.AGENT.RESET  Clear an agent's memory and conversation history
%
%   wyvern.agent.reset("analyst")
%
%   After reset, the agent starts fresh with no prior context.
%   The agent definition (model, tools, system prompt) is preserved.
%
% Arguments:
%   agentId  - string, the agent to reset

    arguments
        agentId (1,1) string
    end

    wyvern.util.checkServer();

    payload.agent_id = agentId;
    resp = wyvern.util.postRequest("/agent/reset", payload);
    fprintf('Agent "%s" memory cleared.\n', agentId);
end
