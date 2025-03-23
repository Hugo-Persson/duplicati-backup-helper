#!/bin/bash
VERSION=2.1.0.3_beta_2025-01-22

cleanup() {
  rm duplicati-*.deb
}

# Run cleanup function on EXIT
trap cleanup EXIT
wget https://updates.duplicati.com/beta/duplicati-$VERSION-linux-x64-gui.deb
dpkg -i duplicati-*.deb
