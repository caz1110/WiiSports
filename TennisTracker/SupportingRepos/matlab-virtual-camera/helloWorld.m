% Dr. Kaputa
% Virtual Camera Demo
% must run helloWorld.py first on the FPGA SoC

%Initialization Parameters
server_ip   = '129.21.70.165';     % IP address of the server
server_port = 9999;                % Server Port of the sever

client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");
 
write(client,'0');
flush(client);