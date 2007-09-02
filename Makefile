LUADOC = luadoc
LUA_DIR = /usr/local/share/lua/5.1
MOD_DIR = $(LUA_DIR)/irc
DOC_DIR = doc
MAIN_LUA = src/irc.lua
MOD_LUAS = src/irc/channel.lua \
           src/irc/constants.lua \
           src/irc/ctcp.lua \
           src/irc/dcc.lua \
           src/irc/debug.lua \
           src/irc/message.lua \
           src/irc/misc.lua

build :

install :
	mkdir -p $(LUA_DIR)
	cp $(MAIN_LUA) $(LUA_DIR)
	mkdir -p $(MOD_DIR)
	cp $(MOD_LUAS) $(MOD_DIR)

doc : $(MAIN_LUA) $(MOD_LUAS)
	mkdir -p $(DOC_DIR)
	$(LUADOC) --nofiles -d $(DOC_DIR) $(MAIN_LUA) $(MOD_LUAS)

clean :
	rm -rf $(DOC_DIR)
