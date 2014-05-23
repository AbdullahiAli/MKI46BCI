set batdir=%~dp0
rem Start the osc2ft shim to transfer osc messages to the buffer
set oscport=1234
set oscdevice=ffc3
start "osc2ft" java -cp buffer/java/Buffer.jar:osc/JavaOSC/JavaOSC.jar:osc osc2ft /muse/eeg/raw:%oscport% localhost:1972 6 500 1 10
rem Search for the buffer executable
set execname=muse-io-2_5_0-build125
if exist "%batdir%buffer\bin\win32\%execname%" ( set buffexe="%batdir%buffer\bin\win32\%execname%.exe" )
if exist "%batdir%buffer\win32\%execname%.exe" ( set buffexe="%batdir%buffer\win32\%execname%.exe" )
if exist "%batdir%%execname%.exe" ( set buffexe="%batdir%%execname%.exe" )
rem start /b "buffer" %buffexe% %1 %2 %3
start /b "buffer" %buffexe% --device %oscdevice% --preset ab --osc osc.udp://localhost:%oscport%