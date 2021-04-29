/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

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

int main(void)
{
    const char *version_string = STRINGIZE_VALUE_OF(SDKVERSION);
    const char *vs;
    const char *file_name = "version.bin";
    uint8_t i = 0, version_val[8];
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
        /* Skip MSB bytes */
        i += 2;
        if (8 == i)
            i -= 1;
    }

    if ((fd = open(file_name, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IRGRP | S_IROTH)) == -1) {
        perror("Failed to open file\n");
        return -1;
    }

    if ((write(fd, version_val, sizeof(version_val))) == -1) {
        perror("Failed to write to file\n");
    }

    close(fd);

    printf("SDK Version written to -- %s\n", file_name);

    return 0;
}
