#!/usr/bin/env bash

# This script prepares a Linux/WSL environment for Engineering & Data Analysis.
# Updated for PEP 668 compliance (Ubuntu 24.04+).

echo "🚀 Initializing Engineering Environment Setup..."

# 1. Update the system package manager
echo "📦 Updating system repositories..."
sudo apt update && sudo apt upgrade -y

# 2. Install Python, Pip, and Venv
echo "🐍 Installing Python3, Pip, and Venv..."
sudo apt install -y python3 python3-pip python3-venv

# 3. Install Engineering Libraries via APT (The "Safe" Way)
# This avoids the 'externally-managed-environment' error.
echo "📊 Installing NumPy, Pandas, Matplotlib, and Jupyter Kernel..."
sudo apt install -y \
    python3-numpy \
    python3-pandas \
    python3-matplotlib \
    python3-ipykernel

# 4. Automate VS Code Extension Setup
if command -v code >/dev/null 2>&1; then
    echo "💻 Syncing VS Code Extensions..."
    code --install-extension ms-python.python
    code --install-extension ms-toolsai.jupyter
    code --install-extension ms-vscode-remote.remote-wsl
else
    echo "⚠️  VS Code binary not found in PATH."
fi

echo "---"
echo "✅ SETUP COMPLETE!"
echo "💡 Note: The base math stack is now installed system-wide via apt."
echo "💡 For specific projects, still use: 'python3 -m venv .venv'"