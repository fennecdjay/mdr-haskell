#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "mdr.h"

static void clean(Mdr *mdr) {
  for(int8_t i = 0; i <= mdr->used; i++) {
    Block* block = &mdr->block[i];
    free(block->name);
    fclose(block->file);
    free(block->data);
  }
}

Block* mdr_block(Mdr *mdr, const char* name) {
  for(int8_t i = 0; i <= mdr->used; i++) {
    Block *block = &mdr->block[i];
    if(!strcmp(name, block->name))
      return block;
  }
  return NULL;
}

static void mdr_tangle(Mdr *mdr) {
  for(int8_t i = 0; i <= mdr->used; i++) {
    Block *block = &mdr->block[i];
    if(block->type) {
      tangle(block);
    }
  }
}

static void compile(char* name) {
  Mdr mdr = { .name = name, .used = -1 };
  prep(&mdr);
  mdr_tangle(&mdr);
  weave(&mdr);
  clean(&mdr);
}

int main(int argc, char **argv) {
  ++argv, --argc;
  if(!argc)
    return 1;
  for(int i = 0; i < argc; i++)
    compile(argv[i]);
  return 0;
}
