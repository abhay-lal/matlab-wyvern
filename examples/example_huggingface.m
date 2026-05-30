%% Wyvern — Example 3: HuggingFace Models
% Load HuggingFace models for embeddings, generation, and classification
% directly from MATLAB.  No API key required.

%% Setup
% wyvern.setup()   % uncomment on first run

%% 1. Sentence Embeddings
% Load a lightweight embedding model (~80 MB, downloads on first use)
wyvern.hf.load("all-MiniLM-L6-v2", task="feature-extraction")

sentences = {
    "MATLAB is excellent for numerical computing"
    "Python is popular in the machine learning community"
    "Signal processing requires Fourier analysis"
    "LLMs are transforming how engineers work"
};

E = wyvern.hf.embed("all-MiniLM-L6-v2", sentences);
fprintf("Embedding matrix: %d x %d\n", size(E))

%% Cosine similarity matrix
E_norm = E ./ vecnorm(E, 2, 2);
simMatrix = E_norm * E_norm';

figure
imagesc(simMatrix)
colorbar
title("Sentence Similarity Matrix")
xticks(1:4); xticklabels(sentences); xtickangle(20)
yticks(1:4); yticklabels(sentences)
clim([0 1])

%% Most similar sentence to a query
query = wyvern.hf.embed("all-MiniLM-L6-v2", {"frequency domain analysis"});
query_norm = query ./ norm(query);
sims = E_norm * query_norm';
[~, idx] = max(sims);
fprintf("Most similar to query: %s\n", sentences{idx})

%% 2. Zero-shot Classification
wyvern.hf.load("facebook/bart-large-mnli", task="zero-shot-classification")

texts  = {"I need to compute the FFT of my accelerometer data"
          "The stock market dropped 200 points today"};
labels = ["signal processing", "finance", "sports", "cooking"];

result = wyvern.hf.classify("facebook/bart-large-mnli", texts, labels=labels);
for i = 1:numel(texts)
    [~, best] = max(result.scores(i,:));
    fprintf("Text %d → %s\n", i, result.labels(best))
end

%% 3. Text Generation (lightweight model)
% wyvern.hf.load("gpt2", task="text-generation")
% text = wyvern.hf.generate("gpt2", "The Fourier transform of a Gaussian is", ...
%     maxNewTokens=50, doSample=true, temperature=0.8)
% disp(text)
