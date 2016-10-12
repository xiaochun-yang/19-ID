/**********************************************************************************
                        Copyright 2002
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


                       Permission Notice

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*********************************************************************************/

// remote wavelength selection 
//check that no debugging features are active by searching for "TEST!"


#include <stdio.h>
#include <stdlib.h>

#include <dirent.h>

#define N_O_P 1000

#define PI 3.14159265

#define magicnumber 12398.0 // to convert A to eV

                          
//#define interedge 500  //Obsolete

// global variables
// Usually one does not want to collect the remote wavelength data at 
// a very low energy, so define a low energy cutoff for the search
// The high energy cutoff should be set where the beamline intensity
// starts to drop.
// 3 september 02: low_E_limit and energy_max may be read from a file

float low_E_limit=9000, energy_max=15000; 

float increase=0.005;    // If grad.area increases by less than increase*100 
float increase2=3.0;     // and if area is increase* larger than initial we 
                         // have found a potential remote

float maxfpp=0.0,maxfp, minfpp=0.0, minfp; // fpp and fp values from scan

float maxefpp,minefp;                    // energy at maxfpp and minfp

float eremote,remotefp,remotefpp;  //values for remote

//functions: 

void readlimit(char *); // Reads hard energy limits for the beamline

void itisnot(char *);  // prints error if files do not exist

void comparefpp();    // picks a remote wavelength as the peak if f" is higher 
                    // for the former (not used in BLU-ICE) 

// main : Selects remote wavelength, prints out the three standard 
//       wavelengths with anomalous scattering factors 



//------------- Function to print file opning error -------------

void itisnot (char *name)
{
  printf("ERROR: Input file %s could not be opened.\n\n", name);
  exit(1);
}

// ------Function to read energy limits from a file
// Read low and high energy limits for remote calculation 
// and area increase

void readlimit (char *parfilename)
{

  FILE *parfile=fopen(parfilename, "r") ;

  float energy_min;

  char string1[8],string2[8],string3[8],string4[8];

  if (!parfile) itisnot(parfilename);

  fscanf(parfile, "%s %f", string1, &energy_min);

  if (low_E_limit < energy_min) low_E_limit = energy_min; 
  
  fscanf(parfile, "%s %f %s %f %s %f",string2,&energy_max,string3,&increase,string4,&increase2);
  
  printf ("The limits are: %5.0f, %5.0f \n\n",low_E_limit,energy_max); 
  printf ("area grad: %4.3f \narea increase: %2.1f \n",increase,increase2); 

  //  if (increase==0.0) increase=0.05; This is not needed, I think- AG 
  fclose(parfile);


}

//--------- Function to select the maximum f" wavelength ---------
// Useful for some L edges 

void comparefpp ()
{
  if (remotefpp > maxfpp)
    printf(
"- Maximum fpp at %4.2f A, (f' = %4.1f  and f\" = %3.1f) \n \
This wavelength also serves as remote.\n",magicnumber/eremote, remotefp, remotefpp);
  else
    printf(
"- Maximum f\" at %6.4f A (f' = %4.1f and f\" = %3.1f) \n\
- Remote at %4.2f A (f' = %4.1f and f\" = %3.1f)\n",magicnumber/maxefpp,maxfp, maxfpp, magicnumber/eremote, remotefp, remotefpp);
}

//------------------------- Main program -------------------------


int main (int argc, char *argv[])
{

  FILE *file;      // Theoretical anomalous scattering factor values

  FILE *choochfile;  // Calculated values from fluorescence scan

  float energy[N_O_P],fpp[N_O_P],fp[N_O_P];

  float diff;        // Difference between energy values

  float area2,area1,area=0.0; //area1: is area delimited by minfp minfpp and 
                              // maxfpp maxfp 
                              //area2: as area1, between maxefpp and emax 
  float energy_last;
  int n=0; 

    // nop is number of points in fluorescence scan
  char header[100], nop[10];

  if(argc!=3 && argc!=4) {

    printf("USAGE: %s <element_symbol.dat> <chooch.efs> (For example: %s Se.dat scan_001.efs)\n\n", argv[0],argv[0]);
    exit(1);
  }


// Finding out maximum fpp and minimum fp from chooch file
  
  if(!(choochfile=fopen(argv[2], "r"))) itisnot(argv[2]);
  fgets(header, 100, choochfile);
  fgets(nop, 10, choochfile);
  while (!feof(choochfile)) {
    fscanf(choochfile, "%f %f %f", &energy[n], &fpp[n], &fp[n] );
    if ((*fpp-maxfpp) > 0.0 ) maxfpp = *fpp, maxfp = *fp, maxefpp=*energy;
    if ((*fp - minfp) < 0.0 ) minfp = *fp, minfpp= *fpp, minefp=*energy;
  }

  if ((area1 = (maxfp - minfp)*(maxfpp + minfpp)) <= 0.0){
    printf("\n ERROR: Scan file may be corrupted\n\n");
    fclose(choochfile);
    exit(1);
  }


  n=0;   // reassign counter  
  fclose(choochfile);


//if no file with beamline parameters is given, use defaults

  if(argc==4) readlimit(argv[3]); 


// Check that theoretical data file exists 

  //  if (chdir(DATA_DIR))
  //  printf("\n ERROR: Data file directory cannot be accessed.\n\n");

  if(!(file=fopen(argv[1], "r"))) itisnot(argv[1]);


  printf ("\n\n \
------------------------ WAVELENGTH SELECTION ------------------------ \n \
                      Ana Gonzalez - September 2002\n\n \
This program extracts the wavelengths which maximize |f\"| and |f'| from \n \
the output .efs file from Chooch. The program then calculates the optimal \n \
remote wavelength for the MAD experiment based on the area determined by \n \
the centers of the phasing circles defined by the values of the complex \n \
anomalous scattering factor. This selection makes the assumption that \n \
anomalous and dispersive differences are measured with the same error \n \
on the MAD experiment. There is experimental evidence that on a typical \n \
experiment, dispersive differences are measured more accurately. \n \
Therefore, selecting a more remote wavelength than the one given by the \n \
program might result in even better phases.\n\n");
 
  if ( (diff = maxefpp - energy_max) >= 0.0 ) diff= -1.0; //Make sure we don't exceed max. E, unless the absorption edge is above the search limit. I don't think this does anything - Ana 4/28/09
  energy_last = low_E_limit;

//Read file with theoretical  fpp and fpp values

  while (!feof(file)) {

    fscanf(file, "%f %f %f", &energy[n], &fp[n], &fpp[n] );
    if ( (diff = *energy - energy_max) > 0.0 ) break;


    if (*energy >= low_E_limit ) {
      area2=area1 + (*fp - maxfp)*(maxfpp + *fpp);
    // If area increases by more than parameter "increase", continue 
    // searching

      printf("E > Elow %f %f %f %f\n",area2,((area2 - area)/(*energy - energy_last)),*energy,area2/area1 ); //TEST!
      if ((area2 - area)/(*energy - energy_last) > increase) {
	eremote=*energy, remotefp=*fp, remotefpp=*fpp;

	area=area2; //Maximum area

	    printf ("REMOTE %f\n", eremote); //TEST!
      }
       // If the area difference is less than "increase" but the 
       // current area is smaller, the enrgy is not a good remote
       // If the area is larger, we have found the remote energy

        else 
          if ((area2 - area) > 0.0  && (area2/area1 > increase2)) {
	    eremote=*energy, remotefp=*fp, remotefpp=*fpp;
	    break;
	  }
    }
    energy_last = *energy;
    //   area=area2;

  }
  fclose(file);
  if (eremote) { 
    printf ("\n The optimal wavelengths for data collection are: \n");
    comparefpp();
    printf (
"- Minimum f' at %6.4f A (f' = %4.1f and f\" = %3.1f)\n",magicnumber/minefp,minfp, minfpp);

//For Blu-ICE

 printf ("\n Remote_info  %6.1f %4.1f %4.1f\n",eremote, remotefp,remotefpp);
  }
}









