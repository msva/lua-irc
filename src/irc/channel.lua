---
-- Implementation of the Channel class

-- initialization {{{
local base =   _G
local irc =    require 'irc'
local misc =   require 'irc.misc'
local socket = require 'socket'
local table =  require 'table'
-- }}}

---
-- This module implements a channel object representing a single channel we
-- have joined
-- @release 0.02
module 'irc.channel'

-- object metatable {{{
-- TODO: this <br /> shouldn't be necessary - bug in luadoc
---
-- An object of the Channel class represents a single joined channel. It has
-- several table fields, and can be used in string contexts (returning the
-- channel name).<br />
-- @class table
-- @name Channel
-- @field name     Name of the channel (read only)
-- @field topic    Channel topic, if set (read/write, writing to this sends a
--                 topic change request to the server for this channel)
-- @field chanmode Channel mode (public/private/secret) (read only)
-- @field members  Array of all members of this channel
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
-- set_basic_mode {{{
--
-- Sets a no-arg mode on a channel.
-- @name chan:set_basic_mode
-- @param self   Channel object
-- @param set    True to set the mode, false to unset it
-- @param letter Letter of the mode
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
---
-- Creates a new Channel object.
-- @param chan Name of the new channel
-- @return The new channel instance
function new(chan)
    return base.setmetatable({_name = chan, _topic = {}, _chanmode = "",
                              _members = {}}, mt)
end
-- }}}

-- public methods {{{
-- iterators {{{
-- each_op {{{
---
-- Iterator over the ops in the channel
-- @param self Channel object
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

-- each_voice {{{
---
-- Iterator over the voiced users in the channel
-- @param self Channel object
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

-- each_user {{{
---
-- Iterator over the normal users in the channel
-- @param self Channel object
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

-- each_member {{{
---
-- Iterator over all users in the channel
-- @param self Channel object
function each_member(self)
    return misc.value_iter, self._members, nil
end
-- }}}
-- }}}

-- return tables of users {{{
-- ops {{{
---
-- Gets an array of all the ops in the channel.
-- @param self Channel object
-- @return Array of channel ops
function ops(self)
    local ret = {}
    for nick in self:each_op() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- voices {{{
---
-- Gets an array of all the voiced users in the channel.
-- @param self Channel object
-- @return Array of channel voiced users
function voices(self)
    local ret = {}
    for nick in self:each_voice() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- users {{{
---
-- Gets an array of all the normal users in the channel.
-- @param self Channel object
-- @return Array of channel normal users
function users(self)
    local ret = {}
    for nick in self:each_user() do
        table.insert(ret, nick)
    end
    return ret
end
-- }}}

-- members {{{
---
-- Gets an array of all the users in the channel.
-- @param self Channel object
-- @return Array of channel users
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
