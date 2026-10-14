% online_V4_emp_checks.m -- Online Appendix V.4 (sec:emp_checks_add): simulated cyclicality checks
% -------------------------------------------------------------------------
% PRODUCES
%   results/tables/tab_emp_checks.txt       tab:emp_checks (ap_additional_results.tex) in the
%                                           paper's layout (typed into the paper): correlations
%                                           with real GDP of marginal cost, search effort and the
%                                           labor wedge, NK-SaM model, each shock in isolation
%   results/tables/simul_stats_{relstd,corr}_{benchmark,saam}.csv
%                                           relative standard deviations and correlations with
%                                           real GDP, all five shocks, benchmark and NK-SaM
%   results/mat/simul_stats.mat
% Runs lib/default_statistics.m for the benchmark (stat_benchmark = 1) and the
% NK-SaM model (0), home production ON in both. The shock-isolation sweeps are
% cached (cache/shock_sweep_*.mat) and shared with diagnostics/diag_slope_paths.m.
% Simulated data: one-sided HP filter (lambda = 1600), fixed seed (run_all_options.m).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

homeprod = 1;   % home production ON in both models (overrides setup_dynare.m's default 0)

stat_variant_names = ["benchmark", "saam"];   % stat_benchmark = [1, 0]
stat_benchmark_vals = [1, 0];

simul_stats = struct();
for vv = 1:numel(stat_benchmark_vals)
    stat_benchmark = stat_benchmark_vals(vv);   % 0 = NK-SaM model, 1 = benchmark NK
    default_statistics;   % produces relstdtab, corrtab in this workspace

    name = stat_variant_names(vv);
    % 5-shock tables (source of tab:emp_checks)
    simul_stats.(name).relstdtab = relstdtab;
    simul_stats.(name).corrtab   = corrtab;
    simul_stats.(name).relstd_raw = table2array(relstdtab);
    simul_stats.(name).corr_raw   = table2array(corrtab);
    simul_stats.(name).row_names  = relstdtab.Properties.RowNames;
    simul_stats.(name).col_names  = relstdtab.Properties.VariableNames;
end

var_sim_select_saved = dynare_opts.var_sim_select;

save(nksam_path('mat', 'simul_stats.mat'), 'simul_stats', 'var_sim_select_saved');
fprintf('Saved %s (benchmark + NK-SaM relstd/corr tables)\n', nksam_path('mat', 'simul_stats.mat'));

% CSV copies of the moment tables (readable without MATLAB)
for vv = 1:numel(stat_variant_names)
    name = stat_variant_names(vv);
    % 5-shock CSVs (source of tab:emp_checks)
    writetable(simul_stats.(name).relstdtab, ...
        nksam_path('tables', sprintf('simul_stats_relstd_%s.csv', name)), ...
        'WriteRowNames', true);
    writetable(simul_stats.(name).corrtab, ...
        nksam_path('tables', sprintf('simul_stats_corr_%s.csv', name)), ...
        'WriteRowNames', true);
end
fprintf('Saved simul_stats CSVs (benchmark + NK-SaM) to %s\n', nksam_path('tables'));

% -------------------------------------------------------------------------
% TABLE OUTPUT: tab:emp_checks (ap_additional_results.tex, sec:emp_checks_add)
% in the paper's layout -> results/tables/tab_emp_checks.txt.
% NK-SaM model, 5-shock correlations with real GDP; '*' = sign matches the
% empirical cyclicality (Data column), as the check mark in the paper.
% -------------------------------------------------------------------------
ec_rows = {'mc_obs', 'Marginal cost', -1; 'd_obs', 'Search effort', 1; 'lw_obs', 'Labor wedge', -1};
C   = simul_stats.saam.corr_raw;
rn  = cellstr(simul_stats.saam.row_names);
cn  = cellstr(simul_stats.saam.col_names);
ok_count = zeros(1, numel(cn));
EL = {sprintf('tab:emp_checks -- correlations with real GDP, NK-SaM model, each shock in isolation (online_V4_emp_checks.m, %s)', ...
              datestr(now, 'yyyy-mm-dd HH:MM')), ... %#ok<TNOW1,DATST>
      '''*'' = sign matches the data column.', '', ...
      sprintf('%-16s%6s%s', 'Variable', 'Data', sprintf('%15s', cn{:})), repmat('-', 1, 22 + 15 * numel(cn))};
for rr = 1:size(ec_rows, 1)
    ri = find(strcmp(rn, ec_rows{rr, 1}), 1);
    assert(~isempty(ri), 'online_V4_emp_checks: row %s not found', ec_rows{rr, 1});
    sgn = '+'; if ec_rows{rr, 3} < 0; sgn = '-'; end
    ln = sprintf('%-16s%6s', ec_rows{rr, 2}, sgn);
    for cc = 1:numel(cn)
        hit = sign(C(ri, cc)) == ec_rows{rr, 3};
        ok_count(cc) = ok_count(cc) + hit;
        mark = ' '; if hit; mark = '*'; end
        ln = [ln sprintf('%13.2f %s', C(ri, cc), mark)]; %#ok<AGROW>
    end
    EL{end+1} = ln; %#ok<AGROW>
end
EL{end+1} = repmat('-', 1, 22 + 15 * numel(cn));
EL{end+1} = sprintf('%-22s%s', 'Checks matched', sprintf('%15s', ...
    string(arrayfun(@(k) sprintf('%d of %d', k, size(ec_rows, 1)), ok_count, 'UniformOutput', false))));
ec_file = nksam_path('tables', 'tab_emp_checks.txt');
fid = fopen(ec_file, 'w');
if fid == -1; error('online_V4_emp_checks: cannot write %s', ec_file); end
fprintf(fid, '%s\n', EL{:});
fclose(fid);
fprintf('%s\n', EL{:});
fprintf('Saved %s\n', ec_file);
clearvars ec_rows C rn cn ok_count EL ri sgn ln hit mark ec_file fid rr cc;

clearvars stat_variant_names stat_benchmark_vals vv name ...
          var_sim_select_saved stat_benchmark relstdtab corrtab;

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
