% main_s5_slope_summary.m -- Section 5 (sec:channel_aggregation): Table 3, tab:slope_summary
% -------------------------------------------------------------------------
% PRODUCES
%   results/tables/tab_slope_summary.txt   Table 3 (simulation.tex) in the paper's layout and
%                                          rounding (typed into the paper)
%   results/txt/beta_alternatives.txt      beta_shock under impact-only, |Y|-weighted and
%                                          four-quarter cumulative weighting (footnote)
%   results/txt/slope_components.txt       channel slopes Theta_Y, Theta_u and the decomposition of
%                                          Proposition 2 (direct layer, tightness coefficient, beta*)
%   results/txt/slope_summary_log.txt      log of Part 2
%   results/mat/gap_irfs.mat, slope_summary_results.mat
%
% Part 1 (Dynare): IRFs of the output and unemployment gaps for each shock,
%   NK-SaM and benchmark, home production ON (the calibration of the
%   reduced-form slopes in lib/compute_wedges.m). The benchmark switches goods
%   market SaM off and keeps home production.
% Part 2 (reduced form): comovement beta_shock = sum_t(u_t*Y_t)/sum_t(Y_t^2),
%   the slope of the unemployment-gap IRF on the output-gap IRF through the
%   origin over the IRF horizon, and the aggregate slopes
%   Theta_Y^{Agg,shock} = Theta_Y + Theta_u*beta_shock for the five channels.
% Diagnostics not in the paper (horizon-by-horizon slopes, moment-based
% beta): diagnostics/diag_slope_paths.m.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% =========================================================================
% PART 1 (Dynare): gap IRFs
% =========================================================================
cfg_saam_g  = base_cfg;
cfg_bench_g = base_cfg;
cfg_bench_g.parSAM.gamQ = 1e-4;
cfg_bench_g.parSAM.subQ = ranges.subQ_high;
cfg_bench_g.target.cuss = 1;
cfg_bench_g.target.dnss = 1e-4;

res_saam_g  = dynare_scenario(cfg_saam_g,  dynare_opts);
res_bench_g = dynare_scenario(cfg_bench_g, dynare_opts);

shocks_saam_g  = ["eA", "eM", "eP", "eD", "eT"];
shocks_bench_g = ["eA", "eM", "eP"];

gap_irfs = struct();
for s = shocks_saam_g
    gap_irfs.saam.(s).gdp_gap = res_saam_g.irfs.(s).gdp_gap(:);
    gap_irfs.saam.(s).ue_gap  = res_saam_g.irfs.(s).ue_gap(:);
end
for s = shocks_bench_g
    gap_irfs.benchmark.(s).gdp_gap = res_bench_g.irfs.(s).gdp_gap(:);
    gap_irfs.benchmark.(s).ue_gap  = res_bench_g.irfs.(s).ue_gap(:);
end

var_sim_select_saved_g = dynare_opts.var_sim_select;
save(nksam_path('mat', 'gap_irfs.mat'), 'gap_irfs', 'var_sim_select_saved_g');
fprintf('Saved %s\n', nksam_path('mat', 'gap_irfs.mat'));

clearvars cfg_saam_g cfg_bench_g res_saam_g res_bench_g shocks_saam_g shocks_bench_g s ...
          gap_irfs var_sim_select_saved_g;

% Dynare work done: delete its regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();

% =========================================================================
% PART 2 (reduced form): comovement and aggregate slopes
% =========================================================================
diary_file = nksam_path('txt', 'slope_summary_log.txt');
if exist(diary_file, 'file'); delete(diary_file); end
diary(diary_file);
diary on;

try

%% -------------------------------------------------------------------
% 1. LOAD GAP IRFS (Part 1 above)
% -------------------------------------------------------------------
fprintf('[1/3] Loading gap_irfs.mat (Part 1)...\n');
load(nksam_path('mat', 'gap_irfs.mat'), 'gap_irfs');

%% -------------------------------------------------------------------
% 2. ANALYTICAL SLOPES (Theta_Y, Theta_u), home production ON
% -------------------------------------------------------------------
fprintf('[2/3] Computing analytical slopes (hw_select=1)...\n');
par = get_params('slopes');
dat = load_nksam_data();

flags.ghh         = 0;
flags.hw_select   = 1;   % home production ON -- matches this script's simulations
flags.hp_select   = 0;
flags.mp_select   = 1;
flags.stst_target = 1;
flags.kapP_select = 0;

p0 = build_p(par, dat, flags);
[out_sam0, out_nk0] = compute_wedges(p0);
fprintf('Baseline check OK: gamQ = %.4f, nuD = nuN = %.4f\n', par.gamQ, par.nuN);

% Channels and shocks
channels = struct( ...
    'M',  struct('prefix', 'AD', 'benchmark', true,  'label', 'Dynamic IS slope'), ...
    'pi', struct('prefix', 'AS', 'benchmark', true,  'label', 'Price Phillips slope'), ...
    'w',  struct('prefix', 'WG', 'benchmark', true,  'label', 'Real wage growth slope'), ...
    'q',  struct('prefix', 'CU', 'benchmark', false, 'label', 'Utilization gap elasticity'), ...
    'Xi', struct('prefix', 'PE', 'benchmark', false, 'label', 'Price-elasticity gap elasticity'));
chan_order = {'M', 'pi', 'w', 'q', 'Xi'};

shock_names_saam   = ["eA", "eM", "eP", "eD", "eT"];
shock_labels_saam  = ["TFP", "Policy", "Cost-Push", "Search", "Matching Eff."];
shock_names_bench  = ["eA", "eM", "eP"];
shock_labels_bench = ["TFP", "Policy", "Cost-Push"]; %#ok<NASGU>

%% -------------------------------------------------------------------
% 3. HORIZON-WEIGHTED BETA_SHOCK AND AGGREGATE SLOPES (Table 3)
% -------------------------------------------------------------------
fprintf('[3/3] Horizon-weighted beta_shock (regression-through-origin)...\n');

% beta_shock = sum_t[ ue_gap_IRF(t) * gdp_gap_IRF(t) ] / sum_t[ gdp_gap_IRF(t)^2 ]
% -- the OLS slope of ue_gap_IRF on gdp_gap_IRF across the whole
% horizon, forced through the origin (no intercept: at t=0 both gaps
% are zero by construction, so a slope-through-origin is the natural
% fit here, not an arbitrary restriction).
%
% Never divides pointwise, so no threshold or mask is needed: a horizon
% where gdp_gap_IRF(t) is near zero contributes almost nothing to
% either the numerator or the denominator, and is therefore
% automatically down-weighted rather than excluded outright.
beta_shock_weighted = struct('saam', struct(), 'benchmark', struct());
for ss = 1:numel(shock_names_saam)
    s = shock_names_saam(ss);
    Y_irf = gap_irfs.saam.(s).gdp_gap;
    u_irf = gap_irfs.saam.(s).ue_gap;
    beta_shock_weighted.saam.(s) = sum(u_irf .* Y_irf) / sum(Y_irf.^2);
end
for ss = 1:numel(shock_names_bench)
    s = shock_names_bench(ss);
    Y_irf = gap_irfs.benchmark.(s).gdp_gap;
    u_irf = gap_irfs.benchmark.(s).ue_gap;
    beta_shock_weighted.benchmark.(s) = sum(u_irf .* Y_irf) / sum(Y_irf.^2);
end

fprintf('\nHorizon-weighted beta_shock (NK-SaM):      ');
for ss = 1:numel(shock_names_saam)
    fprintf('%s=%.3f  ', shock_labels_saam(ss), beta_shock_weighted.saam.(shock_names_saam(ss)));
end
fprintf('\n');
fprintf('Horizon-weighted beta_shock (Benchmark):   ');
for ss = 1:numel(shock_names_bench)
    fprintf('%s=%.3f  ', shock_labels_bench(ss), beta_shock_weighted.benchmark.(shock_names_bench(ss)));
end
fprintf('\n');

% Aggregate slope per channel and shock: Theta_Y + Theta_u * beta_shock (Table 3)
agg_slopes_weighted = struct('saam', struct(), 'benchmark', struct());
for cc = 1:numel(chan_order)
    key = chan_order{cc};
    ch  = channels.(key);

    Theta_Y = out_sam0.([ch.prefix '_t']);
    Theta_u = out_sam0.([ch.prefix '_ue']);
    for ss = 1:numel(shock_names_saam)
        s = shock_names_saam(ss);
        agg_slopes_weighted.saam.(key).(s) = Theta_Y + Theta_u * beta_shock_weighted.saam.(s);
    end

    if ch.benchmark
        Theta_Y = out_nk0.([ch.prefix '_t']);
        Theta_u = out_nk0.([ch.prefix '_ue']);
        for ss = 1:numel(shock_names_bench)
            s = shock_names_bench(ss);
            agg_slopes_weighted.benchmark.(key).(s) = Theta_Y + Theta_u * beta_shock_weighted.benchmark.(s);
        end
    end
end

% -------------------------------------------------------------------
% TABLE OUTPUT (2026-09-29): tab:slope_summary (chapters/simulation.tex)
% in the paper's layout and rounding -> results/tables/tab_slope_summary.txt.
% The paper shows TFP, Policy, Cost-Push, Search; Matching Eff. is added
% here for reference only.
% -------------------------------------------------------------------
tab_file = nksam_path('tables', 'tab_slope_summary.txt');
row_def = { ...   % label, channel key ('' = beta), format
    'Comovement beta_shock',                        '',   '%8.2f'; ...
    'Dynamic IS slope Theta_Y^{Agg,M}',             'M',  '%8.2f'; ...
    'Price Phillips slope Theta_Y^{Agg,pi}',        'pi', '%8.3f'; ...
    'Real wage growth slope Theta_Y^{Agg,w}',       'w',  '%8.2f'; ...
    'Utilization gap elasticity Theta_Y^{Agg,q}',   'q',  '%8.2f'; ...
    'Price-elasticity gap elast. Theta_Y^{Agg,Xi}', 'Xi', '%8.2f'};
col_lbl = {'TFP', 'Policy', 'CostPush', 'Search', 'MatchEff'};
TL = {sprintf('tab:slope_summary -- aggregate slopes by shock, horizon-weighted beta_shock (main_s5_slope_summary.m, %s)', ...
              datestr(now, 'yyyy-mm-dd HH:MM')), ... %#ok<TNOW1,DATST>
      'Paper columns: TFP, Policy, Cost-Push, Search (Matching Eff. for reference). -- = not defined.', ''};
blocks = {'Benchmark Model', 'benchmark', shock_names_bench, 4; ...
          'NK-SaM Model',    'saam',      shock_names_saam,  6};
for bb = 1:size(blocks, 1)
    TL{end+1} = sprintf('%-46s%s', blocks{bb, 1}, sprintf('%10s', col_lbl{:})); %#ok<AGROW>
    TL{end+1} = repmat('-', 1, 46 + 10 * numel(col_lbl)); %#ok<AGROW>
    for rr = 1:blocks{bb, 4}
        ln = sprintf('%-46s', row_def{rr, 1});
        for ss = 1:numel(shock_names_saam)
            s = shock_names_saam(ss);
            v = NaN;
            if any(blocks{bb, 3} == s)
                if isempty(row_def{rr, 2})
                    v = beta_shock_weighted.(blocks{bb, 2}).(s);
                else
                    v = agg_slopes_weighted.(blocks{bb, 2}).(row_def{rr, 2}).(s);
                end
            end
            if isnan(v)
                ln = [ln sprintf('%10s', '--')]; %#ok<AGROW>
            else
                ln = [ln sprintf(['  ' row_def{rr, 3}], v)]; %#ok<AGROW>
            end
        end
        TL{end+1} = ln; %#ok<AGROW>
    end
    TL{end+1} = ''; %#ok<AGROW>
end
fid = fopen(tab_file, 'w');
if fid == -1; error('main_s5_slope_summary: cannot write %s', tab_file); end
fprintf(fid, '%s\n', TL{:});
fclose(fid);
fprintf('%s\n', TL{:});
fprintf('Saved %s\n', tab_file);

% -------------------------------------------------------------------
% ALTERNATIVE WEIGHTINGS OF beta_shock (robustness footnote in
% sec:channel_aggregation): impact only u_1/Y_1; |Y_t|-weighted average
% of u_t/Y_t, i.e. sum(sign(Y_t)*u_t)/sum(|Y_t|); four-quarter cumulative
% sum_{t<=4} u_t / sum_{t<=4} Y_t -> results/txt/beta_alternatives.txt; last column: output gap
% summed over the IRF horizon (sec:robust_sim: search effort's sums to about zero)
% -------------------------------------------------------------------
alt_file = nksam_path('txt', 'beta_alternatives.txt');
fid = fopen(alt_file, 'w');
if fid == -1; error('main_s5_slope_summary: cannot write %s', alt_file); end
fprintf(fid, 'beta_shock under alternative weightings (main_s5_slope_summary.m, %s)\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, '%-10s %-14s %10s %10s %10s %10s %12s\n', 'model', 'shock', 'baseline', 'impact', '|Y|-wtd', '4q cum.', 'sum Y_t');
alt_models = {'saam', shock_names_saam; 'benchmark', shock_names_bench};
for mm = 1:size(alt_models, 1)
    for s = alt_models{mm, 2}
        Y_irf = gap_irfs.(alt_models{mm, 1}).(s).gdp_gap(:);
        u_irf = gap_irfs.(alt_models{mm, 1}).(s).ue_gap(:);
        b_imp = u_irf(1) / Y_irf(1);
        b_abs = sum(sign(Y_irf) .* u_irf) / sum(abs(Y_irf));
        b_cum = sum(u_irf(1:4)) / sum(Y_irf(1:4));
        fprintf(fid, '%-10s %-14s %10.2f %10.2f %10.2f %10.2f %12.4f\n', alt_models{mm, 1}, s, ...
                beta_shock_weighted.(alt_models{mm, 1}).(s), b_imp, b_abs, b_cum, sum(Y_irf));
    end
end
fprintf(fid, 'sum Y_t: output gap summed over the IRF horizon (%d quarters), percent\n', numel(gap_irfs.saam.eM.gdp_gap));
fclose(fid);
fprintf('Saved %s\n', alt_file);


% -------------------------------------------------------------------
% CHANNEL SLOPES AND PROPOSITION 2 (curves.tex, prop:regimes)
%   -> results/txt/slope_components.txt: Theta_Y, Theta_u of every channel
%   (both models) and the decomposition of the aggregate dynamic IS slope,
%   Theta^{Agg,M}(beta) = phi_C + direct layer + c * Theta^{Agg,q}(beta),
%   with c = Theta_u^M / Theta_u^q (tightness-layer coefficient),
%   direct layer = Theta_Y^M - phi_C - c * Theta_Y^q, phi_C = benchmark Theta_Y^M,
%   beta*_q = -Theta_Y^q/Theta_u^q and beta*_Xi = -(Theta_Y^M - phi_C)/Theta_u^M.
% -------------------------------------------------------------------
comp_file = nksam_path('txt', 'slope_components.txt');
fid = fopen(comp_file, 'w');
if fid == -1; error('main_s5_slope_summary: cannot write %s', comp_file); end
fprintf(fid, 'Channel slopes at the baseline calibration (main_s5_slope_summary.m, %s)\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, '%-34s %10s %10s %10s %10s\n', 'channel', 'SaM Th_Y', 'SaM Th_u', 'Bench Th_Y', 'Bench Th_u');
for cc = 1:numel(chan_order)
    ch = channels.(chan_order{cc});
    if ch.benchmark
        bY = out_nk0.([ch.prefix '_t']); bU = out_nk0.([ch.prefix '_ue']);
    else
        bY = NaN; bU = NaN;
    end
    fprintf(fid, '%-34s %10.4f %10.4f %10.4f %10.4f\n', ch.label, ...
            out_sam0.([ch.prefix '_t']), out_sam0.([ch.prefix '_ue']), bY, bU);
end
phiC_b  = out_nk0.AD_t;
c_tight = out_sam0.AD_ue / out_sam0.CU_ue;
direct  = out_sam0.AD_t - phiC_b - c_tight * out_sam0.CU_t;
fprintf(fid, '\nProposition 2 (dynamic IS): phi_C = %.4f, direct layer = %.4f, tightness-layer coefficient = %.4f\n', ...
        phiC_b, direct, c_tight);
fprintf(fid, 'beta*_q  = -Theta_Y^q/Theta_u^q            = %.4f\n', -out_sam0.CU_t / out_sam0.CU_ue);
fprintf(fid, 'beta*_Xi = -(Theta_Y^M - phi_C)/Theta_u^M  = %.4f\n', -(out_sam0.AD_t - phiC_b) / out_sam0.AD_ue);
fprintf(fid, 'beta*_Xi = -Theta_Y^Xi/Theta_u^Xi (check)  = %.4f\n', -out_sam0.PE_t / out_sam0.PE_ue);
fclose(fid);
fprintf('Saved %s\n', comp_file);

results_file = nksam_path('mat', 'slope_summary_results.mat');
run_timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS'); %#ok<TNOW1,DATST>
save(results_file, 'beta_shock_weighted', 'agg_slopes_weighted', 'out_sam0', 'out_nk0', 'run_timestamp');
fprintf('\nSaved %s and %s\n', results_file, diary_file);

fprintf('\nDone.\n');

catch ME
    diary off;
    rethrow(ME);
end
diary off;
