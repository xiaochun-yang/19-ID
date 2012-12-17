#include	<stdio.h>

parse_file_name(s,t,inp)
char    *s,*t;
int     *inp;
  {
        int     i,j,k;

        j = strlen(s);
        for(i = j - 1; i > 0 && s[i] != '_'; i--);
	fprintf(stdout,"j: %d and i: %d after loop\n",j,i);
        *inp = atoi(&s[i + 1]);
        for(j = 0; j < i; j++)
          t[j] = s[j];
        t[i] = '\0';

  }

main(argc,argv)
int	argc;
char	*argv[];
  {
	char	prefix[256];
	int	run;

	if(argc < 2)
	  {
	    fprintf(stderr,"Usage: parse_file_name prefix_run\n");
	    exit(0);
	  }
	parse_file_name(argv[1],prefix,&run);
	fprintf(stdout,"for %s, prefix: %s and run: %d\n",argv[1],prefix,run);
  }
