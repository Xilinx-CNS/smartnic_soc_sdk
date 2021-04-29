/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <linux/i2c-dev.h>
#include <linux/gpio.h>
#include <linux/i2c.h>
#include <errno.h>

#define MAX_READ_SIZE 33 //32 data bytes and 1 byte for addressing
#define BUFF_SIZE 100
#define NUM_CPUS 16

#define SUC_POWER_THROTTLE_GPIO_LINE 0x02

#define I2C_BUS	 0x0
#define I2C_SLAVE_ADDR 0x48
#define DEV_ID	 0x53
#define DEV_VERSION	  0x01

#define SUC_MD_DEV_ID_OFFSET 0
#define SUC_MD_I2C_SOC_THROTTLE_STATUS_OFFSET 0xe

#define SUC_MD_DIODE_TEMP_OFFSET 16
#define SUC_MD_LOWER_CRITICAL_OFFSET 32
#define SUC_MD_LOWER_WARNING_OFFSET 48
#define SUC_MD_UPPER_WARNING_OFFSET 64
#define SUC_MD_UPPER_CRITICAL_OFFSET 80

#define SUC_MD_POWER_THROTTLE_FLAG_MASK 0x20
#define SUC_MD_POWER_THROTTLE_FLAG_SHIFT 5

typedef enum power_states{
	POWERSAVE = 1,
	ONDEMAND
}power_states;

typedef struct sensor_alarms{
	uint16_t lower_warning;
	uint16_t lower_critical;
	uint16_t upper_warning;
	uint16_t upper_critical;
}sensor_alarms;

struct device_info{
	uint8_t device_id;
	uint8_t device_ver;
	uint8_t is_aux_power:1;
	uint8_t is_os_recovery:1;
	uint8_t is_sensor_warning:1;
	uint8_t is_sensor_critical:1;
	uint8_t is_watchdog:1;
	uint8_t is_power_throttle:1;
	uint16_t diode_temp;
	uint16_t ambient_temp;
	uint16_t main_supply_voltage;
	uint16_t main_supply_current;
	sensor_alarms diode_temp_info;
	sensor_alarms ambient_temp_info;
	sensor_alarms main_supply_voltage_info;
	sensor_alarms main_supply_current_info;
};

static int i2c_read_nbytes(int fd, uint8_t reg_addr,  uint8_t num_bytes, uint8_t *value) {
	uint8_t command[] = { reg_addr };
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

static int i2c_write(int fd, uint8_t reg_addr, uint8_t value) {
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

static int throttle_cpu_freq(uint8_t num_cpus, power_states state)
{
	char cmd[BUFF_SIZE];
	char buffer[BUFF_SIZE];
	int i;

	switch(state)
	{
		case POWERSAVE:
			for(i = 0; i < num_cpus; i++){
				snprintf(cmd,BUFF_SIZE,"echo powersave > /sys/devices/system/cpu/cpu%d/cpufreq/scaling_governor", i);
				system(cmd);
			}
			break;
		case ONDEMAND:
			for(i = 0; i < num_cpus; i++){
				snprintf(cmd,BUFF_SIZE,"echo ondemand > /sys/devices/system/cpu/cpu%d/cpufreq/scaling_governor", i);
				system(cmd);
			}
			break;
		default:
			break;
	}
	return 0;
}

static void display_limits(struct device_info *sensor_data, char throttle_status){
	printf("Limits:\n");

	if(throttle_status & 0x1){
		printf("Main supply current lower warning : %dmA\n", sensor_data->main_supply_current_info.lower_warning);
		printf("Main supply current lower critical: %dmA\n", sensor_data->main_supply_current_info.lower_critical);
		printf("Main supply current upper warning : %dmA\n", sensor_data->main_supply_current_info.upper_warning);
		printf("Main supply current upper critical: %dmA\n", sensor_data->main_supply_current_info.upper_critical);
	}
	if(throttle_status & 0x2){
		printf("Main supply voltage lower warning : %dmV\n", sensor_data->main_supply_voltage_info.lower_warning);
		printf("Main supply voltage lower critical: %dmV\n", sensor_data->main_supply_voltage_info.lower_critical);
		printf("Main supply voltage upper warning : %dmV\n", sensor_data->main_supply_voltage_info.upper_warning);
		printf("Main supply voltage upper critical: %dmV\n", sensor_data->main_supply_voltage_info.upper_critical);
		printf("Main supply current lower warning : %dmA\n", sensor_data->main_supply_current_info.lower_warning);
		printf("Main supply current lower critical: %dmA\n", sensor_data->main_supply_current_info.lower_critical);
		printf("Main supply current upper warning : %dmA\n", sensor_data->main_supply_current_info.upper_warning);
		printf("Main supply current upper critical: %dmA\n", sensor_data->main_supply_current_info.upper_critical);
	}
	if(throttle_status & 0x4){
		printf("Diode Temperature lower warning : %d\u00B0C\n", sensor_data->diode_temp_info.lower_warning);
		printf("Diode Temperature lower critical: %d\u00B0C\n", sensor_data->diode_temp_info.lower_critical);
		printf("Diode Temperature upper warning : %d\u00B0C\n", sensor_data->diode_temp_info.upper_warning);
		printf("Diode Temperature upper critical: %d\u00B0C\n", sensor_data->diode_temp_info.upper_critical);

		printf("Ambient Temperature lower warning : %d\u00B0C\n", sensor_data->ambient_temp_info.lower_warning);
		printf("Ambient Temperature lower critical: %d\u00B0C\n", sensor_data->ambient_temp_info.lower_critical);
		printf("Ambient Temperature upper warning : %d\u00B0C\n", sensor_data->ambient_temp_info.upper_warning);
		printf("Ambient Temperature upper critical: %d\u00B0C\n", sensor_data->ambient_temp_info.upper_critical);
	}

	printf("\n");

}

int main()
{
	char read_buf[MAX_READ_SIZE];
	int i2c_fd, ret = 0;
	char i2c_dev[20];
	char gpio_dev[32];
	struct gpioevent_request ereq;
	struct gpioevent_data event;
	int gpio_file;
	struct device_info pm_param;
	uint16_t gpio_set = 0;
	struct pollfd pfd;
	uint8_t number_of_cpus = NUM_CPUS;
	char cmd[BUFF_SIZE];
	power_states state = ONDEMAND, prev_state = ONDEMAND;

	/*verify device ID and device version*/
	memset(read_buf, 0 , sizeof(read_buf));
	snprintf(i2c_dev, 20, "/dev/i2c-%d", I2C_BUS);
	i2c_fd = open(i2c_dev, O_RDWR);
	if (i2c_fd < 0) {
		printf("I2C adapter device node is not available, BUS = %d , error %d\n", I2C_BUS, errno);
		return -1;
	}

	if(ioctl(i2c_fd, I2C_SLAVE, I2C_SLAVE_ADDR)) {
		printf("Slave device with address 0x%x is not accessible, error %d\n", I2C_SLAVE_ADDR, errno);
		goto exit_i2c;
	}
	
	/*Device ID verification*/
	if (i2c_read_nbytes(i2c_fd, SUC_MD_DEV_ID_OFFSET, 3, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}
	pm_param.device_id = read_buf[0];
	pm_param.device_ver = read_buf[1];
	pm_param.is_aux_power = (read_buf[2] & 0x1);

	if (DEV_ID != pm_param.device_id) {
		printf("I2C management Device ID is incorrect Expected:0x%x Received:0x%x\n", DEV_ID, pm_param.device_id);
		goto exit_i2c;
	}

	/*Device version verification*/
	if (DEV_VERSION != pm_param.device_ver) {
		printf("I2C management Device version is incorrect Expected:0x%x Received:0x%x\n", DEV_VERSION, pm_param.device_ver);
		goto exit_i2c;
	}

	if(!pm_param.is_aux_power)
		number_of_cpus = 8;
	/*lower critical threshold*/
	if (i2c_read_nbytes(i2c_fd, SUC_MD_LOWER_CRITICAL_OFFSET, 0x8, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}

	pm_param.diode_temp_info.lower_critical = (read_buf[1] << 0x8) | (read_buf[0] & 0xFF);
	pm_param.ambient_temp_info.lower_critical = (read_buf[3] << 0x8) | (read_buf[2] & 0xFF);
	pm_param.main_supply_voltage_info.lower_critical = (read_buf[5] << 0x8) | (read_buf[4] & 0xFF);
	pm_param.main_supply_current_info.lower_critical = (read_buf[7] << 0x8) | (read_buf[6] & 0xFF);
	
	/*lower warning threshold*/
	if (i2c_read_nbytes(i2c_fd, SUC_MD_LOWER_WARNING_OFFSET, 0x8, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}

	pm_param.diode_temp_info.lower_warning = (read_buf[1] << 0x8) | (read_buf[0] & 0xFF);
	pm_param.ambient_temp_info.lower_warning = (read_buf[3] << 0x8) | (read_buf[2] & 0xFF);
	pm_param.main_supply_voltage_info.lower_warning = (read_buf[5] << 0x8) | (read_buf[4] & 0xFF);
	pm_param.main_supply_current_info.lower_warning = (read_buf[7] << 0x8) | (read_buf[6] & 0xFF);

	/*upper warning threshold*/
	if (i2c_read_nbytes(i2c_fd, SUC_MD_UPPER_WARNING_OFFSET, 0x8, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}

	pm_param.diode_temp_info.upper_warning = (read_buf[1] << 0x8) | (read_buf[0] & 0xFF);
	pm_param.ambient_temp_info.upper_warning = (read_buf[3] << 0x8) | (read_buf[2] & 0xFF);
	pm_param.main_supply_voltage_info.upper_warning = (read_buf[5] << 0x8) | (read_buf[4] & 0xFF);
	pm_param.main_supply_current_info.upper_warning = (read_buf[7] << 0x8) | (read_buf[6] & 0xFF);

	/*upper critical threshold*/
	if (i2c_read_nbytes(i2c_fd, SUC_MD_UPPER_CRITICAL_OFFSET, 0x8, read_buf) < 0) {
		printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
		goto exit_i2c;
	}

	pm_param.diode_temp_info.upper_critical = (read_buf[1] << 0x8) | (read_buf[0] & 0xFF);
	pm_param.ambient_temp_info.upper_critical = (read_buf[3] << 0x8) | (read_buf[2] & 0xFF);
	pm_param.main_supply_voltage_info.upper_critical = (read_buf[5] << 0x8) | (read_buf[4] & 0xFF);
	pm_param.main_supply_current_info.upper_critical = (read_buf[7] << 0x8) | (read_buf[6] & 0xFF);

	/*Update warning and critical trip point temperature*/
	snprintf(cmd,BUFF_SIZE,"echo %d > /sys/class/thermal/thermal_zone0/trip_point_0_temp", (pm_param.diode_temp_info.upper_warning * 1000));
	system(cmd);
	snprintf(cmd,BUFF_SIZE,"echo %d > /sys/class/thermal/thermal_zone0/trip_point_2_temp", (pm_param.diode_temp_info.upper_critical * 1000));
	system(cmd);

	/*GPIO setup*/
	snprintf(gpio_dev, 32, "/dev/gpiochip%d", SUC_POWER_THROTTLE_GPIO_LINE);
	gpio_file = open(gpio_dev, O_RDWR);
	if (gpio_file < 0) {
		printf("could not access GPIO line %d , error %d\n", gpio_file, errno);
		goto exit_i2c;
	}
#ifdef DEBUG
	printf("GPIO fd %d\n", gpio_file);
#endif	
	ereq.lineoffset = 10;
	ereq.handleflags = GPIOHANDLE_REQUEST_INPUT;
	ereq.eventflags = GPIOEVENT_REQUEST_BOTH_EDGES;

	ret = ioctl(gpio_file, GPIO_GET_LINEEVENT_IOCTL, &ereq);
	if(ret) {
		printf("Unable to set GPIO_GET_LINEEVENT_IOCTL , error %d\n", errno);
		goto exit_gpio;
	}

	while(1){

		/*GPIO polling*/
		pfd.fd = ereq.fd;
		pfd.events = POLLIN | POLLPRI;
		ret = poll(&pfd, 1, -1);
		if(ret < 0) {
			printf("GPIO polling failed %d , error %d\n", ret, errno);
			goto exit_gpio;
		}
		else if(ret > 0) {
#ifdef DEBUG
			printf("%d Fds returned events %d \n", ret, pfd.revents);
#endif
			if(pfd.revents & POLLIN) {
				ret = read(ereq.fd, &event, sizeof(event));
				if(ret == -1) {
					printf("Could not read GPIO, error %d\n", errno);
					goto exit_gpio;
				}
				if(event.id == GPIOEVENT_EVENT_RISING_EDGE){
					gpio_set = 0;
				}
				else{
					gpio_set = 1;
					if (i2c_read_nbytes(i2c_fd, SUC_MD_DIODE_TEMP_OFFSET, 0x8, read_buf) < 0) {
						printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
						goto exit_gpio;
					}

					pm_param.diode_temp = (read_buf[1] << 0x8) | (read_buf[0] & 0xFF);
					pm_param.ambient_temp = (read_buf[3] << 0x8) | (read_buf[2] & 0xFF);
					pm_param.main_supply_voltage = (read_buf[5] << 0x8) | (read_buf[4] & 0xFF);
					pm_param.main_supply_current = (read_buf[7] << 0x8) | (read_buf[6] & 0xFF);

					/*Read power throttle status*/
					if (i2c_read_nbytes(i2c_fd, SUC_MD_I2C_SOC_THROTTLE_STATUS_OFFSET, 1, read_buf) < 0) {
						printf("Device read failed for device 0x%x\n", I2C_SLAVE_ADDR);
						goto exit_gpio;
					}

					if(read_buf[0] & 0x1){
						printf("power throttling the SoC for over current, main supply current: %dmA\n", pm_param.main_supply_current);
					}
					if(read_buf[0] & 0x2){
						printf("power throttling the SoC for over power, main supply voltage: %dmV, main supply current: %d mA\n", pm_param.main_supply_voltage, pm_param.main_supply_current);
					}
					if(read_buf[0] & 0x4){
						printf("power throttling the SoC for over temperature, Tdiode temperature: %d\u00B0C,  Ambient temperature: %d\u00B0C\n", pm_param.diode_temp, pm_param.ambient_temp);
					}
					display_limits(&pm_param, read_buf[0]);
				}
			}
		}

		if(gpio_set)
			state = POWERSAVE;
		else
			state = ONDEMAND;

		if(state != prev_state)
		{
			ret = throttle_cpu_freq(number_of_cpus, state);
			if(ret != 0){
				printf("Failure in power throttling state machine \n");
				break;
			}
			prev_state = state;
		}
	}
	close(i2c_fd);
	close(gpio_file);
	return 0;
exit_gpio:
	close(gpio_file);
exit_i2c:
	close(i2c_fd);
	return -1;
}
