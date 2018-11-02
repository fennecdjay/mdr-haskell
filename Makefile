CFLAGS += -I. -g -std=c99
LDFLAGS += -lpthread -pthread
PREFIX ?= /usr/local
ifeq (${USE_COVERAGE}, 1)
CFLAGS += -ftest-coverage -fprofile-arcs
LDFLAGS += --coverage
endif

mdr: src/mdr.o
	${CC} ${LDFLAGS} -o $@ $^

mdr_debug: src/mdr.g
	${CC} ${LDFLAGS} -o $@ $^

.c.o:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.o) -O3

.c.g:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.g) -Og -g

test: mdr
	./mdr test/*.mdr || exit 0
	./mdr README.mdr

install: mdr
	cp -f mdr ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/mdr


clean:
	rm -rf mdr mdr_debug hello_world.c hello_world src/*.o src/*.g tests/*.md

.SUFFIXES: .c .o .g
