include Make.config

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
TEST_LUAS = test/test.lua \
            test/luabot.lua
OTHER_FILES = Makefile \
	      Make.config \
	      README \
	      LICENSE \
	      TODO
DOC_LUAS = src/callbacks.luadoc
VERSION = $(shell grep '^_VERSION =' $(MAIN_LUA) | sed "s/_VERSION = '\(.*\)'/\1/" | tr ' ' '-')

build :

install :
	mkdir -p $(LUA_DIR)
	cp $(MAIN_LUA) $(LUA_DIR)
	mkdir -p $(MOD_DIR)
	cp $(MOD_LUAS) $(MOD_DIR)

doc : $(MAIN_LUA) $(MOD_LUAS) $(DOC_LUAS)
	mkdir -p $(DOC_DIR)
	$(LUADOC) --nofiles -d $(DOC_DIR) $(MAIN_LUA) $(MOD_LUAS) $(DOC_LUAS)
	@touch doc

clean :
	rm -rf $(DOC_DIR)

dist : $(VERSION).tar.gz

$(VERSION).tar.gz : $(MAIN_LUA) $(MOD_LUAS) $(TEST_LUAS) doc $(OTHER_FILES)
	@echo "Creating $(VERSION).tar.gz"
	@mkdir $(VERSION)
	@mkdir $(VERSION)/src
	@cp $(MAIN_LUA) $(VERSION)/src
	@mkdir $(VERSION)/src/irc
	@cp $(MOD_LUAS) $(VERSION)/src/irc
	@mkdir $(VERSION)/test
	@cp $(TEST_LUAS) $(VERSION)/test
	@mkdir $(VERSION)/doc
	@cp -r doc/* $(VERSION)/doc
	@cp $(OTHER_FILES) $(VERSION)
	@tar czf $(VERSION).tar.gz $(VERSION)
	@rm -rf $(VERSION)
