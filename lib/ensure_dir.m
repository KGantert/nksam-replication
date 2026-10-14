function ensure_dir(filepath)
% ENSURE_DIR  Create the parent directory of filepath if it doesn't exist.
%
%   ensure_dir(filepath)
%
%   Guard before fopen/save: a missing folder makes fopen return -1 and
%   fprintf(-1, ...) silently writes nothing.
d = fileparts(filepath);
if ~isempty(d) && ~exist(d, 'dir')
    mkdir(d);
end
end
