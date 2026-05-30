function load(modelId, options)
% WYVERN.HF.LOAD  Load a HuggingFace model into the server
%
%   wyvern.hf.load("all-MiniLM-L6-v2", task="feature-extraction")
%   wyvern.hf.load("gpt2", task="text-generation", device="cuda")
%   wyvern.hf.load("facebook/bart-large-mnli", task="zero-shot-classification")
%
% Arguments:
%   modelId  - string, HuggingFace model identifier
%   task     - string, pipeline task name (default: "feature-extraction")
%   device   - "cpu" | "cuda" | "auto"  (default: "cpu")

    arguments
        modelId         (1,1) string
        options.task    (1,1) string = "feature-extraction"
        options.device  (1,1) string {mustBeMember(options.device, ["cpu","cuda","auto"])} = "cpu"
    end

    wyvern.util.checkServer();

    payload.model_id = modelId;
    payload.task     = options.task;
    payload.device   = options.device;

    resp = wyvern.util.postRequest("/hf/load", payload);
    fprintf('Model "%s" loaded (task: %s).\n', resp.model_id, resp.task);
end
