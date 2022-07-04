import sys
import serial

try:
    s = serial.Serial("/dev/tty.usbmodem21101", 115200)
    cmd = f"{sys.argv[1]}\r".encode()
    print(repr(cmd))
    s.write(cmd)
    s.close()
except Exception as e:
    print(e)
    pass
