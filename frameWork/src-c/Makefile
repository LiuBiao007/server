SKYNET_ROOT := ../3rd/skynet/
LUA_STATICLIB := $(SKYNET_ROOT)3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= $(SKYNET_ROOT)3rd/lua

SRC_DIR = ./
MCSERVICE_PATH = ../cservice/
CFLAGS := -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)
SHARED := -fPIC --shared


SKYNET_CSERVICE = $(SKYNET_ROOT)cservice/
MCSERVICE = cjson skiplist time ltls myclient webclient
all : skynet \
	$(foreach v, $(MCSERVICE), $(MCSERVICE_PATH)$(v).so) \
	$(MCSERVICE_PATH)logger.so \
	copylog \

.PHONY : all clean cleanall	

#cjson
CJSON_ROOT := ../3rd/lua-cjson/
JSONSRC = \
	lua_cjson.c \
	strbuf.c \
	fpconv.c \
	\

$(MCSERVICE_PATH)cjson.so : $(addprefix $(CJSON_ROOT),$(JSONSRC))
	$(CC) $(CFLAGS) -I$(CJSON_ROOT) $(SHARED) $^ -o $@

$(CJSON_ROOT)lua_cjson.c :
	git submodule update --init ../3rd/lua-cjson

#skynet
.PHONY : skynet update3rd

../3rd/skynet/Makefile:
	git submodule update --init ../3rd/skynet

skynet:../3rd/skynet/Makefile
	cd $(SKYNET_ROOT) && $(MAKE) linux

update3rd :
	rm -rf $(SKYNET_ROOT)skynet && git submodule update --init

$(MCSERVICE_PATH) :
	mkdir $(MCSERVICE_PATH)

JE_MALLOC_INC := $(SKYNET_ROOT)3rd/jemalloc/include/jemalloc
JE_MALLOC_LIB := $(SKYNET_ROOT)3rd/jemalloc/lib/libjemalloc_pic.a

TLS_LIB=
TLS_INC=

$(MCSERVICE_PATH)logger.so :$(SRC_DIR)service_mylog.c  | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src

$(MCSERVICE_PATH)skiplist.so : $(foreach v, $(zrank-src), $(SRC_DIR)/$(v)) $(SKYNET_ROOT)skynet-src/malloc_hook.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src -I$(JE_MALLOC_INC)

$(MCSERVICE_PATH)time.so :$(SRC_DIR)/lua-time.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src

$(MCSERVICE_PATH)webclient.so :$(SRC_DIR)/webclient.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src -lcurl

$(MCSERVICE_PATH)myclient.so :$(SRC_DIR)/lua-clientsocket.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src	

$(MCSERVICE_PATH)ltls.so : $(SRC_DIR)/ltls.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_ROOT)skynet-src -L$(TLS_LIB) -I$(TLS_INC) $^ -o $@ -lssl	

copylog:
	$(warning exec copylog)cp $(MCSERVICE_PATH)logger.so $(SKYNET_CSERVICE)

clean :
	rm -f $(MCSERVICE_PATH)*.so

cleanall : clean
	cd $(SKYNET_ROOT) && $(MAKE) cleanall
	cd $(CJSON_ROOT) && $(MAKE) clean

