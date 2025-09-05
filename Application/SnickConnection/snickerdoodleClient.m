classdef snickerdoodleClient
    % snickerdoodleClient Summary:
    % SncikClient is a class that handles the connection to the Snick server.
    % It provides methods to send messages, open and close the connection.
    
    properties (Constant)
        PCSERVER = char(java.net.InetAddress.getLocalHost.getHostAddress);
        PORT = 9999;
        HEADER = 64;
        FORMAT = 'UTF-8';
        Msgs = struct( ...
            'KILL_MESSAGE', '!KILL', ...
            'DISCONNECT_MESSAGE', '!DISCONNECT', ...
            'CALIBRATION_REQUEST', '!CALIBRATION', ...
            'IMAGES_TO_SNICK', '!IMGTOSNICK', ...
            'FEEDTHROUGH_FROM_SNICK', '!GETFEEDTHROUGH', ...
            'PROCESSED_FROM_SNICK', '!GETPROCESSED', ...
            'COORDINATE_CALCULATIONS', '!COORDINATE');
    end
    
    methods (Static)

        function sendString(client, msg)
            msgBytes = unicode2native(msg, snickerdoodleClient.FORMAT);
            lenBytes = unicode2native(sprintf('%d', length(msgBytes)), snickerdoodleClient.FORMAT);
            lenBytes = [lenBytes, repmat(' ', 1, snickerdoodleClient.HEADER - length(lenBytes))];
            write(client, uint8(lenBytes), 'uint8');
            write(client, uint8(msgBytes), 'uint8');
        end

        function client = openConnection()
            disp(['[MATLAB CLIENT] Attempting to connect to server at ', ...
                snickerdoodleClient.PCSERVER, ':', ...
                num2str(snickerdoodleClient.PORT)]);
            try
                client = tcpclient(snickerdoodleClient.PCSERVER, ...
                    snickerdoodleClient.PORT, ...
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
                snickerdoodleClient.sendString(client, snickerdoodleClient.Msgs.DISCONNECT_MESSAGE);
            catch
                error("[MATLAB CLIENT] Failed to disconnect!")
            end
        end

        function calibrationRequest (client, baselinemm, focallengthmm, pixelsizemm)
            snickerdoodleClient.sendString(client, snickerdoodleClient.Msgs.CALIBRATION_REQUEST);
            floatData = single([baselinemm, focallengthmm, pixelsizemm]);
            floatBytes = typecast(floatData, 'uint8');
            write(client, floatBytes, 'uint8');
        end

        % This breaks if images are not the same size!
        function sendImages (client, imageLeft, baselineLeft, imageRight, baselineRight)
            % Data payload prep
            height = size(imageLeft, 1);
            width = size(imageLeft, 2);
            channels = size(imageLeft, 3);
            numberOfImages = 4;
            if any(size(imageLeft) ~= size(imageRight))
                error("[MATLAB CLIENT] Images must be the same size!");
            end
            floatData = single([height, width, channels, numberOfImages]);
            floatBytes = typecast(floatData, 'uint8');

            % Informs server of incoming images and their size
            snickerdoodleClient.sendString(client, snickerdoodleClient.Msgs.IMAGES_TO_SNICK);
            write(client, floatBytes, 'uint8');

            % Send images
            imageLeft    = uint8(imageLeft);
            imageRight   = uint8(imageRight);
            baselineLeft = uint8(baselineLeft);
            baselineRight= uint8(baselineRight);

            write(client, imageLeft(:), "uint8");
            fprintf("Sent left image, size: %s\n", mat2str(size(imageLeft)));

            write(client, baselineLeft(:), "uint8");
            fprintf("Sent left baseline image, size: %s\n", mat2str(size(baselineLeft)));

            write(client, imageRight(:), "uint8");
            fprintf("Sent right image, size: %s\n", mat2str(size(imageRight)));

            write(client, baselineRight(:), "uint8");
            fprintf("Sent right baseline image, size: %s\n", mat2str(size(baselineRight)));
        end

        function killSnick(client)
            try
                snickerdoodleClient.sendString(client, snickerdoodleClient.Msgs.KILL_MESSAGE);
            catch
                error("[MATLAB CLIENT] Failed to send kill message!")
            end
        end
        
        function exampleConnection()
            % Example of how to use the snickerdoodleClient class' connect/disconnect
            client = snickerdoodleClient.openConnection();
            pause(1);
            % Magic aah ahh numbers to test the funni calibrtation request
            snickerdoodleClient.calibrationRequest(client, 100, 50, 0.01);
            pause(1);
            snickerdoodleClient.killSnick(client);
            % Close Server Connection
            pause(1);
            snickerdoodleClient.closeConnection(client);
            disp("[MATLAB CLIENT] Connection closed.");
        end
    end
end

