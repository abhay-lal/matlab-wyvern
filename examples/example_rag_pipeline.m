%% Wyvern — Example 2: RAG Pipeline
% Index a folder of documents and ask questions over them.
% Uses sentence-transformers for embeddings (no API key needed for indexing).

%% Setup
% wyvern.setup()   % uncomment on first run

%% Index the sample document
sampleDir = fullfile(fileparts(mfilename('fullpath')), 'data');

status = wyvern.rag.loadDocs("signals", sampleDir, ...
    fileTypes     = ["txt"], ...
    chunkSize     = 400, ...
    chunkOverlap  = 50, ...
    embeddingModel= "all-MiniLM-L6-v2")

fprintf("Indexed %d chunks.\n", status.chunksIndexed)

%% Semantic search (no LLM required)
chunks = wyvern.rag.search("signals", "preprocessing steps before FFT", topK=3)

for i = 1:numel(chunks)
    fprintf("\n--- Chunk %d (score=%.4f) ---\n%s\n", ...
        i, chunks(i).score, chunks(i).text)
end

%% RAG question answering (requires OpenAI API key in server/.env)
answer = wyvern.rag.ask("signals", ...
    "What preprocessing steps are recommended before computing an FFT?", ...
    model = "gpt-4o", ...
    topK  = 4)

fprintf("\nAnswer:\n%s\n", answer)

%% Verbose answer (includes source files and chunk count)
result = wyvern.rag.ask("signals", ...
    "How do CNNs process spectrograms?", ...
    verbose = true)

fprintf("Answer: %s\n", result.answer)
fprintf("Sources: %s\n", strjoin(result.sources, ", "))
fprintf("Chunks used: %d\n", result.chunksUsed)

%% Index a larger folder (your own documents)
% wyvern.rag.loadDocs("myPapers", "/Users/you/Documents/papers/", ...
%     fileTypes = ["pdf", "txt", "md"], ...
%     chunkSize = 600)
