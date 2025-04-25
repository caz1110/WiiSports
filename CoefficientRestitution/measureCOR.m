function e_mean = measureCOR(app, objectName, varargin)
% measureCOR  Compute coefficient-of-restitution (COR) from Blender
%
%   e_mean = measureCOR(app,"Ball",'Axes',app.CORAxes,'PrintN',4)
%
%   All heights are handled/displayed in **meters** by default.

% ── Options ────────────────────────────────────────────────────────────
p = inputParser;
addRequired (p,'app');
addRequired (p,'objectName',@(s)ischar(s)||isstring(s));
addParameter(p,'Host',     "127.0.0.1");
addParameter(p,'Port',     55001,@(x)isscalar(x)&&x>0);
addParameter(p,'SimTime',  10,@(x)x>0);
addParameter(p,'NBounces', 4,@(x)x>=1);
addParameter(p,'Units',    "m",@(s)any(strcmpi(s,["m","in"])));
addParameter(p,'Plot',     true);
addParameter(p,'Axes',     [],@(h)isempty(h)||isgraphics(h,'axes'));
addParameter(p,'PrintN',   4,@(x)x>=1);
parse(p,app,objectName,varargin{:});
o = p.Results;

toInches = strcmpi(o.Units,"in");
Nprint = o.PrintN;

try
    cli = tcpclient(o.Host,o.Port,"Timeout",20);
catch ME
    uiwarn(app,"Could not connect:\n%s",ME.message); e_mean = NaN; return
end
write(cli,uint8("STREAM_Z:"+string(o.objectName)));

buf = []; tic
while toc < o.SimTime
    n = cli.NumBytesAvailable;
    if n>=8, buf=[buf; read(cli,n,"single")];
    else, pause(0.01); end
end
clear cli
if isempty(buf), uiwarn(app,"No data."); e_mean=NaN; return, end

t = buf(1:2:end);
z = buf(2:2:end);
if toInches, z = z*39.3701; end

[pks,locs] = findpeaks(z,'MinPeakProminence',max(0.02*range(z),0.01), 'MinPeakDistance',0.2*mean(diff(t)));
pks  = pks(1:min(end,o.NBounces+1));
locs = locs(1:end);
e = sqrt(pks(2:end)./pks(1:end-1));
e_mean = mean(e);

g = 9.81;
h_before = pks(1:end-1);
if toInches, h_before = h_before/39.3701; end
v_before = sqrt(2*g*h_before);

fprintf('\nImpact velocities & COR (first %d bounces):\n',min(Nprint,numel(e)));
for i=1:min(Nprint,numel(e))
    fprintf('  Bounce %d | v = %5.2f m/s | e = %.3f\n',i,v_before(i),e(i));
end
fprintf('------------------------------------------------\n');

if ~isempty(app) && isprop(app,'CORTable') && isgraphics(app.CORTable)
    rows = min(Nprint,numel(e));
    T    = table((1:rows).',v_before(1:rows).',e(1:rows).','VariableNames',{'Bounce','Velocity_mps','e'});
    app.CORTable.Data = T;
end
if ~isempty(app) && isprop(app,'lblResult')
    app.lblResult.Text = sprintf('COR = %.3f',e_mean);
end

if o.Plot
    ax = o.Axes;
    if isempty(ax)||~isgraphics(ax,'axes')
        ax = axes('Parent',figure('Name','COR measurement'));
    end
    cla(ax); hold(ax,'on');
    plot(ax,t,z,'k','LineWidth',1);
    plot(ax,t(locs),pks,'ro','MarkerFaceColor','r');
    xlabel(ax,'Time (s)');
    ylabel(ax,sprintf('Height (%s)',o.Units));
    title(ax,sprintf('Bounce profile – mean e = %.3f',e_mean));
    grid(ax,'on'); hold(ax,'off');
end
end
