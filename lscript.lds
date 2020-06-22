/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright (c) Siemens AG, 2020
 *
 * Authors:
 *   Jan Kiszka <jan.kiszka@siemens.com>
 */

ENTRY(reset_entry)

SECTIONS {
	. = 0;
	.text : { *(.text) }
}
