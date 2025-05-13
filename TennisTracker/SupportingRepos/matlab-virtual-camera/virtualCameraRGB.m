% Chris Zamora
% virtualCameraRGB.m - MATLAB script
% Virtual Camera Feed from Snickerdoodle
% NOTE: Must run matlabStereoServer.py
% first on the FPGA SoC

% Image Resolution
width = 752;
height = 480;


function prepPipeline(client, ballImagePath, baselineImagePath)
    % Image Resolution
    width = 752;
    height = 480;

    write(client, '0');         % Signal start of transmission
    flush(client);              % Ensure the command is sent immediately

    % Right Ball & Baseline
    dataBall = imread(ballImagePath);
    dataBaseline = imread(baselineImagePath);

    dataBall = imresize(dataBall, [height width]);
    dataBaseline = imresize(dataBaseline, [height width]);

    % 8-BIT FORMATTING
    dataBall = uint8(dataBall);
    dataBaseline = uint8(dataBaseline);

    % Grayscale channel calculations
    dataGrayBall = im2gray(dataBall);
    dataGrayBaseline = im2gray(dataBaseline);

    % Prepare 64-bit pixel bus formatting
    imageStack = uint8(ones(height, width, 8));
    imageStack(:, :, 1:3) = dataBall;        % Channels 1–3: RGB of Ball image
    imageStack(:, :, 4) = dataGrayBall;      % Channel 4: Gray Ball
    imageStack(:, :, 5:7) = dataBaseline;    % Channels 5–7: RGB of Baseline
    imageStack(:, :, 8) = dataGrayBaseline;  % Channel 8: Gray Baseline

    % Reorder to [channel, column, row] for the hardware
    imageStack = permute(imageStack,[3 2 1]);
    write(client,imageStack(:));
    temp = read(client,1);
end

function sendImage(client, ballImagePath, baselineImagePath)
% sendImage - Sends a ball image and baseline image over TCP to the server
%
% Inputs:
%   client            - TCP client object (must already be connected)
%   ballImagePath     - Path to the ball image (e.g., 'rightBall.jpg')
%   baselineImagePath - Path to the baseline image (e.g., 'rightBaseline.jpg')

    % Image Resolution
    width = 752;
    height = 480;

    % Read and resize the ball and baseline images
    dataBall = imread(ballImagePath);
    dataBaseline = imread(baselineImagePath);

    dataBall = imresize(dataBall, [height, width]);
    dataBaseline = imresize(dataBaseline, [height, width]);

    % Ensure images are 8-bit
    dataBall = uint8(dataBall);
    dataBaseline = uint8(dataBaseline);

    % Grayscale channel calculations
    dataGrayBall = im2gray(dataBall);
    dataGrayBaseline = im2gray(dataBaseline);

    % Prepare 64-bit pixel bus formatting
    imageStack = uint8(ones(height, width, 8));
    imageStack(:, :, 1:3) = dataBall;        % Channels 1–3: RGB of Ball image
    imageStack(:, :, 4) = dataGrayBall;      % Channel 4: Gray Ball
    imageStack(:, :, 5:7) = dataBaseline;    % Channels 5–7: RGB of Baseline
    imageStack(:, :, 8) = dataGrayBaseline;  % Channel 8: Gray Baseline

    % Reorder to [channel, column, row] for the hardware
    imageStack = permute(imageStack, [3 2 1]);
    
    % Send the image data
    write(client, imageStack(:));
    
    % Wait for acknowledgement (1 byte)
    temp = read(client, 1);

end

function [leftImg, rightImg] = receiveImages(client)
% receiveImages - Receives feedthrough and processed images from the server
%
% Inputs:
%   client  - TCP client object
%
% Outputs:
%   leftImg
%   rightImg

    width = 752;
    height = 480;
    channels = 3;

    % Read and discard the left frame
    frameSize = width * height * channels; % 1,084,800 bytes
    rawLeft = [];
    while length(rawLeft) < frameSize
        rawLeft = [rawLeft; read(client, frameSize - length(rawLeft))];
    end
    temp = reshape(rawLeft, [3, width, height]);
    leftImg = permute(temp, [3 2 1]);

    % Read and discard the right frame
    rawRight = [];
    while length(rawRight) < frameSize
        rawRight = [rawRight; read(client, frameSize - length(rawRight))];
    end
    temp = reshape(rawRight, [3, width, height]);
    rightImg = permute(temp, [3 2 1]);

    fprintf(1, "Processed Image Received \n");
end

function updateSnickerdoodleParam(client)
    % Baseline & Focal Length
    baseLine = 9.3064e+03;
    focalLength = 313.6884;

    write(client, '5');         % Signal start of transmission
    flush(client);              % Ensure the command is sent immediately

    % Create message
    message = sprintf('%.4f,%.4f', baseLine, focalLength);
    message_bytes = uint8(message);    % Convert to bytes

    % Prefix with length
    length_prefix = sprintf('%d:', numel(message_bytes));
    full_message = [uint8(length_prefix), message_bytes];

    % Send
    write(client, full_message);
    fprintf(1, "Values Sent (%d bytes)\n", length(full_message));

    % Wait for acknowledgment
    temp = read(client, 1);
    fprintf(1, "Acknowledgement received: %d\n", temp);
end

function generateDataFile(x, z, y)
    % Open or create the file in append mode
    fid = fopen('snickdata.dat', 'a');
    
    % Check if the file opened successfully
    if fid == -1
        error('Failed to open or create snickdata.dat');
    end

    % Write the data as a new line
    fprintf(fid, '%.6f %.6f %.6f\n', x, z, y);

    % Close the file
    fclose(fid);
end

% Server Initialization Parameters
server_ip   = '10.200.191.13';
server_port = 9999;
client = tcpclient(server_ip, server_port, "Timeout", 30);
fprintf(1, "Connected to server\n");

updateSnickerdoodleParam(client);

imgLFeedthrough = imread('leftBall.jpg');
imgRFeedthrough = imread('rightBall.jpg');
prepPipeline(client, 'leftBall.jpg', 'leftBaseline.jpg')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = tiledlayout(2, 2, 'Padding', 'none', 'TileSpacing', 'compact');
t.TileSpacing = 'compact';
t.Padding = 'compact';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % send ball and baseline frames
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% imageBool = false;
% for j = 1:8
%     write(client, '0');         % Signal start of transmission
%     flush(client);              % Ensure the command is sent immediately
% 
%     if imageBool
%         % Right Ball & Baseline
%         dataBall = imread('rightBall.jpg');
%         dataBaseline = imread('rightBaseline.jpg');
%     else
%         % Left Ball & Baseline
%         dataBall = imread('leftBall.jpg');
%         dataBaseline = imread('leftBaseline.jpg');
%     end
% 
%     dataBall = imresize(dataBall, [height width]);
%     dataBaseline = imresize(dataBaseline, [height width]);
% 
%     % 8-BIT FORMATTING
%     dataBall = uint8(dataBall);
%     dataBaseline = uint8(dataBaseline);
% 
%     % Image labeling for loop itteration identification during debugging
%     dataBall = insertText(dataBall,[100 100],j,FontSize=42);
% 
%     % Grayscale channel calculations
%     dataGrayBall = im2gray(dataBall);
%     dataGrayBaseline = im2gray(dataBaseline);
% 
%     % Prepare 64-bit pixel bus formatting
%     imageStack = uint8(ones(height, width, 8));
%     imageStack(:, :, 1:3) = dataBall;        % Channels 1–3: RGB of Ball image
%     imageStack(:, :, 4) = dataGrayBall;      % Channel 4: Gray Ball
%     imageStack(:, :, 5:7) = dataBaseline;    % Channels 5–7: RGB of Baseline
%     imageStack(:, :, 8) = dataGrayBaseline;  % Channel 8: Gray Baseline
% 
%     % Reorder to [channel, column, row] for the hardware
%     imageStack = permute(imageStack,[3 2 1]);
%     write(client,imageStack(:));
%     temp = read(client,1);
% 
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % receive processed frames from snickerdoodle
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if j < 4
%         % receive feedthrough frame
%         write(client, '1');
%         flush(client);
% 
%     % NOTE: Binarized image stored within red channel
%         if imageBool
%             % Right Image
%             dataRight = read(client, width * height * 3);
%             temp = reshape(dataRight, [3, width, height]);
%             imgRFeedthrough = permute(temp, [3 2 1]);
%             colormap gray;
%             imagesc(imgRFeedthrough);
%         else
%             % Left Image
%             dataLeft = read(client, width * height * 3);
%             temp = reshape(dataLeft, [3, width, height]);
%             imgLFeedthrough = permute(temp, [3 2 1]);
%             colormap gray;
%             imagesc(imgLFeedthrough);
%         end
% 
%         % Clear image buffer
%         dataBlank = read(client, width * height * 3);
%     else
%         % receive processed frame
%         write(client, '2');
%         flush(client);
% 
%         if imageBool
%             % Right Image
%             dataRight = read(client, width * height * 3);
%             temp = reshape(dataRight, [3, width, height]);
%             imgRProcessed = permute(temp, [3 2 1]);
%             colormap gray;
%             imagesc(imgRProcessed(:, :, 1));
%         else
%             % Left Image
%             dataLeft = read(client, width * height * 3);
%             temp = reshape(dataLeft, [3, width, height]);
%             imgLProcessed = permute(temp, [3 2 1]);
%             colormap gray;
%             imagesc(imgLProcessed(:, :, 1));
%         end
%         fprintf(1, "Processed Image Recieved: %d\n", j);
% 
%         % Clear image buffer
%         dataBlank = read(client, width * height * 3);
%         fprintf(1, "Image Buffer Cleared\n");
%     end
% 
%     % Flip between L/R side using bool
%     imageBool = not(imageBool);
% 
%     pause(100 / 1000);
% end

for j = 1:2
    write(client, '6');         % Signal start of transmission
    flush(client);              % Ensure the command is sent immediately

    sendImage(client, 'leftBall.jpg', 'leftBaseline.jpg')
    sendImage(client, 'rightBall.jpg', 'rightBaseline.jpg')

    [leftProcessed, rightProcessed] = receiveImages(client);

    write(client, '4');         % Signal start of transmission
    flush(client);              % Ensure the command is sent immediately

    % Now read one double at a time
    currentTimeRaw = read(client, 8);
    currentTime = typecast(uint8(currentTimeRaw), 'double');

    xRaw = read(client, 8);
    x = typecast(uint8(xRaw), 'double');

    yRaw = read(client, 8);
    y = typecast(uint8(yRaw), 'double');

    zRaw = read(client, 8);
    z = typecast(uint8(zRaw), 'double');

    generateDataFile(x, z, y);
    fprintf(1, "Current Time: %f, X: %f, Y: %f, Z: %f\n", currentTime, x, y, z);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Send 'exit' command to close the server
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write(client, 'e');  % Signal server to close
flush(client);          % Ensure the command is sent immediately
fprintf(1, "Exit command sent to server. Closing connection.\n");
% Close the connection
clear client;

% Display Left Original
nexttile;
imagesc(imgLFeedthrough);
colormap default;
title('Left Original Image');
axis off;

% Display Left Processed
nexttile;
imagesc(leftProcessed(:, :, 1));
colormap gray;
title('Left Processed Scaled Red Channel');
axis off;
imwrite(leftProcessed, "leftProcessed.jpg");

% Display Right Original
nexttile;
imagesc(imgRFeedthrough);
colormap default;
title('Right Original Image');
axis off;

% Display Right Processed
nexttile;
imagesc(rightProcessed(:, :, 1));
colormap gray;
title('Right Processed Scaled Red Channel');
axis off;
imwrite(rightProcessed, "rightProcessed.jpg");