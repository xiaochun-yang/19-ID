/************************************************************************
                        Copyright 2003
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
************************************************************************/


/*
 * The library consists of two files: libdistl.h, libdistl.cc.
 *
 * Developed by 
 *  Zepu Zhang,    zpzhang@stanford.edu
 *  Ashley Deacon, adeacon@slac.stanford.edu
 *  and others.
 *
 * July 2001 - May 2004.
 */


#include "libdistl.h"
typedef Distl::spot::point_list_t point_list_t;

diffimage::diffimage(): npxclassifyscan(3), nicecutoff(2),
                        report_overloads(false)
{
	// Only processing parameters not bound to any specific image
	// are specified here.
	// Image properties are initialized when image data is initialized.
	
    overloadvalue = 65535;

    imgmargin = 20;

    scanboxsize[0] = 101;
    scanboxsize[1] = 57;
    scanboxsize[2] = 51;

    bgupperint[0] = 1.5;
    bgupperint[1] = 1.5;
    bgupperint[2] = 1.5;

    difflowerint = 3.8;

    iceringwidth = 4;
    iceresolmin = 1.8;
    iceresolmax = 10.0;

    icering_cutoffint[0] = 0.0;
    icering_cutoffint[1] = 1.5;

    icering_cutoffprct[0] = 0.55;
    icering_cutoffprct[1] = 0.20;

	icering_strength_cutweight[0] = 0.6;
	icering_strength_cutweight[1] = 0.4;
	// Weight of the two cutoff percentages in determining ice-ring strength.
	// Add to 1.
	// The lower cutoff (cutoffint[0]) measures continuity;
	// the higher cutoff (cutoffint[1]) measures intensity.

    spotarealowcut = 5;
    spotintensitycut = 0;
    spotdistminfactor = 0.9;

    imgresolringpow = -3.0;
    imgresol_unispot_shiftfactor = 0.5;
    imgresol_unispace_cutoff_fraction = 0.15;
}


void diffimage::cleardata()
{
	//for (int i = 0; i < pixelvalue.size(); i++)
	//	pixelvalue[i].clear();
	pixelvalue.clear();

	for (int i = 0; i < pixelintensity.size(); i++)
		pixelintensity[i].clear();
	pixelintensity.clear();

	maximas.clear();
	spots.clear();
	overloadpatches.clear();
	icerings.clear();

	imgresol_unispotresols.clear();
	imgresol_unispaceresols.clear();
	imgresol_unispacespotcounts.clear();
}


diffimage::~diffimage() { cleardata(); }

inline int iround(double const& x) {
  if (x < 0) {return static_cast<int>(x-0.5);}
  return static_cast<int>(x+.5);
}

void diffimage::set_imageheader(const double pxsize, const double dist, const double wavelen,
		const double oscstart, const double oscrange, 
		const double beamctrx, const double beamctry) 
{
	// Clear data leftover from processing previous image.
	
	cleardata();

	// In setimageheader and setimagedata
	// eventually all image property values will be reset,
	// except for processing parameters.
	// This is to avoid problems while multiple files
	// are processed in a row.
	
	pixel_size = pxsize;
	distance = dist;
	wavelength = wavelen;
	/* Nick sauter:
	  The following modification fixes a bug that caused a negative number square root.  
	  The resolution limit for the ice ring search must be set to at least wavelength/2, 
	  since diffraction past that limit is mathematically impossible.
	  */
 	iceresolmin = std::max(wavelength/2.0,iceresolmin); //respect sampling theorem
	resolb = pxsize * pxsize / dist / dist;
	osc_start = oscstart;
	osc_range = oscrange;
	beam_center_x = beamctrx;   
	beam_center_y = beamctry;  
	// The origin point wrt which the beam center is located is not clear.
	// Here it is assumed that beam_center_x and beam_center_y use
	// the same coord system as X and Y do, i.e.,
	// beam_center_x: top->bottom
	// beam_center_y: left->right

        //beam_x/beam_y are assigned as integers to support
        // array indexing in subsequent steps.  However, it is dangerous
        // to use static_cast<int> because this produces a truncation
        // instead of a proper rounding to the nearest integer.
        // Use of the new function iround() corrects this.
        
	beam_x = iround(beam_center_x / pixel_size);
	beam_y = iround(beam_center_y / pixel_size);
}


void diffimage::set_imagedata(const int* const data, const int ncol, const int nrow)
{
	// DATA are stored by column, from left to right.
	// Type is int.

	pixelvalue = constmat<int>(data, ncol, nrow);

	firstx = imgmargin;
	lastx = pixelvalue.nx - 1 - imgmargin;
	firsty = imgmargin;
	lasty = pixelvalue.ny - 1 - imgmargin;
}

detector_shape get_image_geometry( image_rawdata_t const& pixels ) {

  // simple heuristic to guess the image geometry.  If a small square region in
  // the upper-left of the image has a constant pixel value, then the active 
  // area is likely an inscribed circle.  Otherwise, image is assumed square. 

  image_rawdata_t::data_type reference = pixels [50][50]; 
  for (int x = 50; x < 100; ++x) {
    for (int y = 50; y < 100; ++y) {
      if (pixels [x][y] != reference) { return SQUARE; }
    }
  }
  return CIRCLE;
}

int diffimage::process()
{
	// The order of the following functions should not be changed 
	// without careful investigation.

	//clock_t t0;
	//clock_t t1;

        // 50-pixel corner sample to detect circular image geometry
        image_geometry = get_image_geometry(pixelvalue);
	underloadvalue = get_underload();

	//t0 = clock();
	pxlclassify();
	//t1 = clock();
	//cout << "\t" << static_cast<double>(t1 - t0)/CLOCKS_PER_SEC << " secondes in pxlclassify\n";

	//t0 = clock();
	search_icerings();
	//t1 = clock();
	//cout << "\t" << static_cast<double>(t1 - t0)/CLOCKS_PER_SEC << " secondes in search_icerings\n";

	//t0 = clock();
	search_maximas();
	//t1 = clock();
	//cout << "\t" << static_cast<double>(t1 - t0)/CLOCKS_PER_SEC << " secondes in search_maximas\n";

	search_spots();

	search_overloadpatches();

	imgresolution();
	
	// the following added by qxu
	imgresolution2();
	spotshape();
        diffstrength();
	diffscore();

	return 0;
}

int diffimage::get_underload() const 
{
	// *****************************************************************
	// Determine the upperbound value for underloaded pixels, i.e.,
	// pixels with value <= UNDERLOAD are considered underloaded, like
	// those on the border or blocked by the beam stick.
	//
	// This function checks the whole image, not restricted by
	// 'firstx', 'lastx', 'firsty', 'lasty'.
	// *****************************************************************

	int ncols = pixelvalue.nx;
	int nrows = pixelvalue.ny;
	int crosswid = 40;
	int cornerfrac = 5;
	int cornerwidth = pixelvalue.ny / cornerfrac;
	int np = 4 * cornerwidth * cornerwidth + 
                 crosswid * (nrows + ncols) - crosswid*crosswid;

	vector<int> px(np);
        vector<int>::iterator px_itr = px.begin();
        
        // Four corners.
        for (int anchor = 0; //linux performance: first iteration is very fast
                 anchor <= pixelvalue.nx - cornerwidth; //2nd consumes more time
                 anchor += pixelvalue.nx - cornerwidth) {
	  for (int x = anchor; x < anchor + cornerwidth; x++) {
		  px_itr = std::copy(pixelvalue[x], 
                                     pixelvalue[x] + cornerwidth, 
			             px_itr); 
		  px_itr = std::copy(pixelvalue[x] + pixelvalue.ny - cornerwidth,
                                     pixelvalue[x]+ pixelvalue.ny, 
			             px_itr); 
	  }
        }
                
        // Central cross.
	for (int icol=0; icol<ncols; icol++) {
	    px_itr =  std::copy(pixelvalue[icol] + nrows/2 - crosswid/2,
                                pixelvalue[icol] + nrows/2 + crosswid/2,
                                px_itr);
	}
	for (int icol=ncols/2-crosswid/2; icol<ncols/2+crosswid/2; icol++) {
	    px_itr =  std::copy(pixelvalue[icol],
                                pixelvalue[icol] + nrows/2 - crosswid/2,
                                px_itr);
	    px_itr =  std::copy(pixelvalue[icol] + nrows/2 + crosswid/2,
                                pixelvalue[icol] + nrows,
                                px_itr);
	}


        // Check 'nq' percentiles of array 'px', identify the value that is 
        // several consecutive percentiles, which indicates that value happens 
        // a lot.
	int nq = 30;
	vector<int> q(nq);

	for (int i=0; i<nq; i++) {
		nth_element(px.begin()+i*np/nq, px.begin()+np*(i+1)/(nq+1), px.end());
		q[i] = px[np*(i+1)/(nq+1)];
	}

	int ul = q[nq/4]; 

	if (q[nq-1]==q[nq-2] && q[nq-2]==q[nq-3]) {
		nth_element(px.begin(), px.begin()+np*(nq+2)/(nq+3), px.end());
		ul = px[np*(nq+2)/(nq+3)];
	} else {
		for (int i=nq-2; i>1; i--)
			if (q[i]==q[i-1] && q[i-1]==q[i-2]) { 
				ul = q[i+1]; break; 
			}
	}

/* NKS.  Add sanity check to make sure that no more than 10% of pixels
   are masked out. The most straightforward way is to copy the data to a new 
   container and use the nth_element algorithm. This is the only way to 
   insure that true background pixels are not masked out as underloads. 
   Two concerns: 1) nth_element might be time-consuming, so only use every 
   4th pixel. 2) want the algorithm to work equally well on circular & 
   square plates, so filter out everything but the inscribed circle.    
*/
        double cutof_frac = 0.1; /*arbitrary choice: no more than
                               10% of pixels should be masked as underloads*/
        double imagearea = pixelvalue.size();
        int speedup = 2;
        std::vector<int> sdata; sdata.reserve((int)imagearea/(speedup*speedup));
        if (image_geometry==CIRCLE) {
          for (int x=0; x<pixelvalue.nx; x+=speedup) {
            double half_chord = std::sqrt((imagearea/4-(ncols/2-x)*(ncols/2-x)));
            for (int y=(nrows/2)-(int)half_chord+1; 
                     y<(nrows/2)+(int)half_chord-1; y+=speedup){
              sdata.push_back(pixelvalue[x][y]);
            }
          }
        } else { 
          for (int x=0; x<pixelvalue.nx; x+=speedup) {
            for (int y=0; y<nrows; y+=speedup){
              sdata.push_back(pixelvalue[x][y]);
            }
          }
        }
        int n_cutoff = (int)((cutof_frac) * sdata.size());
        nth_element(sdata.begin(),sdata.begin()+n_cutoff,sdata.end());
        int n_cutoff_value = *(sdata.begin()+n_cutoff);
       
        return std::min(n_cutoff_value,ul);
}

void diffimage::pxlclassify()
{
	// *********************************************
	// Classify pixels into underloaded, background,
	// diffracted, overloaded, etc.
	//
	// Scan the image box by box.
	// **********************************************************

	pixelintensity = vector< vector<double> >(pixelvalue.nx, vector<double>(pixelvalue.ny, 0.0));

	for (int i=0; i<npxclassifyscan; i++) {
		if (scanboxsize[i] == 0) 
			continue;

		int xstart, xend, ystart, yend;

		int boxsize = scanboxsize[i];

                int x_box = boxsize;

                int y_box = boxsize;
		for (xstart = firstx;
                     xstart + x_box <= lastx; 
                     xstart += x_box) {
	             xend = xstart + x_box - 1;
	             for (ystart = firsty;
                          ystart + y_box <= lasty;
                          ystart += y_box) {
			  yend = ystart + y_box - 1;
			  pxlclassify_scanbox(xstart, xend, ystart, yend, bgupperint[i]);      
		     }
                }
	}
}

struct backplane {
 public:
  int boxnbg;
  double boxmean, boxvar, boxstd;
  double Sum_x,Sum_x2;  
  backplane(){ clear(); }
  virtual void accumulate (const int&, const int&, const int& px){
    Sum_x += px;
    Sum_x2 += (double)(px)*px;
    boxnbg++;
  }
  virtual void clear(){
    boxnbg = 0;
    boxmean = boxvar = boxstd = 0.;
    Sum_x = Sum_x2 = 0.;
  }
  virtual void reinitialize(const int&, const int&){
    clear();
  }
  virtual void finish(){
    boxmean = Sum_x/boxnbg;
    boxvar = Sum_x2/boxnbg - boxmean*boxmean;
    boxstd = std::sqrt(boxvar);
  }
  virtual inline double localmean (const int&, const int&) { 
    return boxmean; }
  virtual ~backplane(){}
};

#include <scitbx/mat3.h>

struct corrected_backplane: public backplane {
 private:
  int Sum_p2,Sum_pq,Sum_p,Sum_q2,Sum_q;
  double Sum_xp,Sum_xq;
  int xstart,ystart;
  double a,b,c;
  std::vector<int> rho_cache;
  std::vector<int> p_cache;
  std::vector<int> q_cache;
  double rmsd;
  double p,q; //temporary values
 public:
  corrected_backplane(const int& xst, const int& yst):
    xstart(xst),ystart(yst) {
    clear();
  }
  void reinitialize(const int& xst, const int& yst){
    xstart = xst; ystart = yst; clear();
  }
  inline void clear(){
    backplane::clear();
    Sum_p2=0;Sum_pq=0;Sum_p=0;Sum_q2=0;Sum_q=0;Sum_xp=0;Sum_xq=0;
    rho_cache.clear();
    p_cache.clear();
    q_cache.clear();
    rmsd=0.;
  }
  inline void accumulate(const int& x, const int& y, const int& px){
    backplane::accumulate(x,y,px);
    int p = x-xstart;
    int q = y-ystart;
    Sum_p2+=p*p;
    Sum_pq+=p*q;
    Sum_p+=p;
    Sum_q2+=q*q;
    Sum_q+=q;
    Sum_xp+=px*p;
    Sum_xq+=px*q;
    rho_cache.push_back(px);p_cache.push_back(p);q_cache.push_back(q);
  }
  inline void finish(){
    scitbx::mat3<double> rossmann(Sum_p2,Sum_pq,Sum_p,
                          Sum_pq,Sum_q2,Sum_q,
                          Sum_p,Sum_q,boxnbg);
    //scitbx::vec3<double> obs(Sum_xp,Sum_xq,Sum_x);
    scitbx::mat3<double> rinv = rossmann.inverse();
    // abc = rossmann.inverse()*obs;
    a = rinv[0]*Sum_xp + rinv[1]*Sum_xq +rinv[2]*Sum_x;
    b = rinv[3]*Sum_xp + rinv[4]*Sum_xq +rinv[5]*Sum_x;
    c = rinv[6]*Sum_xp + rinv[7]*Sum_xq +rinv[8]*Sum_x;
    for (int v=0; v<boxnbg; ++v){
      double bgobs_bgplane = rho_cache[v] - a*p_cache[v] - b*q_cache[v] -c;
      rmsd +=  bgobs_bgplane*bgobs_bgplane;
    }
    rmsd = std::sqrt(rmsd/boxnbg);
    boxstd=rmsd;
  }
  inline double localmean(const int&x, const int&y){
    return a*(x-xstart)+b*(y-ystart)+c;
  }
};

void diffimage::pxlclassify_scanbox(const int xstart, const int xend, 
  const int ystart, const int yend, const double intensity_bguppercutoff)
{
  // ******************************************************************************
  // if any corner of the box is outside of the image active area, then do not
  // scan the box
  // ******************************************************************************
  if (image_geometry==CIRCLE) {
    int iradius = pixelvalue.nx / 2;
    int iradius_sq = iradius*iradius;
    for (int x = xstart; x <= xend; x+=xend-xstart){
      for (int y = ystart; y <= yend; y+=yend-ystart){
        if ( (x-iradius)*(x-iradius) + (y-iradius)*(y-iradius) > iradius_sq )
          { return; }
      }
    }
  }
  // ******************************************************************************   
  // Calculate mean and std of all background pixels in the box.
  // Assign the calculated mean and std to each pixel in the box as its background.
  // Classify each pixel in the box based on this background.
  //
  // Expand the box if number of background pixels falls short of the required
  // amount.
  // ******************************************************************************

  const int speedup = 3;  // Sample from the window. No need to be exhaustive.
  const bool use_plane_correction = true;
  backplane* bp;
  if (use_plane_correction) { bp = new corrected_backplane(xstart,ystart); }
  else { bp = new backplane(); }

  const int nbgmin = (xend - xstart + 1) * (yend - ystart + 1) * 2/3
      /(speedup*speedup); 
  // Making 'nbgmin' reasonably small compared with the box size
  // is to avoid frequent need to expand the box due to shortage 
  // of background pixels.

  for (int x=xstart; x<=xend; x += speedup){
    for (int y=ystart; y<=yend; y += speedup){
      int px = pixelvalue[x][y];
      if (pixelintensity[x][y]<intensity_bguppercutoff && 
	  	px > underloadvalue &&
                (report_overloads || px < overloadvalue)) {
	        bp->accumulate(x,y,px);
      } 
    }
  }
  
  int xbox = xend - xstart + 1;
  int ybox = yend - ystart + 1;
  int halfincrease = min(xbox, ybox) / 3;
  int x0 = xstart;
  int y0 = ystart;

  while (bp->boxnbg<nbgmin) {
    // Usually this loop is skipped because
    // usually boxnbg > nbgmin.
    xbox += 2*halfincrease;
    if (xbox > 1000) {
      delete bp;
      std::cout<<"PXLCLASSIFY SCANBOX THROW"<<std::endl;
      throw;} //do not permit scanbox to increase without limit
    ybox += 2*halfincrease;
    x0 = min(max(0,x0-halfincrease), static_cast<int>(pixelvalue.nx - xbox));
    y0 = min(max(0,y0-halfincrease), static_cast<int>(pixelvalue.ny - ybox));
    // Whole image, rather than confined by firstx, firsty, lastx, lasty,
    // is used for scan.
    
    bp->clear();
    for (int x=x0; x<x0+xbox; x += speedup){
      for (int y=y0; y<y0+ybox; y += speedup){
	int px = pixelvalue[x][y];
	if (pixelintensity[x][y]<intensity_bguppercutoff && 
	    px > underloadvalue && 
            (report_overloads || px < overloadvalue)) {
          bp->accumulate(x,y,px);
	}
      }
    }
  }
  bp->finish();
  // Calculate pixel intensity.
  //
  // Intensity is calculated and assigned to the original box,
  // instead of the expanded box, if any.

  //avoid a divide-by-zero if the signal is flat
  double multfactor = bp->boxstd == 0. ? 0. : 1.0 / bp->boxstd;
  
  for (int x=xstart; x<=xend; x++) {
    for (int y=ystart; y<=yend; y++) {
      double bxmean = bp->localmean(x,y);
      pixelintensity[x][y] = (pixelvalue[x][y] - bxmean) * multfactor;
    }
  }
  delete bp;
}

void diffimage::search_icerings()
{
	// *************************
	// Detect ice-rings.
	// *************************

	double icermin, icermax;

	double dx1 = beam_x - firstx;
	double dx2 = lastx - beam_x;
	double dy1 = beam_y - firsty;
	double dy2 = lasty - beam_y;
	dx1 = dx1 * dx1;
	dx2 = dx2 * dx2;
	dy1 = dy1 * dy1;
	dy2 = dy2 * dy2;
	icermax = max(max(dx1+dy1, dx1+dy2), max(dx2+dy1, dx2+dy2));
	double temp = resol_to_r2(iceresolmin);
	if (temp > icermax)
		icermax = sqrt(icermax);
	else
		icermax = sqrt(temp);

	icermin = sqrt(resol_to_r2(iceresolmax));

	if (icermin >= icermax) return;


	// ring index increases as distance from ring to image center increases.
	// allocate one extra ring to avoid potential problems caused by weird (x,y) values.
	int nrings = static_cast<int>((icermax - icermin) / iceringwidth + 1);

	vector<int> ringnpx(nrings, 0);
	// Number of pixels on each ring.

	vector< vector<int> > ringcutoffnpx(nrings, vector<int>(nicecutoff, 0));
	// Number of pixels whose intensity exceeds the corresponding cutoff intensity values.


	// Sample every several pixels to save time.
	const int jump = 3;

	for (int x=firstx; x<=lastx; x = x + jump) {
		double dx = x - beam_x;
		for (int y=firsty; y<=lasty; y = y + jump) {
			double dy = y - beam_y;
			double r = sqrt(dx*dx + dy*dy);

			if (r > icermin && r < icermax) {
				int ringidx = static_cast<int>((r - icermin) / iceringwidth);
				if (ringidx < nrings) {
					ringnpx[ringidx] ++;
					int pixelint = int(pixelintensity[x][y]);

					for (int cutoffidx = 0; cutoffidx < nicecutoff; cutoffidx++) 
						if (pixelint >= icering_cutoffint[cutoffidx])
							ringcutoffnpx[ringidx][cutoffidx] ++;
				}
			}
		}
	}




	///////////////////////////////////////////
	// Record the ice-rings found.
	// Contiguous ice-rings are combined to be counted as one.
	///////////////////////////////////////////


	int lasticering = -3;


	for (int ringidx = 0; ringidx < nrings; ringidx++) {
		if (ringnpx[ringidx] < 30)
			continue;


		bool passed = true;
		double thisstrength = 0.0;

		for (int cutoffidx=0; cutoffidx<nicecutoff; cutoffidx++) { 
			double prct = static_cast<double>(ringcutoffnpx[ringidx][cutoffidx]) / ringnpx[ringidx];

			if(prct < icering_cutoffprct[cutoffidx]) {
				// Specified intensity dosn't reach required fraction. -- not ice.
				passed = false;
				break;
			} else {
				thisstrength += (prct - icering_cutoffprct[cutoffidx]) / 
					(1.0 - icering_cutoffprct[cutoffidx]) * icering_strength_cutweight[cutoffidx];
			}
		}


		if (passed) {
			double r1 = icermin + iceringwidth*ringidx;
			double r2 = r1 + iceringwidth;
			if (ringidx > lasticering+1) {
				// a new ice-ring, not continuous with the previous one.
				icerings.push_back(icering());
				icerings.back().lowerr2 = r1*r1;
				icerings.back().upperr2 = r2*r2;
				icerings.back().upperresol = r2_to_resol(r1 * r1);
				icerings.back().lowerresol = r2_to_resol(r2 * r2);
				icerings.back().strength = thisstrength;
				icerings.back().npx = ringnpx[ringidx];

			} else {
				// expand the last ice-ring.
				icerings.back().upperr2 = r2*r2;
				icerings.back().lowerresol = r2_to_resol(r2 * r2);
				icerings.back().strength = max(icerings.back().strength, thisstrength);
				icerings.back().npx += ringnpx[ringidx];

			}

			lasticering = ringidx;
		}

	}

}



bool diffimage::pixelisonice(const int x, const int y) const
{
	// ******************************************************************
	// Check whether or not a pixel in on an ice-ring.
	// This function is called only when ice-ring does exist on the image.
	// ******************************************************************

	double resol = xy2resol(x, y);

	for (vector<icering>::const_iterator q=icerings.begin(); q!=icerings.end(); q++) {
		if (resol >= q->lowerresol) {
			if (resol <= q->upperresol)
				return (true);
			else
				return (false);
		}
	}

	return (false);
}



void diffimage::search_maximas()
{
	// ********************************
	// Search for local maximas.
	// ********************************


	// A local maxima is a pixel which is a diffraction pixel 
	// whose value is not smaller than any of its 8 neighbors.

	int neighboramount = min(4, spotarealowcut-1);
	int diffnum = neighboramount - 1;

	for (int x=firstx+1; x<lastx; x++) {
		for (int y=firsty+1; y<lasty; y++) {

			if (pixelvalue[x][y] >= overloadvalue) {
				maximas.push_back(point(x, y, pixelvalue[x][y]));

			} else {
				double pxint = pixelintensity[x][y];
				int pxv = pixelvalue[x][y];

				if (pxint > difflowerint &&
					pxv >= pixelvalue[x-1][y-1] &&
					pxv >= pixelvalue[x][y-1] &&
					pxv >= pixelvalue[x+1][y-1] &&
					pxv >= pixelvalue[x-1][y] &&
					pxv >= pixelvalue[x+1][y] &&
					pxv >= pixelvalue[x-1][y+1] &&
					pxv >= pixelvalue[x][y+1] &&
					pxv >= pixelvalue[x+1][y+1]) {
					int goodneighbors = 
						(pixelintensity[x-1][y-1] > difflowerint) +
						(pixelintensity[x][y-1] > difflowerint) +
						(pixelintensity[x+1][y-1] > difflowerint) +
						(pixelintensity[x-1][y] > difflowerint) +
						(pixelintensity[x+1][y] > difflowerint) +
						(pixelintensity[x-1][y+1] > difflowerint) +
						(pixelintensity[x][y+1] > difflowerint) +
						(pixelintensity[x+1][y+1] > difflowerint); 
					if (goodneighbors > diffnum) { 
						maximas.push_back(point(x, y, pxv));
					}
				}
			}
		}
	}

}


void diffimage::search_spots()
{
	// ************************************************
	// Search for spots. 
	// Record area and calculate intensity of each spot.
	//
	// Every maxima belongs to a unique spot; but
	// one spot could have multiple maximas, depending
	// on whether neighborhoods of two maximas are
	// connnected, in which case both maximas are
	// enclosed in one single spot.
	// ************************************************

	const double PI = 3.14159265;
	
	vector< vector<bool> > pixelvisited(pixelvalue.nx, vector<bool>(pixelvalue.ny, false));
	for (point_list_t::iterator p=maximas.begin(); p!=maximas.end(); p++) {
		if (pixelvisited[p->x][p->y]) 
			continue;

		spots.push_back(spot());

		search_border_spot(p->x, p->y, spots.back(), pixelvisited);
//NKS May '06 it seems correct that no overload checking is done here, but there is 
// another place where overloaded maxima are removed.  It is not known if
// this will adversely affect saturation checking.

		if (spots.back().bodypixels.size() < spotarealowcut) {
			// Discard this spot if smaller than specified threshold.

			spots.pop_back();
		} else {
			// Discard this spot if any of its pixel lies on an ice-ring.
			
			if (~icerings.empty()) {
				for (point_list_t::const_iterator q=spots.back().borderpixels.begin();
						q!=spots.back().borderpixels.end(); q++) {
					if (pixelisonice(q->x, q->y)) {
						spots.pop_back();
						break;
					}
				}
			}
		}
	}

	if (spots.empty())
		return;

	// Calculate spot properties.
	
	vector< vector<bool> > pixelismaxima(pixelvalue.nx, vector<bool>(pixelvalue.ny, false));
	for (point_list_t::const_iterator p=maximas.begin(); p!=maximas.end(); p++)
		pixelismaxima[p->x][p->y] = true;

	for (list<spot>::iterator p=spots.begin(); p!=spots.end(); p++) {

                p->find_weighted_center(pixelvalue,pixelismaxima);

		int peakv = 0;
		for (point_list_t::const_iterator q = p->maximas.begin(); q != p->maximas.end(); q++) {
			if (q->value > peakv) {
				p->peak = *q;
				peakv = q->value;
			}
		}
        
		// If all maximas are close together, view it as a single-maxima spot.
		if (p->maximas.size() > 1) {
			bool allclose = true;
			for (point_list_t::const_iterator q = p->maximas.begin(); q != p->maximas.end(); q++) {
				if (q->x - p->peak.x > 2 || q->x - p->peak.x < -2 ||
					q->y - p->peak.y > 2 || q->y - p->peak.y < -2) {
					allclose = false;
					break;
				}
			}
			if (allclose) {
				p->maximas.clear();
				p->maximas.push_back(p->peak);
			}
		}


		p->peakresol = xy2resol(p->peak.x, p->peak.y);

	}

    //check intensity cutoff
#if 0
	list<spot> local_copy_of_spots = spots;
    spots.clear( );
	for (list<spot>::iterator p=local_copy_of_spots.begin(); p!=local_copy_of_spots.end(); p++) {
        if (p->peak.value >= spotintensitycut)
        {
            spots.push_back( *p );
        }
    }
#else
    // Nick Sauter:
    // The above contains a bug because the function erase(p) invalidates 
    // the iterator p, so the behavior of --p is undefined.
    // The code may be corrected by using the return value of erase(p), 
    // which is a new iterator pointing to the element after p:
    // invalid after erase is called.
    { //establish local scope for p
    list<spot>::iterator p=spots.begin();
    while ( p!=spots.end() ){
      if (p->peak.value < spotintensitycut){
        p = spots.erase( p ); //see Austern, Generic Programming and the STL (1999), pp 138-9
      } else {
	++p;
      } 
    }
    }

#endif

    if (spots.size() > 0) {
	    search_neighbor_spots();
    }
}

void diffimage::spotshape() {
        // spotshape analysis by Qingping 10/22/2004
        // calculate max and min distance between border and center

	double PI=3.1415926;
	shape_mean=5; // shape based on Dmax/Dmin ratio
	shape_median=5; // shape based on Dmax/Dmin ratio
	shape_sd=1; // shape based on Dmax/Dmin ratio
	
	ellip_mean=5;
	ellip_median=5;
	ellip_sd=1;

	int nicerings=icerings.size();
	double Lresol=25.;
	double Hresol=2.0;
	if(nicerings>2) { 
	    Hresol=3.8;
	}

    if (spots.size() == 0) return;

        vector<double> vec_DmaxminRatio;
        for (list<spot>::iterator p=spots.begin(); p!=spots.end(); p++) {
                double d2min=99999;
                double d2max=-99999;

                if ( p->peakresol < Lresol && p->peakresol >= Hresol) {
                        for (point_list_t::const_iterator q=p->borderpixels.begin(); q!=p->borderpixels.end(); q++) {
                                double dist2 = (q->x - p->centerx)*(q->x - p->centerx) \
                                        + (q->y - p->centery)*(q->y - p->centery);
                                if ( dist2 < d2min) d2min=dist2;
                                if ( dist2 > d2max) d2max=dist2;
                        }
                        double dratio=sqrt(d2max/d2min);
                        //cout<<"dratio="<<dratio<<endl;
                        if(dratio>8.0) dratio=8.0; // limit extreme contributions
                        vec_DmaxminRatio.push_back(dratio);
                        p->dmaxminRatio=dratio;
                }
        }

        if (vec_DmaxminRatio.size() == 0) return;

        sort(vec_DmaxminRatio.begin(),vec_DmaxminRatio.end());
        int len=vec_DmaxminRatio.size();
        int middle=static_cast<int>(len/2.0);

	if (len<=5) return; // return if no spots between 15-4.5A

        double avgDratio=0.;
        for(int i=len-1; i>=0;i--) {
                avgDratio+= vec_DmaxminRatio[i];
        }
        avgDratio/= len;  
	double sdratio=0.;
	for(int i=0; i<len;i++) {
		sdratio+=(vec_DmaxminRatio[i]-avgDratio)*(vec_DmaxminRatio[i]-avgDratio);
	}
	sdratio=sqrt(sdratio/(len-1));

	shape_mean=avgDratio; // nomalize to close to 1 for excellent spots
	shape_median=vec_DmaxminRatio[middle];
	shape_sd=sdratio;
        //cout<<" mean="<<avgDratio<<" median="<<vec_DmaxminRatio[middle]<<" sd="<<sdratio<<endl;

	// additional parameters
	double avg_ellipratio=0,avg_theta=0,nspt=0.;
	bool weight=true;
	vector<double> vec_ellipratio;
        for (list<spot>::iterator p=spots.begin(); p!=spots.end(); p++) {
                double m00 = 0.0; //moments, m00 is area
                double m10 = 0.0; 
                double m01 = 0.0;
		double m20 = 0.0;
		double m02 = 0.0;
		double m11 = 0.0;
		// option 1, using border pixels only
                // for (point_list_t::const_iterator q=p->borderpixels.begin(); q!=p->borderpixels.end(); q++) {
		// option 2, using all body pixels
               	for (point_list_t::const_iterator q=p->bodypixels.begin(); q!=p->bodypixels.end(); q++) {
                        double pxv = static_cast<double>(pixelvalue[q->x][q->y]); 
			if(!weight) pxv=1.;
			double x=q->x;
			double y=q->y;
			m00 += pxv;
			m10 += pxv*x;
			m01 += pxv*y;
			m20 += pxv*x*x;
			m02 += pxv*y*y;
			m11 += pxv*x*y;
		}
        if (m00==0) return;
		double cenx=m10/m00; // geometric center x
		double ceny=m01/m00;

		double u00=m00; // central moments
		double u10=0.0;
		double u01=0.0;
        if ((m00-cenx*cenx) == 0 ||
            (m00-ceny*ceny) == 0 ||
            (m00-cenx*ceny) == 0) return;
		double u20=m20/m00-cenx*cenx;
		double u02=m02/m00-ceny*ceny;
		double u11=m11/m00-cenx*ceny;

		/*
		double m00square=m00*m00;
		double m003by2=sqrt(pow(m00,3));
		double v00=1.0; // normalized central moments, independent on spot size
		double v10=u10/m003by2;
		double v01=u01/m003by2;
		double v20=u20/m00square;
		double v02=u02/m00square;
		double v11=u11/m00square;
		cout<<"v00="<<v00<<" v10="<<v10<<" v01="<<v01<<" v20="<<v20<<" v02="<<v02<<" v11="<<v11<<endl;
		*/

		double f1=u02+u20;
		double f2=sqrt((u02-u20)*(u02-u20)+4*u11*u11);
		
		double alpha=sqrt(2*(f1+f2)); // main ellipoid axis
		double beta =sqrt(2*(f1-f2)); // minor ellipoid axis
		//cout << (alpha*beta*3.1415)<<"="<<m00<<endl; // verify the ellipoid area is (close to) m00
		double theta=atan(2*u11/(u20-u02+0.001))/2.0; // added a small number to avoid zero division
		theta *= 180/PI; // convert it to degrees

        if (beta == 0) return;
		p->ellipoidRatio=alpha/beta;
		//eccentricity; 0 for disk, 1 for line; less reliable
		//double eccentricity=sqrt(4*u11*u11+(u02-u20)*(u02-u20))/(u02+u20); 
		// compactness, 1 for disk
		// p->compactness=1.0/f1;
		
                if ( p->peakresol < Lresol && p->peakresol >= Hresol) {
			vec_ellipratio.push_back(p->ellipoidRatio); 
			avg_ellipratio+=p->ellipoidRatio;
			avg_theta+=theta;
			nspt+=1.;
		}
	}

        //int len=vec_ellipratio.size();
        //int middle=static_cast<int>(len/2.0);
	//if (len<=5) return; // return if no spots between 15-4.5A

	// calculate average for the whole image
	avg_ellipratio/= nspt;
	avg_theta/= nspt;
	
	// calculate median,standard derivation
	sort(vec_ellipratio.begin(),vec_ellipratio.end());
	int halfsize=static_cast<int> (nspt*0.5);
	double median=vec_ellipratio[halfsize];

	double sd=0.0; // standard derivation
	for(int i=0;i<nspt;i++) {
		sd= sd+ (vec_ellipratio[i]-avg_ellipratio)*(vec_ellipratio[i]-avg_ellipratio);
	}
	sd=sqrt(sd/(nspt-1.0));
	//cout<<" mean="<<avg_ellipratio<<" median="<<median<<" sd="<<sd<<endl;

	ellip_mean=avg_ellipratio;
	ellip_median=median;
	ellip_sd=sd;
}

#include <stack>
void diffimage::search_border_spot(const int x, const int y, spot& curspot, 
                                   vector< vector<bool> >& pixelvisited) {

  std::stack<point> Q;
  Q.push(point(x,y,pixelvalue[x][y]));
  while (!Q.empty()) {
    point pt = Q.top();
    Q.pop();
    if (pixelvisited[pt.x][pt.y]) {continue;}
    if (pt.x < firstx || pt.x > lastx || pt.y < firsty || pt.y > lasty)
      {continue;}
    pixelvisited[pt.x][pt.y] = true;
    if (pixelintensity[pt.x][pt.y] <= difflowerint) {
      // Hit a nighboring pixel, which does not belong to 
      // this spot. Record border pixels and return.
      curspot.borderpixels.push_back(pt);
      // From this step it is clear that a border pixel
      // is one that is bordering a spot, but does not
      // belong to the spot, i.e, is not counted in the
      // spot area.
      // Perimeter is number of such border pixels.
    } else {
      // An interior pixel on the spot.
      // Label current pixel and search on.
      curspot.bodypixels.push_back(pt);
      Q.push(point(pt.x-1,pt.y-1,pixelvalue[x-1][y-1]));
      Q.push(point(pt.x  ,pt.y-1,pixelvalue[x]  [y-1]));
      Q.push(point(pt.x+1,pt.y-1,pixelvalue[x+1][y-1]));
      Q.push(point(pt.x-1,pt.y,  pixelvalue[x-1][y]  ));
      Q.push(point(pt.x+1,pt.y , pixelvalue[x+1][y]  ));
      Q.push(point(pt.x-1,pt.y+1,pixelvalue[x-1][y+1]));
      Q.push(point(pt.x  ,pt.y+1,pixelvalue[x]  [y+1]));
      Q.push(point(pt.x+1,pt.y+1,pixelvalue[x+1][y+1]));
    }
  }
}

void diffimage::search_overloadpatches()
{
	vector< vector<bool> > pixelvisited(pixelvalue.nx, vector<bool>(pixelvalue.ny, false));

	for (point_list_t::iterator p=maximas.begin(); p!=maximas.end(); p++) {
		if (!pixelvisited[p->x][p->y]) {
			if (pixelvalue[p->x][p->y] >= overloadvalue) {

				// If maxima is overloaded, search for a overloaded patch.
				overloadpatches.push_back(spot());
				search_border_overload(p->x, p->y, overloadpatches.back(), pixelvisited);

				// Remove this maxima from maxima list.
				p = maximas.erase(p); //Bug fix by Nick Sauter
				p--;
      			} 
		}
	}
}


void diffimage::search_border_overload(const int x, const int y, spot& curspot, 
                                   vector< vector<bool> >& pixelvisited)
{
	// One possible undesirable situation is that a spot is found 
	// bordering an overload patch. 
	// But it is unlikely to happen often.

  if (pixelvisited[x][y])
    return;

  if (x<firstx || x>lastx || y<firsty || y>lasty)
    // out of image border
    return;

  pixelvisited[x][y] = true;

  if (pixelvalue[x][y]<overloadvalue) {
    // Hit a nighboring pixel, which does not belong to 
    // this spot. Record border pixels and return.
   
    curspot.borderpixels.push_back(point(x, y, pixelvalue[x][y]));

    // From this step it is clear that a border pixel
    // is one that is bordering a spot, but does not
    // belong to the spot, i.e, is not counted in the
    // spot area.
    // Perimeter is number of such border pixels.
  } else {
    // An interior pixel on the spot.
    // Label current pixel and search on.
 
    curspot.bodypixels.push_back(point(x, y, pixelvalue[x][y]));

    //search_border_overload(x-1, y-1, curspot, pixelvisited);
    search_border_overload(x,   y-1, curspot, pixelvisited);
    //search_border_overload(x+1, y-1, curspot, pixelvisited);
    search_border_overload(x-1, y,   curspot, pixelvisited);
    search_border_overload(x+1, y,   curspot, pixelvisited);
    //search_border_overload(x-1, y+1, curspot, pixelvisited);
    search_border_overload(x  , y+1, curspot, pixelvisited);
    //search_border_overload(x+1, y+1, curspot, pixelvisited);
  }
}




void diffimage::search_neighbor_spots()
{
	const double PI = 3.14159265;

	vector<double> spotperimeter;
	spotperimeter.reserve(spots.size());
	for (list<spot>::const_iterator p = spots.begin(); p != spots.end(); p++)
		spotperimeter.push_back( p->borderpixels.size() );

	int upperidx = static_cast<int>( (spots.size() - 1) * 0.95 );
	nth_element(spotperimeter.begin(), spotperimeter.begin() + upperidx, spotperimeter.end());
	double upperperimeter = spotperimeter[upperidx];
	double mindist = upperperimeter / PI * spotdistminfactor;


	// Sort spots in increasing order of spot's X location.
	spots.sort( cmpspotx() );

	
	for (list<spot>::iterator p = spots.begin(); p != spots.end(); p++) {
		list<spot>::iterator q = p;
		for (q++; q != spots.end(); q++) {
			// Since q is closest to p in X direction,
			// if they're far apart in X direction,
			// no other spot will come closer.
			// In this case, p has no close neighbor.
			
			if (q->peak.x - p->peak.x > mindist)
				break;

			// q and p are close in X direction but far apart
			// in Y direction.
			// There could be spots that are slightly farther
			// in X direction but close in Y direction.
			// Check them out.
			
			if (q->peak.y - p->peak.y > mindist ||
				p->peak.y - q->peak.y > mindist)
				continue;

			double dist = (q->peak.x - p->peak.x) * (q->peak.x - p->peak.x) +
				(q->peak.y - p->peak.y) * (q->peak.y - p->peak.y);
			double localmindist = max(p->borderpixels.size(), q->borderpixels.size()) / 
				PI * spotdistminfactor;
			localmindist = localmindist * localmindist;

			if (dist <= localmindist) {
				// q and p are close enough.
				// Both are marked to be deleted.
				// Continue to check other neighbors.

				p->ncloseneighbors ++;
				q->ncloseneighbors ++;
			}
		}
	}

}

void diffimage::diffscore() { // generate a score from 1 to 10 
	double score=0.0;

	// resolution
	if( imgresol_wilson >20 ) {
		score=score-2;
	} else if ( imgresol_wilson <20 && imgresol_wilson >=8 ) {
		score=score+1;
	} else if ( imgresol_wilson <8 && imgresol_wilson >=5 ) {
		score=score+2;
	} else if ( imgresol_wilson <5 && imgresol_wilson >=4 ) {
		score=score+3;
	} else if ( imgresol_wilson <4 && imgresol_wilson >=3.2 ) {
		score=score+4;
	} else if ( imgresol_wilson <3.2 && imgresol_wilson >=2.7 ) {
		score=score+5;
	} else if ( imgresol_wilson <2.7 && imgresol_wilson >=2.4 ) {
		score=score+7;
	} else if ( imgresol_wilson <2.4 && imgresol_wilson >=2.0 ) {
		score=score+8;
	} else if ( imgresol_wilson <2.0 && imgresol_wilson >=1.7 ) {
		score=score+10;
	} else if ( imgresol_wilson <1.7 && imgresol_wilson >=1.5 ) {
		score=score+12;
	} else {
		score=score+14;
	}

	// diffraction strength
	if ( MaxPixelValue15to4 >= 40000) {
		score=score+2;
        } else if (MaxPixelValue15to4 <40000 && MaxPixelValue15to4>=15000) {
		score=score+1;
        }

	// ice rings
        int nicering=icerings.size();
	if (nicering>=4 && score>3) { 
		score=score-3;
	} else if (nicering<4 && nicering>=2 && score >2) {
		score=score-2;
	} else if (nicering<2 && nicering>0 && score >1) {
		score=score-1;
        }

	// penalize bad spots and award really good ones
	if (ellip_mean > 2.0) score=score-2;
	if (ellip_sd > 1.0) score=score-2;
	if (ellip_median<1.35 && ellip_sd<0.4) score=score+2;

	if (score <0.1 ) {
		if (imgresol_wilson >20.0) {
			score=0;
		} else {
			score=1; // anything diffracts at least have a score of 1
		}
	} 
	imgscore=score;
	//cout<<"Image score= "<<imgscore<<endl;
}

void diffimage::diffstrength() { // analysis diffraction strength of an image
        vector<int> spotintensity;

	// maximum pixel value between 15.0-4.0A 
	float resolution_lowbnd=15.0;
	float resolution_uppbnd=4.0;
        for (list<spot>::const_iterator p = spots.begin(); p != spots.end(); p++) {
		if ( p->peakresol < resolution_lowbnd && p->peakresol >= resolution_uppbnd ) {
			//cout<<p->peakresol<<endl;
			spotintensity.push_back(p->peak.value);	
		}
        }
        // Sort intensities from increasingly
        std::sort(spotintensity.begin (), spotintensity.end ());

        //Display the results.
        //std::cout << "Sorted intensities" << std::endl;
        //for (vector<int>::iterator i = spotintensity.begin(); i != spotintensity.end (); i++)
        //    std::cout << *i <<std::endl;

	if(spotintensity.size()>=1) {
		MaxPixelValue15to4=*(spotintensity.end()-1);
		MinPixelValue15to4=*(spotintensity.begin());
	} else {
		MaxPixelValue15to4=0;
		MinPixelValue15to4=0;
	}
}

void diffimage::imgresolution2()  
/* a new image resolution estimator by Qingping Oct 20, 2004
   the imgresolution() works well for high resolution image with many spots
   does not work well for low resol images with only a few spots; this method
   aim to be foolproof but not aiming to get an accurate estimation of resolution
   
   This method works as follows:
   1. figure out the spots with smallest average intensity value, this will be
	serve as background, B
   2. divide the spots in two shells with equal volume reciprocal bins
   3. calculate average intensity for each resolution shell
	sum(intensity)/nspots/B
   4. calculate averge signal/noise ratio (SNR) for each bin
   5. work from low resolution to high resolution, select resolution cutoff 
	if SNR<threshhold
*/
{
	int nShells=17;
	double resRanges[18]={45.0, 5.50, 3.90, 3.19, 2.78, 2.53, 2.35, 2.21, 2.10,2.0,1.9,1.8,1.7,1.6,1.5,1.4,1.3,1.2}; 
        double sumi[17],sumir[17], sumr[17],SNR[17];
        double spts[17];
        double iMin=65535.0; // store lowest accumulated intensity for a spot, averaged pixel pixel
	double resBest[17]; // store the resolution of the spot with best resolution inside each bin
        
        for(int i=0; i<nShells; i++) {
		sumi[i] =0.01;
		sumr[i] =0.0;
		sumir[i]=0;
                spts[i]=1;  // initiallize to 1 in order to avoid division by zero
		resBest[i]=99.0;
        }

	//double avgRes=0; // calculated I weighted overall resolution
	//double sumI=0.0;
        for (list<spot>::const_iterator p = spots.begin(); p != spots.end(); p++) {
		double avgPixelIntensity=p->total_intensity()/(double)p->area();
                if ( avgPixelIntensity < iMin ) {
			iMin=avgPixelIntensity;
                }
		for(int i=0; i<nShells; i++) {
       			if ( p->peakresol<= resRanges[i] && p->peakresol > resRanges[i+1]) {
				sumi[i]=sumi[i]+avgPixelIntensity;
				spts[i]+=1.0;
				sumir[i]=sumir[i]+avgPixelIntensity*p->peakresol; // weighted resolution range
				sumr[i] =sumr[i] +p->peakresol;                     // unweighted resolution average
				if (p->peakresol<resBest[i]) resBest[i] = p->peakresol;
			}
		}
        }
	//double OverallavgRes=avgRes/sumI;
	//cout<<"Overall weighted resolution="<<OverallavgRes<<endl;

	double SNRcutoff= 1.2;
	double SNRratioCutoff= 1.5; // SNR of two neighour shells: the outshell should be smaller in general 
	double SptRatioCutoff = 4 ; // the # of spots with each shell should be stay with this ratio
	
        for(int i=0; i<nShells; i++) {
		SNR[i]=sumi[i]/spts[i]/iMin;
		sumir[i]=sumir[i]/sumi[i];
		sumr[i]=sumr[i]/spts[i];
		//cout<<"Sum(I)= "<<sumi[i]<<" Nspots="<<spts[i]<<" SNR="<<SNR[i] \
                    <<" Rbest="<<resBest[i]<<" RwI="<<sumir[i]<<" R="<<sumr[i]<<endl;
        }

	imgresol_wilson=99;
        //if (spts[0] < 12 || spts[0]+spts[1] < 24 || sumi[0]/spts[0] < SNRcutoff ) {
        if (spts[0] < 12 || sumi[0]/spts[0] < SNRcutoff ) {
		imgresol_wilson=99.0;	
		return;
        }
	int MinShellSpot=  30; // minimum number of reflection per shell
	if (icerings.size()>=4 ) { // if there are bad ice rings, set min spots higher
		MinShellSpot=50;   // since in first shell, there is no ice, so no increase
	}
        for(int i=1; i<nShells; i++) {
		double SR=spts[i]/spts[i-1];
		//cout <<" SNR="<<SNR[i]<<" SR="<<SR<<" Nspots "<<spts[i]<<endl;
		if (SNR[i] < SNRcutoff || SNR[i]/SNR[i-1] > 1.4  || spts[i] < MinShellSpot || \
			SR > SptRatioCutoff || SR < 1.0/SptRatioCutoff) {
			imgresol_wilson=(resBest[i-1]+sumir[i-1])/2.0;
		  	//cout<<"Best resolution = " <<imgresol_wilson<<endl;
			return;
                }
        } // end
	imgresol_wilson=1.0;
}

void diffimage::imgresolution()
{
	const double PI = 3.14159265;

	imgresol_unispot = 99.0;
	imgresol_unispace = 99.0;
	imgresol_unispot_curvebadness = 1.0;
	imgresol_unispace_curvebadness = 1.0;

	const int nspotmin = 25;
	if (spots.size() <= nspotmin)
		return;

	/////////////////////////////////////////
	// Calulate corner modifiers
	// to be used to adjust amount of spots.
	/////////////////////////////////////////


	// Resolution and corner factor of each spot.
	vector<double> spotresol;
	vector<int> spotcornerfactor;
	spotresol.reserve(spots.size());
	spotcornerfactor.reserve(spots.size());

	// Largest radius with complete circle on the image
	int commonr = min(min(beam_x-firstx, lastx-beam_x), 
					min(beam_y-firsty, lasty-beam_y));
	double rupper = beam_x - firstx;
	double rlower = lastx - beam_x;
	double rleft = beam_y - firsty;
	double rright = lasty - beam_y;

	// Ignore spots with 2 * theta < 2.9 degrees.
	const double resolupperbnd = twotheta_to_resol(2.9 / 180.0 * PI);

	for (list<spot>::const_iterator p = spots.begin();
			p != spots.end(); p++) {

		// Don't consider spots that are 
		//    overloaded or
		//    2 * theta < 2.9 degreed, i.e., too close to beam center.
		if (p->peak.value >= overloadvalue || p->peakresol > resolupperbnd)
			continue;
			
	
		spotresol.push_back(p->peakresol);

		double dx = p->peak.x - beam_x;
		double dy = p->peak.y - beam_y;
		double r = sqrt(dx*dx + dy*dy);
		if (r < commonr) {
			spotcornerfactor.push_back(1);
		} else {
			double goodang = 2.0 * PI;

			if (r > rupper)
			goodang -= 2.0 * acos(rupper/r);
			if (r > rright)
			goodang -= 2.0 * acos(rright/r);
			if (r > rlower)
			goodang -= 2.0 * acos(rlower/r);
			if (r > rleft)
			goodang -= 2.0 * acos(rleft/r);

			if (goodang < 1e-2)
				goodang = 1e-2;

			spotcornerfactor.push_back(static_cast<int>(2.0*PI/goodang));
		}
	}	

	// Order spots from low to high resolution
	sort(spotresol.begin(), spotresol.end(), greater<double>());




	// Duplicate spots whose cornerfactor is greater than 1.
	int nspots = accumulate(spotcornerfactor.begin(),spotcornerfactor.end(),0);

	// If there are spots in the corners,
	// copy corner spots to make total number of spots the expected amount.
	// This insertion does not change the fact that the vector is ordered.
	if (nspots > spotcornerfactor.size()) {
		spotresol.reserve(nspots);
		for (int sptidx=spotresol.size()-1; sptidx>=0; sptidx--) {
			if (spotcornerfactor[sptidx]>1)
				spotresol.insert(spotresol.begin()+sptidx,
						spotcornerfactor[sptidx]-1,spotresol[sptidx]);
		}
	}


	// If there're fewer than 25 spots lower than 4 Angstrom.
	// Otherwise we will get divide by zero below.
	if (spotresol.size() <= 25 || spotresol[24] < 4.0) {
		return;
	}
		

	int nimgresolrings;


	//
	// Curve for Method 1:
	//   evenly divide number of spots, check trend of resolution
	//
	
	nimgresolrings = min(40, static_cast<int>(spotresol.size() / nspotmin));
	int nspotring = spotresol.size() / nimgresolrings;

	// resolution at the outer border of each ring. 
	imgresol_unispotresols = vector<double>(nimgresolrings); 
	vector<double> imgresol_unispotresolspow(nimgresolrings);

	for (int ringidx=0; ringidx<nimgresolrings; ringidx++) {
		int idx = (ringidx + 1) * nspotring - 1;
		imgresol_unispotresols[ringidx] = spotresol[idx];
		imgresol_unispotresolspow[ringidx] = pow(imgresol_unispotresols[ringidx], imgresolringpow);
	}


	/*
	vector<double> ringresolpowsmooth(imgresol_unispotresolspow.size());

	vector<double> ringindices(imgresol_unispotresolspow.size());
	for (int ringidx=0; ringidx<imgresol_unispotresolspow.size(); ringidx++)
		ringindices[ringidx] = static_cast<double>(ringidx);
	ksmooth(ringindices, ringresolpow, ringindices, ringresolpowsmooth, smoothspan);
	*/



	// Slope of line connecting 1st and each other ring.
	vector<double> slope(imgresol_unispotresolspow.size());
	slope[0] = 0;
	for (int ringidx=1; ringidx<imgresol_unispotresolspow.size(); ringidx++) 
		slope[ringidx] = (imgresol_unispotresolspow[ringidx] - 
				imgresol_unispotresolspow[0]) / ringidx;


	// Badness of the curve in Method 1
	// The spots should be more and more sparse as one moves from beam center outwards.
	// Badness of the curve measures violation of this trend.


	// Number of possible pairwise comparisons.
	int ntotalcomb = (slope.size() - 1) * (slope.size() - 2) / 2;
	if (slope.size() > 1 && ntotalcomb > 0) {
		int nbadcomb = 0;

		for (int ringidx = 1; ringidx < slope.size()-1; ringidx++) {
			for (int idx = ringidx+1; idx < slope.size(); idx++) {
				if (slope[idx] <= slope[ringidx])
					nbadcomb ++;
			}
		}

		imgresol_unispot_curvebadness = static_cast<double>(nbadcomb) / ntotalcomb;
	}



	//
	// Curve for Method 2:
	//   evenly divide reciprocal resolution space, check number of spots 
	//
	

	double resolpowmin = pow(spotresol[0] + 0.1, imgresolringpow);
	
	// Plus a little for convenience in the following process.
	// No need to worry about overflow.
	double resolpowmax = pow(spotresol.back() + 0.1, imgresolringpow);

	int ringspotcount0 = max(nspotmin, static_cast<int>(spotresol.size() / 20));

	double resolpowstep = pow(spotresol[ringspotcount0 - 1], imgresolringpow) 
		- resolpowmin;

	nimgresolrings = max( 8, min(30, static_cast<int>((resolpowmax - resolpowmin) / resolpowstep)) );

	resolpowstep = (resolpowmax - resolpowmin) / nimgresolrings;


	imgresol_unispaceresols = vector<double>(nimgresolrings, 0.0);
	for (int ringidx = 0; ringidx < nimgresolrings; ringidx++) {
		imgresol_unispaceresols[ringidx] = pow( resolpowmin + (ringidx + 1) * resolpowstep, 
				1.0/imgresolringpow );
	}

	imgresol_unispacespotcounts = vector<int>(nimgresolrings, 0);
	int curspotidx = 0;


	// Notice that spotresol is ordered from large to small.
	for (int ringidx = 0; ringidx < nimgresolrings; ringidx++) {
		while (spotresol[curspotidx] >= imgresol_unispaceresols[ringidx]) {
			imgresol_unispacespotcounts[ringidx] ++;
			curspotidx ++;
		}

	}



	// Badness of the curve in Method 2
	// Number of spots should decrease as one moves from beam center outwards.
	// Badness of the curve measures violation of this trend.

	// Number of possible pairwise comparisons.
	ntotalcomb = imgresol_unispacespotcounts.size() * (imgresol_unispacespotcounts.size() - 1) / 2;
	if (ntotalcomb > 0) {
		int nbadcomb = 0;
		for (int ringidx=1; ringidx < imgresol_unispacespotcounts.size()-1; ringidx++) {
			for (int idx=ringidx+1; idx<imgresol_unispacespotcounts.size(); idx++) {
				if (imgresol_unispacespotcounts[idx] >= imgresol_unispacespotcounts[ringidx])
					nbadcomb ++;
			}
		}

		imgresol_unispace_curvebadness = static_cast<double>(nbadcomb) / ntotalcomb;
	}



	// If there're fewer than 25 spots lower than 4 Angstrom.
	
	if (spotresol.size() <= 25 || spotresol[24] < 4.0) {
		return;
	}




	// Method 1

	
	if (slope.size() > 4) {

		int maxslopeidx = 0;
		for (int ringidx=1; ringidx<slope.size(); ringidx++) {
			if (slope[ringidx] > slope[maxslopeidx])
				maxslopeidx = ringidx;
		}


		//int maxslopeidx = distance(slope.begin(), max_element(slope.begin(),slope.end()));

		double a = slope[maxslopeidx];
		double b = imgresol_unispotresolspow[0];
		vector<double> gap(maxslopeidx+1);
		int bendidx = 0;
		for (int ringidx=0; ringidx<=maxslopeidx; ringidx++) {
			gap[ringidx] = a*ringidx+b - imgresol_unispotresolspow[ringidx];
			if (gap[ringidx] > gap[bendidx])
				bendidx = ringidx;
		}
		//int bendidx = distance(gap.begin(), max_element(gap.begin(),gap.end()));

		double temp1 = 0;
		double temp2 = 0;
		for (int ringidx=0; ringidx<=maxslopeidx; ringidx++) {
			temp1 += gap[ringidx];
			temp2 += gap[ringidx] * gap[ringidx];
		}
		temp1 /= (maxslopeidx + 1.0);
		temp2 /= (maxslopeidx + 1.0);
		double gapstd = sqrt(temp2 - temp1*temp1);


		double gapmax = gap[bendidx];
		double gapcutoff = gapmax - imgresol_unispot_shiftfactor * gapstd;

		for (int ringidx=bendidx; ringidx<=maxslopeidx; ringidx++) {
			if (gap[ringidx] >= gapcutoff)
				bendidx = ringidx;
			else
				break;
		}

		imgresol_unispot = imgresol_unispotresols[bendidx];
	}



	//
	// Method 2:
	//


	int cutofffrac = int((imgresol_unispacespotcounts[0] * 0.5 + imgresol_unispacespotcounts[1] * 0.5) * imgresol_unispace_cutoff_fraction);

	if (cutofffrac >= 2) {

		// Walk through bins until spot count drops below the threshold.

		for (int ringidx = 2; ringidx < imgresol_unispacespotcounts.size() - 1; ringidx++) {
			if ( (imgresol_unispacespotcounts[ringidx] < cutofffrac &&
				imgresol_unispacespotcounts[ringidx+1] < cutofffrac) ||
				ringidx == imgresol_unispacespotcounts.size() - 2) {
				imgresol_unispace = pow(resolpowmin + resolpowstep * ringidx, 1.0/imgresolringpow);
				break;
			}
		}
	}

}



//inline double diffimage::r2_to_resol(const double r2) const
double diffimage::r2_to_resol(const double r2) const
{
  // ********************************************
  // Determine resolution from squared radius.
  // This function is the reverse of resol_to_r2.
  // ********************************************

  // Calculation of resolution:
  //
  // d = lambda / (2*sin(theta))
  // sin(theta) = sqrt( 1/2 - 1/(2 * sqrt(1+(h/L)^2)) )
  // lambda: wavelength
  // h: distance from spot to beam center
  //    h^2 = ( (x-beam_x)^2 + (y-beam_y)^2 ) * pixel_size^2
  // L: distance from detector to crystal
  // ====>
  //    d = lambda / sqrt( 2 - 2/sqrt(1 + h^2/L^2) )
  //      = wavelength / sqrt( 2 - 2/sqrt(1 + pixel_size^2/L^2 * 
  //                      ( (x-beam_x)^2 + (y-beam_y)^2 ) ) )
  //    b = pixel_size^2 / L^2
  //    c = (x-beam_x)^2 + (y-beam_y)^2
  //    d = sqrt(1 + c * b)
  //    two_sin_theta = sqrt(2 - 2/d)
  //    resolution = wavelength / two_sin_theta

  // resol = wavelength / sqrt(2 - 2/sqrt(1 + b*r^2) )
  // wavelength on the order of 1, b on the order of 1e-7.

  // for b = 1.6e-7, wavelength = 1,
  // 1/d^3 is approx proportional to r^2.8

  // d = wavelength / sqrt(2 - 2/(1 + b*r*r))
  // 1 / sqrt(1 + b*r*r) approx. 1 + b*r*r*(-1/2)
  // ==> d approx. wavelength/sqrt(b*r*r) = A / r
  // So resolution is approx. proportional to 1/r,
  // where r is distance from pixel to beam center.


      
  //static double resolb = pow(pixel_size / distance, 2);

  double d = sqrt(1.0 + resolb * r2);
  double two_sin_theta = sqrt(2.0 - 2.0/d);

  if (two_sin_theta<10e-8)
    return 10e8;
  else
    return wavelength/two_sin_theta;

}


//inline double diffimage::xy2resol(const double x, const double y) const
double diffimage::xy2resol(const double x, const double y) const
{
	double r2 = (x - beam_x)*(x - beam_x) + (y - beam_y)*(y - beam_y);
	return r2_to_resol(r2);
}



double diffimage::resol_to_r2(const double resol) const 
{
  // ********************************************
  // Determine squared radius from resolution.
  // This function is the reverse of r2_to_resol.
  // ********************************************

  // static double b = pow(pixel_size / distance, 2);

  double sin_theta, cos_2theta, tan_2theta_sqr;

  sin_theta = 0.5 * wavelength / resol;
  // When this function is called properly, 
  // 'resol' should be reasonably larger than 0.

  //Nick Sauter: the function resol_to_r2 appears to use an approximate formula in a 
  // situation where the exact expression would be preferred.   
  // The following commented code is added so that future tests can be run with the exact 
  // formula commented in:
  //double two_sin_theta = 2.0*sin_theta;
  //double arg = std::tan(2.*std::asin(two_sin_theta/2.0));
  //double should_be = arg*arg/resolb;
  double d = 1.0 / (1.0 - 2 * sin_theta * sin_theta);

  return (d * d - 1.0) / resolb;
}


//inline double diffimage::twotheta_to_resol(const double twotheta) const
double diffimage::twotheta_to_resol(const double twotheta) const
{
	return wavelength / 2.0 / sin(twotheta * 0.5);
}



// The following utility functions are not used.
/*

template<class T1, class T2> 
int ksmooth(const vector<T1>& X, const vector<T2>& Y, const vector<T1>& fitloc, vector<T2>& fit, const double span)
{
	//
	// Kernel smoother.
	//

	// 'X' are independents.
	// 'Y' are dependents corresponding to 'X'. 
	// 'fitloc' passs in predictors, e.g., a copy of X.
	// 'fit' returns predictions.
	// 'span' specifies search neighborhood to be span multiplied by range of 'X',
	// that is, span/2 * range(X) on each side of a predictor.  0 < span < 1.
	// Triangle kernel is used.
	//
	// Prediction is a weighted average of variables in the neighborhood of the predictor:
	//   fit = r(i) * Y(i) / SUM( r(i) ) 
	// where 
	//       r(i) = min(0, 1 - (|X(i) - predictor|)/(span/2 * range(X)))

	double hspan = (*max_element(X.begin(),X.end()) - *min_element(X.begin(),X.end())) * span * 0.5;

	for (int j=0; j<fitloc.size(); j++) {
		double r;
		double sumr = 0;
		double prediction = 0;

		for (int i=0; i<X.size(); i++) {
			r = abs(X[i] - fitloc[j]);
			if (r < hspan) {
				r = 1.0 - r/hspan;
				prediction += r * Y[i];  
				sumr += r;
			}
		}

		fit[j] = static_cast<T2>(prediction / sumr);
	}

	return 0;
}


*/

