% Dr. Kaputa
% Virtual Camera Demo
% must run matlabStereoServer.py first on the FPGA SoC

% set this to what your resolution is
width = 752;
height = 480;

%Initialization Parameters
server_ip   = '10.200.191.8';     % IP address of the server
server_port = 9999;                % Server Port of the sever

client = tcpclient(server_ip,server_port,"Timeout",30);
fprintf(1,"Connected to server\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send raw frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
for x = 1:20
write(client,'0');         % Signal start of transmission
flush(client);             % Ensure the command is sent immediately

% Load and resize images
dataBall = imread('rightBall.jpg');
dataBaseline = imread('rightBaseline.jpg');
dataBall = imresize(dataBall,[height width]);
dataBaseline = imresize(dataBaseline,[height width]);

% Ensure 8-bit format
dataBall = uint8(dataBall);
dataBaseline = uint8(dataBaseline);

% Optional image labeling
dataBall = insertText(dataBall,[100 100],x,FontSize=42);
% dataBaseline can be left unmarked to avoid visual contamination

% Convert to grayscale
dataGrayBall = im2gray(dataBall);
dataGrayBaseline = im2gray(dataBaseline);

% Prepare an 8-channel image stack
imageStack = uint8(ones(height,width,8));
imageStack(:,:,1:3) = dataBall;            % Channels 1–3: RGB of Ball image
imageStack(:,:,4) = dataGrayBall;          % Channel 4: Gray Ball
imageStack(:,:,5:7) = dataBaseline;        % Channels 5–7: RGB of Baseline
imageStack(:,:,8) = dataGrayBaseline;      % Channel 8: Gray Baseline

imageStack(1,1,:) = 0;                     % Clear first pixel — often a sync flag or header
imageStack = permute(imageStack,[3 2 1]);  % Reorder to [channel, column, row] for the hardware

% Transmit data
write(client,imageStack(:));               % Flatten and send over communication channel
temp = read(client,1);                     % Await response (ack, result, etc.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% receive processed frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
if x < 10
    % receive feedthrough frame
    write(client,'1');
    flush(client);
else
    % receive processed frame
    write(client,'2');
    flush(client); 
end
dataLeft = read(client,width*height*3);   
temp = reshape(dataLeft,[3,width,height]);
leftProcessed = permute(temp,[3 2 1]);

dataRight = read(client,width*height*3);
temp = reshape(dataRight,[3,width,height]);
rightProcessed = permute(temp,[3 2 1]);
imagesc(leftProcessed);
pause(1)
end
t = tiledlayout(1,2, 'Padding', 'none', 'TileSpacing', 'compact'); 
t.TileSpacing = 'compact';
t.Padding = 'compact';
 
nexttile    
imagesc(dataBall)
axis off
nexttile
imagesc(leftProcessed);
colormap gray
axis off