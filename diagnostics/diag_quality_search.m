% diag_quality_search.m -- diagnostic (not in the paper): range of gamma_P for check 2
% -------------------------------------------------------------------------
% Where does the quality-search steady state stop existing? Sweeps gamma_P
% on the NK-SaM baseline and prints, for each value, whether the model
% solves and the steady-state split of shopping time into quantity (dq) and
% quality (dp) search. Used to set ranges.gamP_high in get_params.m.
% Output: console + results/txt/diag_quality_search.txt.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));
dynare_opts.keep_sim = false;

gamP_grid = [0.05 0.10 0.12 0.14 0.16 0.18 0.20 0.25];
out_file  = nksam_path('txt', 'diag_quality_search.txt');
fid = fopen(out_file, 'w');
fprintf(fid, 'gamma_P sweep, NK-SaM baseline (%s)\n', datestr(now));
fprintf(fid, '%8s %8s %10s %10s %10s %10s %s\n', 'gamP', 'solved', 'd', 'dq/d', 'dp/d', 'Y0(eM)', 'message');
for gP = gamP_grid
    cfg = base_cfg;
    cfg.parHW.gamP = gP;
    try
        r  = robust_solve(cfg, dynare_opts);
        d  = r.ss.d; dq = r.ss.dq; dp = r.ss.dp;
        line = sprintf('%8.3f %8s %10.4g %10.4f %10.4f %10.4f', gP, 'yes', d, dq/d, dp/d, r.irfs.eM.gdp_obs(1));
    catch ME
        line = sprintf('%8.3f %8s %10s %10s %10s %10s %s', gP, 'NO', '', '', '', '', ME.message);
    end
    fprintf('%s\n', line);
    fprintf(fid, '%s\n', line);
end
fclose(fid);
fprintf('wrote %s\n', out_file);


% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
