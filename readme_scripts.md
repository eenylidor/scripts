ready_python.sh
This script automates the setup of a complete Python engineering environment on a fresh Ubuntu or WSL instance. It handles the PEP 668 "externally managed environment" restriction by using apt to install NumPy, Pandas, and Matplotlib safely at the system level. Additionally, it configures the ipykernel for Jupyter Notebooks and triggers the installation of essential VS Code extensions (Python, Jupyter, and Remote-WSL) via the command line to ensure your IDE is ready for data analysis immediately.

Usage: ./ready_python.sh

Example: Run this once after a fresh WSL install to skip manual configuration of math libraries and IDE plugins.



mkgen
A dedicated project generator that streamlines the creation of C/C++ development environments, specifically optimized for embedded systems labs. When provided with a source file, it automatically generates a professional Makefile configured for both native x86 execution and ARM cross-compilation using arm-linux-gnueabihf-gcc. It also creates a localized README.md within the project folder that documents common build targets like make build, make run-arm, and make clean.

Usage: mkgen <filename.c>

Example: mkgen exercise1.c will wrap your code in a full build system so you can start testing on ARM immediately.



init_qemu.sh
This utility script initializes the QEMU user-mode emulation environment required to run ARM binaries on an x86_64 host (like your Windows laptop). It checks for the necessary emulation binaries and ensures the system is capable of executing cross-compiled code without needing physical ARM hardware. This is a critical piece of the workflow for testing firmware or embedded Linux applications that were built using the mkgen tool.

Usage: ./init_qemu.sh

Example: Run this before attempting make run-arm in any of your project folders to ensure the emulation layer is active.
