#!/bin/sh

watchdog_period_offset=0x6
soc_state_offset=0x7
scratchpad_offset=0x9
soc_ctrl_offset=0xb
i2c_bus=0x48
soc_state=0x3
watchdog_period=60
dev_id=0x53
dev_ver=0x01

val=$(i2cget -y 0 $i2c_bus 0)
if [ $val != $dev_id ]
then
	echo "I2C Device id is not correct"
	exit 1
fi

val=$(i2cget -y 0 $i2c_bus 1)
if [ $val != $dev_ver ]
then
	echo "I2C Device version is not correct"
	exit 1
fi

i2cset -y 0 $i2c_bus $watchdog_period_offset $watchdog_period b
i2cset -y 0 $i2c_bus $soc_ctrl_offset 0 b
i2cset -y 0 $i2c_bus $soc_state_offset $soc_state b
i2cset -y 0 $i2c_bus $scratchpad_offset $soc_state b
