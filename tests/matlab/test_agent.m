classdef test_agent < matlab.unittest.TestCase
% TEST_AGENT  Unit tests for wyvern.agent.* functions
%
%   Run: results = runtests('test_agent')
%
%   Requires a running Wyvern server (wyvern.setup() must have been called).
%   Tests use a real GPT-4o or Claude call — set OPENAI_API_KEY in server/.env.

    properties (TestParameter)
        AgentId = {"test_matlab_agent"}
    end

    methods (TestClassSetup)
        function startServer(tc)
            % Best-effort: start or verify the server is running.
            try
                wyvern.util.checkServer();
            catch
                wyvern.setup();
            end
        end
    end

    methods (Test)
        function testCreateReturnsAgentId(tc, AgentId)
            id = wyvern.agent.create(AgentId, ...
                model="gpt-4o", ...
                systemPrompt="You are a test assistant. Reply with one word only.", ...
                memory=false);
            tc.verifyEqual(id, AgentId);
        end

        function testRunReturnsNonEmptyString(tc, AgentId)
            wyvern.agent.create(AgentId, model="gpt-4o", memory=false);
            response = wyvern.agent.run(AgentId, "Say the word: hello");
            tc.verifyClass(response, 'string');
            tc.verifyNotEmpty(response);
        end

        function testRunVerboseReturnsStruct(tc, AgentId)
            wyvern.agent.create(AgentId, model="gpt-4o", memory=false);
            result = wyvern.agent.run(AgentId, "Say hi", verbose=true);
            tc.verifyClass(result, 'struct');
            tc.verifyTrue(isfield(result, 'response'));
            tc.verifyTrue(isfield(result, 'tokensUsed'));
        end

        function testResetClearsMemory(tc, AgentId)
            wyvern.agent.create(AgentId, model="gpt-4o", memory=true);
            wyvern.agent.run(AgentId, "My name is TestBot.");
            wyvern.agent.reset(AgentId);
            % After reset, agent should not remember the name
            resp = wyvern.agent.run(AgentId, "What is my name?");
            tc.verifyClass(resp, 'string');
        end

        function testRunUnknownAgentThrows(tc)
            tc.verifyError( ...
                @() wyvern.agent.run("nonexistent_agent_xyz", "hi"), ...
                'Wyvern:notFound');
        end
    end
end
