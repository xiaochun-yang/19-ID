/*
 *	Items designed to make the code compatible, syntatically,
 *	with windows.
 */

#define HANDLE  void *
#define	WINAPI

#define	BYTE	char
#define	LPCSTR	char *
#define	LPSTR	char *
#define	BOOL	char
#define	DWORD	long
#define	WORD	short
#define	ULONG	unsigned long
#define	UCHAR	unsigned char
#define	USHORT	unsigned short
#define	PVOID	void *
#define	UINT	unsigned int
#define	PBYTE	char *
#define	PWORD	short *
#define	__int64	long long
#define	PULONG	unsigned long *
#define	PUCHAR	unsigned char *

/*
 *	Extra windows stuff
 */

#define	GPTR		0
#define	WAIT_TIMEOUT	0
#define	TRUE		1
#define	FALSE		0
#define	LMEM_FIXED	0
#define	GMEM_MOVEABLE	0
#define	GMEM_ZEROINIT	0

#define	WSADATA	int
#define	LPVOID	void *
#define	PUSHORT	unsigned short *
#define	PSHORT	short *

int     WSAStartup(int version, WSADATA * data);
HANDLE  GlobalAlloc(int type, int size);
void    *GlobalLock(HANDLE h);
void    GlobalUnlock(HANDLE h);
void    GlobalFree(HANDLE h);
HANDLE  CreateEvent( void *s, int a, int b, void *t);
void	Sleep(int msec);
LPVOID  LocalAlloc(int type, int size);
void    LocalFree(LPVOID h);
