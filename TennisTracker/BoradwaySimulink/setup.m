% Dr. Kaputa
% Sobel Demo Setup File
R = 752; 
C = 480;

%Image Proc Testing

%rightBall = imread("rightBall.jpg");
%rightBaseline = imread("rightBaseline.jpg");

%rightBall = im2gray(rightBall);
%rightBaseline = im2gray(rightBaseline);

% Current findings:
% image differencing MUST be done BEFORE the gray scale
% operation. It results in a loss of data otherwise. The
% grayscale channel must then be recalculated. This unfortunately
% means two channels are completely wasted.

%difference = imabsdiff(rightBall, rightBaseline);


%imshow(difference)
%imshow(gray)