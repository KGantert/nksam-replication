function r = robust_solve(cfg, dynare_opts)
% ROBUST_SOLVE  Solve one scenario with dynare_scenario and keep a slim
%   result for the robustness exercise: IRFs, moments, and a record of the
%   steady state and of the parameters solved in the steady-state file
%   (so the calibration of each check can be documented and checked).
%
%   r.irfs.(shock).(var)   as in dynare_scenario (percent deviations)
%   r.relstd, r.corr       HP-filtered moments (all shocks active)
%   r.var_sim_select
%   r.ss.(var)             steady-state values (levels), selected variables
%   r.par.(name)           selected parameter values after the solve
global M_ oo_

res = dynare_scenario(cfg, dynare_opts);

r.irfs           = res.irfs;
r.relstd         = res.relstd;
r.corr           = res.corr;
r.var_sim_select = res.var_sim_select;

endo = cellstr(M_.endo_names);
ss_vars = {'t', 'n', 'h', 'd', 'dq', 'dp', 'cu', 'q', 'x', 'ped', 'ue', ...
           'mcY', 'pq', 'kf', 'kh', 'ef'};
r.ss = struct();
% Steady state used for the decision rules (oo_.steady_state is not
% refreshed by the direct stoch_simul call in dynare_scenario and came out
% as zeros in the first run).
if isfield(oo_, 'dr') && isfield(oo_.dr, 'ys') && ~isempty(oo_.dr.ys)
    ys = oo_.dr.ys;
else
    ys = oo_.steady_state;
end
for ii = 1:numel(ss_vars)
    idx = find(strcmp(endo, ss_vars{ii}), 1);
    if ~isempty(idx)
        r.ss.(ss_vars{ii}) = ys(idx);
    end
end

pnames = cellstr(M_.param_names);
p_list = {'epsW', 'kapW', 'kapP', 'epss', 'alpF', 'alpH', 'gamH', 'gamP', ...
          'gamQ', 'subQ', 'nuD', 'nuN', 'delT', 'delI', 'muN', 'muD', 'muH', ...
          'psiQ', 'psiD', 'psiH', 'ghh', 'labor_ext', 'ls_target'};
r.par = struct();
for ii = 1:numel(p_list)
    idx = find(strcmp(pnames, p_list{ii}), 1);
    if ~isempty(idx)
        r.par.(p_list{ii}) = M_.params(idx);
    end
end
end
