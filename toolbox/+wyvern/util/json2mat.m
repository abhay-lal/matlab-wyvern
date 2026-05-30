function data = json2mat(jsonStr)
% WYVERN.UTIL.JSON2MAT  Convert a JSON string to MATLAB struct/array
%
%   data = wyvern.util.json2mat('{"answer":"hello","score":0.9}')
%   % returns struct with fields .answer and .score
%
%   data = wyvern.util.json2mat('[1,2,3]')
%   % returns [1 2 3]
%
%   Wraps jsondecode for a consistent interface.

    arguments
        jsonStr (1,1) string
    end

    data = jsondecode(char(jsonStr));
end
