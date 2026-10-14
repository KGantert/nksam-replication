function p = build_p(par, dat, flags)
% BUILD_P  Assemble the model parameter struct from par, dat, and flags.
%
%   Replaces the 33-argument build_param_struct() call.
%
%   Inputs
%     par   - parameter struct from get_params()
%     dat   - data struct from load_nksam_data()
%     flags - model selection struct with fields:
%               ghh, hw_select, hp_select, mp_select, stst_target
%               kapP_select (optional, defaults to 0)

% Steady-state targets
p.hN      = par.hN;        p.dN      = par.dN;
p.n         = par.n;
p.q         = par.cu;          p.tight         = par.tight;
p.mp        = par.mp;          p.ue        = par.ue;
p.chGDP     = par.chGDP;       p.pc_slope  = par.slopeLS;
p.okun      = dat.okun;

% Phillips-curve calibration: target slope (kapP_select==0, uses p.pc_slope)
% or impose the price adjustment cost directly (kapP_select==1, uses
% p.kapP_dir). Named kapP_dir to keep it distinct from the model OUTPUT
% out.kapP, which is the calibrated/imposed value actually used.
if isfield(par, 'kapP')
    p.kapP_dir = par.kapP;
else
    p.kapP_dir = NaN;
end

% Structural parameters
p.gamH      = par.gamH;        p.subH      = par.subH;
p.psiH      = par.psiH;        p.muH       = par.muH;
p.nuH       = par.nuH;         p.alpH      = par.alpH;
p.muN       = par.muN;         p.nuN       = par.nuN;
p.alpF      = par.alpF;        p.sig       = par.sig;
p.epsP      = par.epsP;        p.muD       = par.muD;
p.nuD       = par.nuD;         p.gamQ      = par.gamQ;
p.subQ      = par.subQ;        p.psiQ      = par.psiQ;
p.gamP      = par.gamP;

% Model selection flags
p.ghh         = flags.ghh;
p.hw_select   = flags.hw_select;
p.hp_select   = flags.hp_select;
p.mp_select   = flags.mp_select;
p.stst_target = flags.stst_target;
if isfield(flags, 'kapP_select')
    p.kapP_select = flags.kapP_select;
else
    p.kapP_select = 0;   % backward-compatible default
end

% -------------------------------------------------------------------------
% Calibrate disutility / efficiency normalisations via stst_target = 1.
% Only needed when stst_target == 0: when stst_target == 1, model_stst
% recomputes these from time-use targets during the actual model run.
% -------------------------------------------------------------------------
p_calib             = p;
p_calib.stst_target = 1;
% Set disutility parameters by steady-state targets and default calibration
[p_calib.gamH, p_calib.subH, p_calib.gamP] = apply_model_selection( ...
    p.gamH, p.subH, p.gamP, p.hw_select, p.hp_select);
[~, par_calib] = model_stst(p_calib);
p.muN  = par_calib.muN;
p.muH  = par_calib.muH;
p.muD  = par_calib.muD;
p.psiH = par_calib.psiH;
p.psiQ = par_calib.psiQ;

end
