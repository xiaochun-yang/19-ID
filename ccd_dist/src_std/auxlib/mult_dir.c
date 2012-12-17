#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/dir.h>
#include	<sys/stat.h>
#include	<sys/statfs.h>

/*
 *	Functions to support seemless multiple directory data
 *	collection.
 *
 *	int	setup_mult_dir(orig_dir)
 *	
 *	Rule:
 *
 *	Looking at orig_dir, check each file in this directory to
 *	see if it is a symbolic link.  If so, it is taken to be
 *	the name of a directory where images can be placed during
 *	data collection.  Ordinary links, directories, and files are
 *	ignored.  Return 0 if all is OK, else return -1 if an error.
 *
 *	Note:	The directory so specified, orig_dir, is also a candidate
 *		for data collection images, so that this method is equivalent
 *		with the ordinary data collection sheme if no symbolic
 *		links are present.
 *
 *
 *	int	get_mult_dir(nkbytes,returned_dir)
 *
 *	Check to see if 5 * nkbytes amount of space are present on the current
 *	directory and move to another directory if possible.  If there are
 *	no more directories available with space, return an error, -1, else
 *	return the name of the directory selected in returned_dir (which is
 *	a pointer to space resereved in the CALLER'S routine).  Errors generate
 *	NULL returned strings.
 *
 *	int	get_mult_dir_totblocks()
 *
 *	Returns the number of 1024 byte blocks available over all of the
 *	possible file systems and directories contained in orig_dir.  This
 *	is primarily to be used by adx_ccd_control so it can accurately
 *	report the number of blocks available to the user.
 *
 *	char	*get_mult_dir_estring()
 *
 *	Returns a pointer to a local buffer containing the specific error
 *	string associated with a failure from one of the above, usually so it
 *	can be posted via a GUI warning box.
 *
 */

static	int	mult_dir_init = 0;

#define	MAX_DIRS	10
#define	MAX_NAMESIZE	256

#define	MIN_FREE_MULT	5

static	char	mult_dir_names[MAX_DIRS][MAX_NAMESIZE];
static	int	mult_dir_ndirs = 0;
static	int	mult_dir_cur_dirind = 0;

static	char	mult_dir_es[MAX_NAMESIZE];

int	setup_mult_dir(orig_dir)
char	*orig_dir;
  {
	DIR		*dirp;
	struct direct	*dp;
	struct stat 	buf;
	char		entry_wd[MAX_NAMESIZE];
	int		fdcheck;

	strcpy(mult_dir_es,"");
	mult_dir_ndirs = 0;
	if(NULL == (dirp = opendir(orig_dir)))
	  {
	    sprintf(mult_dir_es,"setup_mult_dir: Cannot open %s with diropen\n",orig_dir);
	    fprintf(stderr,     "setup_mult_dir: Cannot open %s with diropen\n",orig_dir);
	    return(-1);
	  }
	getcwd(entry_wd,MAX_NAMESIZE);
	chdir(orig_dir);
	getcwd(mult_dir_names[mult_dir_ndirs],MAX_NAMESIZE);
	mult_dir_ndirs++;
	chdir(mult_dir_names[0]);
	while(NULL != (dp = readdir(dirp)))
	  {
		if(-1 == lstat(dp->d_name,&buf))
		  {
		    perror("lstat error");
	    	    sprintf(mult_dir_es,"setup_mult_dir: Cannot lstat %s\n",dp->d_name);
	    	    fprintf(stderr,     "setup_mult_dir: Cannot lstat %s\n",dp->d_name);
		    closedir(dirp);
		    chdir(entry_wd);
	    	    return(-1);
		  }
		if(buf.st_mode & S_IFLNK)
		  {
		    if(-1 != stat(dp->d_name,&buf))
		      {
			if(buf.st_mode & S_IFDIR)
			  {
				chdir(dp->d_name);
				if(-1 == (fdcheck = creat("mult_dir_checkfile",0666)))
				  {
				    sprintf(mult_dir_es,"mult_dir: directory %s is not writable\n",dp->d_name);
				    fprintf(stderr,"mult_dir: directory %s is not writable\n",dp->d_name);
				    closedir(dirp);
				    chdir(entry_wd);
				    return(-1);
				  }
				unlink("mult_dir_checkfile");
				getcwd(mult_dir_names[mult_dir_ndirs],MAX_NAMESIZE);
				mult_dir_ndirs++;
				if(mult_dir_ndirs >= MAX_DIRS)
					break;
				chdir(mult_dir_names[0]);
			  }
		      }
		  }
	  }
	mult_dir_init = 1;
	mult_dir_cur_dirind = 0;
	chdir(entry_wd);
	closedir(dirp);
	return(0);
  }

int	get_mult_dir_totblocks()
  {
	int		i,tot_blocks;
	double		x;
	struct	statfs	buf;

	strcpy(mult_dir_es,"");
	if(mult_dir_init != 1)
	  {
	    sprintf(mult_dir_es,"get_mult_dir_totblocks: mult_dir not sucessfully initialized.\n");
	    fprintf(stderr,     "get_mult_dir_totblocks: mult_dir not sucessfully initialized.\n");
	    return(-1);
	  }
	tot_blocks = 0;
	for(i = 0; i < mult_dir_ndirs; i++)
	  {
		if(-1 == statfs(mult_dir_names[i],&buf,sizeof (buf), 0))
		  {
	    	    sprintf(mult_dir_es,"get_mult_dir_totblocks: Cannot statfs %s\n",mult_dir_names[i]);
	    	    fprintf(stderr,     "get_mult_dir_totblocks: Cannot statfs %s\n",mult_dir_names[i]);
	    	    return(-1);
		  }
		x = ((double)buf.f_bsize) / 1024.;
		tot_blocks += (int) (buf.f_bfree * x);
	  }
	return(tot_blocks);
  }

int	get_mult_dir(nkbytes,returned_dir)
int	nkbytes;
char	*returned_dir;
  {
	int		cind,i;
	double		x;
	struct	statfs	buf;

	strcpy(mult_dir_es,"");
	if(mult_dir_init != 1)
	  {
	    sprintf(mult_dir_es,"get_mult_dir: mult_dir not sucessfully initialized.\n");
	    fprintf(stderr,     "get_mult_dir: mult_dir not sucessfully initialized.\n");
	    return(-1);
	  }

	for(i = 0; i < mult_dir_ndirs; i++)
	  {
	    cind = (i + mult_dir_cur_dirind) % mult_dir_ndirs;
	    if(-1 == statfs(mult_dir_names[i],&buf,sizeof (buf), 0))
		{
	    	    sprintf(mult_dir_es,"get_mult_dir: Cannot statfs %s\n",mult_dir_names[i]);
	    	    fprintf(stderr,     "get_mult_dir: Cannot statfs %s\n",mult_dir_names[i]);
	    	    return(-1);
		  }
	    x = ((double)buf.f_bsize) / 1024.;
	    x = buf.f_bfree * x;
	    if(x >= MIN_FREE_MULT * nkbytes)
	      {
		mult_dir_cur_dirind = cind;
		strcpy(returned_dir,mult_dir_names[cind]);
		return(0);
	      }
	  }
	sprintf(mult_dir_es,"get_mult_dir: No space found on various possible directories.\n");
	fprintf(stderr,     "get_mult_dir: No space found on various possible directories.\n");
	return(-1);
  }	

#ifdef MAIN
main(argc,argv)
int	argc;
char	*argv[];
  {
	int	i,tot_blocks;
	char	returned_dir[256];

	if(argc != 2)
	  {
	    fprintf(stderr,"Usage: mult_dir dir_name\n");
	    exit(0);
	  }
	
	if(-1 == setup_mult_dir(argv[1]))
	  {
	    fprintf(stderr,"Error returned setting up %s\n");
	    exit(0);
	  }
	
	fprintf(stdout,"Number of directories found as usable: %d\n",mult_dir_ndirs);

	for(i = 0; i < mult_dir_ndirs; i++)
	  fprintf(stdout,"Entry: %d with actual directory %s\n",i,mult_dir_names[i]);
	tot_blocks = get_mult_dir_totblocks();
	fprintf(stdout,"Total number of 1024 byte blocks avail would be: %d\n",tot_blocks);

	if(-1 != get_mult_dir(10800,returned_dir))
	    fprintf(stdout,"Returned directory: %s\n",returned_dir);

	exit(0);
  }
#endif /* MAIN */
