function [rgbOut, center] = detectContors(rgbImage)
    % Extract red channel as binary mask
    redChannel = rgbImage(:, :, 1);  % MATLAB uses RGB order
    mask = redChannel == 255;        % Assume binary mask is encoded as 255
    
    % Apply morphological operations
    se = strel('square', 3);
    mask = imerode(mask, se);
    mask = imdilate(mask, se);

    % Find contours (boundaries)
    boundaries = bwboundaries(mask, 'noholes');

    % Initialize output and center
    rgbOut = rgbImage;
    center = [];

    if ~isempty(boundaries)
        % Find largest contour by number of pixels
        maxIdx = 1;
        maxLength = length(boundaries{1});
        for k = 2:length(boundaries)
            if length(boundaries{k}) > maxLength
                maxLength = length(boundaries{k});
                maxIdx = k;
            end
        end

        % Get the largest contour
        contour = boundaries{maxIdx};

        % Fit circle (approximate by centroid and radius)
        stats = regionprops(mask, 'Centroid', 'EquivDiameter');
        center = round(stats(maxIdx).Centroid);
        radius = round(stats(maxIdx).EquivDiameter / 2);

        % Draw red circle outline on the RGB image
        rgbOut = insertShape(rgbOut, 'Circle', [center radius], ...
            'Color', 'red', 'LineWidth', 2);
    end
end


redActivity   = nnz(imgLProcessed(:,:,1));
greenActivity = nnz(imgLProcessed(:,:,2));
blueActivity  = nnz(imgLProcessed(:,:,3));

fprintf('Left Image:\n  Red: %d\n  Green: %d\n  Blue: %d\n', ...
    redActivity, greenActivity, blueActivity);

redActivity   = nnz(imgRProcessed(:,:,1));
greenActivity = nnz(imgRProcessed(:,:,2));
blueActivity  = nnz(imgRProcessed(:,:,3));

fprintf('Right Image:\n  Red: %d\n  Green: %d\n  Blue: %d\n', ...
    redActivity, greenActivity, blueActivity);

% Display Left Original
nexttile
imagesc(dataLeft)
title('Original Image');
axis off

% Display Left Processed
nexttile
imagesc(imgLProcessed(:,:,1) * 255);
title('Scaled Red Channel (Visualized)');
axis off

% Display Right Original
nexttile
% Todo: Update to provide other raw image.
% Program only supporting viewing one side,
% other 4 channels are reserved for the base
% line image
imagesc(dataRight)
title('Original Image');
axis off

leftBalls = detectContors(imgLProcessed);

% Display Right Processed
nexttile
% Note: This is empty due to how the image
% differencing results in only one image
% being sent back at a time, not two
imagesc(leftBalls(:,:,1) * 255);
title('Balls');
axis off

% Gray color mapping for correct
% binarized display
colormap gray

% activeChannel1 = leftProcessed(:,:,1); % Red channel
% imshow(activeChannel1 * 255);          % Amplify signal for visibility
% title('Scaled Red Channel (Visualized)');