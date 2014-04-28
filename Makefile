CC ?= gcc
AR ?= ar

VERSION = 1.1.7
PACKAGE = libCello-$(VERSION)

BINDIR = ${PREFIX}/bin
INCDIR = ${PREFIX}/include
LIBDIR = ${PREFIX}/lib

SRC := $(wildcard src/*.c)
OBJ := $(addprefix obj/,$(notdir $(SRC:.c=.o)))

TESTS := $(wildcard tests/*.c)
TESTS_OBJ := $(addprefix obj/,$(notdir $(TESTS:.c=.o)))

DEMOS := $(wildcard demos/*.c)
DEMOS_OBJ := $(addprefix obj/,$(notdir $(DEMOS:.c=.o)))
DEMOS_EXE := $(DEMOS:.c=)

STD_GNU = -std=gnu99
CFLAGS = -I ./include -Wall -Werror -Wno-unused -O3 -g
LFLAGS = -shared -g -ggdb

PLATFORM := $(shell uname)
COMPILER := $(shell $(CC) -v 2>&1 )

ifneq ($(QNX_HOST),)
# Done here to prevent other platforms from setting variables
	PLATFORM = BlackBerry

	CFLAGS += -Wc,$(STD_GNU)
else
	CFLAGS += $(STD_GNU)
endif

ifeq ($(findstring MINGW,$(PLATFORM)),MINGW)
	PREFIX ?= C:/MinGW64/x86_64-w64-mingw32

	DYNAMIC = libCello.dll
	STATIC = libCello.a
	LIBS =

	INSTALL_LIB = cp $(STATIC) $(LIBDIR)/$(STATIC); cp $(DYNAMIC) $(BINDIR)/$(DYNAMIC)
	INSTALL_INC = cp -r include/* $(INCDIR)
else
	PREFIX ?= /usr/local

	DYNAMIC = libCello.so
	STATIC = libCello.a
	LIBS = -lpthread -lm

	CFLAGS += -fPIC

	ifeq ($(findstring BlackBerry,$(PLATFORM)),BlackBerry)
		CC = $(QNX_HOST)/usr/bin/qcc

		# ARM
		AR = $(QNX_HOST)/usr/bin/ntoarm-ar
		LD = $(QNX_HOST)/usr/bin/ntoarmv7-ld
		QNX_VER = -V4.6.3,gcc_ntoarmv7le
		LIBDIR=${PREFIX}/build/libs/arm

		# x86
		# AR = $(QNX_HOST)/usr/bin/ntox86-ar
		# LD = $(QNX_HOST)/usr/bin/ntox86-ld
		# QNX_VER = -V4.6.3,gcc_ntox86
		# LIBDIR=${PREFIX}/build/libs/x86

		QNX_CFLAGS = -fstack-protector-strong -D__QNX__
		QNX_LFLAGS = -Wl,-z,relro -Wl,-z,now

		INCDIR=${PREFIX}/build/include
		
		CFLAGS += $(QNX_VER) $(QNX_CFLAGS)
		LFLAGS += $(QNX_VER) $(QNX_LFLAGS)
	else
		LIBS += ldl
	endif

	INSTALL_LIB = mkdir -p ${LIBDIR} && cp -f ${STATIC} ${LIBDIR}/$(STATIC)
	INSTALL_INC = mkdir -p ${INCDIR} && cp -r include/* ${INCDIR}
endif

ifeq ($(findstring clang,$(COMPILER)),clang)
	CFLAGS += -fblocks

	ifneq ($(findstring Darwin,$(PLATFORM)),Darwin)
		LIBS += -lBlocksRuntime
	endif
endif

# Libraries

all: $(DYNAMIC) $(STATIC)

$(DYNAMIC): $(OBJ)
	$(CC) $(OBJ) $(LFLAGS) -o $@

$(STATIC): $(OBJ)
	$(AR) rcs $@ $(OBJ)

obj/%.o: src/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

obj:
	mkdir -p obj

# Tests

check: $(TESTS_OBJ) $(STATIC)
	$(CC) $(TESTS_OBJ) $(LFLAGS) $(STATIC) $(LIBS) -o test
	./test

obj/%.o: tests/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

# Demos

demos: $(DEMOS_EXE)

demos/%: demos/%.c $(STATIC) | obj
	$(CC) $< $(STATIC) $(CFLAGS) $(LIBS) -o $@

# Dist

dist: all | $(PACKAGE)
	cp -R demos include src tests INSTALL.md LICENSE.md Makefile README.md $(PACKAGE)
	tar -czf $(PACKAGE).tar.gz $(PACKAGE)

$(PACKAGE):
	mkdir -p $(PACKAGE)

# Clean

clean:
	rm -f $(OBJ) $(TESTS_OBJ) $(DEMOS_OBJ) $(STATIC) $(DYNAMIC)
	rm -f test

# Install

install: all
	$(INSTALL_LIB)
	$(INSTALL_INC)
