# Keybow 2040 Zoom controller for Mac

## Requirements

- assembled [Keybow 2040](https://shop.pimoroni.com/products/keybow-2040)
- Python 3.6+ for the serial script
- Zoom app for Mac

## How to use

### Build client-side app

- Open `Control Zoom.scpt` in Script Editor
- Update path to Python and `serial_script.py` (AFAIK these need to be fully qualified paths)
- File > Export as Application with `Stay open after run handler` checked (see screenshot)
- Run `Control Zoom.app` and allow Accessibility permissions
- Close `Control Zoom.app` and open again, it should now run silently

### Install board code

- Copy `code.py` to the `CIRCUITPYTHON` volume

### Setup Zoom

- Open Zoom preferences and browse to Keyboard shortcuts
- Select the shortcut for "Mute/Unmute my audio" and press key 0 on the keypad
- Select Enable Global Shortcut
- Select the shortcut for "Start/stop" and press key 1 on the keypad
- Select Enable Global Shortcut

### Usage

- When Zoom is closed or no conference is in progress the LEDs will show white
- Key 0 controls the microphone, green for on red for off
- Key 1 controls the video, green for on red for off


## How does it work

The keybow is configured to do send specific keyboard shortcuts on press, these are registered as global shortcuts in Zoom allowing you to use them no matter what app is in the foreground. The Applescript reads the Zoom menu bar icon menu to determine if the audio and video are active, it then calls `serial_script.py` which sends commands over serial to the 2040.

## Attribution

- AppleScript based on [Dustin's Zoom Mute Indicator](https://dustin.lol/post/2020/zoom-mute/)
- Logo is [Camera And Microphone by AmruID from NounProject.com](https://thenounproject.com/icon/camera-and-microphone-3658462/) under CC-BY license
