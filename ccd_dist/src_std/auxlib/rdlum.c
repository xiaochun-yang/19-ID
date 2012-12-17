#include <stdio.h>
#include <string.h>
#ifndef vms
#include <malloc.h>
#endif
#include "filec.h"

/*
 * Read a "Lumiscan" image - which is the format from UVA
 */
int rdlum (char* filename, char** head, int *lhead,
	   char** array, int* naxis, int* axis, int *type)
     
{
  int readl;
  int i, j, k;
  int istat, bo, cbo, dim;
  int lun=1;
  int lflag;
  int is1, is2;
  int  llen, n, val; 
  char lumhead[2048];
  unsigned short lumsiz[2];
  unsigned int *data;
  char s[132];
  int filec_debug = filec_getdebug();

  *array = 0;
  *head = 0;


  j = strlen(filename);
  if (filec_debug)
    printf("Opening file: %s\n", filename);
  dskbor_ ( &lun, filename, &j, &istat);
  if ( istat != 0 ) return -1;

  /*
   * While reading the header, have to wait before proceding
   */
  lflag = (1==1);
  if (filec_debug)
    printf("Reading header\n");
  dskbwr_ ( &lun, &lflag );
  
  /*
   * The header should be 2048 bytes
   */
  readl = 2048;
  dskbr_ ( &lun, (char*) lumhead, &readl, &istat);
  if (filec_debug)
    printf("Read Completion status : %d\n", istat);
  if ( istat != 0 ) goto close;

  /*
   * Is this really a lumiscan image?
   */
  if ( strncmp (&lumhead[4], "lumi", 4) ) return -2;
      
/*
 * Lumiscan images are always big_endian format (bo=1)
 * Check what this computer is 
 */
  cbo = getbo ();
  if (filec_debug)
    {
      if ( cbo == 0 ) 
	printf ("This computer is little endian\n");
      else 
	printf ("This computer is big endian\n");
    }
  
  memcpy (lumsiz, (char*) &lumhead[806], 4);
  if ( cbo == 1 ) swpbyt (0, 4, (char*) lumsiz);
  
  if (filec_debug)
    {
      is1 = *lumsiz; is2 = *(lumsiz+1);
      printf("Image size %d x %d\n", is1, is2);
    }
  
  *lhead = 4096;
  *head = malloc (4096);
  memset (*head, 0, 4096);
  clrhd (*head);
  
  *naxis = 2; axis[0] = is1; axis[1] = is2;
  puthd ("DIM", "2", *head);
  sprintf (s, "%d", is1);
  puthd ("SIZE1", s, *head);
  sprintf (s, "%d", is2);
  puthd ("SIZE2", s, *head);
  *type = SMV_UNSIGNED_SHORT;
  puthd ("TYPE", "unsigned_short", *head);

  if (filec_debug)
    printf("Updated Header        : \n%s<END\n", *head);

  readl = is1 * is2 * sizeof (unsigned short);
  data = malloc (readl);
  *array = (char*) data;
  if (filec_debug)
    printf("Reading %d bytes\n", readl);
  dskbr_ ( &lun, (char*) data, &readl, &istat);

  if ( cbo == 1 ) 
    {
      if (filec_debug)
	printf("Swapping %d bytes\n", readl);
      swpbyt(0, readl, (char*) data);
    }

 close:
  if (filec_debug)
    printf("Done reading Lumiscan image (size %d x %d) (istat %d)\n", 
	   is1, is2, istat);

  if ( istat != 0 ) 
    dskbcr_ (&lun, &i);
  else
    dskbcr_ (&lun, &istat);
  
  if ( istat != 0 )
    {
      if ( *array != 0 ) free (*array);
      if ( *head != 0 ) free (*head);
      return istat;
    }
  else
    return 0;
}
