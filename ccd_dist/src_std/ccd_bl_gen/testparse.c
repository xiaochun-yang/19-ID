#include	<stdio.h>

#define MAXLINES        100
#define MAXSUB          10

extern	int     ccdparse_linec;
extern	char    *ccdparse_linev[MAXLINES];
extern	int     ccdparse_subc[MAXLINES];
extern	char    *ccdparse_subv[MAXLINES][MAXSUB];

main(argc,argv)
int	argc;
char	*argv[];
  {
	char	*teststr = "cmd\nexpose 15.2\nmode normal\nphi 15.\nend_of_det\n";
	int	i,j;

	ccd_parse1(teststr);
	fprintf(stdout,"ccdparse_linec: %d\n",ccdparse_linec);
	fprintf(stdout,"lines are:\n");
	for(i = 0; i < ccdparse_linec; i++)
		fprintf(stdout,"%s\n",ccdparse_linev[i]);
	fprintf(stdout,"Individual strings:\n");
	for(i = 0; i < ccdparse_linec; i++)
	  {
	    fprintf(stdout,"Line %d has %d strings.\n",i,ccdparse_subc[i]);
	    for(j = 0; j < ccdparse_subc[i]; j++)
		fprintf(stdout,"string %d: %s\n",j,ccdparse_subv[i][j]);
	  }
  }
