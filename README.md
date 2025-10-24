# FPGA-UART-Debugger
FPGA register debugger over a UART serial connection.
## Simulating
Tool currently testing using python 3.10.12, and Vivado 2025.1.
1. Clone the github repo.
2. Open your chosen SystemVerilog simulator (e.g:Vivado, ModelSim)
3. Create new project, import src/ and sim/.
4. Run sim using `full_tb.sv`.
5. Run the simulation for 10ms to be sure that logic fully settles. (In TCL console, run command : `run 10ms`)

Output Waveform : 
![Output Waveform](https://github.com/tobywr/FPGA-UART-Debugger/blob/main/images/sim_waveform.png "Output Waveform")

## Uploading to Hardware

### Pre-requisites
1. Change `PIN.xdc` to your own FPGA's specific pin layout. Change all the values of `PACKAGE_PIX X` to your FPGAs specific pins (Found in user manuals / manufacturers docs).
2. Change the Clock Frequency and Baud rate in all files, including `fpga_debug_control.py` file.
3. Change serial connection location in `fpga_debug_control.py` to your connection location. To find connection location : 

_WINDOWS_ : 
- Press `Windows Key + X` and select __Device Manager__.
- Look under sections : Ports (COM & LPT) and Universal Serial Bus Controllers. Note COM port number of FPGA Serial connection.

_LINUX_ :
Method 1 :
- In Terminal, run `ls /dev/tty*` and locate your FPGA connection port (e.g : `/ttyUSB0`)

Method 2 :
- In terminal, after plugging FPGA in, run command : `sudo dmesg | tail -20` and look for serial converter / FPGA connected message.

### Syntheszing + Opening serial viewer:
Create a new project in Vivado/Quartus (Make sure to specify your model of hardware during project creation), and upload all `/src` files.

Run synthesis, implementation and generate bitstream.

Open connection, auto connect to harware.

Upload to your FPGA.

Run in terminal/powershell : 
`python3 fpga_debug_control.py` whilst terminal open in your working directory.

You should see a message saying `Connected to YOUR_COM_PORT at BAUD_RATE baud`.

### How to use:
Two types of commands can be used, `r` and `w`. r = Read from a register address, w = Write a value to a specific register. E.g:

`w05AB` will write to register 05, with a value of 'AB'.
`r05` will read the raw value from register 05 and output the value to the CLI.

Example CLI : 
![Example CLI](https://github.com/tobywr/FPGA-UART-Debugger/blob/main/images/cli_output.png "Example CLI")

Exit by either entering `quit` or `exit` into the CLI.