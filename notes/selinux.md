# Raspberry Pi 4 Fedora Motion Eye RTSP Camera Server Setup Guide

### Install rpmfusion repositories for motion and ffmpeg
  
    dnf install http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

### SELinux Changes required to allow motion to use rtsp port
  
    ausearch -c 'ml1:Driveway' --raw | audit2allow -M my-ml1Driveway#012# semodule -X 300 -i my-ml1Driveway.pp#012
    semodule -X 300 -i my-ml1Driveway.pp
    ausearch -c 'motion' --raw | audit2allow -M my-motion
    semodule -X 300 -i my-motion.pp

### Firewalld changes
  
    firewall-cmd --add-port=8554/tcp --permanent
    firewall-cmd --add-port=8554/udp --permanent
    firewall-cmd --reload

### Play H264 Encoded Video Files on your Fedora client
  
    dnf install gstreamer1-libav

# Setup for RTSP Server
  
    alsa-plugins-usbstream.aarch64 alsa-tools alsa-tools-firmware alsa-firmware -y
