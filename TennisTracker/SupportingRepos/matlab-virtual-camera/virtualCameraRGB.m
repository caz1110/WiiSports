% Chris Zamora
% virtualCameraRGB.m - MATLAB script
% Virtual Camera Feed from Snickerdoodle
% NOTE: Must run matlabStereoServer.py
% first on the FPGA SoC

% Image Resoultuon
width = 752;
height = 480;

% Server Initialization Parameters
server_ip   = '192.168.1.156';
server_port = 9999;
client = tcpclient(server_ip,server_port,"Timeout",30);
fprintf(1,"Connected to server\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send ball and baseline frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
imageBool = true;
for x = 1:20
write(client,'0');         % Signal start of transmission
flush(client);             % Ensure the command is sent immediately

% LOAD IMAGES & RESIZE
if imageBool
    % Right Ball & Baseline
    dataBall = imread('rightBall.jpg');
    dataBaseline = imread('rightBaseline.jpg');
else
    % Left Ball & Baseline
    dataBall = imread('leftBall.jpg');
    dataBaseline = imread('leftBaseline.jpg');
end
dataBall = imresize(dataBall,[height width]);
dataBaseline = imresize(dataBaseline,[height width]);

% 8-BIT FORMATTING
dataBall = uint8(dataBall);
dataBaseline = uint8(dataBaseline);

% Image labeling for loop itteration identification
%   NOTE: dataBaseline can be left unmarked
%   to avoid visual contamination during differencing
dataBall = insertText(dataBall,[100 100],x,FontSize=42);

% Grayscale channel calculations
dataGrayBall = im2gray(dataBall);
dataGrayBaseline = im2gray(dataBaseline);

% Prepare 64-bit pixel bus formatting
%   NOTE:
%   Bits 31-0:  Captured Frame
%   Bits 63-32: Baseline Frame
imageStack = uint8(ones(height,width,8));
imageStack(:,:,1:3) = dataBall;            % Channels 1–3: RGB of Ball image
imageStack(:,:,4) = dataGrayBall;          % Channel 4: Gray Ball
imageStack(:,:,5:7) = dataBaseline;        % Channels 5–7: RGB of Baseline
imageStack(:,:,8) = dataGrayBaseline;      % Channel 8: Gray Baseline

imageStack(1,1,:) = 0;                     % Clear first pixel — often a sync flag or header
imageStack = permute(imageStack,[3 2 1]);  % Reorder to [channel, column, row] for the hardware

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% receive processed frames from snickerdoodle
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

% LOAD IMAGES FROM SNICKERDOODLE
%   NOTE: Binarized image stored within red channel
if imageBool
    % Right Image
    dataRight = read(client,width*height*3);   
    temp = reshape(dataRight,[3,width,height]);
    imgRProcessed = permute(temp,[3 2 1]);
else
    % left Image
    dataLeft = read(client,width*height*3);   
    temp = reshape(dataLeft,[3,width,height]);
    imgLProcessed = permute(temp,[3 2 1]);
end

% Under image differencing, second set
% of RGB channels are empty. Reading is
% peformed in order to clear image buffer
dataBlank = read(client,width*height*3);
temp = reshape(dataBlank,[3,width,height]);
imgEmptyProcessed = permute(temp,[3 2 1]);

% Display image recieved from snickerdoodle
if imageBool
    % Right Ball
    imagesc(imgRProcessed(:,:,1));
else
    % left Ball
    imagesc(imgLProcessed(:,:,1));
end

% Flip between L/R side using bool
imageBool = not(imageBool);

pause(1)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = tiledlayout(1,2, 'Padding', 'none', 'TileSpacing', 'compact'); 
t.TileSpacing = 'compact';
t.Padding = 'compact';

% Display Left Original
nexttile
imagesc(dataLeft)
title('Original Image');
axis off

% Display Left Processed
nexttile
imagesc(imgLProcessed(:,:,1));
title('Scaled Red Channel (Visualized)');
axis off

% Display Right Original
nexttile
imagesc(dataRight)
title('Original Image');
axis off

% Display Right Processed
nexttile
imagesc(imgRProcessed(:,:,1));
title('Scaled Red Channel (Visualized)');
axis off

% Gray color mapping for correct
% binarized display
colormap gray