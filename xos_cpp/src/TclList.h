#ifndef ___DCS_TCL_LIST_H___
#define ___DCS_TCL_LIST_H___

//we do not plan to support dynamic list, so the num_field and max length of field are fixed.

//extra fields are discarded, not exists field are set to ""
#include <iostream>
class TclList
{
public:
	TclList( int num_fields, int max_length_of_field = 1024 );
	~TclList( );

    int getFieldNumber( ) const { return m_numFieldFilled; }

	const char* getField( int index ) const;
	const char* getList( ) const;
    void reset( );
	void parse( const char* tcl_list );
	void setField( int index, const char* field );
    int indexOf( const char* element ) const;
private:
	TclList( ); //prevent default constructor

	void generateWholeList( );
    bool needBrace( const char * pField );
	void addField();
private:
	char** m_fields;
	int m_numField;
    int m_numFieldFilled;
	int m_maxFieldLength;
	char* m_wholeList;
	int m_maxListLength;
};
#endif // ___DCS_TCL_LIST_H___
