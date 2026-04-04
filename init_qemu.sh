#!/usr/bin/env bash

sudo apt update
sudo apt -y upgrade 

sudo apt install -y                  \
     build-essential make pkg-config \
     gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf 

echo "Checking arm-linux-gnueabihf-gcc is installed"
arm-linux-gnueabihf-gcc --version
 
echo "Installing QEMU..."
sudo apt install -y             \
     qemu-user qemu-user-static \
     qemu-system-arm

