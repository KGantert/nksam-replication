function st = robust_iso_stats(cfg, dynare_opts)
% ROBUST_ISO_STATS  Cyclicality statistics under the search-effort shock
%   simulated in isolation (all other shocks: std = 1e-5, rho = 0), as in
%   lib/run_shock_isolation_sweep.m and tab:emp_checks.
%
%   st.corr_lw_y    corr(labor wedge, real GDP)
%   st.corr_cu_y    corr(capacity utilization, real GDP)
%   st.relstd_cu_y  sd(capacity utilization) / sd(real GDP)
%   (one-sided HP filter, lambda = 1600, on the simulated series)
others = {'A', 'Z', 'M', 'P', 'T'};   % every shock except D (search effort)
for ii = 1:numel(others)
    cfg.shock.(['std' others{ii}]) = 1e-5;
    cfg.shock.(['rho' others{ii}]) = 0;
end

res = dynare_scenario(cfg, dynare_opts);

vs  = cellstr(res.var_sim_select);
iY  = find(strcmp(vs, 'gdp_obs'), 1);
iLW = find(strcmp(vs, 'lw_obs'),  1);
iCU = find(strcmp(vs, 'cu'),      1);

st.corr_lw_y   = res.corr(iLW, iY);
st.corr_cu_y   = res.corr(iCU, iY);
st.relstd_cu_y = res.relstd(iCU, iY);
end
