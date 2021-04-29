/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <string.h>
#include <sys/mman.h>
#include <getopt.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>
#include <linux/if.h>
#include <errno.h>
#include <pthread.h>
#include <linux/ip.h>
#include <termios.h>
#include <linux/i2c.h>
#include <dirent.h>
 
#define BUFF_SIZE 100

/*Global Variables*/
static uint8_t i2c_val[] = {0x55, 0xAA, 0xFF, 0x0};
static uint32_t dev_id = 0x9038;

#define SUC_I2C_BUS	 0x0
#define SUC_MD_I2C_ADDR 0x48
#define SUC_MD_DEV_ID   0x53
#define SUC_MD_DEV_VERSION   0x01

#define SUC_MD_I2C_DEV_ID_OFFSET 0x0
#define SUC_MD_I2C_DEV_VER_OFFSET 0x1
#define SUC_MD_I2C_SCRATCHPAD_OFFSET 0x9

#define SUC_EEPROM_I2C_ADDR 0x50
#define SUC_EEPROM_BLOCK_SIZE 32

#define SUC_EEPROM_TEST_SIZE 382
#define SUC_EEPROM_TEST_OFFSET 641

char mem[10] = "100M";
char ddr_test_infinite[10] = "no";
char stresstest_options[70] = "-s 20 -M 512 -m 8 -C 8 -W";

typedef enum test_result
{
	TEST_PASS,
	TEST_FAIL,
	TEST_NOT_RUN,
	TEST_MAX_STATUS_VALUES
} test_result;

const char *test_result_str[TEST_MAX_STATUS_VALUES] =
{
	"PASS",
	"FAIL",
	"NOT RUN"
};

test_result eth1g_result = TEST_FAIL;

/*Function Declarations*/
test_result ddr_test();
test_result pcie_test();
test_result i2c_md_test();
test_result i2c_eeprom_test();
test_result uart_test();
test_result eth_1g_test();
test_result eth_25g_test();
test_result stressapptest_test();

typedef test_result(*test_case)();
typedef struct test_def
{
	test_case   test_case_func;
	char		*test_name_ptr;
} test_def;

static test_def diag_tests[] =
{
	{pcie_test,	 "PCIe"},
	{ddr_test,	  "DDR"},
	{i2c_md_test,   "I2C Management device"},
	{i2c_eeprom_test,   "I2C EEPROM device"},
	{uart_test,	  "UART"},
	{eth_1g_test, "1G Interface"},
	{eth_25g_test, "25G Interface"},
	{stressapptest_test,	  "stressapptest"},
};

static int is_iface_present(int dpni)
{
	char directory[BUFF_SIZE];
	DIR* dir;

	snprintf(directory, BUFF_SIZE, "/sys/bus/fsl-mc/devices/dpni.%d/net/", dpni);

	dir = opendir(directory);
	if (dir) {   /* directory exists */
		closedir(dir);
		return 1;
	}

	/* directry does not exist */
	return 0;
}

static void get_iface_name(int dpni, char *iface_name)
{
	char cmd[BUFF_SIZE];
	FILE *fptr = NULL;

	snprintf(cmd, BUFF_SIZE, "ls /sys/bus/fsl-mc/devices/dpni.%d/net/ > test.txt", dpni);
	system(cmd);
	fptr = fopen("test.txt", "r");
	fgets(iface_name, 10, fptr);
	fclose(fptr);
}

void *packet_receive(void *socket)
{
	int sock = *((int *)socket);
	char rcv_buff[256];
	int i = 0, ret = 0;
	int timeout = 100;

	while(timeout--) {
		ret = recvfrom(sock, rcv_buff, 256, 0, NULL, NULL);
		if (ret < 0)
			printf("recvfrom system call failed. Error: %s\n", strerror(errno));
		
		if((rcv_buff[0] == 0xFF) && (rcv_buff[1] == 0xFF) && (rcv_buff[2] == 0xFF) && (rcv_buff[3] == 0xFF) && (rcv_buff[4] == 0xFF) & (rcv_buff[5] == 0xFF)) {
				/* Validating the payload */
				if ((rcv_buff[34] == 0xde) && (rcv_buff[35] == 0xad) && (rcv_buff[36] == 0xbe) && (rcv_buff[37] == 0xef))
					eth1g_result = TEST_PASS;
				break;
		}
	}
}

test_result eth_1g_test()
{
	int sock;
	struct sockaddr_ll address;
	struct ifreq if_idx;
	uint16_t tx_len = 0;
	char send_buff[256];
	char iface_name[10];
	struct ether_header *eh = (struct ether_header *) send_buff;
	struct iphdr *iph = (struct iphdr *) (send_buff + sizeof(struct ether_header));
	pthread_t thread_id;

	/* If 1G interface is not present, Don't run the test */
	if(!is_iface_present(0)) {
		printf("1G interface is not enabled\n");
		return TEST_NOT_RUN;
	}

	/* Dynamically detecting the interface name for 1G */
	get_iface_name(0, iface_name);

	/* Socket creation */
	sock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if (sock < 0) {
		printf("Error in socket creation. Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}

	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, iface_name, 7);
	if (ioctl(sock, SIOCGIFINDEX, &if_idx) < 0) {
	    printf("IOCTL SIOCGIFINDEX Failed. Error: %s\n", strerror(errno));
	    return TEST_FAIL;
	}

	address.sll_ifindex = if_idx.ifr_ifindex; // index of interface
	address.sll_halen = ETH_ALEN; // length of destination mac address
	address.sll_family = AF_PACKET;
	address.sll_protocol = htons(ETH_P_ALL);
	address.sll_addr[0] = 0xFF;
	address.sll_addr[1] = 0xFF;
	address.sll_addr[2] = 0xFF;
	address.sll_addr[3] = 0xFF;
	address.sll_addr[4] = 0xFF;
	address.sll_addr[5] = 0xFF;

	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, iface_name, 7);
	if (ioctl(sock, SIOCGIFHWADDR, &if_idx) < 0) {
	    printf("IOCTL SIOCGIFHWADDR Failed. Error: %s\n", strerror(errno));
	    return TEST_FAIL;
	}

	/*Create the packet to send / receive */
	memset(send_buff, 0, 256);
	/* Ethernet header */
	eh->ether_shost[0] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[0];
	eh->ether_shost[1] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[1];
	eh->ether_shost[2] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[2];
	eh->ether_shost[3] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[3];
	eh->ether_shost[4] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[4];
	eh->ether_shost[5] = ((uint8_t *)&if_idx.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = 0xFF;
	eh->ether_dhost[1] = 0xFF;
	eh->ether_dhost[2] = 0xFF;
	eh->ether_dhost[3] = 0xFF;
	eh->ether_dhost[4] = 0xFF;
	eh->ether_dhost[5] = 0xFF;
	eh->ether_type = htons(ETH_P_IP);
	tx_len += sizeof(struct ether_header);

	iph->ihl = 5;
	iph->version = 4;
	tx_len +=  sizeof(struct iphdr);

	/* Payload Data */
	send_buff[tx_len++] = 0xde;
	send_buff[tx_len++] = 0xad;
	send_buff[tx_len++] = 0xbe;
	send_buff[tx_len++] = 0xef;

	iph->tot_len = htons(tx_len - sizeof(struct ether_header));

	/* Run a thread in background to receive packets */
	if (pthread_create(&thread_id, NULL, packet_receive, (void *)&sock) != 0)
		printf("Error in Thread creation. Error: %s\n", strerror(errno));

	/* Send packets on the socket */
	if (sendto(sock, send_buff, tx_len, 0, (struct sockaddr *)&address, sizeof(address)) < 0) {
		printf("Error in sending packets. Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}

	/* Wait for the thread to terminate */
	if (pthread_join(thread_id, NULL) != 0)
		printf("Error in pthread join. Error: %s\n", strerror(errno));

	close(sock);

	return eth1g_result;
}

test_result eth_25g_test()
{
	/* If 25G interface is not present, Don't run the test */
	if(!is_iface_present(1)) {
		printf("25G interface is not enabled\n");
		return TEST_NOT_RUN;
	}

	printf("25G test not supported Yet!\n");
	return TEST_NOT_RUN;
}

static int serial_read(int fd, char* rx_buffer) {

	int nbytes_read = 0;

	nbytes_read = read(fd, rx_buffer, 100);
	if (nbytes_read < 0) {
		printf("Read from serial device failed. Error: %s", strerror(errno));
		return -1;
	}

	return nbytes_read;
}

static int serial_write(int fd, const char* tx_buffer) {

	int nbytes_written = 0;

	nbytes_written = write(fd, (const char *)tx_buffer, strlen(tx_buffer));
	if (nbytes_written != (ssize_t)strlen(tx_buffer)) {
		printf("Write to serial device failed. Error: %s", strerror(errno));
		return -1;
	}

	return nbytes_written;
}

test_result uart_test()
{
	int serial_fd;
	int rv = 0;
	char rx_buff[100];
	char tx_buff[100] = "Testing SOC-FPGA Serial Loopback Test";
	char serial_dev[20] = "/dev/ttyAMA1";
	struct termios SerialPortSettings;

	serial_fd = open (serial_dev, O_RDWR | O_NOCTTY | O_NDELAY);
	if (serial_fd < 0) {
		printf("UART device node is not available. Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}

	if((tcgetattr(serial_fd, &SerialPortSettings)) < 0) {		/* Get the current attributes of the Serial port */
	    printf("\n  ERROR ! in Getting attributes. Error: %s", strerror(errno));
	    goto exit_uart;		
	}
	
	if ((cfsetispeed(&SerialPortSettings,B115200)) < 0) { /* Set Read  Speed as 115200 */
		printf("\n  Failed to set Input baud rate. Error: %s", strerror(errno));
		goto exit_uart;
	}
	
	if ((cfsetospeed(&SerialPortSettings,B115200)) < 0) { /* Set Write Speed as 115200 */
		printf("\n  Failed to set Output baud rate. Error: %s", strerror(errno));
		goto exit_uart;	
	}

	/* Configuring it in Raw mode */
	SerialPortSettings.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
			| INLCR | IGNCR | ICRNL | IXON);
	SerialPortSettings.c_oflag &= ~OPOST;
	SerialPortSettings.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	SerialPortSettings.c_cflag &= ~(CSIZE | PARENB);
	SerialPortSettings.c_cflag |= CS8;

	if((tcsetattr(serial_fd,TCSANOW,&SerialPortSettings)) < 0) {/* Set the attributes */
	    printf("\n  ERROR ! in Setting attributes. Error: %s", strerror(errno));
	    goto exit_uart;
	}

	/* loopback test */
	rv = serial_write(serial_fd, tx_buff);
	if (rv < 0)
		goto exit_uart;

	/* Have a delay of 1sec before read*/
	sleep(1);

	memset(rx_buff, 0, sizeof(rx_buff));
	rv = serial_read(serial_fd, rx_buff);
	if (rv < 0)
		goto exit_uart;

	if (strcmp(rx_buff, tx_buff) != 0) {
		printf("Data validation failed\n");
		goto exit_uart;
	}

	close(serial_fd);
	return TEST_PASS;

exit_uart:
	close(serial_fd);
	return TEST_FAIL;
}

test_result ddr_test()
{
	test_result test_status = TEST_NOT_RUN;
	char cmd[BUFF_SIZE], buffer[BUFF_SIZE];
	int ret;
	FILE *fd;

	if (strcmp(ddr_test_infinite,"yes") == 0)
		snprintf(cmd, BUFF_SIZE, "memtester %s > ddr_test.txt", mem);
	else
		snprintf(cmd, BUFF_SIZE, "memtester %s 1 > ddr_test.txt", mem);

	system(cmd);
	fd = popen("echo $?", "r");
	if(fd == NULL) {
		fprintf(stderr, "Could not open pipe. Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}
	fgets(buffer, BUFF_SIZE, fd);
	ret = (unsigned long)strtol(buffer, NULL, 16);

	if(!ret)
		test_status = TEST_PASS;
	else
		test_status = TEST_FAIL;
	return test_status;

}

test_result stressapptest_test()
{
	test_result test_status = TEST_NOT_RUN;
	char cmd[BUFF_SIZE], buffer[BUFF_SIZE];
	int ret;
	FILE *fd;

	snprintf(cmd, BUFF_SIZE, "stressapptest %s > sat.txt", stresstest_options);

	system(cmd);
	fd = popen("echo $?", "r");
	if(fd == NULL) {
		fprintf(stderr, "Could not open pipe.Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}
	fgets(buffer, BUFF_SIZE, fd);
	ret = (unsigned long)strtol(buffer, NULL, 16);

	if(!ret)
		test_status = TEST_PASS;
	else
		test_status = TEST_FAIL;
	return test_status;

}

test_result pcie_test()
{
	int i = 0, bus, device, func;
	unsigned long offset = 0;
	char cmd[BUFF_SIZE];
	unsigned int value[] = {0x1122, 0x1456, 0xAA55, 0x1936, 0x55AA, 0x1234};
	test_result test_status = TEST_PASS;
	FILE *fd;
	int fd2;
	char buffer[BUFF_SIZE], bdf[20] = "ff:ff.f", bdf2[20], *token, *token2;
	uint64_t addr;
	uint32_t read_val = 0;
	void *bar_addr;

	snprintf(cmd,BUFF_SIZE,"lspci -d:%x | awk '{print $1}'", dev_id);
	fd = popen(cmd, "r");
	if (fd == NULL) {
		printf("Could not open pipe. Error: %s\n", strerror(errno));
		return TEST_FAIL;
	}
	
	fgets(bdf, BUFF_SIZE, fd);
	if (!strncmp(bdf,"ff:ff.f", sizeof(bdf))) {
		printf("No device found with device id %x\n", dev_id);
		goto exit_pcie;
	}

	/*Decoding bus, device, function number*/
	strcpy (bdf2, bdf);
	token= strtok(bdf, ":");
	bus = strtoul(token, NULL, 16);
	token = strtok(NULL, ":");
	device = strtoul(token, NULL, 16);
	token2 = strtok(bdf2, ".");
	token2 = strtok(NULL, ".");
	func = strtoul(token2, NULL, 16);

	snprintf(cmd,BUFF_SIZE,"/sys/bus/pci/devices/0000:%.2x:%.2x.%x/resource0", bus, device, func);
	fd2 = open(cmd, O_RDWR | O_SYNC);
	if (fd2 < 0) {
		printf("Not able to open the PCIe device. Error: %s\n", strerror(errno));
		goto exit_pcie;
	}
	bar_addr = mmap(0, 8192, PROT_READ | PROT_WRITE, MAP_SHARED, fd2, 0);
	if(bar_addr == NULL){
		printf("Failed to map the pci memory\n");
		test_status = TEST_FAIL;
		goto exit_pcie1;
	}
	addr = (uint64_t)bar_addr;

	/* Read/Write to 8K Memory */
	for (offset = 0; offset < 0x2000; offset=offset+4) {
		for (i = 0; i < 6; i++) {
			*((volatile uint32_t *)(addr + offset)) = value[i];
			read_val = *((volatile uint32_t *)(addr + offset));
			if(read_val != value[i])
			{
				printf("data mismatch error at addr = 0x%lx expected = 0x%x, received = 0x%x\n", (addr + offset), value[i], read_val);
				test_status = TEST_FAIL;
				goto exit_pcie1;
			}
		}
	}

exit_pcie1:
	close(fd2);
exit_pcie:	
	pclose(fd);


	return test_status;
}

static int suc_i2c_read(int file, uint8_t reg_addr, uint8_t *value) {

    uint8_t command[] = { reg_addr };
    struct i2c_msg messages[] = {
    { SUC_MD_I2C_ADDR, 0, sizeof(command), command },
    { SUC_MD_I2C_ADDR, I2C_M_RD, 1, value },
    };
    struct i2c_rdwr_ioctl_data ioctl_data = { messages, 2 };
    int result = ioctl(file, I2C_RDWR, &ioctl_data);
    if (result != 2)
    {
        printf("i2c read failed for addr %x. Error: %s\n", reg_addr, strerror(errno));
        return -1;
    }
    return 0;
}

static int suc_i2c_write(int file, uint8_t reg_addr, uint8_t value) {
    uint8_t command[] = { reg_addr, value };
    struct i2c_msg messages[] = {
    { SUC_MD_I2C_ADDR, 0, sizeof(command), command },
    };
    struct i2c_rdwr_ioctl_data ioctl_data = { messages, 1 };
    int result = ioctl(file, I2C_RDWR, &ioctl_data);
    if (result != 1)
    {
        printf("i2c write failed for addr %x. Error: %s \n", reg_addr, strerror(errno));
        return -1;
    }
    return 0;
}

test_result i2c_md_test()
{
	int i2c_fd, i = 0;
	char i2c_dev[20];
	char buf[4];
	test_result test_status = TEST_PASS;

	snprintf(i2c_dev, 20, "/dev/i2c-%d", SUC_I2C_BUS);
	i2c_fd = open(i2c_dev, O_RDWR);
	if (i2c_fd < 0) {
		printf("I2C adapter device node is not available, BUS = %d. Error: %s \n", SUC_I2C_BUS, strerror(errno));
		return TEST_FAIL;
	}

	if(ioctl(i2c_fd, I2C_SLAVE, SUC_MD_I2C_ADDR)) {
		printf("Slave device with address 0x%x is not accessible. Error: %s\n", SUC_MD_I2C_ADDR, strerror(errno));
		goto exit_i2c;
	}

	/*Device ID verification*/
	if (suc_i2c_read(i2c_fd, SUC_MD_I2C_DEV_ID_OFFSET, buf) < 0) {
		printf("Device read failed for device 0x%x\n", SUC_MD_I2C_ADDR);
		goto exit_i2c;
	}

	if (SUC_MD_DEV_ID != buf[0]) {
		printf("I2C management Device ID is incorrect Expected:0x%x Received:0x%x\n", SUC_MD_DEV_ID, buf[0]);
		goto exit_i2c;
	}
	/*Device version verification*/
	if (suc_i2c_read(i2c_fd, SUC_MD_I2C_DEV_VER_OFFSET, buf) < 0) {
		printf("Device read failed for device 0x%x\n", SUC_MD_I2C_ADDR);
		goto exit_i2c;
	}

	if (SUC_MD_DEV_VERSION != buf[0]) {
		printf("I2C management Device version is incorrect Expected:0x%x Received:0x%x\n", SUC_MD_DEV_VERSION, buf[0]);
		goto exit_i2c;
	}
	/*scratch pad register read/write verification*/
	for(i = 0; i < (sizeof(i2c_val)/sizeof(i2c_val[0])); i++) {
		if (suc_i2c_write(i2c_fd, SUC_MD_I2C_SCRATCHPAD_OFFSET, i2c_val[i]) < 0) {
			printf("Device write failed for device 0x%x\n", SUC_MD_I2C_ADDR);
			goto exit_i2c;
		}
		if (suc_i2c_read(i2c_fd, SUC_MD_I2C_SCRATCHPAD_OFFSET, buf) < 0) {
			printf("Device read failed for device 0x%x\n", SUC_MD_I2C_ADDR);
			goto exit_i2c;
		}

		if (i2c_val[i] != buf[0]) {
			printf("I2C management Device data mismatch error, Expected:0x%x Received:0x%x\n", i2c_val[i], buf[0]);
			goto exit_i2c;
		}
	}
	close(i2c_fd);
	return test_status;

exit_i2c:
	close(i2c_fd);
	return TEST_FAIL;
}

test_result i2c_eeprom_test()
{
	unsigned char wr_buffer[SUC_EEPROM_TEST_SIZE];
	unsigned char rd_buffer[SUC_EEPROM_TEST_SIZE];
	char cmd[BUFF_SIZE];
	FILE *wptr, *rptr;

	for(int j = 0; j < (sizeof(i2c_val)/sizeof(i2c_val[0])); j++)
	{
		wptr = fopen("/tmp/write.bin","wb");  // w for write, b for binary

		/* fill in the values */
		for(int i = 0; i < SUC_EEPROM_TEST_SIZE; i++)
			wr_buffer[i] = i2c_val[j];

		fwrite(wr_buffer, sizeof(char), sizeof(wr_buffer), wptr);

		fclose(wptr);

		/* Write to EEPROM */
		snprintf(cmd, BUFF_SIZE, "dd if=/tmp/write.bin of=/sys/bus/i2c/devices/0-0050/eeprom bs=1 count=%d seek=%d > /dev/null 2>&1", SUC_EEPROM_TEST_SIZE, SUC_EEPROM_TEST_OFFSET);
		system(cmd);

		/* Have a delay of 1 sec */
		sleep(1);

		/* Read from EEPROM */
		snprintf(cmd, BUFF_SIZE, "dd if=/sys/bus/i2c/devices/0-0050/eeprom of=/tmp/read.bin bs=1 count=%d skip=%d > /dev/null 2>&1", SUC_EEPROM_TEST_SIZE, SUC_EEPROM_TEST_OFFSET);
		system(cmd);

		rptr = fopen("/tmp/read.bin","rb");  // r for read, b for binary

		fread(rd_buffer,sizeof(char),sizeof(rd_buffer),rptr); // read 10 bytes to our buffer

		/* Compare the two arrays */
		for (int i = 0; i < SUC_EEPROM_TEST_SIZE; i++)
		{
			if (wr_buffer[i] != rd_buffer[i]) 
			{
				fclose(rptr);
				system("rm -rf /tmp/write.bin");
				system("rm -rf /tmp/read.bin");
				return TEST_FAIL;
			}
		}

		fclose(rptr);
		system("rm -rf /tmp/write.bin");
		system("rm -rf /tmp/read.bin");
	}

	return TEST_PASS;
}

int diag_usage()
{
	printf("usage :\n./diagnostics --pcie <devid DEVID> <iter N> -- Pass iter 0 for infinite test\n");
	printf("./diagnostics --ddr <iter N> <memory N |K|M|G|> -- Pass iter=0 for infinite test\n");
	printf("./diagnostics --i2cmd\n");
	printf("./diagnostics --i2ceeprom\n");
	printf("./diagnostics --uart\n");
	printf("./diagnostics --eth1g\n");
	printf("./diagnostics --eth25g\n");
	printf("./diagnostics --stressapptest [s <seconds> M <mbytes> m <mem threads> C <cpu threads> <options>] e.g. s 60 M 512 m 8 C 8\n");
	printf("./diagnostics --all <devid PCIE_DEVID> <iter N>\n");
	printf("./diagnostics --help, to get this menu\n");
	return 0;
}

int main(int argc, char **argv)
{
	test_result *result_list_ptr = NULL;
	uint16_t i = 0, j = 0, iter = 1;
	uint8_t num_tests, all_test_index = 0;
	int cmd_opt, option_index;
	bool infinite = false;
	static struct option const diag_long_opts[] = {
	{"pcie", 2, 0, 'p'},
	{"ddr", 2, 0, 'd'},
	{"stressapptest", 2, 0, 's'},
	{"i2cmd", 0, 0, 'm'},
	{"i2ceeprom", 0, 0, 'e'},
	{"uart", 0, 0, 'u'},
	{"eth1g", 0, 0, 'o'},
	{"eth25g", 0, 0, 't'},
	{"all", 2, 0, 'a'},
	{"help", 0, 0, 'h'},
	{NULL, 0, 0, 0}
	};

	if(argc == 1)
	{
		diag_usage();
		return 0;
	}
	num_tests = sizeof(diag_tests) / sizeof(test_def);
	result_list_ptr = malloc(sizeof(test_result) * num_tests);
	if(result_list_ptr == NULL) {
		printf("Unable to allocate the memory\n");
		return -1;
	}

	/*Initialize each test result to NOT RUN*/
	for (i = 0; i < num_tests; i++)
	{
		result_list_ptr[i] = TEST_NOT_RUN;
	}
	while ((cmd_opt = getopt_long(argc, argv, "", diag_long_opts,
						&option_index)) != -1) {
		switch (cmd_opt) {
			case 'p':
				iter = 1;

				if (argc > 2) {
					int i = 0;
					while (0 == strstr(argv[i], diag_long_opts[option_index].name)){
						++i;
					}
					++i;

					while (i < argc) {
						if (0 == strcmp("iter", argv[i])) {
							++i;

							if (i < argc) {
								iter = atoi(argv[i]);
								if (iter == 0) {
									infinite = true;
									iter = 1;
								}
								++i;
							}
						}
						else if (0 == strcmp("devid", argv[i])){
							++i;

							if (i < argc) {
								dev_id = strtoul(argv[i], NULL, 16);
								++i;
							}
						}
						else if ('-' == argv[i][0]) {
							break;
						}
						else {
							printf("Ignoring invalid option [%s]\n", argv[i]);
							break;
						}
					}
				}

				printf("Test: %s, Args= iterations: %d %s, Device Id: %0X\n",
						diag_tests[0].test_name_ptr, iter, (infinite ? "Infinite" : ""), dev_id);

				while (iter) {
					result_list_ptr[0] = diag_tests[0].test_case_func();
					printf("Test: %s: %s\n", diag_tests[0].test_name_ptr, test_result_str[result_list_ptr[0]]);
					if (false == infinite)
						--iter;
				}
				break;
			case 'd':
				iter = 1;

				if (argc > 2) {
					int i = 0;
					while (0 == strstr(argv[i], diag_long_opts[option_index].name)){
						++i;
					}
					++i;

					while (i < argc) {
						if (0 == strcmp("iter", argv[i])) {
							++i;

							if (i < argc) {
								iter = atoi(argv[i]);
								if (iter == 0) {
									strcpy(ddr_test_infinite, "yes");
									infinite = true;
									iter = 1;
								}
								++i;
							}
						}
						else if (0 == strcmp("memory", argv[i])){
							++i;

							if (i < argc) {
								strcpy(mem, argv[i]);
								++i;
							}
						}
						else if ('-' == argv[i][0]) {
							break;
						}
						else {
							printf("Ignoring invalid option [%s]\n", argv[i]);
							break;
						}
					}
				}
				printf("Test: %s, Args= iterations: %d %s, Memory: %s\n",
						diag_tests[1].test_name_ptr, iter, (infinite ? "Infinite" : ""), mem);
				while (iter--) {
					result_list_ptr[1] = diag_tests[1].test_case_func();
					printf("Test: %s: %s\n", diag_tests[1].test_name_ptr, test_result_str[result_list_ptr[1]]);
				}
				break;
			case 'm':
				result_list_ptr[2] = diag_tests[2].test_case_func();
				printf("Test: %s: %s\n", diag_tests[2].test_name_ptr, test_result_str[result_list_ptr[2]]);
				break;
			case 'e':
				result_list_ptr[3] = diag_tests[3].test_case_func();
				printf("Test: %s: %s\n", diag_tests[3].test_name_ptr, test_result_str[result_list_ptr[3]]);
				break;
			case 'u':
				result_list_ptr[4] = diag_tests[4].test_case_func();
				printf("Test: %s: %s\n", diag_tests[4].test_name_ptr, test_result_str[result_list_ptr[4]]);
				break;
			case 'o':
				result_list_ptr[5] = diag_tests[5].test_case_func();
				printf("Test: %s: %s\n", diag_tests[5].test_name_ptr, test_result_str[result_list_ptr[5]]);
				break;
			case 't':
				result_list_ptr[6] = diag_tests[6].test_case_func();
				printf("Test: %s: %s\n", diag_tests[6].test_name_ptr, test_result_str[result_list_ptr[6]]);
				break;
			case 's':
				if (argc > 2) {
					int i = 0, opt_sz = 70;
					bool ov_seconds = true, ov_ram = true, ov_th = true, ov_cores = true, ov_cpustress = true;
					char *val_seconds = "20 ", *val_ram = "512 ", *val_th = "8 ", *val_cores = "8 ";

					strncpy(stresstest_options, "", opt_sz);

					while (0 == strstr(argv[i], diag_long_opts[option_index].name)){
						++i;
					}
					++i;

					for (; i < argc; ++i) {
						if ((argv[i][0] >= 'a' || argv[i][0] >= 'A') && (argv[i][0] <= 'z' || argv[i][0] <= 'Z')) {
							switch (argv[i][0]) {
								case 's' : ov_seconds = false; 		break;
								case 'M' : ov_ram = false; 			break;
								case 'm' : ov_th = false; 			break;
								case 'c' : ov_cores = false; 		break;
								case 'W' : ov_cpustress = false; 	break;
							}
							strncat(stresstest_options, "-", opt_sz);
							opt_sz -= strlen("-");
						}
						else if (argv[i][0] == '-') {
							break;
						}
						strncat(stresstest_options, argv[i], opt_sz);
						opt_sz -= strlen(argv[i]);
						strncat(stresstest_options, " ", opt_sz);
						opt_sz -= strlen(" ");
					}
					if (true == ov_seconds) {
						strncat(stresstest_options, "-s ", opt_sz);
						opt_sz -= strlen("-s ");
						strncat(stresstest_options, val_seconds, opt_sz);
						opt_sz -= strlen(val_seconds);
					}
					if (true == ov_ram) {
						strncat(stresstest_options, "-M ", opt_sz);
						opt_sz -= strlen("-M ");
						strncat(stresstest_options, val_ram, opt_sz);
						opt_sz -= strlen(val_ram);
					}
					if (true == ov_th) {
						strncat(stresstest_options, "-m ", opt_sz);
						opt_sz -= strlen("-m ");
						strncat(stresstest_options, val_th, opt_sz);
						opt_sz -= strlen(val_th);
					}
					if (true == ov_cores) {
						strncat(stresstest_options, "-c ", opt_sz);
						opt_sz -= strlen("-c ");
						strncat(stresstest_options, val_cores, opt_sz);
						opt_sz -= strlen(val_cores);
					}
					if (true == ov_cpustress) {
						strncat(stresstest_options, "-W ", opt_sz);
					}

				}
				printf("Test: %s, Args= %s\n", diag_tests[7].test_name_ptr, stresstest_options);
				result_list_ptr[7] = diag_tests[7].test_case_func();
				printf("Test: %s: %s\n", diag_tests[7].test_name_ptr, test_result_str[result_list_ptr[7]]);
				break;
			case 'a':
				iter = 1;

				if (argc > 2) {
					i = 0;
					while (0 == strstr(argv[i], diag_long_opts[option_index].name)){
						++i;
					}
					++i;

					while (i < argc) {
						if (0 == strcmp("iter", argv[i])) {
							++i;

							if (i < argc) {
								iter = atoi(argv[i]);
								if (iter == 0) {
									iter = 1;
								}
								++i;
							}
						}
						else if (0 == strcmp("devid", argv[i])){
							++i;

							if (i < argc) {
								dev_id = strtoul(argv[i], NULL, 16);
								++i;
							}
						}
						else {
							printf("Ignoring invalid option [%s]\n", argv[i]);
							break;
						}
					}
				}
				/*Iterate over testcases*/
				for (j = 0; j < iter; j++) {
					printf("Iteration : %u\n", j + 1);
					printf("------------------------\n");
					for (i = 0; i < num_tests; i++)
					{
						result_list_ptr[i] = diag_tests[i].test_case_func();
						printf("Test: %s: %s\n", diag_tests[i].test_name_ptr, test_result_str[result_list_ptr[i]]);
					}
					printf("\n");
				}
				break;
			case '?':
			case 'h':
				diag_usage();
				break;
			default:
				break;
		}
	}

	/*Deallocate results table*/
	free(result_list_ptr);
	result_list_ptr = NULL;
	return 0;
}
