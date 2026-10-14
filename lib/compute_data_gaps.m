function gaps = compute_data_gaps(par, dat, flags, s_start)
% COMPUTE_DATA_GAPS  Compute model-implied gap series from US data.
%
%   Inputs
%     par     - parameter struct from get_params()
%     dat     - data struct from load_nksam_data()
%     flags   - model selection flags struct
%     s_start - sample start index for statistics (set in diagnostics/diag_data_gaps.m)
%
%   Output
%     gaps  - struct with fields:
%               cu_gap_1/2, pe_gap_1/2, lw_gap_1/2/nk, d_gap_1/2
%               gdp_gap_ue_share, gdp_gap_cap_share
%               std_dev (nested struct), correl, s_start

p_base = build_p(par, dat, flags);

% SaM slopes: subQ = -0.27 (subQ_loop(2), default)
p_sam1      = p_base;
p_sam1.subQ = par.subQ_loop(2);
[out_sam_1, out_nk_1] = compute_wedges(p_sam1);

% SaM slopes: subQ = -2.7 (subQ_loop(1))
p_sam2      = p_base;
p_sam2.subQ = par.subQ_loop(1);
out_sam_2   = compute_wedges(p_sam2);

% Model-implied gap series
gaps.cu_gap_1  = out_sam_1.CU_t .* dat.gdp_gap + out_sam_1.CU_ue .* dat.ue_gap;
gaps.cu_gap_2  = out_sam_2.CU_t .* dat.gdp_gap + out_sam_2.CU_ue .* dat.ue_gap;
gaps.pe_gap_1  = out_sam_1.PE_t .* dat.gdp_gap + out_sam_1.PE_ue .* dat.ue_gap;
gaps.pe_gap_2  = out_sam_2.PE_t .* dat.gdp_gap + out_sam_2.PE_ue .* dat.ue_gap;
gaps.lw_gap_1  = out_sam_1.LW_t .* dat.gdp_gap + out_sam_1.LW_ue .* dat.ue_gap;
gaps.lw_gap_2  = out_sam_2.LW_t .* dat.gdp_gap + out_sam_2.LW_ue .* dat.ue_gap;
gaps.lw_gap_nk = out_nk_1.LW_t  .* dat.gdp_gap + out_nk_1.LW_ue  .* dat.ue_gap;
gaps.d_gap_1   = out_sam_1.D_t  .* dat.gdp_gap + out_sam_1.D_ue  .* dat.ue_gap;
gaps.d_gap_2   = out_sam_2.D_t  .* dat.gdp_gap + out_sam_2.D_ue  .* dat.ue_gap;

% Output gap decomposition: gdp_gap = gdp_gap_ue_share + gdp_gap_cap_share
gaps.gdp_gap_ue_share  = (-1) .* (out_sam_1.CU_ue ./ out_sam_1.CU_t) .* dat.ue_gap;
gaps.gdp_gap_cap_share = gaps.cu_gap_1 ./ out_sam_1.CU_t;

% Store sample start for use in figs_data
gaps.s_start = s_start;
s = s_start;
gaps.std_dev.gdp_gap    = std(dat.gdp_gap(s:end));
gaps.std_dev.ue_gap     = std(dat.ue_gap(s:end));
gaps.std_dev.util_gap_1 = std(gaps.cu_gap_1(s:end));
gaps.std_dev.util_gap_2 = std(gaps.cu_gap_2(s:end));
gaps.std_dev.pe_gap_1   = std(gaps.pe_gap_1(s:end));
gaps.std_dev.pe_gap_2   = std(gaps.pe_gap_2(s:end));
gaps.std_dev.lw_gap_nk  = std(gaps.lw_gap_nk(s:end));
gaps.std_dev.lw_gap_1   = std(gaps.lw_gap_1(s:end));
gaps.std_dev.lw_gap_2   = std(gaps.lw_gap_2(s:end));
gaps.std_dev.d_gap_1    = std(gaps.d_gap_1(s:end));
gaps.std_dev.d_gap_2    = std(gaps.d_gap_2(s:end));

gaps.correl = corrcoef([dat.gdp_gap(s:end)   gaps.cu_gap_1(s:end)  gaps.cu_gap_2(s:end) ...
                        gaps.pe_gap_1(s:end)  gaps.pe_gap_2(s:end)  gaps.lw_gap_nk(s:end) ...
                        gaps.lw_gap_1(s:end)  gaps.lw_gap_2(s:end)]);

end
