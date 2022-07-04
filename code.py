import board
from keybow2040 import Keybow2040

import usb_hid
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS
from adafruit_hid.keycode import Keycode
import supervisor

# Set up Keybow
i2c = board.I2C()
keybow = Keybow2040(i2c)
keys = keybow.keys

# Set up the keyboard and layout
keyboard = Keyboard(usb_hid.devices)
layout = KeyboardLayoutUS(keyboard)

keymap = {
    0: (Keycode.CONTROL, Keycode.COMMAND, Keycode.LEFT_SHIFT, Keycode.GRAVE_ACCENT),
    4: (Keycode.CONTROL, Keycode.COMMAND, Keycode.LEFT_SHIFT, Keycode.V),
    8: (Keycode.CONTROL, Keycode.COMMAND, Keycode.LEFT_SHIFT, Keycode.L),
}

# The colour to set the keys when pressed, yellow.
RED = [255, 0, 0]
GREEN = [0, 255, 0]
YELLOW = [255, 255, 0]
WHITE = [123, 123, 100]

MIC_KEY = keys[0]
CAM_KEY = keys[4]
LIGHT_KEY = keys[8]


def process_input(input_bytes):
    print(repr(input_bytes))
    if input_bytes == "CAM_ON":
        CAM_KEY.set_led(*GREEN)
    if input_bytes == "CAM_OFF":
        CAM_KEY.set_led(*RED)
    if input_bytes == "MIC_ON":
        MIC_KEY.set_led(*GREEN)
    if input_bytes == "MIC_OFF":
        MIC_KEY.set_led(*RED)
    if input_bytes == "NO_MEETING":
        MIC_KEY.set_led(*WHITE)
        CAM_KEY.set_led(*WHITE)


def serial_read():
    if supervisor.runtime.serial_bytes_available:
        process_input(input())


def toggle_led(key):
    if key.rgb == GREEN:
        key.set_led(*RED)
    elif key.rgb == RED:
        key.set_led(*GREEN)
    elif key.rgb == YELLOW:
        key.set_led(*WHITE)


for key in (MIC_KEY, CAM_KEY, LIGHT_KEY):

    @keybow.on_press(key)
    def press_handler(key):
        try:
            toggle_led(key)
            keycode = keymap[key.number]
            keyboard.send(*keycode)
        except IndexError:
            pass

LIGHT_KEY.set_led(*YELLOW)

@keybow.on_release(LIGHT_KEY)
def reset_light_key(key):
        key.set_led(*YELLOW)

while True:
    # Always remember to call keybow.update()!
    keybow.update()
    try:
        serial_read()
    except Exception as e:
        print(e)
