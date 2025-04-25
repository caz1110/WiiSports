% VolleyBall.m
% Ravvenlabs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% WORKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear all;
close all;

%Initialization Parameters
server_ip   = '127.0.0.1';     %IP address of the Unity Server
server_port = 55001;           %Server Port of the Unity Sever

client = tcpclient(server_ip,server_port,"Timeout",20);
fprintf(1,"Connected to server\n");

width = 752;
height = 480;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   volley1

volley = readmatrix("\data\Volley1.dat");

dataSize = size(volley);
numFrames = dataSize(1);

sampledServeCounter = 1;
frameTimeMs = 100;

%creates images of each cam in each frame
volleyfilesleft =  ["v1m1.fig";"v1m2.fig";"v1m3.fig";"v1m4.fig";"v1m5.fig";"v1m6.fig";"v1m7.fig";"v1m8.fig";"v1m9.fig";"v1m10.fig";"v1m11.fig";"v1m12.fig";"v1m13.fig";"v1m14.fig";"v1m15.fig";"v1m16.fig";"v1m17.fig";"v1m18.fig";"v1m19.fig";"v1m20.fig";];
volleyfilesright = ["v1m1_.fig";"v1m2_.fig";"v1m3_.fig";"v1m4_.fig";"v1m5_.fig";"v1m6_.fig";"v1m7_.fig";"v1m8_.fig";"v1m9_.fig";"v1m10_.fig";"v1m11_.fig";"v1m12_.fig";"v1m13_.fig";"v1m14_.fig";"v1m15_.fig";"v1m16_.fig";"v1m17_.fig";"v1m18_.fig";"v1m19_.fig";"v1m20_.fig";];
replay = [1,size(volleyfilesright)]; %
i = 1; % used to get pic of left cams
ii = 1;% used to get pic of right cams
k = 1; % used to get counter value for replay
for counter = 1:frameTimeMs:numFrames
    x = volley(counter,1);
    y = volley(counter,3);
    z = volley(counter,2);
    x1 =11;
    y1 =-5;
    z1 =8.2;

    image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
    imagesc(image)
    image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
    imagesc(image3)
    if i <=20
        savefig(volleyfilesleft(i,1))
        i = i +1;
    end

      replay(k) = counter;
      k = k+1;

    y1 =5;
    image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
    imagesc(image3)
    if ii <=20
        savefig(volleyfilesright(ii,1))
        ii = ii +1;
    else
        break;
    end
    set(gcf, 'Position', get(0, 'Screensize'));
    axis off
end

%replay 1
image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
for l  = 1:1:20
    x = volley( replay(l),1);
    y = volley(replay(l),3);
    z = volley(replay(l),2);
    x1 =7.5484;
    y1 =4.3444;
    z1 =1.5846;
    rx = 91;
    ry = 0;
    rz = 99;

    image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
    imagesc(image)
    image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
    imagesc(image3)

end

%replay 2
for l1  = 1:1:20
    x = volley( replay(l1),1);
    y = volley(replay(l1),3);
    z = volley(replay(l1),2);
    x1 =0.47844;
    y1 =12.38;
    z1 =1.1546;
    rx = 81;
    ry = 0;
    rz = 178;

    image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
    imagesc(image)
    image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
    imagesc(image3)

end

%replay 3
for l2  = 1:1:20
    x = volley( replay(l2),1);
    y = volley(replay(l2),3);
    z = volley(replay(l2),2);
    x1 =-1.1816;
    y1 =11;
    z1 =0.91456;
    rx = 100;
    ry = 0;
    rz = 231;

    image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
    imagesc(image)
    image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
    imagesc(image3)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Volley 2 done

% volley = readmatrix("\data\Volley2.dat");
% 
% dataSize = size(volley);
% numFrames = dataSize(1);
% 
% sampledServeCounter = 1;
% frameTimeMs = 75;
% 
% %creates images of each cam in each frame
% volleyfilesleft =  ["v2m1.fig";"v2m2.fig";"v2m3.fig";"v2m4.fig";"v2m5.fig";"v2m6.fig";"v2m7.fig";"v2m8.fig";"v2m9.fig";"v2m10.fig";"v2m11.fig";"v2m12.fig";"v2m13.fig";"v2m14.fig";"v2m15.fig";];
% volleyfilesright = ["v2m1_.fig";"v2m2_.fig";"v2m3_.fig";"v2m4_.fig";"v2m5_.fig";"v2m6_.fig";"v2m7_.fig";"v2m8_.fig";"v2m9_.fig";"v2m10_.fig";"v2m11_.fig";"v2m12_.fig";"v2m13_.fig";"v2m14_.fig";"v2m15_.fig";];
% replay = [1,size(volleyfilesright)]; %
% i = 1; % used to get pic of left cams
% ii = 1;% used to get pic of right cams
% k = 1; % used to get counter value for replay
% for counter = 1:frameTimeMs:numFrames
%     x = volley(counter,1);
%     y = volley(counter,3);
%     z = volley(counter,2);
%     x1 =11;
%     y1 =-5;
%     z1 =8.2;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
%     imagesc(image3)
%     if i <=15
%         savefig(volleyfilesleft(i,1))
%         i = i +1;
%     end
% 
%       replay(k) = counter;
%       k = k+1;
% 
%     y1 =5;
%     image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
%     imagesc(image3)
%     if ii <=15
%         savefig(volleyfilesright(ii,1))
%         ii = ii +1;
%     else
%         break;
%     end
%     set(gcf, 'Position', get(0, 'Screensize'));
%     axis off
% end
% 
% %replay 1
% image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
% for l  = 1:1:15
%     x = volley( replay(l),1);
%     y = volley(replay(l),3);
%     z = volley(replay(l),2);
%     x1 =7.5484;
%     y1 =4.3444;
%     z1 =1.5846;
%     rx = 91;
%     ry = 0;
%     rz = 99;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end
% 
% %replay 2
% for l1  = 1:1:15
%     x = volley( replay(l1),1);
%     y = volley(replay(l1),3);
%     z = volley(replay(l1),2);
%     x1 =0.47844;
%     y1 =12.38;
%     z1 =1.1546;
%     rx = 81;
%     ry = 0;
%     rz = 178;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end
% 
% %replay 3
% for l2  = 1:1:15
%     x = volley( replay(l2),1);
%     y = volley(replay(l2),3);
%     z = volley(replay(l2),2);
%     x1 =-1.1816;
%     y1 =11;
%     z1 =0.91456;
%     rx = 100;
%     ry = 0;
%     rz = 216;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % volley 3 done

% volley = readmatrix("\data\Volley3.dat");
% 
% dataSize = size(volley);
% numFrames = dataSize(1);
% 
% sampledServeCounter = 1;
% frameTimeMs = 200;
% 
% %creates images of each cam in each frame
% volleyfilesleft =  ["v3m1.fig";"v3m2.fig";"v3m3.fig";"v3m4.fig";"v3m5.fig";"v3m6.fig";"v3m7.fig";"v3m8.fig";"v3m9.fig";"v3m10.fig";"v3m11.fig";"v3m12.fig";"v3m13.fig";"v3m14.fig";"v3m15.fig";"v3m16.fig";"v3m17.fig";];
% volleyfilesright = ["v3m1_.fig";"v3m2_.fig";"v3m3_.fig";"v3m4_.fig";"v3m5_.fig";"v3m6_.fig";"v3m7_.fig";"v3m8_.fig";"v3m9_.fig";"v3m10_.fig";"v3m11_.fig";"v3m12_.fig";"v3m13_.fig";"v3m14_.fig";"v3m15_.fig";"v3m16_.fig";"v3m17_.fig";];
% replay = [1,size(volleyfilesright)]; %
% i = 1; % used to get pic of left cams
% ii = 1;% used to get pic of right cams
% k = 1; % used to get counter value for replay
% for counter = 1:frameTimeMs:numFrames
%     x = volley(counter,1);
%     y = volley(counter,3);
%     z = volley(counter,2);
%     x1 =11;
%     y1 =-5;
%     z1 =8.2;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
%     imagesc(image3)
%     if i <=20
%         savefig(volleyfilesleft(i,1))
%         i = i +1;
%     end
% 
%       replay(k) = counter;
%       k = k+1;
% 
%     y1 =5;
%     image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
%     imagesc(image3)
%     if ii <=20
%         savefig(volleyfilesright(ii,1))
%         ii = ii +1;
%     else
%         break;
%     end
%     set(gcf, 'Position', get(0, 'Screensize'));
%     axis off
% end
% 
% %replay 1
% image3 = blenderLink(client,width,height,x1,y1,z1,45,0,90,"Left Camera");
% for l  = 1:1:15
%     x = volley( replay(l),1);
%     y = volley(replay(l),3);
%     z = volley(replay(l),2);
%     x1 =7.9384;
%     y1 =9.1744;
%     z1 =1.7746 ;
%     rx = 92;
%     ry = 0;
%     rz = 108;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end
% 
% %replay 2
% for l1  = 1:1:15
%     x = volley( replay(l1),1);
%     y = volley(replay(l1),3);
%     z = volley(replay(l1),2);
%     x1 =3.12844;
%     y1 =12.38;
%     z1 =1.1546;
%     rx = 81;
%     ry = 0;
%     rz = 178;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end
% 
% %replay 3
% for l2  = 1:1:15
%     x = volley( replay(l2),1);
%     y = volley(replay(l2),3);
%     z = volley(replay(l2),2);
%     x1 =-1.1816;
%     y1 =11;
%     z1 =0.91456;
%     rx = 100;
%     ry = 0;
%     rz = 231;
% 
%     image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%     imagesc(image)
%     image3 = blenderLink(client,width,height,x1,y1,z1,rx,ry,rz,"Left Camera");
%     imagesc(image3)
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % original code


%for counter = 1:frameTimeMs:numFrames
%    x = serve(counter,1);
%    y = serve(counter,3);
%    z = serve(counter,2);
%    x1 =13.875;
%    if counter >= numFrames/9
%        y1 =5.21188;
%    else 
%        y1 =-6.9841;
%    end
%    z1 =13.792;

%    image = blenderLink(client,width,height,x,y,z,0,0,0,"tennisBall");
%    imagesc(image)
%    image3 = blenderLink(client,width,height,x1,y1,z1,58.4322,0.000539,90.7338,"Cameraleft");
%    imagesc(image3)
%    set(gcf, 'Position', get(0, 'Screensize'));
%    axis off
%end
