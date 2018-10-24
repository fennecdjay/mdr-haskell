%option outfile="generated/prep.c" header-file="generated/prep.h"
%option reentrant noyywrap extra-type="Mdr*" prefix="prep"
%option nounput noinput

%{
#include "mdr.h"
static void init(Mdr*, const char*, int);
%}

%x CMD
%x OPT
%x BLK
%%

^@exec[ \r\t]*     { BEGIN(CMD); }
<CMD>.*\n       { BEGIN(INITIAL); }

"```"\s*    { BEGIN(OPT); }
<OPT>\n { BEGIN(BLK); }
<OPT>[A-Za-z_][A-Za-z_0_9]* { init(yyextra, yytext, 0); }
<OPT>[/A-Za-z_][/A-Za-z_0_9]*\.[A-Za-z_0_9]* { init(yyextra, yytext, 1); }

<BLK>\n"```"\s*\n { yyextra->curr = NULL; BEGIN(INITIAL); }
<BLK>.     { if(yyextra->curr) fprintf(yyextra->curr, yytext); }
<BLK>\s*\n { if(yyextra->curr) fprintf(yyextra->curr, "\n"); }

<INITIAL,OPT>.|\s*\n* {}
%%

static void init(Mdr *mdr, const char *name, int type) {
  Block *block = &mdr->block[++mdr->used];
  block->file = open_memstream(&block->data, &block->size);
  block->mdr = mdr;
  block->type = type;
  mdr->curr = block->file;
  if(block->file)
    block->name = strdup(name);
  else
    --mdr->used;
}

void prep(Mdr* mdr) {
  FILE *f = fopen(mdr->name, "r" );
  if(!f)
    return;
  yyscan_t scanner;
  preplex_init_extra(mdr, &scanner);
  prepset_in(f, scanner);
  preplex(scanner);
  preplex_destroy(scanner);
  fclose(f);
}
