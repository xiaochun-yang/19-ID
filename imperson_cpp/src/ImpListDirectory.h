#ifndef __ImpListDirectory_h__
#define __ImpListDirectory_h__

/**
 * @file ImpListDirectory.h
 * Header file for ImpListDirectory class.
 */

#include <limits.h>
#include "ImpCommand.h"
#include "ImpRegister.h"
#include <set>

class HttpServer;
class XosFileNameWildcard;

/**
 * @class ImpListDirectory
 * Subclass of ImpCommand for listing a directory.
 *
 * listDirectory allows the client to list the contents of a directory,
 * specified as impDirectory. impMaxDepth can be used to specified the depth
 * of the directory tree. impFileFilter is a filename-wildcard for filter the files to be returned.
 * Note that the directories will not be filtered by this wildcard.
 * impFileType can be used to select the type of files. The value can be file, directory or all.
 *
 * @todo Handle a list of wildcards (separated by commas)
 * @todo Use native Unix wildcard.
 * @todo Move utility func for file access to XosFileUtil.
 */

class ImpListDirectory : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpListDirectory();

    /**
     * @brief Constructor. Creates an instance of ImpListDirectory with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpListDirectory(HttpServer* s);

    ImpListDirectory(const std::string& n, HttpServer* s);

    /**
     * @brief Destructor.
     */
    virtual ~ImpListDirectory();

    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error
     */
    virtual void execute() throw(XosException);

    static std::string resolveDir(std::string dir, const std::string& impUser) 
    throw(XosException);
    
    static std::string getDirFromPath(const std::string& path) 
    throw(XosException);
    /**
     * @brief static method for creating an instance of this class.
     * Used by ImpCommandFactory.
     * @param n Command name to register with ImpCommandFactory
     * @param s Pointer to HttpServer
     */
    static ImpCommand* createCommand(const std::string& n, HttpServer* s);

private:

    std::string impDirectory;
    bool isAbsolutePath;
    int maxDepth;
    bool isListDir;
    bool isListFile;
    bool isFollowSymlink;
    bool isShowDetails;
    int sortType;

    int depth;

    char displayedPath[2000];
    
    std::set<std::string> dirs;


    XosFileNameWildcard* wildcard;

    void readDir() throw(XosException);

    int traverseDirTree(char* fullpath);


    // UTILITY

    /**
     * Returns string representing file status
     **/
    void getFileInfo(char* ret, const char* filename,
                      struct stat& statbuf);

    /**
     * Returns string representing file mode
     **/
    std::string getFileType(mode_t mode);

    /**
     * Returns string representing file permission
     **/
    std::string getFilePermissions(mode_t mode);
    
};

#endif // __ImpListDirectory_h__
