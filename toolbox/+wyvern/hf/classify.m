function result = classify(modelId, texts, options)
% WYVERN.HF.CLASSIFY  Run text classification with a HuggingFace model
%
%   % Standard classification (model's own labels):
%   result = wyvern.hf.classify("distilbert-base-uncased-finetuned-sst-2-english", ...
%                                {"I love this!", "This is terrible."})
%
%   % Zero-shot classification (supply your own labels):
%   result = wyvern.hf.classify("facebook/bart-large-mnli", ...
%                                {"MATLAB is great for engineering"}, ...
%                                labels=["science","politics","sports"])
%
% Arguments:
%   modelId  - string, loaded model
%   texts    - string array / cell array of strings
%   labels   - string array of candidate labels (zero-shot only, optional)
%
% Returns:
%   result.labels  - string array of predicted/candidate labels
%   result.scores  - N×L double matrix (N texts, L labels)

    arguments
        modelId         (1,1) string
        texts                        % string array or cell array
        options.labels  string = string.empty  % string array, optional
    end

    wyvern.util.checkServer();

    textsCell = toStringCell(texts);

    payload.model_id = modelId;
    payload.texts    = textsCell;

    if ~isempty(options.labels)
        payload.labels = cellstr(options.labels);
    else
        payload.labels = [];   % JSON null
    end

    resp = wyvern.util.postRequest("/hf/classify", payload);

    result.labels = string(resp.labels);
    result.scores = double(resp.scores);
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
