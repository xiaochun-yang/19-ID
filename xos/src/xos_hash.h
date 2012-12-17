/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

/****************************************************************
							xos_hash.h
								
	This header file is included by xos_hash.c and any 
	source file that use functions defined therein.	 This file
	defines the xos_hash_t abstract data type which...
	
	Author:				Timothy M. McPhillips, SSRL.
	Last Revision:		March 1, 1998 by TMM.
	
****************************************************************/

#ifndef XOS_HASH_H
#define XOS_HASH_H

/* include the master XOS file */
#include "xos.h"

#ifdef __cplusplus
extern "C" {
#endif

/* define the xos_hash data types */
#ifdef WIN32
typedef unsigned int	xos_hash_data_t;
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
typedef unsigned long xos_hash_data_t;
#endif

#ifdef VMS
typedef unsigned long xos_hash_data_t;
#endif

typedef struct 
	{
	char					*key;
	xos_hash_data_t	data;
	} xos_hash_entry_t;

typedef struct {
	xos_size_t			slotCount;
	xos_size_t			usedSlots;
	xos_hash_entry_t	*slot;
	xos_boolean_t		isValid;
} xos_hash_t;

typedef struct {
	xos_hash_t			hashTable;
} xos_property_table_t;

#define XOS_HASH_TABLE(f) xos_hash_entry_t f[] = {
#define XOS_HASH_FUNCTION_ENTRY(f) { #f, (xos_hash_data_t) f },
#define XOS_HASH_ENTRY(f,g) { #f, (xos_hash_data_t) g },
#define XOS_HASH_TABLE_END {0,0} };


/* declare public member functions */

xos_result_t xos_hash_initialize
	( 
	xos_hash_t			*hash,
	xos_size_t			slotCount,
	xos_hash_entry_t	*table
	);

xos_result_t xos_hash_destroy
	( 
	xos_hash_t	*hash
	);


xos_size_t xos_hash_get_used_slots
	( 
	xos_hash_t	*hash
	);


xos_result_t xos_hash_lookup
	( 
	xos_hash_t			*hash,
	const char			*key,
	xos_hash_data_t	*data
	);

xos_result_t xos_hash_add_entry
	(
	xos_hash_t			*hash,
	const char			*key, 
	xos_hash_data_t	data
	);

xos_result_t xos_hash_set_string
	(
	xos_hash_t			*hash,
	const char			*key, 
	const char			*string
	);
	
xos_result_t xos_hash_get_iterator
	(
	xos_hash_t			*hash,
	xos_iterator_t		*iteratorPtr
	);

xos_result_t xos_hash_get_next
	(
	xos_hash_t			*hash,
	char 					*key,
	xos_hash_data_t	*data,
	xos_iterator_t		*iteratorPtr
	);

xos_result_t xos_hash_clear
	( 
	xos_hash_t			*hash
	);
	
xos_result_t xos_hash_delete_entry
	( 
	xos_hash_t			*hash,
	const char			*key
	);

xos_result_t xos_hash_delete_slot
	( 
	xos_hash_t	*hash,
	int			slotNum
	);


xos_result_t xos_hash_entry_kill
	( 
	xos_hash_t			*hash,
	const char			*key,
	const char			*newKey
	);


xos_result_t xos_property_table_initialize
	(
	xos_property_table_t *	propertyTable,
	xos_size_t				tableSize
	);

xos_result_t xos_property_get
	( 
	xos_property_table_t * propertyTable,
	const char * name,
	char ** valuePtr
	);
	
xos_result_t xos_property_set
	( 
	xos_property_table_t * propertyTable,	
	const char * name, 
	const char * value 
	);

xos_boolean_t xos_property_equals
	( 
	xos_property_table_t * propertyTable,
	const char * name, 
	const char * value 
	);


int xos_property_equals_case_insensitive
	( 
	xos_property_table_t * propertyTable,
	const char * name, 
	const char * value 
	);
	
char * stringToLower( char * string );

#ifdef __cplusplus
}
#endif


#endif
