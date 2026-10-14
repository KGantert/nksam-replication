% online_VI_fixed_kapP.m -- Online Appendix VI, check 5 (fixed kappa_P): price Phillips-curve slopes
% -------------------------------------------------------------------------
% PRODUCES (chapters/online_appendix/ap_robustness.tex, sec:robust_kapP):
%   results/txt/fixed_kapP_summary.txt            numbers of sec:robust_kapP: kappa_P, implied
%                                                 labor-share slopes, price Phillips-curve slopes
%                                                 at the baseline, fixed vs slope-targeted
%   results/mat/fixed_kapP_results.mat
%
% Baseline calibration: kappa_P targets the labor-share Phillips-curve slope
% NKPC_Slope = 0.051 in each model (NK-SaM ~173, benchmark 117.6; 0.047 until 2026-10-06). Here
% kappa_P is FIXED at the benchmark value eps/NKPC_Slope in both models --
% the same value as robustness check 5 (lib/robust_define_checks.m), whose
% IRFs and impact responses (Figure VI.3, Table VI.2) are produced by
% online_VI_robustness.m. Reduced-form model only (flags.kapP_select = 1;
% equivalence of the two calibration modes: diagnostics/diag_kapP_switch.m).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));

% kappa_P of check 5: benchmark value eps/NKPC_Slope, as in lib/robust_define_checks.m
[dpar, ~, ~, ~, dtarget] = get_params('dynare');
kapP_fixed = dpar.epss / dtarget.nkpc_slope;

% Baseline (slope-targeted) and fixed-kappa_P solutions at the baseline calibration
[out_sam_tgt, out_nk_tgt] = compute_wedges(p0);
spar              = par;
spar.kapP         = kapP_fixed;
flags_fix         = flags;
flags_fix.kapP_select = 1;
p_fix = build_p(spar, dat, flags_fix);
[out_sam_fix, out_nk_fix] = compute_wedges(p_fix);

% Sweeps under fixed kappa_P, as in lib/setup_slopes.m (exps(1) and exps_gray); saved to the .mat
% for replication (their figure was dropped from the paper, 2026-10-12)
p0 = p_fix;
[gamQ_cut, ~, gamQ_loop] = compute_gamQ_cutoff(p0, spar.mp_cut_loop, spar.epsP_cut_loop, spar.gamQ_low, spar.gamQ_high);
exps = struct();
exps(1).name       = 'nuD';
exps(1).param      = 'subQ';
exps(1).values     = spar.subQ_loop;
exps(1).sam_fields = {'CU_t','CU_ue','CU_ag', 'PE_t','PE_ue','PE_ag', ...
                      'LW_t','LW_ue','LW_ag', 'AS_t','AS_ue','AS_ag', ...
                      'AD_t','AD_ue','AD_ag', 'WG_t','WG_ue','WG_ag','kapP','pc_slope_impl', ...
                      'D_t','D_ue','D_ag', 'MC_t','MC_ue','MC_ag'};
exps(1).nk_fields  = {'LW_t','LW_ue','LW_ag', 'AS_t','AS_ue','AS_ag', ...
                      'AD_t','AD_ue','AD_ag', 'WG_t','WG_ue','WG_ag','kapP','pc_slope_impl', ...
                      'MC_t','MC_ue','MC_ag'};
[res_sam, res_nk] = compute_sensitivity(p0, gamQ_loop, spar.nuD_sens_loop, exps);
exps_gray = struct();
exps_gray(1).name       = 'nuD';
exps_gray(1).param      = 'subQ';
exps_gray(1).values     = spar.subQ_low;
exps_gray(1).sam_fields = {'CU_t','CU_ue','PE_t','PE_ue', 'LW_t','LW_ue', 'D_t','D_ue', 'MC_t','MC_ue', ...
                           'AD_t','AD_ue', 'AS_t','AS_ue', 'WG_t','WG_ue'};
exps_gray(1).nk_fields  = {};
[res_gray, ~] = compute_sensitivity(p0, gamQ_loop, spar.nuD_sens_loop, exps_gray);


% -------------------------------------------------------------------------
% Summary: numbers of sec:robust_kapP
% -------------------------------------------------------------------------
fid = fopen(nksam_path('txt', 'fixed_kapP_summary.txt'), 'w');
if fid == -1; error('online_VI_fixed_kapP: cannot write fixed_kapP_summary.txt'); end
fprintf(fid, 'FIXED kappa_P (robustness check 5), reduced-form model -- %s\n\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, 'kappa_P fixed at %.2f in both models (benchmark eps/NKPC_Slope)\n', kapP_fixed);
fprintf(fid, 'Slope-targeted kappa_P: NK-SaM %.2f, benchmark %.2f\n', out_sam_tgt.kapP, out_nk_tgt.kapP);
fprintf(fid, 'Labor-share Phillips-curve slope under fixed kappa_P: NK-SaM %.4f, benchmark %.4f (target %.4f), ratio %.2f\n\n', ...
        out_sam_fix.pc_slope_impl, out_nk_fix.pc_slope_impl, p_fix.pc_slope, out_sam_fix.pc_slope_impl / p_fix.pc_slope);
fprintf(fid, 'Price Phillips-curve slopes at the baseline (gamma_Q = %.2f, Gamma_Q ~ 0, nu_D = nu_N):\n', par.gamQ);
fprintf(fid, '%-22s %12s %12s %12s\n', '', 'targeted', 'fixed', 'benchmark');
fprintf(fid, '%-22s %12.3f %12.3f %12.3f\n', 'output gap (AS_t)',       out_sam_tgt.AS_t,  out_sam_fix.AS_t,  out_nk_tgt.AS_t);
fprintf(fid, '%-22s %12.3f %12.3f %12.3f\n', 'unemployment gap (AS_ue)', out_sam_tgt.AS_ue, out_sam_fix.AS_ue, out_nk_tgt.AS_ue);
fclose(fid);

save(nksam_path('mat', 'fixed_kapP_results.mat'), 'kapP_fixed', 'res_sam', 'res_nk', 'res_gray', ...
     'out_sam_fix', 'out_nk_fix', 'out_sam_tgt', 'out_nk_tgt');
fprintf('wrote %s\n', nksam_path('txt', 'fixed_kapP_summary.txt'));
