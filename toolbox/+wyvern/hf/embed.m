function embeddings = embed(modelId, texts)
% WYVERN.HF.EMBED  Get embedding vectors from a HuggingFace model
%
%   E = wyvern.hf.embed("all-MiniLM-L6-v2", {"sentence one", "sentence two"})
%   % E is an N×D double matrix (N texts, D embedding dimensions)
%
%   % Cosine similarity between first two rows:
%   sim = dot(E(1,:), E(2,:)) / (norm(E(1,:)) * norm(E(2,:)))
%
%   % Find most similar text to a query:
%   query = wyvern.hf.embed("all-MiniLM-L6-v2", {"my query"})
%   sims = E * query' ./ (vecnorm(E,2,2) * norm(query))
%   [~, idx] = max(sims)
%
% Arguments:
%   modelId  - string, must be loaded first with wyvern.hf.load
%   texts    - string array, char, or cell array of strings
%
% Returns:
%   embeddings - N×D double matrix

    arguments
        modelId  (1,1) string
        texts               % string array, cell array, or char
    end

    wyvern.util.checkServer();

    % Normalise texts to a cell array of char for JSON encoding
    textsCell = toStringCell(texts);

    payload.model_id = modelId;
    payload.texts    = textsCell;

    resp = wyvern.util.postRequest("/hf/embed", payload);

    % resp.embeddings is an N×D numeric matrix after jsondecode
    embeddings = double(resp.embeddings);
end

% ---------- private ----------

function c = toStringCell(texts)
    if ischar(texts)
        c = {texts};
    elseif isstring(texts)
        c = cellstr(texts);
    elseif iscell(texts)
        c = cellfun(@char, texts, 'UniformOutput', false);
    else
        error('Wyvern:invalidInput', ...
            'texts must be a string array, char, or cell array of strings.');
    end
end
