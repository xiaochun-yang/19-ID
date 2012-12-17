
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


/* local include files */
#include "xos_hash.h"


/* private function declarations */

xos_index_t xos_hash_get_index
	(
	xos_hash_t	*hash,
	const char	*keyString
	);


xos_result_t xos_hash_initialize
	( 
	xos_hash_t			*hash,
	xos_size_t			slotCount,
	xos_hash_entry_t	*table
	)

	{
	/* local variables */
	xos_index_t			slotNum;
	xos_hash_entry_t	*entry;

	/* make sure passed parameters are valid */
	assert ( hash != NULL );
	assert ( slotCount > 0 );

	/* initialize data members */
	hash->isValid	 = FALSE;
	hash->slotCount = slotCount;
	hash->usedSlots = 0;

	/* allocate memory to hold the hash table and keys */
	hash->slot = malloc ( slotCount * sizeof( xos_hash_entry_t ) );

	/* exit if memory allocation failed */
	if ( hash->slot == NULL )
		xos_error_exit( "xos_hash_initialize: Malloc failed." );

	/* initialize slot keys to NULL */
	for ( slotNum = 0; slotNum < slotCount; slotNum ++ )
		{
		hash->slot[slotNum].key = NULL;
		}

	/* hash structure is now valid */
	hash->isValid = TRUE;
	
	/* add entries from passed table if specified */
	if ( table != NULL )
		{
		entry = table;
		while ( entry->key != NULL )
			{
			/* add the current entry */
			if ( xos_hash_add_entry ( hash, entry->key, 
				(xos_hash_data_t) entry->data ) == XOS_FAILURE )
				return XOS_FAILURE;
	
			/* point to next entry in table */
			entry++;
			}
		}

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t xos_hash_clear
	( 
	xos_hash_t			*hash
	)

	{
	/* local variables */
	xos_index_t			slotNum;

	/* make sure passed parameters are valid */
	assert ( hash != NULL );

	/* initialize slot keys to NULL */
	for ( slotNum = 0; slotNum < hash->slotCount; slotNum ++ )
		{
		if ( hash->slot[slotNum].key != NULL ) {
			free( hash->slot[slotNum].key );
			hash->slot[slotNum].key = NULL;
			}
		}

	/* reset used slot counter */
	hash->usedSlots = 0;
	
	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t xos_hash_destroy
	( 
	xos_hash_t	*hash
	)

	{
	/* local variables */
	xos_index_t	slotNum;
	
	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* invalidate object */
	hash->isValid = FALSE;

	/* free memory holding keys and data */
	for ( slotNum = 0; slotNum < hash->slotCount; slotNum ++ )
		{
		if ( hash->slot[slotNum].key != NULL )
			{
			free( hash->slot[slotNum].key );
			}
		}

	/* free memory holding hash table */
	free ( hash->slot );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t xos_hash_lookup
	( 
	xos_hash_t			*hash,
	const char			*key, 
	xos_hash_data_t	*data
	)

	{
	/* local variables */
	xos_index_t slotNum;
	int			pass = 0;

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* lookup key string in hash table */
	slotNum = xos_hash_get_index( hash, key );

	/* find key in table starting from hash value */
	while ( TRUE )
		{
		/* break out of loop if found key */
		if ( hash->slot[slotNum].key != NULL &&
			strcmp( key, hash->slot[slotNum].key ) == 0 )
			{
			break;
			}
			
		slotNum ++;
		if ( slotNum == hash->slotCount )
			{
			slotNum = 0;
			pass ++;
			if ( pass > 1 )
				{
				return XOS_FAILURE;
				}
			}
		}

	/* return failure if empty slot found before key */
	/*	if ( hash->slot[slotNum].key == NULL )
		return XOS_FAILURE;
	*/
	
 	/* return data associated with key if data pointer valid */
	if ( data != NULL )
		{
		*data = hash->slot[slotNum].data;
		}

		
	return XOS_SUCCESS; 
	}


xos_result_t xos_hash_set_string 
	(	
	xos_hash_t			*hash,
	const char			*key, 
	const char			*string
	)
	{
	/* local variables */
	xos_index_t slotNum;
	int			pass = 0;
					
	/* make sure object is valid */
	assert ( hash->isValid == TRUE );
			
	/* lookup key string in hash table */
	slotNum = xos_hash_get_index( hash, key );

	/* find first empty slot starting at returned slot number */
	while ( hash->slot[slotNum].key != NULL )
		{
		/* replace string value if key match found */
		if (strcmp(key, hash->slot[slotNum].key) == 0 )
			{
			if ( (char *)hash->slot[slotNum].data != NULL )
				free((void *) hash->slot[slotNum].data);
			
			//allow ptr to indicate that string is empty
			if ( string != NULL )
				{
				hash->slot[slotNum].data = (xos_hash_data_t) malloc( strlen(string) + 1 );
				strcpy( (char *) hash->slot[slotNum].data, string );
				}
			else
				{
				//set to NULL
				hash->slot[slotNum].data = 0x00;
				}
			return XOS_SUCCESS;
			}	

		slotNum ++;
		if ( slotNum == hash->slotCount )
			{
			slotNum = 0;
			pass ++;
			if ( pass > 1 )
				{
				xos_error("xos_hash_add_entry: Hash table full!");
				return XOS_FAILURE;
				}
			}
		}

/*		puts("no existing match.");	*/

	/* allocate memory for hash key */
	hash->slot[slotNum].key = malloc ( strlen( key ) + 1 );
	
	/* report error if memory allocation failed */
	if ( hash->slot[slotNum].key == NULL )
		{
		xos_error("xos_hash_add_entry: Memory allocation failed!");
		return XOS_FAILURE;
		}
	
	/* copy key and data to slot */
	strcpy( hash->slot[slotNum].key, key );

	if ( string != NULL )
		{
		hash->slot[slotNum].data = (xos_hash_data_t) malloc( strlen(string) + 1 );
		strcpy( (char *) hash->slot[slotNum].data, string );						
		}
	else
		{
		hash->slot[slotNum].data = 0x00;
		}

	/* count slots that have been filled */
	hash->usedSlots ++;

	/* report success */
	return XOS_SUCCESS;
	}	
	 

xos_result_t xos_hash_add_entry
	(
	xos_hash_t			*hash,
	const char			*key, 
	xos_hash_data_t	data
	)

	{
	/* local variables */
	xos_index_t slotNum;
	int			pass = 0;

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* lookup key string in hash table */
	slotNum = xos_hash_get_index( hash, key );

	/* find first empty slot starting at returned slot number */
	while ( hash->slot[slotNum].key != NULL )
		{
		slotNum ++;
		if ( slotNum == hash->slotCount )
			{
			slotNum = 0;
			pass ++;
			if ( pass > 1 )
				{
				xos_error("xos_hash_add_entry: Hash table full!");
				return XOS_FAILURE;
				}
			}
		}

	/* allocate memory for hash key */
	hash->slot[slotNum].key = malloc ( strlen( key ) + 1 );
	
	/* report error if memory allocation failed */
	if ( hash->slot[slotNum].key == NULL )
		{
		xos_error("xos_hash_add_entry: Memory allocation failed!");
		return XOS_FAILURE;
		}
	
	/* copy key and data to slot */
	strcpy( hash->slot[slotNum].key, key );
	hash->slot[slotNum].data = data;
	
	/* count slots that have been filled */
	hash->usedSlots ++;

	/* report success */
	return XOS_SUCCESS;
	}


xos_index_t xos_hash_get_index
	(
	xos_hash_t	*hash,
	const char	*key
	)

	{
	/* local variables */
	const char * characterPtr = key;
	unsigned int sum = 0;

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* determine weighted sum of characters */
	while ( *characterPtr != 0 )
		{
		sum = sum * 3 + *characterPtr;
		characterPtr++;
		}

	/* returned index is modulo slot count of the sum */
	return sum % hash->slotCount;
	}


xos_result_t xos_hash_get_iterator
	(
	xos_hash_t			*hash,
	xos_iterator_t		*iterator
	)
	
	{
	/* make sure arguments are valid */
	assert ( hash != NULL );
	assert ( iterator != NULL );
	assert ( hash->isValid == TRUE );

	/* set iterator to initial value */
	*iterator = XOS_ITERATOR_BEGIN;
	
	/* report success */
	return XOS_SUCCESS;
	}	


xos_result_t xos_hash_get_next
	(
	xos_hash_t			*hash,
	char 					*key,
	xos_hash_data_t	*data,
	xos_iterator_t		*iterator
	)

	{
	
	/* make sure arguments are valid */
	assert ( hash != NULL );
	assert ( hash->isValid == TRUE );
	assert ( iterator != NULL );
	assert ( *iterator != XOS_ITERATOR_END );

	/* initialize iterator to first element of table if first iteration */
	if ( *iterator == XOS_ITERATOR_BEGIN )
		{
		*iterator = 0;
		}
	/* otherwise, increment iterator to point to next element in table */
	else
		{
		(*iterator)++;
		}

	/* loop over remaining elements in table */
	while ( (int)*iterator < (int)hash->slotCount )
		{
		/* return current element if slot in use */
		if ( hash->slot[*iterator].key != NULL )
			{
			strcpy( key, hash->slot[*iterator].key );	
			if ( data != NULL )
				{
				*data = hash->slot[*iterator].data;
				}
			return XOS_SUCCESS;
			}
		
		/* increment iterator */
		(*iterator)++;
		}
		
	/* since no used slot was found, report end of iteration */
	*iterator = XOS_ITERATOR_END;
	return XOS_FAILURE;
	}


xos_size_t xos_hash_get_used_slots
	( 
	xos_hash_t	*hash
	)
	
	{
	/* make sure arguments are valid */
	assert ( hash != NULL );
	assert ( hash->isValid == TRUE );	

	/* return result */
	return hash->usedSlots;
	}
	
	

xos_result_t xos_hash_delete_entry
	( 
	xos_hash_t			*hash,
	const char			*key
	)

	{
	/* local variables */
	xos_index_t slotNum;
	int			pass = 0;

/*	puts("deleting hash entry..."); */

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* lookup key string in hash table */
	slotNum = xos_hash_get_index( hash, key );
		
	/* find key in table starting from hash value */
	while ( TRUE )
		{ 
		if ( hash->slot[slotNum].key != NULL && 
			strcmp( key, hash->slot[slotNum].key ) == 0 )
			{
			break;
			}
		slotNum ++;
		if ( slotNum == hash->slotCount )
			{
			slotNum = 0;
			pass ++;
			if ( pass > 1 )
				{
				return XOS_FAILURE;
				}
			}
		}

/* 	printf("Deleting slot %d\n", slotNum ); */

	/* delete the entry */
	free( hash->slot[slotNum].key );
	hash->slot[slotNum].key = NULL;
	
	/* count the used slots */
	hash->usedSlots --;
		
	return XOS_SUCCESS; 
	}



xos_result_t xos_hash_delete_slot
	( 
	xos_hash_t	*hash,
	int			slotNum
	)

	{
	/* local variables */

/* 	puts("deleting hash slot..."); */

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* printf("Deleting slot %d\n", slotNum ); */

	/* delete the entry */
	free( hash->slot[slotNum].key );
	hash->slot[slotNum].key = NULL;
	
	/* count the used slots */
	hash->usedSlots --;
		
	return XOS_SUCCESS; 
	}


xos_result_t xos_hash_entry_kill
	( 
	xos_hash_t			*hash,
	const char			*key,
	const char			*newKey
	)

	{
	/* local variables */
	xos_index_t slotNum;
	int			pass = 0;

	/* make sure object is valid */
	assert ( hash->isValid == TRUE );

	/* lookup key string in hash table */
	slotNum = xos_hash_get_index( hash, key );

	/* find key in table starting from hash value */
	while ( TRUE )
		{
		/* break out of loop if found key */
		if ( hash->slot[slotNum].key != NULL &&
			  strcmp( key, hash->slot[slotNum].key ) == 0 )
			{
			break;
			}

		slotNum ++;
		if ( slotNum == hash->slotCount )
			{
			slotNum = 0;
			pass ++;
			if ( pass > 1 )
				{
				return XOS_FAILURE;
				}
			}
		}

/* 	printf("slot num %d: new key = %s\n", slotNum, newKey ); */

	/* nullify key from entry so entry cannot be found again */
   free( hash->slot[slotNum].key );
	hash->slot[slotNum].key = (char *) malloc ( strlen( newKey ) + 1 );
	strcpy( hash->slot[slotNum].key, newKey );
	
/* 	puts("key changed."); */

	return XOS_SUCCESS; 
	}


xos_result_t xos_property_table_initialize
	(
	xos_property_table_t *	propertyTable,
	xos_size_t				tableSize
	)

	{
	/* initialize the parameters hash table */
	if ( xos_hash_initialize( & propertyTable->hashTable, tableSize, NULL ) != XOS_SUCCESS ) {
		xos_error("Error initializing property hash table.");
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}


xos_result_t xos_property_get
	( 
	xos_property_table_t * propertyTable,
	const char * name,
	char ** valuePtr
	) 

	{ 
	/* lookup up parameter in hash table */
	return xos_hash_lookup( & propertyTable->hashTable, name, (xos_hash_data_t *) valuePtr );
	}


xos_result_t xos_property_set
	( 
	xos_property_table_t * propertyTable,	
	const char * name, 
	const char * value 
	) 

	{	
	return xos_hash_set_string( & propertyTable->hashTable, name, value );
	}


xos_boolean_t xos_property_equals
	( 
	xos_property_table_t * propertyTable,
	const char * name, 
	const char * value 
	) 

	{
	/* local variables */
	char * valuePtr;
			
	/* return false if parameter not in table */
	if ( xos_property_get(propertyTable, name, &valuePtr) == XOS_FAILURE ) {
		return FALSE;
		}

	//first check to see if the pointers are the same
	if ( valuePtr == value )
		return TRUE;

	// now check to see if either pointer is a NULL
	if ( valuePtr == NULL || value == NULL )
		return FALSE;

	/* return the string comparison converted to boolean */
	return ( strcmp( valuePtr, value ) == 0 );
	}


int xos_property_equals_case_insensitive
	( 
	xos_property_table_t * propertyTable,
	const char * name, 
	const char * value 
	) 

	{
	/* local variables */
	char lowerParameter[1024];
	char lowerValue[1024];
	char * valuePtr;

	/* return false if parameter not in table */
	if ( xos_property_get(propertyTable, name, &valuePtr) == XOS_FAILURE ) {
		return FALSE;
		}

	//first check to see if the pointers are the same
	if ( valuePtr == value )
		return TRUE;

	// now check to see if either pointer is a NULL
	if ( valuePtr == NULL || value == NULL )
		return FALSE;
				
	/* make local copies of the two values to compare */
	strncpy( lowerParameter, valuePtr, 1024 );
	strncpy( lowerValue, value, 1024);
								
	/* convert both values to lower case */
	stringToLower( lowerParameter );
	stringToLower( lowerValue );

	/* return the string comparison converted to boolean */
	return ( strcmp( lowerParameter, lowerValue ) == 0 );	
}



char * stringToLower( char * string ) {

	/* local variables */
	char * charPtr = string;
							
	/* convert each character to lower case */
	while ( *charPtr != 0 ) {
		*charPtr = (char) tolower( (char)*charPtr );
		charPtr++;
	}
							
	/* return the string */
	return string;
}

