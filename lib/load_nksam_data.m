function dat = load_nksam_data()
% LOAD_NKSAM_DATA  Load data.mat and compute all derived series.
%   (Named load_nksam_data, not load_data, because Dynare's toolbox has a
%   different function load_data.)
%
%   Returns a struct dat with fields:
%     gdp_gap, ue_gap, okun           - output/unemployment gaps and Okun coefficient
%     cpi_infl, defl_infl             - demeaned inflation measures
%     caput_alt, caput                - capacity utilisation series
%     lw_cps, lw_pro, lw_cpu, lw_or  - labour wedge series (HP-filtered)
%     observation_date                - date vector for plotting

ensure_hp_filter();   % Dynare's one_sided_hp_filter
raw = load(nksam_path('data', 'data.mat'));

% Output gap
dat.gdp_gap = 100 .* (raw.GDPC1 - raw.GDPPOT) ./ raw.GDPPOT;

% Unemployment gap
dat.ue_gap  = raw.UNRATE - raw.NROU;

% Okun's Law coefficient
dat.okun    = nanmean(dat.gdp_gap ./ dat.ue_gap);

% CPI inflation (demeaned)
cpi_infl        = [NaN; diff(log(raw.CPIAUCSL)) .* 100];
dat.cpi_infl    = cpi_infl - nanmean(cpi_infl);

% GDP deflator inflation (demeaned)
gdp_defl        = raw.GDP ./ raw.GDPC1;
defl_infl       = [NaN; diff(log(gdp_defl)) .* 100];
dat.defl_infl   = defl_infl - nanmean(defl_infl);

% Capacity utilisation: Gantert (2025) measure
dat.caput_alt = [NaN(80,1); raw.cu_obs; NaN(6,1)] .* 100;

% Capacity utilisation: HP-filter cyclical component
dat.caput = NaN(length(raw.TCU), 1);
[~, dat.caput(81:end)] = one_sided_hp_filter(log(raw.TCU(81:end)) .* 100, 1600);

% Labour wedge series: HP-filter cyclical components
dat.lw_cps = NaN(length(raw.wedge_CES_CPS), 1);
dat.lw_pro = NaN(length(raw.wedge_CES_PRO), 1);
dat.lw_cpu = NaN(length(raw.wedge_CPU), 1);
dat.lw_or  = NaN(length(raw.wedge_OR),  1);
[~, dat.lw_cps(69:256)] = one_sided_hp_filter(log(raw.wedge_CES_CPS(69:256)) .* 100, 1600);
[~, dat.lw_pro(69:256)] = one_sided_hp_filter(log(raw.wedge_CES_PRO(69:256)) .* 100, 1600);
[~, dat.lw_cpu(69:260)] = one_sided_hp_filter(log(raw.wedge_CPU(69:260))     .* 100, 1600);
[~, dat.lw_or(69:256)]  = one_sided_hp_filter(log(raw.wedge_OR(69:256))      .* 100, 1600);

% Observation dates (for plotting)
dat.observation_date = raw.observation_date;

end
