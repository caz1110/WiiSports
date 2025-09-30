classdef blenderClient
    properties (Constant)
        % PCSERVER = char(java.net.InetAddress.getLocalHost.getHostAddress);
        PCSERVER = getLocalIP();
        PORT = 5050;
        HEADER = 64;
        FORMAT = 'UTF-8';
        
        Msgs = struct( ...
            'DISCONNECT_MESSAGE', '!DISCONNECT', ...
            'CAPTURE_REQUEST', '!CAPTURE', ...
            'SET_CAMERA', '!SETCAM', ...
            'DEPTH_REQUEST', '!DEPTH', ...
            'TRANSFORM_REQUEST', '!TRANSFORM', ...
            'PING_MESSAGE', '!PING');
        
        LeftCamera = 'LeftCamera';
        RightCamera = 'RightCamera';
        TennisBall = 'tennisBall';
    end
    
    methods (Static)

        function sendString(client, msg)
            msgBytes = unicode2native(msg, blenderClient.FORMAT);
            lenBytes = unicode2native(sprintf('%d', length(msgBytes)), blenderClient.FORMAT);
            lenBytes = [lenBytes, repmat(' ', 1, blenderClient.HEADER - length(lenBytes))];
            write(client, uint8(lenBytes), 'uint8');
            write(client, uint8(msgBytes), 'uint8');
        end

        function client = openConnection()
            try
                client = tcpclient(blenderClient.PCSERVER, ...
                    blenderClient.PORT, ...
                    "Timeout",30);
            catch
                error("[MATLAB CLIENT] Failed to connect!")
            end

            if exist('client', 'var')
                disp("[MATLAB CLIENT] Connected to server...");
            end
        end

        function closeConnection(client)
            try
                blenderClient.sendString(client, blenderClient.Msgs.DISCONNECT_MESSAGE);
            catch
                error("[MATLAB CLIENT] Failed to disconnect!")
            end
        end

        function connected = pingConnection(client)
            try
                blenderClient.sendString(client, blenderClient.Msgs.PING_MESSAGE);
                connected = true;
            catch
                connected = false;
            end
        end
        
        function transformObject(client, obj, x, y, z, pitch, roll, yaw)
            blenderClient.sendString(client, blenderClient.Msgs.TRANSFORM_REQUEST);
            blenderClient.sendString(client, obj);
            floatData = single([x, y, z, pitch, roll, yaw]);
            floatBytes = typecast(floatData, 'uint8');
            write(client, floatBytes, 'uint8');
        end
        
        function depth = getDepth(client, obj)
            blenderClient.sendString(client, blenderClient.Msgs.DEPTH_REQUEST);
            blenderClient.sendString(client, obj);
            try
                raw = read(client, 4, 'uint8');
                depth = typecast(uint8(raw), 'single');
            catch ME
                warning(ME.identifier,'%s', ME.message);
                depth = NaN;
            end
        end
        
        function changeCamera(client, cam)
            blenderClient.sendString(client, blenderClient.Msgs.SET_CAMERA);
            blenderClient.sendString(client, cam);
        end
        
        function img = sendCameraRequest(client, width, height)
            blenderClient.sendString(client, blenderClient.Msgs.CAPTURE_REQUEST);
            payload = typecast(single([width, height]), 'uint8');
            write(client, payload, 'uint8');

            imgSize = width * height * 4;
            buffer = uint8([]);

            while length(buffer) < imgSize
                data = read(client, imgSize - length(buffer), 'uint8');
                buffer = [buffer; data];
            end

            % Convert to RGB image
            imgRaw = reshape(buffer, 4, width, height);
            imgRGB = permute(imgRaw(1:3, :, :), [3, 2, 1]);  % (H, W, 3)
            img = flipud(uint8(imgRGB));
        end
        
        function [img1, img2, depth] = connectAndCapture(client, width, height)
            blenderClient.changeCamera(client, blenderClient.LeftCamera);
            img1 = blenderClient.sendCameraRequest(client, width, height);

            blenderClient.changeCamera(client, blenderClient.RightCamera);
            img2 = blenderClient.sendCameraRequest(client, width, height);

            depth = blenderClient.getDepth(client, blenderClient.TennisBall);
        end
        
        function changeCamPositions(baseline, x, y, z, pitch, roll, yaw)
            leftY = y - baseline / 2;
            rightY = y + baseline / 2;

            client = tcpclient(blenderClient.PCSERVER, blenderClient.PORT);
            disp("[MATLAB CLIENT] Connected to server...");

            blenderClient.transformObject(client, blenderClient.LeftCamera, x, leftY, z, pitch, roll, yaw);
            blenderClient.transformObject(client, blenderClient.RightCamera, x, rightY, z, pitch, roll, yaw);

            blenderClient.sendString(client, blenderClient.Msgs.DISCONNECT_MESSAGE);
        end
    end
end
