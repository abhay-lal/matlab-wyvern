function jsonStr = mat2json(data)
% WYVERN.UTIL.MAT2JSON  Convert MATLAB data to a JSON string
%
%   jsonStr = wyvern.util.mat2json(myStruct)
%   jsonStr = wyvern.util.mat2json({"text one", "text two"})
%
%   Wraps jsonencode with consistent options:
%     - Cell arrays of strings become JSON arrays of strings
%     - Structs become JSON objects
%     - NaN and Inf are encoded as null (JSON-safe)
%
%   Returns a string scalar.

    arguments
        data  % any JSON-serialisable MATLAB value
    end

    jsonStr = string(jsonencode(data, 'ConvertInfAndNaN', true));
end
