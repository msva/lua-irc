#!/usr/bin/env lua

local irc = require 'irc'
irc.DEBUG = true

local nick = "luabot"
local pre_code = [[
io = nil
os = nil
loadfile = nil
dofile = nil
package = nil
require = nil
module = nil
debug = nil
]]

irc.register_callback("connect", function()
    irc.join("#doytest")
end)

irc.register_callback("channel_msg", function(channel, from, message)
    local for_me, code = message:match("^(" .. nick .. ". )(.*)")
    if for_me then
        code = code:gsub("^=", "return ")
        local fn, err = loadstring(pre_code .. code)
        if not fn then
            irc.say(channel.name, from .. ": Error loading code: " .. err)
            return
        else
            local result = {pcall(fn)}
            local success = table.remove(result, 1)
            if not success then
                irc.say(channel.name, from .. ": Error running code: " .. result[1])
            else
                irc.say(channel.name, from .. ": " .. table.concat(result, ", "))
            end
        end
    end
end)

irc.connect{network = "irc.freenode.net", nick = nick}
