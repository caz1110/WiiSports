This code base contains a Vivado reference design that integrates with the Simulink HDL Coder build engine.  One 
must add the path to these files to the Matlab workspace and then open up the Simulink model.  Run setup.m to
setup the model and then execute the Simulink model.  After running the model one can then generate HDL via
HDL Coder that will target the Snickerdoodle Zynq SoC.

See Lectures 11 & 17 for help
run the below lines in Matlab. Swap out the path for whatever the path is to your downloaded directory
addpath('C:\Users\Chris\Documents\Repos\WiiSports\TennisTracker\BoradwaySimulink') 
addpath('C:\Users\Chris\Documents\Repos\WiiSports\TennisTracker\BoradwaySimulink\Fusion2')
Fusion2Registration.plugin_board
savepath
hdlsetuptoolpath('ToolName','Xilinx Vivado','ToolPath', 'D:\Xilinx\Vivado\2019.1\bin\vivado.bat')

File will complie to the following path:
C:\Users\Chris\Desktop\vivado-reference-design\hdl_prj2\vivado_ip_prj\vivado_prj.runs\impl_1\design_1_wrapper.bit

To connect your board to the internet, you'll need to enter the following command:
wpa_passphrase "MyWiFi" "mypassword" | sudo tee /etc/wpa_supplicant.conf