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
echo "Note: Running QEMU with -S and -s will freeze the CPU and wait for a GDB connection."
echo "To start execution, you will need to connect GDB or press 'c' in the QEMU monitor."
echo "------------------------------------------------"

# Prompt the user for confirmation
read -p "Do you want to run the QEMU simulation? (y/n): " confirm

if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]]; then
    echo "Starting QEMU..."
    echo "------------------------------------------------"
    
    # Instructions for the user to follow in the second terminal
    cat << EOF
Inside a separate terminal (ALT + SHIFT + +) run:
  1. cd ~/projects/embedded/lab2 
  2. gdb-multiarch boot.elf
  3. target remote :1234
  4. info registers
  5. x/6i \$pc
  6. info files
  7. stepi

  8. To close the 2nd terminal, press (CTRL + SHIFT + W)
EOF
    echo "------------------------------------------------"

    # Execute the QEMU emulator with tracing enabled
    qemu-system-arm -M virt -cpu cortex-a15 -nographic \
       -S -s -d in_asm,cpu -D qemu_trace.log \
       -device loader,file=boot.elf,cpu-num=0
else
    echo "Exiting without running QEMU."
fi