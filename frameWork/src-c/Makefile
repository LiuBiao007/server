
src-dir = ./
MCSERVICE_PATH = ../cservice/
CFLAGS := -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)
SHARED := -fPIC --shared

#skynet
SKYNET_ROOT := ../3rd/skynet/

MCSERVICE = csjon mylog skiplist time ltls
all:skynet \
	$(foreach v, $(MCSERVICE), $(MCSERVICE_PATH)$(v).so)

.PHONY: all clean cleanall	

SKYNET_MAKEFILE:$(SKYNET_ROOT)Makefile
	git submodule update --init

skynet:	$(SKYNET_MAKEFILE)
	cd $(SKYNET_ROOT) && $(MAKE) linux

$(MCSERVICE_PATH) :
	mkdir $(MCSERVICE_PATH)

#cjson
cjson_root := ../3rd/lua-cjson/
jsonsrc = \
	lua_cjson.c\
	strbuf.c\
	fpconv.c

$(CSERVICE)csjon.so: $(addprefix $(cjson_root),$(jsonsrc))
	$(CC) $(CFLAGS) -I$(cjson_root) $(SHARED) $^ -o $@

$(cjson_root)lua_cjson.c:
	git submodule update --init ../3rd/lua-cjson

JE_MALLOC_INC := $(SKYNET_ROOT)3rd/jemalloc/include/jemalloc
JE_MALLOC_LIB := $(SKYNET_ROOT)3rd/jemalloc/lib/libjemalloc_pic.a

TLS_LIB=
TLS_INC=

$(MCSERVICE_PATH)mylog.so :$(src-dir)/service_mylog.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src

$(MCSERVICE_PATH)skiplist.so : $(foreach v, $(zrank-src), $(src-dir)/$(v)) $(SKYNET_ROOT)skynet-src/malloc_hook.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src -I$(JE_MALLOC_INC)

$(MCSERVICE_PATH)time.so :$(src-dir)/lua-time.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_ROOT)skynet-src

$(MCSERVICE_PATH)ltls.so : $(src-dir)/ltls.c | $(MCSERVICE_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_ROOT)skynet-src -L$(TLS_LIB) -I$(TLS_INC) $^ -o $@ -lssl	

clean:
	rm -f $(MCSERVICE_PATH)*.so

cleanall:clean
	cd $(SKYNET_ROOT) && $(MAKE) cleanall

