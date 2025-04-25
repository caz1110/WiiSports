% D. Kaputa
% baselineCourt.m
% Ravvenlabs

clc;
clear all;
close all;

%Initialization Parameters
server_ip   = '127.0.0.1';     %IP address of the Unity Server
server_port = 55001;           %Server Port of the Unity Sever

client = tcpclient(server_ip,server_port,"Timeout",20);
fprintf(1,"Connected to server\n");

width = 1920;
height = 1080;
image = blenderLink(client,width,height,1,10,1,0,0,0,"tennisBall");
imagesc(image)
set(gcf, 'Position', get(0, 'Screensize'));
axis off
