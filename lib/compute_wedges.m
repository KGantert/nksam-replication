function [out_sam, out_nk, wedge] = compute_wedges(p)
% COMPUTE_WEDGES  Compute SaM model output and NK baseline, and their ratio wedges.
%
%   [out_sam, out_nk, wedge] = compute_wedges(p)
%
%   p is a parameter struct (lib/build_p.m).
%   Model selection flags p.hw_select and p.hp_select are applied here.

% Apply model selection (zero-out home production and/or price search)
[p.gamH, p.subH, p.gamP] = apply_model_selection(...
    p.gamH, p.subH, p.gamP, p.hw_select, p.hp_select);

% ---- Baseline NK model (no goods market SaM) ----------------------------
% Set SaM offsetting parameters
EPS_OFF     = 1e-5;
EPS_NTR     = 1;
% Assign to parameter space
p_nk        = p;
p_nk.muD    = EPS_OFF;
p_nk.gamQ   = EPS_OFF;
p_nk.subQ   = EPS_OFF;
p_nk.gamP   = EPS_OFF;
p_nk.psiQ   = EPS_NTR;
p_nk.tight      = EPS_NTR;
p_nk.q      = EPS_NTR;
% Call NK model and save results
out_nk      = model_system(p_nk);

% ---- Goods market SaM model ---------------------------------------------
p_sam       = p;
% Call NK-SaM model and save results
out_sam     = model_system(p_sam);

% ---- Wedges (SaM relative to NK) ----------------------------------------
wedge.AS = real(out_sam.AS_ag / out_nk.AS_ag);
wedge.AD = real(out_sam.AD_ag / out_nk.AD_ag);

end
