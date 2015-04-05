function set_fig_position(h, top, left, height, width)
% this function simplifies the poisitioning scheme in a more conventional way.
%
% Usage:      SET_FIG_POISITION(h, top, left, height, width);
%
%             H is the handle to the figure.  This can be obtain in the
%               following manner:  H = figure(1);
%             TOP is the "y" screen coordinate for the top of the figure
%             LEFT is the "x" screen coordinate for the left side of the figure
%             HEIGHT is how tall you want the figure
%             WIDTH is how wide you want the figure
%



% PC's active screen size
screen_size = get(0,'ScreenSize');
pc_width  = screen_size(3);
pc_height = screen_size(4);

%Matlab also does not consider the height of the figure's toolbar...
%Or the width of the border... they only care about the contents!
toolbar_height = 77;
window_border  = 5;

% The Format of Matlab is this:
%[left, bottom, width, height]
m_left   = left + window_border;
m_bottom = pc_height - height - top - toolbar_height - 1;
m_height = height;
m_width  = width - 1;

%Set the correct position of the figure
set(h, 'Position', [m_left, m_bottom, m_width, m_height]);

%If you want it to print to file correctly, this must also be set
% and you must use the "-r72" scaling to get the proper format
set(h, 'PaperUnits', 'points');
set(h, 'PaperSize', [width, height]);
set(h, 'PaperPosition', [0, 0, width, height]); %[ left, bottom, width, height]

end