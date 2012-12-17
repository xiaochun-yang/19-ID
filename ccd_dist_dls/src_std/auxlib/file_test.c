#include <stdio.h>
#include <string.h>
#include "filec.h"
#include <stdlib.h>

#define USE_OLD_CALLS 
#ifndef USE_OLD_CALLS

unsigned int main(unsigned int argc, char **argv)
{
  unsigned short *a, *ap;
  char ahead[4096]; 
  int asize[2];
  int adim=2;

  unsigned short *b, *bp;
  char *bhead;
  int bsize[2];
  int bdin;

  int type;
  int i, j;
  int is1=512, is2=512;
  int dim;
  char s[80];
  char filename[80];
  int ii, jj;


  if ( argc > 1 && !strncmp(argv[1], "debug", 5) )
    {
      filec_setdebug (1);
      printf ("Debugging on\n");
    }
  
  a = malloc (is1 * is2 * sizeof (*a) );
  asize[0] = is1; asize[1] = is2;

  printf("Filling test array\n");
  for (i=0, ap=a; i<is1*is2; i++)
    {
      ii = i % 512 + 1;
      jj = i / 512 + 1;
      if ( ii % 10 == 0 )
        *ap++ = 0;
      else if ( jj % 5 == 0 )
        *ap++ = is1+1-ii;
      else
        *ap++ = ii;
    }
  
  printf("\n\n--------Testing Unsigned Short File----------\n");
  printf("Clearing Header\n");
  clrhd (ahead);
  printf("Filling Header\n");
  puthd ("COMMENT1", "This is the first comment", ahead);
  puthd ("COMMENT2", "This is the second comment", ahead);

  printf("Writing test file\n");
  strcpy(filename, "test.dat");
  if (wrfile (filename, ahead, (char*) a, adim, asize, SMV_UNSIGNED_SHORT)!=0 )
    printf("Error writing file\n");

  printf("Reading test file\n");
  if ( rdfile(filename, &bhead, (char**) &b, &dim, bsize, &type)!=0 )
    {
      printf("Error reading file %s\n", filename);
      perror ("Reading file");
    }
  else
    {
      printf("Testing file\n");
      printf ("Image size : %d %d\n", bsize[0], bsize[1]);
      gethd ("TYPE", s, bhead);
      printf ("Type >%s<\n", s);
      gethd ("COMMENT1", s, bhead);
      printf ("Comment1 >%s<\n", s);
      gethd ("COMMENT2", s, bhead);
      printf ("Comment2 >%s<\n", s);
      
      for (i=0, bp=b, ap=a; i<bsize[0]*bsize[1]; i++, bp++, ap++)
        {
          ii = i % 512 + 1;
          jj = i / 512 + 1;
          if ( *ap != *bp ) 
            printf ("ERROR at (%d,%d) %5d (expected: %5d)\n", 
		    ii, jj, *ap, *bp);
        }
    }
  free (b);

  printf("\n\n--------Testing Compressed File----------\n");
  printf("Clearing Header\n");
  clrhd (ahead);
  printf("Filling Header\n");
  puthd ("COMMENT1", "This is the third comment", ahead);
  puthd ("COMMENT2", "This is the fourth comment", ahead);

  printf("Writing compressed file\n");
  strcpy(filename, "test.comp");
  if (wrrlmsb (filename, ahead, (char*) a, adim, asize, SMV_UNSIGNED_SHORT)!=0)
    printf("Error writing Compressed file\n");
  
  printf("Reading compressed file %s\n", filename);

  if ( rdfile(filename, &bhead, (char**) &b, &dim, bsize, &type)!=0 )
    {
      printf("Error reading file %s\n", filename);
      perror ("Reading file");
    }
  else
    {
      printf("Testing file\n");
      printf ("Image size : %d %d\n", bsize[0], bsize[1]);
      gethd ("TYPE", s, bhead);
      printf ("Type >%s<\n", s);
      gethd ("COMMENT1", s, bhead);
      printf ("Comment1 >%s<\n", s);
      gethd ("COMMENT2", s, bhead);
      printf ("Comment2 >%s<\n", s);
      
      for (i=0, bp=b, ap=a; i<bsize[0]*bsize[1]; i++, bp++, ap++)
        {
          ii = i % 512 + 1;
          jj = i / 512 + 1;
          if ( *ap != *bp ) 
            printf ("ERROR at (%d,%d) %5d (expected: %5d)\n", 
		    ii, jj, *ap, *bp);
        }
    }
  free (b);


}

#else

unsigned int main(unsigned int argc, char **argv)
{
  unsigned short a[512*512], *ap;
  int i, j;
  int as1=512, as2=512, is1=512, is2=512;
  char head[4096]; 
  char s[80];
  char filename[80];
  int ii, jj;

  if ( argc > 1 && !strncmp(argv[1], "debug", 5) )
    {
      filec_setdebug (1);
      printf ("Debugging on\n");
    }

  printf("Filling test array\n");
  for (i=0, ap=a; i<512*512; i++)
    {
      ii = i % 512 + 1;
      jj = i / 512 + 1;
      if ( ii % 10 == 0 )
        *ap++ = 0;
      else if ( jj % 5 == 0 )
        *ap++ = is1+1-ii;
      else
        *ap++ = ii;
    }
  
  printf("\n\n--------Testing Unsigned Short File----------\n");
  printf("Clearing Header\n");
  clrhd (head);
  printf("Filling Header\n");
  puthd ("COMMENT1", "This is the first comment", head);
  puthd ("COMMENT2", "This is the second comment", head);

  printf("Writing test file\n");
  strcpy(filename, "test.dat");
  if ( wrmad (filename, head, (short*) a, as1, as2, is1, is2)!=0 )
    printf("Error writing file\n");
  
  printf("Clearing test array\n");
  memset(a, 0, 2*512*512);
  printf("Clearing Header\n");
  clrhd (head);
  
  printf("Reading test file\n");
  if ( rdmad(filename, head, (short*) a, as1, as2, &is1, &is2)!=0 )
    printf("Error reading file\n");
  else
    {
      printf("Testing file\n");
      printf ("Image size : %d %d\n", is1, is2);
      gethd ("TYPE", s, head);
      printf ("Type >%s<\n", s);
      gethd ("COMMENT1", s, head);
      printf ("Comment1 >%s<\n", s);
      gethd ("COMMENT2", s, head);
      printf ("Comment2 >%s<\n", s);
      
      
      for (i=0, ap=a; i<512*512; i++, ap++)
        {
          ii = i % 512 + 1;
          jj = i / 512 + 1;
          if ( ii % 10 == 0 )
            j = 0;
          else if ( jj % 5 == 0 )
            j = is1+1-ii;
          else
            j = ii;
          if ( *ap != j ) 
            printf ("ERROR at (%d,%d) %5d (expected: %5d)\n", 
		    ii, jj, *ap, j);
        }
    }


  printf("Filling test array\n");
  for (i=0, ap=a; i<512*512; i++)
    {
      ii = i % 512 + 1;
      jj = i / 512 + 1;
      if ( ii % 10 == 0 )
        *ap++ = 0;
      else if ( jj % 5 == 0 )
        *ap++ = is1+1-ii;
      else
        *ap++ = ii;
    }
  
  printf("\n\n--------Testing Compressed File----------\n");
  printf("Clearing Header\n");
  clrhd (head);
  printf("Filling Header\n");
  puthd ("COMMENT1", "This is the third comment", head);
  puthd ("COMMENT2", "This is the fourth comment", head);

  printf("Writing compressed file\n");
  strcpy(filename, "test.comp");
  if ( wrswap (filename, head, (short*) a, as1, as2, is1, is2)!=0 )
    printf("Error writing file\n");
  
  printf("Clearing test array\n");
  memset(a, 0, 2*512*512);
  printf("Clearing Header\n");
  clrhd (head);
  
  printf("Reading compressed file %s\n", filename);
  if ( rdmad(filename, head, (short*) a, as1, as2, &is1, &is2)!=0 )
    printf("Error reading file\n");
  else
    {
      printf("Testing compressed file\n");
      printf ("Image size : %d %d\n", is1, is2);
      gethd ("TYPE", s, head);
      printf ("Type >%s<\n", s);
      gethd ("COMMENT1", s, head);
      printf ("Comment1 >%s<\n", s);
      gethd ("COMMENT2", s, head);
      printf ("Comment2 >%s<\n", s);
      
      
      for (i=0, ap=a; i<512*512; i++, ap++)
        {
          ii = i % 512 + 1;
          jj = i / 512 + 1;
          if ( ii % 10 == 0 )
            j = 0;
          else if ( jj % 5 == 0 )
            j = is1+1-ii;
          else
            j = ii;
          if ( *ap != j ) 
            printf ("ERROR at (%d,%d) %5d (expected: %5d)\n", 
		    ii, jj, *ap, j);
        }
    }



}

#endif
