#ifndef __ImpCommandFacory_h__
#define __ImpCommandFacory_h__

/**
 * @file ImpCommandFactory.h
 * Header file ImpCommandFactory class and a list of command names
 * supported by the impersonation server.
 */

/**
 * @defgroup ImpConst Impersonation Constants
 * @brief Command names supported by the impersonation server.
 * @{
 */

/**
 * @defgroup IMP_COMMAND Command Names
 * @ingroup ImpConst
 * @brief Command names supported by the impersonation server.
 * @{
 */

/**
 * @def IMP_GETIMAGE
 * @brief getImage command
 *
 * ImpCommandFactory will create an instance of ImpGetImage for this command.
 */
#define IMP_GETIMAGE "getImage"

/**
 * @def IMP_GETIMAGEHEADER
 * @brief getImageHeader command
 *
 * ImpCommandFactory will create an instance of ImpGetImage for this command.
 */
#define IMP_GETIMAGEHEADER "getImageHeader"


/**
 * @def IMP_GETHEADER
 * @brief getHeader command
 *
 * ImpCommandFactory will create an instance of ImpGetImage for this command.
 */
#define IMP_GETHEADER "getHeader"

/**
 * @def IMP_GETTHUMBNAIL
 * @brief getThumbnail command
 *
 * ImpCommandFactory will create an instance of getThumbnail for this command.
 */
#define IMP_GETTHUMBNAIL "getThumbnail"


/**
 * @def IMP_READFILE
 * @brief readFile command
 *
 * ImpCommandFactory will create an instance of ImpReadFile for this command.
 */
#define IMP_READFILE "readFile"

/**
 * @def IMP_ISFILEREADABLE
 * @brief isFileReadable command
 *
 * ImpCommandFactory will create an instance of ImpreadFile for this command.
 */
#define IMP_ISFILEREADABLE "isFileReadable"

/**
 * @def IMP_WRITEFILE
 * @brief writeFile command
 *
 * ImpCommandFactory will create an instance of ImpWriteFile for this command.
 */
#define IMP_WRITEFILE "writeFile"

/**
 * @def IMP_WRITEFILES
 * @brief writeFiles command
 *
 * ImpCommandFactory will create an instance of ImpWriteFiles for this command.
 */
#define IMP_WRITEFILES "writeFiles"

/**
 * @def IMP_RUNEXECUTABLE
 * @brief runExecutable command
 *
 * ImpCommandFactory will create an instance of ImpRunExecutable for this command.
 */
#define IMP_RUNEXECUTABLE "runExecutable"

/**
 * @def IMP_RUNSCRIPT
 * @brief runScript command
 *
 * ImpCommandFactory will create an instance of ImpRunScript for this command.
 */
#define IMP_RUNSCRIPT "runScript"

/**
 * @def IMP_GETPROCESSSTATUS
 * @brief getProcessInfo command
 *
 * ImpCommandFactory will create an instance of ImpProcess for this command.
 */
#define IMP_GETPROCESSSTATUS "getProcessStatus"

/**
 * @def IMP_KILLPROCESS
 * @brief killProcess command
 *
 * ImpCommandFactory will create an instance of ImpProcess for this command.
 */
#define IMP_KILLPROCESS "killProcess"

/**
 * @def IMP_LISTDIRECTORY
 * @brief listDirectory command
 *
 * ImpCommandFactory will create an instance of ImpListDirectory for this command.
 */
#define IMP_LISTDIRECTORY "listDirectory"

/**
 * @def IMP_GETFILEPERMISSION
 * @brief getFilePermissions command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_GETFILEPERMISSION "getFilePermissions"

/**
 * @def IMP_GETFILESTATUS
 * @brief getFileStatus command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_GETFILESTATUS "getFileStatus"

/**
 * @def IMP_GETVERSION
 * @brief getVersion command
 *
 * ImpCommandFactory will create an instance of ImpVersion for this command.
 */
#define IMP_GETVERSION "getVersion"

/**
 * @def IMP_CREATEDIRECTORY
 * @brief createDirectory command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_CREATEDIRECTORY "createDirectory"

/**
 * @def IMP_DELETEDIRECTORY
 * @brief deleteDirectory command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_DELETEDIRECTORY "deleteDirectory"

/**
 * @def IMP_COPYFILE
 * @brief copyFile command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_COPYFILE "copyFile"

/**
 * @def IMP_RENAMEFILE
 * @brief renameFile command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_RENAMEFILE "renameFile"

/**
 * @def IMP_DELETEFILE
 * @brief deleteFile command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_DELETEFILE "deleteFile"

/**
 * @def IMP_COPYDIRECTORY
 * @brief copyDirectory command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_COPYDIRECTORY "copyDirectory"

/**
 * @def IMP_RENAMEDIRECTORY
 * @brief renameDirectory command.
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_RENAMEDIRECTORY "renameDirectory"

/**
 * @def IMP_WRITABLEDIRECTORY
 * @brief writableDirectory command
 *
 * ImpCommandFactory will create an instance of ImpFileAccess for this command.
 */
#define IMP_WRITABLEDIRECTORY "writableDirectory"

/*
 * optional properties for writableDirecotyr
 * It will return the next file index baseed on these
 * the pattern will be PREFIX*.EXTENSION
 */
#define IMP_FILEFILTER_PREFIX "impFilePrefix"
#define IMP_FILEFILTER_EXTENSION "impFileExtension"

#define IMP_FILECOUNTER "impFileCounter"

/**
 * @}
 */

/**
 * @defgroup IMP_MISCCONST Miscellaneous Constants
 * @ingroup ImpConst
 * @brief Some constants used by the impersonation server.
 * @{
 */

/**
 * @def IMP_TRUE
 * @brief String value of true for the boolean parameters
 */
#define IMP_TRUE "true"

/**
 * @def IMP_FALSE
 * @brief String value of true or false for the boolean parameters
 */
#define IMP_FALSE "false"

/**
 * @}
 */

/**
 * @defgroup IMP_PARAM Parameter Names
 * @ingroup ImpConst
 * @brief Names of parameters that accompay a command.
 * @{
 */

/**
 * @def IMP_USER
 * @brief impUser parameter required by every command.
 */
#define IMP_USER "impUser"

/**
 * @def IMP_SESSIONID
 * @brief impSessionID parameter required by every command.
 */
#define IMP_SESSIONID "impSessionID"

/**
 * @def IMP_COMMAND
 * @brief impSessionID parameter it NOT required by most command
 * since the command name is already in the URL path.
 * readFile, runScript and runExecutable commands are the exceptions
 * since the URL path can be a parameter name of the command.
 * such as the file path (for readFile command) or shell script path
 * (for runScript) or executable path (for runExecutable).
 *
 * For example,
 *
 * @code

   http://localhost:61000/readFile?impUser=penjitk&impFilePath=/data/document.pdf&impSessionID=jdfhjsdfj

   and

   http://localhost:61000//data/document.pdf?impCommand=readFile&impUser=penjitk&impSessionID=jdfhjsdfj

 * @endcode
 *
 * The first URL contains the command name, readFile, in the URL path. The paramerter impCommand
 * therefore not required.
 *
 * The second URL contains the file path (interpreted by the impersonation server as impFilePath
 * parameter). In this case impCommand parameter is required.
 */
#define IMP_COMMAND "impCommand"

/**
 * @def IMP_NORC
 * @brief impNoRc is an optional parameter for runScript command.
 * Default is true. If impNoRc is true, csh or tcsh is run with -f option.
 * bash or sh is run with --norc option.
 */
#define IMP_NORC "impNoRc"

/**
 * @def IMP_FILEPATH
 * @brief impFilePath parameter required by readFile, getFilePermissions, deleteFile,
 * getFileStatus and writeFile commands.
 */
#define IMP_FILEPATH "impFilePath"

/**
 * @def IMP_FILESTARTOFFSET
 * @brief impFileStartOffset is an optional parameter for readFile command.
 */
#define IMP_FILESTARTOFFSET "impFileStartOffset"

/**
 * @def IMP_FILEENDOFFSET
 * @brief impFileEndOffset is an optional parameter for readFile command.
 */
#define IMP_FILEENDOFFSET "impFileEndOffset"

/**
 * @def IMP_FOLLOWSYMLINK
 * @brief impFollowSymlink is an optional parameter for copyDirectory and listDirectory commands.
 */
#define IMP_FOLLOWSYMLINK "impFollowSymlink"

/**
 * @def IMP_FOLLOWSYMLINK
 * @brief impCreateParents is an optional parameter for createDirectory command.
 */
#define IMP_CREATEPARENTS "impCreateParents"

/**
 * @def IMP_DELETECHILDREN
 * @brief impDeleteChildren is an optional parameter for deleteDirectory command.
 */
#define IMP_DELETECHILDREN "impDeleteChildren"

/**
 * @def IMP_SHOWABSOLUTEPATH
 * @brief impShowAbsolutePath is an optional parameter for listDirectory command.
 */
#define IMP_SHOWABSOLUTEPATH "impShowAbsolutePath"

/**
 * @def IMP_DIRECTORY
 * @brief impDirectory is an optional parameter for listDirectory and deleteDirectory commands.
 */
#define IMP_DIRECTORY "impDirectory"

/**
 * @def IMP_HOMEDIR
 * @brief impHomeDir is an optional parameter for runScript and runExecutable commands used
 * as default direvtory when impDirectory parameter is not supplied.
 */
#define IMP_HOMEDIR "impHomeDir"

/**
 * @def IMP_MAXDEPTH
 * @brief impMaxDepth is an optional parameter for listDirectory and copyDirectory commands.
 */
#define IMP_MAXDEPTH "impMaxDepth"

/**
 * @def IMP_FILEFILTER
 * @brief impFileFilter is a mandatory parameter for deleteDirectory command and is an optional
 * parameter for listDirectory command.
 */
#define IMP_FILEFILTER "impFileFilter"

/**
 * @def IMP_FILETYPE
 * @brief impFileType is an optional parameter for listDirectory command.
 */
#define IMP_FILETYPE "impFileType"

/**
 * @def IMP_SHOWDETAILS
 * @brief impShowDetails is an optional parameter for listDirectory command.
 */
#define IMP_SHOWDETAILS "impShowDetails"

/**
 * @def IMP_TMPDIR
 * @brief impTmpDir is an optional parameter for runExecutable command.
 */
#define IMP_TMPDIR "impTmpDir"

#define IMP_USERID "impUserId"
#define IMP_GROUPID "impGroupId"


/**
 * @def IMP_READPERMISSION
 * @brief impReadPermission is a returned parameter for getFilePermissions command.
 */
#define IMP_READPERMISSION "impReadPermission"

/**
 * @def IMP_WRITEPERMISSION
 * @brief impWritePermission is a returned parameter for getFilePermissions command.
 */
#define IMP_WRITEPERMISSION "impWritePermission"

/**
 * @def IMP_EXECUTEPERMISSION
 * @brief impExecutePermission is a returned parameter for getFilePermissions command.
 */
#define IMP_EXECUTEPERMISSION "impExecutePermission"

/**
 * @def IMP_FILEEXISTS
 * @brief impFileExists is a returned parameter for getFilePermissions command.
 */
#define IMP_FILEEXISTS "impFileExists"

/**
 * @def IMP_FILEMODE
 * @brief impFileMode is an optional parameter for copyFile, createDirectory and writeFile commands
 * and is a returned parameter for getFileStatus command.
 */
#define IMP_FILEMODE "impFileMode"

/**
 * @def IMP_EXECUTABLE
 * @brief impExecutable is a mandatory parameter for runExecutable command.
 */
#define IMP_EXECUTABLE "impExecutable"

/**
 * @def IMP_SHOWSYMLINKSTATUS
 * @brief impShowSymlinkStatus is an optional parameter for getFileStatus command.
 */
#define IMP_SHOWSYMLINKSTATUS "impShowSymlinkStatus"

/**
 * @def IMP_OLDFILEPATH
 * @brief impOldFilePath is a mandatory parameter for copyFile and renameFile commands.
 */
#define IMP_OLDFILEPATH "impOldFilePath"

/**
 * @def IMP_NEWFILEPATH
 * @brief impNewFilePath is a mandatory parameter for copyFile and renameFile commands.
 */
#define IMP_NEWFILEPATH "impNewFilePath"

/**
 * @def IMP_OLDDIRECTORY
 * @brief impOldDirectory is a mandatory parameter for copyDirectory command.
 */
#define IMP_OLDDIRECTORY "impOldDirectory"

/**
 * @def IMP_NEWDIRECTORY
 * @brief impNewDirectory is a mandatory parameter for copyDirectory command.
 */
#define IMP_NEWDIRECTORY "impNewDirectory"

#define IMP_USEFORK "impUseFork"

#define IMP_KEEP_STDIN "impKeepStdin"

/**
 * @def IMP_SHELL
 * @brief impShell is an optional parameter for runScript command.
 */
#define IMP_SHELL "impShell"

/**
 * @def IMP_DEFSHELL
 * @brief impDefShell is an optional parameter for runScript command used
 * when impShell parameter is not supplied.
 */
#define IMP_DEFSHELL "impDefShell"

/**
 * @def IMP_COMMANDLINE
 * @brief impCommandLine is a mandatory parameter for runScript command.
 */
#define IMP_COMMANDLINE "impCommandLine"

/**
 * @def IMP_FILETYPE
 * @brief impFileType is a return parameter for getFileStatus command
 * and an optional parameter for listDirectory command.
 */
#define IMP_FILETYPE "impFileType"

/**
 * @def IMP_FILEINO
 * @brief impFileInode is a return parameter for getFileStatus command.
 */
#define IMP_FILEINO "impFileInode"

/**
 * @def IMP_FILEDEV
 * @brief impFileDev is a return parameter for getFileStatus command.
 */
#define IMP_FILEDEV "impFileDev"

/**
 * @def IMP_FILERDEV
 * @brief impFileRdev is a return parameter for getFileStatus command.
 */
#define IMP_FILERDEV "impFileRdev"

/**
 * @def IMP_FILENLINK
 * @brief impFileNlink is a return parameter for getFileStatus command.
 */
#define IMP_FILENLINK "impFileNlink"

/**
 * @def IMP_FILEUID
 * @brief impFileUid is a return parameter for getFileStatus command.
 */
#define IMP_FILEUID "impFileUid"

/**
 * @def IMP_FILEGID
 * @brief impFileGid is a return parameter for getFileStatus command.
 */
#define IMP_FILEGID "impFileGid"

/**
 * @def IMP_FILESIZE
 * @brief impFileSize is a return parameter for getFileStatus command.
 */
#define IMP_FILESIZE "impFileSize"

/**
 * @def IMP_FILEATIME
 * @brief impFileAtime is a return parameter for getFileStatus command.
 */
#define IMP_FILEATIME "impFileAtime"

/**
 * @def IMP_FILEMTIME
 * @brief impFileMtime is a return parameter for getFileStatus command.
 */
#define IMP_FILEMTIME "impFileMtime"

/**
 * @def IMP_FILECTIME
 * @brief impFileCtime is a return parameter for getFileStatus command.
 */
#define IMP_FILECTIME "impFileCtime"

/**
 * @def IMP_FILEBLKSIZE
 * @brief impFileBlkSize is a return parameter for getFileStatus command.
 */
#define IMP_FILEBLKSIZE "impFileBlkSize"

/**
 * @def IMP_FILEBLOCKS
 * @brief impFileBlocks is a return parameter for getFileStatus command.
 */
#define IMP_FILEBLOCKS "impFileBlocks"

/**
 * @def IMP_FILEPATHREAL
 * @brief impFilePathReal is a return parameter for getFileStatus command.
 */
#define IMP_FILEPATHREAL "impFilePathReal"

/**
 * @def IMP_FILEREADABLE
 * @brief impFileReadable
 *
 * impFileReadable is a return parameter for isFileReadable command.
 */
#define IMP_FILEREADABLE "impFileReadable"

/**
 * @def IMP_WRITEBINARY
 * @brief impWriteBinary
 *
 * impWriteBinary is an optional input parameter for writeFile command
 * indicating that the file will be opened for writing in binary mode.
 */
#define IMP_WRITEBINARY "impWriteBinary"

/**
 * @def IMP_APPEND
 * @brief impAppend
 *
 * impAppend is an optional input parameter for writeFile command
 * indicating that the text will be appended to the existing file.
 */
#define IMP_APPEND "impAppend"

/**
 * @def IMP_BACKUPEXIST
 * @brief impBackupExist
 *
 * impBackupExist is an optional input parameter for writeFile command
 * indicating that if the file already exists, it will be backed up in
 * OVERWRITTEN_FILES sub directory.
 * File in OVERWRITTEN_FILES will be just overwritten.
 */
#define IMP_BACKUPEXIST "impBackupExist"

/**
 * @def IMP_WARNINGMSG
 * @brief impWarningMsg is an optional result for writeFile command.
 */
#define IMP_WARNINGMSG "impWarningMsg"

/**
 * @def IMP_SORTTYPE
 * @brief impSortType
 *
 * impSortType is an optional input parameter for listDirectory command.
 * 0 for no sorting, 1 for sort by file path.
 */
#define IMP_SORTTYPE "impSortType"

/**
 */
#define IMP_PROCESSID "impProcessId"

/**
 */
#define IMP_STDOUTFILE "impStdoutFile"

/**
 */
#define IMP_STDERRFILE "impStderrFile"

#define IMP_SHOWUSERPROCESSONLY "impShowUserProcessOnly"
#define IMP_USERSTAFF "impUserStaff"
/**
 * @}
 */

/**
 * @}
 */

#include <string>
#include <map>

class HttpServer;
class ImpCommand;

typedef ImpCommand* (*func_pointer)(const std::string&, HttpServer*);

/**
 * @class ImpCommandFactory
 * A factortory class for create an instance of subclasses of ImpCommand
 * for a given command name.
 */
class ImpCommandFactory
{
public:

    /**
     * @brief Creates an instance of a subclass of ImpCommand
     * for the given command.
     * @param name Command name
     * @param s A valid HttpServer to be used by the ImpCommand
     *          to access HttpRequest, HttpResponse and the HTTP streams.
     */
    static ImpCommand* createImpCommand(
                        const std::string& name,
                        HttpServer* s);

    /**
     * @brief Creates an instance of a subclass of ImpCommand
     * for the given command. Same as createImpCommand()
     * but only the readonly commands are allowed.
     * @param name Command name
     * @param s A valid HttpServer to be used by the ImpCommand
     *          to access HttpRequest, HttpResponse and the HTTP streams.
     */
    static ImpCommand* createReadOnlyImpCommand(
                        const std::string& name,
                        HttpServer* s);

    /**
     * @brief Register a static function to create a command.
     * @param name Command name
     * @param func A function pointer
     */
    static void registerImpCommand(
                        const std::string& name,
                        func_pointer func,
		    	bool readOnly);
    
    static std::map<std::string, func_pointer>* funcLookup;
    static std::map<std::string, func_pointer>* readOnlyFuncLookup;
	
};

#endif // __ImpCommandFacory_h__
