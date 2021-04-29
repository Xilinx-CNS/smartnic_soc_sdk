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
#include <stdbool.h>
#include <sys/ioctl.h>
#include <string.h>
#include <errno.h>

#define SUC_I2C_BUS                     0x0
#define SUC_MD_I2C_ADDR                 0x48
#define SUC_MD_DEV_ID                   0x53
#define SUC_MD_DEV_VERSION              0x01
#define SUC_MD_I2C_DEV_ID_OFFSET        0x0
#define SUC_MD_I2C_DEV_VER_OFFSET       0x1
#define SUC_SOC_STATE_OFFSET            0x7
#define SUC_FW_VERSION_START_OFFSET     0x80
#define SUC_UBOOT_VERSION_START_OFFSET  0x88
#define SUC_RFS_VERSION_START_OFFSET    0x90
#define SUC_BR_VERSION_START_OFFSET     0x98


#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

static int i2c_file;

static int suc_i2c_read(uint8_t reg_addr, uint8_t *value)
{

    uint8_t command[] = { reg_addr };
    struct i2c_msg messages[] = {
    { SUC_MD_I2C_ADDR, 0, sizeof(command), command },
    { SUC_MD_I2C_ADDR, I2C_M_RD, 1, value },
    };
    struct i2c_rdwr_ioctl_data ioctl_data = { messages, 2 };
    int result = ioctl(i2c_file, I2C_RDWR, &ioctl_data);

    if (result != 2) {
        printf("i2c read failed for addr %x\n", reg_addr);
        perror("");
        return -1;
    }

    return 0;
}

static int suc_i2c_write(uint8_t reg_addr, uint8_t value)
{
    uint8_t command[] = { reg_addr, value };
    struct i2c_msg messages[] = {
    { SUC_MD_I2C_ADDR, 0, sizeof(command), command },
    };
    struct i2c_rdwr_ioctl_data ioctl_data = { messages, 1 };
    int result = ioctl(i2c_file, I2C_RDWR, &ioctl_data);

    if (result != 1) {
        printf("i2c write failed for addr %x\n", reg_addr);
        perror("");
        return -1;
    }

    return 0;
}

static int init_i2c(void)
{
    char buf[4];
    char suc_dev[32];

    snprintf(suc_dev, 32, "/dev/i2c-%d", SUC_I2C_BUS);

    i2c_file = open(suc_dev, O_RDWR);
    if (i2c_file < 0) {
        perror("could not access I2C slave bus device");
        return -1;
    }

    if (ioctl(i2c_file, I2C_SLAVE, SUC_MD_I2C_ADDR)) {
        printf("could not bus addr 0x%x \n", SUC_MD_I2C_ADDR);
        perror("");
        goto error_i2c;
    }

    /* Read and verify device ID */
    if (suc_i2c_read(SUC_MD_I2C_DEV_ID_OFFSET, buf) < 0) {
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

    /* Read and verify device Version */
    if (suc_i2c_read(SUC_MD_I2C_DEV_VER_OFFSET, buf) < 0) {
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

    return 0;
error_i2c:
    close(i2c_file);
    return -1;
}

static uint8_t strtouint8(const char *str, size_t len)
{
    uint8_t res = 0, i;

    if ((str == NULL) || (len > 3))
        return 0;

    for (i = 0; i < len; ++i) {
        res = (res * 10) + (str[i] - '0');
    }

    return res;
}


static void update_version(bool is_br)
{
    char *myfile = "";
    char *peerfile = "";
    const char *version_string = STRINGIZE_VALUE_OF(SDKVERSION);
    const char *vs;
    uint8_t i = 0, version_val[8], my_offset, peer_offset;
    size_t version_loc, version_string_len;
    int fd;

    memset(version_val, 0, 8);
    version_string_len = strlen(version_string);
    vs = version_string;

    while (1) {
        version_loc = strcspn(vs, ".");

        version_val[i] = strtouint8(vs, version_loc);

        if (version_loc >= version_string_len) {
            break;
        }

        vs = vs + version_loc + 1;
        version_string_len = version_string_len - (version_loc + 1);
        /* Skip major bytes */
        i += 2;
        if (8 == i)
            i -= 1;
    }

    if (is_br) {
        my_offset = SUC_BR_VERSION_START_OFFSET;
	peer_offset = SUC_RFS_VERSION_START_OFFSET;
	myfile = "/mnt/p2/br_version.bin";
	peerfile = "/mnt/p2/rfs_version.bin";
    } else {
        my_offset = SUC_RFS_VERSION_START_OFFSET;
	peer_offset = SUC_BR_VERSION_START_OFFSET;
	myfile = "/mnt/p2/rfs_version.bin";
	peerfile = "/mnt/p2/br_version.bin";
    }
    for (i = 0; i < sizeof(version_val); ++i) {
        /* Update the version */
        if (suc_i2c_write(my_offset + i, version_val[i]) < 0) {
            printf("could not update version");
            return ;
        }
    }

    /* Further code asssumes /dev/mmcblk1p2 is mounted at /mnt/p2 */
        /* Save version file to /mnt/p2 */
    if ((fd = open(myfile, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH)) == -1) {
	perror("Failed to open file:");
        return;
    }

    if ((write(fd, version_val, sizeof(version_val))) == -1) {
        perror("Failed to write to file:");
    }

    close(fd);

    /* Open peer version file and update version */
    if ((fd = open(peerfile, O_RDONLY)) == -1)
        return;

    if ((read(fd, version_val, sizeof(version_val))) == -1) {
        perror("Failed to read file:");
    } else {
        for (i = 0; i < sizeof(version_val); ++i) {
            /* Update the version */
            if (suc_i2c_write(peer_offset + i, version_val[i]) < 0) {
                printf("could not update version");
                break;
            }
        }
        close(fd);
    }
}

static void dump_version(void)
{
    int i;
    uint8_t i2c_offset, version_val[8];

    for (i2c_offset = SUC_FW_VERSION_START_OFFSET; i2c_offset < (SUC_BR_VERSION_START_OFFSET + 8); i2c_offset += 8) {
        for (i = 0; i < sizeof(version_val); ++i) {
            if (suc_i2c_read(i2c_offset + i, &version_val[i]) < 0) {
                printf("could not read dev version");
                break;
            }
        }

        if (i2c_offset == SUC_FW_VERSION_START_OFFSET) {
            printf("%21s", "FW Version : ");
        } else if (i2c_offset == SUC_UBOOT_VERSION_START_OFFSET) {
            printf("%21s", "U-Boot Version : ");
        } else if ("%21s", i2c_offset == SUC_RFS_VERSION_START_OFFSET) {
            printf("%21s", "Root FS Version : ");
        } else if (i2c_offset == SUC_BR_VERSION_START_OFFSET) {
            printf("%21s", "Build Root Version : ");
        }

        for (i = 0; i < sizeof(version_val) - 2; i += 2) {
            printf("%u.", (uint16_t)version_val[i]);
        }
        /* Print Dirty Bit + Build version */
        printf("%u%u", version_val[i+1], version_val[i]);
        printf("\n");
    }
}

enum cmd_op {
    VERSION_DUMP,
    BR_VERSION_UPDATE,
    RFS_VERSION_UPDATE,
    NONE
};

int main(int argc, char **argv)
{
    int ret;
    enum cmd_op op = NONE;

    if (argc == 1) {
        op = VERSION_DUMP;
    }
    else if (argc == 2) {
        if (0 == strcmp("br", argv[1])) {
            op = BR_VERSION_UPDATE;
        }
        else if (0 == strcmp("rfs", argv[1])) {
            op = RFS_VERSION_UPDATE;
        }
    }

    if (op == NONE) {
        printf("Unknown command not supported\n");
        return -1;
    }

    if (init_i2c()) {
        return -1;
    }

    if (op == VERSION_DUMP) {
        dump_version();
    }
    else {

        update_version((op == BR_VERSION_UPDATE) ? true:false);
    }

    close(i2c_file);
    return 0;
}

