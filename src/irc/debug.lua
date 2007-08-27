-- initialization {{{
local base = _G
local io =   require 'io'
-- }}}

module 'irc.debug'

-- defaults {{{
COLOR = true
-- }}}

-- local variables {{{
local ON = false
local outfile = io.output()
-- }}}

-- public functions {{{
-- enable {{{
function enable()
    ON = true
end
-- }}}

-- disable {{{
function disable()
    ON = false
end
-- }}}

-- set_output {{{
function set_output(file)
    outfile = base.assert(io.open(file))
end
-- }}}

-- message {{{
function message(msg_type, msg, color)
    if ON then
        local endcolor = ""
        if COLOR then
            color = color or "\027[1;30m"
            endcolor = "\027[0m"
        else
            color = ""
            endcolor = ""
        end
        outfile:write(color .. msg_type .. ": " .. msg .. endcolor .. "\n")
    end
end
-- }}}

-- err {{{
function err(msg)
    message("ERR", msg, "\027[0;31m")
    base.error(msg, 2)
end
-- }}}

-- warn {{{
function warn(msg)
    message("WARN", msg, "\027[0;33m")
end
-- }}}
-- }}}
