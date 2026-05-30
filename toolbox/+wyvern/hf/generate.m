function text = generate(modelId, prompt, options)
% WYVERN.HF.GENERATE  Run text generation with a HuggingFace model
%
%   text = wyvern.hf.generate("gpt2", "Once upon a time")
%   text = wyvern.hf.generate("gpt2", "The answer is", maxNewTokens=100, doSample=true)
%
% Arguments:
%   modelId       - string, must be loaded with task="text-generation"
%   prompt        - string, the input prompt
%   maxNewTokens  - integer (default 256)
%   temperature   - float 0–2 (default 1.0, only used when doSample=true)
%   doSample      - logical (default false)
%
% Returns:
%   text - string, the full generated text

    arguments
        modelId              (1,1) string
        prompt               (1,1) string
        options.maxNewTokens (1,1) double {mustBeInteger, mustBePositive} = 256
        options.temperature  (1,1) double {mustBeInRange(options.temperature, 0, 2)} = 1.0
        options.doSample     (1,1) logical = false
    end

    wyvern.util.checkServer();

    payload.model_id       = modelId;
    payload.prompt         = prompt;
    payload.max_new_tokens = options.maxNewTokens;
    payload.temperature    = options.temperature;
    payload.do_sample      = options.doSample;

    resp = wyvern.util.postRequest("/hf/generate", payload);
    text = string(resp.generated_text);
end
