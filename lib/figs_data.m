function figs_data(gaps, dat, lwdth)
% DATA_FIGS  Plot gap data figures.
%
%   Inputs
%     gaps  - struct from compute_data_gaps()
%     dat   - struct from load_nksam_data()
%     lwdth - line width for all graphs

s = gaps.s_start;

cBlue1  = [0.3010 0.7450 0.9330];
cBlue2  = [0      0.4470 0.7410];
cOrange = [0.8500 0.3250 0.0980];
cYellow = [0.9290 0.6940 0.1250];

%% Output Gap Decomposition
figure('Name','Output Gap Decomposition')
area(dat.observation_date(s:end), ...
    [gaps.gdp_gap_ue_share(s:end) gaps.gdp_gap_cap_share(s:end)])
axis tight;
xlabel('Time', 'Interpreter', 'latex'); ylabel('\%-Deviations', 'Interpreter', 'latex');
title('Output Gap Decomposition ($\Gamma_Q = 0$ calibration)', 'Interpreter', 'latex');
legend('Unemployment Gap','Utilization Gap', ...
    'Location','southoutside','Orientation','horizontal', 'Interpreter','latex');
save_fig(nksam_path('figures', 'gap_decomp_data.eps'), 21, 10)

%% Capacity Utilization, Price Elasticity, Labor Wedge & Search Effort Gaps
% 1 column x 4 rows so the figure (plus a note added later) fits on one
% DIN A4 page (21.0 x 29.7 cm) when printed. Width is close to the A4 page
% width (with room for standard margins) so each wide, short time-series
% panel stays legible; height leaves clear space below for the note.
figure('Name','CU, PE, LW & Search Effort Gaps in US Data')
tiledlayout(4,1);

nexttile; hold on;
area(dat.observation_date(s:end), dat.gdp_gap(s:end),  'FaceColor', cBlue1, 'LineStyle','none')
area(dat.observation_date(s:end), dat.ue_gap(s:end),   'FaceColor', cBlue2, 'LineStyle','none')
plot(dat.observation_date(s:end), dat.caput_alt(s:end), 'g-', 'LineWidth', lwdth)
yline(0)
plot(dat.observation_date(s:end), gaps.cu_gap_1(s:end), 'Color', cOrange, 'LineWidth', lwdth)
plot(dat.observation_date(s:end), gaps.cu_gap_2(s:end), 'Color', cYellow, 'LineWidth', lwdth)
hold off; axis tight;
xlabel('Time', 'Interpreter', 'latex'); ylabel('\%-Deviations', 'Interpreter', 'latex'); title('Capacity Utilization Gap', 'Interpreter', 'latex');

nexttile; hold on;
area(dat.observation_date(s:end), dat.gdp_gap(s:end),   'FaceColor', cBlue1, 'LineStyle','none')
area(dat.observation_date(s:end), dat.ue_gap(s:end),    'FaceColor', cBlue2, 'LineStyle','none')
plot(dat.observation_date(s:end), dat.cpi_infl(s:end),  'g-', 'LineWidth', lwdth)
plot(dat.observation_date(s:end), gaps.pe_gap_1(s:end), 'Color', cOrange, 'LineWidth', lwdth)
plot(dat.observation_date(s:end), gaps.pe_gap_2(s:end), 'Color', cYellow, 'LineWidth', lwdth)
hold off; axis tight;
xlabel('Time', 'Interpreter', 'latex'); ylabel('\%-Deviations', 'Interpreter', 'latex'); title('Price Elasticity of Demand Gap', 'Interpreter', 'latex');

nexttile; hold on;
h1 = area(dat.observation_date(s:end), dat.gdp_gap(s:end),    'FaceColor', cBlue1, 'LineStyle','none');
h2 = area(dat.observation_date(s:end), dat.ue_gap(s:end),     'FaceColor', cBlue2, 'LineStyle','none');
h3 = plot(dat.observation_date(s:end), dat.lw_cpu(s:end)',    'g-',  'LineWidth', lwdth);
h4 = plot(dat.observation_date(s:end), gaps.lw_gap_nk(s:end), 'k-.', 'LineWidth', lwdth);
h5 = plot(dat.observation_date(s:end), gaps.lw_gap_1(s:end),  'Color', cOrange, 'LineWidth', lwdth);
h6 = plot(dat.observation_date(s:end), gaps.lw_gap_2(s:end),  'Color', cYellow, 'LineWidth', lwdth);
hold off; axis tight;
xlabel('Time', 'Interpreter', 'latex'); ylabel('\%-Deviations', 'Interpreter', 'latex'); title('Labor Wedge Gap', 'Interpreter', 'latex');

nexttile; hold on;
area(dat.observation_date(s:end), dat.gdp_gap(s:end), 'FaceColor', cBlue1, 'LineStyle','none')
area(dat.observation_date(s:end), dat.ue_gap(s:end),  'FaceColor', cBlue2, 'LineStyle','none')
yline(0)
plot(dat.observation_date(s:end), gaps.d_gap_1(s:end), 'Color', cOrange, 'LineWidth', lwdth)
plot(dat.observation_date(s:end), gaps.d_gap_2(s:end), 'Color', cYellow, 'LineWidth', lwdth)
hold off; axis tight;
xlabel('Time', 'Interpreter', 'latex'); ylabel('\%-Deviations', 'Interpreter', 'latex'); title('Total Search Effort Gap', 'Interpreter', 'latex');

% Shared legend built from the Labor Wedge panel's handles — the only panel
% with all 6 plotted categories (CU/PE/D have no NK-model line since CU, PE,
% and total search effort have no counterpart in the pure NK benchmark).
leg = legend([h1 h2 h3 h4 h5 h6], ...
    {'Output Gap','Unemployment Gap','Data','NK Model', ...
     'SaM Model $\Gamma_Q=0$','SaM Model $\Gamma_Q=-2.7$'}, ...
    'Orientation','horizontal','NumColumns',3,'Interpreter','latex');
leg.Layout.Tile = 'south';
save_fig(nksam_path('figures', 'cu_pe_lw_se_gap_data.eps'), 17, 22)

end
