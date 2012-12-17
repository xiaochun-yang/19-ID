#ifndef __XOS_POINTER_LIST_H__
#define __XOS_POINTER_LIST_H__

#include "log_quick.h"

//a double linked list using array space
//typedef void* ElementType;

#define LIST_ELEMENT_NOT_FOUND -1
#define LIST_DEFAULT_MAX_LENGTH 10

template <class ElementType>
class CPPNativeList
{
public:
	class CPPNativeListElement
	{
	public:
		int next;	//-1 means NULL
		int prev;
		ElementType value;
	};

	CPPNativeList( int max_length );
	~CPPNativeList( );

	//copy constructor
	CPPNativeList( const CPPNativeList& source );



	bool         IsEmpty( ) const { return m_CurrentLength == 0; }
	int          GetLength( ) const { return m_CurrentLength; }
	int          GetMaxLength( ) const { return m_MaxLength; }

	int			 Find( ElementType value ) const;
	ElementType GetHead( ) const { return m_pElements[m_Head].value; }
	ElementType GetAt( int position ) const { return m_pElements[position].value; }

	int          GetFirst( ) const { return m_Head; }
	int          GetNext( int current ) const { return m_pElements[current].next; }

	ElementType RemoveHead( ) { return RemoveAt( m_Head ); }
	bool         AddHead( ElementType );
	bool         AddTail( ElementType );

	bool         RemoveElement( ElementType value );
	ElementType RemoveAt( int position );

	void         Clean( );

	void		 PrintoutToLog( ) const;

private:

	int			AllocateElement( );

	//forbid
	CPPNativeList& operator = ( const CPPNativeList& source );

	////////////////data/////////////
	int m_MaxLength;
	int m_CurrentLength;
	int m_Head;				//index of head or -1
	int m_Tail;				//index of tail or -1

	int m_FreeHead;				//not in list
	int m_FreeTail;

	CPPNativeListElement* m_pElements;
};

template <class ElementType>
CPPNativeList<ElementType>::CPPNativeList( int max_length):
	m_MaxLength(max_length),
	m_CurrentLength(0),
	m_Head(LIST_ELEMENT_NOT_FOUND),
	m_Tail(LIST_ELEMENT_NOT_FOUND),
	m_FreeHead(LIST_ELEMENT_NOT_FOUND),
	m_FreeTail(LIST_ELEMENT_NOT_FOUND)
{
	if (m_MaxLength <= 0) m_MaxLength = LIST_DEFAULT_MAX_LENGTH;
	m_pElements = new CPPNativeListElement[m_MaxLength];

	if (m_pElements == NULL)
	{	
		m_MaxLength = 0;
		return;
	}

	Clean( );
}

template <class ElementType>
CPPNativeList<ElementType>::CPPNativeList( const CPPNativeList<ElementType>& source ):
	m_MaxLength(source.m_MaxLength),
	m_CurrentLength(source.m_CurrentLength),
	m_Head(source.m_Head),
	m_Tail(source.m_Tail),
	m_FreeHead(source.m_FreeHead),
	m_FreeTail(source.m_FreeTail),
	m_pElements(NULL)
{
	//copy elements of list
	if (source.m_pElements)
	{
		m_pElements = new CPPNativeListElement[m_MaxLength];

		if (m_pElements == NULL)
		{	
			m_MaxLength = 0;
			return;
		}
		memcpy( m_pElements, source.m_pElements, sizeof(CPPNativeListElement) * m_MaxLength );
	}
}

template <class ElementType>
CPPNativeList<ElementType>::~CPPNativeList( )
{
	if (m_pElements) delete [] m_pElements;
}

template <class ElementType>
void CPPNativeList<ElementType>::Clean( )
{
	if (m_pElements == NULL) return;

	//list properties
	m_Head = LIST_ELEMENT_NOT_FOUND;
	m_Tail = LIST_ELEMENT_NOT_FOUND;
	m_CurrentLength = 0;

	//free properties
	m_FreeHead = 0;
	m_FreeTail = m_MaxLength - 1;

	m_pElements[0].prev = LIST_ELEMENT_NOT_FOUND;
	for (int i = 0; i < m_MaxLength - 1; ++i)
	{
		m_pElements[i + 1].prev = i;
		m_pElements[i].next = i + 1;
	}
	m_pElements[m_MaxLength - 1].next = LIST_ELEMENT_NOT_FOUND;
}

template <class ElementType>
int	CPPNativeList<ElementType>::Find( ElementType value ) const
{
	int currentPosition = m_Head;

	while (currentPosition != LIST_ELEMENT_NOT_FOUND)
	{
		if (m_pElements[currentPosition].value == value)
		{
			break;
		}
		else
		{
			currentPosition = GetNext( currentPosition );
		}
	}
	return currentPosition;
}

template <class ElementType>
int	CPPNativeList<ElementType>::AllocateElement( )
{
	int result = m_FreeHead;

	m_FreeHead = GetNext( m_FreeHead );
	if (m_CurrentLength >= m_MaxLength - 1)
	{
		m_FreeHead = LIST_ELEMENT_NOT_FOUND;	//we only use freehead as indicator
		m_FreeTail = LIST_ELEMENT_NOT_FOUND;
	}
	else
	{
		m_pElements[m_FreeHead].prev = LIST_ELEMENT_NOT_FOUND;
	}

	return result;
}

template <class ElementType>
bool CPPNativeList<ElementType>::AddHead( ElementType value )
{
	if (m_CurrentLength >= m_MaxLength) return false;

	int newElement = AllocateElement( );

	//init
	m_pElements[newElement].value = value;

	//insert at head
	int oldHead = m_Head;

	m_Head = newElement;
	m_pElements[m_Head].next = oldHead;
	m_pElements[m_Head].prev = LIST_ELEMENT_NOT_FOUND;

	if (m_CurrentLength > 0)
	{
		m_pElements[oldHead].prev = m_Head;
	}
	else
	{
		m_Tail = m_Head;
	}

	++m_CurrentLength;

	return true;
}

template <class ElementType>
bool CPPNativeList<ElementType>::AddTail( ElementType value )
{
	if (m_CurrentLength >= m_MaxLength) return false;

	int newElement = AllocateElement( );

	//init
	m_pElements[newElement].value = value;

	//insert at Tail
	int oldTail = m_Tail;

	m_Tail = newElement;
	m_pElements[m_Tail].next = LIST_ELEMENT_NOT_FOUND;
	m_pElements[m_Tail].prev = oldTail;

	if (m_CurrentLength > 0)
	{
		m_pElements[oldTail].next = m_Tail;
	}
	else
	{
		m_Head = m_Tail;
	}

	++m_CurrentLength;

	return true;
}

template <class ElementType>
bool CPPNativeList<ElementType>::RemoveElement( ElementType value )
{
	int foundat = Find( value );
	
	if (foundat == LIST_ELEMENT_NOT_FOUND)
	{
		return false;
	}
	else
	{
		RemoveAt( foundat );

		return true;
	}
}

template <class ElementType>
ElementType CPPNativeList<ElementType>::RemoveAt( int position )
{
	ElementType result = GetAt( position );

	if (m_CurrentLength <= 1)
	{
		Clean( );

		return result;
	}

	//remove it from list
	int nextElement = GetNext( position );
	int prevElement = m_pElements[position].prev;

	if (nextElement != LIST_ELEMENT_NOT_FOUND)
	{
		m_pElements[nextElement].prev = prevElement;
	}
	if (prevElement != LIST_ELEMENT_NOT_FOUND)
	{
		m_pElements[prevElement].next = nextElement;
	}

	if (m_Head == position)
	{
		m_Head = nextElement;
	}
	if (m_Tail == position)
	{
		m_Tail = prevElement;
	}

	//put it into free list
	if (m_FreeHead != LIST_ELEMENT_NOT_FOUND)
	{
		//assume m_FreeTail != LIST_ELEMENT_NOT_FOUND too
		m_pElements[position].next = LIST_ELEMENT_NOT_FOUND;
		m_pElements[position].prev = m_FreeTail;
		m_pElements[m_FreeTail].next = position;
		m_FreeTail = position;
	}
	else
	{
		m_FreeTail = position;
		m_FreeHead = m_FreeTail;
	}

	--m_CurrentLength;
	return result;
}

template <class ElementType>
void CPPNativeList<ElementType>::PrintoutToLog( ) const
{
	LOG_FINEST( "CPPNativeList::PrintoutToLog\n" );
	LOG_FINEST1( "m_MaxLength=%d\n", m_MaxLength );
	LOG_FINEST1( "m_CurrentLength=%d\n", m_CurrentLength );
	LOG_FINEST1( "m_pElements=0x%p\n", m_pElements );

	int currentPosition = m_Head;

	int i = 0;
	while (currentPosition != LIST_ELEMENT_NOT_FOUND)
	{
		LOG_FINEST2( "list[%d]=0x%x\n", i, m_pElements[currentPosition].value );
		currentPosition = GetNext( currentPosition );
		++i;
	}

	LOG_FINEST( "DUMP\n" );
	LOG_FINEST1( "m_Head=%d\n", m_Head );
	LOG_FINEST1( "m_Tail=%d\n", m_Tail );
	LOG_FINEST1( "m_FreeHead=%d\n", m_FreeHead );
	LOG_FINEST1( "m_FreeTail=%d\n", m_FreeTail );

	for (i = 0; i < m_MaxLength; ++i)
	{
		char buffer[128] = {0};
		sprintf( buffer, "element[%d]: prev=%d, next=%d, value=0x%x\n",
			i,
			m_pElements[i].prev,
			m_pElements[i].next,
			m_pElements[i].value
			);
		LOG_FINEST( buffer );
	}
}

#endif //#ifndef __XOS_POINTER_LIST_H__
