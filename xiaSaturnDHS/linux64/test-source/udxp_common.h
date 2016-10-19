/*
 * Copyright (c) 2004 X-ray Instrumentation Associates
 *               2005-2012 XIA LLC
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, 
 * with or without modification, are permitted provided 
 * that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above 
 *     copyright notice, this list of conditions and the 
 *     following disclaimer.
 *   * Redistributions in binary form must reproduce the 
 *     above copyright notice, this list of conditions and the 
 *     following disclaimer in the documentation and/or other 
 *     materials provided with the distribution.
 *   * Neither the name of XIA LLC 
 *     nor the names of its contributors may be used to endorse 
 *     or promote products derived from this software without 
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
 * SUCH DAMAGE.
 *
 * $Id$
 *
 */

#ifndef __UDXP_COMMON_H__
#define __UDXP_COMMON_H__

#include "xerxesdef.h"
#include "xerxes_structures.h"

XERXES_SHARED byte_t dxp_compute_chksum(unsigned int len, byte_t *data);
XERXES_SHARED int    dxp_build_cmdstr(byte_t cmd, unsigned short len, 
									  byte_t *data, byte_t *cmdstr);
XERXES_SHARED int    dxp_command(int ioChan, DXP_MD_IO udxp_io, 
								 byte_t cmd, unsigned int lenS,
								 byte_t *send, unsigned int lenR,
								 byte_t *receive, byte_t ioFlags);
XERXES_SHARED int dxp_byte_to_string(unsigned char *bytes, 
                  unsigned int len, char *string);
XERXES_SHARED int dxp_usb_read_block(int ioChan, DXP_MD_IO udxp_io, 
                 unsigned long addr, unsigned long n, unsigned short *data);
XERXES_SHARED int dxp_usb_write_block(int ioChan, DXP_MD_IO udxp_io,
                                      unsigned long addr, unsigned long n,
                                      unsigned short *data);
XERXES_SHARED void dxp_init_pic_version_cache(void);
XERXES_SHARED boolean_t dxp_has_cpld(int ioChan);
XERXES_SHARED boolean_t dxp_is_supermicro(int ioChan);
XERXES_SHARED boolean_t dxp_has_direct_trace_readout(int ioChan);

#define UDXP_FREE(x)   udxpc_md_free((void *)(x)); \
                  (x) = NULL


/* Communication constants used for USB comm*/
#define DXP_A_IO    0
#define DXP_A_ADDR  1

#define DXP_F_IGNORE 0
#define DXP_F_WRITE  1
#define DXP_F_READ   0

/* Locations of PIC information */
#define PIC_VARIANT             0
#define PIC_MAJOR               1      
#define PIC_MINOR               2
#define PIC_VERSION_NUMBERS     3            

#endif /* __UDXP_COMMON_H__ */


