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
 * This library is used to analyze images of crystal diffraction patterns.
 * Major functions include:
 *  1) Calculate an "intensity" score for each pixel, 
 *     based on the characteristics if local background.
 *  2) Mark out diffraction spots, indicating number of peaks within the spot.
 *  3) Estimate a resolution boundary within (larger than) which
 *     a major fraction of the diffraction spots reside.
 *  4) Summarize the diffraction spots on a variety of measures.
 *  5) Accurately locate and mark out ice-rings.
 *
 * The library consists of two files: libdistl.h, libdistl.cc
 *
 * Developed by 
 *  Zepu Zhang,    zpzhang@stanford.edu
 *  Ashley Deacon, adeacon@slac.stanford.edu
 *  and others.
 *
 * July 2001 - May 2004.
 */


#ifndef LIBDISTL_H
#define LIBDISTL_H

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iterator>
#include <vector>
#include <list>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <functional>
//#include <ctime>         // for timing the code while debugging
#define DISTL_CHECKPT {std::cout<<"checkpoint at line "<<__LINE__<<std::endl;}
#define DISTL_EXAMINE(A) {std::cout<<"variable "<<#A<<": "<<A<<std::endl;}

#include <spot_types.h>

using namespace std;

namespace Distl {

typedef std::vector< std::vector< bool > > flag_array_t;
typedef std::vector< std::vector< double > > double_array_t;

template <class T>
class constmat {

private:
	vector<const T*> data;

public:
	size_t nx;
	size_t ny;

	typedef T  data_type;
	typedef T* pointer;
	typedef const T* const_pointer;
	typedef T& reference;
	typedef const T& const_reference;

	typedef pointer iterator;
	typedef const_pointer const_iterator;

	iterator begin() { return data[0]; }
	iterator end() { return data[0] + nx*ny; }
	const_iterator begin() const { return data[0]; }
	const_iterator end() const {return data[0] + nx*ny; }

	//pointer operator[](size_t n) {return data[n]; }
	const_pointer operator[](size_t n) const { return data[n]; }

	size_t size() const { return nx*ny; }

	constmat() {
		nx = 0;
		ny = 0;
		data = vector<const T*>();
	}

	constmat(const T* mat, size_t n1, size_t n2) {
		nx = n1;
		ny = n2;
		data = vector<const T*>(nx);
		for (int x = 0; x < nx; x++)
			data[x] = mat + x*ny; 
	};

	void clear() {
		data.clear();
	}
};

typedef constmat<int> image_rawdata_t;

struct point {
  int x;
  int y;
  int value;

  point(): x(0), y(0) {;}
  point(const int xx, const int yy): x(xx), y(yy) {;}
  point(const int xx, const int yy, const int vv): x(xx), y(yy), value(vv) {;}
};


struct spot_base {
        typedef Distl::list_types<point>::list_t point_list_t;
        point_list_t bodypixels;    // area is bodypixels.size()
	point_list_t borderpixels;  // perimeter is close to borderpixels.size()
	// spot doesn't include the pixels in 'borderpixels'

	point_list_t maximas;

	double centerx;
	double centery;
	// Average of bodypixel coordinates, weighted by pixel value.


	point peak;
	// Body pixel with max value.

        double peakresol;

	// added by Qingping
        double m_PixelValueSum; // total intensity over all pixel values
        
        //Methods
        int area() const {return bodypixels.size();}//number of pixels in spot
        double total_intensity() const {return m_PixelValueSum;}
        void find_weighted_center(image_rawdata_t const&, flag_array_t const&);
	double shape() const;
};

struct spot: public spot_base {


	//additional shape parameters, added by Qingping
	double dmaxminRatio; // shape based on max/min distance to the border
	double ellipoidRatio; //  ratio of major and minor axis if every spot is approximated by an ellipoid
	double compactness; // compactness, another shape indicator

	int ncloseneighbors;
        spot():ncloseneighbors(0){}
};


struct cmpspotx {
	bool operator()(const spot& a, const spot& b) const {
		return (a.peak.x < b.peak.x);
	}
};


struct icering {
	// squared radius of inner and outter bounds
	double lowerr2;
	double upperr2;

	// resolution of inner and outter bounds
	double lowerresol;
	double upperresol;

	double strength;  // between 0 and 1.
	int npx;          // number of pixels on the ring.
};

enum detector_shape { UNKNOWN, SQUARE, CIRCLE, RECTANGULAR_PIXEL };

class diffimage {
private:

	int get_underload() const;

	void pxlclassify(); 
	void pxlclassify_scanbox(const int, const int, const int, const int, 
								const double);

	void search_icerings();

	void search_maximas();

	void search_spots();
	void search_neighbor_spots();
	void search_overloadpatches();
	void search_border_spot(const int, const int, spot&, 
							vector< vector<bool> >&); 
	void search_border_overload(const int, const int, spot&, 
							vector< vector<bool> >&); 


        void diffstrength(); // analysis diffraction strength of an image
	void diffscore();
	void imgresolution();
	void imgresolution2();
	void spotshape();

	void cleardata();


public:
	
	// Processing parameters and options
	
	int underloadvalue;
	int overloadvalue;    // >= OVERLOAD: overloaded pixel
        bool report_overloads; // ignore the cutoff when spot searching

	// Specifies margin width to be ignored from processing.
	int imgmargin;

	const int npxclassifyscan; // = 3

	// border length of square boxes scanned in determining 
	// local background and pixel intensities 
	int scanboxsize[3];

	// upper intensity threshold for bg pixel.
	// intensity < bgupperint && value > UNDERLOAD
	// => bg pixel
	//
	// "bgupperint"
	// is set at the beginning of each scan, and used in the scan,
	// so the code works the same for each scan, except for different
	// parameters; but the code doesn't need to know how many
	// scans have been done.
	double bgupperint[3];

	// lower intensity threshold for diff pixel.
	// intensity > difflowerint && value < OVERLOAD
	// => diffraction
	double difflowerint;
	
	// Width of rings used while checking for ice-rings.
	int iceringwidth;
	
	// Maximum  and minimum resolution of the region checked
	// for ice-rings.
	double iceresolmax;
	double iceresolmin;

	// Number of elements in icering_cutoffint and icering_cutoffprct.
	const int nicecutoff; // = 2
	
	double icering_cutoffint[2];
	// Two pixel intensity values.

	double icering_cutoffprct[2];   
	// Two percentage values in [0, 1].
	// Ice-ring must satisfy:
	//   at least icering_cutoffprct[0] * 100 % of pixels on the ring have intensity >= icering_cutoffint[0],
	//   and
	//   at least icering_cutoffprct[1] * 100 % of pixels on the ring have intensity >= icering_cutoffint[1],

	double icering_strength_cutweight[2];
	// Weight of the two cutoff percentages in determining ice-ring strength.
	// Add to 1.
	// The lower cutoff (cutoffint[0]) measures continuity;
	// the higher cutoff (cutoffint[1]) measures intensity.


	// Spot area lower bound. A spot should have at least this many body pixels.
	int spotarealowcut;

    // the peak of the spot should have at least the intensity
    int spotintensitycut;
	
	
	// If two spots are closer than
	//    spotdistminfactor * max_diameter_of_the_two, 
	// both are marked as have a close neighbor..
	// Distance is between two spot peaks.
	double spotdistminfactor;


	double imgresolringpow; 
	// power of resol used in defining the rings in resolution determination.


	// Image facts
	
	double pixel_size;       // (mm)
	double distance;         // (mm)
	double wavelength;       // (angstroms)
	double resolb;           // (pixel_size/distance)^2
	double osc_start;
	double osc_range;

	double beam_center_x;    // (mm)
	double beam_center_y;    // (mm)



	int beam_x; // x index of beam center on image
	int beam_y; // y ...

	int nxs;  // number of X in the matrix, from left to right
	int nys;  // number of Y in the matrix, from top to bottom 

	// Define processing region on the image.
	int firstx;
	int lastx; 
	int firsty;
	int lasty;
        // Image geometry; important to exclude periphery from circular image
        detector_shape image_geometry;

	//vector< vector<int> > pixelvalue;
	constmat<int> pixelvalue;
	// Each element vector of pixelvalue contains the values of
	// one column of pixels, from top to bottom. 
	// Element vectors of pixelvalue are columns from left
	// to right.
	

	// Processing results

	vector< vector<double> > pixelintensity;  
	// (PixelValue - LocalBackground) / LocalStandardError
	// Same location arrangement as in pixelvalue.

	spot::point_list_t maximas;
	list<spot> spots;
	list<spot> overloadpatches;
	vector<icering> icerings;


	vector<double> imgresol_unispotresols;
	vector<double> imgresol_unispaceresols;
	vector<int> imgresol_unispacespotcounts;

	double imgresol_unispot;            // image resolution limit
	double imgresol_unispot_shiftfactor;
	double imgresol_unispot_curvebadness; 
	double imgresol_unispace;            // image resolution limit
	double imgresol_unispace_cutoff_fraction;
	double imgresol_unispace_curvebadness; 

        double imgresol_wilson; // pseudo-wilson resolution estimation
	double imgscore; // score for the image

	double shape_mean; // average spot shape for the image based on dmaxminratio
	double shape_median; // medium
	double shape_sd; // standard derivation

	double ellip_mean; // average spot based on ratio of ellipoid axis ratio main/minor
	double ellip_median;
	double ellip_sd;

	int MaxPixelValue15to4; //maximum (peak) pixel value between 15-4A in a spot
	int MinPixelValue15to4; //minimum (peak) pixel value between 15-4A in a spot

	// Public functions
	
	diffimage();
	~diffimage();

	// Utilities
	double r2_to_resol(const double) const; 
	double xy2resol(const double, const double) const;
	double resol_to_r2(const double) const; 
	double twotheta_to_resol(const double) const;

	void set_imageheader(const double, const double, const double,
					const double, const double, const double, const double); 
	void set_imagedata(const int* const, const int, const int);


	bool pixelisonice(const int x, const int y) const;

	int process();

};





// The following utility functions are not actually used.
/*
 
template<class T1, class T2> 
int ksmooth(const vector<T1>& X, const vector<T2>& Y, 
		const vector<T1>& fitloc, vector<T2>& fit, const double span);

*/

}

using namespace Distl;


#endif
