PRG     ?= mdr
PREFIX  ?= /usr
LEX     ?= alex
YACC    ?= happy
LFLAGS  += -g
YFLAGS  += -a -g -c
#HSFLAGS += -dynamic --make -O2 -fprof-auto -fprof-cafs -Wall -Wextra
HSFLAGS += -static --make -O2
HSFLAGS += -XLambdaCase
HSFLAGS += -fwarn-identities -fwarn-incomplete-record-updates
HSFLAGS += -fhpc
#non exaustive pattern in alex
#-fwarn-incomplete-uni-patterns
#HSFLAGS += -fwarn-monomorphism-restriction -fwarn-incomplete-uni-patterns
# because alex misse many signatures
#HSFLAGS += -Wmissing-exported-signatures -Wmissing-local-signatures
# just boring
#HSFLAGS +=  -fwarn-implicit-prelude -fwarn-missing-import-lists

all: lexer.hs parser.hs
	rm -f mdr.tix
	ghc ${HSFLAGS} -o ${PRG} *.hs

lexer.hs: lexer.x
	${LEX} ${LFLAGS} $<

parser.hs: parser.y
	${YACC} ${YFLAGS} $<

test: ${PRG}
	@echo "# Title" | ./${PRG} > /dev/null
	@echo "# Title" | ./${PRG} -- > /dev/null
	@./${PRG} $(wildcard tests/*.mdr)

clean:
	rm -f lexer.hs
	rm -f parser.hs
	rm -f *.hi *.o
	rm -f ${PRG}
	rm -f hello_world.c hello_world
	rm -f ${PRG}.tix *.html
	rm -f $(wildcard tests/*.md)
	rm -rf unwritable Just.sh

install:
	install ${PRG} ${PREFIX}/bin/${PRG}
