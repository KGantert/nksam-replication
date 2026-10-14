% online_V3_efficiency_irfs.m -- Online Appendix V.3: IRFs to a matching efficiency shock
% -------------------------------------------------------------------------
% PRODUCES (chapters/online_appendix/ap_additional_results.tex, sec:irf_add_cost-push):
%   results/figures/fig_irf_default_efficiency.eps   fig:irf_add_cost-push
% Same four scenarios as main_s5_irfs.m (lib/compute_default_scenarios.m,
% cached in cache/default_scenarios.mat).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));
compute_default_scenarios;

% -- Matching-efficiency IRF panel (fig:irf_add_cost-push) ----------------
pcfg = base_plot_cfg;
pcfg.shocks       = "eT";
pcfg.shock_labels = "Matching Efficiency";
pcfg.shock_tags   = "efficiency";
pcfg.fig_prefix   = nksam_path('figures', 'fig_irf_default');
pcfg.legend       = default_scenario_legend;
pcfg.styles       = default_scenario_styles;
pcfg.legend_cols  = 4;

plot_irf_exercise(res_1, pcfg);

clearvars pcfg;

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
