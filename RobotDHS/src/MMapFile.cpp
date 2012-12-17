#include "stdafx.h"
#include "Registry.h"
#include "MMapFile.h"
#include "log_quick.h"

MMapFile::MMapFile ( void ):
	m_FileHandle(INVALID_HANDLE_VALUE),
	m_MapHandle(NULL),
	m_Address(NULL)
{
}

MMapFile::~MMapFile ( void )
{
	if (m_Address) UnmapViewOfFile ( m_Address );
	if (m_MapHandle) CloseHandle( m_MapHandle );
	if (m_FileHandle != INVALID_HANDLE_VALUE) CloseHandle( m_FileHandle );
}

void MMapFile::CreateMemMapFile ( void )
{
	DWORD dwCreateFileShareMode			= FILE_SHARE_READ | FILE_SHARE_WRITE;
	DWORD dwCreateFileDesiredAccess		= GENERIC_READ | GENERIC_WRITE;
	DWORD dwCreateDisposition			= OPEN_ALWAYS;
    const char* defaultFileName				= "C:\\RobotState.mem";

    //setup DCSS server info
	CRegistry winRegistry;

    CString fileName;

	winRegistry.SetRootKey( HKEY_LOCAL_MACHINE );
	if (winRegistry.SetKey("Software\\ROBOT\\RobotControl", FALSE ))
	{
		fileName = winRegistry.ReadString ( "MemoryMapFile", defaultFileName );
	}

	m_FileHandle = CreateFile (	fileName,
								dwCreateFileDesiredAccess, 
								dwCreateFileShareMode, 
								NULL,
								dwCreateDisposition, 
								FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, 
								NULL );
	if (m_FileHandle == INVALID_HANDLE_VALUE)
	{
        LOG_SEVERE1( "MMapFile::CreateMemMapFile(%s): failed in CreateFile", (const char *)fileName );
	}
}

int MMapFile::OpenMemMap ( unsigned mapSize, void** baseAddress )
{
	CreateMemMapFile ( );
	if (m_FileHandle == INVALID_HANDLE_VALUE)
	{
		return -1;
	}

	m_MapHandle = CreateFileMapping( m_FileHandle,			// use paging file
												NULL,				// no security attributes
												PAGE_READWRITE,		// read/write access
												0,					// size: high 32-bits
												mapSize,			// size: low 32-bits
												"myMemMap" );		// name of map object
	if (m_MapHandle == NULL)
	{
		LOG_SEVERE( "MMapFile::OpenMemMap: failed in CreateFileMapping" );
		return -1;
	}

    m_Address = MapViewOfFile(	m_MapHandle,	// object to map view of
									FILE_MAP_WRITE,	// read/write access
									0,				// high offset:  map from
									0,				// low offset:   beginning
									0 );			// default: map entire file

	if ( m_Address == NULL ) 
	{
		return -1;
	}

	//OK
	*baseAddress = m_Address;
	return 0;
}