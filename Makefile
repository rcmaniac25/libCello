CC = gcc
AR = ar

VERSION = 1.1.2
PACKAGE = libCello-$(VERSION)

PREFIX=/usr/local
DESTDIR=
INCDIR=${PREFIX}/include
LIBDIR=${PREFIX}/lib
I=${DESTDIR}/${INCDIR}
L=${DESTDIR}/${LIBDIR}

SRC = $(wildcard src/*.c)
OBJ = $(addprefix obj/,$(notdir $(SRC:.c=.o)))

TESTS = $(wildcard tests/*.c)
TESTS_OBJ = $(addprefix obj/,$(notdir $(TESTS:.c=.o)))

DEMOS = $(wildcard demos/*.c)
DEMOS_OBJ = $(addprefix obj/,$(notdir $(DEMOS:.c=.o)))
DEMOS_EXE = $(DEMOS:.c=)

CFLAGS_NO_STD = -I ./include -Wall -Werror -Wno-unused -O3 -g
CFLAGS = $(CFLAGS_NO_STD) -std=gnu99
LFLAGS = -shared -g -ggdb

PLATFORM = $(shell uname)

ifneq ($(QNX_HOST),)
# Done here to prevent other platforms from setting variables
	PLATFORM = BlackBerry
endif

ifeq ($(findstring Linux,$(PLATFORM)),Linux)
	DYNAMIC = libCello.so
	STATIC = libCello.a
	CFLAGS += -fPIC
	LIBS = -lpthread -ldl -lm
	INSTALL_LIB = mkdir -p ${L} && cp -f ${STATIC} ${L}/$(STATIC)
	INSTALL_INC = mkdir -p ${I} && cp -r include/* ${I}
endif

ifeq ($(findstring BlackBerry,$(PLATFORM)),BlackBerry)
	CC = $(QNX_HOST)/usr/bin/qcc
	AR = $(QNX_HOST)/usr/bin/ntoarm-ar
	LD = $(QNX_HOST)/usr/bin/ntoarmv7-ld

	I=${DESTDIR}/build/include
	L=${DESTDIR}/build/libs/arm

	DYNAMIC = libCello.so
	STATIC = libCello.a
	CFLAGS = $(CFLAGS_NO_STD) -Wc,-std=gnu99 -V4.6.3,gcc_ntoarmv7le -D__QNX__ -fPIC
	LFLAGS += -V4.6.3,gcc_ntoarmv7le
	LIBS = -lm -lbacktrace
	INSTALL_LIB = mkdir -p ${L} && cp -f ${STATIC} ${L}/$(STATIC)
	INSTALL_INC = mkdir -p ${I} && cp -r include/* ${I}
endif

ifeq ($(findstring Darwin,$(PLATFORM)),Darwin)
	DYNAMIC = libCello.so
	STATIC = libCello.a
	CFLAGS += -fPIC -fblocks -fnested-functions
	LIBS = -lpthread -ldl -lm
	INSTALL_LIB = mkdir -p ${L} && cp -f $(STATIC) ${L}/$(STATIC)
	INSTALL_INC = mkdir -p ${I} && cp -r include/* ${I}
endif

ifeq ($(findstring MINGW,$(PLATFORM)),MINGW)
	DYNAMIC = libCello.dll
	STATIC = libCello.a
	LIBS = 
	INSTALL_LIB = cp $(STATIC) C:/MinGW64/x86_64-w64-mingw32/lib/$(STATIC); cp $(DYNAMIC) C:/MinGW64/x86_64-w64-mingw32/bin/$(DYNAMIC)
	INSTALL_INC = cp -r include/* C:/MinGW64/x86_64-w64-mingw32/include/
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
  
# Install
  
install: all
	$(INSTALL_LIB)
	$(INSTALL_INC)
