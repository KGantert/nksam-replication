function info = check_cache_signature(repo_root)
% CHECK_CACHE_SIGNATURE  Delete ALL caches when the calibration, the model,
%   the data or any execution file changed since the caches were built, so
%   a user can rely on the calibration in get_params.m actually being used.
%
%   info = check_cache_signature(repo_root)
%
%   Called at the start of lib/setup_dynare.m and lib/setup_slopes.m (so
%   every script checks, whether run by run_all or on its own) and once at
%   the start of run_all.
%
%   SIGNATURE (compared with isequaln against cache/cache_signature.mat):
%     - all VALUES returned by get_params('dynare') and get_params('slopes')
%     - the full text of get_params.m, every *.m file in lib/ and scripts/,
%       model/nk_time.dyn, model/nk_time_steadystate.m and data/data.mat
%       (any edit counts, comments included; a full run takes ~20 minutes,
%       so recomputing too often is cheap compared with a stale result)
%   Not included: run_all.m, run_all_options.m, lib/run_all_engine.m,
%   diagnostics/ (they do not feed any cache).
%   On a change: deletes every *.mat in cache/ (except the signature),
%   prints what changed, stores the new signature and the time of the change
%   (info.changed_at). run_all uses changed_at to refuse intermediate
%   results in results/mat/ that are older than the last change.
%   No stored signature yet (first run) counts as a change.
%
%   POLICY (environment variable NKSAM_CACHE_POLICY, set by run_all):
%     'auto'  (default)  as above
%     'reuse'            never invalidate, only warn (quick figure tweaks)
%
%   info fields: changed (logical), changed_at (datenum), what (cellstr)

sig_file = fullfile(repo_root, 'cache', 'cache_signature.mat');
policy   = lower(strtrim(getenv('NKSAM_CACHE_POLICY')));
if isempty(policy); policy = 'auto'; end

% ---- Files in the signature ---------------------------------------------------
files = {'get_params.m', 'model/nk_time.dyn', 'model/nk_time_steadystate.m', 'data/data.mat'};
for sub = {'lib', 'scripts'}
    f = dir(fullfile(repo_root, sub{1}, '*.m'));
    f = f(~strcmp({f.name}, 'run_all_engine.m'));   % master-script code: feeds no cache
    files = [files, strcat(sub{1}, '/', {f.name})]; %#ok<AGROW>
end
files = sort(files);

% ---- Current signature --------------------------------------------------------
sig = struct();
[sig.dyn.par, sig.dyn.parHW, sig.dyn.parSAM, sig.dyn.shock, sig.dyn.target, ...
    sig.dyn.ranges] = get_params('dynare');
sig.slopes = get_params('slopes');
sig.files  = struct();
for k = 1:numel(files)
    key = matlab.lang.makeValidName(files{k});
    fid = fopen(fullfile(repo_root, files{k}), 'r');
    if fid == -1
        sig.files.(key) = [];
    else
        sig.files.(key) = fread(fid, Inf, '*uint8')';
        fclose(fid);
    end
end

% ---- Compare ------------------------------------------------------------------
info = struct('changed', false, 'changed_at', 0, 'what', {{}});
if isfile(sig_file)
    S = load(sig_file, 'sig', 'changed_at');
    info.changed_at = S.changed_at;
    info.what = diff_parts(S.sig, sig);
else
    info.what = {'no stored signature (first run)'};
end
if isempty(info.what)
    return;                                   % caches are consistent
end

if strcmp(policy, 'reuse')
    warning('check_cache_signature:stale', ['Calibration/model/code changed (%s) but ' ...
        'NKSAM_CACHE_POLICY = reuse: caches kept, results may be STALE.'], ...
        strjoin(info.what, ', '));
    return;
end

% ---- Invalidate -----------------------------------------------------------------
f = dir(fullfile(repo_root, 'cache', '*.mat'));
f = f(~strcmp({f.name}, 'cache_signature.mat'));
for k = 1:numel(f)
    delete(fullfile(f(k).folder, f(k).name));
end
changed_at = now; %#ok<TNOW1>
if ~isfolder(fileparts(sig_file)); mkdir(fileparts(sig_file)); end
save(sig_file, 'sig', 'changed_at');
info.changed = true;
info.changed_at = changed_at;
what = info.what;
if numel(what) > 6; what = [what(1:6), {sprintf('... (%d more)', numel(info.what) - 6)}]; end
fprintf(['check_cache_signature: calibration/model/code changed (%s)\n' ...
         '  -> deleted %d cache file(s); results will be recomputed.\n'], ...
         strjoin(what, ', '), numel(f));
end

function what = diff_parts(a, b)
what = {};
parts = {'dyn', 'get_params(''dynare'')'; 'slopes', 'get_params(''slopes'')'};
for k = 1:size(parts, 1)
    if ~isfield(a, parts{k, 1}) || ~isequaln(a.(parts{k, 1}), b.(parts{k, 1}))
        what{end+1} = parts{k, 2}; %#ok<AGROW>
    end
end
fb = fieldnames(b.files);
for k = 1:numel(fb)
    if ~isfield(a, 'files') || ~isfield(a.files, fb{k}) || ...
            ~isequal(a.files.(fb{k}), b.files.(fb{k}))
        what{end+1} = fb{k}; %#ok<AGROW>
    end
end
if isfield(a, 'files')
    gone = setdiff(fieldnames(a.files), fb);
    what = [what, strcat(gone(:)', ' (removed)')];
end
end
