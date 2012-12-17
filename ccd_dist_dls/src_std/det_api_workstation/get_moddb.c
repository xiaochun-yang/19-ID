#include	"q_moddef.h"
#include	<stdlib.h>
#include	<stdio.h>
#include	<string.h>
#ifdef	WINNT
#include	<winsock2.h>
#endif /* WINNT */
#ifdef unix
#include	<unistd.h>
#endif /* unix */

#define	MAX_CONTROLLERS		9

extern	FILE	*fpout;
extern	FILE	*fperr;

/*
 *	Detector database
 *

#
#	Description of detector system/computers/modules etc.
#
#	For chip, EEV should be			chip 1152 1152 1152.
#			  Thomson should be		chip 2112 2076 2048.
#
chip raw_colsize raw_rowsize imaged_size
host machine1 2
host machine2 2
module 0 master	 2929 W	180 machine1 port1 dport1 sport1
module 1 slave   2928 X	270 machine1 port1 dport1 sport1
module ? virtual 0000 Y   0 machine2 port2 dport1 sport1
module ? slave   2927 Z  90 machine2 port2 dport2 sport2
#
# ? for find board/choose board(virtual), number for absolute assignment.
#
#	Using "localhost" for any machine name eliminates any host lookup
#	for the entry.
#
*/

static	struct q_moddef qs[MAX_CONTROLLERS];

static	char			q_hostname[MAX_CONTROLLERS][100];
static	int				q_nboards[MAX_CONTROLLERS];
static	int				q_nhosts;

extern	int				q_ncols_raw;
extern	int				q_nrows_raw;
extern	int				q_image_size;

static  char			*dg_dir[] = {
									  "chip",
									  "host",
									  "module",
									  NULL
									};

int	checkwhite(char c)
{
	if(c == '\n' || c == ' ' || c == '\t' || c == '\r' || c == '\b')
		return(1);
	return(0);
}

int	get_moddb(struct q_moddef *qm, int max_c, char *fname, int ignore_host)
{
	FILE			*fp;
	char			line[132];
	char			lookhost[256];
	int				i,j,foundi,n,nf,nitems,ntry,nfinal;
	int				adc,ser;
	char			g0[100],g1[100],g2[100],g3[100],g4[100],g5[100],g6[100],
					g7[100],g8[100],g9[100];
	int				f2,f0;
	struct q_moddef qt[MAX_CONTROLLERS];
	int				test_communications(int	bn, int *padc, int *pser);
	int				reset_controller(int bn);


	gethostname(lookhost,sizeof lookhost);

	fprintf(fpout,"\n                  localhost: %s\n",lookhost);
	q_nhosts = 0;
	q_ncols_raw = -1;
	q_nrows_raw = -1;
	q_image_size = -1;

	if(NULL == (fp = fopen(fname,"r")))
	{
		fprintf(fperr,"get_moddb: Cannot open file %s\n",fname);
		return(0);
	}
	for(n = 0; n < max_c; n++)
		qt[n].q_def = 0;

	nf = 0;
	while(NULL != fgets(line,sizeof line, fp))
	{
		for(i = 0; line[i] != '\0'; i++)
			if(0 == checkwhite(line[i]))
				break;
/*
 *	Allow the first non-whitespace thing to be a #
 */
		if(line[i] == '#')
	    	continue;
/*
 *	Also allow lines with only white space; ignore them.
 */
		if(line[i] == '\0')
			continue;

		nitems = sscanf(&line[i],"%s %s %s %s %s %s %s %s %s %s",
								  g0,g1,g2,g3,g4,g5,g6,g7,g8,g9);
		if(nitems == 0)
		{
			fprintf(fperr,"get_moddb: no items found for %s\n",line);
			fclose(fp);
			return(0);
		}
		for(n = 0; dg_dir[n] != NULL; n++)
			if(0 == (int) strcmp(dg_dir[n], g0))
				break;
		if(dg_dir[n] == NULL)
		{
			fprintf(fperr,"get_moddb: %s is an unknown database directive\n",
				g0);
			fclose(fp);
			return(0);
		}
		switch(n)
		{
		case 0:
			/*
			 *	chip directive
			 */
			if(nitems != 4)
			{
				fprintf(fperr,"get_moddb: chip directive, nitems(%d) != 4\n",
					nitems);
				fclose(fp);
				return(0);
			}
			q_ncols_raw = (int) atoi(g1);
			q_nrows_raw = (int) atoi(g2);
			q_image_size = (int) atoi(g3);
			break;
		case 1:
			/*
			 *	host directive
			 */
			if(nitems != 3)
			{
				fprintf(fperr,"get_moddb: host directive, nitems(%d) != 3)\n",
					nitems);
				fclose(fp);
				return(0);
			}
			strcpy(q_hostname[q_nhosts], g1);
			q_nboards[q_nhosts] = atoi(g2);
			q_nhosts++;
			break;
		case 2:
			/*
			 *	module directive
			 */
			if(nitems != 10)
			{
				fprintf(fperr,"get_moddb: number (%d) of args not correct\n",
						nitems);
				fclose(fp);
				return(0);
			}
			if(g1[0] == '?')
				f0 = -1;
			else
			{
				f0 = atoi(g1);
				if(f0 < 0 || f0 >= max_c)
				{
					fprintf(fperr,"get_moddb: board num %d not 0 to %d\n",
						f0,max_c -1);
					fclose(fp);
					return(0);
				}
			}
			qt[nf].q_def = 1;
			qt[nf].q_type = -1;
			if(0 == strcmp(g2,"master"))
				qt[nf].q_type = 0;
			if(0 == strcmp(g2,"slave"))
				qt[nf].q_type = 1;
			if(0 == strcmp(g2,"virtual"))
				qt[nf].q_type = 2;

			if(qt[nf].q_type == -1)
			{
				fprintf(fperr,"type unknown: %s\n",g2);
				fclose(fp);
				return(0);
			}
			qt[nf].q_assign = g4[0];
			qt[nf].q_rotate = atoi(g5);
			strcpy(qt[nf].q_host, g6);
			qt[nf].q_port = atoi(g7);
			qt[nf].q_dport = atoi(g8);
			qt[nf].q_sport = atoi(g9);

			sscanf(g3,"%x",&f2);
			if(qt[nf].q_type != 2 && 0 == strcmp(g6, lookhost) && ignore_host == 0)
			{
				if(f0 == -1)
				{
					ntry = MAX_CONTROLLERS;
					for(j = 0; j < q_nhosts; j++)
						if(0 == strcmp(q_hostname[j], g6))
						{
							ntry = q_nboards[j];
							break;
						};
					for(n = 0; n < ntry; n++)
						if(0 == reset_controller(n))
						{
							if(0<= test_communications(n, &adc, &ser))
							{
								if(f2 == ser)
								{
									f0 = n;
									break;
								}
							}
						}
					if(f0 == -1)
					{
						fprintf(fperr,"get_moddb: Error: serial number %x not found\n",f2);
						fclose(fp);
						return(0);
					}
				}
			}

			qt[nf].q_bn = f0;
			qt[nf].q_serial = f2;

			nf++;
			break;
		}
	}
	fclose(fp);
	for(n = 0; n < nf; n++)
	{
		if(qt[n].q_bn == -1)
		{
			for(i = 0; i < nf; i++)
			{
				foundi = 0;
				for(j = 0; j < nf; j++)
					if(qt[j].q_bn == i)
						foundi = 1;
				if(foundi == 0)
				{
					qt[n].q_bn = i;
					break;
				}
			}
		}
	}
	for(n = 0; n < nf; n++)
		qs[qt[n].q_bn] = qt[n];
	/*
	 *	Now just return the modules associated with this host
	 *	unless ignore_host is on, in which case return 'em all.
	 *
	 *	If the hostname "localhost" appears, don't look up this
	 *	machine's hostname, but return all entries matching localhost.
	 *	This will defeat the purpose of having all databases the
	 *	same on all machines, but....
	 */
	lookhost[0] = '\0';

	for(i = 0; i < q_nhosts; i++)
		if(0 == strcmp("localhost", q_hostname[i]))
		{
			strcpy(lookhost,q_hostname[i]);
			break;
		}
	if(lookhost[0] == '\0')
		(void) gethostname(lookhost,sizeof lookhost);

	nfinal = 0;
	for(n = 0; n < nf; n++)
	{
		if(ignore_host)
		{
			qm[nfinal++] = qs[n];
		}
		else
		{
			if(0 == strcmp(lookhost, qs[n].q_host))
			{
				qm[nfinal++] = qs[n];
			}
		}
	}
	return(nfinal);
}

int	get_moddb_eev(struct q_moddef *qm, int max_c, char *fname, int ignore_host)
{
	FILE			*fp;
	char			line[132];
	char			lookhost[256];
	int				i,j,foundi,n,nf,nitems,ntry,nfinal;
	char			g0[100],g1[100],g2[100],g3[100],g4[100],g5[100],g6[100],
					g7[100],g8[100],g9[100];
	int				f2,f0;
	struct q_moddef qt[MAX_CONTROLLERS];
	int				test_communications(int	bn, int *padc, int *pser);
	int				reset_controller(int bn);


	gethostname(lookhost,sizeof lookhost);

	fprintf(fpout,"\n                  localhost: %s\n",lookhost);
	q_nhosts = 0;
	q_ncols_raw = -1;
	q_nrows_raw = -1;
	q_image_size = -1;

	if(NULL == (fp = fopen(fname,"r")))
	{
		fprintf(fperr,"get_moddb: Cannot open file %s\n",fname);
		return(0);
	}
	for(n = 0; n < max_c; n++)
		qt[n].q_def = 0;

	nf = 0;
	while(NULL != fgets(line,sizeof line, fp))
	{
		for(i = 0; line[i] != '\0'; i++)
			if(0 == checkwhite(line[i]))
				break;
/*
 *	Allow the first non-whitespace thing to be a #
 */
		if(line[i] == '#')
	    	continue;
/*
 *	Also allow lines with only white space; ignore them.
 */
		if(line[i] == '\0')
			continue;

		nitems = sscanf(&line[i],"%s %s %s %s %s %s %s %s %s %s",
								  g0,g1,g2,g3,g4,g5,g6,g7,g8,g9);
		if(nitems == 0)
		{
			fprintf(fperr,"get_moddb: no items found for %s\n",line);
			fclose(fp);
			return(0);
		}
		for(n = 0; dg_dir[n] != NULL; n++)
			if(0 == (int) strcmp(dg_dir[n], g0))
				break;
		if(dg_dir[n] == NULL)
		{
			fprintf(fperr,"get_moddb: %s is an unknown database directive\n",
				g0);
			fclose(fp);
			return(0);
		}
		switch(n)
		{
		case 0:
			/*
			 *	chip directive
			 */
			if(nitems != 4)
			{
				fprintf(fperr,"get_moddb: chip directive, nitems(%d) != 4\n",
					nitems);
				fclose(fp);
				return(0);
			}
			q_ncols_raw = (int) atoi(g1);
			q_nrows_raw = (int) atoi(g2);
			q_image_size = (int) atoi(g3);
			break;
		case 1:
			/*
			 *	host directive
			 */
			if(nitems != 3)
			{
				fprintf(fperr,"get_moddb: host directive, nitems(%d) != 3)\n",
					nitems);
				fclose(fp);
				return(0);
			}
			strcpy(q_hostname[q_nhosts], g1);
			q_nboards[q_nhosts] = atoi(g2);
			q_nhosts++;
			break;
		case 2:
			/*
			 *	module directive
			 */
			if(nitems != 10)
			{
				fprintf(fperr,"get_moddb: number (%d) of args not correct\n",
						nitems);
				fclose(fp);
				return(0);
			}
			if(g1[0] == '?')
				f0 = -1;
			else
			{
				f0 = atoi(g1);
				if(f0 < 0 || f0 >= max_c)
				{
					fprintf(fperr,"get_moddb: board num %d not 0 to %d\n",
						f0,max_c -1);
					fclose(fp);
					return(0);
				}
			}
			qt[nf].q_def = 1;
			qt[nf].q_type = -1;
			if(0 == strcmp(g2,"master"))
				qt[nf].q_type = 0;
			if(0 == strcmp(g2,"slave"))
				qt[nf].q_type = 1;
			if(0 == strcmp(g2,"virtual"))
				qt[nf].q_type = 2;

			if(qt[nf].q_type == -1)
			{
				fprintf(fperr,"type unknown: %s\n",g2);
				fclose(fp);
				return(0);
			}
			qt[nf].q_assign = g4[0];
			qt[nf].q_rotate = atoi(g5);
			strcpy(qt[nf].q_host, g6);
			qt[nf].q_port = atoi(g7);
			qt[nf].q_dport = atoi(g8);
			qt[nf].q_sport = atoi(g9);

			sscanf(g3,"%d",&f2);
			if(qt[nf].q_type != 2 && 0 == strcmp(g6, lookhost) && ignore_host == 0)
			{
				if(f0 == -1)
				{
					ntry = MAX_CONTROLLERS;
					for(j = 0; j < q_nhosts; j++)
						if(0 == strcmp(q_hostname[j], g6))
						{
							ntry = q_nboards[j];
							break;
						};
					f0 = 0;		/* EEV systems are always one board */
				}
			}

			qt[nf].q_bn = f0;
			qt[nf].q_serial = f2;

			nf++;
			break;
		}
	}
	fclose(fp);
	for(n = 0; n < nf; n++)
	{
		if(qt[n].q_bn == -1)
		{
			for(i = 0; i < nf; i++)
			{
				foundi = 0;
				for(j = 0; j < nf; j++)
					if(qt[j].q_bn == i)
						foundi = 1;
				if(foundi == 0)
				{
					qt[n].q_bn = i;
					break;
				}
			}
		}
	}
	for(n = 0; n < nf; n++)
		qs[qt[n].q_bn] = qt[n];
	/*
	 *	Now just return the modules associated with this host
	 *	unless ignore_host is on, in which case return 'em all.
	 *
	 *	If the hostname "localhost" appears, don't look up this
	 *	machine's hostname, but return all entries matching localhost.
	 *	This will defeat the purpose of having all databases the
	 *	same on all machines, but....
	 */
	lookhost[0] = '\0';

	for(i = 0; i < q_nhosts; i++)
		if(0 == strcmp("localhost", q_hostname[i]))
		{
			strcpy(lookhost,q_hostname[i]);
			break;
		}
	if(lookhost[0] == '\0')
		(void) gethostname(lookhost,sizeof lookhost);

	nfinal = 0;
	for(n = 0; n < nf; n++)
	{
		if(ignore_host)
		{
			qm[nfinal++] = qs[n];
		}
		else
		{
			if(0 == strcmp(lookhost, qs[n].q_host))
			{
				qm[nfinal++] = qs[n];
			}
		}
	}
	return(nfinal);
}

static	char	*q_types[] = {"master ","slave  ","virtual"};

void	print_moddb(struct q_moddef *qm, int max_c)
{
	int	i;
	void order_modules(struct q_moddef *qm, int max_c, int *pvec);

	fprintf(fpout,"                          Module Summary\n");
	fprintf(fpout,"                 bn pos  type   serial rotate  port dport sport host\n");
	for(i = 0; i < max_c; i++)
	{
		if(qm[i].q_def == 0)
			continue;
		fprintf(fpout,"                 %2d  %c  %s  %4x   %3d    %4d  %4d  %4d %s\n",
			qm[i].q_bn,qm[i].q_assign,q_types[qm[i].q_type],qm[i].q_serial,
			qm[i].q_rotate,
			qm[i].q_port,qm[i].q_dport,qm[i].q_sport,qm[i].q_host);
	}

	fprintf(fpout,"\n");
}

void	print_moddb_eev(struct q_moddef *qm, int max_c)
{
	int	i;
	void order_modules(struct q_moddef *qm, int max_c, int *pvec);

	fprintf(fpout,"                          Module Summary\n");
	fprintf(fpout,"                 bn pos  type   offset rotate  port dport sport host\n");
	for(i = 0; i < max_c; i++)
	{
		if(qm[i].q_def == 0)
			continue;
		fprintf(fpout,"                 %2d  %c  %s  %4d   %3d    %4d  %4d  %4d %s\n",
			qm[i].q_bn,qm[i].q_assign,q_types[qm[i].q_type],qm[i].q_serial,
			qm[i].q_rotate,
			qm[i].q_port,qm[i].q_dport,qm[i].q_sport,qm[i].q_host);
	}

	fprintf(fpout,"\n");
}

void	print_moddb_all(struct q_moddef *qm, int max_c)
{
	int	i;

	if(q_ncols_raw != -1 && q_nrows_raw != -1 && q_image_size != -1)
	{
	fprintf(fpout,"                          Chip Summary\n");
	fprintf(fpout,"                 number of cols in a raw: %4d\n",
					q_ncols_raw);
	fprintf(fpout,"                 number of rows in a raw: %4d\n",
					q_nrows_raw);
	fprintf(fpout,"                 chip corrected size: %4d x %4d\n",
					q_image_size,q_image_size);
	fprintf(fpout,"\n");
	}

	if(q_nhosts > 0)
	{
	fprintf(fpout,"                          Host Summary\n");
	for(i = 0; i < q_nhosts; i++)
		if(q_nboards[i] == 1)
			fprintf(fpout,"                 Host: %s with %d LionM board.\n",
				q_hostname[i],q_nboards[i]);
		else
			fprintf(fpout,"                 Host: %s with %d LionM boards.\n",
				q_hostname[i],q_nboards[i]);
	fprintf(fpout,"\n");
	}

	fprintf(fpout,"                          Module Summary\n");
	fprintf(fpout,"                 bn pos  type   serial rotate  port dport sport host\n");
	for(i = 0; i < max_c; i++)
	{
		if(qm[i].q_def == 0)
			continue;
		fprintf(fpout,"                 %2d  %c  %s  %4x   %3d    %4d  %4d  %4d %s\n",
			qm[i].q_bn,qm[i].q_assign,q_types[qm[i].q_type],qm[i].q_serial,
			qm[i].q_rotate,
			qm[i].q_port,qm[i].q_dport,qm[i].q_sport,qm[i].q_host);
	}
	fprintf(fpout,"\n");
}

void	print_moddb_all_eev(struct q_moddef *qm, int max_c)
{
	int	i;

	if(q_ncols_raw != -1 && q_nrows_raw != -1 && q_image_size != -1)
	{
	fprintf(fpout,"                          Chip Summary\n");
	fprintf(fpout,"                 number of cols in a raw: %4d\n",
					q_ncols_raw);
	fprintf(fpout,"                 number of rows in a raw: %4d\n",
					q_nrows_raw);
	fprintf(fpout,"                 chip corrected size: %4d x %4d\n",
					q_image_size,q_image_size);
	fprintf(fpout,"\n");
	}

	if(q_nhosts > 0)
	{
	fprintf(fpout,"                          Host Summary\n");
	for(i = 0; i < q_nhosts; i++)
		if(q_nboards[i] == 1)
			fprintf(fpout,"                 Host: %s with %d PCI board.\n",
				q_hostname[i],q_nboards[i]);
		else
			fprintf(fpout,"                 Host: %s with %d PCI boards.\n",
				q_hostname[i],q_nboards[i]);
	fprintf(fpout,"\n");
	}

	fprintf(fpout,"                          Module Summary\n");
	fprintf(fpout,"                 bn pos  type   offset rotate  port dport sport host\n");
	for(i = 0; i < max_c; i++)
	{
		if(qm[i].q_def == 0)
			continue;
		fprintf(fpout,"                 %2d  %c  %s  %4d   %3d    %4d  %4d  %4d %s\n",
			qm[i].q_bn,qm[i].q_assign,q_types[qm[i].q_type],qm[i].q_serial,
			qm[i].q_rotate,
			qm[i].q_port,qm[i].q_dport,qm[i].q_sport,qm[i].q_host);
	}
	fprintf(fpout,"\n");
}

void print_moddb_local()
{
	print_moddb_all(qs, MAX_CONTROLLERS);
}

int	real_module(int v)
{
	if(v == 1 || v == 2)
		return(1);
	else
		return(0);
}

static struct q_moddef *qso;

int	which_module_number(char type)
{
	char	mods[] = {'W','X','Z','Y','0','1','2','3','4','5','6','7','8','\0'};
	int		nos[] = {0,1,2,3,0,1,2,3,4,5,6,7,8,-1};
	int		i;

	for(i = 0; mods[i] != '\0'; i++)
		if(mods[i] == type)
			return(nos[i]);
	return(-1);
}
int	cmp_orders(int o1, int o2)
{
	int		v1,v2;

	v1 = which_module_number(qso[o1].q_assign);
	v2 = which_module_number(qso[o1].q_assign);

	return(v2 - v1);
}

void order_modules(struct q_moddef *qm, int max_c, int *pvec)
{
	int			i, j, k, val;

	qso = qm;
	for(i = 0; i < MAX_CONTROLLERS; i++)
		pvec[i] = i;

	for(i = 0; i < max_c - 1; i++)
		for(j = 0; j < max_c - 1; j++)
		{
			if((val = cmp_orders(pvec[j], pvec[j + 1]))< 0)
			{
				k = pvec[j];
				pvec[j] = pvec[j + 1];
				pvec[j + 1] = k;
			}
		}
}
