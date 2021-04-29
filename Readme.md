#### Copyright (c) 2020 - 2021,  Xilinx, Inc.
#### All rights reserved.
## ARM Platform Build System
### Prerequisites
The build system is intended to run under Debian based distributions. It is tested on Ubuntu 18.04 and 20.04. Root access is required for compiling the SDK.

### Steps to checkout and build the SDK

1. Download the third party source package to smartnic_soc_sdk.
2. Rename the third party source package as preseed.tgz.
3. Generate a default configuration using following command
    -   make defconfig
4. Install the missing build dependencies using following command
    -    make deps
5. Copy the Debian packages which needs to be included in RootFS to imports/debian folder
    -   cp *.deb imports/debian/
6. Packages which needs to be pre-installed shall be mentioned in file imports/install.list.
7. Use preseed file to avoid downloading third party source code again.
    -   make import-downloads
8. Start compilation, This will take ~2 hrs for builds from a fresh checkout.
    -   make
    -   make boot
9. Once successfully compiled, Images shall be available in build/lx2162a/boot/ directory.
10. Refer to SN1000 installation and user guide to install SoC images.

