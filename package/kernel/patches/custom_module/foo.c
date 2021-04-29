/*
 * This file is distributed as part of Xilinx ARM SDK
 *
 * Copyright (c) 2020 - 2021,  Xilinx, Inc.
 * All rights reserved.
 *
 */

/* this is a dummy module */

#include <linux/module.h>

static int __init foo_init(void)
{
	printk(KERN_INFO "Generic foo module installed\n");

	return 0;
}

static void __exit foo_exit(void)
{
	printk(KERN_INFO "Generic foo module removed\n");
}


module_init(foo_init);
module_exit(foo_exit);

MODULE_AUTHOR("Nick Bane");
MODULE_LICENSE("GPL");
