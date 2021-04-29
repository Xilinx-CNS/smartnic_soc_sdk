/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <sys/ioctl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <pthread.h>
#include <errno.h>
#include "thermal.h"

#define MAX_READ_SIZE 33 //32 data bytes and 1 byte for addressing

#define I2C_BUS	 0x0
#define I2C_SLAVE_ADDR 0x48

#define DEV_ID_OFFSET 0

#define SENSORS_OP_OFFSET 120
#define SENSORS_STATUS_OFFSET 121

#define SENSOR_START 0x53
#define NEXT_SENSOR 0x4e

#define MAX_CONNECTIONS 1024
sensor_info sensor_data[100];
uint8_t device_id;
uint8_t device_ver;
uint8_t max_sensors;
typedef struct thread_info{
	pthread_t tid;
	int connfd;
}thread_info;

static int i2c_read_nbytes(int fd, uint8_t reg_addr,  uint8_t num_bytes, uint8_t *value) {
	uint8_t command[] = {reg_addr};
	struct i2c_msg messages[] = {
	{ I2C_SLAVE_ADDR, 0, sizeof(command), command },
	{ I2C_SLAVE_ADDR, I2C_M_RD, num_bytes, value },
	};
	struct i2c_rdwr_ioctl_data ioctl_data = { messages, 2 };
	int result = ioctl(fd, I2C_RDWR, &ioctl_data);
	if (result != 2)
	{
		printf("i2c read failed for addr %x error %d\n", reg_addr, errno);
		return -1;
	}

	return 0;
}

static int i2c_write_byte(int fd, uint8_t reg_addr, uint8_t value) {
	uint8_t command[] = { reg_addr, value };
	struct i2c_msg messages[] = {
	{ I2C_SLAVE_ADDR, 0, sizeof(command), command },
	};
	struct i2c_rdwr_ioctl_data ioctl_data = { messages, 1 };
	int result = ioctl(fd, I2C_RDWR, &ioctl_data);
	if (result != 1)
	{
		printf("i2c write failed for addr %x error %d\n", reg_addr, errno);
		return -1;
	}
	return 0;
}

static int sensor_data_read(){
	char read_buf[MAX_READ_SIZE];
	uint16_t reg_addr = 0;
	int i2c_fd;
	char i2c_dev[20];
	uint8_t status = 1, count = 0;

	memset(read_buf, 0 , sizeof(read_buf));
	snprintf(i2c_dev, 20, "/dev/i2c-%d", I2C_BUS);
	i2c_fd = open(i2c_dev, O_RDWR);
	if (i2c_fd < 0) {
		printf("I2C adapter device node is not available, BUS = %d err %d\n", I2C_BUS, errno);
		return -1;
	}

	if(ioctl(i2c_fd, I2C_SLAVE, I2C_SLAVE_ADDR)) {
		printf("Slave device with address 0x%x is not accessible error %d\n", I2C_SLAVE_ADDR, errno);
		goto exit_i2c;
	}

	/*Device ID verification*/
	if (i2c_read_nbytes(i2c_fd, DEV_ID_OFFSET, 2, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}
	device_id = read_buf[0];
	device_ver = read_buf[1];

	if (DEV_ID != device_id) {
		printf("I2C management Device ID is incorrect Expected:0x%x Received:0x%x\n", DEV_ID, device_id);
		goto exit_i2c;
	}

	/*Device version verification*/
	if (DEV_VERSION != device_ver) {
		printf("I2C management Device version is incorrect Expected:0x%x Received:0x%x\n", DEV_VERSION, device_ver);
		goto exit_i2c;
	}

	// Retrieving sensors information
	if (i2c_write_byte(i2c_fd, SENSORS_OP_OFFSET, SENSOR_START) < 0) {
		printf("Device write failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}

	/*Sensor status*/
	if (i2c_read_nbytes(i2c_fd, SENSORS_STATUS_OFFSET, 0x7, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}
	status = read_buf[0];
	count = 0;
	max_sensors = 0;
	while(status == 0){
		// Read Sensor ID and value
		sensor_data[count].id = (read_buf[2] << 0x8) | (read_buf[1] & 0xFF);
		sensor_data[count].value =  ((read_buf[6] << 24) | (read_buf[5] << 16) | (read_buf[4] << 8) | (read_buf[3] & 0xFF));
		count++;
		if (i2c_write_byte(i2c_fd, SENSORS_OP_OFFSET, NEXT_SENSOR) < 0) {
			printf("Device write failed for device 0x%x\n", I2C_SLAVE_ADDR);
			goto exit_i2c;
		}

		/*Sensor status*/
		if (i2c_read_nbytes(i2c_fd, SENSORS_STATUS_OFFSET, 0x7, read_buf) < 0) {
			printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
			goto exit_i2c;
		}
		status = read_buf[0];
	}
	max_sensors = count;
	close(i2c_fd);
	return 0;

exit_i2c:
	close(i2c_fd);
	return -1;
}

void * thread_func(void * arg)
{
	thread_info *thread_temp_data = (thread_info *)arg;
	int sockfd = thread_temp_data->connfd, ret;
	char buff[BUF_SIZE];
	uint8_t ack;
	struct device_info *data;
	interface_data comm_data;
	char cmd[100];
	response_codes load_response = SUCCESS;
	uint16_t size;

	while(1) {
		bzero(buff, BUF_SIZE);

		// read the message from client and copy it in buffer
		if ((ret = recv(sockfd, &comm_data, BUF_SIZE, 0)) == -1)
		{
			printf("recv() failed, error %d\n", errno);
			break;
		}
		/*Exiting if the connection is closed*/
		if(ret == 0)
		{
			printf("connection closed\n");
			break;
		}

		if(strcmp(comm_data.command, "load") == 0){
			if(comm_data.load_interval <= 100 && comm_data.load_interval > 0){
				ret = system("pidof stress-ng > /dev/null");
				if(ret == 0) {
					printf("A process of similar kind is already running, please try after some time\n");
					load_response = PROCESS_RUNNING;
				}
				if (send(sockfd, &load_response, sizeof(load_response), 0) != sizeof(load_response))
				{
					printf("send() failed, error %d\n", errno);
					break;
				}
				if(load_response == PROCESS_RUNNING)
					break;
				snprintf(cmd,100, "stress-ng -c 0 -l %d -t %s", comm_data.load_interval, comm_data.load_duration);
				system(cmd);
			}
			else if(comm_data.load_interval == 0){
				ret = system("pidof stress-ng > /dev/null");
				if(ret == 0) {
					system("pkill -9 -f stress-ng");
				}
				if (send(sockfd, &load_response, sizeof(load_response), 0) != sizeof(load_response))
				{
					printf("send() failed, error %d\n", errno);
					break;
				}
			}
			else{
				printf("Requested load is not supported, load = %d \n", comm_data.load_interval);
				load_response = FAILURE;
				if (send(sockfd, &load_response, sizeof(load_response), 0) != sizeof(load_response))
				{
					printf("send() failed, error %d\n", errno);
					break;
				}
			}
		}
		else if(strcmp(comm_data.command, "sensordata") == 0) {
			ret = sensor_data_read();
			size = sizeof(struct device_info) + (max_sensors * sizeof(sensor_info));
			data = malloc(size);
			if(data == NULL){
				printf("unable to allocate malloc memory, error %d\n", errno);
				pthread_exit(NULL);
			}
			data->device_id = device_id;
			data->device_ver = device_ver;
			data->max_sensors = max_sensors;

			if(ret < 0)
			{
				printf("Failed to retrive sensor data\n");
				data->response = FAILURE;
			}
			else{
				data->response = SUCCESS;
				memcpy(data->sensor_data, &sensor_data, (max_sensors * sizeof(sensor_info)));
			}

			if (send(sockfd, (void *)data, size, 0) != size)
			{
				printf("send() failed, error %d\n", errno);
				free(data);
				break;
			}
			free(data);
		}
	}

	close(sockfd);
	free(arg);
	pthread_exit(NULL);
}

int main(int argc, char**argv) {
	int server_sock, sockopt, addr_len;
	uint16_t port = SERV_TCP_PORT;
	struct sockaddr_in server_addr;
	struct sockaddr_storage cl_addr;
	pthread_t tid;
	int ret;
	thread_info *thread_data;

	if (argc > 2) {
	  printf("usage: ./thermalload <tcp_port(optional)>\n");
	  exit(1);
	}

	if (argc > 1) {
	  port = strtoul(argv[1], NULL, 10);
	}

	// create the server socket
	server_sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if(server_sock < 0){
		printf("Error in connection.error: %d\n", errno);
		exit(1);
	}

	sockopt = 1;
	/* Allow the socket to be reused - incase connection is closed prematurely */
	if (setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &sockopt, sizeof(sockopt)) < 0) {
		printf("setsockopt for SO_REUSEADDR is failed error: %d\n", errno);
		close(server_sock);
		exit(1);
	}

	server_addr.sin_family = AF_INET;
	server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	server_addr.sin_port = htons(port);

	//bind the socket to localhost port, default value is 4444
	if (bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
	{
		printf("bind failed error:%d \n", errno);
		close(server_sock);
		exit(1);
	}

	// make socket listening
	if (listen(server_sock, MAX_CONNECTIONS) < 0)
	{
		printf("listen failed %d \n", errno);
		close(server_sock);
		exit(1);
	}
	/*set detachable state for pthreads*/
	pthread_attr_t attr;
	ret = pthread_attr_init(&attr);
	if (ret != 0)
	{
		printf("pthread_attr_init failed, error %d\n", errno);
		exit(1);
	}
	ret = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	if (ret != 0){
		printf("pthread_attr_setdetachstate failed, error %d\n", errno);
		exit(1);
	}

	addr_len = sizeof(cl_addr);
	while(1) {
		thread_data = (thread_info*) malloc(sizeof(thread_info));
		// Accept the data packet from client and verification
		thread_data->connfd = accept(server_sock, (struct sockaddr *) &cl_addr, &addr_len);
		if (thread_data->connfd < 0) {
			printf("server acccept failed..., error %d\n", errno);
			close(server_sock);
			free(thread_data);
			exit(1);
		}
		else {
			if( pthread_create(&thread_data->tid, &attr, &thread_func, thread_data) != 0) {
				printf("Failed to create thread error: %d\n", errno);
				close(server_sock);
				free(thread_data);
				exit(1);
			}
		}
	}
	close(server_sock);
}
