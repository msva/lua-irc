---
-- Implementation of the CTCP protocol
-- initialization {{{
local base = _G
local table = require "table"
-- }}}

---
-- This module implements the various quoting and escaping requirements of the
-- CTCP protocol.
module "irc.ctcp"

-- internal functions {{{
-- _low_quote {{{
--
-- Applies low level quoting to a string (escaping characters which are illegal
-- to appear in an IRC packet).
-- @param str String to quote
-- @return Quoted string
function _low_quote(str)
    return str:gsub("[%z\n\r\020]", {["\000"] = "\0200",
                                     ["\n"]   = "\020n",
                                     ["\r"]   = "\020r",
                                     ["\020"] = "\020\020"})
end
-- }}}

-- _low_dequote {{{
--
-- Removes low level quoting done by low_quote.
-- @param str String with low level quoting applied to it
-- @return String with those quoting methods stripped off
function _low_dequote(str)
    return str:gsub("\020(.?)", function(s)
                                    if s == "0" then return "\000" end
                                    if s == "n" then return "\n" end
                                    if s == "r" then return "\r" end
                                    if s == "\020" then return "\020" end
                                    return ""
                                end)
end
-- }}}

-- _ctcp_quote {{{
--
-- Applies CTCP quoting to a block of text which has been identified as CTCP
-- data (by the calling program).
-- @param str String to apply CTCP quoting to
-- @return String with CTCP quoting applied
function _ctcp_quote(str)
    local ret = str:gsub("[\001\\]", {["\001"] = "\\a",
                                      ["\\"]   = "\\\\"})
    return "\001" .. ret .. "\001"
end
-- }}}

-- _ctcp_dequote {{{
--
-- Removes CTCP quoting from a block of text which has been identified as CTCP
-- data (likely by ctcp_split).
-- @param str String with CTCP quoting
-- @return String with all CTCP quoting stripped
function _ctcp_dequote(str)
    local ret = str:gsub("^\001", ""):gsub("\001$", "")
    return ret:gsub("\\(.?)", function(s)
                                  if s == "a" then return "\001" end
                                  if s == "\\" then return "\\" end
                                  return ""
                              end)
end
-- }}}

-- _ctcp_split {{{
-- TODO: again with this string/table thing... it's ugly!
--
-- Splits a low level dequoted string into normal text and unquoted CTCP
-- messages.
-- @param str Low level dequoted string
-- @return Array, where string values correspond to plain text, and table
--         values have t[1] as the CTCP message
function _ctcp_split(str)
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
            table.insert(ret, {_ctcp_dequote(ctcp_string)})
        end

        iter = e + 1
    end

    return ret
end
-- }}}
-- }}}
