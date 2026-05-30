function root = toolboxRoot()
% WYVERN.UTIL.TOOLBOXROOT  Return the absolute path to the matlab-wyvern root
%
%   root = wyvern.util.toolboxRoot()
%
%   Resolves the root by walking up from this file's location:
%     <root>/toolbox/+wyvern/util/toolboxRoot.m  →  <root>

    thisDir  = fileparts(mfilename('fullpath'));   % .../toolbox/+wyvern/util
    wyvernDir = fileparts(thisDir);               % .../toolbox/+wyvern
    toolboxDir = fileparts(wyvernDir);            % .../toolbox
    root = fileparts(toolboxDir);                 % .../matlab-wyvern
end
