% diag_data_gaps.m -- diagnostic (not in the paper): model-implied gap series vs. US data
% -------------------------------------------------------------------------
% PRODUCES results/figures/gap_decomp_data.eps, cu_pe_lw_se_gap_data.eps
% (lib/compute_data_gaps.m, lib/figs_data.m)
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));

s_start = 85;
gaps = compute_data_gaps(par, dat, flags, s_start);
figs_data(gaps, dat, lwdth);
