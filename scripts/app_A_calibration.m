% app_A_calibration.m -- Appendix A, Table A.1: parameter values implied by the steady-state targets
% -------------------------------------------------------------------------
% PRODUCES
%   results/txt/calibration_dynare.txt   parameters of the full model (Dynare) implied by the
%                                        targets, NK-SaM and benchmark: mu_H, psi_H, mu_D,
%                                        psi_D, mu_N, epsilon, epsilon_W, kappa_P, kappa_W, ...
% The composites of the linearized model (epsilon, kappa_P, phi_Xi, ...) and the
% reduced-form normalizations are in results/txt/calibration_summary.txt
% (main_s3_s4_slopes.m). mu_H, psi_D and mu_D in Table A.1 are the full-model values.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));
dynare_opts.keep_sim = false;

% Benchmark: goods market SaM off, as in lib/compute_default_scenarios.m
nk_cfg = base_cfg;
nk_cfg.parSAM.gamQ = 1e-4;
nk_cfg.parSAM.subQ = ranges.subQ_high;
nk_cfg.target.cuss = 1;
nk_cfg.target.dnss = 1e-4;

r_sam = robust_solve(base_cfg, dynare_opts);
r_nk  = robust_solve(nk_cfg,   dynare_opts);

fid = fopen(nksam_path('txt', 'calibration_dynare.txt'), 'w');
if fid == -1; error('app_A_calibration: cannot write calibration_dynare.txt'); end
fprintf(fid, 'Full-model (Dynare) parameters implied by the targets (app_A_calibration.m, %s)\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, '%-10s %14s %14s\n', 'parameter', 'NK-SaM', 'benchmark');
f = fieldnames(r_sam.par);
for k = 1:numel(f)
    fprintf(fid, '%-10s %14.6g %14.6g\n', f{k}, r_sam.par.(f{k}), r_nk.par.(f{k}));
end
fprintf(fid, '\nSteady state (levels)\n');
f = fieldnames(r_sam.ss);
for k = 1:numel(f)
    fprintf(fid, '%-10s %14.6g %14.6g\n', f{k}, r_sam.ss.(f{k}), r_nk.ss.(f{k}));
end
fclose(fid);
fprintf('wrote %s\n', nksam_path('txt', 'calibration_dynare.txt'));

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
