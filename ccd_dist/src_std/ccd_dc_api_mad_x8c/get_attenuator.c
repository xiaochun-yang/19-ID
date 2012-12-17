#include	<stdio.h>

/*
 *	Return the attenuator name according to the index
 *	"index".  If anything goes wrong, print out to the
 *	screen and set the attenuator text to the character
 *	form of the value index.  Best we can do.
 */

#define	MAX_ATTENUATORS	100

int	get_attenuator_name(int index, char *name)
{
	int	n;

    	FILE	*fpatten;
	char	*attencp;
	char	attenline[132];
	char	attenwidname[132];
	char	atten_label[132];

	n = 0;
	if(NULL != (attencp = (char *) getenv("CCD_ATTENUATOR_LIST")))
	{
		if(NULL != (fpatten = fopen(attencp,"r")))
		{
			for(n = 0; n < MAX_ATTENUATORS; n++)
			{
				if(NULL != fgets(attenline,sizeof attenline, fpatten))
				{
					if(n == index)
					{
						attenline[strlen(attenline) - 1] = '\0';
						strcpy(name, attenline);
						fclose(fpatten);
						return(1);
					}
				}
				else
					break;
			}
			fprintf(stderr,"get_attenuator_name: Cannot find line %d in file %s \n",index, attencp);
			sprintf(name,"%d",index);
			return(0);
			fclose(fpatten);
		}
		else
		{
			fprintf(stderr,"get_attenuator_name: Cannot open %s as attenuator name file.\n",attencp);
			sprintf(name,"%d",index);
			return(0);
		}
		
	}
	else
	{
		fprintf(stderr,"get_attenuator_name: Environment for attenuator file %s NOT set\n", attencp);
		sprintf(name,"%d",index);
		return(0);
	}
}
