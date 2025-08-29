package = "gabby-lua"
version = "0.0.01-1"
source = {
   url = "file://",
   dir = "."
}
package = "gabby-lua"
version = "0.1.0-1"
source = {
   url = "https://github.com/aptitudetechnology/gabby-lua/archive/refs/tags/v0.1.0.tar.gz",
   dir = "gabby-lua-0.1.0"
}
description = {
   summary = "GabbyLua - P2P Chat with UDP Discovery (Development Version)",
   detailed = [[
      GabbyLua is a work-in-progress P2P chat application featuring:
      - UDP broadcast peer discovery
      - Basic TCP messaging
      - JSON message format
      - Non-blocking I/O architecture
      - Simple CLI interface
   ]],
   homepage = "https://github.com/aptitudetechnology/gabby-lua",
   license = "MIT"
}
dependencies = {
   "lua >=5.1, <5.5",
   "lua-cjson ~=2.1",
   "luasocket ~=3.0"
}
build = {
   type = "builtin",
   modules = {
      ["config"] = "config.lua",
      ["discovery_service"] = "discovery_service.lua",
      ["message_listener"] = "message_listener.lua",
      ["message_writer"] = "message_writer.lua"
   },
   copy_directories = { "gofiles" }
}


