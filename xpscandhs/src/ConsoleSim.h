#ifndef __CONSOLE_SIMULATOR_H__
#define __CONSOLE_SIMULATOR_H__


#include "Console.h"

class ConsoleSim :
	public Console
{
public:
	ConsoleSim(void);
	~ConsoleSim(void);

	virtual BOOL Initialize( );
	virtual void Cleanup( ) {}

	virtual ConsoleStatus GetStatus( ) const;
/*
	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL MountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL MountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL PrepareSortCrystal( const char argument[], char status_buffer[] );
	virtual BOOL SortCrystal( const char argument[], char status_buffer[] );


	virtual BOOL Config( const char argument[],  char status_buffer[] );

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] );
*/	
	// console dhs operations
	virtual BOOL Init8bmCons(const char argument[], char status_buffer[] );
        virtual BOOL StartMonitorCounts(const char argument[], char status_buffer[] );
        virtual BOOL StopMonitorCounts(const char argument[], char status_buffer[] );
	virtual BOOL ReadMonitorCounts(const char argument[], char status_buffer[] );
	virtual BOOL ReadAnalog(const char argument[], char status_buffer[] );
	virtual BOOL MoveToNewEnergy(const char argument[], char status_buffer[] );	
	virtual BOOL GetCurrentEnergy(const char argument[], char status_buffer[] );
        virtual BOOL ReadOrtecCounters(const char argument[], char status_buffer[] );
        virtual BOOL readOrtecCounters(const char argument[], char status_buffer[] );
        virtual BOOL MonoStatus(const char argument[], char status_buffer[] );

	double m_CurrentWavelength;

private:
	BOOL m_CrystalMounted;
};

#endif //#ifndef __CONSOLE_SIMULATOR_H__
