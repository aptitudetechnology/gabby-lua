#!/bin/bash
# install-dependencies.sh
# Installs required Lua dependencies for Gabby

set -e

# Update package lists
sudo apt-get update

# Install Lua and LuaRocks if not present
sudo apt-get install -y lua5.3 luarocks

# Install LuaSocket
sudo luarocks install luasocket

# Install lua-cjson
sudo luarocks install lua-cjson

echo "All dependencies installed successfully."
