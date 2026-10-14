function save_fig(fname, w, h)
% SAVE_FIG  Export current figure as vector EPS at journal size.
%   save_fig(fname, w, h)  saves gcf to fname (EPS) at w x h centimetres,
%   7pt font, vector content type.
set(gcf, 'Units', 'centimeters', 'Position', [0 0 w h], ...
         'PaperUnits', 'centimeters', 'PaperSize', [w h], ...
         'PaperPositionMode', 'manual', 'PaperPosition', [0 0 w h]);
fontsize(gcf, 7, 'points');
ensure_dir(fname);
exportgraphics(gcf, fname, 'ContentType', 'vector');
end
