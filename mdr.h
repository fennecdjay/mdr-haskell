#include <stdio.h>
#include <inttypes.h>
typedef struct {
  char* name;
  FILE* file;
  char* data;
  size_t size;
  struct Mdr* mdr;
  unsigned type : 1;
} Block;

typedef struct Mdr {
  FILE* curr;
  Block block[128];
  char* name;
  int8_t used;
} Mdr;

void prep(Mdr*);
void tangle(Block* block);
void weave(Mdr* mdr);
Block* mdr_block(Mdr *mdr, const char* name);
