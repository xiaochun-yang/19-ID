#include "xos.h"
#include "log_quick.h"
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "ImpStatusCodes.h"
#include "XosStringUtil.h"
#include "XosFileUtil.h"
#include "XosException.h"
#include "XosAutoBuffer.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpFileAccess.h"
#include "ImpCommandFactory.h"
#include "XosFileNameWildcard.h"
#include "ImpListDirectory.h"    // Need it to get resoveDirectory()

#define HUNK_MAX 100000

ImpRegister* dummy1 = new ImpRegister(IMP_GETFILEPERMISSION, &ImpFileAccess::createCommand, true);
ImpRegister* dummy2 = new ImpRegister(IMP_GETFILESTATUS, &ImpFileAccess::createCommand, true);
ImpRegister* dummy3 = new ImpRegister(IMP_CREATEDIRECTORY, &ImpFileAccess::createCommand, false);
ImpRegister* dummy4 = new ImpRegister(IMP_DELETEDIRECTORY, &ImpFileAccess::createCommand, false);
ImpRegister* dummy5 = new ImpRegister(IMP_COPYFILE, &ImpFileAccess::createCommand, false);
ImpRegister* dummy6 = new ImpRegister(IMP_RENAMEFILE, &ImpFileAccess::createCommand, false);
ImpRegister* dummy7 = new ImpRegister(IMP_COPYDIRECTORY, &ImpFileAccess::createCommand, false);
ImpRegister* dummy8 = new ImpRegister(IMP_DELETEFILE, &ImpFileAccess::createCommand, false);
ImpRegister* dummy9 = new ImpRegister(IMP_WRITABLEDIRECTORY, &ImpFileAccess::createCommand, false);

std::string ImpFileAccess::sp = " ";

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpFileAccess::createCommand(const std::string& n, HttpServer* s)
{
    return new ImpFileAccess(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpFileAccess::ImpFileAccess()
    : ImpCommand()
{
    init();
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpFileAccess::ImpFileAccess(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
    init();
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpFileAccess::~ImpFileAccess()
{
}

/*************************************************
 *
 * init
 *
 *************************************************/
void ImpFileAccess::init()
{
    separator = "=";
    depth = 0;
    maxDepth = 1000;
}

/*************************************************
 *
 * execute
 *
 *************************************************/
void ImpFileAccess::execute()
    throw(XosException)
{

    if (name == IMP_GETFILEPERMISSION) {
        doGetFilePermission();
    } else if (name == IMP_GETFILESTATUS) {
        doGetFileStatus();
    } else if (name == IMP_CREATEDIRECTORY) {
        doCreateDirectory();
    } else if (name == IMP_DELETEDIRECTORY) {
        doDeleteDirectory();
    } else if (name == IMP_COPYFILE) {
        doCopyFile();
    } else if (name == IMP_RENAMEFILE) {
        doRenameFile();
    } else if (name == IMP_COPYDIRECTORY) {
        doCopyDirectory();
    } else if (name == IMP_DELETEFILE) {
        doDeleteFile();
    } else if (name == IMP_WRITABLEDIRECTORY) {
        doWritableDirectory();
    } else {
        throw XosException(554, SC_554);
    }
}

/*************************************************
 *
 * doGetFilePermission
 *
 *************************************************/
void ImpFileAccess::doGetFilePermission()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("getFilePermission: missing %s", IMP_USER);
        throw XosException(432, SC_432);
   }

    std::string impFilePath;
    if (!request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {
          LOG_WARNING1("getFilePermission: missing %s", IMP_FILEPATH);
        throw XosException(437, SC_437);
     } 

    impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);

    std::string endofline("\n");
    std::string body("");

    body += IMP_READPERMISSION + separator;
    if (access(impFilePath.c_str(), R_OK) >= 0) {
        body += IMP_TRUE;
        response->setHeader(IMP_READPERMISSION, IMP_TRUE);
    } else {
        body += IMP_FALSE;
        response->setHeader(IMP_READPERMISSION, IMP_FALSE);
          if (errno != 0)
                LOG_WARNING2("getFilePermission read access for %s failed because %s", 
                                        impFilePath.c_str(),
                                        XosFileUtil::getAccessErrorString(errno).c_str());
    }


    body += endofline + IMP_WRITEPERMISSION + separator;
    if (access(impFilePath.c_str(), W_OK) >= 0) {
        body += IMP_TRUE;
        response->setHeader(IMP_WRITEPERMISSION, IMP_TRUE);
    } else {
        body += IMP_FALSE;
        response->setHeader(IMP_WRITEPERMISSION, IMP_FALSE);
          if (errno != 0)
                LOG_WARNING2("getFilePermission write access for %s failed because %s", 
                                        impFilePath.c_str(),
                                        XosFileUtil::getAccessErrorString(errno).c_str());
    }

    body += endofline + IMP_EXECUTEPERMISSION + separator;
    if (access(impFilePath.c_str(), X_OK) >= 0) {
        body += IMP_TRUE;
        response->setHeader(IMP_EXECUTEPERMISSION, IMP_TRUE);
    } else {
        body += IMP_FALSE;
        response->setHeader(IMP_EXECUTEPERMISSION, IMP_FALSE);
          if (errno != 0)
                LOG_WARNING2("getFilePermission execute access for %s failed because %s", 
                                        impFilePath.c_str(),
                                        XosFileUtil::getAccessErrorString(errno).c_str());
    }


    body += endofline + IMP_FILEEXISTS + separator;
    if (access(impFilePath.c_str(), F_OK) == 0) {
        body += IMP_TRUE;
        response->setHeader(IMP_FILEEXISTS, IMP_TRUE);
    } else {
        body += IMP_FALSE;
        response->setHeader(IMP_FILEEXISTS, IMP_FALSE);
          if (errno != 0)
                LOG_WARNING2("getFilePermission F_OK for %s failed because %s", 
                                        impFilePath.c_str(),
                                        XosFileUtil::getAccessErrorString(errno).c_str());
    }


    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    stream->finishWriteResponse();

}

/*************************************************
 *
 * doCopyDirectory
 *
 *************************************************/
void ImpFileAccess::doCopyDirectory()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("copyDirectory missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
   }

    // Old file
    std::string impOldDirectory;
    if (!request->getParamOrHeader(IMP_OLDDIRECTORY, impOldDirectory)) {
          LOG_WARNING1("copyDirectory missing %s parameter", IMP_OLDDIRECTORY);
        throw XosException(447, SC_447);
    }

    impOldDirectory = ImpListDirectory::resolveDir(impOldDirectory, impUser);
    
    // New file
    std::string impNewDirectory;
    if (!request->getParamOrHeader(IMP_NEWDIRECTORY, impNewDirectory)) {
         LOG_WARNING1("copyDirectory missing %s parameter", IMP_NEWDIRECTORY);
        throw XosException(448, SC_448);
    }

    impNewDirectory = ImpListDirectory::resolveDir(impNewDirectory, impUser);

    // Optional impMaxDepth
    std::string impMaxDepth;
    if (request->getParamOrHeader(IMP_MAXDEPTH, impMaxDepth)) {
        sscanf(impMaxDepth.c_str(), "%d", &maxDepth );
        if (maxDepth <= 0) {
               LOG_WARNING1("copyDirectory invalid %s parameter", IMP_MAXDEPTH);
            throw XosException(449, SC_449);
          }
    }

    // Optional impFollowSymlink
    isFollowSymlink = true;
    std::string impFollowSymlink;
    if (request->getParamOrHeader(IMP_FOLLOWSYMLINK, impFollowSymlink)) {
        if (XosStringUtil::toLower(impFollowSymlink) == IMP_FALSE)
            isFollowSymlink = false;
    }


    char olddir[PATH_MAX+1];
    char newdir[PATH_MAX+1];

    if (impOldDirectory.size( ) > PATH_MAX) {
        LOG_SEVERE( "old dir too long, HACKER??" );
        throw XosException(450, SC_450);
    }
    if (impNewDirectory.size( ) > PATH_MAX) {
        LOG_SEVERE( "new dir too long, HACKER??" );
        throw XosException(595, SC_595);
    }

    strcpy(olddir, impOldDirectory.c_str());
    strcpy(newdir, impNewDirectory.c_str());

    traverseCopyDirTree(olddir, newdir);

    HttpResponse* response = stream->getResponse();
    std::string body("OK");
    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

    stream->finishWriteResponse();

}



/*************************************************
 *
 * doCopyFile
 *
 *************************************************/
void ImpFileAccess::doCopyFile()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    // Old file
    std::string impOldFilePath;
    if (!request->getParamOrHeader(IMP_OLDFILEPATH, impOldFilePath)) {
          LOG_WARNING1("copyFile missing %s parameter", IMP_OLDFILEPATH);
        throw XosException(445, SC_445);
    }

    // supporting multiple file copies
    if (impOldFilePath == "MULTIPLE_IN_BODY") {
        doCopyMultipleFiles( );
        return;
    }

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("copyFile missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }


    impOldFilePath = ImpListDirectory::resolveDir(impOldFilePath, impUser);
    
    // New file
    std::string impNewFilePath;
    mode_t fileMode;
    bool fileNeedBackup = false;
    bool fileBackuped = false;
    bool dummy;

    prepareDestinationFile(
        impNewFilePath,
        fileMode,
        dummy,
        fileNeedBackup,
        fileBackuped,
        request,
        IMP_NEWFILEPATH
    );

    copyFile(impOldFilePath.c_str(), impNewFilePath.c_str());

    if (chmod(impNewFilePath.c_str(), fileMode) != 0) {
        int errCode = errno;
        LOG_WARNING3("copyFile from %s to %s chmod failed because %s", 
        impOldFilePath.c_str(), 
        impNewFilePath.c_str(), 
        XosFileUtil::getChmodErrorString(errno).c_str());
        throw XosException(563, std::string(SC_563) + " " + XosFileUtil::getErrorCode(errCode));

    }
    
    HttpResponse* response = stream->getResponse();
    std::string body("OK");

    if (fileNeedBackup) {
        writeBackupWarning( response, body, impNewFilePath, fileBackuped );
    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

    stream->finishWriteResponse();

}
void ImpFileAccess::doCopyMultipleFiles( )
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();
    std::string body("OK");

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("copyFile missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }
    const size_t MAX_LINE_SIZE = PATH_MAX + 100;

    // "impOldFilePath=/old/path impNewFilePath=/new/path\n"
    char line[2*MAX_LINE_SIZE + 256] = {0};
    while (stream->fgetsRequestBody( line, sizeof(line) )) {
        std::string impOldFilePath;
        std::string impNewFilePath;

        if (!parseForOldNew( line, impOldFilePath, impNewFilePath )) {
            continue;
        }

        impOldFilePath = 
            ImpListDirectory::resolveDir(impOldFilePath, impUser);
        impNewFilePath = 
            ImpListDirectory::resolveDir(impNewFilePath, impUser);

        LOG_FINEST2( "copying %s to %s", impOldFilePath.c_str( ),
        impNewFilePath.c_str( ) );

        mode_t fileMode;
        bool fileNeedBackup = false;
        bool fileBackuped = false;
        bool dummy;

        prepareDestinationFile(
            impNewFilePath,
            fileMode,
            dummy,
            fileNeedBackup,
            fileBackuped,
            request
        );
        copyFile(impOldFilePath.c_str(), impNewFilePath.c_str());

        if (chmod(impNewFilePath.c_str(), fileMode) != 0) {
            int errCode = errno;
            LOG_WARNING3("copyFile from %s to %s chmod failed because %s", 
            impOldFilePath.c_str(), 
            impNewFilePath.c_str(), 
            XosFileUtil::getChmodErrorString(errno).c_str());
            throw XosException(563, std::string(SC_563) + " " + XosFileUtil::getErrorCode(errCode));
        }
        if (fileNeedBackup) {
            writeBackupWarning(
                response, body, impNewFilePath, fileBackuped
            );
        }
        body += "\n" + impOldFilePath + " copied to " + impNewFilePath;
    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

    stream->finishWriteResponse();

}

/*************************************************
 *
 * doRenameFile
 *
 *************************************************/
void ImpFileAccess::doRenameFile()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("renameFile missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
   }

    // Old file
    std::string impOldFilePath;
    if (!request->getParamOrHeader(IMP_OLDFILEPATH, impOldFilePath)) {
          LOG_WARNING1("renameFile missing %s parameter", IMP_OLDFILEPATH);
        throw XosException(445, SC_445);
    }
    impOldFilePath = ImpListDirectory::resolveDir(impOldFilePath, impUser);

    struct stat statbuf;
    if (stat(impOldFilePath.c_str(), &statbuf) != 0) {
          int errCode = errno;
          if ((errCode == ENOENT) && !impOldFilePath.empty()) {
                throw XosException(581, SC_581 + std::string(" ") + impOldFilePath 
                            + " does not exist");
          }
         LOG_WARNING2("renameFile stat for %s failed because %s", 
                            impOldFilePath.c_str(), 
                            XosFileUtil::getStatErrorString(errCode).c_str());
        throw XosException(581, SC_581 + std::string(" stat failed for ") + impOldFilePath 
                            + XosFileUtil::getErrorCode(errCode));
     }

    // New file
    std::string impNewFilePath;
    mode_t fileMode;
    bool fileNeedBackup = false;
    bool fileBackuped = false;
    bool dummy;

    prepareDestinationFile(
        impNewFilePath,
        fileMode,
        dummy,
        fileNeedBackup,
        fileBackuped,
        request,
        IMP_NEWFILEPATH
    );


    if (rename(impOldFilePath.c_str(), impNewFilePath.c_str()) != 0) {
          int errCode = errno;
         LOG_WARNING3("renameFile from %s to %s failed because %s", 
                impOldFilePath.c_str(), 
                impNewFilePath.c_str(), 
                XosFileUtil::getRenameErrorString(errCode).c_str());
        throw XosException(581, std::string(SC_581) + " " + XosFileUtil::getErrorCode(errCode));
     }

    HttpResponse* response = stream->getResponse();
    std::string body("OK");

    if (fileNeedBackup) {
        writeBackupWarning( response, body, impNewFilePath, fileBackuped );
    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

    stream->finishWriteResponse();
}


/*************************************************
 *
 * doDeleteFile
 *
 *************************************************/
void ImpFileAccess::doDeleteFile()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("deleteFile missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
   }


    // single file
    std::string impFilePath;
    if (request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {

        impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);
        
        if (remove(impFilePath.c_str()) != 0) {
                int errCode = errno;
                LOG_WARNING2("deleteFile %s failed because ", 
                        impFilePath.c_str(), 
                        XosFileUtil::getErrorString(errCode).c_str());
            throw XosException(574, std::string(SC_574) + " " + XosFileUtil::getErrorCode(errCode));
          }

    } else {


        // NO impFilePath
        // delete multiple files
        // Expect to see impDirectory and impFileFilter
        std::string impDirectory;
        if (!request->getParamOrHeader(IMP_DIRECTORY, impDirectory)) {
            LOG_WARNING1("deleteFile missing %s parameter", IMP_DIRECTORY);
            throw XosException(440, SC_440);
        }
            
        impDirectory = ImpListDirectory::resolveDir(impDirectory, impUser);


        std::string impFileFilter;
        XosFileNameWildcard* wildcard = NULL;
        if (!request->getParamOrHeader(IMP_FILEFILTER, impFileFilter)) {
            LOG_WARNING1("deleteFile missing %s parameter", IMP_FILEFILTER);
            throw XosException(443, SC_443);
         }

        // Create wildcard
        if (!impFileFilter.empty()) {
            wildcard = XosFileNameWildcard::createFileNameWildcard(impFileFilter.c_str());
        }

        if (wildcard == NULL) {
            LOG_WARNING1("deleteFile %s", SC_443);
            throw XosException(443, SC_443);
        }


        struct stat statbuf;
        struct dirent * dirp;
        DIR* dp;
        std::string slash("/");
        std::string fullpath("");
        if ((dp = opendir(impDirectory.c_str())) == NULL) {
            std::string err = XosFileUtil::getErrorString(errno, SC_572 + sp + impDirectory);
            LOG_WARNING1("deleteFile opendir failed: %s", err.c_str());
            throw XosException(572, err);
        }

        while ((dirp = readdir(dp)) != NULL) {

            if ((strcmp(dirp->d_name, ".") == 0) ||
                (strcmp(dirp->d_name, "..") == 0)) {
                    continue;
            }

            if (wildcard->match(dirp->d_name)) {

                fullpath = impDirectory;

                if (fullpath[fullpath.size()-1] != '/')
                    fullpath += slash;

                fullpath += dirp->d_name;

                // Failed to get file stat
                if (lstat(fullpath.c_str(), &statbuf) < 0) {
                    if (errno > 0)
                        LOG_INFO2("deleteFile lstat fails for %s because %s", 
                                    fullpath.c_str(), 
                                    XosFileUtil::getLstatErrorString(errno).c_str());
                    continue;
                }

                // Not a valid dir
                if (S_ISREG(statbuf.st_mode)) {
                    if (remove(fullpath.c_str()) != 0) {
                        delete wildcard;
                        std::string err = XosFileUtil::getErrorString(errno, SC_574 + sp + fullpath);
                        LOG_WARNING1("deleteFile remove failed: %s", err.c_str());
                        throw XosException(574, err);
                    }
                } else if (S_ISLNK(statbuf.st_mode)) {
                    if (unlink(fullpath.c_str()) != 0) {
                        delete wildcard;
                        std::string err = XosFileUtil::getErrorString(errno, SC_576 +  sp + fullpath);
                        LOG_WARNING1("deleteFile unlink failed: %s", err.c_str());
                        throw XosException(576, err);
                    }
                }

            } // wildcard->match

        }

        if (errno != 0) {
            LOG_WARNING2("Error in deletFile for %s: %s", 
                        impFilePath.c_str(), 
                        XosFileUtil::getReaddirErrorString(errno).c_str());
        }

        delete wildcard;
        
    }


    HttpResponse* response = stream->getResponse();
    std::string body("OK");
    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    
    stream->finishWriteResponse();
}


/*************************************************
 *
 * doGetFileStatus
 *
 *************************************************/
void ImpFileAccess::doGetFileStatus()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();


    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
       LOG_WARNING1("getFileStatus: Missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
   }

    std::string impFilePath;
    if (!request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {
           LOG_WARNING1("getFileStatus: Missing %s parameter", IMP_FILEPATH);
        throw XosException(437, SC_437);
    }
        
    impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);

    std::string impShowSymlinkStatus;
    bool isShowSymlinkStatus = false;
    if (request->getParamOrHeader(IMP_SHOWSYMLINKSTATUS, impShowSymlinkStatus)) {
        if (XosStringUtil::toLower(impShowSymlinkStatus) == IMP_TRUE)
            isShowSymlinkStatus = true;
    }


    struct stat info;
    if (lstat(impFilePath.c_str(), &info) != 0) {
          std::string err = XosFileUtil::getErrorString(errno, SC_558 + sp + impFilePath);
          LOG_WARNING2("getFileStatus: (1) %s %s", impFilePath.c_str(), err.c_str());
        throw XosException(558, err);
    }


    std::string separator("=");
    std::string endofline("\n");
    std::string body("");

    std::string val("");

    bool isLink = S_ISLNK(info.st_mode);

    // Show real file
    if (!isShowSymlinkStatus && isLink) {

        // Get info of the actual file
        if (stat(impFilePath.c_str(), &info) != 0) {
                  std::string err = XosFileUtil::getErrorString(errno, SC_558 + sp + impFilePath);
                  LOG_WARNING2("getFileStatus: (2) %s, %s", impFilePath.c_str(), err.c_str());
                throw XosException(558, err);
        }
    }

    // File path
    body += IMP_FILEPATH + separator;
    body += impFilePath;
    response->setHeader(IMP_FILEPATH, impFilePath);

    // File type
    if (!body.empty())
        body += endofline;

    val = getFileType(info.st_mode);
    body += IMP_FILETYPE + separator;
    body += val;
    response->setHeader(IMP_FILETYPE, val);

    // File permission
    val = getFilePermissions(info.st_mode);
    body += endofline + IMP_FILEMODE + separator;
    body += val;
    response->setHeader(IMP_FILEMODE, val);

    // Inode number
    val = XosStringUtil::fromLongInt(info.st_ino);
    body += endofline + IMP_FILEINO + separator;
    body += val;
    response->setHeader(IMP_FILEINO, val);

    // device number
    val = XosStringUtil::fromInt(info.st_dev);
    body += endofline + IMP_FILEDEV + separator;
    body += val;
    response->setHeader(IMP_FILEDEV, val);

    // device number for special file
    val = XosStringUtil::fromInt(info.st_rdev);
    body += endofline + IMP_FILERDEV + separator;
    body += val;
    response->setHeader(IMP_FILERDEV, val);

    // number of links
    val = XosStringUtil::fromInt(info.st_nlink);
    body += endofline + IMP_FILENLINK + separator;
    body += val;
    response->setHeader(IMP_FILENLINK, val);

    // user id of owner
    val = XosStringUtil::fromInt(info.st_uid);
    body += endofline + IMP_FILEUID + separator;
    body += val;
    response->setHeader(IMP_FILEUID, val);

    // group id of owner
    val = XosStringUtil::fromInt(info.st_gid);
    body += endofline + IMP_FILEGID + separator;
    body += val;
    response->setHeader(IMP_FILEGID, val);


    // Size in bytes
    val = XosStringUtil::fromLongInt(info.st_size);
    body += endofline + IMP_FILESIZE + separator;
    body += val;
    response->setHeader(IMP_FILESIZE, val);

    // last access time
    val = asctime(localtime(&info.st_atime));
    val = XosStringUtil::trim(val);
    body += endofline + IMP_FILEATIME + separator;
    body += val;
    response->setHeader(IMP_FILEATIME, val);

    // last modification time
    val = asctime(localtime(&info.st_mtime));
    val = XosStringUtil::trim(val);
    body += endofline + IMP_FILEMTIME + separator;
    body += val;
    response->setHeader(IMP_FILEMTIME, val);

    // last status change time
    val = asctime(localtime(&info.st_ctime));
    val = XosStringUtil::trim(val);
    body += endofline + IMP_FILECTIME + separator;
    body += val;
    response->setHeader(IMP_FILECTIME, val);

    // best I/O block size
    val = XosStringUtil::fromLongInt(info.st_blksize);
    body += endofline + IMP_FILEBLKSIZE + separator;
    body += val;
    response->setHeader(IMP_FILEBLKSIZE, val);

    // number of 512-byte blocks allocated
    val = XosStringUtil::fromLongInt(info.st_blocks);
    body += endofline + IMP_FILEBLOCKS + separator;
    body += val;
    response->setHeader(IMP_FILEBLOCKS, val);


    // Show real file name
    if (isLink) {

        char buf[PATH_MAX+1];
        int num;
        // Write out the actual file name
        if ((num=readlink(impFilePath.c_str(), buf, PATH_MAX+1)) > 0) {
            buf[num] = '\0';
            body += endofline + IMP_FILEPATHREAL + separator;
            body += buf;
            response->setHeader(IMP_FILEPATHREAL, buf);
        }

    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    stream->finishWriteResponse();

}

/*************************************************
 *
 * doCreateDirectory
 *
 *************************************************/
void ImpFileAccess::doCreateDirectory()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("createDirectory missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    std::string impFilePath;
    if (!request->getParamOrHeader(IMP_DIRECTORY, impFilePath)) {
            LOG_WARNING1("createDirectory missing %s parameter", IMP_DIRECTORY);
        throw XosException(440, SC_440);
    }
        
    impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);

    std::string impCreateParents;
    bool isCreateParents = false;
    if (request->getParamOrHeader(IMP_CREATEPARENTS, impCreateParents)) {
        if (XosStringUtil::toLower(impCreateParents) == IMP_TRUE)
            isCreateParents = true;
    }

    // File permissions canbe in one of the two formats:
    // octal number such as 0640
    // or a 10-character string beginning with d, such as drwx--x--x
    std::string impFileMode;
    mode_t fileMode = 0750;
    if (request->getParamOrHeader(IMP_FILEMODE, impFileMode)) {
        if (impFileMode[0] == '0') {
            sscanf(impFileMode.c_str(), "%4o", &fileMode);
        } else if ((impFileMode.size() == 10) &&
                (impFileMode[0] == 'd')) {
            fileMode = getFilePermissions(impFileMode, 0750);
        } else {
                LOG_WARNING2("createDirectory invalid %s parameter: %s", IMP_FILEMODE, impFileMode.c_str());
            throw XosException(453, SC_453);
        }
    }


    // If the user wants to make the whole path
    // then we need to start from top
    if (isCreateParents) {

        std::vector<std::string> paths;
        XosStringUtil::tokenize(impFilePath, "/", paths);

        std::string curPath("");
        std::string slash("/");
        std::vector<std::string>::iterator i = paths.begin();
        size_t count = 0;
        for (; i != paths.end(); ++i) {
            ++count;
            if ((*i == ".") || (*i == ".."))
                continue;
            curPath += slash + *i;
//            LOG_FINE1("checking path %s\n", curPath.c_str());
            // Create it if it does not exist
            if (access(curPath.c_str(), F_OK) < 0) {
                // Make the dir
//                LOG_FINE1("creating dir %s\n", curPath.c_str());
                if (mkdir(curPath.c_str(), fileMode) != 0) {
                          std::string err = XosFileUtil::getErrorString(errno, SC_573 + sp + curPath);
                          LOG_WARNING1("createDirectory %s", err.c_str());
                    throw XosException(573, err);
                }
            } else {
                // Throw an exception if the leaf already exists
                if (count == paths.size()) {
                          LOG_WARNING1("createDirectory: directory %s already exists", curPath.c_str());
                    throw XosException(573, curPath + " directory already exists");
                     }
            }

        }
    } else {

        // Make the leaf dir
        if (mkdir(impFilePath.c_str(), fileMode) != 0) {
                std::string err = XosFileUtil::getErrorString(errno, SC_573 + sp + impFilePath);
                LOG_WARNING1("createDirectory %s", err.c_str());
            throw XosException(573, err);
        }
        if (chmod(impFilePath.c_str(), fileMode) != 0) {
                std::string err = XosFileUtil::getErrorString(errno, SC_573 + sp + impFilePath);
                LOG_WARNING1("createDirectory %s", err.c_str());
            //throw XosException(573, err);
        }
    }

    HttpResponse* response = stream->getResponse();
    std::string body(response->getStatusPhrase());
    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    
    stream->finishWriteResponse();

}

/*************************************************
 *
 * doDeleteDirectory
 *
 *************************************************/
void ImpFileAccess::doDeleteDirectory()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
            LOG_WARNING1("deleteDirectory missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    std::string impDirectory;
    if (!request->getParamOrHeader(IMP_DIRECTORY, impDirectory)) {
            LOG_WARNING1("deleteDirectory missing %s parameter", IMP_DIRECTORY);
        throw XosException(440, SC_440);
     }

    impDirectory = ImpListDirectory::resolveDir(impDirectory, impUser);

    std::string impRmChildren;
    bool rmChildren = false;
    if (request->getParamOrHeader(IMP_DELETECHILDREN, impRmChildren)) {
        if (XosStringUtil::toLower(impRmChildren) == IMP_TRUE) {
            rmChildren = true;
        }
    }

    // Remove all children of this dir first
    if (rmChildren) {

        char fullpath[PATH_MAX+1];
        if (impDirectory.size( ) > PATH_MAX) {
            LOG_SEVERE( "dir too long, HACKER??" );
            throw XosException(444, SC_444);
        }
        strcpy(fullpath, impDirectory.c_str());

        traverseRmDirTree(fullpath);

    } else {


        if (rmdir(impDirectory.c_str()) != 0) {
                std::string err = XosFileUtil::getErrorString(errno, SC_574 + sp + impDirectory);
                LOG_WARNING1("deleteDirectory rmdir failed: %s", err.c_str());
            throw XosException(574, err);
        }
    }


    HttpResponse* response = stream->getResponse();
    std::string body("OK");
    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    
    stream->finishWriteResponse();

}


/*************************************************
 *
 * traverseRmDirTree
 *
 *************************************************/
void ImpFileAccess::traverseRmDirTree(char* fullpath)
    throw (XosException)
{

    struct stat statbuf;
    struct dirent * dirp;
    DIR * dp;
    char *ptr;
    std::string separator(": ");


    // Failed to get file stat
    if (lstat(fullpath, &statbuf) < 0) {
            std::string err = std::string(SC_558) + sp + fullpath + sp + XosFileUtil::getLstatErrorString(errno);
            LOG_WARNING1("traverseRmDirTree lstat failed: %s", err.c_str());
        throw XosException(558, err);
    }

    // Not a valid dir
    if (S_ISDIR(statbuf.st_mode) == 0) {
        switch (statbuf.st_mode & S_IFMT) {
            case S_IFREG:
                if (remove(fullpath) != 0) {
                            std::string err = std::string(SC_574) + sp + fullpath + sp + XosFileUtil::getErrorString(errno);
                            LOG_WARNING1("traverseRmDirTree remove failed: %s", err.c_str());
                    throw XosException(574, err);
                     }
                return;
            case S_IFBLK:
                break;
            case S_IFCHR:
                break;
            case S_IFIFO:
                break;
            case S_IFLNK:
                if (unlink(fullpath) != 0) {
                            std::string err = XosFileUtil::getErrorString(errno, SC_576 +  sp + fullpath);
                            LOG_WARNING1("traverseRmDirTree unlink failed: %s", err.c_str());
                    throw XosException(576, err);
                }
                     return;
            case S_IFSOCK:
                break;
            case S_IFDIR:
                break;
        }

        throw XosException(575, SC_575);
    }


    // It's a dir


    // point to the end of fullpath
    if (strlen( fullpath ) > PATH_MAX - 1) {
        throw XosException(449, SC_449);
    }
    ptr = fullpath + strlen(fullpath);
    *ptr++ = '/';
    *ptr = 0;

    // Can't read dir. Skip it
    if ((dp = opendir(fullpath)) == NULL) {
            std::string err = XosFileUtil::getErrorString(errno, SC_572 + sp + fullpath);
            LOG_WARNING1("traverseRmDirTree opendir failed: %s", err.c_str());
        throw XosException(572, err);
    }

     errno = 0;
    while ((dirp = readdir(dp)) != NULL) {

        if ((strcmp(dirp->d_name, ".") == 0) ||
            (strcmp(dirp->d_name, "..") == 0)) {
                continue;
        }

        // append name after slash
        if (strlen( fullpath ) + strlen( dirp->d_name) > PATH_MAX - 1) {
            throw XosException(449, SC_449);
        }
        strcpy(ptr, dirp->d_name);

        // Found non-dir file
        // An excetopn will be thrown if something is wrong
        traverseRmDirTree(fullpath);

          // reset errno for the next readdir.
          errno = 0;
    }

     if (errno != 0) {
             LOG_WARNING2("traverseRmDirTree readdir returns errno for %s because %s", 
                    fullpath, XosFileUtil::getReaddirErrorString(errno).c_str());
    }

    // erase everything from slash onwards
    ptr[-1] = 0;


    if (closedir(dp) < 0) {
          std::string err = XosFileUtil::getErrorString(errno, SC_574 + sp + fullpath);
        LOG_SEVERE1("traverseRmDirTree closedir failed: %s\n", err.c_str());
    }

    if (rmdir(fullpath) != 0) {
            std::string err = XosFileUtil::getErrorString(errno, SC_574 + sp + fullpath);
            LOG_SEVERE1("traverseRmDirTree rmdir failed: %s\n", err.c_str());
        throw XosException(574, err);
    }



}


/*************************************************
 *
 * traverseCopyDirTree
 *
 *************************************************/
int ImpFileAccess::traverseCopyDirTree(char* fullpath, char* newpath)
    throw (XosException)
{

    struct stat statbuf;
    struct dirent * dirp;
    DIR * dp;
    int ret = 0;
    char *ptr;
    char *newptr;

//    LOG_FINE4("copying old %s to %s depth = %d, maxDepth = %d\n", fullpath, newpath, depth, maxDepth);


    // Ignore the dir if we can get the stat
    if (lstat(fullpath, &statbuf) < 0) {
        if (depth == 0) {
                  std::string err = XosFileUtil::getErrorString(errno, SC_558 + sp + fullpath);
                 LOG_WARNING1("traverseCopyDirTree lstat failed: %s", err.c_str());
            throw XosException(558, SC_558);
          }
        return ret;
    }


    // For symlink, get the stat of the real file
    if (S_ISLNK(statbuf.st_mode)) {

        // ignore the symlink
        if (!isFollowSymlink)
            return ret;

        // Ignore the dir if we can get the stat
        if (stat(fullpath, &statbuf) < 0) {
            if (depth == 0) {
                       std::string err = XosFileUtil::getErrorString(errno, SC_558 + sp + fullpath);
                      LOG_WARNING1("traverseCopyDirTree stat failed: %s", err.c_str());
                throw XosException(558, SC_558);
                }
            return ret;
        }
    }


    if (!S_ISDIR(statbuf.st_mode)) {
        if (depth == 0) {
                 LOG_WARNING1("traverseCopyDirTree mkdir failed: %s is not a valid directory", fullpath);
            throw XosException(450, SC_450);
            }

        // Could throw an exception
        copyFile(fullpath, newpath);
        return ret;
    }

    // It's a dir

    if (depth >= maxDepth)
        return ret;

    if (mkdir(newpath, statbuf.st_mode) != 0) {
          std::string err = XosFileUtil::getErrorString(errno, SC_573 + sp + newpath);
         LOG_WARNING1("traverseCopyDirTree mkdir failed: %s", err.c_str());
       throw XosException(573, err);
     }


    // point to the end of fullpath
    if (strlen( fullpath ) > PATH_MAX - 1) {
        throw XosException(449, SC_449);
    }
    ptr = fullpath + strlen(fullpath);
    *ptr++ = '/';
    *ptr = 0;

    // new dir
    if (strlen( newpath ) > PATH_MAX - 1) {
        throw XosException(449, SC_449);
    }
    newptr = newpath + strlen(newpath);
    *newptr++ = '/';
    *newptr = 0;


    // Can't read dir. Skip it
    if ((dp = opendir(fullpath)) == NULL) {
        if (depth == 0) {
                std::string err = XosFileUtil::getErrorString(errno, SC_572 + sp + fullpath);
                LOG_WARNING1("traverseCopyDirTree opendir failed: %s", err.c_str());
            throw XosException(572, err);
          }

        return ret;
    }


    ++depth;


    while ((dirp = readdir(dp)) != NULL) {

        if ((strcmp(dirp->d_name, ".") == 0) ||
            (strcmp(dirp->d_name, "..") == 0)) {
                continue;
        }

        // append name after slash
        if (strlen( fullpath ) + strlen( dirp->d_name ) > PATH_MAX - 1) {
            throw XosException(449, SC_449);
        }
        strcpy(ptr, dirp->d_name);

        // New dir: append name after slash
        if (strlen( newpath ) + strlen( dirp->d_name ) > PATH_MAX - 1) {
            throw XosException(449, SC_449);
        }
        strcpy(newptr, dirp->d_name);


        traverseCopyDirTree(fullpath, newpath);


    }

    // erase everything from slash onwards
    ptr[-1] = 0;
    newptr[-1] = 0;

    if (closedir(dp) < 0) {
            std::string err = XosFileUtil::getErrorString(errno, SC_583 + sp + std::string(fullpath));
            LOG_WARNING1("traverseCopyDirTree closedir failed: %s", err.c_str());
        throw XosException(583, err);
    }


    --depth;

    return ret;

}

/*************************************************
 *
 * getFileType
 *
 *************************************************/
std::string ImpFileAccess::getFileType(mode_t mode)
{

    if (S_ISREG(mode))
        return "regular";

    if (S_ISDIR(mode))
        return "directory";

    if (S_ISCHR(mode))
        return "character special";

    if (S_ISBLK(mode))
        return "block special";

    if (S_ISFIFO(mode))
        return "fifo";

    if (S_ISLNK(mode))
        return "symbolic link";

    if (S_ISSOCK(mode))
        return "socket";

    return "unknown";
}

/*************************************************
 *
 * getFilePermissions
 *
 *************************************************/
std::string ImpFileAccess::getFilePermissions(mode_t mode)
{
    std::string ret("");
    std::string dash("-");

    if (S_ISREG(mode))
        ret += dash;
    else if (S_ISDIR(mode))
        ret += "d";
    else if (S_ISCHR(mode))
        ret += "c";
    else if (S_ISBLK(mode))
        ret += "b";
    else if (S_ISFIFO(mode))
        ret += "f";
    else if (S_ISLNK(mode))
        ret += "l";
    else if (S_ISSOCK(mode))
        ret += "s";


    // USER
    if (mode & S_IRUSR)
        ret += "r";
    else
        ret += dash;

    if (mode & S_IWUSR)
        ret += "w";
    else
        ret += dash;

    if (mode & S_IXUSR)
        ret += "x";
    else
        ret += dash;

    // GROUP
    if (mode & S_IRGRP)
        ret += "r";
    else
        ret += dash;

    if (mode & S_IWGRP)
        ret += "w";
    else
        ret += dash;

    if (mode & S_IXGRP)
        ret += "x";
    else
        ret += dash;

    // OTHER
    if (mode & S_IROTH)
        ret += "r";
    else
        ret += dash;

    if (mode & S_IWOTH)
        ret += "w";
    else
        ret += dash;

    if (mode & S_IXOTH)
        ret += "x";
    else
        ret += dash;


    return ret;
}

/*************************************************
 *
 * getFilePermissions
 *
 *************************************************/
mode_t ImpFileAccess::getFilePermissions(const std::string& modeStr, mode_t def)
{

    if (modeStr.size() != 10)
        return def;

    mode_t mode = 0;


    // skip the first char


    // USER
    if (modeStr[1] == 'r')
        mode |= S_IRUSR;

    if (modeStr[2] == 'w')
        mode |= S_IWUSR;

    if (modeStr[3] == 'x')
        mode |= S_IXUSR;



    // GROUP
    if (modeStr[4] == 'r')
        mode |= S_IRGRP;

    if (modeStr[5] == 'w')
        mode |= S_IWGRP;

    if (modeStr[6] == 'x')
        mode |= S_IXGRP;



    // OTHER
    if (modeStr[7] == 'r')
        mode |= S_IROTH;

    if (modeStr[8] == 'w')
        mode |= S_IWOTH;

    if (modeStr[9] == 'x')
        mode |= S_IXOTH;


    return mode;
}


/*************************************************
 *
 * Utility func to copy a file
 * file handles may be not closed if error happens.
 * it is fine as long as each call is new process
 *
 *************************************************/
void ImpFileAccess::copyFile(const char* oldfile, const char* newfile)
    throw (XosException)
{
    if (!oldfile || !newfile)
        return;

//    LOG_FINE2("in copyFile old = %s, new = %s\n", oldfile, newfile);
    XosAutoBuffer auto_buffer(HUNK_MAX);
    char* localBuffer = auto_buffer.getBuffer( );
    if (localBuffer == NULL) {
        std::string err = XosFileUtil::getErrorString(errno, SC_580);
        LOG_WARNING3("copyFile from %s to %s failed no memory: %s", 
        oldfile, newfile, err.c_str());
        throw XosException(580, err);
    }

    struct stat oldfileStat;
    if (stat(oldfile, &oldfileStat) != 0) {
        LOG_WARNING1( "stat failed errno=%s",
                            XosFileUtil::getStatErrorString(errno).c_str());
        throw XosException(558, SC_558);
    }
    int left = oldfileStat.st_size;
    int hunk = (left < HUNK_MAX) ? left : HUNK_MAX;;

    int oldfileId, newfileId;

    // open old file for reading
    if ((oldfileId = open(oldfile, O_RDONLY)) == -1) {
        std::string err = XosFileUtil::getErrorString(errno, SC_555 + sp + std::string(oldfile));
            LOG_WARNING1("copyFile open failed (1): %s", err.c_str());
        throw XosException(555, err);
    }

    // open new file for writing
    if ((newfileId = open(newfile, O_WRONLY | O_CREAT | O_TRUNC , S_IRUSR | S_IWUSR)) == -1) {

        std::string err = XosFileUtil::getErrorString(errno, SC_561 + sp + std::string(newfile));
        LOG_WARNING1("copyFile open failed (2): %s", err.c_str());
        throw XosException(561, err);
     }


    // Read oldfile in chunk and write it out to newfile
    while (left > 0) {

        if (read(oldfileId, localBuffer, hunk) != hunk) {
            std::string err = XosFileUtil::getErrorString(errno, SC_579 + sp + std::string(oldfile));
            LOG_WARNING1("copyFile read failed: %s", err.c_str());
            throw XosException(579, err);
        }

        if (write(newfileId, localBuffer, hunk) != hunk) {
             std::string err = XosFileUtil::getErrorString(errno, SC_562 + sp + std::string(newfile));
            LOG_WARNING1("copyFile write failed: %s", err.c_str());
            throw XosException(562, err);
        }


        left -= hunk;

        if (left < hunk)
            hunk = left;

    }

    if (close(oldfileId) != 0) {
        std::string err = SC_582 + sp + std::string(oldfile) + sp + XosFileUtil::getCloseErrorString(errno);
        LOG_WARNING1("copyFile1 close failed: %s", err.c_str());
        throw XosException(582, err);
    }

    if (close(newfileId) != 0) {
        std::string err = SC_582 + sp + std::string(newfile) + sp + XosFileUtil::getCloseErrorString(errno);
        LOG_WARNING1("copyFile2 close failed: %s", err.c_str());
        throw XosException(582, err);
    } 


    // chmod the new file
    if (chmod(newfile, oldfileStat.st_mode) != 0) {
            std::string err = SC_563 + sp + std::string(newfile) + sp + XosFileUtil::getChmodErrorString(errno);
            LOG_WARNING1("copyFile chmod failed: %s", err.c_str());
        throw XosException(563, err);
     }

}

/*************************************************
 *
 * doWritableDirectory
 # modified from doCreateDirectory
 *
 *************************************************/
void ImpFileAccess::doWritableDirectory()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("writableDirectory missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    std::string impFilePath;
    if (!request->getParamOrHeader(IMP_DIRECTORY, impFilePath)) {
            LOG_WARNING1("writableDirectory missing %s parameter", IMP_DIRECTORY);
        throw XosException(440, SC_440);
    }
        
    impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);

    // File permissions canbe in one of the two formats:
    // octal number such as 0640
    // or a 10-character string beginning with d, such as drwx--x--x
    std::string impFileMode;
    mode_t fileMode = getParentPermissions( impFilePath );
    if (request->getParamOrHeader(IMP_FILEMODE, impFileMode)) {
        if (impFileMode[0] == '0') {
            sscanf(impFileMode.c_str(), "%4o", &fileMode);
        } else if ((impFileMode.size() == 10) &&
                (impFileMode[0] == 'd')) {
            fileMode = getFilePermissions(impFileMode, fileMode);
        } else {
                LOG_WARNING2("createDirectory invalid %s parameter: %s", IMP_FILEMODE, impFileMode.c_str());
            throw XosException(453, SC_453);
        }
    }

    bool dirExist = createOrCheckDirectoryWritable( impFilePath, fileMode );

    HttpResponse* response = stream->getResponse();
    std::string body(response->getStatusPhrase());

    std::string separator("=");
    std::string endofline("\n");

    long counter = 1;
    if (dirExist) {
        std::string prefix;
        std::string ext = "";
        if (request->getParamOrHeader(IMP_FILEFILTER_PREFIX, prefix)) {
            request->getParamOrHeader(IMP_FILEFILTER_EXTENSION, ext);
            counter = getNextFileCounter( impFilePath, prefix, ext );
        }
    }

    if (dirExist) {
        response->setHeader(IMP_FILEEXISTS, IMP_TRUE);
        body += endofline + IMP_FILEEXISTS + separator;
        body += IMP_TRUE;
    }

    std::string val = XosStringUtil::fromLongInt(counter);
    response->setHeader(IMP_FILECOUNTER, val);
    body += endofline + IMP_FILECOUNTER + separator;
    body += val;

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    
    stream->finishWriteResponse();

}

mode_t ImpFileAccess::getParentPermissions( const std::string& path ) {
    std::vector<std::string> paths;
    XosStringUtil::tokenize(path, "/", paths);

    std::string curPath("");
    std::string slash("/");
    std::vector<std::string>::iterator i = paths.begin();
    size_t count = 0;
    struct stat fs;

    mode_t result = 0640;
    for (; i != paths.end(); ++i) {
        ++count;
        curPath += slash + *i;
        //LOG_FINE1("checking path %s\n", curPath.c_str());
        if (stat( curPath.c_str( ), &fs )) {
            break;
        } else {
            if (count != paths.size()) {
                result = fs.st_mode;
            }
        }
    }
    //remove x bits
    return (result & 0666);
}
bool ImpFileAccess::createOrCheckDirectoryWritable( const std::string& dir,
mode_t mode ) throw(XosException) {
    bool dirExist = false;

    std::vector<std::string> paths;
    XosStringUtil::tokenize(dir, "/", paths);

    std::string curPath("");
    std::string slash("/");
    std::vector<std::string>::iterator i = paths.begin();
    size_t count = 0;

    //owner should have all rwx for new directory
    //otherwise we cannot make sure the last directory is writable
    mode |= 0700;

    //add x if any other bits are on
    if (mode & 060) {
        mode |= 010;
    }
    if (mode & 06) {
        mode |= 01;
    }

    for (; i != paths.end(); ++i) {
        ++count;
        if ((*i == ".") || (*i == "..")) {
            //should not be here, already checked before
            throw XosException(440, "bad path contains . or ..: " + dir );
        }
        curPath += slash + *i;
        //LOG_FINE1("checking path %s\n", curPath.c_str());
        // Create it if it does not exist
        if (access(curPath.c_str(), F_OK) < 0) {
            // Make the dir
            //LOG_FINE1("creating dir %s\n", curPath.c_str());
            if (mkdir(curPath.c_str(), mode) != 0) {
                if (errno != EEXIST) {
                    std::string err = 
                    XosFileUtil::getErrorString(errno, SC_573 + sp + curPath);
                    LOG_WARNING1("createOrCheckDirectoryWritable mkdir %s",
                    err.c_str());
                    throw XosException(573, err);
                } else {
                    std::string err = "maybe a dangling symbolic link or NFS error: ";
                    err += curPath;
                    LOG_WARNING1("path not exist but exist when mkdir %s", err.c_str( ));
                    throw XosException(573, err);
                }
            }
            if (chmod( curPath.c_str( ), mode )) {
                std::string err = 
                XosFileUtil::getErrorString(errno, SC_573 + sp + curPath);
                LOG_WARNING1("createOrCheckDirectoryWritable chmod %s",
                err.c_str());
                //warning is enough
                //throw XosException(573, err);
            }
        } else {
            if (count == paths.size()) {
                dirExist = true;
                if (access( curPath.c_str( ), X_OK | W_OK )) {
                    LOG_WARNING1("createOrCheckDirectoryWritable: %s not",
                    curPath.c_str());
                    throw XosException(573, curPath + " directory not writable");
                 }
            }
        }
    }
    return dirExist;
}
long ImpFileAccess::getNextFileCounter( const std::string& dir,
const std::string& prefix, const std::string& ext ) {
    DIR* dp = opendir( dir.c_str( ) );
    if (dp == NULL) {
        return 1;
    }

    long counter = 0;
    size_t le = ext.size( );
    struct dirent * dirp;

    while ((dirp = readdir( dp )) != NULL) {
        //if need fancy stuff, use fnmatch
        if (strncmp( dirp->d_name, prefix.c_str( ), prefix.size( ) )) {
            continue;
        }
        size_t lf = strlen( dirp->d_name );
        if (lf <= le) {
            continue;
        }
        if (le > 0) {
            lf -= le + 1;
            if (dirp->d_name[lf] != '.') {
                continue;
            }
            if (strcmp( dirp->d_name + lf + 1, ext.c_str( ) )) {
                continue;
            }
        }
        //OK match, get the counter
        //LOG_INFO1( "find counter: %s", dirp->d_name );
        size_t iD  = lf; //index of first digit

        while (iD  > 0 && isdigit( dirp->d_name[iD - 1] ) ) {
            --iD;
        }
        if (iD < lf ) {
            errno = 0;
            long fCnt = strtol( dirp->d_name + iD, NULL, 10 );
            if (errno) {
                continue;
            }
            //LOG_INFO1( "find counter: cnt %ld", fCnt );
            if (fCnt > counter) {
                counter = fCnt;
            }
        }
    }
    closedir( dp );

    ++counter;
    return counter;
}


//backupFile:
//    It will try to copy or move the file to sub-directory OVERWRITTEN_FILES.
//
//    If the file does no exist, no action.
//    If it cannot create the sub-directory, it will do no action.
//
//    If the file exists but not readable, it will try to move it.
//    If the file is readable and "append" flag is on, it will copy it.
//     
bool ImpFileAccess::backupFile(
const std::string& filePath, mode_t mode, bool copy ) {

    if (copy) {
//        LOG_INFO( "backupFile copy == true" );
    } else {
//        LOG_INFO( "backupFile copy == false" );
    }

    ///////////////////////////////////////////////////////
    //  return if the filst not exists
    ///////////////////////////////////////////////////////
    if (access( filePath.c_str( ), F_OK )) {
        return false;
    }

    ///////////////////////////////////////////////////////
    //  return if cannot create subdirectory
    ///////////////////////////////////////////////////////
    // split path into dir + filename
    size_t slashIndex = filePath.rfind( '/' );
    std::string dir;
    std::string fileName;
    if (slashIndex == std::string::npos) {
        LOG_WARNING1( "backup file %s failed: bad path, no / found", 
        filePath.c_str( ) );
        return false;
    }
    ++slashIndex; //include slash in the dir
    dir = filePath.substr( 0, slashIndex );
    fileName = filePath.substr( slashIndex );
    dir += "OVERWRITTEN_FILES";
    std::string destFN = dir + "/" + fileName;
    try {
        ImpFileAccess::createOrCheckDirectoryWritable( dir, mode);
    } catch (XosException& e) {
        LOG_WARNING1( "backup file %s failed: cannot create writable sub-dir", 
        filePath.c_str( ) );
        return false;
    }

    //////////////////////////////////////////////
    //  backup that file
    //////////////////////////////////////////////
    if (!copy || access( filePath.c_str( ), R_OK )) {
        // move the file to sub-dir
            //LOG_WARNING2( "backup (rename) file %s to %s",
            //filePath.c_str( ),
            //destFN.c_str( ));
        if (rename( filePath.c_str( ), destFN.c_str( ) )) {
            int errCode = errno;
            LOG_WARNING3( "rename file from %s to %s failed: %d",
            filePath.c_str( ), destFN.c_str( ), errCode );
            return false;
        }
    } else {
        // copy the file
        try {
            //LOG_WARNING2( "backup (copy) file %s to %s",
            //filePath.c_str( ),
            //destFN.c_str( ));
            copyFile( filePath.c_str( ), destFN.c_str( ) );
        } catch (XosException& e) {
            LOG_WARNING3( "backup (copy) file %s to %s failed: %s",
            filePath.c_str( ),
            destFN.c_str( ),
            e.getMessage().c_str( ) );
            return false;
        }
    }
    return true;
}
void ImpFileAccess::prepareDestinationFile(
    std::string& filePath,
    mode_t& mode,
    bool& append,
    bool& needBackup,
    bool& backuped,
    const HttpRequest* request,
    const char* tag
) throw(XosException) {

    filePath = "";
    mode = 0750;
    append = false;
    needBackup = false;
    backuped = false;

    if (!request->getParamOrHeader(tag, filePath)) {
          LOG_WARNING1("missing %s parameter", tag);
        throw XosException(446, SC_446);
    }

	prepareDestinationFile(filePath, mode, append, needBackup, backuped, request);
}
void ImpFileAccess::prepareDestinationFile(
    std::string& filePath, // may be modified if relative path
    mode_t& mode,
    bool& append,
    bool& needBackup,
    bool& backuped,
    const HttpRequest* request
) throw(XosException) {

    mode = 0750;
    append = false;
    needBackup = false;
    backuped = false;

    ////////////////////////////////////////////////
    //parse request
    ////////////////////////////////////////////////
    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    filePath = ImpListDirectory::resolveDir(filePath, impUser);
    mode_t dirMode = getParentPermissions( filePath );
    mode = dirMode;
    std::string impFileMode;
    if (request->getParamOrHeader(IMP_FILEMODE, impFileMode)) {
        if (!impFileMode.empty())
            sscanf( impFileMode.c_str(), "%4o", &mode );
    }

    bool backupExist = false;
    std::string tmp = "";
    if (request->getParamOrHeader( IMP_BACKUPEXIST, tmp )) {
        if (tmp == "true" || tmp == "TRUE") {
            backupExist = true;
        }
    }

    //change it to true if you want default to true
    bool createParents = true;
    tmp = "";
    if (request->getParamOrHeader( IMP_CREATEPARENTS, tmp )) {
        if (!createParents) {
            if (tmp == "true" || tmp == "TRUE") {
                createParents = true;
            }
        } else {
            if (tmp == "false" || tmp == "FALSE") {
                createParents = false;
            }
        }
    }

    tmp = "";
    if (request->getParamOrHeader(IMP_APPEND, tmp)) {
		if ((tmp == "true") || (tmp == "TRUE")) {
			append = true;
        } else {
			append = false;
        }
	}

    //check to see if need backup dest file
    if (backupExist && access( filePath.c_str( ), F_OK ) == 0) {
        needBackup = true;
        backuped = backupFile( filePath, mode, append );
    }

    //if need to create parents
    if (createParents && access( filePath.c_str( ), F_OK )) {
        std::string dir = ImpListDirectory::getDirFromPath( filePath );
        createOrCheckDirectoryWritable( dir, mode ); //may throw
    }

    //try remove the file if it exists and not writable
    if (access( filePath.c_str( ), F_OK ) == 0 &&
    access( filePath.c_str( ), W_OK )) {
        //ignore error here. it will fail in open again later
        unlink( filePath.c_str( ) );
    }
}
void ImpFileAccess::prepareDestinationTmpFile(
    std::string& filePath,
    mode_t& mode,
    bool& append,
    const HttpRequest* request
) throw(XosException) {

    mode = 0750;
    append = false;

    ////////////////////////////////////////////////
    //parse request
    ////////////////////////////////////////////////
    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    filePath = ImpListDirectory::resolveDir(filePath, impUser);
    mode_t dirMode = getParentPermissions( filePath );
    mode = dirMode;
    std::string impFileMode;
    if (request->getParamOrHeader(IMP_FILEMODE, impFileMode)) {
        if (!impFileMode.empty())
            sscanf( impFileMode.c_str(), "%4o", &mode );
    }

    //change it to true if you want default to true
    bool createParents = true;
    std::string tmp = "";
    if (request->getParamOrHeader( IMP_CREATEPARENTS, tmp )) {
        if (!createParents) {
            if (tmp == "true" || tmp == "TRUE") {
                createParents = true;
            }
        } else {
            if (tmp == "false" || tmp == "FALSE") {
                createParents = false;
            }
        }
    }

    tmp = "";
    if (request->getParamOrHeader(IMP_APPEND, tmp)) {
		if ((tmp == "true") || (tmp == "TRUE")) {
			append = true;
        } else {
			append = false;
        }
	}

    //if need to create parents
    if (createParents && access( filePath.c_str( ), F_OK )) {
        std::string dir = ImpListDirectory::getDirFromPath( filePath );
        createOrCheckDirectoryWritable( dir, mode ); //may throw
    }
    size_t slashIndex = filePath.rfind( '/' );
    std::string dir;
    std::string fileName;
    if (slashIndex == std::string::npos) {
        LOG_WARNING1( "backup file %s failed: bad path, no / found", 
        filePath.c_str( ) );
        throw XosException(437, SC_437);
    }
    ++slashIndex; //include slash in the dir
    dir = filePath.substr( 0, slashIndex );
    fileName = filePath.substr( slashIndex );

    std::string tmpDest = dir + "_tmp_" + fileName;
    if (append && access( filePath.c_str( ), R_OK ) == 0) {
        copyFile( filePath.c_str( ), tmpDest.c_str( ) );
    }

    //try remove the file if it exists and not writable
    if (access( filePath.c_str( ), F_OK ) == 0 &&
    access( filePath.c_str( ), W_OK )) {
        //ignore error here. it will fail in open again later
        unlink( filePath.c_str( ) );
    }
    //now all OK we switch the filename
    filePath = tmpDest;
}
void ImpFileAccess::backupDestinationFileAtTheEnd(
    const std::string& filePath, // may be modified if relative path
    mode_t mode,
    bool& needBackup,
    bool& backuped,
    const HttpRequest* request
) throw(XosException) {
    needBackup = false;
    backuped = false;

    ////////////////////////////////////////////////
    //parse request
    ////////////////////////////////////////////////
    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser)) {
        LOG_WARNING1("missing %s parameter", IMP_USER);
        throw XosException(432, SC_432);
    }

    bool backupExist = false;
    std::string tmp = "";
    if (request->getParamOrHeader( IMP_BACKUPEXIST, tmp )) {
        if (tmp == "true" || tmp == "TRUE") {
            backupExist = true;
        }
    }

    //check to see if need backup dest file
    if (backupExist && access( filePath.c_str( ), F_OK ) == 0) {
        needBackup = true;
        backuped = backupFile( filePath, mode, false );
    }
}
void ImpFileAccess::writeBackupWarning(
    HttpResponse* response,
    std::string& body,
    const std::string& filePath,
    bool  backuped
) {
    static const std::string separator("=");
    static const std::string endofline("\n");

    std::string msg;

    if (backuped) {
        msg = "movedExistingFile " + filePath + " to OVERWRITTEN_FILES";
    } else {
        msg = "failed to backup existing file " + filePath;
    }

    response->setHeader( IMP_WARNINGMSG, msg );
    body += endofline + IMP_WARNINGMSG + separator + msg;
}
int ImpFileAccess::parseForOldNew(
    const char *line,
    std::string& oldPath,
    std::string& newPath
) {
    const size_t LL_OLD = strlen( IMP_OLDFILEPATH );
    const size_t LL_NEW = strlen( IMP_NEWFILEPATH );

    if (line == NULL || line[0] == '\0') {
        LOG_FINEST( "parseForOldNew: empty line" );
        return 0;
    }
    const char *pOld = strstr( line, IMP_OLDFILEPATH );
    const char *pNew = strstr( line, IMP_NEWFILEPATH );
    if (pOld == NULL || pNew == NULL) {
        LOG_FINEST1( "parseForOldNew: tags not found {%s}", line );
        return 0;
    }
    if (pOld[LL_OLD] != '=' || pNew[LL_NEW] != '=') {
        LOG_FINEST1( "parseForOldNew: = not found {%s}", line );
        return 0;
    }
    const char *pOldStart = pOld + LL_OLD + 1;
    const char *pNewStart = pNew + LL_NEW + 1;
    oldPath = pOldStart;
    newPath = pNewStart;
    if (pNew > pOld) {
        oldPath = oldPath.substr( 0, (pNew - pOldStart) );
    } else {
        newPath = newPath.substr( 0, (pOld - pNewStart) );
    }

    oldPath = XosStringUtil::trim(oldPath);
    newPath = XosStringUtil::trim(newPath);

    return 1;
}
