function chunks = search(collectionId, query, options)
% WYVERN.RAG.SEARCH  Semantic search over an indexed document collection
%
%   chunks = wyvern.rag.search("papers", "transformer attention mechanism")
%   chunks = wyvern.rag.search("papers", "methodology", topK=10)
%
% Arguments:
%   collectionId  - string, previously loaded collection name
%   query         - string, natural language search query
%   topK          - integer, number of results to return (default: 5)
%
% Returns:
%   chunks  - struct array with fields:
%               .text   string, chunk content
%               .source string, source file path
%               .score  double, similarity score

    arguments
        collectionId     (1,1) string
        query            (1,1) string
        options.topK     (1,1) double {mustBeInteger,mustBePositive} = 5
    end

    wyvern.util.checkServer();

    payload.collection_id = collectionId;
    payload.query         = query;
    payload.top_k         = options.topK;

    resp = wyvern.util.postRequest("/rag/search", payload);

    % resp.chunks is a struct array from jsondecode
    rawChunks = resp.chunks;
    n = numel(rawChunks);
    chunks = struct('text', cell(n,1), 'source', cell(n,1), 'score', cell(n,1));
    for i = 1:n
        chunks(i).text   = string(rawChunks(i).text);
        chunks(i).source = string(rawChunks(i).source);
        chunks(i).score  = double(rawChunks(i).score);
    end
end
