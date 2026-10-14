function res = dynare_scenario(cfg, dynare_opts)
% dynare_scenario  Run one Dynare scenario and return IRFs and moments.
%
%   Requires the one-time preprocessing call to dynare (lib/setup_dynare.m) that
%   populates the global M_, options_, oo_.  Each call to this function then
%   injects new parameter values directly into M_.params via set_M_params and
%   re-solves using stoch_simul — skipping the expensive preprocessing step.
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%   cfg         Struct with optional override fields:
%     .par        Standard model parameters
%     .parHW      Home production parameters
%     .parSAM     Search-and-matching parameters
%     .shock      Shock parameters (rho*, std*)
%     .target     Calibration targets
%     .switches   Functional form / mode switches (all fields required;
%                 defaults: base_cfg.switches in lib/setup_dynare.m):
%                   .ghh_pref    GHH=1, KPR=0 preferences
%                   .labor_ext   Labor frictions on/off
%                   .dAP        Alt. search disutility aggregation
%                   .nkpc_target Target NKPC slope instead of kapP
%                   .markup_stst Target steady-state markup
%                   .ls_target   Target labor share for alpF
%
%   dynare_opts  Struct with Dynare/simulation settings:
%     .approxorder       Perturbation order
%     .irfperiod         IRF horizon (quarters)
%     .simperiod         Simulation length
%     .replicnumber      Replications for stoch_simul
%     .simreplicnumber   Simulation replications
%     .dropnumber        Burn-in periods for moments
%     .var_sim_select    String array of variable names for second moments
%
% -------------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------------
%   res         Struct:
%     .irfs.(shock_name).(var_name)   T×1 vector (%-deviations from ss)
%     .relstd                         n_vars × n_vars relative std matrix
%     .corr                           n_vars × n_vars correlation matrix
%     .var_sim_select                 Variable list (echoed from dynare_opts)

global M_ options_ oo_

% -------------------------------------------------------------------------
% 1. Fresh parameter load and overrides
% -------------------------------------------------------------------------
[par, parHW, parSAM, shock, target] = get_params('dynare');
par    = apply_overrides(par,    cfg, 'par');
parHW  = apply_overrides(parHW,  cfg, 'parHW');
parSAM = apply_overrides(parSAM, cfg, 'parSAM');
shock  = apply_overrides(shock,  cfg, 'shock');
target = apply_overrides(target, cfg, 'target');

% Unpack functional-form switches (defaults: lib/setup_dynare.m)
switches = cfg.switches;

% -------------------------------------------------------------------------
% 2. Inject parameters directly into M_.params
% -------------------------------------------------------------------------
M_ = set_M_params(M_, par, parHW, parSAM, shock, target, switches);

% Rebuild the shock covariance from the (possibly overridden) std values
% (2026-09-23 fix). nk_time.dyn's shocks block fixes M_.Sigma_e once at
% preprocessing (driver.m: Sigma_e(i,i) = params(38..43)^2), so overriding
% stdX in M_.params alone has no effect on stoch_simul -- this silently
% disabled the shock isolation in run_shock_isolation_sweep.m
% (tab:emp_checks). Mapped by name: eA->stdA, ..., eD->stdD (the driver's
% parameter order has stdD before stdT). Default IRFs are unaffected, since
% the default std values equal those used at preprocessing.
exo = cellstr(M_.exo_names);
for ii = 1:numel(exo)
    M_.Sigma_e(ii, ii) = shock.(['std' exo{ii}(2:end)])^2;
end

% -------------------------------------------------------------------------
% 3. Re-solve: steady state + decision rules + IRFs + simulation
% -------------------------------------------------------------------------
% Fixed random seed before EVERY simulation (2026-09-29), so each scenario's
% simulated moments are identical whatever ran before it in the session and
% whether or not a cache was reused. The seed is set in run_all_options.m (OPT.seed)
% and passed via the environment variable NKSAM_SEED; scripts run on their
% own use the same default (1).
seed = str2double(getenv('NKSAM_SEED'));
if isnan(seed); seed = 1; end
if exist('set_dynare_seed', 'file')
    set_dynare_seed(seed);
else
    rng(seed, 'twister');
end
[info, oo_, options_, M_] = stoch_simul(M_, options_, oo_, {});
if info(1)
    error('dynare_scenario: stoch_simul failed (error code %d).', info(1));
end

% -------------------------------------------------------------------------
% 4. Extract IRFs into res.irfs.(shock).(variable)
% -------------------------------------------------------------------------
exo_names  = cellstr(M_.exo_names);
endo_names = cellstr(M_.endo_names);
res.irfs   = struct();

for ii = 1:numel(exo_names)
    ename = exo_names{ii};
    for jj = 1:numel(endo_names)
        vname     = endo_names{jj};
        irf_field = [vname '_' ename];
        if isfield(oo_.irfs, irf_field)
            res.irfs.(ename).(vname) = transpose(oo_.irfs.(irf_field)) .* 100;
        end
    end
end

% -------------------------------------------------------------------------
% 5. Compute HP-filtered second moments
% -------------------------------------------------------------------------
var_sim = dynare_opts.var_sim_select;
n_vars  = numel(var_sim);
var_ind = zeros(1, n_vars);
for ii = 1:n_vars
    idx = find(strcmp(endo_names, var_sim(ii)));
    if isempty(idx)
        error('dynare_scenario: variable "%s" not found in model.', var_sim(ii));
    end
    var_ind(ii) = idx;
end

y_sim = transpose(oo_.endo_simul(var_ind, :));
[~, y_cyc] = one_sided_hp_filter(y_sim(dynare_opts.dropnumber + 1:end, :), 1600);

res.relstd = zeros(n_vars, n_vars);
for kk = 1:n_vars
    for jj = 1:n_vars
        val = std(y_cyc(:, kk)) / std(y_cyc(:, jj));
        if val > 100, val = NaN; end
        res.relstd(kk, jj) = val;
    end
end
res.corr           = corrcoef(y_cyc);
res.var_sim_select = var_sim;

% -------------------------------------------------------------------------
% 6. Retain the simulated series
% -------------------------------------------------------------------------
%   Needed by scatter/regression figures (plot_okun_scatter.m), which must be
%   estimated on the model's ergodic distribution rather than on IRFs: pooling
%   IRFs gives every shock the same number of points regardless of its
%   calibrated variance, so the resulting slope is an arbitrary mixture. The
%   simulation weights shocks by their actual contribution.
%
%   Stored in MODEL UNITS -- unlike res.irfs, which dynare_scenario already
%   multiplies by 100 above. var_sim_select mixes gap variables (deviations
%   from a counterfactual, so a blanket x100 gives percent) with level
%   variables such as cu (where x100 would be meaningless), so the scaling is
%   left to the caller, which knows which variable it is plotting.
%
%   Size: (simperiod - dropnumber) x numel(var_sim_select) doubles per
%   scenario -- about 14 MB at the current settings. Set
%   dynare_opts.keep_sim = false to suppress it for many-scenario exercises.
if ~isfield(dynare_opts, 'keep_sim') || dynare_opts.keep_sim
    res.sim.names = var_sim;
    res.sim.raw   = y_sim(dynare_opts.dropnumber + 1:end, :);   % post-burn-in
    res.sim.cyc   = y_cyc;                                      % one-sided HP, lambda=1600
    res.sim.drop  = dynare_opts.dropnumber;
end

end

% =========================================================================
% Local helper: apply struct overrides field by field
% =========================================================================
function s = apply_overrides(s, cfg, field)
    if isfield(cfg, field)
        ov     = cfg.(field);
        fnames = fieldnames(ov);
        for i  = 1:numel(fnames)
            s.(fnames{i}) = ov.(fnames{i});
        end
    end
end
