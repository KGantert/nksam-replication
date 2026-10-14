% online_V1_steady_states.m -- Online Appendix V.1: steady-state effects of goods market SaM
% -------------------------------------------------------------------------
% PRODUCES (chapters/online_appendix/ap_additional_results.tex, sec:stst_add_gdp):
%   results/figures/fig_stst_fixed.eps     fig:stst_fixed    (experiment 1: psiQ, muN, epsilon fixed)
%   results/figures/fig_stst_targeted.eps  fig:stst_targeted (experiment 2: q, N and the markup targeted)
%   results/txt/fig_stst_endpoints.txt     numbers quoted in the text (largest gamma_Q)
% Both conventions are computed on local copies of p0 (flags, p0 and the
% cache are untouched). Figures: lib/figs_stst_experiments.m.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));

% Experiment 1 (fixed parameters): psiQ, muN, muD, ... stay at their baseline-calibrated values
% (stored in p0 by build_p), so BOTH switches must be flipped: stst_target = 0 (use the fixed
% parameters instead of recomputing them from the time-use targets q, N) and mp_select = 0
% (epsilon is the exogenous input). With stst_target = 1 output equals q for every gamQ.
p_fix = p0;  p_fix.stst_target = 0;  p_fix.mp_select = 0;
stst_fixed = compute_stst_experiments(p_fix, par.gamQ_loop_stst, [], par.epsP_loop_stst, par.psiQ_loop_stst);
% Experiment 2 (targeted calibration): q, N and the markup are targets.
p_tgt = p0;  p_tgt.stst_target = 1;  p_tgt.mp_select = 1;
stst_targ  = compute_stst_experiments(p_tgt, par.gamQ_loop_stst, par.mp_loop_stst, [], par.psiQ_loop_stst);

figs_stst_experiments(stst_fixed, stst_targ, par.gamQ_loop_stst, par.epsP_loop_stst, ...
                      par.mp_loop_stst, par.psiQ_loop_stst, lwdth);

% Endpoint report (largest gamQ) for checking the numbers quoted in the text of Online Appendix V.1;
% printed to the command window and written to results/txt/fig_stst_endpoints.txt.
ii  = numel(par.gamQ_loop_stst);
fid = fopen(nksam_path('txt', 'fig_stst_endpoints.txt'), 'w');
for f = [1, fid]
    fprintf(f, '\nExperiment 1 (fixed parameters), gamQ = %.3f, ratios SaM/NK (search price: level)\n', par.gamQ_loop_stst(ii));
    fprintf(f, '%8s %12s %14s %14s %10s\n', 'epsilon', 'search price', 'price elast.', 'markup', 'output');
    for kk = 1:numel(par.epsP_loop_stst)
        fprintf(f, '%8.2f %12.3f %14.3f %14.3f %10.3f\n', par.epsP_loop_stst(kk), ...
            stst_fixed.ps_epsP_sam(ii,kk), ...
            stst_fixed.pe_epsP_sam(ii,kk) / stst_fixed.pe_epsP_nk(ii,kk), ...
            stst_fixed.mp_epsP_sam(ii,kk) / stst_fixed.mp_epsP_nk(ii,kk), ...
            stst_fixed.t_epsP_sam(ii,kk)  / stst_fixed.t_epsP_nk(ii,kk));
    end
    fprintf(f, '\nOutput ratio at gamQ = %.3f by psiQ:', par.gamQ_loop_stst(ii));
    fprintf(f, ' %.3f', stst_fixed.t_psiQ_sam(ii,:) ./ stst_fixed.t_psiQ_nk(ii,:));
    fprintf(f, '   (psiQ =');  fprintf(f, ' %.2f', par.psiQ_loop_stst);  fprintf(f, ')\n');
    fprintf(f, 'Output ratio at gamQ = 0 (first grid point), by epsilon:');
    fprintf(f, ' %.3f', stst_fixed.t_epsP_sam(1,:) ./ stst_fixed.t_epsP_nk(1,:));  fprintf(f, '\n');
    fprintf(f, 'Experiment 2 (targeted), gamQ = %.3f: eps ratio SaM/NK by markup:', par.gamQ_loop_stst(ii));
    fprintf(f, ' %.3f', stst_targ.eps_epsP_sam(ii,:) ./ stst_targ.eps_epsP_nk(ii,:));
    fprintf(f, ';  search price by markup:'); fprintf(f, ' %.3f', stst_targ.ps_epsP_sam(ii,:)); fprintf(f, '\n');
end
fclose(fid);
