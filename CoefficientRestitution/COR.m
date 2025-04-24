% bounce_tennis_ball_realtime.m
% Real‑time animation of a tennis ball bouncing on clay, grass, and asphalt.

close all;  clc;

g = 9.81;
h0 = 2.54;
e_vals = [0.78  0.72  0.85];
labels = {'Clay', 'Grass', 'Hard'};
colors = lines(numel(e_vals));
h_min = 0.01;
dt = 0.005;
metersToInches = 39.3701;

figure('Name','Coefficient of Restitution');
hold on; grid on;
xlabel('Time (s)');  ylabel('Height (in)');
title('Tennis Ball Bounce on Different Court Surfaces');
ylim([0 h0*metersToInches*1.1]); xlim([0 5]);

hLines = gobjects(numel(e_vals),1);
for k = 1:numel(e_vals)
    hLines(k) = animatedline('Color', colors(k,:), 'LineWidth', 1.5, 'DisplayName', labels{k});
end
legend('Location','northeast');

h = h0 * ones(numel(e_vals),1);
v = zeros(numel(e_vals),1);
active = true(numel(e_vals),1);
t = 0;

while any(active)
    pause(dt);
    t = t + dt;
    
    for k = 1:numel(e_vals)
        if ~active(k); continue; end

        v(k) = v(k) - g*dt;
        h(k) = h(k) + v(k)*dt;
        
        if h(k) <= 0
            h(k) = 0;
            v(k) = -e_vals(k) * v(k);
            
            if (v(k)^2) / (2*g) < h_min
                active(k) = false;
            end
        end

        addpoints(hLines(k), t, h(k)*metersToInches);
    end
    
    curr_xlim = xlim(gca);
    if t > curr_xlim(2) - 0.5
        xlim([curr_xlim(1), t + 1]);
    end

    drawnow limitrate;
end