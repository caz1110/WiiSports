function runBaselineCOR(axHandle,Nprint,app)
% runBaselineCOR  Animated textbook COR demo (clay/grass/hard)

if nargin<1||isempty(axHandle)
    axHandle = axes('Parent',figure('Name','Coefficient of Restitution'));
end
if nargin<2||isempty(Nprint), Nprint = 4; end
if nargin<3, app = []; end

cla(axHandle);
hold(axHandle,'on');
grid(axHandle,'on');

g = 9.81;
h0 = 2.54;
e_vals = [0.78 0.72 0.85];         % clay, grass, hard
labels  = {'Clay','Grass','Hard'};
colors  = lines(numel(e_vals));
dt = 0.005;
h_min = 0.01;

title(axHandle,'Tennis Ball Bounce – Baseline Demo');
xlabel(axHandle,'Time (s)');
ylabel(axHandle,'Height (m)');
ylim(axHandle,[0 h0*1.1]);
xlim(axHandle,[0 5]);

hl = gobjects(numel(e_vals),1);
for k=1:numel(e_vals)
    hl(k) = animatedline(axHandle,'Color',colors(k,:), ...
                         'LineWidth',1.5,'DisplayName',labels{k});
end
legend(axHandle,'Location','northeast');

fprintf('\nBaseline COR demo – first %d bounces (meters):\n',Nprint);
fprintf('Surface  Bounce  v_before (m/s)   e\n');

rowsSurf   = strings(numel(e_vals)*Nprint,1);
rowsBounce = zeros(numel(e_vals)*Nprint,1);
rowsVel    = zeros(numel(e_vals)*Nprint,1);
rowsE      = zeros(numel(e_vals)*Nprint,1);
idx = 1;

for k = 1:numel(e_vals)
    for j = 1:Nprint
        h_peak = h0 * e_vals(k)^(2*(j-1));
        v_b    = sqrt(2*g*h_peak);
        fprintf('%-6s    %2d      %6.2f        %.3f\n', ...
                labels{k}, j, v_b, e_vals(k));

        rowsSurf(idx)   = labels{k};
        rowsBounce(idx) = j;
        rowsVel(idx)    = v_b;
        rowsE(idx)      = e_vals(k);
        idx = idx + 1;
    end
end
fprintf('----------------------------------------------------\n');

if ~isempty(app) && isprop(app,'CORTable') && isgraphics(app.CORTable)
    app.CORTable.Data = table(rowsSurf,rowsBounce,rowsVel,rowsE,'VariableNames',{'Surface','Bounce','Velocity_mps','e'});
end

h = h0*ones(numel(e_vals),1);  v = zeros(numel(e_vals),1);
active = true(numel(e_vals),1); t = 0;

while any(active)
    pause(dt); t = t+dt;
    for k=1:numel(e_vals)
        if ~active(k), continue, end
        v(k)=v(k)-g*dt; h(k)=h(k)+v(k)*dt;
        if h(k)<=0
            h(k)=0; v(k)=-e_vals(k)*v(k);
            if (v(k)^2)/(2*g) < h_min, active(k)=false; end
        end
        addpoints(hl(k),t,h(k));
    end
    cx=xlim(axHandle); if t>cx(2)-0.5, xlim(axHandle,[cx(1) t+1]); end
    drawnow limitrate;
end
end
