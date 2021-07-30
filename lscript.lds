/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright (c) Siemens AG, 2020-2021
 *
 * Authors:
 *   Jan Kiszka <jan.kiszka@siemens.com>
 */

ENTRY(reset_entry)

SECTIONS {
	. = 0;
	.text : { *(.text) }
	.gnu_build_id : { *(.note.gnu.build-id) }
}
