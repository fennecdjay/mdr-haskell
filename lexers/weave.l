%option outfile="generated/weave.c" header-file="generated/weave.h"
%option reentrant extra-type="Weaver*" prefix="weave"
%option nounput noinput

%{
#include "config.h"
#include "mdr.h"
typedef struct {
  FILE* file;
  Mdr* mdr;
  uint16_t used;
} Weaver;

#define PUTS(a) fputs((a), yyextra->file)
static void expand(yyscan_t, char* name);
static void command(const char*, FILE*);
%}

%x CMD
%x OPT
%x BLK
%%

<INITIAL>^@exec[ \r\t]*   { BEGIN(CMD); }
<CMD>[ \r\t]*\n   { BEGIN(INITIAL); }
<CMD>.*           { command(yytext, yyextra->file); }
"@{{"[A-Za-z_][A-Za-z0-9_]*"}}" { expand(yyscanner, yytext); }
<BLK>"```" { PUTS(yytext); BEGIN(INITIAL); }
"```" { PUTS(yytext); BEGIN(BLK); }
<*>.|\n { PUTS(yytext); }

%%
int weavewrap(yyscan_t scanner) {
  weavepop_buffer_state(scanner);
  return !!--weaveget_extra(scanner)->used;
}

static void expand(yyscan_t scanner, char* name) {
  Weaver* weaver = weaveget_extra(scanner);
  name[strlen(name) - 2] = '\0';
  Block *b = mdr_block(weaver->mdr, name + 3);
  if(!b)
    return;
  YY_BUFFER_STATE state = weave_create_buffer (b->file, YY_BUF_SIZE, scanner);
  ++weaver->used;
  weavepush_buffer_state(state, scanner);
}


static void command(const char* s, FILE* file) {
  FILE* in = popen(s, "r");
  if(!in)
    return;
  fputs(prefix, file);
  char ch;
  while((ch = fgetc(in)) != EOF)
    putc(ch, file);
  fclose(in);
  fputs(suffix, file);
}

void weave(Mdr* mdr) {
  FILE* in = fopen(mdr->name, "r" );
  if(!in)
    return;
  char name[strlen(mdr->name) + 2];
  strcpy(name, mdr->name);
  name[strlen(mdr->name)] = 'r';
  name[strlen(mdr->name) + 1] = '\0';
  FILE* out = fopen(name, "w" );
  yyscan_t scanner;
  Weaver weaver = { out, mdr, 0 };
  weavelex_init_extra(&weaver, &scanner);
  weaveset_in(in, scanner);
  weavelex(scanner);
  weavelex_destroy(scanner);
  fclose(in);
  fclose(out);
}
