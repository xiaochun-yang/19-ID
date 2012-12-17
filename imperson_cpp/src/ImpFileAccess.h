#ifndef __ImpFileAccess_h__
#define __ImpFileAccess_h__

/**
 * @file ImpFileAccess.h
 * Header file for ImpFileAccess class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"

class HttpServer;

/**
 * @class ImpFileAccess
 * Subclass of ImpCommand for handling file access commands, including
 * copyFile, renameFile, deleteFile, getFileStatus, getFilePermissions,
 * createDirectory, deleteDirectory and copyDirectory.
 *
 * ImpServer creates an instance of this class if the value of the request
 * header, "impCommand", is one of the above commands.
 *
 * @todo Move utility func for file access to XosFileUtil.
 *
 */

class ImpFileAccess : public ImpCommand
{
public:


    /**
     * @brief Constructor. Creates an instance of ImpRunScript with a command name and HttpServer.
     * @param n Name of the command.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpFileAccess(const std::string& n, HttpServer* s);


    /**
     * @brief Destructor.
     */
    virtual ~ImpFileAccess();

    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error.
     */
    virtual void execute() throw (XosException);

    /**
     * @brief static method for creating an instance of this class.
     * Used by ImpCommandFactory.
     * @param n Command name to register with ImpCommandFactory
     * @param s Pointer to HttpServer
     */
    static ImpCommand* createCommand(const std::string& n, HttpServer* s);

    /**
     * @brief static method to create or check a directory is writable
     * Used by writableDirectory in this class and impWriteFile
     * @param dir Directory Name to check
     * @param fileMode file mode to use if need create directory
     * It will return true if the directory exists but writable
     * It will through exception if failed
     */
    static bool createOrCheckDirectoryWritable( const std::string& dir,
    mode_t mode ) throw(XosException);


    static mode_t getParentPermissions( const std::string& path );

    static long getNextFileCounter( const std::string& impFilePath,
    const std::string& prefix, const std::string& ext );

    /**
     * @brief backup file to OVERWRITTEN_FILES sub directory.
     * Used by ImpWriteFile and ImpCopyFile.
     * only throw when directory (not the OVERWRITTEN_FIELS) not writable
     * @param filePath existing file to backup
     * @param mode used in creating dir or file
     * @param copy if true, the file is copied not moved.
     * @return false failed to back up file so it is removed
     */
    static bool  backupFile(
        const std::string& filePath, mode_t mode, bool copy );

    //more than backup file
    static void prepareDestinationFile(
        std::string& fileName,
        mode_t& mode,
        bool& append,
        bool& needBackup,
        bool& backuped,
        const HttpRequest* request,
        const char* tag
    ) throw(XosException);
    
    static void prepareDestinationFile(
        std::string& fileName,
        mode_t& mode,
        bool& append,
        bool& needBackup,
        bool& backuped,
        const HttpRequest* request
    ) throw(XosException);

    static void prepareDestinationTmpFile(
        std::string& fileName,
        mode_t& mode,
        bool& append,
        const HttpRequest* request
    ) throw(XosException);

    static void backupDestinationFileAtTheEnd(
        const std::string& fileName,
        mode_t mode,
        bool& needBackup,
        bool& backuped,
        const HttpRequest* request
    ) throw(XosException);

    static void writeBackupWarning(
        HttpResponse* response,
        std::string& body,
        const std::string& filePath,
        bool  backuped
    );

protected:

    ImpFileAccess();


private:

    std::string separator;
    static std::string sp;

    bool isFollowSymlink;
    int maxDepth;
    int depth;

    /**
     * init
     **/
    void init();

    /**
     * Handle the getFilePermission command
     **/
    void doGetFilePermission() throw(XosException);

    /**
     * Handle the getFileStatus command
     **/
    void doGetFileStatus() throw(XosException);

    /**
     * Handle createDirectory command
     **/
    void doCreateDirectory() throw(XosException);

    /**
     * Handle writableDirectory command
     **/
    void doWritableDirectory() throw(XosException);

    /**
     * Handle deleteDirectory command
     **/
    void doDeleteDirectory() throw(XosException);

    /**
     * Handle copyFile command
     **/
    void doCopyFile() throw(XosException);

    /**
     * Handle renameFile command
     **/
    void doRenameFile() throw(XosException);

    /**
     * Handle deleteFile command
     **/
    void doDeleteFile() throw(XosException);

    /**
     * Handle copyDirectory command
     **/
    void doCopyDirectory() throw(XosException);


    // UTILITY

    /**
     * Returns string representing file mode
     **/
    std::string getFileType(mode_t mode);

    /**
     * Returns string representing file permission
     **/
    std::string getFilePermissions(mode_t mode);

    /**
     * Returns number with bits on or off depending on the file modes
     **/
    mode_t getFilePermissions(const std::string& s, mode_t def);


    /**
     * Recursively remove file/dir set in fullpath
     **/
    void traverseRmDirTree(char* fullpath) throw (XosException);

    /**
     * Recursively copy file/dir from oldpath to newpath
     **/
    int traverseCopyDirTree(char* oldpath, char* newpath)
        throw (XosException);

    /**
     * Copy a file
     **/
    static void copyFile(const char* oldfile, const char* newfile)
        throw (XosException);
};

#endif // __ImpFileAccess_h__
