redActivity   = nnz(leftProcessed(:,:,1));
greenActivity = nnz(leftProcessed(:,:,2));
blueActivity  = nnz(leftProcessed(:,:,3));

fprintf('Left Image:\n  Red: %d\n  Green: %d\n  Blue: %d\n', ...
    redActivity, greenActivity, blueActivity);

redActivity   = nnz(rightProcessed(:,:,1));
greenActivity = nnz(rightProcessed(:,:,2));
blueActivity  = nnz(rightProcessed(:,:,3));

fprintf('Right Image:\n  Red: %d\n  Green: %d\n  Blue: %d\n', ...
    redActivity, greenActivity, blueActivity);

% Display Left Original
nexttile
imagesc(dataBall)
title('Original Image');
axis off

% Display Left Processed
nexttile
imagesc(leftProcessed(:,:,1) * 255);
title('Scaled Red Channel (Visualized)');
axis off

% Display Right Original
nexttile
% Todo: Update to provide other raw image.
% Program only supporting viewing one side,
% other 4 channels are reserved for the base
% line image
imagesc(dataBall)
title('Original Image');
axis off

% Display Right Processed
nexttile
% Note: This is empty due to how the image
% differencing results in only one image
% being sent back at a time, not two
imagesc(rightProcessed(:,:,1) * 255);
title('Scaled Red Channel (Visualized)');
axis off

% Gray color mapping for correct
% binarized display
colormap gray

% activeChannel1 = leftProcessed(:,:,1); % Red channel
% imshow(activeChannel1 * 255);          % Amplify signal for visibility
% title('Scaled Red Channel (Visualized)');