#!/bin/bash
VERSION=2.1.0.3_beta_2025-01-22

cleanup() {
  rm -f duplicati-*.deb duplicati-*.rpm
}

# Run cleanup function on EXIT
trap cleanup EXIT

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif [ -f /etc/system-release ]; then
    if grep -q "Amazon Linux" /etc/system-release; then
        OS="amzn"
    else
        OS="unknown"
    fi
else
    OS="unknown"
fi

echo "Detected OS: $OS"

# Install based on distribution
if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ] || [ "$OS" == "centos" ] || [ "$OS" == "fedora" ]; then
    # For Amazon Linux and other RPM-based systems
    echo "Installing for Amazon Linux / RPM-based system"
    wget https://updates.duplicati.com/beta/duplicati-$VERSION-linux-x64-gui.rpm
    sudo yum -y install mono-core
    sudo rpm -ivh duplicati-*.rpm
else
    # Default to Debian-based installation
    echo "Installing for Debian-based system"
    wget https://updates.duplicati.com/beta/duplicati-$VERSION-linux-x64-gui.deb
    sudo apt-get update
    sudo apt-get -y install mono-runtime
    sudo dpkg -i duplicati-*.deb
    # Handle dependencies
    sudo apt-get -y -f install
fi

echo "Duplicati installation completed"