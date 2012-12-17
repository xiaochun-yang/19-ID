#include <stdio.h>
#include <string.h>
#include "filec.h"


int rdcal ( char* filename, struct readcalp *c )
{
  int istat;
  char info[2048];
  char s[80];

  istat = rdhead ( filename, info );
  
  if ( istat == 0 )
    {
      
      gethd ("TYPE", s, info );
      if ( strcmp(s,"calibration_file") )
	return -1;

      gethd ("X_CENTER", s, info );
      sscanf (s, "%f", &c->x_center);
      gethd ("Y_CENTER", s, info );
      sscanf (s, "%f", &c->y_center);
      gethd ("X_PT_CENTER", s, info );
      sscanf (s, "%f", &c->x_pt_center);
      gethd ("Y_PT_CENTER", s, info );
      sscanf (s, "%f", &c->y_pt_center);
      gethd ("X_SCALE", s, info );
      sscanf (s, "%f", &c->x_scale);
      gethd ("Y_SCALE", s, info );
      sscanf (s, "%f", &c->y_scale);
      gethd ("RATIO", s, info );
      sscanf (s, "%f", &c->ratio);
      gethd ("VER_SLOPE", s, info );
      sscanf (s, "%f", &c->ver_slope);
      gethd ("HORZ_SLOPE", s, info );
      sscanf (s, "%f", &c->horz_slope);
      gethd ("RADIAL_A", s, info );
      sscanf (s, "%f", &c->a);
      gethd ("RADIAL_A1", s, info );
      sscanf (s, "%f", &c->a1);
      gethd ("RADIAL_B", s, info );
      sscanf (s, "%f", &c->b);
      gethd ("RADIAL_C", s, info );
      sscanf (s, "%f", &c->c);
      gethd ("SPACING", s, info );
      sscanf (s, "%f", &c->spacing);
      gethd ("X_BEAM", s, info );
      sscanf (s, "%f", &c->x_beam);
      gethd ("Y_BEAM", s, info );
      sscanf (s, "%f", &c->y_beam);
      gethd ("X_SIZE", s, info );
      sscanf (s, "%d", &c->x_size);
      gethd ("Y_SIZE", s, info );
      sscanf (s, "%d", &c->y_size);

      gethd ("XINT_START", s, info );
      sscanf (s, "%d", &c->xint_start);
      gethd ("YINT_START", s, info );
      sscanf (s, "%d", &c->yint_start);
      gethd ("XINT_STEP", s, info );
      sscanf (s, "%d", &c->xint_step);
      gethd ("YINT_STEP", s, info );
      sscanf (s, "%d", &c->yint_step);
      gethd ("XINV_START", s, info );
      sscanf (s, "%d", &c->xinv_start);
      gethd ("YINV_START", s, info );
      sscanf (s, "%d", &c->yinv_start);
      gethd ("XINV_STEP", s, info );
      sscanf (s, "%d", &c->xinv_step);
      gethd ("YINV_STEP", s, info );
      sscanf (s, "%d", &c->yinv_step);

      gethd ("PSCALE", s, info );
      sscanf (s, "%f", &c->pscale);
    }
  
  return istat;
}





