% *************************************************************************
% When Buying Takes Time:
% Implications for the New-Keynesian Business Cycle Model
% diag_kapP_switch.m -- TEST OF THE kappa_P CALIBRATION SWITCH (reduced-form model)
% -------------------------------------------------------------------------
% Konstantin Gantert
% kgantert@mail.de
% *************************************************************************
%
% The two Phillips-curve calibration modes are exact inverses:
%     kapP_select == 0 :  kapP          = pPIpi*sPImc / pc_slope
%     kapP_select == 1 :  pc_slope_impl = pPIpi*sPImc / kapP
% so imposing the kappa_P that mode 0 produces must reproduce mode 0's
% output field for field. This script checks that round trip for both the
% NK-SaM model and the benchmark NK model, and prints the kappa_P values
% to paste into par.kapP in get_params.m.
%
% Diagnostic (not in the paper): run diagnostics/diag_kapP_switch.m. Puts the
% codebase on the path itself (no lib/setup_slopes.m: the sweeps are not needed).
clear; clc;

this_file_dir = fileparts(mfilename('fullpath'));   % <codebase>/diagnostics
repo_root     = fileparts(this_file_dir);           % <codebase>
addpath(genpath(repo_root));

TOL = 1e-12;

%% ------------------------------------------------------------------------
% BASELINE SETUP (same flags as lib/setup_slopes.m)
% -------------------------------------------------------------------------
flags.ghh         = 0;
flags.hw_select   = 1;
flags.hp_select   = 0;
flags.mp_select   = 1;
flags.stst_target = 1;
flags.kapP_select = 0;

par = get_params('slopes');
dat = load_nksam_data();
p0  = build_p(par, dat, flags);

% Reproduce the two parameter structs compute_wedges() evaluates, so the
% test covers the benchmark NK block as well as the NK-SaM block.
[p_sam, p_nk] = wedge_structs(p0);

%% ------------------------------------------------------------------------
% MODE 0: SLOPE TARGETED, kappa_P ENDOGENOUS
% -------------------------------------------------------------------------
out_sam_0 = model_system(p_sam);
out_nk_0  = model_system(p_nk);

fprintf('Mode 0 (target labour-share slope = %.4f):\n', p0.pc_slope);
fprintf('   NK-SaM  : kapP = %10.4f   pc_slope_impl = %.6f\n', ...
    out_sam_0.kapP, out_sam_0.pc_slope_impl);
fprintf('   NK bench: kapP = %10.4f   pc_slope_impl = %.6f\n\n', ...
    out_nk_0.kapP, out_nk_0.pc_slope_impl);

%% ------------------------------------------------------------------------
% ROUND TRIP: IMPOSE THE IMPLIED kappa_P, EXPECT IDENTICAL OUTPUT
% -------------------------------------------------------------------------
p_sam_1 = p_sam;  p_sam_1.kapP_select = 1;  p_sam_1.kapP_dir = out_sam_0.kapP;
p_nk_1  = p_nk;   p_nk_1.kapP_select  = 1;  p_nk_1.kapP_dir  = out_nk_0.kapP;

out_sam_1 = model_system(p_sam_1);
out_nk_1  = model_system(p_nk_1);

ok_sam = compare_out(out_sam_0, out_sam_1, TOL, 'NK-SaM ');
ok_nk  = compare_out(out_nk_0,  out_nk_1,  TOL, 'NK bench');

%% ------------------------------------------------------------------------
% MODE 1 AT THE CALIBRATED par.kapP: IMPLIED SLOPES
% -------------------------------------------------------------------------
% Under direct calibration both models share one kappa_P (compute_wedges
% copies p into p_nk), so the labour-share slope differs across models
% instead of the price adjustment cost.
flags1 = flags;  flags1.kapP_select = 1;
p1     = build_p(par, dat, flags1);
[q_sam, q_nk] = wedge_structs(p1);
r_sam  = model_system(q_sam);
r_nk   = model_system(q_nk);

fprintf('\nMode 1 (impose par.kapP = %.4f):\n', par.kapP);
fprintf('   NK-SaM  : kapP = %10.4f   pc_slope_impl = %.6f   AS_ag = %.6f\n', ...
    r_sam.kapP, r_sam.pc_slope_impl, r_sam.AS_ag);
fprintf('   NK bench: kapP = %10.4f   pc_slope_impl = %.6f   AS_ag = %.6f\n', ...
    r_nk.kapP,  r_nk.pc_slope_impl,  r_nk.AS_ag);
fprintf('   AS wedge (SaM/NK) = %.6f   [mode 0: %.6f]\n', ...
    real(r_sam.AS_ag/r_nk.AS_ag), real(out_sam_0.AS_ag/out_nk_0.AS_ag));

%% ------------------------------------------------------------------------
% VERDICT
% -------------------------------------------------------------------------
fprintf('\n');
if ok_sam && ok_nk
    fprintf('PASS: both calibration modes agree at the implied kappa_P.\n');
else
    fprintf('FAIL: see mismatches above.\n');
end

if abs(out_sam_0.kapP - par.kapP) > 0.5
    fprintf(['NOTE: par.kapP = %.4f differs from the baseline NK-SaM value ' ...
             '%.4f.\n      Set par.kapP = %.4f in get_params.m for the two modes ' ...
             'to coincide.\n'], par.kapP, out_sam_0.kapP, out_sam_0.kapP);
end


% =========================================================================
% LOCAL HELPERS
% =========================================================================

function [p_sam, p_nk] = wedge_structs(p)
% WEDGE_STRUCTS  Rebuild the SaM and benchmark-NK parameter structs exactly
%   as compute_wedges() does, so the test evaluates the same objects.
[p.gamH, p.subH, p.gamP] = apply_model_selection( ...
    p.gamH, p.subH, p.gamP, p.hw_select, p.hp_select);

EPS_OFF = 1e-5;
EPS_NTR = 1;

p_sam       = p;

p_nk        = p;
p_nk.muD    = EPS_OFF;
p_nk.gamQ   = EPS_OFF;
p_nk.subQ   = EPS_OFF;
p_nk.gamP   = EPS_OFF;
p_nk.psiQ   = EPS_NTR;
p_nk.tight  = EPS_NTR;
p_nk.q      = EPS_NTR;
end

function ok = compare_out(a, b, tol, label)
% COMPARE_OUT  Field-by-field relative comparison of two model_system
%   outputs. NaN in both counts as a match.
flds = fieldnames(a);
ok   = true;
for k = 1:numel(flds)
    f  = flds{k};
    va = a.(f);  vb = b.(f);
    if isequaln(va, vb)   % covers exact equality, NaN and +/-Inf
        continue
    end
    d = abs(va - vb) ./ max(1, abs(va));
    if ~(d <= tol)
        ok = false;
        fprintf('   %s mismatch in %-14s : %.10g vs %.10g (rel %.3g)\n', ...
            label, f, va, vb, d);
    end
end
if ok
    fprintf('   %s round trip OK (%d fields, rel. tol %g)\n', label, numel(flds), tol);
end
end

% ----------------------------- End of file -------------------------------
