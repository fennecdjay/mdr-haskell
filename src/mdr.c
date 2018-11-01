#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
#include <string.h>

#define MDR_MAX 80
#define MDR_CHR '@'
#define INC_INI "[["
#define INC_END "]]"
#define BLK_STR "```"
#define EXE_STR "exec"

#define MDR_SUCCESS   1
#define MDR_FAILURE   0
#define MDR_ERROR    -1

#define MDR(a) { if((a) == MDR_ERROR) return MDR_ERROR; }

static const char prefix[] = "result:" BLK_STR "\n";
static const char suffix[] = "\n" BLK_STR;

typedef struct {
  char       *name;
  FILE       *file;
  char       *fptr;
  size_t      size;
  unsigned    type : 1;
} Block;

typedef struct {
  Block       *data;
  Block       *curr;
  const char  *name;
  uint8_t      used;
} Blocks;

typedef struct Lex {
  FILE *fio[2];
  Blocks *blocks;
  char *buf;
  struct Lex *base;
  uint8_t len;
  char chr;
  unsigned alt : 1;
  unsigned dec : 1;
  unsigned act : 1;
} Lex;

typedef enum lex_opt {
  MDR_PRE = 1 << 0,
  MDR_RUN = 1 << 1,
  MDR_DEC = 1 << 2
} lex_opt;

static int block_init(Block *block, const char *name, const int type) {
  if(!(block->file = open_memstream(&block->fptr, &block->size)))
    return MDR_ERROR;
  block->name = strdup(name);
  block->type = type;
  return MDR_SUCCESS;
}

static FILE *block_add(Blocks *blocks, const char *name, const int type) {
  if(blocks->curr)
    return blocks->curr->file;
  Block *block = &blocks->data[blocks->used];
  if(block_init(block, name, type)) {
    ++blocks->used;
    block->type = type;
    return block->file;
  }
  return NULL;
}

static void free_blocks(const Blocks *blocks) {
  for(int8_t i = 0; i < blocks->used; i++) {
    Block *const block = &blocks->data[i];
    free(block->name);
    fclose(block->file);
    free(block->fptr);
  }
}

static FILE *block_open_in(Blocks *blocks) {
  if(blocks->curr) {
    FILE *file = blocks->curr->file;
    rewind(file);
    return file;
  }
  return fopen(blocks->name, "r");
}

static FILE *block_open_out(const Blocks *blocks) {
  if(blocks->curr)
    return fopen(blocks->curr->name, "w");
  const char *name = blocks->name;
  const size_t len = strlen(name);
  char c[len];
  strcpy(c, name);
  c[len - 1] = '\0';
  return fopen(c, "w");
}

static inline int isidini(const char c) {
  return isalpha(c) || c == '_';
}

static inline int isid(const char c) {
  return isalnum(c) || c == '_';
}

static inline int ispath(const char c) {
  return c == '/' || c == '.';
}


static inline int lex_chr(const Lex *lex, const char c) {
  return lex->chr == c;
}

static inline int lex_eat(Lex *lex) {
  return
    ((lex->chr = (lex->buf[lex->len++] = fgetc(lex->fio[0]))) != EOF) &&
    lex->len < MDR_MAX;
}

static inline void lex_clean(Lex *lex) {
//  memset(lex->buf, 0, lex->len);
  memset(lex->buf, 0, MDR_MAX);
  lex->len = 0;
}

static inline void lex_start(Lex *lex) {
//  memset(lex->buf, 0, lex->len);
  memset(lex->buf, 0, MDR_MAX);
  lex->buf[0] = lex->chr;
  lex->len = 1;
}

static int lex_id(Lex *lex) {
  if(!isidini(lex->chr))
    return MDR_FAILURE;
  lex_start(lex);
  while(lex_eat(lex)) {
    if(isid(lex->chr))
      continue;
    break;
  }
  return MDR_SUCCESS;
}

static int lex_ispath(const char c, int *id) {
  if(!ispath(c))
    return MDR_FAILURE;
  *id = 1;
  return MDR_SUCCESS;
}

static int lex_path(Lex *lex, int *is_path) {
  while(lex_eat(lex) && lex_chr(lex, ' '));
  lex_start(lex);
  if(!(isidini(lex->chr) || lex_ispath(lex->chr, is_path)))
    return MDR_FAILURE;
  while(lex_eat(lex)) {
    if(!(isid(lex->chr) || lex_ispath(lex->chr, is_path)))
      break;
  }
  return MDR_SUCCESS;
}

static void dump(FILE *restrict from, FILE *restrict to) {
  char ch;
  while((ch = fgetc(from)) != EOF)
    putc(ch, to);
// rewind
  fseek(to, -1, SEEK_CUR);
}

static void dec(FILE *restrict from, FILE *restrict to) {
  fputs(prefix, to);
  dump(from, to);
  fputs(suffix, to);
}

static void lex_exec(const Lex *lex) {
  FILE *file = popen(lex->buf, "r");
  if(!file)
    return;
  if(lex->dec)
    dec(file, lex->fio[1]);
  else
    dump(file, lex->fio[1]);
  fclose(file);
}

static void lex_line(Lex *lex) {
  lex_clean(lex);
  while(!lex_chr(lex, '\n') && lex_eat(lex));
}

static int lex_block(const Lex *lex, const int trim) {
  Blocks *blocks = lex->blocks;
  lex->buf[lex->len - trim] = '\0';
  for(int8_t i = 0; i < blocks->used; i++) {
    Block *const block = &blocks->data[i];
    if(!strcmp(lex->buf, block->name)) {
      blocks->curr = block;
      return MDR_SUCCESS;
    }
  }
  return MDR_FAILURE;
}

static int lex_string(Lex *lex, const char *str) {
  if(!lex_chr(lex, str[0]))
    return MDR_FAILURE;
  const size_t len = strlen(str);
  size_t i = 1;
  while(i < len  && lex_eat(lex)) {
    if(!lex_chr(lex, str[i++]))
      return MDR_FAILURE;
  }
  return MDR_SUCCESS;
}

static inline void lex_putc(Lex *lex, const char c) {
  fputc(c, lex->fio[1]);
}

static inline void lex_puts(Lex *lex, const char *c) {
  fputs(c, lex->fio[1]);
}

static inline void lex_put_chr(Lex *lex) {
  fputc(lex->chr, lex->fio[1]);
}

static inline void lex_put_buf(Lex *lex) {
  fputs(lex->buf, lex->fio[1]);
  lex_clean(lex);
}

static void lex_init(Lex *lex, char *c, const lex_opt opt) {
  memset(c, 0, MDR_MAX);
  lex->buf = c;
  lex->act = ((opt & MDR_RUN) == MDR_RUN);
  lex->dec = ((opt & MDR_DEC) == MDR_DEC);
}

static inline int lex_cmp(Lex *lex, const char *s) {
  return strncmp(lex->buf, s, strlen(s));
}

static int lex_open(Lex *lex, Lex *const base) {
  lex->base = base;
  if(!(lex->fio[0] = block_open_in(lex->blocks)))
    return MDR_ERROR;
  if(lex->act) {
    if(base && base->fio[1]) {
      lex->fio[1] = base->fio[1];
      return MDR_SUCCESS;
    }
    if(!(lex->fio[1] = block_open_out(lex->blocks)))
      return MDR_ERROR;
  }
  return MDR_SUCCESS;
}

static int cmd(Lex *);

static void lex_close(Lex *lex) {
  if(lex->dec) {
    fclose(lex->fio[0]);
    fclose(lex->fio[1]);
  } else if(!lex->act)
    fclose(lex->fio[0]);
  else if(!lex->base->fio[1])
    fclose(lex->fio[1]);
}

static int lex_run(Lex *lex) {
  while(lex_eat(lex)) {
    if(lex_chr(lex, MDR_CHR))
      MDR(cmd(lex))
      else if(lex->act || lex->alt)
        lex_put_chr(lex);
    lex->len = 0;
  }
  lex_close(lex);
  return MDR_SUCCESS;
}


static int tangle(Lex *base) {
  char buf[MDR_MAX];
  Lex lex = { .blocks=base->blocks };
  lex_init(&lex, buf, MDR_RUN);
  MDR(lex_open(&lex, base))
  const int ret = lex_run(&lex);
  lex.blocks->curr = NULL;
  return ret;
}

static int inc_run(Lex *lex) {
  if(lex_block(lex, 2))
    return tangle(lex);
  return MDR_FAILURE;
}

static int inc(Lex *lex) {
  if(!lex_string(lex, INC_INI))
    return MDR_FAILURE;
  if(!lex_eat(lex))
    return MDR_ERROR;
  if(!lex_id(lex) || !lex_string(lex, INC_END))
    return MDR_FAILURE;
  if(lex->act)
    return inc_run(lex);
  return MDR_FAILURE;
}

static void ini(Lex *lex) {
  int is_path = 0;
  if(lex_path(lex, &is_path)) {
    lex_block(lex, 1);
    lex->fio[1] = block_add(lex->blocks, lex->buf, is_path);
  }
}

static int blk(Lex *lex) {
  if(!lex_string(lex, BLK_STR))
    return MDR_FAILURE;
  if(lex->act)
    lex_puts(lex, BLK_STR);
  if(!(lex->alt = !lex->alt))
    return MDR_SUCCESS;
  if(!lex->act) {
    ini(lex);
    lex_line(lex);
  } else {
    int is_path; // TODO: error checking
    lex_path(lex, &is_path);
    lex_clean(lex);
    lex_line(lex);
    lex_putc(lex, ' ');
    lex_put_buf(lex);
  }
  return MDR_SUCCESS;
}

static int exe(Lex *lex) {
  if(!lex_id(lex) || lex_cmp(lex, EXE_STR) || lex->alt) {
    if(!lex->act)
      lex->fio[1] = NULL;
    return MDR_FAILURE;
  }
  lex_line(lex);
  if(lex->act)
    lex_exec(lex);
  return MDR_SUCCESS;
}

static int opt(Lex *lex) {
  int ret;
  if(!lex->alt) {
    if((ret = lex_chr(lex, MDR_CHR))) {
      if(lex->dec)
        lex_put_chr(lex);
      return ret;
    }
    if((ret = exe(lex)))
      return ret;
    if((ret = inc(lex)))
      return ret;
  }
  return MDR_FAILURE;
}

static int cmd_fail(Lex *lex) {
  if(lex->act || lex->alt) {
    lex_putc(lex, MDR_CHR);
    lex_put_buf(lex);
  }
  return MDR_FAILURE;
}

static int cmd(Lex *lex) {
  int ret;
  lex_clean(lex);
  if(!lex_eat(lex))
    return MDR_ERROR;
  if((ret = opt(lex)))
    return ret;
  if((ret = blk(lex)))
    return ret;
  return cmd_fail(lex);
}

static int mdr_tangle(Blocks *blocks) {
  char buf[MDR_MAX];
  Lex lex = { .blocks=blocks };
  lex_init(&lex, buf, MDR_RUN);
  for(int i = 0; i < blocks->used; ++i) {
    Block *const block = &blocks->data[i];
    if(block->type) {
      blocks->curr = block;
      MDR(tangle(&lex))
    }
  }
  return MDR_SUCCESS;
}

static int mdr_run(Blocks *const blocks, const enum lex_opt opt) {
  char buf[MDR_MAX];
  Lex lex = { .blocks=blocks };
  lex_init(&lex, buf, opt);
  MDR(lex_open(&lex, NULL))
  return lex_run(&lex);
}

static int mdr(const char *name) {
  Block  data[MDR_MAX];
  Blocks blocks = { .data=data, .name = name };
  MDR(mdr_run(&blocks, MDR_PRE))
  MDR(mdr_tangle(&blocks))
  MDR(mdr_run(&blocks, MDR_RUN | MDR_DEC))
  free_blocks(&blocks);
  return MDR_SUCCESS;
}

int main(int argc, char **argv) {
  for(int i = 1; i < argc; ++i)
    MDR(mdr(argv[i]));
  return 0;
}
