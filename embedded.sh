#!/usr/bin/env bash

init(){
    sudo apt update
    sudo apt -y upgrade 

    sudo apt install -y                  \
        build-essential make pkg-config \
        gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf 

     
    sudo apt install -y             \
    	qemu-user qemu-user-static \
        qemu-system-arm

    sudo apt install -y gcc-arm-none-eabi \
        binutils-arm-none-eabi gdb-multiarch qemu-system-arm

clear
echo "-------------------------------------------------------------------------------------"
echo "                      The required packages has been installed.                      "
echo "-------------------------------------------------------------------------------------"
}

create_arm_machine(){
    mkdir -p ~/projects/embedded/lab2
    cd ~/projects/embedded/lab2

    cat <<-EOF > startup.s
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

    cat <<-EOF > linker.ld
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

    arm-none-eabi-gcc -nostdlib -nostartfiles -T linker.ld startup.s -Wl,-Map=boot.map -o boot.elf
    chmod +x boot.elf

echo "-------------------------------------------------------------------------------------"
echo "                      The machine has been created.                                  "
echo "-------------------------------------------------------------------------------------"
}

run_debugger(){

# Prompt the user for confirmation
read -p "Do you want to run the QEMU debugger? (y/n): " confirm

if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]]; then
    echo "Starting emulation and debugger..."
echo "-------------------------------------------------------------------------------------"
     cd ~/projects/embedded/lab2
   
    # Instructions for the user to follow in the second terminal
    cat << EOF
	target remote :1234 -- to connect to the QEMU instance
   	info registers sp r0 r1 r2 -- to monitor only registers sp,r0,r1,r2 ( after each stepi command )
   	x/6i \$pc -- to show the first 6 lines of the instructions
   	info files -- to display information about the loaded files
   	stepi -- to execute one step
   	exit -- to exit GDB
EOF
echo "-------------------------------------------------------------------------------------"

    # Execute the QEMU emulator with tracing enabled
    qemu-system-arm -M virt -cpu cortex-a15 -nographic \
       -S -s -d in_asm,cpu -D qemu_trace.log \
       -device loader,file=boot.elf,cpu-num=0 &
     # The -S option tells QEMU to start in a paused state, waiting for a GDB connection before executing any instructions.
     # The -s option is a shorthand for -gdb tcp::1234, which tells QEMU to listen for a GDB connection on TCP port 1234. This allows you
     QEMU_PID=$! # to get the PID of the QEMU process
     gdb-multiarch boot.elf # to start GDB multiarch with the boot.elf file
     kill -9 $QEMU_PID
else
    echo "Exiting without running GDB multiarch."
fi
}
clear # main header

echo   "-------------------------------------------------------------------------------------"
echo   "               This script can preform the following tasks :                         "
echo   "                                                                                     "
echo   "                                                                                     "
echo   "     0. to exit the script and return to the terminal prompt.                        "
echo   "                                                                                     "
echo   "     1. install the required packages for qemu and arm development                   "
echo   "                                                                                     "
echo   "     2. create_arm_machine with the required startup.s and linker.ld & boot.elf image"
echo   "                                                                                     "
echo   "     3. run the qemu emulator and gdb multiarch debugger                             "
echo   "                                                                                     "
echo   "                                                                                     "
echo   "       This Bash script was created by Lidor.Y(E.E student) and Dani.R(DevOps)       "
echo   "                                                                                     "
read -p"------------------------Enter your choice (0, 1, 2, or 3):---------------------------" choice

if   [[ "$choice" == [0] ]]; then
	clear
	echo "Exiting the script."
	sleep 3
	exit 0
elif [[ "$choice" == [1] ]]; then
	clear
	echo "Installing required packages for qemu and arm development..."
	sleep 3
	init
elif [[ "$choice" == [2] ]]; then
	clear
	echo "Creating ARM machine with startup.s, linker.ld, and boot.elf image..."
	sleep 3
	create_arm_machine
elif [[ "$choice" == [3] ]]; then
	clear
	echo "Running QEMU emulator and GDB multiarch debugger..."
	sleep 3
	run_debugger
else
	echo "-------------------------------------------------------------------------------------"
	echo "                 Invalid choice, returning to the terminal prompt.                   "
	echo "-------------------------------------------------------------------------------------"
fi
