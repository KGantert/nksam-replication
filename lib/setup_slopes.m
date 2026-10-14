% setup_slopes.m  (lib) -- shared preamble of every script using the
% linearized reduced-form model (Sections 3-4, Appendix C, Online Appendix IV-V)
% -------------------------------------------------------------------------
% Run as the FIRST line of a script:
%   run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));
% Clears the workspace, puts the codebase on the path, checks the cache
% signature (lib/check_cache_signature.m), builds the baseline parameter
% struct and computes (or loads from cache/slopes_common.mat) the gamma_Q
% cutoff and the nu_D sweeps behind the slope figures.
%
% PROVIDES: flags, par, dat, p0, lwdth, gamQ_cut, gamQ_cut_loop, gamQ_loop,
%   res_sam, res_nk  (sweep over nu_D for Gamma_Q in par.subQ_loop),
%   res_gray         (same sweep for Gamma_Q -> -infinity, par.subQ_low)
% -------------------------------------------------------------------------
clear all; clc;

this_file_dir = fileparts(mfilename('fullpath'));       % <codebase>/lib
repo_root     = fileparts(this_file_dir);               % <codebase>
addpath(genpath(repo_root));
check_cache_signature(repo_root);   % deletes all caches if calibration/model/code changed

lwdth = 1.5;   % Line width for all graphs (shared plotting setting)

% -------------------------------------------------------------------------
% MODEL SELECTION FLAGS (baseline calibration)
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

cache_file = nksam_path('cache', 'slopes_common.mat');

if exist(cache_file, 'file')
    load(cache_file, 'gamQ_cut', 'gamQ_cut_loop', 'gamQ_loop', ...
        'res_sam', 'res_nk', 'res_gray');
else
    [gamQ_cut, gamQ_cut_loop, gamQ_loop] = compute_gamQ_cutoff( ...
        p0, par.mp_cut_loop, par.epsP_cut_loop, par.gamQ_low, par.gamQ_high);

    exps = struct();
    exps(1).name       = 'nuD';
    exps(1).param      = 'subQ';
    exps(1).values     = par.subQ_loop;
    exps(1).sam_fields = {'CU_t','CU_ue','CU_ag', 'PE_t','PE_ue','PE_ag', ...
                          'LW_t','LW_ue','LW_ag', 'AS_t','AS_ue','AS_ag', ...
                          'AD_t','AD_ue','AD_ag', 'WG_t','WG_ue','WG_ag','kapP','pc_slope_impl', ...
                          'D_t','D_ue','D_ag', 'MC_t','MC_ue','MC_ag'};
    exps(1).nk_fields  = {'LW_t','LW_ue','LW_ag', 'AS_t','AS_ue','AS_ag', ...
                          'AD_t','AD_ue','AD_ag', 'WG_t','WG_ue','WG_ag','kapP','pc_slope_impl', ...
                          'MC_t','MC_ue','MC_ag'};

    [res_sam, res_nk] = compute_sensitivity(p0, gamQ_loop, par.nuD_sens_loop, exps);

    % Gamma_Q -> -infinity variant (par.subQ_low), kept separate from
    % exps(1)/par.subQ_loop (write_endpoint_table's "last index = default"
    % convention); the grey lines of all three slope figures.
    exps_gray = struct();
    exps_gray(1).name       = 'nuD';
    exps_gray(1).param      = 'subQ';
    exps_gray(1).values     = par.subQ_low;
    exps_gray(1).sam_fields = {'CU_t','CU_ue','PE_t','PE_ue', 'LW_t','LW_ue', 'D_t','D_ue', 'MC_t','MC_ue', ...
                                'AD_t','AD_ue', 'AS_t','AS_ue', 'WG_t','WG_ue'};
    exps_gray(1).nk_fields  = {};
    [res_gray, ~] = compute_sensitivity(p0, gamQ_loop, par.nuD_sens_loop, exps_gray);
    clearvars exps_gray;

    save(cache_file, 'gamQ_cut', 'gamQ_cut_loop', 'gamQ_loop', ...
        'res_sam', 'res_nk', 'res_gray');
    clearvars exps;
end
