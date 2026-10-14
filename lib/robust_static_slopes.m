function S = robust_static_slopes(checks)
% ROBUST_STATIC_SLOPES  Output-gap slopes of the utilization and price-
%   elasticity gaps, Theta_Y^q (CU_t) and Theta_Y^Xi (PE_t), from the
%   reduced-form slope model (sec:sam_gap_channels), at the
%   baseline calibration and for each robustness variant whose
%   .slopes_ovr is a cell. Each variant is re-calibrated via build_p
%   (same steady-state targets). Variants with .slopes_ovr = NaN (not in
%   the reduced-form model: capital, long-term contracts, inventories)
%   get NaN, i.e. an empty table cell.
%
%   Baseline flags = lib/setup_slopes.m's model-selection flags.
%
%   S.base   = [Theta_Y^q, Theta_Y^Xi] at the baseline
%   S.val{c} = nE x 2 levels, S.ratio{c} = nE x 2 ratios to S.base
%   S.thr_base, S.thr{c} (2026-10-11) = regime thresholds [omega*_q, omega*_Xi]
%            = [-Theta_Y^q/Theta_u^q, -Theta_Y^Xi/Theta_u^Xi] (sec:phase_diagram),
%            baseline (1 x 2) and per variant (nE x 2; NaN if not nested), for
%            the regimes table tab:robust_regimes.
par0   = get_params('slopes');
dat    = load_nksam_data();
flags0 = struct('ghh', 0, 'hw_select', 1, 'hp_select', 0, ...
                'mp_select', 1, 'stst_target', 1, 'kapP_select', 0);

[S.base, S.thr_base] = slopes_at(par0, flags0, dat);
fprintf('  static slopes, baseline: Theta_Y^q = %.4f, Theta_Y^Xi = %.4f\n', S.base);
fprintf('  thresholds, baseline: omega*_q = %.4f, omega*_Xi = %.4f\n', S.thr_base);

S.val   = cell(1, numel(checks));
S.ratio = cell(1, numel(checks));
S.thr   = cell(1, numel(checks));
for c = 1:numel(checks)
    nE = numel(checks(c).ext);
    S.val{c}   = NaN(nE, 2);
    S.ratio{c} = NaN(nE, 2);
    S.thr{c}   = NaN(nE, 2);
    for k = 1:nE
        ovr = checks(c).ext(k).slopes_ovr;
        if ~iscell(ovr), continue; end        % not available -> empty cell
        X.par = par0; X.flags = flags0;
        X = robust_apply_ovr(X, ovr);
        try
            [S.val{c}(k, :), S.thr{c}(k, :)] = slopes_at(X.par, X.flags, dat);
            S.ratio{c}(k, :) = S.val{c}(k, :) ./ S.base;
        catch ME
            warning('robust_static_slopes: %s variant %d failed: %s', ...
                    checks(c).tag, k, ME.message);
        end
    end
end
end

% =========================================================================
function [v, thr] = slopes_at(par, flags, dat)
p = build_p(par, dat, flags);
[out_sam, ~] = compute_wedges(p);
v   = real([out_sam.CU_t, out_sam.PE_t]);
thr = real([-out_sam.CU_t/out_sam.CU_ue, -out_sam.PE_t/out_sam.PE_ue]);   % as online_VI_rigidity_grid.m
end
