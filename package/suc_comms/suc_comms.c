/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <string.h>

#define SUC_I2C_BUS     0x0
#define SUC_MD_I2C_ADDR 0x48

#define SUC_MD_DEV_ID   0x53
#define SUC_MD_DEV_VERSION   0x01

#define SUC_MD_I2C_DEV_ID_OFFSET 0x0
#define SUC_MD_I2C_DEV_VER_OFFSET 0x1
#define SUC_MD_I2C_WD_KICK_OFFSET 0x5

#define SUC_MD_I2C_WD_KICK_VALUE 0x57

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
        printf("i2c read failed for addr %x \n", reg_addr);
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
        printf("i2c write failed for addr %x \n", reg_addr);
        return -1;
    }
    return 0;
}

int main()
{
    int i2c_file;
    char buf[4];
    char suc_dev[32];

    snprintf(suc_dev, 32, "/dev/i2c-%d", SUC_I2C_BUS);

    i2c_file = open(suc_dev, O_RDWR);
    if (i2c_file < 0) {
        printf("could not access I2C slave bus device %d \n", i2c_file);
        goto error_i2c;
    }

    if(ioctl(i2c_file, I2C_SLAVE, SUC_MD_I2C_ADDR)) {
        printf("could not bus addr 0x%x \n", SUC_MD_I2C_ADDR);
        goto error_i2c;
    }

    /*Read and verify device ID*/
    if (suc_i2c_read(i2c_file, SUC_MD_I2C_DEV_ID_OFFSET, buf) < 0) {
        printf("could not read dev_id");
        goto error_i2c;
    } else if (SUC_MD_DEV_ID != buf[0]) {
        printf("dev_id not correct 0x%x\n", buf[0]);
        goto error_i2c;
    } else {
#ifdef DEBUG
        printf("SuC dev id %d\n", buf[0]);
#endif
    }

    /*Read and verify device Version*/
    if (suc_i2c_read(i2c_file, SUC_MD_I2C_DEV_VER_OFFSET, buf) < 0) {
        printf("could not read dev version");
        goto error_i2c;
    } else if (SUC_MD_DEV_VERSION != buf[0]) {
        printf("dev version not compatible 0x%x\n", buf[0]);
        goto error_i2c;
    } else {
#ifdef DEBUG
        printf("SuC dev version %d\n", buf[0]);
#endif
    }

    /*Update the watchdog kick*/
    if (suc_i2c_write(i2c_file, SUC_MD_I2C_WD_KICK_OFFSET, SUC_MD_I2C_WD_KICK_VALUE) < 0) {
        printf("could not update watchdog kick");
        goto error_i2c;
    } else {
#ifdef DEBUG
        printf("SOC watchdog kicked\n");
#endif
        }
error_i2c:
    close(i2c_file);
    return 0;
}

