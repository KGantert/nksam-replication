function p = nksam_path(kind, name)
% NKSAM_PATH  Absolute path of a codebase folder or of a file in it.
%
%   p = nksam_path(kind)          folder
%   p = nksam_path(kind, name)    file in that folder
%
%   kind      folder                      contents
%   'root'    <codebase>/                 run_all.m, run_all_options.m, get_params.m, README.md
%   'lib'     lib/                        shared functions and setup scripts
%   'model'   model/                      Dynare model (nk_time.dyn, steady state)
%   'data'    data/                       data.mat
%   'cache'   cache/                      regenerable caches (check_cache_signature.m)
%   'figures' results/figures/            figures (*.eps, *.png)
%   'tables'  results/tables/             tables (*.tex, tab_*.txt, *.csv)
%   'txt'     results/txt/                reports, numbers quoted in the text, logs of single scripts
%   'mat'     results/mat/                intermediate results passed between scripts (*.mat)
%   'logs'    results/logs/               run_all logs
%   Output folders are created on first use. Every script writes through this
%   function, so no output depends on the current folder.

root = fileparts(fileparts(mfilename('fullpath')));   % <codebase>/lib -> <codebase>
switch lower(kind)
    case 'root';                                   d = root;
    case {'lib', 'model', 'data', 'cache'};        d = fullfile(root, lower(kind));
    case {'figures', 'tables', 'txt', 'mat', 'logs'}; d = fullfile(root, 'results', lower(kind));
    otherwise
        error('nksam_path: unknown kind "%s".', kind);
end
if ~isfolder(d); mkdir(d); end
if nargin < 2 || isempty(name)
    p = d;
else
    p = fullfile(d, name);
end
end
