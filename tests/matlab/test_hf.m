classdef test_hf < matlab.unittest.TestCase
% TEST_HF  Unit tests for wyvern.hf.* functions
%
%   Run: results = runtests('test_hf')
%
%   Requires a running Wyvern server.  Uses the lightweight
%   "all-MiniLM-L6-v2" model (~80 MB) for embedding tests.
%   No API key required for HuggingFace inference tests.

    properties (Constant)
        EmbedModel = "all-MiniLM-L6-v2"
    end

    methods (TestClassSetup)
        function startServerAndLoadModel(tc)
            try
                wyvern.util.checkServer();
            catch
                wyvern.setup();
            end
            wyvern.hf.load(tc.EmbedModel, task="feature-extraction");
        end
    end

    methods (Test)
        function testEmbedReturnsMatrix(tc)
            texts = {"Hello world", "MATLAB is great"};
            E = wyvern.hf.embed(tc.EmbedModel, texts);
            tc.verifyClass(E, 'double');
            tc.verifySize(E, [2, NaN]);   % 2 rows, any number of cols
            tc.verifyGreaterThan(size(E, 2), 0);
        end

        function testEmbedSingleString(tc)
            E = wyvern.hf.embed(tc.EmbedModel, "single sentence");
            tc.verifyClass(E, 'double');
            tc.verifyEqual(size(E, 1), 1);
        end

        function testEmbedDimensionConsistent(tc)
            E1 = wyvern.hf.embed(tc.EmbedModel, {"a"});
            E2 = wyvern.hf.embed(tc.EmbedModel, {"b", "c"});
            tc.verifyEqual(size(E1, 2), size(E2, 2));
        end

        function testEmbedUnloadedModelThrows(tc)
            tc.verifyError( ...
                @() wyvern.hf.embed("not-loaded-model", {"test"}), ...
                'Wyvern:notFound');
        end

        function testCosineSimilarityRange(tc)
            E = wyvern.hf.embed(tc.EmbedModel, {"cat", "dog", "quantum mechanics"});
            % Normalised dot product should be in [-1, 1]
            norms = vecnorm(E, 2, 2);
            E_norm = E ./ norms;
            sim = E_norm * E_norm';
            tc.verifyLessThanOrEqual(max(sim(:)), 1.01);
            tc.verifyGreaterThanOrEqual(min(sim(:)), -1.01);
        end
    end
end
