# Microsoft Developer Studio Project File - Name="dhs" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=dhs - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "dhs.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "dhs.mak" CFG="dhs - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "dhs - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "dhs - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "dhs - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "WITH_DSA2000_SUPPORT" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp2 /MT /W3 /GX /O2 /I "C:\Adlib\AlWdm\Msc" /I "..\..\xos\src" /I "..\..\mysql\include" /I "c:\genie2k\s560\\" /D "WITH_ADAC5500_SUPPORT" /D "WIN32" /D "WITH_DSA2000_SUPPORT" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /U "VMS" /FD /c /Tp
# SUBTRACT CPP /YX
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 adlcore.lib utility.lib sad.lib xos.lib mysqlclient.lib wsock32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386 /nodefaultlib:"MSVCRT" /libpath:"C:\Adlib\AlWdm\Msc" /libpath:"..\..\xos\win32\Release" /libpath:"..\..\mysql\lib\opt" /libpath:"c:\genie2k\s560\\"

!ELSEIF  "$(CFG)" == "dhs - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "WITH_DSA2000_SUPPORT" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /ZI /Od /I "C:\Adlib\AlWdm\Msc" /I "..\..\xos\src" /I "..\..\mysql\include" /I "c:\genie2k\s560" /D "WITH_ADAC5500_SUPPORT" /D "WIN32" /D "WITH_DSA2000_SUPPORT" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /U "VMS" /FR /FD /GZ /c /Tp
# SUBTRACT CPP /YX
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 adlcore.lib sad.lib utility.lib ..\..\mysql\lib\debug\libmySQL.lib xos.lib wsock32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept /libpath:"C:\Adlib\AlWdm\Msc" /libpath:"..\..\xos\win32\Debug\\" /libpath:"c:\genie2k\s560" /libpath:"..\..\mysql\lib\debug"
# SUBTRACT LINK32 /verbose /pdb:none /incremental:no

!ENDIF 

# Begin Target

# Name "dhs - Win32 Release"
# Name "dhs - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\src\ADAC5500.cpp
# End Source File
# Begin Source File

SOURCE=..\src\adac5500_win32.cpp
# End Source File
# Begin Source File

SOURCE=..\src\dhs_config.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_database.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_dcs_messages.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_main.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_monitor.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_motor_messages.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_network.cc
# End Source File
# Begin Source File

SOURCE=..\src\dhs_threads.cc
# End Source File
# Begin Source File

SOURCE=..\src\dsa2000.cpp
# End Source File
# Begin Source File

SOURCE=..\src\xos_database.cc
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\src\adac5500.h
# End Source File
# Begin Source File

SOURCE=..\src\adac5500_win32.h
# End Source File
# Begin Source File

SOURCE=..\src\async.h
# End Source File
# Begin Source File

SOURCE=..\src\dcs.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_Camera.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_config.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_database.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_dcs_messages.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_detector.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_dmc1000.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_dmc2180.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_messages.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_monitor.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_motor_messages.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_network.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_Quantum315.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_Quantum4.h
# End Source File
# Begin Source File

SOURCE=..\src\dhs_threads.h
# End Source File
# Begin Source File

SOURCE=..\src\dsa2000.h
# End Source File
# Begin Source File

SOURCE=..\src\imgCentering.h
# End Source File
# Begin Source File

SOURCE=..\src\libimage.h
# End Source File
# Begin Source File

SOURCE=..\src\resource.h
# End Source File
# Begin Source File

SOURCE=..\src\safeFile.h
# End Source File
# Begin Source File

SOURCE=..\src\simulate_dsa2000.h
# End Source File
# Begin Source File

SOURCE=..\src\xform.h
# End Source File
# Begin Source File

SOURCE=..\src\xos_database.hh
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=..\src\adac5500_win32.rc
# End Source File
# End Group
# End Target
# End Project
