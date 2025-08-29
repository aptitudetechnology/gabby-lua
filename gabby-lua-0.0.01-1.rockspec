package = "gabby-lua"
version = "0.0.01-1"
source = {
   url = "file://",
   dir = "."
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
      ["gabby.config"] = "config.lua",
      ["gabby.discovery"] = "discovery_service.lua",
      ["gabby.listener"] = "message_listener.lua",
      ["gabby.writer"] = "message_writer.lua"
   },
   copy_directories = { "gofiles" }
}


