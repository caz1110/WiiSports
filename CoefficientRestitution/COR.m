% COR.m
% Plot a tennis ball’s bounce on clay, grass, and asphalt courts.

close all; clc;

g = 9.81;
h0 = 1.0;
e_vals = [0.78  0.72  0.85];
labels = {'Clay','Grass','Asphalt'};
colors = lines(numel(e_vals));
h_min = 0.01;
Npts = 60;

figure; hold on; grid on;
for k = 1:numel(e_vals)
    e = e_vals(k);
    h = h0;
    t_global = 0;
    T = [];  H = [];
    
    while h > h_min
        tf = sqrt(2*h/g);
        t  = linspace(0, tf, Npts);
        y  = h - 0.5*g*t.^2;
        T  = [T, t_global + t];
        H  = [H, y];
        
        v_impact = sqrt(2*g*h);
        v_up = e * v_impact;
        h_next = v_up^2 / (2*g);
        tr = v_up / g;
        t  = linspace(0, tr, Npts);
        y  = v_up*t - 0.5*g*t.^2;
        T  = [T, t_global + tf + t];
        H  = [H, y];
        
        t_global = t_global + tf + tr;
        h = h_next;
    end
    
    plot(T, H, 'LineWidth', 1.5, 'Color', colors(k,:), 'DisplayName', labels{k});
end

xlabel('Time  (s)');
ylabel('Height  (m)');
title('Tennis Ball Bounce on Different Court Surfaces');
legend('Location','northeast');
xlim([0, inf]);
ylim([0, h0*1.05]);