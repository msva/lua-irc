-- initialization {{{
local base = _G
local table = require "table"
-- }}}

module "irc.ctcp"

-- public functions {{{
-- low_quote {{{
-- applies low level quoting to a string (escaping characters which
-- are illegal to appear in an irc packet)
function low_quote(str)
    return str:gsub("[%z\n\r\020]", {["\000"] = "\0200",
                                     ["\n"]   = "\020n",
                                     ["\r"]   = "\020r",
                                     ["\020"] = "\020\020"})
end
-- }}}

-- low_dequote {{{
-- removes low level quoting done by low_quote
function low_dequote(str)
    return str:gsub("\020(.?)", function(s)
                                    if s == "0" then return "\000" end
                                    if s == "n" then return "\n" end
                                    if s == "r" then return "\r" end
                                    if s == "\020" then return "\020" end
                                    return ""
                                end)
end
-- }}}

-- ctcp_quote {{{
-- applies ctcp quoting to a block of text which has been identified
-- as ctcp data (by the calling program)
function ctcp_quote(str)
    local ret = str:gsub("[\001\\]", {["\001"] = "\\a",
                                      ["\\"]   = "\\\\"})
    return "\001" .. ret .. "\001"
end
-- }}}

-- ctcp_dequote {{{
-- removes ctcp quoting from a block of text which has been
-- identified as ctcp data (likely by ctcp_split)
function ctcp_dequote(str)
    local ret = str:gsub("^\001", ""):gsub("\001$", "")
    return ret:gsub("\\(.?)", function(s)
                                  if s == "a" then return "\001" end
                                  if s == "\\" then return "\\" end
                                  return ""
                              end)
end
-- }}}

-- ctcp_split {{{
-- takes in a mid_level (low level dequoted) string and splits it
-- up into normal text and ctcp messages. it returns an array, where string
-- values correspond to plain text and table values have t[1] as the ctcp
-- message. if dequote is true, each ctcp message will also be ctcp dequoted.
function ctcp_split(str, dequote)
    local ret = {}
    local iter = 1
    while true do
        local s, e = str:find("\001.*\001", iter)

        local plain_string, ctcp_string
        if not s then
            plain_string = str:sub(iter, -1)
        else
            plain_string = str:sub(iter, s - 1)
            ctcp_string = str:sub(s, e)
        end

        if plain_string ~= "" then
            table.insert(ret, plain_string)
        end
        if not s then break end
        if ctcp_string ~= "" then
            if dequote then
                table.insert(ret, {ctcp_dequote(ctcp_string)})
            else
                table.insert(ret, {ctcp_string})
            end
        end

        iter = e + 1
    end

    return ret
end
-- }}}
-- }}}
