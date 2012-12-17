#ifndef DIFFIMAGE_MAGIKMARKUP_H
#define DIFFIMAGE_MAGIKMARKUP_H

#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <list>
#include <cmath>
#include <Magick++.h>
#include <scitbx/error.h>
#include <markup.h>
#include <xos.h>
#include <XosException.h>

typedef std::list<Magick::Drawable> drawlist_t;
typedef unsigned int comment_t;

/**
 * Centralized location to configure options for graphical rendering
 */
struct MarkupProcessingParameters {
  double ellipseStrokeWidth;
  double adhocDotRadius1;
  double adhocDotRadius2;
  inline MarkupProcessingParameters():
    ellipseStrokeWidth(1.),adhocDotRadius1(0.5),adhocDotRadius2(0.25){}
};
typedef MarkupProcessingParameters options_t;

/**
 */
class Conversion
{
public:
	double offsetX;
	double offsetY;
	double ratio;

	/**
	 * Constructor
	 */
	Conversion(const double &ox,const double& oy,const double &ra)
		:offsetX(ox),offsetY(oy),ratio(ra)
	{
	}

	inline double double_image_x_to_display( const double& imageX )
	{
		return (imageX-double(offsetX))/ratio;
	}

	inline double double_image_y_to_display( const double& imageY )
	{
		return (imageY-double(offsetY))/ratio;
	}
};

/**
 * Base class for all shapes
 */
class DrawBlock
{
public:
	/**
	 * Color to draw the shape
	 */
	Magick::ColorRGB color;

	/**
	 * List of data point
	 */
	std::vector<std::vector<double> > data;

	/**
	 * Comment?
	 */
	comment_t tag;

	/**
	 * Constructor
	 */
	DrawBlock(double r,double g,double b,comment_t tag)
		: color(r,g,b),tag(tag)
	{
	}

	virtual ~DrawBlock()
	{
	}

	/**
	 * Add a point to the shape
	 */
	void add(std::vector<double> v)
	{
		data.push_back(v);
	}

	/**
	 * Default method to be overridden by subclasses.
	 */
	virtual void process(drawlist_t*, Conversion di, options_t*, int)
	{
	}
};

/**
 * Circle shape
 */
class CircleBlock: public DrawBlock
{
public:

	/**
	 * Constructor
	 */
	CircleBlock(double r,double g,double b,comment_t tag): DrawBlock(r,g,b,tag)
	{
	}

	/**
	 * Override DrawBlock::process method
	 */
	virtual void process(drawlist_t* drawq, Conversion di, options_t* opt, int size);
};

/**
 * Cross shape
 */
class CrossBlock: public DrawBlock
{
public:
	/**
	 * Constructor
	 */
	CrossBlock(double r,double g,double b,comment_t tag)
		: DrawBlock(r,g,b,tag)
	{
	}

	/**
	 * Override DrawBlock::process method
	 */
	virtual void process(drawlist_t* drawq, Conversion di, options_t* opt, int size)
	{
		drawq->push_back(Magick::DrawableStrokeColor(color));
		drawq->push_back(Magick::DrawableStrokeWidth(1.));
		drawq->push_back(Magick::DrawableFillOpacity(0.) );
		for (std::size_t x=0; x<data.size(); ++x){
			std::vector<double> v = data[x];
			double radius = v[2]/2./di.ratio;
			double xcen(di.double_image_x_to_display(v[0]));
			double ycen(di.double_image_y_to_display(v[1]));
			drawq->push_back(Magick::DrawableLine(
			xcen-radius, ycen,xcen+radius, ycen) );
			drawq->push_back(Magick::DrawableLine(
			xcen, ycen-radius,xcen, ycen+radius) );
		}
	}
};

/**
 * Ellipse shape
 */
class EllipseBlock: public DrawBlock
{
public:
	/**
	 * Constructor
	 */
	EllipseBlock(double r,double g,double b,comment_t tag)
		: DrawBlock(r,g,b,tag)
	{
	}

	/**
	 * Override DrawBlock::process method
	 */
	virtual void process(drawlist_t* drawq, Conversion di, options_t* opt, int size)
	{
		drawq->push_back(Magick::DrawableStrokeColor(color));
		drawq->push_back(Magick::DrawableStrokeWidth(opt->ellipseStrokeWidth));
		drawq->push_back(Magick::DrawableFillOpacity(0.) );
		for (int x=0; x<data.size(); ++x){
			std::vector<double> v = data[x];
			double xcen(di.double_image_x_to_display(v[0]+0.5));
			double ycen(di.double_image_y_to_display(v[1]+0.5));
			double pi = 2.*std::acos(0.);
			double costh(std::cos((pi/180.)*v[4]));
			double sinth(std::sin((pi/180.)*v[4]));
			drawq->push_back(Magick::DrawableRotation(v[4]) );
			double xcenpr(costh*xcen + sinth*ycen);
			double ycenpr(-sinth*xcen + costh*ycen);
			drawq->push_back(Magick::DrawableEllipse(
			xcenpr, ycenpr ,v[2]/di.ratio,v[3]/di.ratio, 0.0,360.0) );
			drawq->push_back(Magick::DrawableRotation(-v[4]) );
		}
	}

};

/**
 * Dot shape
 */
class DotBlock: public DrawBlock
{
public:
	/**
	 * Constructor
	 */
	DotBlock(double r,double g,double b,comment_t tag)
		: DrawBlock(r,g,b,tag)
	{
	}

	/**
	 * OVerride DrawBlock::process method
	 */
	virtual void process(drawlist_t* drawq, Conversion di, options_t* opt, int size)
	{
		double adhoc_radius;
		if (tag==1024){adhoc_radius = opt->adhocDotRadius1/di.ratio;}
		else {adhoc_radius = opt->adhocDotRadius2/di.ratio;}
		drawq->push_back(Magick::DrawableStrokeColor(color));
		drawq->push_back(Magick::DrawableFillColor(color));
		drawq->push_back(Magick::DrawableStrokeWidth(0.0));
		drawq->push_back(Magick::DrawableFillOpacity(1.) );
		for (int x=0; x<data.size(); ++x){
			std::vector<double> v = data[x];
			double xcen(di.double_image_x_to_display(v[0]+0.5));
			double ycen(di.double_image_y_to_display(v[1]+0.5));
			drawq->push_back(Magick::DrawableCircle(
			xcen, ycen,xcen, ycen+adhoc_radius) );
		}
	}
};

/**
 * Image markup class, containing a list of drawable shapes,
 * e.g. circles, ellipes and etc.
 */
class LabelitMarkup : public Markup
{
public:

	static xos_mutex_t magick_mutex;
	//
	std::size_t dataseek;

	// List of markup shapes
	std::vector<DrawBlock*> blocks;

	// binary file format version
	unsigned short m_version;

    // adjustable rendering parameters
    options_t opt;

	/**
	 * Default constructor
	 */
	LabelitMarkup(){
		init();
	}

  	/**
	 * Constructor, reading and parsing a markup file
	 */
	LabelitMarkup(const char* filename);

  	/**
	 * Destructor: cleanup some pointers
	 */
	virtual ~LabelitMarkup();

	/**
	 * Parse markup file
	 */
	virtual void parse_markup();

	/**
	 * Returns true if this is an image markup file.
	 */
	virtual bool image_has_markup()
	{
		return (dataseek>0);
	}

	virtual void draw_markup(int sizeX, int sizeY, double offsetX, double offsetY, double ratio, const void* buffer)
	{
		if (!image_has_markup())
			return;

		Magick::Image mg_image( sizeY, sizeX, "RGB", Magick::CharPixel, (const void*)buffer );
		draw_blocks(mg_image,Conversion(offsetX,offsetY,ratio));
		mg_image.write(0,0,sizeY, sizeX, "RGB", Magick::CharPixel, (void*)buffer);

	}

private:
	/**
	 * Use image magik to draw markup shapes on image
	 */
	inline void draw_blocks(Magick::Image& im, Conversion di)
	{
		//computed arcs assume square images, for now
		SCITBX_ASSERT(im.rows() == im.columns());
		lock();
		for (std::size_t x = 0; x < blocks.size(); ++x) {
			drawlist_t drawq;
			blocks[x]->process(&drawq,di,&opt,im.rows());
			// This line needs to be protected by a mutex or the image server
			// will crash with a segfault.
			im.draw(drawq);
		}
		unlock();
	}
	void lock();
	void unlock();
	void init();
};

#endif // DIFFIMAGE_MAGIKMARKUP_H
