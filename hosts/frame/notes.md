
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
