function answer = ask(collectionId, question, options)
% WYVERN.RAG.ASK  Answer a question using RAG over an indexed collection
%
%   answer = wyvern.rag.ask("papers", "What preprocessing steps were used?")
%   answer = wyvern.rag.ask("papers", "Summarise the findings", model="gpt-4o", topK=8)
%
% Arguments:
%   collectionId  - string, previously loaded collection name
%   question      - string, natural language question
%   model         - string, LLM model for synthesis (default: "gpt-4o")
%   apiKey        - string, API key (default: reads from server/.env)
%   topK          - integer, chunks to retrieve (default: 5)
%
% Returns:
%   answer  - string (default) when options.verbose = false
%             struct with .answer, .sources, .chunksUsed when verbose = true

    arguments
        collectionId     (1,1) string
        question         (1,1) string
        options.model    (1,1) string  = "gpt-4o"
        options.apiKey   (1,1) string  = ""
        options.topK     (1,1) double  {mustBeInteger,mustBePositive} = 5
        options.verbose  (1,1) logical = false
    end

    wyvern.util.checkServer();

    payload.collection_id = collectionId;
    payload.question      = question;
    payload.model         = options.model;
    payload.top_k         = options.topK;

    if options.apiKey ~= ""
        payload.api_key = options.apiKey;
    else
        payload.api_key = [];
    end

    resp = wyvern.util.postRequest("/rag/ask", payload);

    if options.verbose
        answer.answer     = string(resp.answer);
        answer.sources    = string(resp.sources);
        answer.chunksUsed = resp.chunks_used;
    else
        answer = string(resp.answer);
    end
end
