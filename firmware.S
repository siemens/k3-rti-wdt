/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright (c) Siemens AG, 2020-2023
 *
 * Authors:
 *   Jan Kiszka <jan.kiszka@siemens.com>
 *   Li Huaqian <huaqian.li@siemens.com>
 */

#define VIM_VEC_INT			0x40f82000
#define VIM_INTR_EN			0x40f80408

#define SEC_PROXY_STATUS		0x2a380000
#define SEC_PROXY_MSG_DATA		0x2a480004

#if defined(PON_REASON_BASE_ADDR)
#define PON_REASON_SOF_ADDR     	PON_REASON_BASE_ADDR
#define PON_REASON_MAGIC_ADDR   	(4 + PON_REASON_BASE_ADDR)
#define PON_REASON_EOF_ADDR     	(8 + PON_REASON_BASE_ADDR)
#define PON_REASON_SOF_NUM      	0xBBBBCCCC
#define PON_REASON_MAGIC_NUM    	0xDDDDDDDD
#define PON_REASON_EOF_NUM      	0xCCCCBBBB
#endif

#define HOST_R5_SEC_0			4
#define PROC_R5_0			1

#define THREAD_R5_SEC_0_RX		6
#define THREAD_R5_SEC_0_TX_HI		7

#define TISCI_MSG_SYS_RESET		0x0005
#define TISCI_MSG_SET_DEVICE		0x0200
#define TISCI_MSG_SET_FWL_REGION	0x9000
#define TISCI_MSG_PROC_REQUEST		0xc000

#define TISCI_MSG_FLAG_AOP		(1 << 1)

#define TISCI_MSG_FLAG_ACK		(1 << 1)

#define AM6_DEV_MCU_RTIX		(134 + RTI_MODULE)
#define DEVICE_SW_STATE_ON		2

#define FWL_MCU_ARMSS0_CORE0_SLV	1024
#define FWL_CTRL_LOCK			(1 << 4)
#define FWL_CTRL_EN			0xa

#define MCU_RTI_WWD_INT			(42 + RTI_MODULE)

#define SCTLR_VE			(1 << 24)

	.section ".text", "ax"

	.global reset_entry
reset_entry:
	b       init
	b       sys_reset	/* undef instr */
	b       sys_reset	/* svc */
	b       sys_reset	/* pabt */
	b       sys_reset	/* dabt */
	b       sys_reset	/* unused */
	b       sys_reset	/* irq */
	b       sys_reset	/* fiq */

init:
	/* set sys_reset as handler for MCU_RTI_WWD_INT */
	ldr	r0, =VIM_VEC_INT + 4 * MCU_RTI_WWD_INT
	adr	r1, sys_reset
	str	r1, [r0]

	/* enable MCU_RTI_WWD_INT */
	ldr	r0, =VIM_INTR_EN + 0x20 * (MCU_RTI_WWD_INT / 32)
	mov	r1, #(1 << (MCU_RTI_WWD_INT % 32))
	str	r1, [r0]

	/* enable VIM */
	mrc	p15, 0, r0, c1, c0, 0	/* read SCTLR */
	orr	r0, r0, #SCTLR_VE
	dsb
	mcr	p15, 0, r0, c1, c0, 0	/* write SCTLR */

	/* enabled interrupts */
	cpsie if

get_proc:
	mov	r0, #0x100000

	/* delay a bit */
wait:	subs	r0, #1
	bne	wait

	/* try to get the lock for the own processor */
	adr	r0, proc_req_msg
	adr	r1, proc_req_msg_end
	bl	send_msg

	/*
	 * This may fail initially if the loading host processor still holds
	 * the lock for the processor we are running on.
	 */
	ands	r0, #TISCI_MSG_FLAG_ACK
	beq	get_proc

	/*
	 * Ensure that RTI1 stays powered-on.
	 */
	adr	r0, set_device_msg
	adr	r1, set_device_msg_end
	bl	send_msg

	/*
	 * Enable firewall for MCU_ARMSS0_CORE0_SLV interface.
	 * This protects the firmware against overwriting.
	 */
	adr	r0, set_fwl_region_msg
	adr	r1, set_fwl_region_msg_end
	bl	send_msg

halt:	wfi
	b	halt

/*
 * Send TISCI message
 *
 * r0: message address
 * r1: message end address
 *
 * Returns response flags in r0
 */
send_msg:
	ldr	r2, =SEC_PROXY_STATUS + THREAD_R5_SEC_0_TX_HI * 0x1000

	/* wait until there is at least one TX slot free */
tx_wt:	ldr	r4, [r2]
	ands	r4, #0xff
	beq	tx_wt

	ldr	r2, =SEC_PROXY_MSG_DATA + THREAD_R5_SEC_0_TX_HI * 0x1000
	mov	r3, r2

	/* write outgoing message */
tx_lp:	ldr	r4, [r0], #4
	str	r4, [r2], #4
	cmp	r0, r1
	bne	tx_lp

	/* write final word (assuming the message was shorter than 15 words) */
	mov	r4, #0
	str	r4, [r3, #14*4]

	ldr	r2, =SEC_PROXY_STATUS + THREAD_R5_SEC_0_RX * 0x1000

	/* wait until we have a response */
rx_wt:	ldr	r4, [r2]
	ands	r4, #0xff
	beq	rx_wt

	/* load response flags */
	ldr	r2, =SEC_PROXY_MSG_DATA + THREAD_R5_SEC_0_RX * 0x1000
	ldr	r0, [r2, #2*4]

	/* read last word to consume message */
	ldr	r1, [r2, #14*4]

	bx	lr

/*
 * Reset system via TISCI
 */
sys_reset:
#if defined(PON_REASON_BASE_ADDR)
	/* Record the PON REASON in memory */
	ldr r2, =PON_REASON_SOF_ADDR
	ldr r3, =PON_REASON_SOF_NUM
	str r3, [r2]

	ldr r2, =PON_REASON_MAGIC_ADDR
	ldr r3, =PON_REASON_MAGIC_NUM
	str r3, [r2]

	ldr r2, =PON_REASON_EOF_ADDR
	ldr r3, =PON_REASON_EOF_NUM
	str r3, [r2]
	dsb
#endif

	adr	r0, sys_reset_msg
	adr	r1, sys_reset_msg_end
	bl	send_msg

	/* we should never get here */
	b	halt

/* TISCI message to request processor */
proc_req_msg:
	.word	0		/* secure header */
	.short	TISCI_MSG_PROC_REQUEST
	.byte	HOST_R5_SEC_0
	.byte	0		/* seq */
	.word	TISCI_MSG_FLAG_AOP
	.byte	PROC_R5_0
	.byte	0, 0, 0		/* padding */
proc_req_msg_end:

set_device_msg:
	.word	0		/* secure header */
	.short	TISCI_MSG_SET_DEVICE
	.byte	HOST_R5_SEC_0
	.byte	0		/* seq */
	.word	TISCI_MSG_FLAG_AOP
	.word	AM6_DEV_MCU_RTIX
	.word	0		/* reserved */
	.byte	DEVICE_SW_STATE_ON
	.byte	0, 0, 0		/* padding */
set_device_msg_end:

set_fwl_region_msg:
	.word	0		/* secure header */
	.short	TISCI_MSG_SET_FWL_REGION
	.byte	HOST_R5_SEC_0
	.byte	0		/* seq */
	.word	TISCI_MSG_FLAG_AOP
	.short	FWL_MCU_ARMSS0_CORE0_SLV
	.short	0		/* region 0 */
	.word	3		/* number of permission registers */
	.word	FWL_CTRL_LOCK | FWL_CTRL_EN
	.word	0, 0, 0		/* empty permission */
	.quad	0x41000000	/* start */
	.quad	0x41007fff	/* end */
set_fwl_region_msg_end:

/* TISCI message to issue system reset */
sys_reset_msg:
	.word	0		/* secure header */
	.short	TISCI_MSG_SYS_RESET
	.byte	HOST_R5_SEC_0
	.byte	0		/* seq */
	.word	TISCI_MSG_FLAG_AOP
sys_reset_msg_end:

/* Resource table */
	.section ".resource_table", "a"

	.word	1		/* version */
	.word	0		/* number of entries */
	.word	0, 0		/* reserved */
