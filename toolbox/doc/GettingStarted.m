%% Wyvern — Getting Started
% This live script walks you through all core Wyvern features.
% Run it top-to-bottom after setting your API key in server/.env.
%
% PREREQUISITE: Run the following once before this script:
%   addpath(genpath('<path-to-matlab-wyvern>/toolbox'))
%   wyvern.setup(apiKey="your-openai-key")

%% Section 1: Setup and Health Check

% If Wyvern is already running from a previous session:
wyvern.status()

% To start fresh:
% wyvern.setup()

%% Section 2: First Agent — Simple Q&A

wyvern.agent.create("intro_agent", ...
    model       = "gpt-4o", ...
    systemPrompt= "You are a concise MATLAB and engineering assistant.", ...
    memory      = true)

q1 = wyvern.agent.run("intro_agent", ...
    "What is MATLAB primarily used for in engineering? Answer in 2 sentences.")
disp(q1)

%% Section 3: RAG over a Sample Document

% Locate the sample document bundled with the toolbox
examplesDir  = fullfile(fileparts(mfilename('fullpath')), '..', 'examples', 'data');
sampleFile   = fullfile(examplesDir, 'signal_processing_overview.txt');

% Index the document
wyvern.rag.loadDocs("demo_docs", fileparts(sampleFile), fileTypes=["txt"])

% Semantic search (no LLM required)
chunks = wyvern.rag.search("demo_docs", "wavelet transform applications", topK=2);
fprintf("Top chunk:\n%s\n\n", chunks(1).text)

% Full RAG answer
answer = wyvern.rag.ask("demo_docs", ...
    "What preprocessing steps should I perform before computing an FFT?", ...
    model="gpt-4o")
disp(answer)

%% Section 4: HuggingFace Embedding + Similarity Search

% Load a lightweight embedding model
wyvern.hf.load("all-MiniLM-L6-v2", task="feature-extraction")

% Embed a set of engineering concepts
concepts = {
    "fast Fourier transform"
    "wavelet decomposition"
    "neural network classification"
    "IIR filter design"
    "principal component analysis"
};
E = wyvern.hf.embed("all-MiniLM-L6-v2", concepts);

% Find the most similar concept to a query
query = wyvern.hf.embed("all-MiniLM-L6-v2", {"spectral analysis of signals"});
E_norm   = E ./ vecnorm(E, 2, 2);
q_norm   = query ./ norm(query);
sims     = E_norm * q_norm';
[score, idx] = max(sims);
fprintf("Query: 'spectral analysis of signals'\n")
fprintf("Most similar concept: '%s' (cosine sim = %.4f)\n", concepts{idx}, score)

% Visualise similarity matrix
E_norm_all = E ./ vecnorm(E, 2, 2);
simMatrix  = E_norm_all * E_norm_all';
figure
imagesc(simMatrix, [0 1])
colorbar
title("Concept Similarity Matrix")
xticks(1:5); xticklabels(concepts); xtickangle(25)
yticks(1:5); yticklabels(concepts)

%% Section 5: Multi-Turn Conversation with Memory

wyvern.agent.create("mentor", ...
    model       = "gpt-4o", ...
    systemPrompt= "You are an experienced DSP engineer mentoring a student.", ...
    memory      = true)

wyvern.agent.run("mentor", "I want to understand IIR filters.");
r2 = wyvern.agent.run("mentor", "What are the trade-offs compared to FIR?");
r3 = wyvern.agent.run("mentor", "Can you give me MATLAB code for the type you recommended?");

disp("=== Final mentor response ===")
disp(r3)

% Reset for a fresh conversation
wyvern.agent.reset("mentor")

%% Done!
fprintf(['\nYou have completed the Wyvern Getting Started guide.\n' ...
    'Explore the examples/ folder for more advanced usage.\n'])
