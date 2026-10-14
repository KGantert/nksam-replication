function out = robust_cached(cache_file, sig, force_rerun, fun)
% ROBUST_CACHED  Load out from cache_file if it exists AND was computed
%   under the same signature sig (calibration, check definition, options);
%   otherwise run out = fun() and save it. force_rerun = true always
%   recomputes. fun = [] means LOAD ONLY: return [] instead of computing
%   (used for checks not in checks_to_run, so the summary table stays
%   complete). Edits to the model files or code are handled globally by
%   lib/check_cache_signature.m, which deletes all caches.
%
%   2026-09-24: signatures are compared WITHOUT get_params' `ranges`
%   struct. Every range value a scenario uses is already contained in the
%   check definition (dyn_ovr) or in nk_cfg, so an unrelated range edit
%   (e.g. ranges.gamP_high) no longer invalidates every cache.
out = [];
if ~force_rerun && exist(cache_file, 'file')
    S = load(cache_file, 'out', 'sig');
    if isfield(S, 'sig') && isequaln(strip_ranges(S.sig), strip_ranges(sig))
        fprintf('  reusing cache %s\n', cache_file);
        out = S.out;
        return;
    end
    fprintf('  cache %s is stale (signature changed)\n', cache_file);
end
if isempty(fun)
    fprintf('  -> not in checks_to_run: left empty in the table\n');
    return;
end
out = fun();
ensure_dir(cache_file);
save(cache_file, 'out', 'sig');
end

function s = strip_ranges(s)
% Remove what does not affect the solution: get_params' ranges (their used
% values are in dyn_ovr / nk_cfg) and, 2026-09-24, the presentation fields
% of a check (labels, legend, styles, title), so relabelling or
% renumbering checks does not invalidate their caches.
if ~isstruct(s), return; end
if isfield(s, 'gp') && isstruct(s.gp) && isfield(s.gp, 'ranges')
    s.gp = rmfield(s.gp, 'ranges');
end
if isfield(s, 'chk') && isstruct(s.chk)
    c = s.chk;
    s.chk = struct('tag', c.tag, 'bench_changes', c.bench_changes, ...
                   'dyn_ovr', {{c.ext.dyn_ovr}});
end
if isfield(s, 'base')
    s.base = strip_ranges(s.base);
end
end
