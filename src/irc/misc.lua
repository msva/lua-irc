-- initialization {{{
local base =      _G
local irc_debug = require 'irc.debug'
local socket =    require 'socket'
local math =      require 'math'
local os =        require 'os'
local string =    require 'string'
local table =     require 'table'
-- }}}

module 'irc.misc'

-- defaults {{{
DELIM = ' '
PATH_SEP = '/'
ENDIANNESS = "big"
INT_BYTES = 4
-- }}}

-- private functions {{{
local function exists(filename)
    local _, err = os.rename(filename, filename)
    if not err then return true end
    return not err:find("No such file or directory")
end
-- }}}

-- public functions {{{
-- split() - splits str into substrings based on several options {{{
function split(str, delim, end_delim, lquotes, rquotes)
    -- handle arguments {{{
    delim = "["..(delim or DELIM).."]"
    if end_delim then end_delim = "["..end_delim.."]" end
    if lquotes then lquotes = "["..lquotes.."]" end
    if rquotes then rquotes = "["..rquotes.."]" end
    local optdelim = delim .. "?"
    -- }}}

    local ret = {}
    local instring = false
    while str:len() > 0 do
        -- handle case for not currently in a string {{{
        if not instring then
            local end_delim_ind, lquote_ind, delim_ind
            if end_delim then end_delim_ind = str:find(optdelim..end_delim) end
            if lquotes then lquote_ind = str:find(optdelim..lquotes) end
            local delim_ind = str:find(delim)
            if not end_delim_ind then end_delim_ind = str:len() + 1 end
            if not lquote_ind then lquote_ind = str:len() + 1 end
            if not delim_ind then delim_ind = str:len() + 1 end
            local next_ind = math.min(end_delim_ind, lquote_ind, delim_ind)
            if next_ind == str:len() + 1 then
                table.insert(ret, str)
                break
            elseif next_ind == end_delim_ind then
                -- TODO: hackish here
                if str:sub(next_ind, next_ind) == end_delim:gsub('[%[%]]', '') then
                    table.insert(ret, str:sub(next_ind + 1))
                else
                    table.insert(ret, str:sub(1, next_ind - 1))
                    table.insert(ret, str:sub(next_ind + 2))
                end
                break
            elseif next_ind == lquote_ind then
                table.insert(ret, str:sub(1, next_ind - 1))
                str = str:sub(next_ind + 2)
                instring = true
            else -- last because the top two contain it
                table.insert(ret, str:sub(1, next_ind - 1))
                str = str:sub(next_ind + 1)
            end
        -- }}}
        -- handle case for currently in a string {{{
        else
            local endstr = str:find(rquotes..optdelim)
            table.insert(ret, str:sub(1, endstr - 1))
            str = str:sub(endstr + 2)
            instring = false
        end
        -- }}}
    end
    return ret
end
-- }}}

-- basename() - returns the basename of a file {{{
function basename(path, sep)
    sep = sep or PATH_SEP
    if not path:find(sep) then return path end
    return socket.skip(2, path:find(".*" .. sep .. "(.*)"))
end
-- }}}

-- dirname() - returns the dirname of a file {{{
function dirname(path, sep)
    sep = sep or PATH_SEP
    if not path:find(sep) then return "." end
    return socket.skip(2, path:find("(.*)" .. sep .. ".*"))
end
-- }}}

-- str_to_int() - converts a number to a low-level int {{{
function str_to_int(str, bytes, endian)
    bytes = bytes or INT_BYTES
    endian = endian or ENDIANNESS
    local ret = ""
    for i = 0, bytes - 1 do 
        local new_byte = string.char(math.fmod(str / (2^(8 * i)), 256))
        if endian == "big" or endian == "network" then ret = new_byte .. ret
        else ret = ret .. new_byte
        end
    end
    return ret
end
-- }}}

-- int_to_str() - converts a low-level int to a number {{{
function int_to_str(int, endian)
    endian = endian or ENDIANNESS
    local ret = 0
    for i = 1, int:len() do
        if endian == "big" or endian == "network" then ind = int:len() - i + 1
        else ind = i
        end
        ret = ret + string.byte(int:sub(ind, ind)) * 2^(8 * (i - 1))
    end
    return ret
end
-- }}}

-- ip_str_to_int() - converts a string ip address to an int {{{
function ip_str_to_int(ip_str)
    local i = 3
    local ret = 0
    for num in ip_str:gmatch("%d+") do
        ret = ret + num * 2^(i * 8)                  
        i = i - 1
    end
    return ret
end
-- }}}

-- ip_int_to_str() - converts an int to a string ip address {{{
function ip_int_to_str(ip_int)
    local ip = {}
    for i = 3, 0, -1 do
        local new_num = math.floor(ip_int / 2^(i * 8))
        table.insert(ip, new_num)
        ip_int = ip_int - new_num * 2^(i * 8)
    end 
    return table.concat(ip, ".")
end
-- }}}

-- get_unique_filename() - returns a unique filename {{{
function get_unique_filename(filename)
    if not exists(filename) then return filename end

    local count = 1
    while true do
        if not exists(filename .. "." .. count) then
            return filename .. "." .. count
        end
        count = count + 1
    end
end
-- }}}

-- try_call() - call a function, if it exists {{{
function try_call(fn, ...)
    if base.type(fn) == "function" then
        return fn(...)
    end
end
-- }}}

-- try_call_warn() - same as try_call, but complain if not {{{
function try_call_warn(msg, fn, ...)
    if base.type(fn) == "function" then
        return fn(...)
    else
        irc_debug.warn(msg)
    end
end
-- }}}

-- parse_user() - gets the various parts of a full username {{{
-- args: user - usermask (i.e. returned in the from field of a callback)
-- return: nick, username, hostname (these can be nil if nonexistant)
function parse_user(user)
    local found, bang, nick = user:find("^([^!]*)!")
    if found then 
        user = user:sub(bang + 1)
    else
        return user
    end
    local found, equals = user:find("^.=")
    if found then
        user = user:sub(3)
    end
    local found, at, username = user:find("^([^@]*)@")
    if found then
        return nick, username, user:sub(at + 1)
    else
        return nick, user
    end
end
-- }}}

-- value_iter() - iterate just over values of a table {{{
function value_iter(state, arg, pred)
    for k, v in base.pairs(state) do
        if arg == v then arg = k end
    end
    local key, val = base.next(state, arg)
    if not key then return end

    if base.type(pred) == "function" then
        while not pred(val) do
            key, val = base.next(state, key)
            if not key then return end
        end
    end
    return val
end
-- }}}
-- }}}
