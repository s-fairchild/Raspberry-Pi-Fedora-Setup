### Initial Pre-boot Configuration

### Update the board firmware!!!
It's important to ensure the latest firmware is installed. \
[See rpi-imager to update firmware without having to install Raspberry Pi OS](https://github.com/raspberrypi/rpi-imager) \
[Blog Article](https://www.raspberrypi.com/news/raspberry-pi-imager-imaging-utility/) \
See the advanced section to download the update utility only, flash to an sdcard, reboot and remove.

<!-- TODO fix this sed command -->
  
    sed -i.bak /dev/mmcblk0p1 ${bootDir}/config.txt

### Tips and Tricks
If you're using a serial terminal connection, set it to your appropriate screen size. \
The below works for my terminal full screen on a 16:9 1920x1080 display
  
    stty rows 32 cols 159
  
### References

* Official Raspberry Pi Documentation
  - https://www.raspberrypi.com/documentation/computers/configuration.html
  - https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/uart.adoc
  - https://www.raspberrypi.com/documentation/computers/config_txt.html

* Arch Linux Arm
  - https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
