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

/*
 * header.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern "C" {
#include "xos.h"
#include "xos_log.h"
}
#include "marheader.h"

#define END_HEADER         "END OF HEADER"

int parse_body_header_to_buf( FILE *input, char* buf, int maxSize);


xos_result_t append_mar345_header_to_buf(const char* filename, char* buf, int maxSize) 
{
	FILE * input;
	
	if ((buf == NULL) || (maxSize <= 0)) 
		return XOS_FAILURE;
	
	if ((input = fopen( filename, "rt"))==NULL) 
   	{
    	xos_error("Error opening %s \n", filename);
		return XOS_FAILURE;
	}
	
	// find start of text portion of header
	parse_start_header(input, NULL);
	
	// read the header
	parse_body_header_to_buf(input, buf, maxSize);
   
	// close the image file
	fclose(input);

   
	return XOS_SUCCESS;
	
 }


xos_result_t append_mar345_header ( const char * filename, FILE * output) 
	{
	FILE * input;
	
	if ((input = fopen( filename, "rt"))==NULL) 
   	{
    	xos_error("Error opening %s \n", filename);
		return XOS_FAILURE;
		}
	
	/* find start of text portion of header */
		parse_start_header(input, output);
	
	/* read the header */
	parse_body_header(input,output);
   
   /* close the image file */
   fclose(input);

   
   return XOS_SUCCESS;
 }


void parse_start_header( FILE *input, FILE * /*output*/ )
	{   
	int count=0;
   
	while ( ( fgetc(input) != 'm') && ( count++ < 128 ) );
 	while( fgetc(input) != 'h' );
	} 



int parse_body_header_to_buf( FILE *input, char* buf, int maxSize)
{
	int i=50,j=0,k=0,t=0;
	char line[3000]={' '};
	char *concat_tokens;
	char key_token[32][100]={' '};
	char item_token[32][100]={' '};
   char spacer[200];
   int len;
   char outputbuffer[255];
   
	/* skip blank lines */
	while( fgetc(input) != '\n' );
	
	fgets(line,300,input);
		
	while(line[i]==' ')
		{  
		i--;
		}
   
   concat_tokens=(char *)malloc(1400*sizeof(char));
   
   while( j <= i )
		{ 
		concat_tokens[j]=line[j]; 
      j++; 
     	}
  	
   if (strcmp(concat_tokens, END_HEADER)==0) return 0;
		


   while( (strcmp(concat_tokens, END_HEADER) !=0 ) )
   	{
		i=0; j=0; t=0; 
        
        while(line[i]!=' ') i++;
        
        i++;
       
		while(line[t]!=' ')
			{
			key_token[k][t]=line[t];       
			t++; 
			}          
   
  	 	while(line[t]==' ') t++;
			          
			j=t; 
			i=0;
		
	    	while (line[t]!='\n')
  	   	{       
			t++;       
	      if (line[t]==' ')	
				{
				t++;
				if (line[t]==' ')
					{
				 	t++;
               if (line[t]==' ')
						{	
						t -= 2;
			 			break; 
						}
					}
				} 	
			}
		
		while(j<t)
			{
			item_token[k][i] = line[j];
			j++; 
			i++;
			}   
	
	
		len = (int)strlen( key_token[k] );
		
		strcpy( spacer, "                        " );
		spacer[20-len] = 0;
		sprintf( outputbuffer, "%s %s %s\n", key_token[k], spacer,
			item_token[k] );
//		fputs(outputbuffer, output );
		if (strlen(outputbuffer) < (maxSize - strlen(buf)))
			strcat(buf, outputbuffer);
		else
			return 0;
	
		for (i=0; i<300; i++)
			{
			line[i]=' ';
        	}
 
		if ((k!=0)&&(k!=1))
			{
			fgets(line,300,input);
			}  
		
		fgets(line,300,input);
		memmove(concat_tokens,key_token[k],100);
		strcat(concat_tokens," ");
      strcat(concat_tokens,item_token[k]);
		k++;
    	}  
   
   	return 1;       
	}
	
	
int parse_body_header( FILE *input, FILE *output )
{
	int i=50,j=0,k=0,t=0;
	char line[3000]={' '};
	char *concat_tokens;
	char key_token[32][100]={' '};
	char item_token[32][100]={' '};
   char spacer[200];
   int len;
   char outputbuffer[255];
   
	/* skip blank lines */
	while( fgetc(input) != '\n' );
	
	fgets(line,300,input);
		
	while(line[i]==' ')
		{  
		i--;
		}
   
   concat_tokens=(char *)malloc(1400*sizeof(char));
   
   while( j <= i )
		{ 
		concat_tokens[j]=line[j]; 
      j++; 
     	}
  	
   if (strcmp(concat_tokens, END_HEADER)==0) return 0;
		


   while( (strcmp(concat_tokens, END_HEADER) !=0 ) )
   	{
		i=0; j=0; t=0; 
        
        while(line[i]!=' ') i++;
        
        i++;
       
		while(line[t]!=' ')
			{
			key_token[k][t]=line[t];       
			t++; 
			}          
   
  	 	while(line[t]==' ') t++;
			          
			j=t; 
			i=0;
		
	    	while (line[t]!='\n')
  	   	{       
			t++;       
	      if (line[t]==' ')	
				{
				t++;
				if (line[t]==' ')
					{
				 	t++;
               if (line[t]==' ')
						{	
						t -= 2;
			 			break; 
						}
					}
				} 	
			}
		
		while(j<t)
			{
			item_token[k][i] = line[j];
			j++; 
			i++;
			}   
	
	
		len = (int)strlen( key_token[k] );
		
		strcpy( spacer, "                        " );
		spacer[20-len] = 0;
		sprintf( outputbuffer, "%s %s %s\n", key_token[k], spacer,
			item_token[k] );
		fputs(outputbuffer, output );
	
		for (i=0; i<300; i++)
			{
			line[i]=' ';
        	}
 
		if ((k!=0)&&(k!=1))
			{
			fgets(line,300,input);
			}  
		
		fgets(line,300,input);
		memmove(concat_tokens,key_token[k],100);
		strcat(concat_tokens," ");
      strcat(concat_tokens,item_token[k]);
		k++;
    	}  
   
   	return 1;       
	}
