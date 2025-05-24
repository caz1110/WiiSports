classdef snickClient
    % SNICKCLIENT Summary:
    % SncikClient is a class that handles the connection to the Snick server.
    % It provides methods to send messages, open and close the connection.
    
    properties
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
            msgBytes = unicode2native(msg, snickClient.FORMAT);
            lenBytes = unicode2native(sprintf('%d', length(msgBytes)), snickClient.FORMAT);
            lenBytes = [lenBytes, repmat(' ', 1, snickClient.HEADER - length(lenBytes))];
            write(client, uint8(lenBytes), 'uint8');
            write(client, uint8(msgBytes), 'uint8');
        end

        function client = openConnection()
            try
                client = tcpclient(snickClient.PCSERVER, ...
                    snickClient.PORT, ...
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
                snickClient.sendString(client, snickClient.Msgs.DISCONNECT_MESSAGE);
            catch
                error("[MATLAB CLIENT] Failed to disconnect!")
            end
        end

        function calibrationRequest (client, baselinemm, focallengthmm, pixelsizemm)
            snickClient.sendString(client, snickClient.Msgs.CALIBRATION_REQUEST);
            floatData = single([baselinemm, focallengthmm, pixelsizemm]);
            floatBytes = typecast(floatData, 'uint8');
            write(client, floatBytes, 'uint8');
        end
        
    end
end

