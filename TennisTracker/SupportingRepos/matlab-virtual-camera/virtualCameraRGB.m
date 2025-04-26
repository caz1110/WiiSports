% Chris Zamora
% virtualCameraRGB.m - MATLAB script
% Virtual Camera Feed from Snickerdoodle
% NOTE: Must run matlabStereoServer.py
% first on the FPGA SoC

% Image Resolution
width = 752;
height = 480;

% Server Initialization Parameters
server_ip   = '129.21.136.43';
server_port = 9999;
client = tcpclient(server_ip, server_port, "Timeout", 60);
fprintf(1, "Connected to server\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send ball and baseline frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imageBool = true;
for x = 1:20
    write(client, '0');         % Signal start of transmission
    flush(client);              % Ensure the command is sent immediately

    if imageBool
        % Right Ball & Baseline
        dataBall = imread('rightBall.jpg');
        dataBaseline = imread('rightBaseline.jpg');
    else
        % Left Ball & Baseline
        dataBall = imread('leftBall.jpg');
        dataBaseline = imread('leftBaseline.jpg');
    end

    dataBall = imresize(dataBall, [height width]);
    dataBaseline = imresize(dataBaseline, [height width]);

    % 8-BIT FORMATTING
    dataBall = uint8(dataBall);
    dataBaseline = uint8(dataBaseline);

    % Image labeling for loop itteration identification during debugging
    % dataBall = insertText(dataBall,[100 100],x,FontSize=42);

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
    temp = read(client,1)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % receive processed frames from snickerdoodle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if x < 10
        % receive feedthrough frame
        write(client, '1');
        flush(client);

    % NOTE: Binarized image stored within red channel
        if imageBool
            % Right Image
            dataRight = read(client, width * height * 3);
            temp = reshape(dataRight, [3, width, height]);
            imgRFeedthrough = permute(temp, [3 2 1]);
            colormap gray;
            imagesc(imgRFeedthrough);
        else
            % Left Image
            dataLeft = read(client, width * height * 3);
            temp = reshape(dataLeft, [3, width, height]);
            imgLFeedthrough = permute(temp, [3 2 1]);
            colormap gray;
            imagesc(imgLFeedthrough);
        end

        % Clear image buffer
        dataBlank = read(client, width * height * 3);
    else
        % receive processed frame
        write(client, '2');
        flush(client);

        if imageBool
            % Right Image
            dataRight = read(client, width * height * 3);
            temp = reshape(dataRight, [3, width, height]);
            imgRProcessed = permute(temp, [3 2 1]);
            colormap gray;
            imagesc(imgRProcessed(:, :, 1));
        else
            % Left Image
            dataLeft = read(client, width * height * 3);
            temp = reshape(dataLeft, [3, width, height]);
            imgLProcessed = permute(temp, [3 2 1]);
            colormap gray;
            imagesc(imgLProcessed(:, :, 1));
        end

        % Clear image buffer
        dataBlank = read(client, width * height * 3);
    end

    % Flip between L/R side using bool
    imageBool = not(imageBool);

    pause(100 / 1000);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Send 'exit' command to close the server
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write(client, "exit");  % Signal server to close
flush(client);          % Ensure the command is sent immediately
fprintf(1, "Exit command sent to server. Closing connection.\n");

% Close the connection
clear client;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = tiledlayout(2, 2, 'Padding', 'none', 'TileSpacing', 'compact');
t.TileSpacing = 'compact';
t.Padding = 'compact';

% Display Left Original
nexttile;
imagesc(imgLFeedthrough);
colormap default;
title('Left Original Image');
axis off;

% Display Left Processed
nexttile;
imagesc(imgLProcessed(:, :, 1));
colormap gray;
title('Left Processed Scaled Red Channel');
axis off;
imwrite(imgLProcessed, "leftProcessed.jpg");

% Display Right Original
nexttile;
imagesc(imgRFeedthrough);
colormap default;
title('Right Original Image');
axis off;

% Display Right Processed
nexttile;
imagesc(imgRProcessed(:, :, 1));
colormap gray;
title('Right Processed Scaled Red Channel');
axis off;
imwrite(imgRProcessed, "rightProcessed.jpg");
