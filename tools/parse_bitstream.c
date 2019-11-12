#include <arpa/inet.h>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>

#define ARRAY_SIZE(x)		(sizeof(x) / sizeof((x)[0]))

#define NR_BYTES_OF_ICAP	(4)

struct cmd_entry {
	int cmd;
	char name[32];
	int type;
};

static struct cmd_entry cmd_table[] = {
	{ .cmd = 0xFFFFFFFF, .name = "dummy", },
	{ .cmd = 0xaa995566, .name = "SYNC", },
	{ .cmd = 0x000000BB, .name = "Bus Width Sync", },
	{ .cmd = 0x11220044, .name = "Bus Width Detect", },
	{ .cmd = 0x20000000, .name = "NOOP", },

	{ .cmd = 0x30022001, .name = "Write to TIMER", },
	{ .cmd = 0x30020001, .name = "Write to WBSTAR", },
	{ .cmd = 0x30002001, .name = "Write to FAR", },
	{ .cmd = 0x30026001, .name = "Write to CRC", },
	{ .cmd = 0x30012001, .name = "Write to CRO0", },
	{ .cmd = 0x3001C001, .name = "Write to CRO1", },
	{ .cmd = 0x30018001, .name = "Write to IDCODE", },
	{ .cmd = 0x3000C001, .name = "Write to MASK", },
	{ .cmd = 0x3000A001, .name = "Write to CTL0", },
	{ .cmd = 0x30030001, .name = "Write to CTL1", },
	{ .cmd = 0x30004000, .name = "Write to FDRI", },

	{ .cmd = 0x30008001, .name = "Write to CMD", },
	//{ .cmd = 0x00000000, .name = "   CRC (CMD Reg)", },
	//{ .cmd = 0x00000001, .name = "   FAR (CMD Reg)", },
	{ .cmd = 0x00000004, .name = "   RCFG (CMD Reg)", },
	{ .cmd = 0x00000005, .name = "   START (CMD Reg)", },
	{ .cmd = 0x0000000B, .name = "   SHUTDONE (CMD Reg)", },
	{ .cmd = 0x00000007, .name = "   RCRC (CMD Reg)", },
	{ .cmd = 0x0000000D, .name = "   DESYNC (CMD Reg)", },

	{ .cmd = 0x28006000, .name = "Read from FDRO", },
	{ .cmd = 0x20008001, .name = "Read from CMD", },
};

static struct cmd_entry *find_entry(int cmd)
{
	int i;
	struct cmd_entry *entry;

	for (i = 0; i < ARRAY_SIZE(cmd_table); i++) {
		entry = &cmd_table[i];
		if (entry->cmd == cmd)
			return entry;
	}
	return NULL;
}

enum sm {
	SM_NORMAL,
	FDRI_LENGTH,
	FDRI_DATA,
};

int main(int argc, char **argv)
{
	char *fname, *str_nr_words_to_parse;
	struct stat fs_stat;
	int fd, ret;
	int i, nr_words, current;
	int state = SM_NORMAL;
	int fdri_data_offset = 1;
	int nr_config_words;

	if (argc != 3) {
		printf("Usage: ./parse bitstream.bin [nr_words]\n");
		exit(-1);
	}

	fname = argv[1];
	str_nr_words_to_parse = argv[2];

	fd = open(fname, O_RDONLY); 
	if (fd < 0) {
		printf("Fail to open: %s\n", fname);
		exit(-1);
	}

	state = SM_NORMAL;
	nr_words = atoi(str_nr_words_to_parse);
	if (nr_words == -1) {
		stat(fname, &fs_stat);
		nr_words = fs_stat.st_size;
		nr_words /= 4;
	}

	printf("nr_words: %d\n", nr_words);

	for (i = 0; i < nr_words; i++) {
		ssize_t nr_read;
		struct cmd_entry *entry;

		nr_read = read(fd, &current, NR_BYTES_OF_ICAP);
		if (nr_read != NR_BYTES_OF_ICAP)
			goto done;

		current = htonl(current);
		entry = find_entry(current);

rerun:
		if (state == SM_NORMAL) {
			/* Write to FDRI register */
			if (current == 0x30004000) {
				state = FDRI_LENGTH;
			};

			printf("[%08x] %08x  %s\n",
				i*NR_BYTES_OF_ICAP, current,
				entry ? entry->name : "");
		} else if (state == FDRI_LENGTH) {
			/*
			 * This is a Type 2 Packer Header.
			 * Only the lower 27bits means word count.
			 */
			nr_config_words = current & 0x07FFFFFF;
			printf("[%08x] %08x  (word_count=%d)\n",
				i*NR_BYTES_OF_ICAP, current, nr_config_words);
			state = FDRI_DATA;
		} else if (state == FDRI_DATA) {
			if (current != 0) {
				printf("[%08x] %08x  (Bitstream word offset: %08x, or %d)\n",
					i*NR_BYTES_OF_ICAP, current,
					fdri_data_offset, fdri_data_offset);
			}
			fdri_data_offset++;

			if (fdri_data_offset > nr_config_words) {
				printf("End of FDRI Configuration Data Section\n");
				fdri_data_offset = 0;
				state = SM_NORMAL;
			}
		}
	}

done:
	return 0;
}
