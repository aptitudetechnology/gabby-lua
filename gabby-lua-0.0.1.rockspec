package = "gabby-lua"
version = "0.0.1-1"
source = {
  url = "git+https://github.com/aptitudetechnology/gabby-lua.git",
  tag = "v0.0.1"
}
description = {
  summary = "Gabby Lua library",
  detailed = [[
    Gabby Lua is a library for ... (add a more detailed description here)
  ]],
  homepage = "https://github.com/aptitudetechnology/gabby-lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["gabby.main"] = "main.lua",
    ["gabby.logger"] = "logger.lua",
    ["gabby.message_listener"] = "message_listener.lua",
    ["gabby.message_writer"] = "message_writer.lua",
    ["gabby.discovery_service"] = "discovery_service.lua"
  }
}
