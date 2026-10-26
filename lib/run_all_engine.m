function summary = run_all_engine(varargin)
% RUN_ALL_ENGINE  Code of the master script. Call it through run_all (see
%   `help run_all`); options are in run_all_options.m. run_all re-reads this
%   file and every other .m file before each call. Not part of the cache
%   signature (lib/check_cache_signature.m), so editing it keeps the caches.

[RUN, OPT] = run_all_options();   % USER OPTIONS: run_all_options.m

ip = inputParser;
addParameter(ip, 'scripts', {});
addParameter(ip, 'groups', {});
addParameter(ip, 'cache', OPT.cache);
addParameter(ip, 'seed', OPT.seed);
addParameter(ip, 'copy_to_paper', OPT.copy_to_paper);
addParameter(ip, 'cleanup_dynare', OPT.cleanup_dynare);
addParameter(ip, 'stop_on_error', OPT.stop_on_error);
addParameter(ip, 'close_figures', OPT.close_figures);
addParameter(ip, 'list', false);
addParameter(ip, 'compare_only', false);
parse(ip, varargin{:});
opt = ip.Results;
opt.cache = lower(char(opt.cache));
if ~ismember(opt.cache, {'auto', 'fresh', 'reuse'})
    error('run_all:cache', 'cache must be ''auto'', ''fresh'' or ''reuse''.');
end

repo_root = fileparts(fileparts(mfilename('fullpath')));   % this file is in lib/
paper_dir = fullfile(fileparts(repo_root), '1_nksam_paper');
steps     = define_steps();
names     = {steps.name};

if opt.list
    fprintf('%-26s %-5s %-12s %-6s %s\n', 'script', 'RUN', 'group', 'dynare', 'paper output');
    for s = steps
        fprintf('%-26s %-5d %-12s %-6d %s\n', s.name, isfield(RUN, s.name) && RUN.(s.name), ...
                s.group, s.dynare, s.desc);
    end
    summary = steps;
    return;
end

% ---- Selection ---------------------------------------------------------------
if ~isempty(opt.scripts)
    req = cellstr(opt.scripts);
    bad = setdiff(req, names);
    if ~isempty(bad)
        error('run_all:scripts', 'Unknown script(s): %s', strjoin(bad, ', '));
    end
    sel = ismember(names, req);
elseif ~isempty(opt.groups)
    groups = cellstr(opt.groups);
    if any(strcmpi(groups, 'all'))
        sel = true(1, numel(steps));
    else
        sel = ismember({steps.group}, groups);
    end
else
    missing = setdiff(names, fieldnames(RUN));
    if ~isempty(missing)
        error('run_all:RUN', 'No RUN switch for: %s', strjoin(missing, ', '));
    end
    sel = cellfun(@(n) logical(RUN.(n)), names);
end
if ~any(sel)
    error('run_all:nothing', 'No scripts selected. Use run_all(''list'', true).');
end

% ---- Compare only: no script is run ----------------------------------------------
if opt.compare_only
    if ~isfolder(paper_dir)
        error('run_all:paper', 'Paper folder not found: %s', paper_dir);
    end
    summary = struct('name', {}, 'status', {}, 'minutes', {}, 'note', {});
    all_diff = {};
    for s = steps(sel)
        missing = s.outputs(~cellfun(@(o) isfile(fullfile(repo_root, o)), s.outputs));
        if ~isempty(missing)
            note = sprintf('output missing: %s', strjoin(missing, ', '));
            status = 'OUTPUT MISSING';
        else
            pdiff = compare_with_paper(repo_root, paper_dir, s.outputs, opt.copy_to_paper);
            all_diff = [all_diff, pdiff]; %#ok<AGROW>
            status = 'COMPARED';
            if isempty(pdiff)
                note = 'identical to paper';
            elseif opt.copy_to_paper
                note = ['copied to paper: ' strjoin(pdiff, ', ')];
            else
                note = ['differs from paper: ' strjoin(pdiff, ', ')];
            end
        end
        fprintf('[run_all] %-26s %-15s %s\n', s.name, status, note);
        summary(end+1) = struct('name', s.name, 'status', status, 'minutes', 0, 'note', note); %#ok<AGROW>
    end
    fprintf('[run_all] compare_only: %d file(s) %s.\n', numel(all_diff), ...
            ternary(opt.copy_to_paper, 'copied to the paper', 'differ from the paper'));
    return;
end

% ---- Preflight ------------------------------------------------------------------
for s = steps(sel)
    if ~isfile(fullfile(repo_root, s.file))
        error('run_all:missing', 'Script not found: %s', s.file);
    end
end
if isempty(which('dynare'))
    error('run_all:dynare', ['Dynare is not on the MATLAB path. Add Dynare''s ' ...
        'matlab/ folder (e.g. addpath(''/Applications/Dynare/7.2/matlab'')) and retry.']);
end
compare_paper = isfolder(paper_dir);
if opt.copy_to_paper && ~compare_paper
    error('run_all:paper', 'Paper folder not found: %s', paper_dir);
end

% ---- State to restore on exit -----------------------------------------------------
start_path = path;
start_dir  = pwd;
env_names  = {'NKSAM_CLEANUP_DYNARE', 'NKSAM_CACHE_POLICY', 'NKSAM_SEED'};
old_env    = cellfun(@getenv, env_names, 'UniformOutput', false);
restore    = onCleanup(@() restore_state(start_path, start_dir, env_names, old_env)); %#ok<NASGU>
setenv('NKSAM_CLEANUP_DYNARE', num2str(double(logical(opt.cleanup_dynare))));
setenv('NKSAM_CACHE_POLICY', strrep(opt.cache, 'fresh', 'auto'));
setenv('NKSAM_SEED', num2str(opt.seed));

% ---- Logs and caches -------------------------------------------------------------
addpath(genpath(repo_root));
stamp   = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>
log_dir = nksam_path('logs', stamp);
if ~isfolder(log_dir); mkdir(log_dir); end
if strcmp(opt.cache, 'fresh')
    f = dir(fullfile(nksam_path('cache'), '*.mat'));
    for k = 1:numel(f); delete(fullfile(f(k).folder, f(k).name)); end
    fprintf('run_all: deleted %d cache file(s)\n', numel(f));
end
check_cache_signature(repo_root);
path(start_path);

% ---- Run ----------------------------------------------------------------------------
summary = struct('name', {}, 'status', {}, 'minutes', {}, 'note', {});
paper_changes = {};
t_all = tic;

for s = steps(sel)
    note = '';
    path(start_path);
    addpath(genpath(repo_root));
    cd(repo_root);
    clear functions; rehash;   % externally edited files (sync, scripts) are re-read before every script
    if opt.close_figures, close all force; end

    log_file = fullfile(log_dir, sprintf('%s.txt', s.name));
    diary(log_file); diary on;
    fprintf('\n[run_all] ===== %s =====\n[run_all] %s\n', s.file, s.desc);

    t_step  = tic;
    t_start = now; %#ok<TNOW1>
    try
        evalin('base', sprintf('run(''%s'');', ...
            strrep(fullfile(repo_root, s.file), '''', '''''')));
        status = 'OK';
    catch ME
        status = 'ERROR';
        note   = ME.message;
        fprintf(2, '[run_all] %s FAILED:\n%s\n', s.name, getReport(ME, 'extended'));
        if s.dynare
            try cleanup_dynare_output(); catch; end   % leftovers of the failed run
        end
    end
    diary(log_file); diary off;   % scripts may have redirected the diary
    minutes = toc(t_step) / 60;

    % output check (1 s tolerance for file-system timestamps)
    if strcmp(status, 'OK')
        for o = s.outputs
            f = dir(fullfile(repo_root, o{1}));
            if isempty(f)
                status = 'OUTPUT MISSING'; note = o{1}; break;
            elseif f(1).datenum < t_start - 1/86400
                status = 'OUTPUT NOT UPDATED'; note = o{1}; break;
            end
        end
    end

    % paper comparison (figures and .tex tables)
    if strcmp(status, 'OK')
        note = sprintf('%d output(s) checked', numel(s.outputs));
        if compare_paper
            pdiff = compare_with_paper(repo_root, paper_dir, s.outputs, opt.copy_to_paper);
            if ~isempty(pdiff)
                if opt.copy_to_paper; verb = 'updated in paper'; else; verb = 'DIFFERS from paper'; end
                note = sprintf('%s; %s: %s', note, verb, strjoin(pdiff, ', '));
                paper_changes = [paper_changes, pdiff]; %#ok<AGROW>
            end
        end
    end

    fprintf('[run_all] %-26s %s (%.1f min)\n', s.name, status, minutes);
    summary(end+1) = struct('name', s.name, 'status', status, ...
                            'minutes', minutes, 'note', note); %#ok<AGROW>
    cd(repo_root);

    if opt.stop_on_error && ~strcmp(status, 'OK')
        fprintf(2, '[run_all] stop_on_error: stopping after %s.\n', s.name);
        break;
    end
end
if opt.close_figures, close all force; end

% ---- Summary --------------------------------------------------------------------------
lines = {sprintf('run_all %s  (cache=%s, seed=%g, copy_to_paper=%d, cleanup_dynare=%d)  total %.1f min', ...
                 stamp, opt.cache, opt.seed, opt.copy_to_paper, opt.cleanup_dynare, toc(t_all) / 60), ...
         sprintf('%-26s %-19s %7s  %s', 'script', 'status', 'min', 'note')};
for r = summary
    lines{end+1} = sprintf('%-26s %-19s %7.1f  %s', r.name, r.status, r.minutes, r.note); %#ok<AGROW>
end
if ~compare_paper
    lines{end+1} = 'paper: folder ../1_nksam_paper not found, comparison skipped';
elseif isempty(paper_changes)
    lines{end+1} = 'paper: all figures/tables identical in content to ../1_nksam_paper';
elseif opt.copy_to_paper
    lines{end+1} = sprintf('paper: %d file(s) updated in ../1_nksam_paper: %s', numel(paper_changes), strjoin(paper_changes, ', '));
else
    lines{end+1} = sprintf('paper: %d file(s) differ from ../1_nksam_paper (copy_to_paper = true updates them): %s', ...
                           numel(paper_changes), strjoin(paper_changes, ', '));
end
fprintf('\n%s\n', strjoin(lines, newline));
fid = fopen(fullfile(log_dir, 'summary.txt'), 'w');
if fid ~= -1
    fprintf(fid, '%s\n', lines{:});
    fclose(fid);
end
fprintf('\n[run_all] results: %s\n[run_all] log:     %s\n', fullfile(repo_root, 'results'), log_dir);
end

% =================================================================================
function steps = define_steps()
% name, group, file, Dynare?, expected outputs (relative to the codebase), description
F = 'results/figures/'; T = 'results/tables/'; X = 'results/txt/'; M = 'results/mat/';
S = {
 'app_A_build_data', 'appendix', false, ...
   {'data/data.mat'}, ...
   'App. A data: data/data.mat from data/raw/ (FRED, Karabarbounis 2014, cu_obs)';
 'main_s3_s4_slopes', 'main', false, ...
   [strcat(F, {'fig_slopes_5eq_cu_pe.eps', 'fig_slopes_5eq_ee_pc_rw.eps', 'fig_slopes_5eq_lw_se_mc.eps', 'fig_stst_gamES_cutoff.eps'}), ...
    strcat(X, {'fig_slopes_5eq_cu_pe.txt', 'fig_slopes_5eq_ee_pc_rw.txt', 'fig_slopes_5eq_lw_se_mc.txt', 'calibration_summary.txt', 'nuD_cutoffs.txt'})], ...
   'Sec. 3 fig:slopes_5eq_util, Sec. 4 fig:slopes_5eq, OA V.2 fig:app_slopes_tot_wedge, App. C fig:cutoff_gammaQ; calibration and nu_D cutoff numbers';
 'main_s5_irfs', 'main', true, ...
   [strcat(F, {'fig_phase_diagram.eps', 'fig_irf_default_tfp.eps', 'fig_irf_default_policy.eps', 'fig_irf_default_search.eps', 'fig_irf_default_eis.eps'}), {[X 'phase_diagram.txt'], [X 'irf_impact.txt']}], ...
   'Sec. 5 fig:phase_diagram, fig:irf_default_{tfp,policy,search_effort,eis}';
 'main_s5_slope_summary', 'main', true, ...
   {[T 'tab_slope_summary.txt'], [X 'beta_alternatives.txt'], [X 'slope_components.txt'], [X 'slope_summary_log.txt'], [M 'gap_irfs.mat'], [M 'slope_summary_results.mat']}, ...
   'Sec. 5 tab:slope_summary';
 'app_A_calibration', 'appendix', true, ...
   {[X 'calibration_dynare.txt']}, ...
   'App. A Table A.1: full-model parameters implied by the targets';
 'app_A_data_moments', 'appendix', false, ...
   {[X 'data_moments.txt']}, ...
   'App. A (also Intro, OA V.4, OA VI): corr(cu,Y), sd(cu)/sd(Y) in the data';
 'online_IV_equivalence', 'online', false, ...
   {[T 'tab_param_equiv.tex'], [X 'param_equivalence.txt'], [X 'param_jacobian.txt']}, ...
   'OA IV tab:param_equiv';
 'online_V1_steady_states', 'online', false, ...
   {[F 'fig_stst_fixed.eps'], [F 'fig_stst_targeted.eps'], [X 'fig_stst_endpoints.txt']}, ...
   'OA V.1 fig:stst_fixed, fig:stst_targeted';
 'online_V3_efficiency_irfs', 'online', true, ...
   {[F 'fig_irf_default_efficiency.eps']}, ...
   'OA V.3 fig:irf_add_matching';
 'online_V4_emp_checks', 'online', true, ...
   {[T 'tab_emp_checks.txt'], [T 'simul_stats_corr_saam.csv'], [M 'simul_stats.mat']}, ...
   'OA V.4 tab:emp_checks';
 'online_VI_robustness', 'online', true, ...
   [strcat(F, 'fig_robust_', {'calib', 'kapPci', 'kapP', 'kapW', 'hours', 'nohp', 'ghh', 'qs', 'longterm', 'capital', 'iq'}, '.eps'), ...
    {[T 'tab_robust_regimes.tex'], [T 'tab_robust_magnitudes.tex'], [X 'robustness_summary.txt']}], ...
   'OA VI (and Sec. 6) fig:robust_<check>, tab:robust_regimes, tab:robust_magnitudes';
 'online_VI_fixed_kapP', 'online', false, ...
   {[X 'fixed_kapP_summary.txt'], [M 'fixed_kapP_results.mat']}, ...
   'OA VI check 5 (sec:robust_kapP): kappa_P, implied labor-share and price Phillips-curve slopes';
 'online_VI_rigidity_grid', 'online', true, ...
   {[F 'fig_robust_rigidity.eps'], [X 'rigidity_grid_summary.txt'], [M 'rigidity_grid.mat']}, ...
   'OA VI price vs wage rigidity grid (95% CIs and literature estimates): omega_shock and NK-SaM/benchmark ratios';
 'diag_kapP_switch', 'diagnostics', false, {}, ...
   'diagnostic: kappa_P calibration modes are exact inverses';
 'diag_quality_search', 'diagnostics', true, {[X 'diag_quality_search.txt']}, ...
   'diagnostic: largest gamma_P with a steady state (check 2)';
 'diag_data_gaps', 'diagnostics', false, {[F 'gap_decomp_data.eps'], [F 'cu_pe_lw_se_gap_data.eps']}, ...
   'diagnostic: model-implied gaps vs. US data';
 'diag_slope_paths', 'diagnostics', true, ...
   {[F 'fig_dynamic_slopes_saam.eps'], [F 'fig_weighted_slopes_saam.eps'], [T 'gap_moments_corr_saam.csv']}, ...
   'diagnostic: aggregate slopes horizon by horizon, moment-based beta';
 'diag_shock_persistence', 'diagnostics', true, ...
   {[F 'fig_robust_persistence.eps'], [X 'diag_shock_persistence.txt']}, ...
   'diagnostic: robustness to the persistence of the shocks (rho_A = 0.95, rho_Z = 0.9, all other rho = 0.8)';
 'diag_phase_diagram_capital', 'diagnostics', true, ...
   {[F 'fig_phase_diagram_capital_nocap.eps'], [F 'fig_phase_diagram_capital_fixed.eps'], [F 'fig_phase_diagram_capital_variable.eps'], [X 'diag_phase_diagram_capital.txt']}, ...
   'diagnostic: Barro-Grossman phase diagram with capital (fixed / variable utilization), no analytical thresholds'};
steps = struct('name', S(:,1)', 'group', S(:,2)', 'dynare', S(:,3)', ...
               'outputs', S(:,4)', 'desc', S(:,5)', 'file', '');
for k = 1:numel(steps)
    if strcmp(steps(k).group, 'diagnostics')
        steps(k).file = ['diagnostics/' steps(k).name '.m'];
    else
        steps(k).file = ['scripts/' steps(k).name '.m'];
    end
end
end

function pdiff = compare_with_paper(repo_root, paper_dir, outputs, to_paper)
% Content comparison of the .eps/.tex outputs with the paper's copies;
% with to_paper, copies the differing ones (unchanged files keep their dates).
pdiff = {};
for o = outputs
    [~, nm, ext] = fileparts(o{1});
    switch lower(ext)
        case '.eps'; sub = 'eps_figures';
        case '.tex'; sub = 'tables';
        otherwise;   continue;
    end
    src = fullfile(repo_root, o{1});
    dst = fullfile(paper_dir, sub, [nm ext]);
    if ~same_content(src, dst)
        pdiff{end+1} = [nm ext]; %#ok<AGROW>
        if to_paper
            [ok, msg] = copyfile(src, dst, 'f');
            if ~ok; warning('run_all:copy', 'could not copy %s: %s', src, msg); end
        end
    end
end
end

function tf = same_content(a, b)
% True if files a and b are identical after dropping metadata lines that
% change on every export: EPS %%CreationDate/%%Title/%%Creator/%%For, and
% the '% generated by ... (timestamp)' first line of .tex tables.
tf = false;
if ~isfile(a) || ~isfile(b); return; end
tf = isequal(strip_meta(fileread(a)), strip_meta(fileread(b)));
end

function L = strip_meta(txt)
L = regexp(txt, '\r?\n', 'split');
L = L(~startsWith(L, {'%%CreationDate', '%%Title', '%%Creator', '%%For', '% generated by'}));
end

function out = ternary(cond, a, b)
if cond; out = a; else; out = b; end
end

function restore_state(start_path, start_dir, env_names, old_env)
diary off;
path(start_path);
if isfolder(start_dir); cd(start_dir); end
for k = 1:numel(env_names)
    setenv(env_names{k}, old_env{k});
end
end
