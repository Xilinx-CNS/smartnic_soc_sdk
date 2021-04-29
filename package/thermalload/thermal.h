/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <getopt.h>
#include <strings.h>

#define SERV_TCP_PORT 4444
#define BUF_SIZE 2000

#define DEV_ID   0x53
#define DEV_VERSION   0x01

#pragma pack(1)
typedef struct sensor_info{
	uint16_t id;
	uint32_t value;
}sensor_info;

typedef struct interface_data{
char command[30];
uint16_t load_interval;
char load_duration[20];
}interface_data;

typedef enum response_codes{
	SUCCESS=0,
	FAILURE,
	PROCESS_RUNNING
}response_codes;

struct device_info{
	uint8_t device_id;
	uint8_t device_ver;
	uint8_t max_sensors;
	response_codes response;
	sensor_info sensor_data[0];
};
#pragma pack(0)
int is_valid_ip(char *ipaddr)
{
	struct sockaddr_in sa;
	int result = inet_pton(AF_INET, ipaddr, &(sa.sin_addr));

	return result;
}
