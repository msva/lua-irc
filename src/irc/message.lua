-- initialization {{{
local base =      _G
local constants = require 'irc.constants'
local ctcp =      require 'irc.ctcp'
local irc_debug = require 'irc.debug'
local misc =      require 'irc.misc'
local socket =    require 'socket'
local string =    require 'string'
local table =     require 'table'
-- }}}

module 'irc.message'

-- local functions {{{
-- parse() - parse a server command {{{
function parse(str)
    -- low-level ctcp quoting {{{
    str = ctcp.low_dequote(str)
    -- }}}
    -- parse the from field, if it exists (leading :) {{{
    local from = ""
    if str:sub(1, 1) == ":" then
        local e
        e, from = socket.skip(1, str:find("^:([^ ]*) "))
        str = str:sub(e + 1)
    end
    -- }}}
    -- get the command name or numerical reply value {{{
    local command, argstr = socket.skip(2, str:find("^([^ ]*) ?(.*)"))
    local reply = false
    if command:find("^%d%d%d$") then
        reply = true
        if constants.replies[base.tonumber(command)] then
            command = constants.replies[base.tonumber(command)]
        else
            irc_debug.warn("Unknown server reply: " .. command)
        end
    end
    -- }}}
    -- get the args {{{
    local args = misc.split(argstr, " ", ":")
    -- the first arg in a reply is always your nick
    if reply then table.remove(args, 1) end
    -- }}}
    -- return the parsed message {{{
    return {from = from, command = command, args = args}
    -- }}}
end
-- }}}
-- }}}
