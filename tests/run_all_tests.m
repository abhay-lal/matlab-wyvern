% run_all_tests.m — Run the complete Wyvern test suite
%
%   Run from the matpy-wyvern root directory in MATLAB after wyvern.setup():
%
%       cd /path/to/matpy-wyvern
%       addpath(genpath('toolbox'))
%       run('tests/run_all_tests.m')
%
%   Starts the server if not already running, executes all MATLAB unit tests,
%   prints a pass/fail summary, then stops the server.

fprintf('╔══════════════════════════════╗\n')
fprintf('║   Wyvern Test Suite v%s   ║\n', wyvern.version())
fprintf('╚══════════════════════════════╝\n\n')

% ── 1. Start server ──────────────────────────────────────────────────────────
fprintf('Starting server...\n')
try
    wyvern.util.checkServer();
    fprintf('  Server already running.\n\n')
catch
    wyvern.setup();
end

% ── 2. Run MATLAB unit tests ─────────────────────────────────────────────────
fprintf('Running MATLAB unit tests...\n\n')
testSuite = fullfile(fileparts(mfilename('fullpath')), 'matlab');
results   = runtests(testSuite, Verbosity=2);

% ── 3. Summary ───────────────────────────────────────────────────────────────
nPassed    = sum([results.Passed]);
nFailed    = sum([results.Failed]);
nIncomplete= sum([results.Incomplete]);

fprintf('\n════════════════════════════════\n')
fprintf('Results\n')
fprintf('  Passed:   %d\n', nPassed)
fprintf('  Failed:   %d\n', nFailed)
fprintf('  Skipped:  %d\n', nIncomplete)
fprintf('════════════════════════════════\n')

if nFailed > 0
    fprintf('\nFailed tests:\n')
    failed = results([results.Failed]);
    for i = 1:numel(failed)
        fprintf('  ✗ %s\n', failed(i).Name)
        if ~isempty(failed(i).Details)
            fprintf('    %s\n', failed(i).Details.DiagnosticRecord.Report)
        end
    end
    fprintf('\n')
    wyvern.stop();
    error('Wyvern:testsFailed', '%d test(s) failed.', nFailed)
end

fprintf('\n✓ All %d tests passed.\n\n', nPassed)
wyvern.stop()
