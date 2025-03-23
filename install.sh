#!/bin/bash
BASE_URL="https://github.com/duplicati/duplicati/releases/download/v2.1.0.5_stable_2025-03-04/duplicati-2.1.0.5_stable_2025-03-04"

cleanup() {
  rm -f duplicati-*.deb duplicati-*.rpm
}

# Run cleanup function on EXIT
trap cleanup EXIT

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=${VERSION_ID}
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
    
    # Add mono repository if needed
    if [ "$OS" == "fedora" ]; then
        sudo rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
        sudo dnf config-manager --add-repo https://download.mono-project.com/repo/centos8-stable.repo
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
        sudo rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
        if [ "$VERSION_ID" == "7" ]; then
            sudo yum-config-manager --add-repo https://download.mono-project.com/repo/centos7-stable.repo
        else
            sudo yum-config-manager --add-repo https://download.mono-project.com/repo/centos8-stable.repo
        fi
    elif [ "$OS" == "amzn" ]; then
        sudo rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
        sudo yum-config-manager --add-repo https://download.mono-project.com/repo/centos7-stable.repo
    fi
    
    # Install Mono and libicu dependencies
    if [ "$OS" == "fedora" ]; then
        sudo dnf -y install mono-complete libicu
    else
        sudo yum -y install mono-complete libicu
    fi
    
    # Download and install Duplicati
    wget "$BASE_URL-linux-x64-cli.rpm"
    
    if [ "$OS" == "fedora" ]; then
        sudo dnf -y install duplicati-*.rpm
    else
        sudo yum -y install duplicati-*.rpm
    fi
else
    # Default to Debian-based installation
    echo "Installing for Debian-based system"
    wget "$BASE_URL-linux-x64-cli.deb"
    sudo apt-get update
    sudo apt-get -y install mono-runtime libmono-2.0-1
    sudo dpkg -i duplicati-*.deb
    # Handle dependencies
    sudo apt-get -y -f install
fi

echo "Duplicati installation completed"

echo "Testing Duplicati installation"
duplicati-cli --version
if [ $? -ne 0 ]; then
    echo "Duplicati installation failed"
    exit 1
fi