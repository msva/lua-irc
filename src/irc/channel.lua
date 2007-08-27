-- initialization {{{
local base =   _G
local irc =    require 'irc'
local misc =   require 'irc.misc'
local socket = require 'socket'
local table =  require 'table'
-- }}}

module 'irc.channel'

-- object metatable {{{
local mt = {
    -- __index() {{{
    __index =    function(self, key)
                     if key == "name" then
                         return self._name
                     elseif key == "topic" then
                         return self._topic
                     elseif key == "chanmode" then
                         return self._chanmode
                     else
                         return _M[key]
                     end
                 end,
    -- }}}
    -- __newindex() {{{
    __newindex = function(self, key, value)
                     if key == "name" then
                         return
                     elseif key == "topic" then
                         irc.send("TOPIC", self._name, value)
                     elseif key == "chanmode" then
                         return
                     else
                         base.rawset(self, key, value)
                     end
                 end,
    -- }}}
    -- __concat() {{{
    __concat =   function(first, second)
                     local first_str, second_str

                     if base.type(first) == "table" then
                         first_str = first._name
                     else
                         first_str = first
                     end
                     if base.type(second) == "table" then
                         second_str = second._name
                     else
                         second_str = second
                     end

                     return first_str .. second_str
                 end,
    -- }}}
    -- __tostring() {{{
    __tostring = function(self)
                     return self._name
                 end
    -- }}}
}
-- }}}

-- private methods {{{
-- set_basic_mode() - sets a no-arg mode on a channel {{{
local function set_basic_mode(self, set, letter)
    if set then
        irc.send("MODE", self.name, "+" .. letter)
    else
        irc.send("MODE", self.name, "-" .. letter)
    end
end
-- }}}
-- }}}

-- constructor {{{
function new(chan)
    return base.setmetatable({_name = chan, _topic = {}, _chanmode = "",
                              _members = {}}, mt)
end
-- }}}

-- public methods {{{
-- iterators {{{
-- each_op() {{{
function each_op(self)
    return function(state, arg)
               return misc.value_iter(state, arg,
                                      function(v)
                                          return v:sub(1, 1) == "@"
                                      end)
           end,
           self._members,
           nil
end
-- }}}

-- each_voice() {{{
function each_voice(self)
    return function(state, arg)
               return misc.value_iter(state, arg,
                                      function(v)
                                          return v:sub(1, 1) == "+"
                                      end)
           end,
           self._members,
           nil
end
-- }}}

-- each_user() {{{
function each_user(self)
    return function(state, arg)
               return misc.value_iter(state, arg,
                                      function(v)
                                          return v:sub(1, 1) ~= "@" and
                                                 v:sub(1, 1) ~= "+"
                                      end)
           end,
           self._members,
           nil
end
-- }}}

-- each_member() {{{
function each_member(self)
    return misc.value_iter, self._members, nil
end
-- }}}
-- }}}

-- return tables of users {{{
-- ops() {{{
function ops(self)
    local ret = {}
    for nick in self:each_op() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- voices() {{{
function voices(self)
    local ret = {}
    for nick in self:each_voice() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- users() {{{
function users(self)
    local ret = {}
    for nick in self:each_user() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- members() {{{
function members(self)
    local ret = {}
    -- not just returning self._members, since the return value shouldn't be
    -- modifiable
    for nick in self:each_member() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}
-- }}}

-- setting modes {{{
-- ban() - ban a user from a channel {{{
-- TODO: hmmm, this probably needs an appropriate mask, rather than a nick
function ban(self, name)
    irc.send("MODE", self.name, "+b", name)
end
-- }}}

-- unban() - remove a ban on a user {{{
-- TODO: same here
function unban(self, name)
    irc.send("MODE", self.name, "-b", name)
end
-- }}}

-- voice() - give a user voice on a channel {{{
function voice(self, name)
    irc.send("MODE", self.name, "+v", name)
end
-- }}}

-- devoice() - remove voice from a user {{{
function devoice(self, name)
    irc.send("MODE", self.name, "-v", name)
end
-- }}}

-- op() - give a user ops on a channel {{{
function op(self, name)
    irc.send("MODE", self.name, "+o", name)
end
-- }}}

-- deop() - remove ops from a user {{{
function deop(self, name)
    irc.send("MODE", self.name, "-o", name)
end
-- }}}

-- set_limit() - set a channel limit {{{
function set_limit(self, new_limit)
    if new_limit then
        irc.send("MODE", self.name, "+l", new_limit)
    else
        irc.send("MODE", self.name, "-l")
    end
end
-- }}}

-- set_key() - set a channel password {{{
function set_key(self, key)
    if key then
        irc.send("MODE", self.name, "+k", key)
    else
        irc.send("MODE", self.name, "-k")
    end
end
-- }}}

-- set_private() - set the private state of a channel {{{
function set_private(self, set)
    set_basic_mode(self, set, "p")
end
-- }}}

-- set_secret() - set the secret state of a channel {{{
function set_secret(self, set)
    set_basic_mode(self, set, "s")
end
-- }}}

-- set_invite_only() - set whether joining the channel requires an invite {{{
function set_invite_only(self, set)
    set_basic_mode(self, set, "i")
end
-- }}}

-- set_topic_lock() - if true, the topic can only be changed by an op {{{
function set_topic_lock(self, set)
    set_basic_mode(self, set, "t")
end
-- }}}

-- set_no_outside_messages() - if true, users must be in the channel to send messages to it {{{
function set_no_outside_messages(self, set)
    set_basic_mode(self, set, "n")
end
-- }}}

-- set moderated() - set whether voice is required to speak {{{
function set_moderated(self, set)
    set_basic_mode(self, set, "m")
end
-- }}}
-- }}}

-- accessors {{{
-- add_user() {{{
function add_user(self, user, mode)
    mode = mode or ''
    self._members[user] = mode .. user
end
-- }}}

-- remove_user() {{{
function remove_user(self, user)
    self._members[user] = nil
end
-- }}}

-- change_status() {{{
function change_status(self, user, on, mode)
    if on then
        if mode == 'o' then
            self._members[user] = '@' .. user
        elseif mode == 'v' then
            self._members[user] = '+' .. user
        end
    else
        if (mode == 'o' and self._members[user]:sub(1, 1) == '@') or
           (mode == 'v' and self._members[user]:sub(1, 1) == '+') then
            self._members[user] = user
        end
    end
end
-- }}}

-- contains() {{{
function contains(self, nick)
    for member in self:each_member() do
        local member_nick = member:gsub('@+', '')
        if member_nick == nick then
            return true
        end
    end
    return false
end
-- }}}

-- change_nick {{{
function change_nick(self, old_nick, new_nick)
    for member in self:each_member() do
        local member_nick = member:gsub('@+', '')
        if member_nick == old_nick then
            local mode = self._members[old_nick]:sub(1, 1)
            if mode ~= '@' and mode ~= '+' then mode = "" end
            self._members[old_nick] = nil
            self._members[new_nick] = mode .. new_nick
            break
        end
    end
end
-- }}}
-- }}}
-- }}}
