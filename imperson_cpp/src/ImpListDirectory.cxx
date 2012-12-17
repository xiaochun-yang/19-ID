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
#include "XosException.h"
#include "XosStringUtil.h"
#include "XosFileUtil.h"
#include "XosFileNameWildcard.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "ImpListDirectory.h"
#include "ImpCommandFactory.h"
#include "ImpRunExecutable.h"

#define SORT_NO 0
#define SORT_BY_NAME
#define SORT_BY_DATE

static ImpRegister* dummy = new ImpRegister(IMP_LISTDIRECTORY, &ImpListDirectory::createCommand, true);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpListDirectory::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpListDirectory(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpListDirectory::ImpListDirectory()
    : ImpCommand(IMP_LISTDIRECTORY, NULL), wildcard(0)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpListDirectory::ImpListDirectory(HttpServer* s)
    : ImpCommand(IMP_LISTDIRECTORY, s), wildcard(0)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpListDirectory::ImpListDirectory(const std::string& n, HttpServer* s)
    : ImpCommand(n, s), wildcard(0)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpListDirectory::~ImpListDirectory()
{
    if (!wildcard)
        delete wildcard;

    wildcard = 0;
}


/*************************************************
 *
 * execute
 *
 *************************************************/
void ImpListDirectory::execute()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();
    
    response->setContentType("text/plain; charset=ISO-8859-1");

/////////////////////////////////////////////////////

    std::string impUser;
    if (!request->getParamOrHeader(IMP_USER, impUser))
        throw XosException(432, SC_432);

    // Get absolute or relative path
    if (!request->getParamOrHeader(IMP_DIRECTORY, impDirectory))
        throw XosException(440, SC_440);


    // Should we show result as subsolute path or full path
    std::string impAbsolutePaths;
    isAbsolutePath = false;
    if (request->getParamOrHeader(IMP_SHOWABSOLUTEPATH, impAbsolutePaths)) {
        if (XosStringUtil::toLower(impAbsolutePaths) == IMP_TRUE)
            isAbsolutePath = true;
    }



    // Max dir depth we want to list
    std::string impMaxDepth;
    maxDepth = 1;
    if (request->getParamOrHeader(IMP_MAXDEPTH, impMaxDepth)) {
        sscanf(impMaxDepth.c_str(), "%d", &maxDepth);
        if (maxDepth <= 0)
            impMaxDepth = "1";
    } else {
        impMaxDepth = "1";
    }

    std::string impFileFilter;
    if (request->getParamOrHeader(IMP_FILEFILTER, impFileFilter)) {
        // Create wildcard
        if (!impFileFilter.empty()) {

            wildcard = XosFileNameWildcard::createFileNameWildcard(impFileFilter.c_str());

            if (!wildcard)
                throw XosException(443, SC_443);

        }
    }


    std::string impFollowSymlink;
    isFollowSymlink = false;
    if (request->getParamOrHeader(IMP_FOLLOWSYMLINK, impFollowSymlink)) {
        if (XosStringUtil::toLower(impFollowSymlink) == IMP_TRUE)
            isFollowSymlink = true;
    }

    std::string impShowDetails;
    isShowDetails = true;
    if (request->getParamOrHeader(IMP_SHOWDETAILS, impShowDetails)) {
        if (XosStringUtil::toLower(impShowDetails) == IMP_FALSE)
            isShowDetails = false;
    }
    
    std::string impSortType;
    sortType = 0;
    if (request->getParamOrHeader(IMP_SORTTYPE, impSortType)) {
	sortType = XosStringUtil::toInt(impSortType, 0);
     }
    
    // sesolve ~
   	impDirectory = resolveDir(impDirectory, impUser);


    isListFile = true;
    isListDir = true;
    std::string impFileType;
    if (request->getParamOrHeader(IMP_FILETYPE, impFileType)) {
        if (impFileType == "file") {
            isListFile = true;
            isListDir = false;
        } else if (impFileType == "directory") {
            isListFile = false;
            isListDir = true;
        } else if (impFileType == "all") {
            isListFile = true;
            isListDir = true;
        } else {
            throw XosException(442, SC_442);
        }
    }


    readDir();


}


/*************************************************
 *
 * resolveDir
 *
 *************************************************/
std::string ImpListDirectory::resolveDir(std::string dir, const std::string& impUser) throw (XosException)
{ 
    if (dir.size( ) == 0) {
        throw XosException(440, "zero length directory path" );
    }
    if (dir[0] != '/' && dir[0] != '~') {
        throw XosException(440, "must be absolute path " + dir );
    }

    //all these are to avoid call to token
    if (dir.find( ".." ) != std::string::npos) {
        throw XosException(440, "bad path contains ..: " + dir );
    }
    if (dir.find( "./" ) != std::string::npos) {
        throw XosException(440, "bad path contains ./: " + dir );
    }
    if (dir[dir.size( ) - 1] == '.') {
        throw XosException(440, "bad path ends with .: " + dir );
    }

    if (dir[0] == '/') {
        return dir;
    }

    if (dir[0] != '~') {
        throw XosException(440, "bad path format: " + dir );
    }

    std::string userName = impUser;
    std::string result;
    std::string remain = "";
    size_t slashIndex = dir.find( '/' );
    if (slashIndex == std::string::npos) {
        slashIndex = dir.size( );
    } else {
        remain = dir.substr( slashIndex );
    }

    if (slashIndex > 1) {
        userName = dir.substr( 1, slashIndex - 1 );
    }

    //change to getpwnam_r in the future if changes to multi-thread
    struct passwd *passwdEntryPtr;
    // look up password file entry for user
    if (passwdEntryPtr = getpwnam( userName.c_str( ) )) {
        result = passwdEntryPtr->pw_dir;
    } else {
        LOG_WARNING1( "resolveDir getpwname failed for user %s",
        userName.c_str( ) );
        result = "/home/" + userName;
    }

    result += remain;

	return result;
}
std::string ImpListDirectory::getDirFromPath( const std::string& path ) throw (XosException)
{ 
    size_t slashIndex = path.rfind( '/' );
    std::string dir;
    if (slashIndex == std::string::npos) {
        throw XosException(440, "bad path format: " + path );
    }
    ++slashIndex; //include slash in the dir
    dir = path.substr( 0, slashIndex );

    return dir;
}
/*************************************************
 *
 * readDir
 *
 *************************************************/
void ImpListDirectory::readDir()
     throw(XosException)
{

    char fullpath[PATH_MAX+1];
    depth = 0;

    strncpy(fullpath, impDirectory.c_str(), PATH_MAX);

    
    // Make sure we can read it.
    DIR * dp;
    if ((dp = opendir(fullpath)) == NULL) {
        throw XosException(572,
            XosFileUtil::getErrorString(errno, SC_572 + std::string(" ") + fullpath));
    }
    if (closedir(dp) < 0) {
        LOG_WARNING1("Failed to close dir %s\n", fullpath);
    }
    
    struct stat statbuf;
    if (lstat(fullpath, &statbuf) < 0) {
        throw XosException(558,
            XosFileUtil::getErrorString(errno, SC_558 + std::string(" ") + fullpath));
    }
    
    
    char tmp[2000];
    getFileInfo(tmp, fullpath, statbuf);
    

    if (!S_ISDIR(statbuf.st_mode) && !S_ISLNK(statbuf.st_mode)) {
        throw XosException(444, SC_444 + std::string(" ") + fullpath);
    }

    traverseDirTree(fullpath);
    
    // Write the sorted list
    if (sortType != SORT_NO) {
	std::set<std::string>::iterator i = dirs.begin();
	std::string item;
    	for (; i != dirs.end(); ++i) {
	   item = *i;
	   stream->writeResponseBody(item.c_str(), item.size());
    	}	    
    }
    
    dirs.clear();

}

/*************************************************
 *
 * readDir
 *
 *************************************************/
int ImpListDirectory::traverseDirTree(char* fullpath)
{

    struct stat statbuf;
    struct dirent * dirp;
    DIR * dp;
    int ret = 0;
    char *ptr;


    // It's a dir


    if (depth >= maxDepth)
        return 1;

    // point to the end of fullpath
    if (strlen( fullpath ) > PATH_MAX - 1) {
        throw XosException(449, SC_449);
    }
    ptr = fullpath + strlen(fullpath);
    *ptr++ = '/';
    *ptr = 0;

    // Can't read dir. Skip it
    if ((dp = opendir(fullpath)) == NULL)
        return 572;


    ++depth;


    bool shouldPrint = false;
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


        ////////////////////////////////////////////////////
        //
        ////////////////////////////////////////////////////


        if (lstat(fullpath, &statbuf) < 0)
            continue;

        mode_t mode = statbuf.st_mode;

        if (S_ISLNK(mode)) {
            struct stat realStat;
            if (stat(fullpath, &realStat) < 0)
                mode = realStat.st_mode;
        }

        // Not a dir
        shouldPrint = false;
        if (S_ISDIR(mode)) {
            if (isListDir)
                shouldPrint = true;
        } else {
            if (!isListFile)
                continue;
            // match the wildcard
            if (wildcard && !wildcard->match(dirp->d_name)) {
                continue;
            }


            shouldPrint = true;
        }

        if (shouldPrint) {
            if (isShowDetails) { // show filename and file status
                getFileInfo(displayedPath, fullpath, statbuf);
		if (sortType == SORT_NO)
                	stream->writeResponseBody(displayedPath, strlen(displayedPath));
		else
			dirs.insert(std::set<std::string>::value_type(displayedPath));
            } else { // show filename only
                if (isAbsolutePath) { // show full path
                    sprintf(displayedPath, "%s%s", fullpath, CRLF);               
		    if (sortType == SORT_NO)
                	stream->writeResponseBody(displayedPath, strlen(displayedPath));
		    else
			dirs.insert(std::set<std::string>::value_type(displayedPath));
                } else { // show relative path
                    sprintf(displayedPath, ".%s%s", &fullpath[impDirectory.size()], CRLF);
 		    if (sortType == SORT_NO)
                   	stream->writeResponseBody(displayedPath, strlen(displayedPath));
 		    else
			dirs.insert(std::set<std::string>::value_type(displayedPath));
                }
            }
        }

        // Don't follow the symlink
        if (!isFollowSymlink && S_ISLNK(statbuf.st_mode)) {
            continue;
        }


        ////////////////////////////////////////////////////
        //
        ////////////////////////////////////////////////////



        // Found non-dir file
        // Ignore the one we can't reach
        traverseDirTree(fullpath);
    }

    // erase everything from slash onwards
    ptr[-1] = 0;

    if (closedir(dp) < 0) {
        LOG_WARNING2("Failed to close dir %s because %s\n", fullpath, XosFileUtil::getErrorString(errno).c_str( ));
    }


    --depth;

    return ret;

}


/*************************************************
 *
 * getFileInfo
 *
 *************************************************/
void ImpListDirectory::getFileInfo(char* ret,
                                    const char* filename,
                                    struct stat& statbuf)
{


    if (isAbsolutePath) {

        sprintf(ret, "%s,%s,%s,%lu,%ld,%ld,%u,%u,%u,%ld,%ld,%ld,%ld,%ld,%ld",
                filename,
                getFileType(statbuf.st_mode).c_str(),
                getFilePermissions(statbuf.st_mode).c_str(),
                (long unsigned int)statbuf.st_ino,
                (long int)statbuf.st_dev,
                (long int)statbuf.st_rdev,
                statbuf.st_nlink,
                statbuf.st_uid,
                statbuf.st_gid,
                (long int)statbuf.st_size,
                (long int)statbuf.st_atime,
                (long int)statbuf.st_mtime,
                (long int)statbuf.st_ctime,
                (long int)statbuf.st_blksize,
                (long int)statbuf.st_blocks);

    } else {

        sprintf(ret, ".%s,%s,%s,%lu,%ld,%ld,%u,%u,%u,%ld,%ld,%ld,%ld,%ld,%ld",
                &filename[impDirectory.size()],
                getFileType(statbuf.st_mode).c_str(),
                getFilePermissions(statbuf.st_mode).c_str(),
                (long unsigned int)statbuf.st_ino,
                (long int)statbuf.st_dev,
                (long int)statbuf.st_rdev,
                statbuf.st_nlink,
                statbuf.st_uid,
                statbuf.st_gid,
                (long int)statbuf.st_size,
                (long int)statbuf.st_atime,
                (long int)statbuf.st_mtime,
                (long int)statbuf.st_ctime,
                (long int)statbuf.st_blksize,
                (long int)statbuf.st_blocks);

    }

    if (S_ISLNK(statbuf.st_mode)) {
        char buf[PATH_MAX+1];
        int num;
        // Write out the actual file name
        if ((num=readlink(filename, &buf[1], PATH_MAX)) > 0) {
            buf[0] = ',';
            buf[num+1] = '\0';
            strcat(ret, buf);
        }

    }

    strcat(ret, CRLF);

}

/*************************************************
 *
 * getFileType
 *
 *************************************************/
std::string ImpListDirectory::getFileType(mode_t mode)
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
std::string ImpListDirectory::getFilePermissions(mode_t mode)
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


