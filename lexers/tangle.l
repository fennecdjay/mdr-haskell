%option outfile="generated/tangle.c" header-file="generated/tangle.h"
%option reentrant extra-type="Tangler*"prefix="tangle"
%option nounput noinput nointeractive

%{
#include "mdr.h"
typedef struct {
  FILE* file;
  Mdr* mdr;
  uint8_t used;
} Tangler;
static void expand(yyscan_t, char* name);
%}

%%
"@{{"[A-Za-z_][A-Za-z0-9_]*"}}" { expand(yyscanner, yytext); }
.|\n   { putc(*yytext, yyextra->file); }

%%
int tanglewrap(yyscan_t scanner) {
  tanglepop_buffer_state(scanner);
  return !!--tangleget_extra(scanner)->used;
}

static void expand(yyscan_t scanner, char* name) {
  Tangler* tangler = tangleget_extra(scanner);
  name[strlen(name) - 2] = '\0';
  Block *b = mdr_block(tangler->mdr, name + 3);
  YY_BUFFER_STATE state = tangle_create_buffer (b->file, YY_BUF_SIZE, scanner);
  ++tangler->used;
  tanglepush_buffer_state(state, scanner);
}

void tangle(Block* block) {
  FILE* file = fopen(block->name, "w");
  if(!file)
    return;
  yyscan_t scanner;
  Tangler tangler = { file, block->mdr, 0 };
  tanglelex_init_extra(&tangler, &scanner) ;
  tangleset_in(block->file, scanner);
  tanglelex(scanner);
  tanglelex_destroy(scanner);
  fclose(file);
}
