function out = robust_run_check(chk, nk_cfg, sam_cfg, dynare_opts)
% ROBUST_RUN_CHECK  Solve all scenarios of one robustness check.
%
%   out.sam{k}  NK-SaM model with variant k    (robust_solve)
%   out.nk{k}   benchmark with variant k, only if chk.bench_changes
%   out.iso{k}  search-effort-only cyclicality stats, NK-SaM variant k
%   out.fail(k) true if variant k could not be solved (e.g. no steady
%               state); its cells are left empty, and the figure and the
%               table skip it. out.msg{k} holds the error message.
%
%   2026-09-24 (after the first run): failures are caught PER VARIANT, so
%   one failing variant (quality search, gamma_P = 0.2: Dynare error 19)
%   no longer drops the whole check.
nE       = numel(chk.ext);
out.sam  = cell(1, nE);
out.nk   = cell(1, nE);
out.iso  = cell(1, nE);
out.fail = false(1, nE);
out.msg  = cell(1, nE);
for k = 1:nE
    fprintf('  [%s] variant %d/%d: %s\n', chk.tag, k, nE, chk.ext(k).change);
    try
        cfg_sam = robust_apply_ovr(sam_cfg, chk.ext(k).dyn_ovr);
        cfg_nk  = robust_apply_ovr(nk_cfg,  chk.ext(k).dyn_ovr);
        out.sam{k} = robust_solve(cfg_sam, dynare_opts);
        if chk.bench_changes
            out.nk{k} = robust_solve(cfg_nk, dynare_opts);
        end
        out.iso{k} = robust_iso_stats(cfg_sam, dynare_opts);
    catch ME
        out.fail(k) = true;
        out.msg{k}  = ME.message;
        out.sam{k} = []; out.nk{k} = []; out.iso{k} = [];
        fprintf(2, '    *** variant %d FAILED and is skipped: %s\n', k, ME.message);
    end
end
if all(out.fail)
    error('robust_run_check: all variants of "%s" failed.', chk.tag);
end
end
