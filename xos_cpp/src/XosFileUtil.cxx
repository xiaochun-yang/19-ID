/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/

#include "xos.h"
#include "XosException.h"
#include "XosFileUtil.h"
#include "XosStringUtil.h"

#define HUNK_MAX 100000


/***********************************************************
 *
 * Returns an error string from errno
 *
 ***********************************************************/
std::string XosFileUtil::getErrorCode(int err)
{
    std::string str = "";

    switch (err) {

        case 0:
				str = "(errno = 0)";
				break;
#ifndef WIN32
        case ETXTBSY:
				str = "(ETXTBSY)";
				break;
        case EOVERFLOW:
				str = "(EOVERFLOW)";
				break;
		  case ELOOP:
				str = "(ELOOP)";
				break;
#endif
        case E2BIG:
            str = "(E2BIG)";
            break;
        case EACCES:
            str = "(EACCES)";
            break;
        case EAGAIN:
            str = "(EAGAIN)";
            break;
        case EBADF:
            str = "(EBADF)";
            break;
        case EBUSY:
            str = "(EBUSY)";
            break;
        case ECHILD:
            str = "(ECHILD)";
            break;
#ifndef WIN32
        case ECONNRESET:
            str = "(ECONNRESET)";
            break;
#endif
        case EDEADLK:
            str = "(EDEADLK)";
            break;
        case EDOM:
            str = "(EDOM)";
            break;
        case EEXIST:
            str = "(EEXIST)";
            break;
        case EFAULT:
            str = "(EFAULT)";
            break;
        case EFBIG:
            str = "(EFBIG)";
            break;
        case EINTR:
            str = "(EINTR)";
            break;
        case EINVAL:
            str = "(EINVAL)";
            break;
        case EIO:
            str = "(EIO)";
            break;
        case EISDIR:
            str = "(EISDIR)";
            break;
        case EMFILE:
            str = "(EMFILE)";
            break;
        case EMLINK:
            str = "(EMLINK)";
            break;
        case ENAMETOOLONG:
            str = "(ENAMETOOLONG)";
            break;
        case ENFILE:
            str = "(ENFILE)";
            break;
        case ENODEV:
            str = "(ENODEV)";
            break;
        case ENOENT:
            str = "(ENOENT)";
            break;
        case ENOEXEC:
            str = "(ENOEXEC)";
            break;
        case ENOLCK:
            str = "(ENOLCK)";
            break;
        case ENOMEM:
            str = "(ENOMEM)";
            break;
        case ENOSPC:
            str = "(ENOSPC)";
            break;
        case ENOSYS:
            str = "(ENOSYS)";
            break;
        case ENOTDIR:
            str = "(ENOTDIR)";
            break;
        case ENOTEMPTY:
            str = "(ENOTEMPTY)";
            break;
        case ENOTTY:
            str = "(ENOTTY)";
            break;
        case ENXIO:
            str = "(ENXIO)";
            break;
        case EPERM:
            str = "(EPERM)";
            break;
        case EPIPE:
            str = "(EPIPE)";
            break;
        case ERANGE:
            str = "(ERANGE)";
            break;
        case EROFS:
            str = "(EROFS)";
            break;
        case ESPIPE:
            str = "(ESPIPE)";
            break;
        case ESRCH:
            str = "(ESRCH)";
            break;
        case EXDEV:
            str = "(EXDEV)";
            break;

     }

     return str;
}

/***********************************************************
 *
 * Returns an error string from errno
 *
 ***********************************************************/
std::string XosFileUtil::getErrorString(int err)
{
	return getErrorString(err, "");
}

std::string XosFileUtil::getErrorString(int err, const std::string& prefix)
{
    std::string str = "";

    switch (err) {

        case E2BIG:
            str = "(E2BIG) Argument/environment list too big";
            break;
        case EACCES:
            str = "(EACCES) Permission denied";
            break;
        case EAGAIN:
            str = "(EAGAIN) O_NONBLOCK is set for file or not enough resource to create a new process";
            break;
        case EBADF:
            str = "(EBADF) Invalid file descriptor";
            break;
        case EBUSY:
            str = "(EBUSY) The directory is in use";
            break;
        case ECHILD:
            str = "(ECHILD) invalid child process";
            break;
        case EDEADLK:
            str = "(EDEADLK) AN fcntl with function F_SETLKW cause a deadlock";
            break;
        case EDOM:
            str = "(EDOM) Argument out of range";
            break;
        case EEXIST:
            str = "(EEXIST) The named file already exsts";
            break;
        case EFAULT:
            str = "(EFAULT) Invalid address in function arguments";
            break;
        case EFBIG:
            str = "(EFBIG) Attempt to write file that exceeds max file size";
            break;
        case EINTR:
            str = "(EINTR) Function was interrupted by a signal";
            break;
        case EINVAL:
            str = "(EINVAL) Invalid argument";
            break;
        case EIO:
            str = "(EIO) Input or output error";
            break;
        case EISDIR:
            str = "(EISDIR) Attempt to open dir for writing or to rename a file to be a dir";
            break;
        case EMFILE:
            str = "(EMFILE) Too many file descriptors in use by this process";
            break;
        case EMLINK:
            str = "(EMLINK) The number of link would exceed LINK_MAX";
            break;
        case ENAMETOOLONG:
            str = "(ENAMETOOLONG) File name too long";
            break;
#ifndef WIN32
        case ENETDOWN:
            str = "(ENETDOWN) local network interface is down";
            break;
#endif
        case ENFILE:
            str = "(ENFILE) Too many files are currently open in the system";
            break;
#ifndef WIN32
        case ENOBUFS:
            str = "(NOBUFS) Insufficient resource";
            break;
#endif
		case ENODEV:
            str = "(ENODEV) No such device";
            break;
        case ENOENT:
            str = "(ENOENT) A file or dir does not exist";
            break;
        case ENOEXEC:
            str = "(ENOEXEC) Attempt to execute a file that is not in the correct format";
            break;
        case ENOLCK:
            str = "(ENOLCK) No locks available";
            break;
        case ENOMEM:
            str = "(ENOMEM) No memory available";
            break;
        case ENOSPC:
            str = "(ENOSPC) No space left on disk";
            break;
        case ENOSYS:
            str = "(ENOSYS) Function not implemented";
            break;
        case ENOTDIR:
            str = "(ENOTDIR) A component of the pathname was not a dir when a dir was expected";
            break;
        case ENOTEMPTY:
            str = "(ENOTEMPTY) Attemp to delete or rename a non-empty dir";
            break;
        case ENOTTY:
            str = "(ENOTTY) Terminal control func attempted for a file that is not a terminal";
            break;
        case ENXIO:
            str = "(ENXIO) No such device or device not ready";
            break;
        case EPERM:
            str = "(EPERM) Process does not have permissions to perform the requested operation";
            break;
        case EPIPE:
            str = "(EPIPE) Attemp to write to a pipe or FIFIO with no reader";
            break;
        case ERANGE:
            str = "(ERANGE) Result too large";
            break;
        case EROFS:
            str = "(EROFS) read-only file system";
            break;
        case ESPIPE:
            str = "(ESPIPE) an lseek() was issued on a pipe or FIFO";
            break;
        case ESRCH:
            str = "(ESRCH) No Such process";
            break;
        case EXDEV:
            str = "(EXDEV) Attempt to link a file to another file system";
            break;
		  default:
				str = "(errno " + XosStringUtil::fromInt(err) + ")";

     }

     if (!prefix.empty())
			return prefix + str;

	return str;
}



/***********************************************************
 *
 * Translates an errno to a string.
 *
 ***********************************************************/
std::string XosFileUtil::getFopenErrorString(int err)
{
	std::string str = "";
	switch (err) {
		case EACCES:
			str = "(EACCES) Search permission is denied or write permission is denied for the parent directory";
			break;
		case EINTR:
			str = "(EINTR) A signal was caught during fopen()";
			break;
		case EISDIR:
			str = "(EISDIR) The named file is a directory and mode requires write access.";
			break;
		case EMFILE :
			str = "(EMFILE) {OPEN_MAX} file descriptors are currently open in the calling process.";
			break;
		case ENAMETOOLONG:
			str = "(ENAMETOOLONG) File name too long";
			break;
		case ENFILE:
			str = "(ENFILE) The maximum allowable number of files is currently open in the system. ";
			break;
		case ENOENT:
			str = "(ENOENT) A component of filename does not name an existing file or filename is an empty string.";
			break;
		case ENOSPC :
			str = "(ENOSPC) No space left on disk";
			break;
		case ENOTDIR:
			str = "(ENOTDIR) A component of the path prefix is not a directory. ";
			break;
		case ENXIO:
			str = "(ENXIO) The named file is a character special or block special file, and the device associated with this special file does not  exist.";
			break;
		case EROFS:
			str = "(EROFS) The named file resides on a read-only file system and mode requires write access.";
			break;
		case EINVAL:
			str = "(EINVAL) The value of the mode argument is not valid.";
			break;
		case ENOMEM:
			str = "(ENOMEM) Insufficient storage space is available.";
			break;
#ifndef WIN32
		case ELOOP:
			str = "(ELOOP) A loop exists in symbolic links encountered during resolution of the path argument.";
			break;
		case ETXTBSY:
			str = "(ETXTBSY) The file is a pure procedure (shared text) file that is being executed and mode requires write access.";
			break;
		case EOVERFLOW:
			str = "(EOVERFLOW) The named file is a regular file and the size of the file cannot be represented correctly in an object of type off_t.";
			break;
#endif
		default:
			str = getErrorString(err);
	}

	return str;
}

/***********************************************************
 *
 * Translates an errno to a string.
 *
 ***********************************************************/
std::string XosFileUtil::getChmodErrorString(int err)
{
	std::string str = "";
	switch (err) {
		case EPERM:
			str = "(EPERM) The effective UID does not match the owner of the file, and is not zero";
			break;
		case EROFS:
			str = "(EROFS) The named file resides on a read-only file system.";
			break;
		case EFAULT:
			str = "(EFAULT) path points outside your accessible address space.";
			break;
		case ENAMETOOLONG:
			str = "(ENAMETOOLONG) path is too long.";
			break;
		case ENOENT:
			str = "(ENOENT) The file does not exist.";
			break;
		case ENOMEM:
			str = "(ENOMEM) Insufficient kernel memory was available.";
			break;
		case ENOTDIR:
			str = "(ENOTDIR) A component of the path prefix is not a directory.";
			break;
		case EACCES:
			str = "(EACCES) Search permission is denied on a component of the path prefix.";
			break;
#ifndef WIN32
		case ELOOP:
			str = "(ELOOP) Too many symbolic links were encountered in resolving path.";
			break;
#endif
		case EIO:
			str = "(EIO) An I/O error occurred.";
			break;
		case EBADF:
			str = "(EBADF) The file descriptor fildes is not valid.";
			break;
		default:
			str = getErrorString(err);
	}

	return str;
}


/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getAccessErrorString(int err)
{
	switch (err) {
		case EACCES:
			return "(EACCES) The requested access would be denied to the file or search permission is denied to one of the directories in pathname.";
		case ENAMETOOLONG:
			return "(ENAMETOOLONG) pathname is too long";
		case ENOENT:
			return "(ENOENT) A directory component in pathname would have been accessible but does not exist or was a dangling symbolic link.";
		case ENOTDIR:
			return "(ENOTDIR) A component used as a directory in pathname is not, in fact, a directory.";
		case EROFS:
			return "(EROFS) Write permission was requested for a file on a read-only filesystem.";
		case EFAULT:
			return "(EFAULT) pathname points outside your accessible address space.";
		case EINVAL:
			return "(EINVAL) mode was incorrectly specified.";
		case EIO:
			return "(EIO) An I/O error occurred.";
		case ENOMEM:
			return "(ENOMEM) Insufficient kernel memory was available.";
#ifndef WIN32
		case ELOOP:
			return "(ELOOP) Too many symbolic links were encountered in resolving pathname.";
		case ETXTBSY:
			return "(ETXTBSY) Write access was requested to an executable which is being executed.";
#endif
	}

	return getErrorString(err);
}

/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getStatErrorString(int err)
{
	switch (err) {
		case EBADF:
			return "(EBADF) filedes is bad";
		case ENOENT:
			return "(ENOENT) A component of the path file_name does not exist, or the path is an empty string.";
		case ENOTDIR:
			return "(ENOTDIR) A component of the path is not a directory.";
#ifndef WIN32
		case ELOOP:
			return "(ELOOP) Too many symbolic links encountered while traversing the path.";
#endif
		case EFAULT:
			return "(EFAULT) Bad address.";
		case EACCES:
			return "(EACCES) Permission denied.";
		case ENOMEM:
			return "(ENOMEM) Out of memory (i.e. kernel memory).";
		case ENAMETOOLONG:
			return "(ENAMETOOLONG) File name too long.";
	}

	return getErrorString(err);
}

/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getRenameErrorString(int err)
{
	switch (err) {
		case EISDIR:
			return "(EISDIR) newpath is an existing directory, but oldpath is not a directory.";
		case EXDEV:
			return "(EXDEV) oldpath and newpath are not on the same filesystem";
		case EEXIST:
			return "(EEXIST) newpath is a non-empty directory.";
		case ENOTEMPTY:
			return "(ENOTEMPTY) newpath is a non-empty directory.";
		case EBUSY:
			return "(EBUSY)  The rename fails because oldpath or newpath is a directory that is in use by some process.";
		case EINVAL:
			return "(EINVAL) An attempt was made to make a directory a subdirec-tory of itself.";
		case EMLINK:
			return "(EMLINK) oldpath already has the maximum number of links to it.";
		case ENOTDIR:
			return "(ENOTDIR) A  component  used as a directory in oldpath or newpath is not a directory.";
		case EFAULT:
			return "(EFAULT) oldpath or newpath points outside your accessible address space.";
		case EACCES:
			return "(EACCES) Write access to the directory containing oldpath or newpath is not allowed.";
		case EPERM:
			return "(EPERM) The directory containing oldpath of newpath has the sticky bit set.";
		case ENAMETOOLONG:
			return "(ENAMETOOLONG) oldpath or newpath was too long";
		case ENOENT:
			return "(ENOENT) A directory component in oldpath  or  newpath does not exist or is a dangling symbolic link.";
		case ENOMEM:
			return "(ENOMEM) Insufficient kernel memory was available.";
		case EROFS:
			return "(EROFS) The file is on a read-only filesystem.";
#ifndef WIN32
		case ELOOP:
			return "(ELOOP) Too many symbolic links were encountered in resolving oldpath or newpath.";
#endif
		case ENOSPC:
			return "(ENOSPC) The device containing the file has no room for the new directory entry.";
	}

	return getErrorString(err);
}

/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getReaddirErrorString(int err)
{
	switch (err) {
#ifndef WIN32
		case EOVERFLOW:
			return "(EOVERFLOW) One of the values in the structure to be returned cannot be represented correctly.";
#endif
		case EBADF:
			return "(EBADF) The dirp argument does not refer to an open directory stream.";
		case ENOENT:
			return "(ENOENT) The current position of the directory stream is invalid.";
	}

	return getErrorString(err);
}

/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getLstatErrorString(int err)
{
	switch (err) {
		case EACCES:
			return "(EACCES) A component of the path prefix denies search permission.";
		case EIO:
			return "(EIO) An error occurred while reading from the file system.";
		case ENOTDIR:
			return "(ENOTDIR) A component of the path prefix is not a directory.";
		case ENOENT:
			return "(ENOENT) A component of path does not name an existing file or path is an empty string.";
#ifndef WIN32
		case ELOOP:
			return "(ELOOP) A loop exists in symbolic links encountered during resolution of the path argument.";
		case EOVERFLOW:
			return "(EOVERFLOW) The file size cannot be represented in the structure pointed to by buf argument.";
#endif
	}

	return getErrorString(err);
}

/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getReadlinkErrorString(int err)
{
	switch (err) {
		case ENOTDIR:
			return "(ENOTDIR) A component of the path prefix is not a directory.";
		case EINVAL:
			return "(EINVAL) bufsiz is not positive or The named file is not a symbolic link.";
		case ENAMETOOLONG:
			return "(ENAMETOOLONG) A pathname, or a component of a pathname, was too long.";
		case ENOENT:
			return "(ENOENT) The named file does not exist.";
		case EACCES:
			return "(EACCES) Search permission is denied for a component of the path prefix.";
#ifndef WIN32
		case ELOOP:
			return "(ELOOP) Too many symbolic links were encountered in translating the pathname.";
#endif
		case EIO:
			return "(EIO) An I/O error occurred while reading from the file system.";
		case EFAULT:
			return "(EFAULT) buf extends outside the process?s allocated address space.";
		case ENOMEM:
			return "(ENOMEM) Insufficient kernel memory was available.";
	}

	return getErrorString(err);
}


/*************************************************
 *
 * Translates an errno to a string.
 *
 *************************************************/
std::string XosFileUtil::getCloseErrorString(int err)
{
	switch (err) {
		case EBADF:
			return "(EBADF) fd isn?t a valid open file descriptor.";
		case EINTR:
			return "(EINTR) The close() call was interrupted by a signal.";
		case EIO:
			return "(EIO) An I/O error occurred.";
	}

	return getErrorString(err);
}


/*************************************************
 *
 * Utility func to copy a file
 *
 *************************************************/
void XosFileUtil::copyFile(const char* oldfile, const char* newfile)
    throw (XosException)
{
    if (!oldfile || !newfile)
        return;

    xos_log("in copyFile old = %s, new = %s\n", oldfile, newfile);

    struct stat oldfileStat;
    if (stat(oldfile, &oldfileStat) != 0)
        throw XosException(XosFileUtil::getErrorString(errno,
        			"Failed to get stat for file " + std::string(oldfile)));

    int left = oldfileStat.st_size;
    int hunk = (left < HUNK_MAX) ? left : HUNK_MAX;;

    int oldfileId, newfileId;

    // open old file for reading
    if ((oldfileId = open(oldfile, O_RDONLY)) == -1)
        throw XosException(XosFileUtil::getErrorString(errno, 
        				"Failed to open file " + std::string(oldfile)));

    // open new file for writing
    if ((newfileId = open(newfile, O_WRONLY | O_CREAT | O_TRUNC)) == -1)
        throw XosException(XosFileUtil::getErrorString(errno, 
            			"Failed to open file " + std::string(newfile)));

	char* bigbuf = NULL;

    // Allocate memory for it
	if ((bigbuf = (char*)malloc(HUNK_MAX)) == NULL) {
		xos_log("Failed to allocate memory %d\n", HUNK_MAX);
		throw XosException(XosFileUtil::getErrorString(errno,
							"Failed to allocate memory"));
	}
    

    // Read oldfile in chunk and write it out to newfile
    while (left > 0) {

        if (read(oldfileId, bigbuf, hunk) != hunk) {
        	free(bigbuf);
            throw XosException(XosFileUtil::getErrorString(errno, 
            		"Failed to read file " + std::string(oldfile)));
        }

        if (write(newfileId, bigbuf, hunk) != hunk) {
        	free(bigbuf);
            throw XosException(XosFileUtil::getErrorString(errno, 
            		"Failed to write file " + std::string(newfile)));
		}

        left -= hunk;

        if (left < hunk)
            hunk = left;

    }
    
    free(bigbuf);
    bigbuf = NULL;


    if (close(oldfileId) != 0)
        throw XosException(XosFileUtil::getErrorString(errno, 
        			"Failed to close file " + std::string(oldfile)));

    if (close(newfileId) != 0)
        throw XosException(XosFileUtil::getErrorString(errno, 
        			"Failed to close file " + std::string(newfile)));


    // chmod the new file
    if (chmod(newfile, oldfileStat.st_mode) != 0)
        throw XosException(XosFileUtil::getErrorString(errno, 
        			"Failed to chmod file " + std::string(newfile)));


}
