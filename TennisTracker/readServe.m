% Argenis
% readServe.m
clear all

serve = readmatrix("\data\serve1.dat");

dataSize = size(serve)
numFrames = dataSize(1)

sampledServeCounter = 1;
frameTimeMs = 50;
for counter = 1:frameTimeMs:numFrames
    x = serve(counter,1);
    y = serve(counter,3);
    z = serve(counter,2);
    sampledServe(1,sampledServeCounter) = x;
    sampledServe(2,sampledServeCounter) = y;
    sampledServe(3,sampledServeCounter) = z;
    sampledServeCounter = sampledServeCounter + 1;
end
scatter3(sampledServe(1,:),sampledServe(2,:),sampledServe(3,:))

%-------------------------------------------------------------------------

clear all

serve1 = readmatrix("\data\serve2.dat");

dataSize = size(serve1);
numFrames = dataSize(1);

sampledServeCounter = 1;
frameTimeMs = 50;
for counter = 1:frameTimeMs:numFrames
    x = serve1(counter,1);
    y = serve1(counter,3);
    z = serve1(counter,2);
    sampledServe(1,sampledServeCounter) = x;
    sampledServe(2,sampledServeCounter) = y;
    sampledServe(3,sampledServeCounter) = z;
    sampledServeCounter = sampledServeCounter + 1;
end
figure;
scatter3(sampledServe(1,:),sampledServe(2,:),sampledServe(3,:))

%-------------------------------------------------------------------------

clear all

serve3 = readmatrix("\data\serve3.dat");

dataSize = size(serve3);
numFrames = dataSize(1);

sampledServeCounter = 1;
frameTimeMs = 50;
for counter = 1:frameTimeMs:numFrames
    x = serve3(counter,1);
    y = serve3(counter,3);
    z = serve3(counter,2);
    sampledServe(1,sampledServeCounter) = x;
    sampledServe(2,sampledServeCounter) = y;
    sampledServe(3,sampledServeCounter) = z;
    sampledServeCounter = sampledServeCounter + 1;
end
figure;
scatter3(sampledServe(1,:),sampledServe(2,:),sampledServe(3,:))