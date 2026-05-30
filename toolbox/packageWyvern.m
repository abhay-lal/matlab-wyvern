function packageWyvern()
% PACKAGEWYVERN  Build the Wyvern.mltbx toolbox package
%
%   Run this script from the matlab-wyvern root directory in MATLAB to
%   produce Wyvern.mltbx, suitable for MATLAB File Exchange submission
%   and Add-On Explorer.
%
%   Requirements:
%     - MATLAB R2024a or later
%     - Run from the matlab-wyvern root directory
%
%   Usage:
%     cd /path/to/matlab-wyvern
%     addpath(genpath('toolbox'))
%     packageWyvern()

    rootDir = pwd;

    % ---- Toolbox options ------------------------------------------------
    opts = matlab.addons.toolbox.ToolboxOptions( ...
        fullfile(rootDir, 'toolbox'), ...   % folder to package
        'Wyvern');                           % toolbox name / identifier

    opts.ToolboxName            = 'Wyvern — MATLAB LLM Agent Toolbox';
    opts.ToolboxVersion         = '0.1.0';
    opts.AuthorName             = 'Wyvern Contributors';
    opts.AuthorEmail            = '';
    opts.AuthorCompany          = '';
    opts.Summary                = ['Transparent access to LangChain, LangGraph, ' ...
                                   'and HuggingFace from MATLAB without writing Python.'];
    opts.Description            = fileread(fullfile(rootDir, 'README.md'));
    opts.MinimumMatlabRelease   = 'R2024a';
    opts.MaximumMatlabRelease   = '';

    % Include Getting Started live script and examples
    opts.ToolboxGettingStartedGuide = fullfile(rootDir, 'toolbox', 'doc', 'GettingStarted.m');

    % Output path
    outputFile = fullfile(rootDir, 'Wyvern.mltbx');
    opts.OutputFile = outputFile;

    % ---- Package ---------------------------------------------------------
    fprintf('Packaging Wyvern toolbox...\n');
    matlab.addons.toolbox.packageToolbox(opts);
    fprintf('Done! Package written to: %s\n', outputFile);
end
