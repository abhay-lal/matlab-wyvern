classdef test_rag < matlab.unittest.TestCase
% TEST_RAG  Unit tests for wyvern.rag.* functions
%
%   Run: results = runtests('test_rag')
%
%   Requires a running Wyvern server.  A sample .txt file is created in
%   tempdir for indexing tests; no external API calls needed for search.

    properties
        SampleDir   (1,1) string
        CollectionId = "test_rag_collection"
    end

    methods (TestClassSetup)
        function startServerAndCreateDocs(tc)
            try
                wyvern.util.checkServer();
            catch
                wyvern.setup();
            end

            % Write a small sample document
            tc.SampleDir = fullfile(tempdir, 'wyvern_test_docs');
            if ~exist(tc.SampleDir, 'dir')
                mkdir(tc.SampleDir);
            end
            sampleFile = fullfile(tc.SampleDir, 'sample.txt');
            fid = fopen(sampleFile, 'w');
            fprintf(fid, ['Wyvern is a MATLAB toolbox for LLM agents.\n' ...
                'It uses LangGraph, LangChain, and HuggingFace.\n' ...
                'RAG enables question answering over documents.\n']);
            fclose(fid);

            % Index the docs
            wyvern.rag.loadDocs(tc.CollectionId, tc.SampleDir, fileTypes=["txt"]);
        end
    end

    methods (Test)
        function testLoadDocsReturnsStatus(tc)
            colId = "test_rag_load_status";
            status = wyvern.rag.loadDocs(colId, tc.SampleDir, fileTypes=["txt"]);
            tc.verifyClass(status, 'struct');
            tc.verifyTrue(isfield(status, 'chunksIndexed'));
            tc.verifyGreaterThan(status.chunksIndexed, 0);
            tc.verifyTrue(status.ready);
        end

        function testSearchReturnsChunks(tc)
            chunks = wyvern.rag.search(tc.CollectionId, "LangGraph agents");
            tc.verifyClass(chunks, 'struct');
            tc.verifyNotEmpty(chunks);
            tc.verifyTrue(isfield(chunks(1), 'text'));
            tc.verifyTrue(isfield(chunks(1), 'score'));
        end

        function testSearchTopKRespected(tc)
            chunks = wyvern.rag.search(tc.CollectionId, "MATLAB", topK=1);
            tc.verifyLessThanOrEqual(numel(chunks), 1);
        end

        function testLoadInvalidPathThrows(tc)
            tc.verifyError( ...
                @() wyvern.rag.loadDocs("bad", "/nonexistent/path/abc123"), ...
                'Wyvern:fileNotFound');
        end

        function testSearchUnknownCollectionThrows(tc)
            tc.verifyError( ...
                @() wyvern.rag.search("no_such_collection", "test"), ...
                'Wyvern:notFound');
        end
    end
end
