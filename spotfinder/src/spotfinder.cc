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
 * This program uses libdiffspot to analyze images of crystal diffraction patterns.
 * It illustrates the use of libdiffspot, and meantime is a useful application
 * in its own right.
 *
 * Help information is obtained by running the program 
 * with no command-line parameters.
 *
 * Developed by 
 *  Zepu Zhang,    zpzhang@stanford.edu
 *  Ashley Deacon, adeacon@slac.stanford.edu
 *  and others.
 *
 * July 2001 - May 2004.
 */


// libimage.h defines
//     #define img_pixel(img,x,y) (((img)->image) [img_rows * x + y])
//
// which means pixels are stored row by row, from top to bottom.
// In each row, pixels are stored from left to right.
//   y <-> left->right <---> nys
//   x <-> top->bottom <---> nys
// 
// In the processing and results, this coord system is used, i.e.
// x goes from top to bottom, y goes from left to right,
// for locations in both pixel indices and mm.
//
// shown by ADXV on the lower-left corner of image are 
//      Mm:  mmx, mmy     (left->right, bottom->top)
//   Pixel:    y,   x     (left->right, top->bottom)

// Image file format is SMV.


#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <string>
#include <math.h>
#include <vector>
#include <algorithm>
//#include <ctime>     // for timing the code while debugging.d

#include "libdistl.h"

#include "libimage.h"
extern "C" {
#include "jpeglib.h"
}

typedef Distl::spot::point_list_t point_list_t;

struct userdata {
	bool writejpg;
	bool writejpg_orig;
	bool writeimg;
	bool writemosflm;
	bool writeresolcurve;
    bool writespot;
    bool good_spot_only;
    bool resolution_boundary_check;

	string spotfilename;

	string outputdir;

	string parfilename;

	double beam_center_x;
	double beam_center_y;
    double good_spot_resolution_low;
    double good_spot_resolution_high;

	int spotbasesize;
	// Spots of size no smaller than this are used for summarizing
	// shape, intensity, etc.

	int jpgquality;
	
	userdata( ):
		writejpg( false ), writejpg_orig( false ), 
		writeimg( false ), 
		writemosflm( false ),
		writeresolcurve( false ),
        writespot( false ),
        good_spot_only ( false ),
        resolution_boundary_check ( false ),
		spotfilename( "" ),
		outputdir( "" ),
		parfilename( "" ),
		beam_center_x( -1 ), beam_center_y( -1 ),
        good_spot_resolution_low(40),
        good_spot_resolution_high(3),
		spotbasesize( 16 ),
		jpgquality( 75 )
	{ ; }

};



void print_help();
int parseargs(int, char**, userdata&);
void parseparfile(ifstream&, userdata&, diffimage&);
void parsefilename(const string& fullname, string& pathname, string& filename);

void summarize(const diffimage&, userdata&, ofstream&, const string&);

void markimage(point_list_t&, const diffimage&);

template<class T> void write_smvimg(const string&, img_object *img, 
		const constmat<int>&, const point_list_t&, bool);
		//const vector< vector<T> >&, const point_list_t&, bool);

void write_int_jpeg(const string& fileprefix, const diffimage& finder,
	const point_list_t& pixelmarkers, const userdata& useropts);
//template<class T> void write_jpeg_transform(const vector< vector<T> >& imagedata, 
template<class T> void write_jpeg_transform(const constmat<int>& imagedata, 
	unsigned char * dataRGB,
	const T pivotvalue[], const int pivotcolor[], const double transpower[]);

void write_jpeg(const string& fileout, 
		const unsigned char* datamatirx, const int image_width, const int image_height,
		const double quality, const point_list_t& pixelmarkers);

void write_mosflm(ofstream&, const diffimage&);


int main(int argc, char *argv[]) 
{
	if (argc<2) {
		print_help();
		exit(0);
	}

	diffimage finder;
	userdata useropts;


	// Parse command-line parameters
	int argIndex = 0;
	if ((argIndex=parseargs(argc, argv, useropts)) == 0) {
		printf("Please enter image files\n");
		exit(1);
	}
	if (!useropts.outputdir.empty() && useropts.outputdir[useropts.outputdir.length() - 1] != '/')
		useropts.outputdir.append("/");


	// Read in user parameter file if one is specified.
	// User parameter file will overwrite default parameters on common parameters.

	if (!useropts.parfilename.empty()) {
        cout << "reading user parameter file" <<useropts.parfilename<<endl;
		ifstream parfile;
		parfile.open(useropts.parfilename.c_str());
		if (!parfile.is_open()) {
			cout << "Cannot find or open specified parameter file " << useropts.parfilename << ".\n"
				<< "Default parameter values are used.\n";
		} else {
			parseparfile(parfile, useropts, finder);
			useropts.parfilename = "";
			parfile.close();
		}
	}



	// Delete the named spot file if it already exists.
	if (useropts.writemosflm && useropts.spotfilename.size() > 0) {
		useropts.spotfilename.insert(0, useropts.outputdir);

		ofstream spotfile(useropts.spotfilename.c_str(), ios::out);
		spotfile << "";
		spotfile.close();
	}

	for (int iarg=argIndex; iarg<argc; iarg++) {
		string arg = argv[iarg];

		if (arg.length() <= 4) continue;

		string::size_type idx=arg.rfind('.');
		string basename=arg.substr(0,idx);
		string extname=arg.substr(idx+1);

		string filename = arg;

		// Get file name prefix, remove trailing '.img',
		// add user-defined storage directory.
		string fileprefix = basename;
		if (!useropts.outputdir.empty()) {
                        string path,filename, newfullname;
                        parsefilename(fileprefix,path,filename);
			fileprefix=useropts.outputdir+"/"+filename;
		}

		cout << endl;
		cout << "Processing image file " << filename << " ......\n" << flush;

		img_object *img = img_make_handle(); //img_open();
		if (img_read(img,filename.c_str()) != 0) {
			cout << "!! Failed in reading image file.\n";
			img_free_handle(img); //img_close(img);
			continue;
		}
		// For large images, this step is the #4 time consumer.

		/*
		cout<<"pixel size= "<<img_get_number(img,"PIXEL SIZE")<<endl;
		cout<<"wavelength= "<<img_get_number(img,"WAVELENGTH")<<endl;
		cout<<"oscrange= "<<img_get_number(img,"OSCILLATION RANGE")<<endl;
		cout<<"phi "<<img_get_number(img,"PHI")<<endl;
		cout<<"distance "<<img_get_number(img,"DISTANCE")<<endl;
		cout<<"beam center "<<img_get_field(img,"BEAM CENTRE")<<endl;
		*/

		string detector=img_get_field(img,"DETECTOR");
		double beamctrx = useropts.beam_center_x;

		if(detector.substr(0,4)=="ADSC") { // adsc
			if (beamctrx < 0)
				beamctrx = img_get_number(img, "BEAM_CENTER_X");

			double beamctry = useropts.beam_center_y;
			if (beamctry < 0)
				beamctry = img_get_number(img, "BEAM_CENTER_Y");
		
			finder.set_imageheader(img_get_number(img,"PIXEL_SIZE"),
							img_get_number(img,"DISTANCE"),
							img_get_number(img,"WAVELENGTH"),
							img_get_number(img,"OSC_START"),
							img_get_number(img,"OSC_RANGE"),
							beamctrx, beamctry);
		} else if (detector.substr(0,3)=="MAR") { //mar345
		
						double pixel_size = img_get_number(img,"PIXEL SIZE");
							
                        if (beamctrx < 0)
                                beamctrx = img_columns(img)*pixel_size/2.0;

                        double beamctry = useropts.beam_center_y;
                        if (beamctry < 0)
                                beamctry = img_rows(img)*pixel_size/2.0;
                                
                        double osc_range = img_get_number(img,"OSCILLATION RANGE");
                                                                
                        finder.set_imageheader(pixel_size,
                                                        img_get_number(img,"DISTANCE"),
                                                        img_get_number(img,"WAVELENGTH"),
                                                        img_get_number(img,"PHI"),
                                                        osc_range,
                                                        beamctrx, beamctry);
		}

		finder.set_imagedata(img->image, img_columns(img), img_rows(img));
		// For large images, this step is the #2 time consumer.

		finder.process();
		// For large images, this step is the #1 time consumer.

		cout << "- Summarizing" << endl;
		string logfilename = fileprefix + ".log";

		ofstream logfile;
		cout << "- Output log message in file " << logfilename << endl;
		logfile.open(logfilename.c_str());
		if (!logfile.is_open()) {
			cout << "!! Failed to open log file.\n";
		}

		if (logfile.is_open()) {
			summarize(finder, useropts, logfile, filename);
			logfile.close();
		}


		if (useropts.writejpg || useropts.writejpg_orig || useropts.writeimg)
		{
			point_list_t pixelmarkers;
			markimage(pixelmarkers, finder);

			if (useropts.writeimg)
			{
				cout << "- Output processed image in SMV format as file " << fileprefix+".spt.img" << endl;
				write_smvimg<int>(fileprefix+".spt.img", img, finder.pixelvalue, pixelmarkers, true);
				// For large images, this step is the #3 time consumer.
			}

			write_int_jpeg(fileprefix, finder, pixelmarkers, useropts);
		}



		img_free_handle(img); 


		if (useropts.writemosflm) {
			if (useropts.spotfilename.size() > 0) {
				cout << "- Output spot information in file " << useropts.spotfilename  << endl
					 << "  If file '" << useropts.spotfilename << "' already exists, it is overwritten.\n";
				ofstream spotfile(useropts.spotfilename.c_str(), ios::app);
				if (!spotfile.is_open()) {
					cout << "!! Failed to open spot file " << useropts.spotfilename << endl;
				} else {
					write_mosflm(spotfile, finder);
					spotfile.close();
				}
			} else {
				string fname = fileprefix + ".spt";
				cout << "- Output spot information in file " << fname  << endl;
				ofstream spotfile(fname.c_str(), ios::out);
				if (!spotfile.is_open()) {
					cout << "!! Failed to open spot file " << useropts.spotfilename << endl;
				} else {
					write_mosflm(spotfile, finder);
					spotfile.close();
				}
			}
		}

		

		cout << endl;
	}

	return(0);
}




void print_help() 
{
	// **********************************
	// Help message to be printed while
	// program is called with no argument.
	// **********************************

	printf("\n"
		"NAME\n"
		"\n"
		"  spotfinder - Diffraction spot finding\n"
		"\n"
		"SYNOPSIS\n"
		"\n"
		"   spotfinder [flag1 value1 [flag2 value2 [...]] filename1.img filename2.img ...\n"
		"\n"
		"OPTIONS\n"
		"\n"
		"   All the following command line parameters are optional,\n"
		"   except for -i, the parameter specifying processing parameter file,\n"
		"   because for the moment I don't know how to get a default fiel for it. \n"
		"   Each flag consists of '-' followed by one letter, not quoted.\n"
		"   Parameter values are string or number, not quoted.\n"
		"\n"
		"   One or more input images can be specified for processing.\n"
		"   While specifying more than one images, wildcard can be used.\n"
		"\n"
		"   An option pair [flag value] should stay one after another.\n"
		"   All options are read in before any image is processed,\n"
		"   so the order of options and image files is insignificant.\n"
		"\n"
		"   A log file, named 'xxx.log', containing more information, \n"
		"   is always provided for each processed image.\n"
		"\n"
		"   The parameter file, defaulted to spotfinder.par in the same directory as the program,\n"
		"   contains more information regarding additional parameters and output images.\n"
		"\n"
		"   Command-line arguments:\n"
		"\n"
		"       -i      User parameter file.\n"
		"               Read in parameter values set in the specified parameter file to override default values.\n"
		"               An example parameter file, spotfinder.par, can be found in the program directory.\n"
		"\n"
		"       -d      Destination directory of output files.\n"
		"               If this argument is absent, output files are saved in the same folder as\n"
		"               the image files. This argument is particularly useful if the user does not\n"
		"               have write permission to the image directory.\n"
		"               Use . to specify current working directory.\n"
		"               '\' symbol at the end of the directory name is optional.\n\n"
		"\n"
		"               When the image files are in multiple directories,\n"
		"               or they are in a single directory but their path is specified,\n"
		"               the plan is to build a corresponding directory structure under the specified directory.\n"
		"               But this is not implemented yet; the program fails in this situation.\n"
		"\n"
		"       -m      Write out MOSFLM spot file?\n"
		"               0 -- no;  1 -- yes.\n"
		"               Default is 0.\n"
		"\n"
		"       -s      Name of spot file (MOSFLM file).\n"
		"               If this is specified, one common spot list file is output for all images.\n"
		"               If this is absent, one spot list file is output for each image with name \n"
		"               'originalfilename.spt'.\n"
		"               This should be the file name only, without path.\n"
		"               This option is effective only when -m is set to 1.\n"
		"\n"
		"       -x      X position of beam center, in mm. \n"
		"               This is needed only if corresponding information in image header is known to be wrong.\n"
		"               Value set for this is effective for all images.\n"
		"\n"
		"       -y      Y position of beam center, in mm. \n"
		"               This is needed only if corresponding information in image header is known to be wrong.\n"
		"               Value set for this is effective for all images.\n"
		"\n"
		/*
		"       -b0,-b1,-b2  Integer, preferably odd.\n"
		"               Box sizes used while scanning the image to classify pixels and identify spots. \n"
		"               The three box sizes correspond to one preliminary scan and two extensive scans, \n"
		"               respectively. \n"
		"               Internally a relatively large box size is used for the preliminary scan, \n"
		"               and it is advised not to set '-b0' manually.\n"
		"               Setting a boxsize to 0 causes the corresponding scan to be skipped.\n\n"
		"               Recommended values for 'b1' and 'b2': [31,81]\n\n"
		"       -u0,-u1,-u2  Upper intensity thresholds for background pixels. \n"
		"               It is advised not to set 'u0' manually.\n\n"
		"               Recommended value for 'u1' and 'u2': \n"
		"                   [1.65, corresponding 'w'] (see below for 'w')\n\n"
		"       -w0,-w1,-w2  Lower intensity thresholds for diffraction pixels. \n"
		"               It is advised not to set 'w0' manually.\n\n"
		"               Recommended values for 'w1' and 'w2': [1.96, 4.0]\n\n"
		"   Ice-Ring Detection Parameters:\n\n"
		"       -i3     Intensity percentile as a measure of ice-ring strength.\n\n"
		"               Recommended value: [0.1, 0.3]\n\n"
		"       -i1     Ice ring resolution lower bound. \n"
		"               Region outside of (i.e., <) this resolution is ignored.\n\n" 
		"       -i2     Ice ring resolution upper bound. \n"
		"               Region inside of (i.e., >) this resolution is ignored.\n\n" 
		"       -o1,-o2 Cutoff values for ring pixel intensity percentiles in ice-ring detection. \n"
		"               By default -p1 < -p2, so if -p1, -p2 are left as default, \n"
		"               -o1 < -o2 should be maintained. \n\n"
		"               Recommended values: [0, 2].\n\n"
		"       -p1,-p2 Percentiles corresponding to the Cutoff values. \n\n"
		"               Recommended values: [0.3, 0.9].\n\n"
		"   Image-Resolution Determination Parameters:\n\n"
		"       -y1     Power of resol for allocating shells. For example,\n"
		"                   -q -2.0    -- shells allocated by equal 1/d^2 steps.\n\n"
		"               Rcommended values: [-3.0, -2.0]\n\n"
		"       -y2     Number of spots per ring.\n\n"
		"               Recommended value: [10, 30]\n\n"
		*/
		//"EXAMPLES\n"
		//"\n"
		//"  None.\n"     
		"\n");
}



/**
 * Returns the index to the first image file, which follows all
 * other commandline arguments.
 */
int parseargs(int argc, char* argv[], userdata& useropts)
{
  // *************************************************
  // Parse command-line parameters.
  // *************************************************

  int iargv = 1;
  while (iargv < argc-1) {
    char *flag = argv[iargv];
	if (flag[0] != '-') {
		return iargv;
	}
	++iargv;

    switch (flag[1]) {
	  case 'd': useropts.outputdir = (string)(argv[iargv]); break; 
	  case 'i':
	  case 'I': useropts.parfilename = (string)(argv[iargv]); break;
	  case 'm': useropts.writemosflm = static_cast<bool>(atoi(argv[iargv])); break;
	  case 's': useropts.spotfilename = (string)(argv[iargv]); break;
	  case 'x':
	  case 'X': useropts.beam_center_x = atof(argv[iargv]); break;
	  case 'y':
	  case 'Y': useropts.beam_center_y = atof(argv[iargv]); break;
      default:
        cout << "Unknown argument " << flag << endl; return(1);
    }
    iargv++;		 
  }
  
  return iargv;
}



void parseparfile(ifstream& parfile, userdata& useropts, diffimage& finder)
{
	// *************************************************
	// Read in parameter file.
	// *************************************************

	bool inblock = false;
	string blockname;
	string blockvalue;
	string line;

	while (!parfile.eof()) {
		while (getline(parfile, line)) {
			if (inblock) {
				if (line.length() == 0 || line[0] != '#') {
					inblock = false;
					blockvalue = line;
					break;
				}
			} else {
				if (line.length() > 0 && line[0] == '#') {
					inblock = true;
					blockname = line;
					blockname.erase(0, 2);
				}
			}
		}

		if (blockname == "writejpg") {
			useropts.writejpg = (blockvalue == "1");
		} else if (blockname == "writejpg_orig") {
			useropts.writejpg_orig = (blockvalue == "1");
		} else if (blockname == "writeimg") {
			useropts.writeimg = (blockvalue == "1");
		} else if (blockname == "jpgquality") {
			useropts.jpgquality = atoi(blockvalue.c_str());
		} else if (blockname == "writeresolcurve") {
			useropts.writeresolcurve = (blockvalue == "1");
		} else if (blockname == "writespot") {
			useropts.writespot = (blockvalue == "1");
		} else if (blockname == "good_spot_only") {
			useropts.good_spot_only = (blockvalue == "1");
		} else if (blockname == "resolution_boundary_check") {
			useropts.resolution_boundary_check = (blockvalue == "1");
		} else if (blockname == "spotbasesize") {
			useropts.spotbasesize = atoi(blockvalue.c_str());
		} else if (blockname == "spotintensitycut") {
			finder.spotintensitycut = atoi(blockvalue.c_str());
		} else if (blockname == "spotarealowcut") {
			finder.spotarealowcut = atoi(blockvalue.c_str());
		} else if (blockname == "imgmargin") {
			finder.imgmargin = atoi(blockvalue.c_str());
		} else if (blockname == "overloadvalue") {
			finder.overloadvalue = atoi(blockvalue.c_str());
		} else if (blockname == "iceresolmin") {
			finder.iceresolmin = atof(blockvalue.c_str());
		} else if (blockname == "iceresolmax") {
			finder.iceresolmax = atof(blockvalue.c_str());
		} else if (blockname == "good_spot_resolution_low") {
			useropts.good_spot_resolution_low = atof(blockvalue.c_str());
		} else if (blockname == "good_spot_resolution_high") {
			useropts.good_spot_resolution_high = atof(blockvalue.c_str());
		} else {
			cout << "Unknown parameter file item '" << blockname << "' is ignored.\n"
				<< "If the program fails later, " 
				<< "missing parameter assignments due to messed-up parameter file may be the reason.\n";
		}
	}
}


void log_par( const diffimage& finder, const userdata& useropts,
    ofstream& logfile, int numberwid )
{
    logfile<<"USER CONFIG"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.writejpg<<"# writejpg"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.writejpg_orig<<"# writejpg_orig"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.writeimg<<"# writeimg"<<endl;
	logfile<<setw(numberwid)<<useropts.jpgquality<<"# jpgquality"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.writeresolcurve<<"# writeresolcurve"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.writespot<<"# writespot"<<endl;
	logfile<<setw(numberwid)<<useropts.spotbasesize<<"# spotbasesize (not used)"<<endl;
	logfile<<setw(numberwid)<<finder.spotintensitycut<<"# spotintensitycut"<<endl;
	logfile<<setw(numberwid)<<finder.spotarealowcut<<"# spotarealowcut"<<endl;
	logfile<<setw(numberwid)<<finder.imgmargin<<"# imgmargin"<<endl;
	logfile<<setw(numberwid)<<finder.overloadvalue<<"# overloadvalue"<<endl;
	logfile<<setw(numberwid)<<finder.iceresolmin<<"# iceresolmin"<<endl;
	logfile<<setw(numberwid)<<finder.iceresolmax<<"# iceresolmax"<<endl;
	logfile<<setw(numberwid)<<(int)useropts.good_spot_only<<"# good_spot_only"<<endl;
	if (useropts.good_spot_only) {
	    logfile<<setw(numberwid)<<useropts.good_spot_resolution_low
                <<"# good_spot_resolution_low"<<endl;
	    logfile<<setw(numberwid)<<useropts.good_spot_resolution_high
                <<"# good_spot_resolution_high"<<endl;
    }
    logfile<<"==============================================="<<endl;
}

void summarize (const diffimage& finder, userdata& useropts, 
		ofstream& logfile, const string& imgfilename)
{

	// Summary of ice-ring strength.

	double iceringstrength = 0;

	if (finder.icerings.size() > 0) {
		for (int icering=0; icering<finder.icerings.size(); icering++) 
			if (finder.icerings[icering].strength > iceringstrength) 
				iceringstrength = finder.icerings[icering].strength;
	}


	// Summary of overloaded patches:
	// size of largest overloaded patch, and
	// whether it lies on any ice-ring.
	
	int overloadpatches_maxarea = 0;
	int overloadpatches_maxonice = 0;

	if (!finder.overloadpatches.empty()) {
		list<spot>::const_iterator q = finder.overloadpatches.begin();

		for (list<spot>::const_iterator p = finder.overloadpatches.begin(); 
				p != finder.overloadpatches.end(); p++) {
			if (p->bodypixels.size() > q->bodypixels.size())
				q = p;
		}

		overloadpatches_maxarea = q->bodypixels.size();

		for (point_list_t::const_iterator p=q->borderpixels.begin(); 
				p!=q->borderpixels.end(); p++) {
			if (finder.pixelisonice(p->x,p->y)) {
				overloadpatches_maxonice = 1;
				break;
			}
		}
	}


	// Summary of spots.

	int nspots = finder.spots.size();

    int nspots_good = 0;
	int nspots_overloaded = 0;
	int nspots_hascloseneighbor = 0;
	int nspots_multimax = 0;
	int spotareasummary = 0;
	double spotshapesummary = 0;

    double spotintensitysum = 0;
    double spotsizesum = 0;

    const double good_resolution_low = useropts.good_spot_resolution_high;
    const double good_resolution_high = useropts.good_spot_resolution_low;

	if (finder.spots.size() > 0)
	{
		vector<int> spotarea;
		spotarea.reserve(nspots);
		vector<double> spotshape;
		spotshape.reserve(nspots);


		for (list<spot>::const_iterator p = finder.spots.begin();
				p != finder.spots.end(); p++) {

            if (!useropts.good_spot_only || 
            (p->peakresol <= good_resolution_high &&
            p->peakresol >= good_resolution_low &&
            p->peak.value < finder.overloadvalue &&
            p->ncloseneighbors ==0))
            {
                spotintensitysum += p->total_intensity();
                spotsizesum += p->area();
                ++nspots_good;
                //they may be set to 0 later if all resolutions are failed
            }

			if (p->peak.value >= finder.overloadvalue)
				nspots_overloaded ++;

			if (p->maximas.size() > 1)
				nspots_multimax ++;

			if (p->ncloseneighbors > 0) 
				nspots_hascloseneighbor++;

			spotshape.push_back(p->shape());
			spotarea.push_back(p->area());
		}

        if (useropts.resolution_boundary_check)
        {
            double check_resolution = 99.0;
            if (useropts.good_spot_resolution_low < check_resolution)
            {
                check_resolution = useropts.good_spot_resolution_low;
            }

		    if (finder.imgresol_wilson >= check_resolution &&
		    finder.imgresol_unispot >= check_resolution &&
		    finder.imgresol_unispace >= check_resolution)
            {
                nspots_good = 0;
                spotintensitysum = 0.0;
                spotsizesum = 0.0;
            }
        }

		nth_element(spotarea.begin(), spotarea.begin()+spotarea.size()/2, spotarea.end());
		spotareasummary = spotarea[spotarea.size()/2];

		nth_element(spotshape.begin(), spotshape.begin()+spotshape.size()/2, spotshape.end());
		spotshapesummary = spotshape[spotshape.size()/2];
		//spotshapesummary = accumulate(spotshape.begin(), spotshape.end(), 0.0) / nspots;
		spotshapesummary = min(1.0, max(0.0, spotshapesummary));
	}


	//------------------------------------------
	// print out summary to log file.
	//------------------------------------------
	
	if (!logfile.is_open())
		return;

	
	const int numberwid = 15;

	logfile << imgfilename << endl << endl;

	logfile 
		<< setprecision(4) 
		<< "----------------------------------------" << endl
		<< "Image summary" << endl 
		<< "----------------------------------------" << endl;
    if (useropts.good_spot_only) {
		logfile << setw(numberwid) <<  nspots_good
		<< "# number of spots" << endl;
    } else {
		logfile << setw(numberwid) << finder.spots.size() 
		<< "# number of spots" << endl;
    }
	logfile<< setw(numberwid) << nspots_overloaded
		<< "# number of spots with overloaded pixels" << endl
		<< setw(numberwid) << nspots_hascloseneighbor 
		<< "# number of spots with close neighbors" << endl
		<< setw(numberwid) << nspots_multimax 
		<< "# number of spots with multiple maxima" << endl
		<< setw(numberwid) << spotareasummary 
		<< "# spot size median" << endl
		<< setw(numberwid) << spotshapesummary 
		<< "# spot shape median" << endl
		<< setw(numberwid) << finder.imgresol_wilson 
		<< "# resolution boundary by Method W" << endl 
		<< setw(numberwid) << finder.imgresol_unispot 
		<< "# resolution boundary by Method 1" << endl 
		<< setw(numberwid) << finder.imgresol_unispace 
		<< "# resolution boundary by Method 2" << endl 
		<< setw(numberwid) << (finder.imgresol_unispace + finder.imgresol_unispot) / 2.0
		<< "# average resolution boundary estimate" << endl 
		<< setw(numberwid) << finder.imgresol_unispot_curvebadness  
		<< "# badness of curve in Method 1" << endl
		<< setw(numberwid) << finder.imgresol_unispace_curvebadness  
		<< "# badness of curve in Method 2" << endl
		<< setw(numberwid) << finder.icerings.size()
		<< "# number of ice-rings" << endl
		<< setw(numberwid) << finder.MaxPixelValue15to4
		<< "# maximum (peak) pixel value between 15-4A in a spot" << endl
		<< setw(numberwid) << finder.MinPixelValue15to4
		<< "# minimum (peak) pixel value between 15-4A in a spot" << endl
		<< setw(numberwid) << finder.shape_mean
		<< "# spot shape, <Dmax/Dmin>, 1 for circle" << endl
		<< setw(numberwid) << finder.shape_median
		<< "# spot shape, median Dmax/Dmin, 1 for circle" << endl
		<< setw(numberwid) << finder.shape_sd
		<< "# spot shape, standard derivation" << endl
		<< setw(numberwid) << finder.ellip_mean
		<< "# ellipoid spot shape, mean of ratio of ellipoid axes, 1 for disk" << endl
		<< setw(numberwid) << finder.ellip_median
		<< "# ellipoid spot shape, median of ellipoid axes ratio, 1 for disk" << endl
		<< setw(numberwid) << finder.ellip_sd
		<< "# ellipoid spot shape, standard derivation of ellipoid axes" << endl
		<< setw(numberwid) << finder.imgscore
		<< "# composite score " << endl
		<< setw(numberwid) << iceringstrength
		<< "# strength of the strongest ice-ring" << endl;

	if (finder.icerings.size() > 0) 
	{
		for (int icering=0; icering<finder.icerings.size(); icering++) 
			logfile << "< " << setprecision(3) << finder.icerings[icering].upperresol
					<< " , " << setprecision(3) << finder.icerings[icering].lowerresol
					<< " >   ";
		
		logfile << "  ";
	} else {
		logfile << setw(numberwid) << "< >";
	}
	logfile << "# location of ice-rings <resol bounds>" << endl
		<< setw(numberwid) << overloadpatches_maxarea 
		<< "# size of largest overloaded patch" << endl
		<< setw(numberwid) << overloadpatches_maxonice
		<< "# whether or not the largest overloaded patch lies on ice-ring" << endl;

	logfile	<< setw(numberwid) << setprecision(0)<< spotintensitysum
		<< "# spot intensity integration" << endl;
	logfile	<< setw(numberwid) << setprecision(0)<< spotsizesum
		<< "# spot size sum" << endl;
    if (spotsizesum > 0)
    {
	    logfile	<< setw(numberwid) << setprecision(0)<< (spotintensitysum / spotsizesum)
		    << "# average spot intensity" << endl;
    }
	/*
	logfile << endl
		<< setprecision(4)
		<< "----------------------------------------" << endl
		<< "Image facts and processing parameters:" << endl
		<< "----------------------------------------" << endl
		<< setw(numberwid) << finder.pixelvalue.ny
		<< "# image height" << endl
		<< setw(numberwid) << finder.pixelvalue.nx
		<< "# image width" << endl
		<< setw(numberwid) << finder.overloadvalue
		<< "# overload pixel value" << endl
		<< setw(numberwid) << finder.underloadvalue
		<< "# underload pixel value (calculated)" << endl
		<< setw(numberwid) << finder.imgmargin
		<< "# image margin width ignored" << endl
		<< setw(numberwid) << finder.scanboxsize[0]
		<< "# box size for local scan, first pass" << endl
		<< setw(numberwid) << finder.scanboxsize[1]
		<< "# box size for local scan, second pass" << endl
		<< setw(numberwid) << finder.scanboxsize[2]
		<< "# box size for local scan, third pass" << endl
		<< setw(numberwid) << finder.bgupperint[0]
		<< "# upper intensity for background, first pass" << endl
		<< setw(numberwid) << finder.bgupperint[1]
		<< "# upper intensity for background, second pass" << endl
		<< setw(numberwid) << finder.bgupperint[2]
		<< "# upper intensity for background, third pass" << endl
		<< setw(numberwid) << finder.difflowerint
		<< "# lower intensity for diffraction" << endl
		<< setw(numberwid) << finder.spotarealowcut
		<< "# spot area lower bound" << endl
		<< setw(numberwid) << finder.spotdistminfactor
		<< "# spot minimum distance factor, used for identifying 'close neighbors'" << endl
		<< setw(numberwid) << finder.iceringwidth
		<< "# ring width in ice-ring searching" << endl
		<< setw(numberwid) << finder.icering_cutoffint[0] 
		<< "# ice-ring intensity cutoff, lower" << endl
		<< setw(numberwid) << finder.icering_cutoffprct[0] * 100
		<< "# ice-ring intensity cutoff percentage, lower" << endl
		<< setw(numberwid) << finder.icering_cutoffint[1] 
		<< "# ice-ring intensity cutoff, higher" << endl
		<< setw(numberwid) << finder.icering_cutoffprct[1] * 100
		<< "# ice-ring intensity cutoff percentage, higher" << endl
		<< setw(numberwid) << finder.iceresolmin
		<< "# ice-ring search resolution lower bound" << endl 
		<< setw(numberwid) << finder.iceresolmax
		<< "# ice-ring search resolution upper bound" << endl 
		<< endl << flush; 
	*/

	if (useropts.writeresolcurve) {
		// Plotting this information is mainly for debug.

		if (finder.imgresol_unispotresols.size() > 0) {
			logfile << "----------------------------------------------" << endl
				<< "Plot of spots resolution:" << endl
				<< "----------------------------------------------" << endl
				<< setw(8) << "D" << setw(6) << " respow" << " | " << "pow(resol)   Plot\n"
				<< "----------------------------------------------" << endl;

			logfile.setf(ios::right, ios::adjustfield);
			double widthfactor = 80 / pow(finder.imgresol_unispotresols.back(), finder.imgresolringpow);

			for (int ringidx=0; ringidx<finder.imgresol_unispotresols.size(); ringidx++) {
				double respow = pow(finder.imgresol_unispotresols[ringidx], finder.imgresolringpow);
				int wid = static_cast<int>(respow * widthfactor); 
				logfile << setw(8) << setprecision(4) << finder.imgresol_unispotresols[ringidx] 
					<< setw(6) << setprecision(2) << respow << " | "
					<< setw(wid) << "o" << endl;
			}
			logfile << endl;
		}



		if (finder.imgresol_unispaceresols.size() > 2) {
			logfile << endl << endl;
			logfile << "----------------------------------------------" << endl
				<< "Plot of spots counts by shell:" << endl
				<< "----------------------------------------------" << endl
				<< setw(8) << "D" << setw(6) << " #spot" << " | " << "Spot #   Plot\n"
				<< "----------------------------------------------" << endl;

			logfile.setf(ios::right, ios::adjustfield);

			
			double basewidth = finder.imgresol_unispacespotcounts[0] * 0.3 +
				finder.imgresol_unispacespotcounts[1] * 0.4 + 
				finder.imgresol_unispacespotcounts[2] * 0.3;
			double widthfactor;
			if (basewidth > 1)
				widthfactor = 80.0 / basewidth;
			else
				widthfactor = 8.0;



			for (int ringidx=0; ringidx<finder.imgresol_unispacespotcounts.size(); ringidx++) {
				int wid = static_cast<int>( finder.imgresol_unispacespotcounts[ringidx] * widthfactor); 
				logfile << setw(8) << setprecision(4) << finder.imgresol_unispaceresols[ringidx] 
					<< setw(6) << finder.imgresol_unispacespotcounts[ringidx] << " | "
					<< setw(wid) << "o" << endl;
			}
			logfile << endl;
		}
	}

	if (useropts.writespot && finder.spots.size( ) > 0) {
		logfile << setw(numberwid) << finder.spots.size() 
		<< "# number of raw spots" << endl;
        logfile<<"SPOT LIST: centerx centery num_pixel max_pixel sum"<<endl;
	    if (finder.spots.size() > 0)
	    {
		    for (list<spot>::const_iterator p = finder.spots.begin();
				p != finder.spots.end(); p++)
            {
				logfile<<setprecision(2)<<fixed
                       <<setw(10)<<p->centerx
                       <<setw(10)<<p->centery
				       <<setprecision(0)
                       <<setw(10)<<p->area()
                       <<setw(10)<<p->peak.value
                       <<setw(20)<<p->total_intensity()<<setprecision(2)
                       <<setw(20)<<p->peakresol;
                if (useropts.good_spot_only && (
                p->peakresol > good_resolution_high ||
                p->peakresol < good_resolution_low ||
                p->peak.value >= finder.overloadvalue ||
                p->ncloseneighbors >0))
                {
                    logfile<<" BAD spot";
                }
                
                logfile<<endl;
            }
        }
        log_par( finder, useropts, logfile, numberwid );
    }
}


void markimage(point_list_t& pixelmarkers, const diffimage& finder)
{
	const int overload_mark = 1;
	const int maxima_mark = 2;
	const int spotbor_good_mark = 3;
	const int spotbor_close_mark = 4;
	const int spotbor_mmax_mark = 5;
	const int spotbor_over_mark = 6;
	const int icering_mark = 7;
	const int resollim_unispace_mark = 8;
	const int resollim_unispot_mark = 9;
	const int margin_mark = 0;


	// Mark estimated resolution limit and ice-ring central lines.

	vector<double> linerr(2 + finder.icerings.size());
	vector<int> liner(2 + finder.icerings.size());
	linerr[0] = finder.resol_to_r2(finder.imgresol_unispot);
	liner[0] = static_cast<int>(sqrt(linerr[0]));
	linerr[1] = finder.resol_to_r2(finder.imgresol_unispace);
	liner[1] = static_cast<int>(sqrt(linerr[1]));
	for (int ringidx = 0; ringidx < finder.icerings.size(); ringidx++)
	{
		double rtemp = (sqrt(finder.icerings[ringidx].lowerr2) 
			+ sqrt(finder.icerings[ringidx].upperr2)) / 2.0;
		linerr[2 + ringidx] = rtemp * rtemp;
		liner[2 + ringidx] = static_cast<int>( rtemp );
	}

	vector<int> linemark(2 + finder.icerings.size(), icering_mark);
	linemark[0] = resollim_unispot_mark;
	linemark[1] = resollim_unispace_mark;


	for (int i = 0; i < linerr.size(); i++)
	{
		double rr = linerr[i];
		int r = liner[i];
		int mark = linemark[i];


		// linepattern = {a, b} --> a consecutive marked pixels, 
		// followed by b consecutive unmarked pixels.
		int linepattern[2];
		if (i == 0)    // image resolution method 1, short dashes
		{
			linepattern[0] = 15;
			linepattern[1] = 20;
		}
		else
		{
			if (i == 1)   // image resolution method 2, long dashes
			{
				linepattern[0] = 70;
				linepattern[1] = 50;
			}
			else
			{
				linepattern[0] = 10;
				linepattern[1] = 5;
			}
		}


		int xdmax = min(r, min(finder.lastx-finder.beam_x,finder.beam_x-finder.firstx));
		int ydmax = min(r, min(finder.lasty-finder.beam_y,finder.beam_y-finder.firsty));
		int xdmin = min(0, static_cast<int>(sqrt(rr - ydmax*static_cast<double>(ydmax))));

		int xd = xdmin;
		double yy = rr - xd * static_cast<double>(xd);
		int step = 0;


		while ((xd <= xdmax) && (yy > 0))
		{
			int yd = static_cast<int>(sqrt(yy));

			if (finder.beam_x - xd >= finder.firstx)
			{
				if (finder.beam_y - yd >= finder.firsty)
				{
					pixelmarkers.push_back( point(finder.beam_x-xd, finder.beam_y-yd, mark) );
					pixelmarkers.push_back( point(finder.beam_x-xd+1, finder.beam_y-yd, mark) );
				}
				
				if (finder.beam_y + yd <= finder.lasty)
				{
					pixelmarkers.push_back( point(finder.beam_x-xd, finder.beam_y+yd, mark) );
					pixelmarkers.push_back( point(finder.beam_x-xd+1, finder.beam_y+yd, mark) );
				}
			}

			if (finder.beam_x + xd <= finder.lastx)
			{
				if (finder.beam_y - yd >= finder.firsty)
				{
					pixelmarkers.push_back( point(finder.beam_x+xd, finder.beam_y-yd, mark) );
					pixelmarkers.push_back( point(finder.beam_x+xd-1, finder.beam_y-yd, mark) );
				}
				
				if (finder.beam_y + yd <= finder.lasty)
				{
					pixelmarkers.push_back( point(finder.beam_x+xd, finder.beam_y+yd, mark) );
					pixelmarkers.push_back( point(finder.beam_x+xd-1, finder.beam_y+yd, mark) );
				}
			}


			// yy = r * r - (x + t) * (x + t)
			//    = r * r - x * x - 2 * t * x - t * t

			if (step < linepattern[0])
			{
				xd ++;
				yy -= (xd + xd + 1);
				step ++;
			}
			else
			{
				xd += linepattern[1];
				yy -= (2 * linepattern[1] * xd + linepattern[1] * linepattern[1]);
				step = 0;
			}
		}
	}



	// Mark spot border.

	if (finder.spots.size()>0) {
		for (list<spot>::const_iterator p = finder.spots.begin(); 
			p != finder.spots.end(); p++) {
			if (p->ncloseneighbors > 0)
			{
				for (point_list_t::const_iterator q=p->borderpixels.begin(); 
					q!=p->borderpixels.end(); q++) 
				{
					pixelmarkers.push_back(point(q->x, q->y, spotbor_close_mark));
				}
			}
			else if (p->peak.value >= finder.overloadvalue)
			{
				for (point_list_t::const_iterator q=p->borderpixels.begin(); 
					q!=p->borderpixels.end(); q++) 
				{
					pixelmarkers.push_back(point(q->x, q->y, spotbor_over_mark));
				}

			}
			else if (p->maximas.size() > 1)
			{
				for (point_list_t::const_iterator q=p->borderpixels.begin(); 
					q!=p->borderpixels.end(); q++) 
				{
					pixelmarkers.push_back(point(q->x, q->y, spotbor_mmax_mark));
				}

			}
			else
			{
				for (point_list_t::const_iterator q=p->borderpixels.begin(); 
					q!=p->borderpixels.end(); q++) 
				{
					pixelmarkers.push_back(point(q->x, q->y, spotbor_good_mark));
				}

			}
		}
	}


	for (list<spot>::const_iterator p = finder.spots.begin(); p != finder.spots.end(); p++) 
	{
		for (point_list_t::const_iterator q = p->maximas.begin(); q != p->maximas.end(); q++)
		{
			if (q->value < finder.overloadvalue)
				pixelmarkers.push_back(point(q->x, q->y, maxima_mark));
			else
				pixelmarkers.push_back(point(q->x, q->y, overload_mark));
		}
	}


}



template<class T> void write_smvimg(const string& filename, img_object *img, 
		const constmat<int>& pixelmatrix, const point_list_t& pixelmarkers, bool intvalue)
		//const vector< vector<T> >& pixelmatrix, const point_list_t& pixelmarkers, bool intvalue)
{

	if (intvalue)
	{

		for (int x = 0; x < pixelmatrix.nx; x++)
		{
			int idx = x * pixelmatrix.ny;

			for (int y = 0; y < pixelmatrix.ny; y++)
			{
				img->image[idx++] = pixelmatrix[x][y];
			}
		}

	}
	else
	{
		double maxv = * max_element(pixelmatrix.begin(), pixelmatrix.end());
		double minv = * min_element(pixelmatrix.begin(), pixelmatrix.end());

		
		// Transform from [minv, maxint] to [0, overloadvalue / 2].
		
		int lb = 0;
		int ub = 65535 / 2;
		double slope = (ub - lb) / (maxv - minv);

		for (int x = 0; x < pixelmatrix.nx; x++)
		{ 
			int idx = x * pixelmatrix.ny;
			for (int y = 0; y < pixelmatrix.ny; y++)
			{
				int v = int(lb + (pixelmatrix[x][y] - minv) * slope);
				img->image[idx++] = v;	
			}
		}

	}


	const int yellowpx = 65535;
	const int whitepx = 0;


	for (point_list_t::const_iterator p = pixelmarkers.begin(); 
			p != pixelmarkers.end(); p++) 
	{
		int idx = p->x * pixelmatrix.ny + p->y;

		switch (p->value)
		{
			case 1:  // overload
			case 3:  // good spot 
			case 7:  // ice ring
			case 8:  // resol estimate method 1 
			case 9:  // resol estimate method 2 
				img->image[idx] = yellowpx;	
				break;
			case 2:  // maxima
			case 4:  // close spot
			case 5:  // mmax spot 
			case 6:  // overload spot
				img->image[idx] = whitepx;	
				break;
			default:
				break;
		}
	}



	if (img_write_smv(img, filename.c_str(), 16) != 0) {
		// What is the meaning of this 16?????
		cout << "Error in writing " + filename << endl;
	}

}


void write_int_jpeg(const string& fileprefix, const diffimage& finder,
	const point_list_t& pixelmarkers, const userdata& useropts)
{

	double lowerprct = 0.0001;
	double midprct = 0.998;
	double upperprct = 0.9999;

	int pivotcolor[] = {0, 175, 255};
	double transpower[] = {1.8, 1.0};

	/*
	vector<int> pixelvalues(static_cast<long>(finder.pixelvalue.size()) * finder.pixelvalue[0].size());
	for (int i = 0; i < finder.pixelvalue.size(); i++)
	{
		copy(finder.pixelvalue[i].begin(), finder.pixelvalue[i].end(), 
				pixelvalues.begin() + i * finder.pixelvalue[0].size());
	}
	*/
	vector<int> pixelvalues(finder.pixelvalue.size(), 0);
	copy(finder.pixelvalue.begin(), finder.pixelvalue.end(), pixelvalues.begin());


	vector<int>::iterator new_end = remove_if(pixelvalues.begin(), pixelvalues.end(), 
			bind2nd(greater_equal<int>(), finder.overloadvalue));
	pixelvalues.erase(new_end, pixelvalues.end());


	int loweridx = static_cast<int>( (pixelvalues.size() - 1) * lowerprct );
	int mididx = static_cast<int>( (pixelvalues.size() - 1) * midprct );
	int upperidx = static_cast<int>( (pixelvalues.size() - 1) * upperprct );


	nth_element(pixelvalues.begin(), pixelvalues.begin() + loweridx, pixelvalues.end());
	int lowervalue = pixelvalues[loweridx];

	nth_element(pixelvalues.begin(), pixelvalues.begin() + mididx, pixelvalues.end());
	int midvalue = pixelvalues[mididx];

	nth_element(pixelvalues.begin(), pixelvalues.begin() + upperidx, pixelvalues.end());
	int uppervalue = pixelvalues[upperidx];

	int pivotvalue[] = {lowervalue, midvalue, uppervalue};

	int image_height = finder.pixelvalue.ny; //finder.pixelvalue[0].size();
	int image_width = finder.pixelvalue.nx; //finder.pixelvalue.size();
	long npixels = static_cast<long>(image_height) * image_width;

	unsigned char *dataRGB = new unsigned char[npixels * 3];   


    write_jpeg_transform<int>(finder.pixelvalue, dataRGB, pivotvalue, pivotcolor, transpower);

	if (useropts.writejpg)
	{
		cout << "- Output processed image in JPEG format as file " << fileprefix+".spt.jpg" << endl;
		write_jpeg(fileprefix+".spt.jpg", dataRGB, image_width, image_height, 
			double(useropts.jpgquality), pixelmarkers);
	}


	if (useropts.writejpg_orig)
	{
		point_list_t markers;
		for (point_list_t::const_iterator p = pixelmarkers.begin();
			p != pixelmarkers.end(); p++)
		{
			if (p->value == 1) // overloaded pixel
			{
				markers.push_back(*p);
			}
		}

		cout << "- Output original image in JPEG format as file " << fileprefix+".jpg" << endl;
		write_jpeg(fileprefix+".jpg", dataRGB, image_width, image_height, 
			useropts.jpgquality, markers);
	}

	delete[] dataRGB;
}




//template<class T> void write_jpeg_transform(const vector< vector<T> >& imagedata, 
template<class T> void write_jpeg_transform(const constmat<int>& imagedata, 
	unsigned char * dataRGB,
	const T pivotvalue[], const int pivotcolor[], const double transpower[]) 
{
	// jpgtranspower: (1.5)
	// transformation power. 
	// If < 1, distinction between small pixel values will be stretched (strengthened).
	// if > 1, distinction between large pixel values will be stretched.
	//

	int image_height = imagedata.ny;
	int image_width = imagedata.nx;
	long npixels = static_cast<long>(image_height) * image_width;


	// Y = a * x^p + b
	//   a = (y2 - y1) / (x2^p - x1^p)
	double a1 =  (pivotcolor[1] - pivotcolor[0]) / 
		(pow(pivotvalue[1], transpower[0]) - pow(pivotcolor[0], transpower[0]));
	double b1 = pivotcolor[1] - a1 * pow(pivotvalue[1], transpower[0]);

	double a2 =  (pivotcolor[2] - pivotcolor[1]) / 
		(pow(pivotvalue[2], transpower[1]) - pow(pivotcolor[1], transpower[1]));
	double b2 = pivotcolor[2] - a2 * pow(pivotvalue[2], transpower[1]);


	long idx = 0;
	for (int x=0; x<image_width; x++) 
	{
		for (int y=0; y<image_height; y++) 
		{
			double px = static_cast<double>( imagedata[x][y] );
			int pxcolor;

			if (px < pivotvalue[1])
			{
				pxcolor = static_cast<int>( a1 * pow(px, transpower[0]) + b1 );
			}
			else
			{
				pxcolor = static_cast<int>( a2 * pow(px, transpower[1]) + b2 );
			}

			unsigned char pxv = 255 - min(255, max(0, pxcolor));

			dataRGB[idx++] = pxv;
			dataRGB[idx++] = pxv;
			dataRGB[idx++] = pxv;
		}
	}


}


void write_jpeg(const string& fileout, 
		const unsigned char* datamatrix, const int image_width, const int image_height,
		const double quality, const point_list_t& pixelmarkers)
{
	// quality: (70)
	// Compression level, (1, 100); the bigger, the higher the quality

	int colormap[][3] = {
		{0, 0, 0},          // nocolor
		{255, 255, 0},      // yellow
		{255, 0, 255},      // magenta
		{0, 255, 255},      // cyan
		{255, 0, 0},        // red
		{0, 255, 0},        // green
		{0, 0, 255},        // blue
		{255, 255, 255},    // white
		{0, 0, 0}};         // black
	const int nocolor = 0;
	const int yellow = 1;
	const int magenta = 2;
	const int cyan = 3;
	const int red = 4;
	const int green = 5;
	const int blue = 6;
	const int white = 7;
	const int black = 8;


	FILE * outfile;
	if ((outfile = fopen(fileout.c_str(), "wb")) == NULL) {
		cout << "!! Failed to open file " << fileout << " for output.\n";
		return;
	}


	long npixels = static_cast<long>(image_height) * image_width;
	long npixels_3 = npixels*3;
	unsigned char *dataRGB = new unsigned char[npixels * 3];   
	memcpy(dataRGB, datamatrix, sizeof(unsigned char) * npixels * 3);


	for (point_list_t::const_iterator p = pixelmarkers.begin();
			p != pixelmarkers.end(); p++)
	{
		int clr = 0;

		switch (p->value)
		{
			case 1:  // overloaded
				clr = yellow;
				break;
			case 2:  // maxima
				clr = red;
				break;
			case 3:  // good spot
				clr = green;
				break;
			case 4:  // close spot
				clr = white;
				break;
			case 5:  // mmax spot
				clr = red;
				break;
			case 6:  // overload spot
				clr = yellow;
				break;
			case 7:  // icering
				clr = magenta;
				break;
			case 8:  // resol method 1
				clr = blue;
				break;
			case 9:  // resol method 2
				clr = blue;
				break;
			default:
				break;
		}
		
		if (clr > 0)
		{
			long idx = (p->x * image_height + p->y) * 3;
			if ((idx >= 0) && (idx < npixels_3)) {
				dataRGB[idx] = colormap[clr][0]; 
				dataRGB[idx + 1] = colormap[clr][1];
				dataRGB[idx + 2] = colormap[clr][2];
			}
		}

	}



	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;
	memset(&cinfo, 0, sizeof(cinfo));
	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cinfo);

	cinfo.image_width = image_width;      /* image width and height, in pixels */
	cinfo.image_height = image_height;
	cinfo.input_components = 3;           /* # of color components per pixel */
	cinfo.in_color_space = JCS_RGB;       /* colorspace of input image */
	jpeg_set_defaults(&cinfo);
	jpeg_stdio_dest(&cinfo, outfile);
	jpeg_set_quality(&cinfo, (int)quality, TRUE); 


	jpeg_start_compress(&cinfo, TRUE);
	while (cinfo.next_scanline < cinfo.image_height) 
	{
		JSAMPROW row_pointer = (JSAMPROW)(dataRGB + cinfo.next_scanline*3*image_width);
		(void) jpeg_write_scanlines(&cinfo, &row_pointer, 1);
	}
	jpeg_finish_compress(&cinfo);
	jpeg_destroy_compress(&cinfo);


	fclose(outfile);
	delete[] dataRGB;

}




void write_mosflm(ofstream& spotfile, const diffimage& finder)
{
	if (finder.spots.size() == 0) return;


	vector<int> spotarea;
	vector<double> peakint;
	spotarea.reserve(finder.spots.size());
	peakint.reserve(finder.spots.size());

	for (list<spot>::const_iterator p = finder.spots.begin();
			p != finder.spots.end(); p++) {

		// screening spots
		
		if (p->peak.value >= finder.overloadvalue ||
				p->ncloseneighbors > 0 ||
				p->maximas.size() > 1)
		{
			continue;
		}
		
		// write down properties
		
		spotarea.push_back(p->bodypixels.size());
		peakint.push_back(finder.pixelintensity[p->peak.x][p->peak.y]);
	}


	if (spotarea.size() == 0) return;


	// amount of spots MOSFLM feels comfort with.
	int nspot_mosflm = 300;

	// percentage of spots to keep
	double prct_keep = min(0.95, static_cast<double>(nspot_mosflm) / spotarea.size());

	// The following percentage bound will not result in
	// exactly nspot_mosflm spots, because two criteria are used.
	// But should be close.
	
	double lowprct = (1.0 - prct_keep) * 0.67;
	double upprct = lowprct + prct_keep;
	int lowidx = static_cast<int>( (spotarea.size() - 1) * lowprct );
	int upidx = static_cast<int>( (spotarea.size() - 1) * upprct );
	
	sort(spotarea.begin(), spotarea.end());
	sort(peakint.begin(), peakint.end());


	nth_element(spotarea.begin(), spotarea.begin()+lowidx, spotarea.end());
	int lowarea = spotarea[lowidx];
	nth_element(spotarea.begin(), spotarea.begin()+upidx, spotarea.end());
	int uparea = spotarea[upidx];

	nth_element(peakint.begin(), peakint.begin()+lowidx, peakint.end());
	double lowpeakint = peakint[lowidx];
	nth_element(peakint.begin(), peakint.begin()+upidx, peakint.end());
	double uppeakint = peakint[upidx];


	spotfile << setw(12) << ios::fixed << ios::right << finder.nxs 
		<< setw(12) << ios::fixed << ios::right << finder.nys 
		<< setw(11) << setprecision(8) << ios::fixed << ios::right << finder.pixel_size 
		<< setw(12) << setprecision(6) << ios::fixed << ios::right << 1.0 
		<< setw(12) << setprecision(6) << ios::fixed << ios::right << 0.0 << endl;

	spotfile << setw(12) << setprecision(0) << ios::fixed << ios::right << 1 
		<< setw(12) << setprecision(0) << ios::fixed << ios::right << 1 << endl;

	spotfile << setw(11) << setprecision(5) << ios::fixed << ios::right << finder.beam_center_x 
		<< setw(11) << setprecision(5) << ios::fixed << ios::right << finder.beam_center_y << endl;

	double phihalfrange = finder.osc_range / 2;
	double phipos = finder.osc_start + phihalfrange;

	int ncols = finder.nxs;


	for (list<spot>::const_iterator p=finder.spots.begin(); p!=finder.spots.end(); p++) {
		if (p->peak.value >= finder.overloadvalue ||
				p->ncloseneighbors > 0 ||
				p->maximas.size() > 1 ||
				p->bodypixels.size() < lowarea ||
				p->bodypixels.size() > uparea ||
				finder.pixelintensity[p->peak.x][p->peak.y] < lowpeakint ||
				finder.pixelintensity[p->peak.x][p->peak.y] > uppeakint
				)
		{
			continue;
		}

		double xmm = (p->peak.x + 0.5) * finder.pixel_size;
		double ymm = (p->peak.y + 0.5) * finder.pixel_size;
		// xmm: top -> bottom
		// ymm: left->ios::right 
		spotfile << setw(11) << setprecision(2) << ios::fixed << ios::right << xmm 
			<< setw(10) << setprecision(2) << ios::fixed << ios::right << ymm 
			<< setw(9) << setprecision(3) << ios::fixed << ios::right << phihalfrange 
			<< setw(9) << setprecision(3) << ios::fixed << ios::right << phipos 
			<< setw(12) << setprecision(1) << ios::fixed << ios::right << finder.pixelintensity[p->peak.x][p->peak.y] 
			<< setw(10) << setprecision(1) << ios::fixed << ios::right << 0.1 << endl;
	}

	spotfile << setw(11) << setprecision(2) << ios::fixed << ios::right << -999.0 
		<< setw(10) << setprecision(2) << ios::fixed << ios::right << -999.0
		<< setw(9) << setprecision(3) << ios::fixed << ios::right << -999.0
		<< setw(9) << setprecision(3) << ios::fixed << ios::right << -999.0
		<< setw(12) << setprecision(1) << ios::fixed << ios::right << -999.0
		<< setw(10) << setprecision(1) << ios::fixed << ios::right << -999.0
		<< endl;

	spotfile << setw(7) << ios::fixed << ios::right << finder.nxs 
		<< setw(6) << ios::fixed << ios::right << finder.nys 
		<< setw(10) << setprecision(4) << ios::fixed << ios::right << finder.pixel_size 
		<< setw(5) << setprecision(0) << ios::fixed << ios::right << 1 << endl;
}

void parsefilename(const string& fullname, string& pathname, string& filename)
{
	int idx = fullname.rfind("/");
	if (idx < fullname.length()) {
		pathname = fullname.substr(0, idx + 1);
		filename = fullname.substr(idx+1, fullname.length() - idx - 1);
	} else {
		pathname = "";
		filename = fullname;
	}
}
