#include "libdistl.h"

using namespace Distl;

void
spot_base::find_weighted_center(image_rawdata_t const& pixelvalue,
                                flag_array_t const& pixelismaxima){
  centerx = 0.0;
  centery = 0.0;
  m_PixelValueSum = 0.0;
  for (point_list_t::const_iterator q=bodypixels.begin(); q!=bodypixels.end(); q++) {
    double pxv = static_cast<double>(pixelvalue[q->x][q->y]);
    centerx += q->x * pxv;
    centery += q->y * pxv;
    m_PixelValueSum += pxv;
    if (pixelismaxima[q->x][q->y]) {
      maximas.push_back( *q );
    }
  }	

  // Calculate spot center, weighted by body pixel value.
  centerx /= m_PixelValueSum;
  centery /= m_PixelValueSum;
}

double 
spot_base::shape() const {

  // Calculate spot shape.

  double varborderdist = 0;
  double meanborderdist = 0;

  for (point_list_t::const_iterator q=borderpixels.begin(); q!=borderpixels.end(); q++) {	
	  double dist = (q->x - centerx)*(q->x - centerx) + (q->y - centery)*(q->y - centery);
	  meanborderdist += sqrt(dist);
	  varborderdist += dist;
  }
  meanborderdist /= borderpixels.size();
  varborderdist = varborderdist / borderpixels.size() - meanborderdist * meanborderdist;

  double m_shape = sqrt(varborderdist) / meanborderdist;

  // Transform the above value to (1, 0) from (0.12, 0.25), 
  // corresponding to bounds of usual values.
  // slope = 1.0 / (0.12 - 0.25) = -7.69;
  // intercept = -slope * 0.25 = 1.92.
  m_shape = -7.69 * m_shape + 1.92;
  return m_shape;
}
