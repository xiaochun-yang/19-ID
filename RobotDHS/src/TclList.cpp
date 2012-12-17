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
	for (int i = 0; i < m_numField; ++i)
	{
		delete [] m_fields[i];
	}
	delete [] m_wholeList;
	delete [] m_fields;
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
void TclList::parse( const char *tcl_list )
{
	size_t ll = strlen( tcl_list );

	int i = 0;
	//clear all fields
	for (i = 0; i < m_numField; ++i)
	{
		memset( m_fields[i], 0, m_maxFieldLength + 1 );
	}

	size_t index = 0; //index is string index
	i = 0; //i is field index
	int insideField = 0; //index inside a field
	bool found_brace = false;
	bool inField = true;
	bool foundAll = false;
	for (index = 0; index < ll; ++index)
	{
		char theLetter = tcl_list[index];
		switch (theLetter)
		{
		case ' ':
		case '\n':
		case '\r':
		case '\t':
			if (found_brace)
			{
				if (insideField < m_maxFieldLength)
				{
					m_fields[i][insideField++] = ' ';
				}
			}
			else if (inField)
			{
				inField = false;
				insideField = 0;
				++i;
				if (i >= m_numField)
				{
					foundAll = true; //done
				}
			}
			else
			{
				//skip
			}
			break;

		case '{':
			if (inField)
			{
				throw "bad list";
			}
			found_brace = true;
			break;

		case '}':
			if (found_brace)
			{
				//end of field
				found_brace = false;
				inField = false;
				insideField = 0;
				++i;
				if (i >= m_numField)
				{
					foundAll = true; //done
				}
			}
            else
            {
			    inField = true;
			    if (insideField < m_maxFieldLength)
			    {
				    m_fields[i][insideField++] = theLetter;
			    }
            }
			break;

		default:
			inField = true;
			if (insideField < m_maxFieldLength)
			{
				m_fields[i][insideField++] = theLetter;
			}
		}
		if (foundAll) break;
	}//for index

	generateWholeList( );
}
void TclList::setField( int index, const char* field )
{
	if (index < 0 || index >= m_numField)
	{
		return;
	}
	memset( m_fields[index], 0, m_maxFieldLength + 1 );
	strncpy( m_fields[index], field, m_maxFieldLength );
	generateWholeList( );
}

void TclList::generateWholeList( )
{
	//generate whole list
	memset( m_wholeList, 0, m_maxListLength + 1 );

	for (int i = 0; i < m_numField; ++i)
	{
		if (i > 0)
		{
			strcat( m_wholeList, " " );
		}
		if (strlen( m_fields[i] ) == 0 || strchr( m_fields[i], ' ' ))
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