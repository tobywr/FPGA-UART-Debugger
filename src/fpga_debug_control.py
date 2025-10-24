import serial
import time
import sys

# USE YOUR PORT AND BAUD RATE!!!!
SERIAL_PORT = '/dev/ttyUSB0'
BAUD_RATE = 115200
TIMEOUT = 0.1 #100ms

ser = None

def connect():
    #establish serial connection.
    global ser
    try:
        ser = serial.Serial(
            port=SERIAL_PORT,
            baudrate=BAUD_RATE,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            bytesize=serial.EIGHTBITS,
            timeout=TIMEOUT
        )
        print(f"Connected to {SERIAL_PORT} at {BAUD_RATE} baud")
        #flush old data
        ser.flushInput()
        ser.flushOutput()
        return True
    except serial.SerialException as e:
        print(f"Error could not open port : {SERIAL_PORT}")
        print(f"Details : {e}")
        return False
    
def send_command(command_str):
    #send cmd string to FPGA
    if not ser:
        print("not connected.")
        return
    
    ser.write(command_str.encode('ascii'))

def handle_read(command_str):
    # sends read command + returns 4-byte response.
    ser.flushInput()
    send_command(command_str)

    response = ser.read(4)

    if len(response) < 4:
        print(f"Error : Read timeout, recieved: {response}")
        return "TIMEOUT"
    
    try:
        response_str = response.decode('ascii')
        value = response_str[2:]
        return value
    except UnicodeDecodeError :
        print(f"Error, recieved non ascii data : {response}")
        return "ERROR"
    
#main program.
if __name__ == "__main__":
    if not connect():
        sys.exit(1)

    print("\n--- FPGA debugger ---")
    print("Type your command (e.g : w05AB)")
    print("Type quit or exit to exit.")

    while True:
        try:
            cmd = input("\n> ")
            cmd = cmd.strip() #remove whitespace.

            if not cmd:
                continue

            if cmd.lower() in ["quit", "exit"]:
                print("exiting")
                break

            if cmd.startswith('w'):
                send_command(cmd)
                print(f"Write command sent : {cmd}")

            elif cmd.startswith('r'):
                print(f"Read command sent {cmd}")
                value = handle_read(cmd)
                print(f"Response : {value}")

            else:
                print(f"Error, unknown command, start with r or w.")

        except KeyboardInterrupt:
            print("interrupt, exiting.")
            break

    if set and ser.is_open:
        ser.close()
    print("Connection closed.")