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

echo "installing emulator..."
sudo apt install -y gcc-arm-none-eabi \
     binutils-arm-none-eabi gdb-multiarch qemu-system-arm

mkdir -p ~/projects/embedded/lab2
cd ~/projects/embedded/lab2

echo "Creating startup.s and linker.ld files..."

cat << EOF > startup.s
.syntax unified
.cpu cortex-a15
.arm
.section .text
.global _start

_start:
     ldr sp, =stack_top
     mov r0, #5
     mov r1, #7
     add r2, r0, r1

loop:
     b loop
EOF

cat << EOF > linker.ld
ENTRY(_start)

SECTIONS
{
  . = 0x40100000;

  .text : { *(.text*) *(.rodata*) }
  .data : { *(.data*) }
  .bss  : { *(.bss*) *(COMMON) }

  . = ALIGN(8);
  . += 0x1000;
  stack_top = .;
}
EOF

echo "Creating boot.elf image..."
arm-none-eabi-gcc -nostdlib -nostartfiles -T linker.ld startup.s -Wl,-Map=boot.map -o boot.elf

chmod +x boot.elf

echo "------------------------------------------------"
echo "The compilation is complete."
echo "------------------------------------------------"

# Prompt the user for confirmation
read -p "Do you want to run the QEMU debugger? (y/n): " confirm

if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]]; then
    echo "Starting emulation and debugger..."
    echo "------------------------------------------------"
    
    # Instructions for the user to follow in the second terminal
    cat << EOF
   target remote :1234 -- to connect to the QEMU instance
   info registers sp r0 r1 r2 -- to monitor only registers sp,r0,r1,r2 ( after each stepi command )
   x/6i \$pc -- to show the first 6 lines of the instructions
   info files -- to display information about the loaded files
   stepi -- to execute one step
   exit -- to exit GDB
EOF
    echo "------------------------------------------------"

    # Execute the QEMU emulator with tracing enabled
    qemu-system-arm -M virt -cpu cortex-a15 -nographic \
       -S -s -d in_asm,cpu -D qemu_trace.log \
       -device loader,file=boot.elf,cpu-num=0 &
     # The -S option tells QEMU to start in a paused state, waiting for a GDB connection before executing any instructions.
     # The -s option is a shorthand for -gdb tcp::1234, which tells QEMU to listen for a GDB connection on TCP port 1234. This allows you
     echo "QEMU_PID = $!"
     sleep 5 
     QEMU_PID=$! # to get the PID of the QEMU process
     gdb-multiarch boot.elf # to start GDB multiarch with the boot.elf file
     kill -9 $QEMU_PID
else
    echo "Exiting without running GDB multiarch."
fi