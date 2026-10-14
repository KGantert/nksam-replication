% diag_slope_paths.m -- diagnostic (not in the paper): aggregate slopes horizon by horizon
% -------------------------------------------------------------------------
% Complements Table 3 (scripts/main_s5_slope_summary.m) with
%   - the horizon-by-horizon slope theta_Agg(t) = Theta_Y + Theta_u*beta_shock(t),
%     beta_shock(t) = u_t/Y_t, horizons with |Y_t| < 5% of the peak masked
%     -> results/figures/fig_dynamic_slopes_saam.{eps,png}
%   - the horizon-weighted aggregate slopes as bar charts
%     -> results/figures/fig_weighted_slopes_saam.{eps,png}
%   - the moment-based beta = corr(u,Y) x sd(u)/sd(Y) from simulated data
%     (output-gap-relative) -> results/tables/gap_moments_*.csv
%   log: results/txt/diag_slope_paths_log.txt; results/mat/diag_slope_paths.mat
% The matching-efficiency shock is computed but not plotted (its slopes
% equal those of the search-effort shock).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% =========================================================================
% PART 1 (Dynare): gap IRFs and simulated gap moments
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

% Shock-isolation sweep: lib/run_shock_isolation_sweep.m, cached per variant in
% cache/shock_sweep_<benchmark|saam>.mat and shared with scripts/online_V4_emp_checks.m
% (lib/default_statistics.m), whose configurations are identical.
gap_idx_g = find(strcmp(dynare_opts.var_sim_select, "gdp_gap"), 1);
assert(~isempty(gap_idx_g), 'diag_slope_paths: "gdp_gap" not found in var_sim_select.');

gap_variant_names = ["benchmark", "saam"];
gap_variant_cfgs  = {cfg_bench_g, cfg_saam_g};
gap_moments = struct();

for vv = 1:numel(gap_variant_cfgs)
    cfg_g = gap_variant_cfgs{vv};
    [relstd_TIME_g, corr_TIME_g] = run_shock_isolation_sweep( ...
        cfg_g, dynare_opts, char(gap_variant_names(vv)));

    relstd_TAB_g = squeeze(relstd_TIME_g(:, gap_idx_g, :));
    corr_TAB_g   = squeeze(corr_TIME_g(:, gap_idx_g, :));

    name = gap_variant_names(vv);
    gap_moments.(name).relstdtab_gap = array2table(round(relstd_TAB_g(:,[1,3,4,6,5]),2), ...
        'VariableNames', ["TFP", "Policy", "Cost-Push", "Search", "Matching Eff."], ...
        'RowNames', dynare_opts.var_sim_select);
    gap_moments.(name).corrtab_gap = array2table(round(corr_TAB_g(:,[1,3,4,6,5]),2), ...
        'VariableNames', ["TFP", "Policy", "Cost-Push", "Search", "Matching Eff."], ...
        'RowNames', dynare_opts.var_sim_select);

    % Plain-numeric mirrors (same pattern as online_V4_emp_checks.m's simul_stats)
    gap_moments.(name).relstd_raw = table2array(gap_moments.(name).relstdtab_gap);
    gap_moments.(name).corr_raw   = table2array(gap_moments.(name).corrtab_gap);
    gap_moments.(name).row_names  = gap_moments.(name).relstdtab_gap.Properties.RowNames;
    gap_moments.(name).col_names  = gap_moments.(name).relstdtab_gap.Properties.VariableNames;
end

% CSV copies of the gap moments (readable without MATLAB)
for vv = 1:numel(gap_variant_names)
    name = gap_variant_names(vv);
    writetable(gap_moments.(name).relstdtab_gap, ...
        nksam_path('tables', sprintf('gap_moments_relstd_%s.csv', name)), 'WriteRowNames', true);
    writetable(gap_moments.(name).corrtab_gap, ...
        nksam_path('tables', sprintf('gap_moments_corr_%s.csv', name)), 'WriteRowNames', true);
end

% Dynare work done: delete its regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();

% =========================================================================
% PART 2 (reduced form): slope paths
% =========================================================================
diary_file = nksam_path('txt', 'diag_slope_paths_log.txt');
if exist(diary_file, 'file'); delete(diary_file); end
diary(diary_file);
diary on;

try

%% -------------------------------------------------------------------
% 1-2. ANALYTICAL SLOPES (Theta_Y, Theta_u), home production ON
% -------------------------------------------------------------------
fprintf('[2/7] Computing analytical slopes (hw_select=1)...\n');
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

%% -------------------------------------------------------------------
% 3. DYNAMIC MEASURE: theta_Agg(t) per channel/shock
% -------------------------------------------------------------------
fprintf('[3/7] Building dynamic aggregate-slope paths...\n');

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

% Matching efficiency (eT) is computed and saved throughout this script
% exactly like every other shock -- masking, dynamic path,
% horizon-weighted beta, corrected static beta, all of it -- but is
% excluded from BOTH figures (step 5 and step 6) because its slopes
% turned out numerically identical to Search effort (eD)'s: plotting
% both would just draw one line/bar twice. If that identity ever
% breaks (e.g. after a calibration change), removing eT from
% plot_idx_saam below is the only change needed to show it again.
plot_idx_saam = find(shock_names_saam ~= "eT");

% --- Near-zero-denominator safeguard --------------------------------
% A horizon t is masked (beta_shock(t) -> NaN) whenever
%   |gdp_gap_IRF(t)| < MASK_THRESHOLD_FRAC * max_t |gdp_gap_IRF(t)|
% for that shock's own IRF. Relative to the shock's own peak response,
% not an absolute level, so shocks of different overall size are
% treated consistently. 5% is a judgment call, not a derived number --
% change MASK_THRESHOLD_FRAC below and re-run to see the sensitivity.
MASK_THRESHOLD_FRAC = 0.05;

% beta_shock(t) and its mask depend only on the shock (not the
% channel), so compute each shock's path once here and reuse it across
% all five channel panels below -- avoids redundant work and redundant
% masking log messages.
beta_saam  = struct();
mask_saam  = struct();
beta_bench = struct();
mask_bench = struct();

fprintf('  Masking near-zero-denominator horizons (|gdp_gap_IRF| < %.0f%% of peak):\n', ...
    100 * MASK_THRESHOLD_FRAC);
for ss = 1:numel(shock_names_saam)
    s = shock_names_saam(ss);
    Y_irf = gap_irfs.saam.(s).gdp_gap;
    u_irf = gap_irfs.saam.(s).ue_gap;
    thresh = MASK_THRESHOLD_FRAC * max(abs(Y_irf));
    mask = abs(Y_irf) < thresh;
    beta_t = u_irf ./ Y_irf;
    beta_t(mask) = NaN;
    beta_saam.(s) = beta_t;
    mask_saam.(s) = mask;
    if any(mask)
        fprintf('    NK-SaM,  %-10s: masked horizons %s (of %d)\n', ...
            shock_labels_saam(ss), mat2str(find(mask)'), numel(Y_irf));
    else
        fprintf('    NK-SaM,  %-10s: no masking needed\n', shock_labels_saam(ss));
    end
end
for ss = 1:numel(shock_names_bench)
    s = shock_names_bench(ss);
    Y_irf = gap_irfs.benchmark.(s).gdp_gap;
    u_irf = gap_irfs.benchmark.(s).ue_gap;
    thresh = MASK_THRESHOLD_FRAC * max(abs(Y_irf));
    mask = abs(Y_irf) < thresh;
    beta_t = u_irf ./ Y_irf;
    beta_t(mask) = NaN;
    beta_bench.(s) = beta_t;
    mask_bench.(s) = mask;
    if any(mask)
        fprintf('    Bench,   %-10s: masked horizons %s (of %d)\n', ...
            shock_labels_bench(ss), mat2str(find(mask)'), numel(Y_irf));
    else
        fprintf('    Bench,   %-10s: no masking needed\n', shock_labels_bench(ss));
    end
end

dynamic_slopes = struct('saam', struct(), 'benchmark', struct());

for cc = 1:numel(chan_order)
    key = chan_order{cc};
    ch  = channels.(key);

    % NK-SaM
    Theta_Y = out_sam0.([ch.prefix '_t']);
    Theta_u = out_sam0.([ch.prefix '_ue']);
    for ss = 1:numel(shock_names_saam)
        s = shock_names_saam(ss);
        dynamic_slopes.saam.(key).(s) = Theta_Y + Theta_u .* beta_saam.(s);
    end

    % Benchmark (only for channels that exist there)
    if ch.benchmark
        Theta_Y = out_nk0.([ch.prefix '_t']);
        Theta_u = out_nk0.([ch.prefix '_ue']);
        for ss = 1:numel(shock_names_bench)
            s = shock_names_bench(ss);
            dynamic_slopes.benchmark.(key).(s) = Theta_Y + Theta_u .* beta_bench.(s);
        end
    end
end

%% -------------------------------------------------------------------
% 4. HORIZON-WEIGHTED BETA_SHOCK: a single number per shock, derived
%    directly from the IRFs, that sidesteps the division problem in
%    step 3 by construction rather than patching around it. Computed
%    here (before the figure) so the resulting agg_slopes_weighted can
%    be drawn onto the same panels as the dynamic path in step 5.
% -------------------------------------------------------------------
fprintf('[4/7] Horizon-weighted beta_shock (regression-through-origin)...\n');

% beta_shock = sum_t[ ue_gap_IRF(t) * gdp_gap_IRF(t) ] / sum_t[ gdp_gap_IRF(t)^2 ]
% -- the OLS slope of ue_gap_IRF on gdp_gap_IRF across the whole
% horizon, forced through the origin (no intercept: at t=0 both gaps
% are zero by construction, so a slope-through-origin is the natural
% fit here, not an arbitrary restriction).
%
% Never divides pointwise, so no threshold or mask is needed: a horizon
% where gdp_gap_IRF(t) is near zero contributes almost nothing to
% either the numerator or the denominator, and is therefore
% automatically down-weighted rather than excluded outright. Uses the
% FULL, unmasked IRFs (mask_saam/mask_bench from step 3 are irrelevant
% here).
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

% Implied single aggregate slope per channel/shock -- a scalar analog
% of the dynamic_slopes(t) paths from step 3, using the horizon-
% weighted beta in place of beta_shock(t). Plotted as a horizontal
% reference line per shock in step 5. A useful cross-check: this
% number should sit somewhere inside the range spanned by that shock's
% unmasked dynamic_slopes(t) values, since it's a weighted average of
% essentially the same underlying ratio.
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

%% -------------------------------------------------------------------
% 5. FIGURE 1: one panel per NK-SaM channel, one line per shock -- the
%    dynamic (horizon-by-horizon) aggregate slope path from step 3.
% -------------------------------------------------------------------
fprintf('[5/7] Plotting dynamic aggregate slopes (figure 1)...\n');

T = numel(gap_irfs.saam.eA.gdp_gap);
quarters = (1:T)';
assert(numel(gap_irfs.benchmark.eA.gdp_gap) == T, ...
    'Benchmark and NK-SaM IRF horizons differ in length (%d vs %d) -- both come from dynare_scenario with the same dynare_opts, so this should not happen; check the irf-horizon setting.', ...
    numel(gap_irfs.benchmark.eA.gdp_gap), T);

fig1 = figure('Name', 'Dynamic Aggregate Slopes', 'Position', [100 100 1100 650]);
% Fifth row (green) added for the matching-efficiency shock (eT) --
% continues MATLAB's own default color order (rows 1-4 here already
% matched it) rather than picking an arbitrary new color.
colors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.47 0.67 0.19];

% Benchmark shocks (eA, eM, eP) share their color with the matching
% NK-SaM shock -- shock_names_saam's first three entries are the same
% eA/eM/eP in the same order, so colors(1:3,:) line up directly.
% Benchmark lines are dashed and excluded from the legend
% (HandleVisibility off) to avoid duplicate entries; the color already
% ties each dashed line to its solid counterpart, and the annotation
% below states the solid/dashed convention once for the whole figure.
%
% The horizon-weighted (single-number) measure from step 4 is NOT
% overlaid here -- it gets its own figure (step 6) instead, so this
% figure stays exclusively about how the slope moves over time.
for cc = 1:numel(chan_order)
    key = chan_order{cc};
    ch  = channels.(key);
    subplot(2, 3, cc); hold on;
    for ss = plot_idx_saam   % excludes eT -- see note at plot_idx_saam's definition (step 3)
        s = shock_names_saam(ss);
        plot(quarters, dynamic_slopes.saam.(key).(s), '-o', ...
            'Color', colors(ss, :), 'LineWidth', 1.2, 'MarkerSize', 3, ...
            'DisplayName', shock_labels_saam(ss));
    end
    if ch.benchmark
        for ss = 1:numel(shock_names_bench)
            s = shock_names_bench(ss);
            plot(quarters, dynamic_slopes.benchmark.(key).(s), '--s', ...
                'Color', colors(ss, :), 'LineWidth', 1.2, 'MarkerSize', 3, ...
                'HandleVisibility', 'off');
        end
    end
    yline(0, 'k:', 'HandleVisibility', 'off');
    title(ch.label, 'Interpreter', 'none');
    xlabel('Quarter'); ylabel('\Theta_Y^{Agg}(t)');
    if cc == 1; legend('Location', 'best'); end
    hold off;
end
sgtitle('NK-SaM: Dynamic Aggregate Slopes,  \Theta_Y + \Theta_u \cdot [ue_{gap}(t) / gdp_{gap}(t)]');
annotation(fig1, 'textbox', [0 0 1 0.06], 'String', ...
    sprintf(['Solid = NK-SaM, dashed = Benchmark (same color = same shock; Benchmark has no Search shock, no CU/PE channels). ' ...
    'Gaps in lines: horizons masked where |gdp gap IRF| < %.0f%% of that shock''s peak response (near-zero-denominator).'], ...
    100 * MASK_THRESHOLD_FRAC), ...
    'Interpreter', 'none', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontSize', 8, 'FontAngle', 'italic');

saveas(fig1, nksam_path('figures', 'fig_dynamic_slopes_saam.png'));
saveas(fig1, nksam_path('figures', 'fig_dynamic_slopes_saam.eps'), 'epsc');
fprintf('Saved fig_dynamic_slopes_saam.png / .eps\n');

%% -------------------------------------------------------------------
% 6. FIGURE 2: one panel per NK-SaM channel, grouped bar chart of the
%    horizon-weighted (single-number) aggregate slope per shock, from
%    step 4. A separate figure rather than an overlay on figure 1,
%    since it's a genuinely different kind of object (one number per
%    shock, not a horizon path) and reads better as bars than as lines
%    with no x-axis meaning of their own.
% -------------------------------------------------------------------
fprintf('[6/7] Plotting horizon-weighted aggregate slopes (figure 2)...\n');

% One grouped-bar group per shock (TFP, Policy, Cost-Push, Search),
% two bars per group (NK-SaM, Benchmark) where Benchmark exists.
% Benchmark has no Search shock, so its bar there is left as NaN --
% MATLAB's bar() simply omits a NaN bar rather than erroring or
% plotting a zero, which is the correct reading ("not defined"), not
% "estimated at zero".
fig2 = figure('Name', 'Horizon-Weighted Aggregate Slopes', 'Position', [100 100 1100 650]);
for cc = 1:numel(chan_order)
    key = chan_order{cc};
    ch  = channels.(key);
    subplot(2, 3, cc);

    % plot_idx_saam excludes eT (matching efficiency) -- its slopes are
    % numerically identical to Search (eD)'s, so it's computed and
    % saved (agg_slopes_weighted.saam.(key).eT still exists) but not
    % drawn a second time here. See plot_idx_saam's definition (step 3).
    shock_names_plot  = shock_names_saam(plot_idx_saam);
    shock_labels_plot = shock_labels_saam(plot_idx_saam);

    vals_saam = nan(numel(shock_names_plot), 1);
    for ss = 1:numel(shock_names_plot)
        vals_saam(ss) = agg_slopes_weighted.saam.(key).(shock_names_plot(ss));
    end

    % categorical() with an explicit ValueSet (the same list twice)
    % keeps the TFP/Policy/Cost-Push/Search order on the x-axis --
    % without it, categorical() sorts categories alphabetically, which
    % would silently scramble the bar order (Cost-Push, Policy,
    % Search, TFP).
    shock_cats = categorical(cellstr(shock_labels_plot), cellstr(shock_labels_plot));

    if ch.benchmark
        vals_bench = nan(numel(shock_names_plot), 1);
        for ss = 1:numel(shock_names_bench)
            bench_idx = find(shock_names_plot == shock_names_bench(ss), 1);
            vals_bench(bench_idx) = agg_slopes_weighted.benchmark.(key).(shock_names_bench(ss));
        end
        b = bar(shock_cats, [vals_saam, vals_bench]);
        b(1).FaceColor = [0.00 0.45 0.74]; b(1).DisplayName = 'NK-SaM';
        b(2).FaceColor = [0.60 0.60 0.60]; b(2).DisplayName = 'Benchmark';
        if cc == 1; legend('Location', 'best'); end
    else
        b = bar(shock_cats, vals_saam);
        b.FaceColor = [0.00 0.45 0.74];
    end
    yline(0, 'k:', 'HandleVisibility', 'off');
    title(ch.label, 'Interpreter', 'none');
    ylabel('\Theta_Y^{Agg} (horizon-weighted)');
end
sgtitle('NK-SaM: Horizon-Weighted Aggregate Slopes,  \Theta_Y + \Theta_u \cdot \beta_{shock}^{weighted}');
annotation(fig2, 'textbox', [0 0 1 0.05], 'String', ...
    'beta_{shock}^{weighted} = \Sigma_t[ue\_gap\_IRF(t)*gdp\_gap\_IRF(t)] / \Sigma_t[gdp\_gap\_IRF(t)^2] -- one number per shock, no masking needed (see step 4).', ...
    'Interpreter', 'tex', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontSize', 8, 'FontAngle', 'italic');

saveas(fig2, nksam_path('figures', 'fig_weighted_slopes_saam.png'));
saveas(fig2, nksam_path('figures', 'fig_weighted_slopes_saam.eps'), 'epsc');
fprintf('Saved fig_weighted_slopes_saam.png / .eps\n');

%% -------------------------------------------------------------------
% 7. CORRECTED STATIC MEASURE (secondary): Corr x RelStd of ue_gap
%    relative to gdp_gap (not real GDP), home production ON.
% -------------------------------------------------------------------
fprintf('[7/7] Corrected static beta_shock (output-gap-relative)...\n');

beta_shock_corrected = struct();
variant_names = ["benchmark", "saam"];
for vv = 1:numel(variant_names)
    mm = variant_names(vv);
    relstd_g = gap_moments.(mm).relstdtab_gap;
    corr_g   = gap_moments.(mm).corrtab_gap;
    row_idx  = find(strcmp(string(relstd_g.Properties.RowNames), "ue_gap"), 1);
    assert(~isempty(row_idx), 'ue_gap row not found in relstdtab_gap.');
    beta_shock_corrected.(mm) = corr_g{row_idx, :} .* relstd_g{row_idx, :};
end

fprintf('\nCorrected beta_shock (NK-SaM, output-gap-relative):       ');
fprintf('%.3f ', beta_shock_corrected.saam); fprintf('\n');
fprintf('Corrected beta_shock (Benchmark, output-gap-relative):    ');
fprintf('%.3f ', beta_shock_corrected.benchmark); fprintf('\n');
fprintf('(Columns: TFP, Policy, Cost-Push, Search, Matching Eff.)\n');


results_file = nksam_path('mat', 'diag_slope_paths.mat');
save(results_file, 'dynamic_slopes', 'beta_shock_corrected', 'beta_shock_weighted', ...
    'agg_slopes_weighted', 'gap_moments', 'out_sam0', 'out_nk0', ...
    'mask_saam', 'mask_bench', 'MASK_THRESHOLD_FRAC');
fprintf('\nSaved %s and %s\n', results_file, diary_file);

fprintf('\nDone.\n');

catch ME
    diary off;
    rethrow(ME);
end
diary off;
