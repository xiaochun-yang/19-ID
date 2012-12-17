
/*
 *	Prototype parameter entry typedef.
 *
 *	Used by the param_file.c routines in gui_lib + may need
 *	to be included by others which directly access the database.
 */

#define MAX_TAG_LENGTH (120) /* maximum length of a tag string */
#define MAX_VAL_LENGTH (120) /* maximum length of a value string */
#define MAX_COM_LENGTH (256) /* maximum length of a comment */
#define MAX_PARAMETERS (512) /* maximum number of lines in paramter file. */

typedef struct {
	char tag[MAX_TAG_LENGTH+1];
	char val[MAX_VAL_LENGTH+1];
	char comment[MAX_COM_LENGTH+1];
	int flag;
} PARAMETER;
