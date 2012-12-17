#include <string.h>
#include "TclList.h"

typedef char *pChar;

TclList::TclList( int num_field, int max_field_length )
{
	//no safety check is fine
	m_fields = new pChar[num_field];
	m_maxListLength = num_field * (3 + max_field_length) - 1;
	m_wholeList = new char[ m_maxListLength+ 1];
	memset( m_wholeList, 0, m_maxListLength + 1 );
	for (int i = 0; i < num_field; ++i)
	{
		m_fields[i] = new char[max_field_length + 1];
		memset( m_fields[i], 0, max_field_length + 1 );
	}
	m_numField = num_field;
	m_maxFieldLength = max_field_length;
}

TclList::~TclList( )
{
	for(int i = 0; i < m_numField; i++){
		delete [] m_fields[i];
	}
	delete [] m_fields;
    delete [] m_wholeList;
}

const char* TclList::getField( int index ) const
{
	if (index < 0 || index >= m_numField)
	{
		return NULL;
	}
	return m_fields[index];
}
const char* TclList::getList( ) const
{
	return m_wholeList;
}

//we only support normal list, no special characters

#define END_OF_FIELD \
inField = false; \
insideField = 0; \
++m_numFieldFilled

#define COPY_OVER \
if (insideField < m_maxFieldLength) { \
    m_fields[m_numFieldFilled][insideField++] = theLetter; \
}

#define IN_FIELD \
if(inField == false && m_numFieldFilled >= m_numField) { \
    addField(); \
} \
inField = true

void TclList::reset( ) {
	//clear all fields
	for (int i = 0; i < m_numField; ++i)
	{
		memset( m_fields[i], 0, m_maxFieldLength + 1 );
	}
    m_numFieldFilled = 0;
}
void TclList::parse( const char *tcl_list )
{
	size_t ll = strlen( tcl_list );

    reset( );

	size_t index = 0; //index is string index
	int insideField = 0; //index inside a field
	bool inField = false;
	unsigned int numBrace = 0;
    // numBrace >0 is a subset of inField = true;

	for (index = 0; index < ll; ++index)
	{
		char theLetter = tcl_list[index];

        if (numBrace) {
            //inField must be true already
            //"} ", "}}" or "}" at the end of string
            if (theLetter == '}' &&
            (index == ll - 1 || isspace(tcl_list[index+1]) || tcl_list[index+1] == '}')) {
                --numBrace;
                if (numBrace == 0) {
                    END_OF_FIELD;
                } else {
                    COPY_OVER;
                }
            } else {
                COPY_OVER;
                if (theLetter == '{' &&
                (isspace(tcl_list[index - 1]) || tcl_list[index - 1] == '{')) {
                    ++numBrace;
                }
            }
        } else if (inField) {
            //in field but no brace
		    if (isspace(theLetter)) {
                END_OF_FIELD;   
            } else {
                COPY_OVER;
            }
        } else {
            //not in a field
            if (isspace(theLetter)) {
                //skip
            } else if (theLetter == '{') {
                IN_FIELD;
                ++numBrace;
            } else {
                IN_FIELD;
                COPY_OVER;
            }
        }// if(numBrace)  
	}//for index

	generateWholeList( );
}
void TclList::setField( int index, const char* field )
{
	if (index < 0){
		return;
	}
	else while(index >= m_numField){
		addField();
	}
    if (index >= m_numFieldFilled) {
        m_numFieldFilled = index + 1;
    }
	memset( m_fields[index], 0, m_maxFieldLength + 1 );
	strncpy( m_fields[index], field, m_maxFieldLength );
	generateWholeList( );
}

bool TclList::needBrace( const char *pField ) {
    if (pField == NULL || pField[0] == 0) {
        return true;
    }

    const char *pChar = pField;

    while (*pChar != '\0') {
        if (isspace(*pChar)) {
            return true;
        }
        ++pChar;
    }

    return false;
}

void TclList::generateWholeList( )
{
	//generate whole list
	memset( m_wholeList, 0, m_maxListLength + 1 );

	for (int i = 0; i < m_numFieldFilled; ++i)
	{
		if (i > 0)
		{
			strcat( m_wholeList, " " );
		}
		if (needBrace( m_fields[i] ))
		{
			strcat( m_wholeList, "{" );
			strcat( m_wholeList, m_fields[i] );
			strcat( m_wholeList, "}" );
		}
		else
		{
			strcat( m_wholeList, m_fields[i] );
		}
	}
}
void TclList::addField(){
    //create new array with bigger size
	char ** fields2 = new pChar[m_numField + 1];
    fields2[m_numField] = new char[m_maxFieldLength + 1];
    memset( fields2[m_numField], 0, m_maxFieldLength + 1 );

    //copy the old array
	for (int i = 0; i < m_numField; ++i){
		fields2[i] = m_fields[i];
	}

    //assign the new one
	delete [] m_fields;
	m_fields = fields2;

    ++m_numField;
    //new whole list
	m_maxListLength = m_numField * (3 + m_maxFieldLength) - 1;
	delete [] m_wholeList;
	m_wholeList = new char[ m_maxListLength+ 1];
	memset( m_wholeList, 0, m_maxListLength + 1 );
}
int TclList::indexOf( const char * element ) const {
	for (int i = 0; i < m_numFieldFilled; ++i) {
        if (!strcmp( element, m_fields[i] )) {
            return i;
        }
    }
    return -1;
}
