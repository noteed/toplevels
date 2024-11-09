
This is a NixOS configuration for my Framework 13 laptop.

To build and install the configuration:

```
$ scripts/update-frame.sh
```

In addition to the NixOS configuration:

In Firefox about:config: layout.css.devPixelsPerPx is set to 0.9.

To see the battery state:

```
$ upower -i /org/freedesktop/UPower/devices/battery_BAT1
```

To change the backlight

```
$ echo 55 > /sys/class/backlight/amdgpu_bl1/brightness
```

To have the function keys (F1..F12) act as such instead of multimedia keys,
there is no BIOS option, but using`fn` and `fn-lock` (on the ESC key) switches
the behavior (and is supposed to be persisted across reboots).

For the sound in Google Meet, even with the Arctis headphones plugged in, I
have only the default ouput visible (but mic is fine ). I can select the Arctis
with pactl:

```
$ pactl set-default-sink alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.mono-chat
```
