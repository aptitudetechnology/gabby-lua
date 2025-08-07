#!/bin/bash
# install-dependencies.sh
# Installs required Lua dependencies for Gabby

set -e

# Update package lists
sudo apt-get update


# Install Lua, LuaRocks, and Lua dev headers if not present
sudo apt-get install -y lua5.3 luarocks liblua5.3-dev

# Install LuaSocket and lua-cjson for Lua 5.3
sudo luarocks install luasocket --lua-version=5.3
sudo luarocks install lua-cjson --lua-version=5.3

echo "All dependencies installed successfully."
echo
echo "IMPORTANT: To run your Lua scripts with LuaRocks modules, use:"
echo '  eval "$(luarocks path --bin --lua-version=5.3)"'
echo '  lua main.lua'
