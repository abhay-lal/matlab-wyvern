function status = loadDocs(collectionId, folderPath, options)
% WYVERN.RAG.LOADDOCS  Index documents into a named vector store collection
%
%   wyvern.rag.loadDocs("papers", "/home/user/research/")
%   wyvern.rag.loadDocs("papers", "/home/user/research/", fileTypes=["pdf","txt"])
%   wyvern.rag.loadDocs("papers", "/home/user/research/", chunkSize=800, chunkOverlap=100)
%
%   Prints progress: "Indexing 47 chunks from 12 documents..."
%
% Arguments:
%   collectionId    - string, user-defined name for this document set
%   folderPath      - string, absolute path to a folder or single file
%   fileTypes       - string array, extensions to index (default: ["pdf","txt","md"])
%   chunkSize       - integer, tokens per chunk (default: 500)
%   chunkOverlap    - integer, overlap between consecutive chunks (default: 50)
%   embeddingModel  - string, sentence-transformers model (default: "all-MiniLM-L6-v2")
%
% Returns:
%   status.collectionId   - string
%   status.chunksIndexed  - integer
%   status.ready          - logical

    arguments
        collectionId           (1,1) string
        folderPath             (1,1) string
        options.fileTypes      string = ["pdf","txt","md"]
        options.chunkSize      (1,1) double {mustBeInteger,mustBePositive} = 500
        options.chunkOverlap   (1,1) double {mustBeInteger,mustBeNonnegative} = 50
        options.embeddingModel (1,1) string = "all-MiniLM-L6-v2"
    end

    wyvern.util.checkServer();

    % Validate path exists (early friendly error)
    if ~exist(folderPath, 'file') && ~exist(folderPath, 'dir')
        error('Wyvern:fileNotFound', ...
            'Path ''%s'' does not exist or is not accessible.', folderPath);
    end

    fprintf('Indexing documents from "%s"...\n', folderPath);

    payload.collection_id    = collectionId;
    payload.path             = folderPath;
    payload.file_types       = cellstr(options.fileTypes);
    payload.chunk_size       = options.chunkSize;
    payload.chunk_overlap    = options.chunkOverlap;
    payload.embedding_model  = options.embeddingModel;

    resp = wyvern.util.postRequest("/rag/load", payload);

    fprintf('  Collection "%s" ready: %d chunks indexed.\n', ...
        resp.collection_id, resp.chunks_indexed);

    status.collectionId  = string(resp.collection_id);
    status.chunksIndexed = resp.chunks_indexed;
    status.ready         = strcmp(resp.status, 'ready');
end
