% main_s5_irfs.m -- Section 5 (Simulation Analysis): phase diagram and impulse responses
% -------------------------------------------------------------------------
% PRODUCES (chapters/simulation.tex):
%   results/figures/fig_phase_diagram.eps       fig:phase_diagram (sec:phase_diagram)
%   results/figures/fig_irf_default_tfp.eps     fig:irf_default_tfp
%   results/figures/fig_irf_default_policy.eps  fig:irf_default_policy
%   results/figures/fig_irf_default_search.eps  fig:irf_default_search_effort
%   results/figures/fig_irf_default_eis.eps     fig:irf_default_eis (epsilon-cost-push)
%   results/txt/phase_diagram.txt               thresholds and Okun numbers quoted in sec:phase_diagram
%   results/txt/irf_impact.txt                  responses in quarters 1-4 (numbers quoted in Section 5)
% Four scenarios (benchmark, perfect complements, Cobb-Douglas, CES) from
% lib/compute_default_scenarios.m, cached in cache/default_scenarios.mat and
% shared with online_V3_efficiency_irfs.m.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));
compute_default_scenarios;

% -- IRF panels: TFP, monetary policy, search effort (matching efficiency: online_V3_efficiency_irfs.m) --
pcfg = base_plot_cfg;
pcfg.shocks       = ["eA",  "eM",              "eD"];
pcfg.shock_labels = ["TFP", "Monetary Policy",  "Search Effort"];
pcfg.shock_tags   = ["tfp", "policy",           "search"];
pcfg.fig_prefix   = nksam_path('figures', 'fig_irf_default');
pcfg.legend       = default_scenario_legend;
pcfg.styles       = default_scenario_styles;
pcfg.legend_cols  = 4;

plot_irf_exercise(res_1, pcfg);

% -- Standalone epsilon-cost-push (formerly "EIS") default figure (same 4 scenarios) --------------------
pcfg_eis = base_plot_cfg;
pcfg_eis.shocks       = "eP";
pcfg_eis.shock_labels = "ε-Cost-Push";   % figure window name only
pcfg_eis.shock_tags   = "eis";
pcfg_eis.fig_prefix   = nksam_path('figures', 'fig_irf_default');
pcfg_eis.legend       = default_scenario_legend;
pcfg_eis.styles       = default_scenario_styles;
pcfg_eis.legend_cols  = 4;

plot_irf_exercise(res_1, pcfg_eis);

% -- Barro-Grossman phase diagram -----------------------------------------
pcfg_pd = struct();
pcfg_pd.scenario     = 3;
pcfg_pd.shocks       = ["eA",       "eM",               "eD",            "eT",                 "eP"];
pcfg_pd.shock_labels = ["Technology","Monetary Policy",  "Search Effort", "Matching Efficiency","$\epsilon$-Cost-Push"];   % legend uses the LaTeX interpreter
pcfg_pd.colors       = [col_blue; col_orange; col_yellow; col_purple; col_green];
pcfg_pd.fig_name     = 'Barro-Grossman Phase Diagram';
pcfg_pd.fig_prefix   = nksam_path('figures', 'fig_phase_diagram');
pcfg_pd.legend_cols  = 3;   % ignored: phase-diagram legend is fixed at 3 columns
pcfg_pd.okun_elast   = -2.23;   % knotekHow2007, as in sec:sam_gap_channels
pcfg_pd.norm_impact  = true;
pcfg_pd.extra_scale  = [1, 0.5, 1, 1, 1];   % per-shock factor on top of the impact normalization (order of pcfg_pd.shocks): monetary policy at half the common norm for legibility (stated in the figure note)
% Regime geometry of Proposition 2 (prop:regimes): price-elasticity / Euler
% threshold beta*_Xi = -PE_t/PE_ue from the same analytical slopes
% (compute_wedges, home production ON) as tab:slope_summary (main_s5_slope_summary.m).
par_pd = get_params('slopes');
dat_pd = load_nksam_data();
flags_pd = struct('ghh', 0, 'hw_select', 1, 'hp_select', 0, 'mp_select', 1, ...
                  'stst_target', 1, 'kapP_select', 0);
[out_sam_pd, ~] = compute_wedges(build_p(par_pd, dat_pd, flags_pd));
pcfg_pd.xi_beta      = -out_sam_pd.PE_t / out_sam_pd.PE_ue;
pcfg_pd.shade_amp    = true;
pcfg_pd.mark_impact  = true;
fprintf('Phase diagram: beta*_q = %.3f (diagonal boundary), beta*_Xi = %.3f (threshold)\n', ...
        -out_sam_pd.CU_t / out_sam_pd.CU_ue, pcfg_pd.xi_beta);

pd_info = plot_phase_diagram(res_1, pcfg_pd);

% Impact and early responses quoted in Section 5 -> results/txt/irf_impact.txt
irf_vars = ["gdp_obs", "gdp_gap", "ue_gap", "ue", "piC", "w_obs", "lpr_obs", "mc_obs", "cu", "ped_obs", "lw_obs", "d_obs"];
irf_scen = ["Benchmark", "Complements", "Cobb-Douglas", "CES"];
fid = fopen(nksam_path('txt', 'irf_impact.txt'), 'w');
fprintf(fid, 'Impulse responses, quarters 1-4, percent deviations (main_s5_irfs.m, %s)\n', datestr(now)); %#ok<TNOW1,DATST>
for sh = ["eA", "eM", "eD", "eT", "eP"]
    fprintf(fid, '\n==== shock %s ====\n%-12s', sh, 'variable');
    fprintf(fid, '%28s', irf_scen); fprintf(fid, '\n');
    for v = irf_vars
        fprintf(fid, '%-12s', v);
        for k = 1:numel(res_1)
            if isfield(res_1(k).irfs, sh) && isfield(res_1(k).irfs.(sh), v)
                x = res_1(k).irfs.(sh).(v);
                fprintf(fid, '  %6.3f %6.3f %6.3f %6.3f', x(1:4));
            else
                fprintf(fid, '%28s', '--');
            end
        end
        fprintf(fid, '\n');
    end
end
fclose(fid);

% Numbers quoted in sec:phase_diagram / sec:okun_limits -> results/txt/phase_diagram.txt
fid = fopen(nksam_path('txt', 'phase_diagram.txt'), 'w');
fprintf(fid, 'Phase diagram (main_s5_irfs.m, %s), Cobb-Douglas NK-SaM scenario\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, 'beta*_q  (diagonal boundary, -CU_t/CU_ue) = %.3f\n', -out_sam_pd.CU_t / out_sam_pd.CU_ue);
fprintf(fid, 'beta*_Xi (threshold, -PE_t/PE_ue)         = %.3f\n', pcfg_pd.xi_beta);
fn = fieldnames(pd_info);
for k = 1:numel(fn)
    v = pd_info.(fn{k});
    if isnumeric(v) && ~isempty(v) && numel(v) <= 10
        fprintf(fid, '%-16s = %s\n', fn{k}, mat2str(v, 4));
    end
end
if ~isempty(pd_info.regime_switch)
    fprintf(fid, 'classified differently in levels and gaps: %s\n', char(strjoin(string(pd_info.regime_switch), ', ')));
end
fclose(fid);

clearvars pcfg pcfg_eis pcfg_pd par_pd dat_pd flags_pd out_sam_pd fid fn k v x sh irf_vars irf_scen;

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
