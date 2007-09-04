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
TEST_LUAS = test/test.lua
VERSION = $(shell grep '^_VERSION =' $(MAIN_LUA) | sed "s/_VERSION = '\(.*\)'/\1/" | tr ' ' '-')

build :

install :
	mkdir -p $(LUA_DIR)
	cp $(MAIN_LUA) $(LUA_DIR)
	mkdir -p $(MOD_DIR)
	cp $(MOD_LUAS) $(MOD_DIR)

doc : $(MAIN_LUA) $(MOD_LUAS)
	mkdir -p $(DOC_DIR)
	$(LUADOC) --nofiles -d $(DOC_DIR) $(MAIN_LUA) $(MOD_LUAS)
	@touch doc

clean :
	rm -rf $(DOC_DIR)

dist : $(VERSION).tar.gz

$(VERSION).tar.gz : $(MAIN_LUA) $(MOD_LUAS) $(TEST_LUAS) doc Makefile README TODO
	@echo "Creating $(VERSION).tar.gz"
	@mkdir $(VERSION)
	@cp -r src test doc Makefile README TODO $(VERSION)
	@tar czf $(VERSION).tar.gz $(VERSION)
	@rm -rf $(VERSION)
