% COR Logic Supporting Function
% Author: Jonathan Sumner

classdef COR
    methods (Static)
    
        % ===============================================================
        % measureCOR.m   —  Single-surface COR measurement & visualisation
        % ---------------------------------------------------------------
        % • Plots the bounce trajectory in app.CORAxes (if provided) or
        %   a standalone figure.
        % • Streams the pose to Blender via blenderLink.m (if socket open).
        % • Fills app.CORTable with 3 columns:  bounce # | velocity | E
        % • Returns a results struct for scripts or tests.
        % ---------------------------------------------------------------
        % USAGE EXAMPLE (inside an App Designer callback)
        %   surface = app.SurfaceDropDown.Value;   % "clay","grass","hard"
        %   measureCOR(surface, app);              % updates GUI automatically
        % ===============================================================
        function results = measureCOR(surface, app, Nprint, ...
              blenderPort, blenderIP)
        
        % ----------------------------- OPTIONS -------------------------
        if nargin < 2, app         = [];           end
        if nargin < 3, Nprint      = 4;            end
        if nargin < 4, blenderPort = 5000;         end
        if nargin < 5, blenderIP   = "127.0.0.1";  end
        
        g = 9.81;      % gravity [m/s²]
        h0 = 2.54;      % release height [m]
        dt = 0.005;     % integration step [s]
        hMinStop  = 0.01;      % stop when rebound < 1 cm
        
        courtDict = struct('clay',0.78,'grass',0.72,'hard',0.85);
        surface = lower(string(surface));
        
        assert(isfield(courtDict,surface), "Surface must be 'clay', 'grass', or 'hard'.");
        eNominal = courtDict.(surface);
        
        % --------------------------- AXES SETUP ------------------------
        if ~isempty(app) && isprop(app,'CORAxes') && isgraphics(app.CORAxes)
        ax = app.CORAxes;
        cla(ax); hold(ax,'on'); grid(ax,'on');
        else
        fig = figure('Name','Coefficient of Restitution');
        ax  = axes(fig); hold(ax,'on'); grid(ax,'on');
        end
        
        title(ax,"COR – "+upper(surface));
        xlabel(ax,'Time [s]'); ylabel(ax,'Height [m]');
        ylim(ax,[0 h0*1.1]); xlim(ax,[0 5]);
        
        hLine = animatedline(ax,'LineWidth',1.8,'DisplayName',surface);
        
        % ----------------------- BLENDER SOCKET ------------------------
        try
        bClient = tcpclient(blenderIP,blenderPort);
        catch
        bClient = [];
        end
        frameW = 640; frameH = 480;
        
        % ---------------------- MAIN SIMULATION ------------------------
        h = h0; v = 0; t = 0; bounce = 0;
        data = [];  % rows: [bounce, v_before, h_apex]
        
        while true
        pause(dt);                % keeps UI responsive
        v = v - g*dt;
        h = h + v*dt;
        t = t + dt;
        
        % Send pose to Blender every frame (if connected)
        if ~isempty(bClient) && isvalid(bClient)
        blenderLink(bClient,frameW,frameH, 0,0,h,0,0,0,"tennisBall");
        end
        addpoints(hLine,t,h);
        
        % Impact with court?
        if h <= 0
        bounce = bounce + 1;
        v_pre  = v;            % velocity just before impact
        v = -eNominal*v;  % rebound velocity
        h_apex = (v^2)/(2*g);  % next peak height
        data(end+1,:) = [bounce, abs(v_pre), h_apex];
        
        % Optional console printout
        if bounce <= Nprint
        fprintf('Bounce %2d | v_before = %6.3f m/s | h_next = %.3f m\n', bounce, abs(v_pre), h_apex);
        end
        
        if h_apex < hMinStop
        break            % stop when rebound is negligible
        end
        h = 0;               % reset to ground
        end
        end
        
        % -------------- Compute measured e for each rebound -------------
        if size(data,1) >= 2
        eMeasured = sqrt(data(2:end,3) ./ data(1:end-1,3));
        else
        eMeasured = [];
        end
        eAvg = mean(eMeasured);
        
        fprintf('----------------------------------------------\n');
        fprintf('Average measured e = %.4f\n', eAvg);
        
        % -------------- Push results into GUI table (3 cols) ------------
        BounceCol   = data(1:end-1,1);
        VelocityCol = data(1:end-1,2);
        Ecol        = eMeasured;
        
        if ~isempty(app) && isprop(app,'CORTable') && isgraphics(app.CORTable)
        app.CORTable.Data       = [BounceCol, VelocityCol, Ecol];
        app.CORTable.ColumnName = {'Bounce #','Velocity','E'};
        else
        disp(table(BounceCol,VelocityCol,Ecol, ...
        'VariableNames',{'Bounce #','Velocity','E'}));
        end
        
        % -------------- Return struct for scripts/tests -----------------
        results = struct('surface',surface,'nominal_e',eNominal, ...
        'bounces',data,'e_measured',eMeasured, ...
        'e_average',eAvg);
        end  % ========================= END OF measureCOR ===============
        
        
        % ===============================================================
        % runBaselineCOR.m   —  Baseline COR demo animation & table update
        % ---------------------------------------------------------------
        % • Simulates textbook bounces for clay, grass, and hard surfaces.
        % • Plots animated bounce trajectories in app.CORAxes (or a new figure).
        % • Calculates and prints initial velocities and COR values per bounce.
        % • Fills app.CORTable with: surface | bounce # | velocity | E
        % • Returns no output — purely for visualization and GUI update.
        % ---------------------------------------------------------------
        % USAGE EXAMPLE (inside an App Designer callback)
        %   runBaselineCOR(app.CORAxes, 5, app);    % plots & updates GUI
        % ===============================================================
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
        app.CORTable.Data = table(rowsSurf,rowsBounce,rowsVel,rowsE, ...
        'VariableNames',{'surface','bounce #','velocity','E'});   % <-- keeps headers in data
        app.CORTable.ColumnName = {'surface','bounce #','velocity','E'}; % <-- NEW
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
        end % ========================= END OF runBaselineCOR ===============
    end
end