#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <ctype.h>
#include <termios.h>

int main (int argc, char *argv[])
{
  int priv2;
  struct stat sb;
  void *memblk, *adr;
  off_t offset;
  int type;
  uint64_t val64;
  uint32_t val32;

  if (argc < 3) {
    printf("Usage: mmio <r,w> <adr> <Region_file> [dat]\n\n");
    exit(-1);
  }
  
  if ((priv2 = open(argv[3], O_RDWR)) < 0) {
    printf("Can not open %s\n",argv[1]);
    exit(-1);
  }

  fstat(priv2, &sb);
  
  memblk = mmap(NULL,sb.st_size, PROT_WRITE|PROT_READ, MAP_SHARED, priv2, 0);
  if (memblk == MAP_FAILED) {
    printf("Can not mmap %s\n",argv[1]);
    exit(-1);
  }

  type = 0;
  if (tolower(argv[1][0] == 'd')) {
    type++;
  }
  if (argc == 5) {
    type += 2;
  }

  offset = strtoul(argv[2], 0, 0);

  adr = memblk + (offset & (sb.st_size - 1));

  printf("\n");
  switch (type) {
    case 0 : // Read word
      val32 = *((uint32_t *)adr);
      printf("Reading word : [%jx]= 0x%08jx\n",adr, val32);
      break;
    case 1 : // Read double
      val64 = *((uint64_t *)adr);
      printf("Reading double : [%jx]= 0x%016jx\n",adr, val64);
      break;
    case 2 : // Write word
      val32 = strtoul(argv[4], 0, 0);
      *((uint32_t *)adr) = val32;
      printf("Writing word : [%jx]= 0x%08jx\n",adr, val32);
      break;
    case 3 : // Write double
      val64 = strtoul(argv[4], 0, 0);
      *((uint64_t *)adr) = val64;
      printf("Writing double : [%jx]= 0x%016jx\n",adr, val64);
      break;
    other : // Error
      printf("Invalid Parms\n");
      exit(-1);
      break;
  }

  munmap(memblk,sb.st_size);

  printf("\n");
  close(priv2);
}
