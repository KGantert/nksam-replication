# Replication package: "When Buying Takes Time: Shock Transmission across Goods and Labor Market Regimes in the New Keynesian Model"

Konstantin Gantert · contact: kgantert@mail.de  
Paper: SSRN working paper, https://doi.org/10.2139/ssrn.5440912  
Code: https://github.com/KGantert/nksam-replication

## Overview

This package reproduces every model-based figure, table and number of the paper and its (online) appendices. All results come from two models that share one calibration (`get_params.m`):

- **the full nonlinear NK-SaM model** (`model/nk_time.dyn`), solved and simulated with Dynare: Section 5, Online Appendices V.3, V.4 and VI;
- **its linearized reduced form** (`lib/model_stst.m`, `lib/model_system.m`), evaluated in MATLAB: Sections 2–4, Appendix C, Online Appendices IV, V.1 and V.2.

One command, `run_all`, runs all scripts and writes every output to `results/`. A full run takes about 20 minutes. The package ships with the reference output of the final run in `results/` (`run_all('cache','fresh')`, 14 October 2026, with all results recomputed from scratch; log in `results/logs/20261014_194859/`). All figures and `.tex` tables in `results/` are identical in content to those in the paper.

## Data availability and provenance

All data are publicly available. The package contains no original data, only calculations on public data. The raw files are included in `data/raw/`, and `data/data.mat`, the input of all scripts, is built from them by `scripts/app_A_build_data.m`.

| Series | Source | Frequency, sample | File |
|---|---|---|---|
| GDP, GDPC1 (real GDP), GDPPOT (potential GDP), NROU (natural rate of unemployment), UNRATE, CPIAUCSL, TCU (capacity utilization: manufacturing, mining, utilities) | Federal Reserve Bank of St. Louis, FRED (original sources: BEA, CBO, BLS, Federal Reserve Board). Downloaded 5 August 2025 as quarterly aggregates. | quarterly, 1947Q1–2025Q2 (series-specific starts) | `data/raw/<ID>.xlsx` |
| Labor wedge (four measures with different data for hours per person: `wedge_OR`, `wedge_CPU`, `wedge_CES/CPS`, `wedge_CES/PRO`; tax-unadjusted) | Karabarbounis (2014), data accompanying the article | quarterly, 1964Q1–2011Q4 | `data/raw/labor_wedge.xls` |
| Service-adjusted capacity utilization, cyclical component (`cu_obs`) | Constructed from FRED TCU and EU service-sector capacity utilization of the European Commission's Business and Consumer Surveys; services mapped to the US through their standard deviation and correlation with industry utilization (Appendix A) | quarterly, 1967Q1–2023Q4 | `data/raw/cu_obs.csv` |

The time-use targets (shopping time and total non-market time relative to market work, 0.21 and 0.707) are averages of the American Time Use Survey (BLS, Table A-1, 2003–2019), constructed as in Petrosky-Nadeau, Wasmer and Zeng (2016). They enter as parameter values in `get_params.m`. All other parameters are taken from the literature cited in Appendix A and Online Appendix II and are also set in `get_params.m`.

Terms of use: FRED data are subject to the FRED terms of use; the series used here originate from U.S. government agencies. The European Commission's survey data may be reused with acknowledgement of the source. The labor wedge data are those published with Karabarbounis (2014) and are redistributed here with citation.

## Computational requirements

- MATLAB R2020a or later (developed with R2026a Update 5), with the Optimization Toolbox (`fsolve`).
- Dynare 7.2, with its `matlab/` folder on the MATLAB path, e.g. `addpath('/Applications/Dynare/7.2/matlab')`. Dynare also provides `one_sided_hp_filter`, used for the data and for all simulated moments.
- Runtime: about 20 minutes for a full run on a MacBook Pro (Apple M3 Pro, macOS). Of this, about 11 minutes are the robustness checks (`online_VI_robustness`) and about 4.5 minutes the Phillips-curve slope grid (`online_VI_rigidity_grid`).
- Disk: about 1 GB of free space while a Dynare script runs; Dynare's simulation output is deleted after each script.
- Randomness: all simulations use a fixed seed (`OPT.seed = 1` in `run_all_options.m`), set before every simulation, so results do not depend on the order in which scripts run.

## Instructions

1. Start MATLAB and put Dynare on the path (see above).
2. Change to this folder and run `run_all`. For a clean replication, use `run_all('cache', 'fresh')`.
3. Outputs are written to `results/`. The run log and a summary with the status of every script are in `results/logs/<timestamp>/`.

`run_all.m` is the entry point; it re-reads every `.m` file before each call, so edits to the options, the scripts, `lib/` or the model take effect without a `clear`, also when made outside the MATLAB editor. Options are set in `run_all_options.m`, or per call (overriding those defaults):

| Option | Default | Meaning |
|---|---|---|
| `RUN.<script>` | paper scripts on, diagnostics off | which scripts run |
| `'scripts'`, `'groups'` | – | run only the named scripts, or groups `main`, `appendix`, `online`, `diagnostics`, `all` |
| `'cache'` | `'auto'` | `'auto'`: caches are deleted automatically when calibration, model, data or code change; `'fresh'`: delete all caches first; `'reuse'`: keep them |
| `'seed'` | 1 | random seed of all simulations |
| `'copy_to_paper'` | false | copy figures and `.tex` tables that differ in content to `../1_nksam_paper/` (author's use) |
| `'cleanup_dynare'` | true | delete Dynare's build and simulation output after each Dynare script |
| `'close_figures'` | true | `false`: keep all MATLAB figure windows open (they are otherwise closed before each script and at the end) |
| `'stop_on_error'` | false | `true`: stop at the first failing script instead of logging the error and continuing |
| `'list'` | – | `run_all('list', true)` lists all scripts |
| `'compare_only'` | false | run nothing; compare the existing `results/` with the paper (with `'copy_to_paper', true`: copy the differing figures and `.tex` tables) |

Every script can also be run on its own (e.g. `run('scripts/main_s5_irfs.m')`).

### Running all or parts of the package

All commands are typed in MATLAB in this folder. `'scripts'` takes precedence over `'groups'`, and both take precedence over the `RUN.<script>` switches in `run_all_options.m`.

```matlab
run_all                                         % all scripts switched on in RUN (paper scripts)
run_all('cache', 'fresh')                       % clean replication: delete all caches first
run_all('list', true)                           % list all scripts, their group and RUN switch; runs nothing

% one or several scripts by name
run_all('scripts', {'online_VI_rigidity_grid'})
run_all('scripts', {'main_s5_irfs', 'main_s5_slope_summary'})

% whole groups: 'main' | 'appendix' | 'online' | 'diagnostics' | 'all'
run_all('groups', {'main'})                     % Sections 2-5
run_all('groups', {'online'})                   % Online Appendices IV-VI
run_all('groups', {'all'})                      % everything, including diagnostics

% options combine with any selection
run_all('scripts', {'online_VI_robustness'}, 'cache', 'reuse')  % re-plot from existing caches
run_all('groups', {'main'}, 'stop_on_error', true)               % stop at the first failing script
run_all('scripts', {'online_VI_rigidity_grid'}, 'close_figures', false)  % keep the figure windows open

% compare with the paper / copy to the paper (author's use)
run_all('compare_only', true)                         % run nothing; list results that differ from the paper
run_all('compare_only', true, 'copy_to_paper', true)  % ... and copy the differing figures and tables
```

| Script | Group | Dynare | Paper result |
|---|---|---|---|
| `main_s3_s4_slopes` | main | no | Sections 2–4 slope figures, calibration numbers, Appendix C cutoffs, OA V.2 |
| `main_s5_irfs` | main | yes | Section 5 phase diagram and impulse responses |
| `main_s5_slope_summary` | main | yes | Section 5, Table 3 (`tab:slope_summary`) |
| `app_A_build_data` | appendix | no | `data/data.mat` from `data/raw/` (off by default; `data.mat` is shipped) |
| `app_A_calibration` | appendix | yes | Appendix A, Table A.1 implied parameters |
| `app_A_data_moments` | appendix | no | capacity-utilization moments in the data |
| `online_IV_equivalence` | online | no | OA IV, Table IV.1 |
| `online_V1_steady_states` | online | no | OA V.1 steady-state figures |
| `online_V3_efficiency_irfs` | online | yes | OA V.3 matching-efficiency IRFs |
| `online_V4_emp_checks` | online | yes | OA V.4, Table V.1 |
| `online_VI_robustness` | online | yes | Section 6 and OA VI robustness checks 1–11 and the literature combinations (incl. κ_P and κ_W at the bounds of their 95% intervals) |
| `online_VI_fixed_kapP` | online | no | OA VI, check 5: Phillips-curve slopes with fixed κ_P (numbers quoted in the text) |
| `online_VI_rigidity_grid` | online | yes | OA VI: price vs. wage rigidity grid over the two Phillips-curve slope targets (95% intervals and other literature estimates), Figure VI.8 |
| `diag_*` | diagnostics | mixed | checks not in the paper (see Notes; off by default) |

## Structure of the package

```
run_all.m      master script (entry point)
run_all_options.m
               options of run_all (RUN switches, OPT defaults)
get_params.m   calibration of both models
scripts/       one script per paper result, named after its place in the paper:
               main_s<section>_*, app_<appendix>_*, online_<appendix>_*
diagnostics/   checks that are not part of the paper (diag_*)
lib/           shared functions; setup_dynare.m and setup_slopes.m prepare every script;
               run_all_engine.m is the code of run_all
model/         Dynare model (nk_time.dyn) and its steady-state file
data/          data.mat (input of all scripts), raw/ (source files)
cache/         caches, created and invalidated automatically
results/       figures/  *.eps (paper figures)
               tables/   *.tex (read by the paper), tab_*.txt (tables typed into the paper), *.csv
               txt/      numbers quoted in the text, reports, logs of single scripts
               mat/      intermediate results
               logs/     run_all logs
```

## Figures and tables

| Paper | Label | Script | Output (`results/`) |
|---|---|---|---|
| Table 1, A.1–A.3 | `tab:calibration`, `tab:calibration_*` | `get_params.m`, `main_s3_s4_slopes`, `app_A_calibration` | typed in; implied values in `txt/calibration_summary.txt` (ε, κ_P, κ_W, ε_W, μ_N, ψ_H) and `txt/calibration_dynare.txt` (μ_H, ψ_D, μ_D) |
| Figure 1 | `fig:slopes_5eq_util` | `main_s3_s4_slopes` | `figures/fig_slopes_5eq_cu_pe.eps` |
| Figure 2 | `fig:slopes_5eq` | `main_s3_s4_slopes` | `figures/fig_slopes_5eq_ee_pc_rw.eps` |
| Figure 3 | `fig:phase_diagram` | `main_s5_irfs` | `figures/fig_phase_diagram.eps` |
| Table 3 | `tab:slope_summary` | `main_s5_slope_summary` | `tables/tab_slope_summary.txt` (typed in) |
| Figures 4–7 | `fig:irf_default_{policy,search_effort,tfp,eis}` | `main_s5_irfs` | `figures/fig_irf_default_{policy,search,tfp,eis}.eps` |
| Figure C.1 | `fig:cutoff_gammaQ` | `main_s3_s4_slopes` | `figures/fig_stst_gamES_cutoff.eps` |
| Table IV.1 | `tab:param_equiv` | `online_IV_equivalence` | `tables/tab_param_equiv.tex` |
| Figures V.1, V.2 | `fig:stst_fixed`, `fig:stst_targeted` | `online_V1_steady_states` | `figures/fig_stst_{fixed,targeted}.eps` |
| Figure V.3 | `fig:app_slopes_tot_wedge` | `main_s3_s4_slopes` | `figures/fig_slopes_5eq_lw_se_mc.eps` |
| Figure V.4 | `fig:irf_add_matching` | `online_V3_efficiency_irfs` | `figures/fig_irf_default_efficiency.eps` |
| Table V.1 | `tab:emp_checks` | `online_V4_emp_checks` | `tables/tab_emp_checks.txt` (typed in) |
| Table VI.1 | `tab:robust_calibration` | `lib/robust_define_checks.m` | typed in (definition of the checks) |
| Table VI.2 | `tab:robust_regimes` | `online_VI_robustness` | `tables/tab_robust_regimes.tex` |
| Table VI.3 | `tab:robust_magnitudes` | `online_VI_robustness` | `tables/tab_robust_magnitudes.tex` |
| Figures VI.1–VI.4 | `fig:robust_{calib,qs,iq,longterm}` (checks 1–4) | `online_VI_robustness` | `figures/fig_robust_<check>.eps` |
| Figures VI.5–VI.7 | `fig:robust_{kapP,kapPci,kapW}` (checks 5–7; the literature combinations have no figure) | `online_VI_robustness` | `figures/fig_robust_<check>.eps` |
| Figure VI.8 | `fig:robust_rigidity` | `online_VI_rigidity_grid` | `figures/fig_robust_rigidity.eps` |
| Figures VI.9–VI.12 | `fig:robust_{nohp,ghh,hours,capital}` (checks 8–11) | `online_VI_robustness` | `figures/fig_robust_<check>.eps` |

Table 2 (`tab:coef_reminder`) and Table II.1 (`tab:calibration_sources_extended`) contain definitions and parameter values from `get_params.m`; they are not computed.

## Numbers quoted in the text

| Numbers | Where in the paper | File (`results/txt/`) | Script |
|---|---|---|---|
| ε, κ_P (NK-SaM, benchmark), κ_W and other implied parameters | Section 2, Appendix A, Section 4 | `calibration_summary.txt` | `main_s3_s4_slopes` |
| ν_D cutoffs (incl. the sign cutoff of the utilization feedback loop, Section 3.3 footnote) | Section 4, Appendix C, Section 6, OA VI | `nuD_cutoffs.txt` | `main_s3_s4_slopes` |
| Crossings and endpoints of the slope curves | Sections 3–4, OA V.2 | `fig_slopes_5eq_*.txt` | `main_s3_s4_slopes` |
| corr(cu, Y), sd(cu)/sd(Y), TCU mean | Introduction, Appendix A, OA V.4, OA VI | `data_moments.txt` | `app_A_data_moments` |
| Regime thresholds β\*, Okun comparison | Section 5 (`sec:phase_diagram`, `sec:okun_limits`) | `phase_diagram.txt` | `main_s5_irfs` |
| Impulse responses quoted in the text (e.g. labor productivity, price elasticity on impact) | Section 5 | `irf_impact.txt` | `main_s5_irfs` |
| Channel slopes Θ_Y, Θ_u; Proposition 2 (direct layer, tightness coefficient, β\*) | Sections 4–5 | `slope_components.txt` | `main_s5_slope_summary` |
| β_shock under alternative weightings; output gap summed over the horizon | Section 5, footnote in `sec:channel_aggregation`; Section 6 | `beta_alternatives.txt` | `main_s5_slope_summary` |
| Steady-state ratios at the largest γ_Q | OA V.1 | `fig_stst_endpoints.txt` | `online_V1_steady_states` |
| Equivalence classes, Jacobian | OA IV | `param_equivalence.txt`, `param_jacobian.txt` | `online_IV_equivalence` |
| Robustness: impact responses, direction reading, channels, thresholds, ω_shock per variant, search-effort cyclicality and its cross-variant correlation (OA V), real wage and utilization after monetary policy (OA VI) | Section 6, OA V, OA VI | `robustness_summary.txt` (and the tables VI.2–VI.3) | `online_VI_robustness` |
| Check 5: κ_P, implied labor-share and price Phillips-curve slopes | OA VI (`sec:robust_kapP`) | `fixed_kapP_summary.txt` | `online_VI_fixed_kapP` |
| ω_shock, κ_P, κ_W and NK-SaM/benchmark ratios over the Phillips-curve slope grid | OA VI (`sec:robust_rigidity`), Section 6 | `rigidity_grid_summary.txt` | `online_VI_rigidity_grid` |

## Notes

- **Rounding:** all numbers typed into the paper (Tables 1, 3, A.1, V.1 and the text) agree with the reference output up to the rounding shown in the paper (checked against the 14 October 2026 run).

- **Caches** (`cache/`) hold expensive intermediate solutions: the default Dynare scenarios, the shock-isolation sweeps, the reduced-form sweeps, and one file per robustness check. `lib/check_cache_signature.m` compares all values returned by `get_params` and the full text of `get_params.m`, `lib/`, `scripts/`, the model files and `data.mat` with the state under which the caches were built, and deletes all caches when anything differs. So a changed calibration is always used.
- **Implementation of limit cases:** Γ_Q = 0 is implemented as −10⁻⁴ (Cobb-Douglas), and Γ_Q → −∞ as −10⁴. Parameters of extension margins that are absent from the core model are set to negligible placeholders (α_F = α_H = γ_P = 10⁻⁵, δ_F1 = δ_H1 = 0.999); see the footnote in Appendix A.
- **Diagnostics** (`diagnostics/`, off by default):
  - `diag_kapP_switch` checks that the two Phillips-curve calibration modes (target the slope or fix κ_P) are exact inverses.
  - `diag_quality_search` finds the range of γ_P with a steady state (robustness check 2).
  - `diag_data_gaps` plots the model-implied gaps against US data.
  - `diag_slope_paths` complements Table 3 with the aggregate slopes horizon by horizon and a moment-based comovement measure.
  - `diag_shock_persistence` re-solves the benchmark and the NK-SaM model with more persistent shocks (ρ_A = 0.95, discount rate ρ_Z = 0.9, all other shocks 0.8) and plots the four IRF curves per variable in the layout of the robustness figures (`fig_robust_persistence.eps`), with impact, peak and cumulative responses, NK-SaM/benchmark ratios and regime quadrants in `diag_shock_persistence.txt`. Not one of the 11 robustness checks.
- **One purpose per script:** every output file is written by exactly one script. Computations that several scripts need (the four default Dynare scenarios, the shock-by-shock simulations) are cached and shared, never repeated.

## References

- Adjemian, S., M. Juillard, F. Karamé, W. Mutschler, J. Pfeifer, M. Ratto, N. Rion and S. Villemot (2026). Dynare: Reference Manual, Version 7. Dynare Working Papers 87, CEPREMAP.
- European Commission. Business and Consumer Surveys. https://economy-finance.ec.europa.eu/economic-forecast-and-surveys/business-and-consumer-surveys_en
- Federal Reserve Bank of St. Louis. FRED, Federal Reserve Economic Data. https://fred.stlouisfed.org/ (series GDP, GDPC1, GDPPOT, NROU, UNRATE, CPIAUCSL, TCU; downloaded 5 August 2025).
- Karabarbounis, L. (2014). The Labor Wedge: MRS vs. MPN. Review of Economic Dynamics 17(2), 206–223. https://doi.org/10.1016/j.red.2013.07.003
- Petrosky-Nadeau, N., E. Wasmer and S. Zeng (2016). Shopping Time. Economics Letters 143, 52–60. https://doi.org/10.1016/j.econlet.2016.02.003
- U.S. Bureau of Labor Statistics. American Time Use Survey. https://www.bls.gov/tus/

## License

The code is licensed under the MIT License (`LICENSE`). The data in `data/raw/` remain subject to the terms of their original providers (see above).
