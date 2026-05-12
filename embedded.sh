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

	sudo apt install -y \
  		 git bc bison flex libssl-dev libncurses-dev \
  		 make gcc-arm-linux-gnueabihf \
  		 qemu-system-arm device-tree-compiler \
  		 busybox-static cpio wget bzip2

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

lab3(){
clear
STAY="true"
while [ "$STAY" = "true" ]; do
	 
	echo "looping menu for lab3 until the user chooses to exit								   "
	echo " "
	echo " "
	echo "to exit - choose 0	  								 		 				       "
	echo " "
	echo "download & build linux kernel - choose 1	  		  								   "
	echo " "
	echo "download & build busybox  - choose 2	  		  				  	     			   "
	echo " "
	echo "import statically compiled 32b elf from ~/projects/embedded/lab3- choose 3	  	   "
	echo " "
	echo "run the kernel with the initramfs image - choose 4      		  		  			   "
	echo " "
	echo "-------------------------Enter your choice (0, 1, 2, 3 or 4):------------------------"
	read lab3_choice


		if [[ "$lab3_choice" == [0] ]]; then
			clear

			echo "Exiting lab3."
			sleep 3
			STAY="false"
		elif [[ "$lab3_choice" == [1] ]]; then

			clear
			read -p "Do you want to download the linux kernel (~175MB)? (y/n): " download_confirm

			if [[ "$download_confirm" == [yY] || "$download_confirm" == [yY][eE][sS] ]]; then
				clear
				echo "Starting to download the Linux kernel...(to directory: ~/projects/embedded/lab3)"
				sleep 5
				mkdir -p ~/projects/embedded/lab3
				cd ~/projects/embedded/lab3
				clear
				wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.81.tar.xz
				tar -xf linux-6.12.81.tar.xz
				cd linux-6.12.81
				export ARCH=arm
				export CROSS_COMPILE=arm-linux-gnueabihf-
				export SRC=$PWD
				export BLD=~/projects/embedded/lab3/build-arm 
				mkdir -p "$BLD"
				make O=$BLD -C $SRC ARCH=arm CROSS_COMPILE=$CROSS_COMPILE multi_v7_defconfig
			fi

			clear
			echo "do you wish to configure the kernel? (y/n): "
			read config_choice
			if [[ "$config_choice" == [yY] || "$config_choice" == [yY][eE][sS] ]]; then
				make O=$BLD -C $SRC ARCH=arm CROSS_COMPILE=$CROSS_COMPILE menuconfig
			fi

			clear
			echo "do you wish to compile the kernel? (y/n) (takes approximately 10-15 minutes)"
			read build_choice
			if [[ "$build_choice" == [yY] || "$build_choice" == [yY][eE][sS] ]]; then
				make O=$BLD -C $SRC ARCH=arm CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) zImage dtbs
				clear
				echo "build directory: $BLD/arch/arm/boot/   "
				ls $BLD/arch/arm/boot/zImage
				ls $BLD/arch/arm/boot/dts/arm/vexpress-v2p-ca15-tc1.dtb
				echo "-------------------------------------------------------------------------------------"
				echo "            download & install linux kernel has been completed.                      "
				echo "-------------------------------------------------------------------------------------"
				sleep 3
			fi
			echo "-------------------------------------------------------------------------------------"
			echo "                    continue to busybox initialization.                              "
			echo "-------------------------------------------------------------------------------------"
			sleep 3

		elif [[ "$lab3_choice" == [2] ]]; then
				clear
				echo "Do you wish to download busybox ? (y/n): "
				read -p "------------------------Enter your choice (y/n):---------------------------" download_busybox
				if [[ "$download_busybox" == [yY] || "$download_busybox" == [yY][eE][sS] ]]; then
					mkdir -p ~/projects/embedded/lab3
					cd ~/projects/embedded/lab3
					wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
					tar -xjf busybox-1.36.1.tar.bz2
				fi	
				clear
				echo "do you wish create initramfs image with busybox ? (y/n): "
				read create_initramfs_choice
				if [[ "$create_initramfs_choice" == [yY] || "$create_initramfs_choice" == [yY][eE][sS] ]]; then
					cd ~/projects/embedded/lab3/busybox-1.36.1
					make distclean
					make defconfig
					sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
					sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config
					make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
					clear
					ls -l busybox
					file busybox
					sleep 5
					cd ~/projects/embedded/lab3
					rm -rf initramfs initramfs.cpio initramfs.cpio.gz
					mkdir -p initramfs/{bin,sbin,etc,proc,sys,usr/bin,usr/sbin,dev}
					cp ~/projects/embedded/lab3/busybox-1.36.1/busybox initramfs/bin/
					cd ~/projects/embedded/lab3/initramfs/bin/
					chmod +x busybox 
					ln -s busybox uname
					ln -s busybox sh
					ln -s busybox mount
					ln -s busybox echo
					ln -s busybox ls
					ln -s busybox cat

					cat <<-'EOF' > init
					#!/bin/sh
					mount -t proc none /proc
					mount -t sysfs none /sys
					mount -t devtmpfs none /dev
					busybox clear
					busybox sleep 1
					busybox clear
					busybox sleep 1
					busybox clear
					echo "Minimal Linux Boot Successful"
					busybox sleep 2
					exec /bin/sh
					EOF

					# cat <<-'EOF' > init
					# #!/bin/sh
					# mount -t proc none /proc
					# mount -t sysfs none /sys
					# mount -t devtmpfs none /dev
					# busybox clear
					# busybox sleep 1
					# busybox clear
					# busybox sleep 1
					# busybox clear
					# echo "Minimal Linux Boot Successful"
					# busybox sleep 2
					# /bin/gpio_control_static_arm &
					# exec /bin/sh
					# EOF

					chmod +x init
					cd .. # to return to the initramfs directory
					find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
					cd .. # to return to the lab3 directory
					INIT_PATH=/$(cpio -t < initramfs.cpio 2>/dev/null | grep -E "/init$") # keeps the path of init as a parameter before gzipping initramfs.cpio
					gzip -f initramfs.cpio
					clear
					echo "-------------------------------------------------------------------------------------"
					echo "       download & install busybox and init filesystem have been completed.           "
					echo "-------------------------------------------------------------------------------------"
					sleep 5
				fi
					echo "-------------------------------------------------------------------------------------"
					echo "                 continue with qemu emulation of minimal linux.                      "
					echo "-------------------------------------------------------------------------------------"
		elif [[ "$lab3_choice" == [3] ]]; then
			clear
			echo "type in the exact statically compiled 32b arm elf file_name you wish to import( must be in ~/projects/embedded/lab3 ):"
			read file_name
			elf_file=$(echo "$file_name" | xargs) # to trim any leading or trailing whitespace from the input
			cd ~/projects/embedded/lab3
			rm -rf initramfs initramfs.cpio initramfs.cpio.gz
			mkdir -p initramfs/{bin,sbin,etc,proc,sys,usr/bin,usr/sbin,dev}
			cp ~/projects/embedded/lab3/busybox-1.36.1/busybox initramfs/bin/
			cp ~/projects/embedded/lab3/$elf_file ~/projects/embedded/lab3/initramfs/bin/
			cd ~/projects/embedded/lab3/initramfs/bin/
			chmod +x busybox 
			chmod +x $elf_file
			ln -s busybox uname
			ln -s busybox sh
			ln -s busybox mount
			ln -s busybox echo
			ln -s busybox ls
			ln -s busybox cat

			cat <<-EOF > init
			#!/bin/sh
			mount -t proc none /proc
			mount -t sysfs none /sys
			busybox clear
			busybox sleep 1
			busybox clear
			busybox sleep 1
			busybox clear
			echo "Minimal Linux Boot Successful"
			busybox sleep 2
			echo "to run $elf_file cd to /bin and ./$elf_file"
			exec /bin/sh
			EOF

			#example of how to add a simple 'C' mooooo program to the initramfs image (after compiling it as a static 32b elf file) :
			# cat <<-'EOF' > init
			# #!/bin/sh
			# mount -t proc none /proc
			# mount -t sysfs none /sys
			# echo "Minimal Linux Boot Successful"
			# cowsay "simple 'C' mooooo program"
			# exec /bin/sh
			# EOF

			chmod +x init
			cd .. # to return to the initramfs directory
			find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
			cd .. # to return to the lab3 directory
			INIT_PATH=/$(cpio -t < initramfs.cpio 2>/dev/null | grep -E "/init$") # keeps the path of init as a parameter before gzipping initramfs.cpio
			gzip -f initramfs.cpio

		elif [[ "$lab3_choice" == [4] ]]; then
				clear
				echo "do you wish to print instructions for mounting SD card image inside the qemu emulation? (y/n): "
				read print_instructions_choice
				if [[ "$print_instructions_choice" == [yY] || "$print_instructions_choice" == [yY][eE][sS] ]]; then
					clear
					cat <<-'EOF' 
					before starting QEMU - make sure you have a statically compiled 32b elf file.

					-------------------------------------------------------------------------------------
					from outside qemu's VM :
					-------------------------------------------------------------------------------------
					
					# 1. Create a blank 8MB raw image file ( it will be created in the current directory)
					dd if=/dev/zero of=transfer.img bs=1M count=8

					# 2. Format the image as ext2 (lightweight, no journal)
					# If it prompts "transfer.img is not a block special device", press 'y'
					mkfs.ext2 transfer.img

					# 3. Create a temporary folder on your host to mount the image
					mkdir -p /tmp/mnt_transfer

					# 4. Mount the image locally (requires sudo)
					sudo mount -o loop transfer.img /tmp/mnt_transfer

					# 5. Copy your statically compiled binary into the mounted drive
					sudo cp </path/binary_name> /tmp/mnt_transfer/

					# 6. Safely unmount the drive (CRITICAL before starting QEMU)
					sudo umount /tmp/mnt_transfer

					# 7. Make sure to include the SD card image flag in the when launching QEMU !
					-drive file=/path/transfer.img,format=raw,if=sd \

					-------------------------------------------------------------------------------------
					from inside qemu's VM (after booting with the initramfs image and SD card image attached) :
					-------------------------------------------------------------------------------------

					# 1. Tell the kernel to populate the /dev folder with hardware nodes
					busybox mount -t devtmpfs devtmpfs /dev

					# 2. Create a folder inside the VM to act as the mount point
					busybox mkdir -p /mnt/usb

					# 3. Mount the virtual SD card (vexpress-a15 mounts SD cards as mmcblk0)
					busybox mount -t ext2 /dev/mmcblk0 /mnt/usb

					# 4. Verify your file is present on the drive
					busybox ls -l /mnt/usb/

					# 5. Execute your program
					/mnt/usb/<binary_name>

					GOOD LUCK :)
					EOF
				fi
				echo "-------------------------------------------------------------------------------------"
				echo "-------------------------------------------------------------------------------------"
				cat <<-'EOF'
						do you wish to launch minimal Linux (initramfs is required - lab3 - opt2) ?
						
						0. No, return to the lab3 menu.
						1. Yes, launch minimal Linux with QEMU.
						2. yes, launch minimal Linux with QEMU and attach the SD card image (transfer.img) to it.
						EOF
				read -p "------------------------Enter your choice (0, 1 or 2):---------------------------" launch_choice
				if [[ "$launch_choice" == [0] ]]; then
					clear
					echo "Exiting lab3."
					sleep 3
					STAY="false"
					
				elif [[ "$launch_choice" == [1] ]]; then
					STAY="false"
					clear
					cd ~/projects/embedded/lab3
					qemu-system-arm \
					-M vexpress-a15 \
					-cpu cortex-a15 \
					-m 512 \
					-nographic \
					-kernel build-arm/arch/arm/boot/zImage \
					-dtb build-arm/arch/arm/boot/dts/arm/vexpress-v2p-ca15-tc1.dtb \
					-initrd initramfs.cpio.gz \
					-append "console=ttyAMA0 rdinit=${INIT_PATH}"

				elif [[ "$launch_choice" == [2] ]]; then
					clear
					STAY="false"
					cd ~/projects/embedded/lab3
					qemu-system-arm \
					-M vexpress-a15 \
					-cpu cortex-a15 \
					-m 512 \
					-nographic \
					-kernel build-arm/arch/arm/boot/zImage \
					-dtb build-arm/arch/arm/boot/dts/arm/vexpress-v2p-ca15-tc1.dtb \
					-initrd initramfs.cpio.gz \
					-drive file=/home/lidor/projects/embedded/lab3/transfer.img,format=raw,if=sd \
					-append "console=ttyAMA0 rdinit=${INIT_PATH}"		
				else
					echo "Invalid choice, returning to the lab3 menu."
				fi

		else
				echo "Invalid choice, returning to the terminal prompt."
		fi
done
}
	

clear
echo   "-------------------------------------------------------------------------------------------------"
echo   "               This script can preform the following tasks :                                     "
echo   "                                                                                 		         "
echo   "                                                                                     			 "
echo   "     0. to exit the script and return to the terminal prompt.                        			 "
echo   "                                                                                     			 "
echo   "     1. install the required packages for qemu and arm development                   			 "
echo   "                                                                                     			 "
echo   "     2. create_arm_machine with the required startup.s and linker.ld & boot.elf image (lab2 pt.1)"
echo   "                                                                                     			 "
echo   "     3. run the qemu emulator and gdb multiarch debugger (lab2 pt.2                  		     "
echo   "                                                                                     			 "
echo   "     4. build the linux kernel and busybox ( lab3 )                                  			 "
echo   "                                                                                     			 "
echo   "                                                                                     			 "
echo   "      				 This 'Bash' script was created by eenylidor(Github) 	                     "
echo   "                                                                                     			 "
echo   "------------------------Enter your choice (0, 1, 2, 3 or 4):-------------------------------------"
read choice

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
elif [[ "$choice" == [4] ]]; then
	clear
	echo "Starting lab3..."
	sleep 3
	lab3
else
	echo "-------------------------------------------------------------------------------------"
	echo "                 Invalid choice, returning to the terminal prompt.                   "
	echo "-------------------------------------------------------------------------------------"
fi







