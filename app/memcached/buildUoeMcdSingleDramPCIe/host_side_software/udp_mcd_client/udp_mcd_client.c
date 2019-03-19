#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <time.h>
#include <getopt.h>
#include <errno.h>
#include <linux/types.h>

static unsigned int time_out = 1;
static double read_ratio = 0.7; //70% read 30% write
static char *config_file_name = "kv_pair.csv";
static int single_run = 0;

static void print_help (char *name)
{
	printf("\nUSAGE: %s [OPTIONS]\n", name);
	printf("\t--config_file_name \tKV request configuration file name. Default=%s\n", config_file_name);
	printf("\t--read_ratio         \tread ratio. Default=%f\n", read_ratio);
	printf("\t--time_out         \tDefault=%d seconds\n", time_out);
	printf("\t--single_run			\t issue set and get requests generated from the config file once.\n");
	printf("\t--help             \tprint this message.\n");
	printf("\n");
}

void hexDump(char* desc, void *addr, int len) {
  int i;
  unsigned char *pc = (unsigned char*)addr;

  if (desc != NULL)
    printf("%s", desc);

  for (i=0; i < len; i++) {
    if ((i %4) == 0){
      printf("\n");
      printf(" %04x ", i);
    }
    printf(" %02x", pc[i]);
  }
  printf("\n");
}


void transmit_reqs_once(int num_of_reqs, uint8_t* reqs, int *req_size_arr, int socket, struct sockaddr *si_other, socklen_t slen) {
	uint8_t *req_addr;
	uint8_t rec_data[4096];
	int sent_items, rec_items;
	int i;
	char req_str[100];

	i = 0;
	req_addr = reqs;
	do {
				//sent reqs
				sent_items = sendto(socket, req_addr, req_size_arr[i], 0, si_other, slen);
				//sprintf(req_str, "request %d is: ", i);
				//hexDump(req_str, req_addr, req_size_arr[i]);
				req_addr += req_size_arr[i];
				rec_items = recvfrom(socket, &rec_data, sizeof(rec_data), 0, si_other, &slen);
				i++;
	} while (i <  num_of_reqs);

}

void transmit_reqs(int num_of_reqs, uint8_t *set_reqs, int *set_req_size_arr, uint8_t *get_reqs, int *get_req_size_arr, int socket, struct sockaddr *si_other, socklen_t slen) {
	int num_of_sets, num_of_gets, config_interval;
	int interval;
	uint8_t *set_req_addr, *get_req_addr;
	uint8_t rec_data[4096];
	int sent_iterms, rec_items;
	int i, j,k;
	int res;

	struct timespec start, now;
	double time_passed;


	num_of_gets = read_ratio * 100;
	num_of_sets = 100 - num_of_gets;
	config_interval = num_of_gets/num_of_sets;

	res = clock_gettime(CLOCK_REALTIME, &start);
	do {
		interval = 0;
		i = num_of_sets;
		j = num_of_gets;
		while ((i !=0) ||(j !=0)) {
			if ((i !=0) && (interval == 0)) {
				//sent set reqs
				set_req_addr = set_reqs;
				for (k=0; k<num_of_reqs; k++) {
					sendto(socket, set_req_addr, set_req_size_arr[k], 0, si_other, slen);
					set_req_addr = set_req_addr + set_req_size_arr[k];
				rec_items = recvfrom(socket, &rec_data, sizeof(rec_data), 0, si_other, &slen);
				}
				i--;
				interval = config_interval;
			}
			if ((j != 0) && (interval != 0)) {
				get_req_addr = get_reqs;
				for (k=0; k<num_of_reqs; k++) {
					sendto(socket, get_req_addr, get_req_size_arr[k], 0, si_other, slen);
					get_req_addr = get_req_addr + get_req_size_arr[k];
				rec_items = recvfrom(socket, &rec_data, sizeof(rec_data), 0, si_other, &slen);
				}
				j--;
				interval--;
			}

			if ((j != 0) && (interval == 0)) {
				get_req_addr = get_reqs;
				for (k=0; k<num_of_reqs; k++) {
					sendto(socket, get_req_addr, get_req_size_arr[k], 0, si_other, slen);
					get_req_addr = get_req_addr + get_req_size_arr[k];
				rec_items = recvfrom(socket, &rec_data, sizeof(rec_data), 0, si_other, &slen);
				}
				j--;
			}
			else if ((j==0) && (interval != 0)) {
				interval = 0;
			}
		}
		res = clock_gettime(CLOCK_REALTIME, &now);
		time_passed = now.tv_sec - start.tv_sec;
	} while ((int)time_passed < time_out);
}

int main (int argc, char *argv[])
{
	int opt;
	int option_index = 0;
	char str_line[100];
	FILE *fp;
	int *key_size_arr, *value_size_arr;
	int num_of_reqs;
	int *set_req_size_arr, *get_req_size_arr;
	uint32_t total_key_size, total_value_size;
	uint32_t total_set_req_size, total_get_req_size;
	uint8_t *keys, *values;
	uint8_t *set_reqs, *get_reqs;

	const int SET_HEADER_SIZE = 32;
	const int GET_HEADER_SIZE = 24;
	uint8_t set_header[] = {0x80, 0x01, 0x00, 0x05,
													0x08, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x12,
													0x00, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x00,
													0xde, 0xad, 0xbe, 0xef,
													0x00, 0x00, 0x00, 0x00
													};

	uint8_t get_header[] = {0x80, 0x00, 0x00, 0x05,
													0x00, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x12,
													0x00, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x00,
													0x00, 0x00, 0x00, 0x00
													};
	//parse parameters
	static struct option long_options[] = {
		{"config_file_name", required_argument, 0, 'c'},
		{"read_ratio", required_argument, 0, 'r'},
		{"time_out", required_argument, 0, 't'},
		{"single_run", no_argument, &single_run, 1},
		{"help", no_argument, 0, 'h'},
		{NULL, 0, 0, 0}
	};

	while ((opt = getopt_long(argc, argv, "avhc:t:", long_options, &option_index)) >= 0) {
		switch (opt)
		{
			case 0:
			break;
			case 'c':
				config_file_name = optarg;
				break;
			case 'r':
				read_ratio = atof(optarg);
				break;
			case 't':
				time_out = strtoul(optarg, NULL, 0);
				break;
			case 'h':
				print_help(argv[0]);
				return 0;
				break;
			default:
				print_help(argv[0]);
				return -1;
		}
	} //finished parameter parsing

	printf ("config_file_name is %s\n", config_file_name);
	printf ("read_ratio is %f\n", read_ratio);
	printf ("time_out is %u seconds\n", time_out);

	//parsing kv config file to record num_of_sets, num_of_gets
	num_of_reqs = 0;
	fp = fopen(config_file_name, "r");
	if (fp == NULL) {
		perror("Error opening file");
		return(-1);
	}
	while (fgets(str_line, sizeof(str_line), fp) != NULL) {
		num_of_reqs++;
	}
	fclose(fp);
	//allocate memory for key_size_arr, value_size_arr
	//set_req_size_arr, get_req_size_arr
	key_size_arr = malloc(num_of_reqs*sizeof(int));
	value_size_arr = malloc(num_of_reqs*sizeof(int));
	set_req_size_arr = malloc(num_of_reqs*sizeof(int));
	get_req_size_arr = malloc(num_of_reqs*sizeof(int));

	int i = 0;
	fp = fopen(config_file_name, "r");
	while (fgets(str_line, sizeof(str_line), fp) != NULL) {
		//parsing line into key value sizes
		sscanf(str_line, "%d,%d", &(key_size_arr[i]), &(value_size_arr[i]));
		i++;
	}
	fclose(fp);

	int j= 0;
	total_key_size = 0;
	total_value_size = 0;
	total_set_req_size = 0;
	total_get_req_size = 0;

	for (i=0; i<num_of_reqs; i++) {
		total_key_size += key_size_arr[i];
		total_value_size += value_size_arr[i];
		set_req_size_arr[i] = SET_HEADER_SIZE + key_size_arr[i] + value_size_arr[i];
		get_req_size_arr[i] = GET_HEADER_SIZE + key_size_arr[i];
		total_set_req_size += set_req_size_arr[i];
		total_get_req_size += get_req_size_arr[i];
	}
	//allocate memory for keys and values
	keys = malloc(total_key_size*sizeof(uint8_t));
	values = malloc(total_value_size*sizeof(uint8_t));
	uint8_t current_key=0x00;
	uint8_t current_value = 0x00;
	int key_base_addr = 0;
	int value_base_addr = 0;
	for (i=0; i<num_of_reqs; i++) {
		for (j=0; j<key_size_arr[i]; j++) {
			keys[key_base_addr+j] = current_key;
			current_key++;
		}
		key_base_addr += key_size_arr[i];
		for (j=0; j<value_size_arr[i]; j++) {
			values[value_base_addr+j] = current_value;
			current_value++;
		}
		value_base_addr += value_size_arr[i];
	}
	set_reqs = malloc(total_set_req_size*sizeof(uint8_t));
	get_reqs = malloc(total_get_req_size*sizeof(uint8_t));
	printf("allocated %u bytes to set_reqs\n", total_set_req_size*sizeof(uint8_t));	
	printf("allocated %u bytes to get_reqs\n", total_get_req_size*sizeof(uint8_t));
	//generate set_reqs
	uint16_t key_length;
	uint32_t total_body_length;
	int base_addr=0;
	key_base_addr = 0;
	value_base_addr = 0;
	for (i=0; i<num_of_reqs; i++) {
		key_length = key_size_arr[i];
		total_body_length = 8 + key_size_arr[i]+value_size_arr[i];
		for (j=0; j<SET_HEADER_SIZE; j++) {
			set_reqs[base_addr+j] = set_header[j];
		}
		set_reqs[base_addr+ 2] = (uint8_t)(key_length >> 8);
		set_reqs[base_addr+3] = (uint8_t)(key_length);
		set_reqs[base_addr+8] = (uint8_t)(total_body_length >> 24);
		set_reqs[base_addr+9] = (uint8_t)(total_body_length >> 16);
		set_reqs[base_addr+10] = (uint8_t)(total_body_length >> 8);
		set_reqs[base_addr+11] = (uint8_t)(total_body_length);
		for(j=0; j<key_size_arr[i]; j++) {
			set_reqs[base_addr+SET_HEADER_SIZE+j] = keys[key_base_addr+j];
		}
		key_base_addr += key_size_arr[i];
		for (j=0; j<value_size_arr[i]; j++) {
			set_reqs[base_addr+SET_HEADER_SIZE+key_size_arr[i]+j] = values[value_base_addr + j];
		}
		value_base_addr += value_size_arr[i];
		base_addr = base_addr+ set_req_size_arr[i];
	}

	base_addr = 0;
	key_base_addr = 0;
	for (i=0; i<num_of_reqs; i++) {
		key_length = key_size_arr[i];
		total_body_length = key_size_arr[i];
		for (j=0; j<GET_HEADER_SIZE; j++) {
			get_reqs[base_addr+j] = get_header[j];
		}
		get_reqs[base_addr+ 2] = (uint8_t)(key_length >> 8);
		get_reqs[base_addr+3] = (uint8_t)(key_length);
		get_reqs[base_addr+8] = (uint8_t)(total_body_length >> 24);
		get_reqs[base_addr+9] = (uint8_t)(total_body_length >> 16);
		get_reqs[base_addr+10] = (uint8_t)(total_body_length >> 8);
		get_reqs[base_addr+11] = (uint8_t)(total_body_length);
		for(j=0; j<key_size_arr[i]; j++) {
			get_reqs[base_addr+GET_HEADER_SIZE+j] = keys[key_base_addr+j];
		}
		key_base_addr += key_size_arr[i];
		base_addr += get_req_size_arr[i];
	}
	//dump set requests
	/*char req_str[100];
	for (i=0; i<num_of_reqs; i++) {
		sprintf(req_str, "set request %d is: ", i);
		hexDump(req_str, set_reqs+i*set_req_size_arr[i], set_req_size_arr[i]);
	}*/

	//dump get requests
	/*for (i=0; i<num_of_reqs; i++) {
		sprintf(req_str, "get request %d is: ", i);
		hexDump(req_str, get_reqs+i*get_req_size_arr[i], get_req_size_arr[i]);
	}*/
	//create udp socket and transmit requests accroding to the read_ratio
	const int port = 11211;//32773;//should be 11211. change that after changed the bitstream
	int udp_socket;
	struct in_addr def_ip;
	struct in_addr netmask;
	struct sockaddr_in si_other;
	int slen;

	inet_aton("1.1.1.1", &def_ip);
	inet_aton("255.255.255.0", netmask);
	
	udp_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (udp_socket == -1) {
		perror("socket");
		free(key_size_arr);
		free(value_size_arr);
		free(set_req_size_arr);
		free(get_req_size_arr);
		free(set_reqs);
		free(get_reqs);
		free(keys);
		free(values);
		return -1;
	}

	slen = sizeof(si_other);
	si_other.sin_family = AF_INET;
	si_other.sin_port = htons(port);
	si_other.sin_addr = def_ip;
	if (single_run == 0) {
		transmit_reqs(num_of_reqs, set_reqs, set_req_size_arr, get_reqs, get_req_size_arr, udp_socket, (struct sockaddr*) &si_other, (socklen_t) slen);
	} else {
		transmit_reqs_once(num_of_reqs, set_reqs, set_req_size_arr, udp_socket, (struct sockaddr*) &si_other, (socklen_t) slen);
		transmit_reqs_once(num_of_reqs, get_reqs, get_req_size_arr, udp_socket, (struct sockaddr*) &si_other, (socklen_t) slen);
	}
	printf("finished running...\n");
	//free memory
	free(key_size_arr);
	printf("freed key_size_arr \n");

	free(value_size_arr);
	printf("freed value_size_arr \n");

	free(set_req_size_arr);
	printf("freed set_req_size_arr \n");

	free(get_req_size_arr);
	printf("freed get_req_size_arr \n");

	free(set_reqs);
	printf("freed set_reqs\n");

	free(get_reqs);
	printf("freed get_reqs\n");

	free(keys);
	printf("freed keys\n");

	free(values);
	printf("freed values\n");
	close(udp_socket);
	return 0;
}
