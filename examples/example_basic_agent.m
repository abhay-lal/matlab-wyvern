%% Wyvern — Example 1: Basic Agent
% This example shows how to create a LangGraph agent, run it, and use
% streaming output.  You need an OpenAI or Anthropic API key in server/.env.

%% Setup
% Run this once after cloning the toolbox.
% wyvern.setup()   % uncomment on first run

%% Create an agent
wyvern.agent.create("engineer", ...
    model       = "gpt-4o", ...
    systemPrompt= "You are an expert MATLAB and signal processing engineer.", ...
    memory      = true)

%% Simple question-answer
response = wyvern.agent.run("engineer", ...
    "What is the difference between DFT and FFT?")

fprintf("Agent response:\n%s\n", response)

%% Multi-turn conversation (agent remembers context)
wyvern.agent.run("engineer", "What window functions reduce spectral leakage?")
wyvern.agent.run("engineer", "Which of those did you mention first?")
% The agent remembers the previous answer.

%% Stream tokens live to the console
wyvern.agent.stream("engineer", ...
    "Walk me through designing an IIR Butterworth low-pass filter in MATLAB.")

%% Get verbose output (steps + token count)
result = wyvern.agent.run("engineer", ...
    "What MATLAB function computes the CWT?", verbose=true)
fprintf("Tokens used: %d\n", result.tokensUsed)

%% Reset memory (start a fresh conversation)
wyvern.agent.reset("engineer")

%% Agent with tools
wyvern.agent.create("researcher", ...
    model  = "gpt-4o", ...
    tools  = ["web_search", "calculator"], ...
    memory = false)

result = wyvern.agent.run("researcher", ...
    "What is the square root of 144 times pi?")
disp(result)
