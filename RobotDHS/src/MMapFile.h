#ifndef MMAPFILE_H
#define MMAPFILE_H


class MMapFile {

//methods
public:

	MMapFile ( void );
	~MMapFile ( void );

	int OpenMemMap ( unsigned, void** );
private:
	void CreateMemMapFile ( void );

//data
	HANDLE  m_FileHandle;
	HANDLE  m_MapHandle;
	LPVOID  m_Address;
	
};

#endif