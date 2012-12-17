#include <LabelitMarkup.h>
#include "point_t.h"

static double pi = 3.14159265;

inline double ver_distance(double Ax,double Ay, double Bx, double By){
  return std::sqrt( (Ax-Bx)*(Ax-Bx) + (Ay-By)*(Ay-By) );
}

enum direction { HORIZONTAL, VERTICAL };
enum motion { ENTERING, LEAVING };

struct IntersectionPoint {
   point_t circle_square_intersect;
   point_t circle_center;
   double radius;
   double Angle_deg;
   motion topo;
};

typedef std::vector<IntersectionPoint> arc_end_t;
typedef arc_end_t::iterator Ran;

struct BoundaryOfSquare {

  direction line_direction;
  int interior_sign; //+1: interior is above horizontal or right of vertical; -1 otherwise
  int constant_index() const {
    return (line_direction==HORIZONTAL ? 1 : 0);
  }
  int varying_index() const {
    return (line_direction==HORIZONTAL ? 0 : 1);
  }
  double constant, lower_bound, upper_bound;
  BoundaryOfSquare(direction d, double con, double low, double hi, int sign):
    line_direction(d),constant(con),lower_bound(low),upper_bound(hi),
    interior_sign(sign){}

  void store_line_intersection_points (const point_t& center,
                const double& radius, arc_end_t* intersection_list,
                bool* circle_within_square) const
  {
    if ( interior_sign*(center[constant_index()] - constant) < 0 ) {
      *circle_within_square = false;
    }
    // step 1
    if ( center[constant_index()] - radius < constant &&
         constant < center[constant_index()] + radius ) {
      // There are two intersection points
      *circle_within_square = false;
      double y = std::sqrt( radius*radius -
                            (center[constant_index()] - constant)*
                            (center[constant_index()] - constant) );
      for (int sign = -1; sign <=1; sign += 2) {
        double varying_value = center[varying_index()] + sign * y;
        // step 2
        if (varying_value > lower_bound && varying_value < upper_bound) {
          // This is a circle - square intersection point.
          // step 3: Now determine if it is entering or leaving
          point_t cs_intersection;
          motion topo;
          if (line_direction == HORIZONTAL) {
            cs_intersection=point_t(varying_value,constant);
          } else {
            cs_intersection=point_t(constant,varying_value);
          }
          point_t clock_vector = cs_intersection - center;
          double angle = std::atan2(clock_vector[1],clock_vector[0]);
          //double derivative_wrt_angle = 2.*std::cos(angle)*std::sin(angle);
          //if (line_direction==VERTICAL) {derivative_wrt_angle *= -1.;}
          double derivative_wrt_angle;
          if (line_direction==VERTICAL) {
            derivative_wrt_angle = -1.*std::sin(angle);
          } else {
            derivative_wrt_angle = std::cos(angle);
          }
          derivative_wrt_angle *= interior_sign;
          topo = derivative_wrt_angle > 0 ? ENTERING : LEAVING;

          IntersectionPoint IP;
          IP.circle_square_intersect = cs_intersection;
          IP.circle_center = center;
          IP.radius = radius;
          IP.Angle_deg = angle*180./pi;
          IP.topo = topo;
          intersection_list->push_back(IP);
        }
      }
    }
  }

};

struct angle_cmp {
  bool operator()(const IntersectionPoint& a, const IntersectionPoint& b) {
    if (a.Angle_deg==b.Angle_deg) {return false;}
    return (a.Angle_deg < b.Angle_deg);
  }
};

typedef std::vector<BoundaryOfSquare> sides;

/* alternate algorithm for computing circular arcs that fall within
   a square.

   1. Compute the circle's intersection with each of the 4 lines that
      bound the square.  For each line there are either 0,1,or 2 intersecting
      points.  Only keep the points on a given line if there are 2.

   case a. If there are no intersection points then the circle lies
           entirely inside.  Use Magick::DrawableCircle
   case b. Continue:

   2. Throw out all points that do not fall on one of the 4 line segments
      defining the square.  Use strict inequalities:
          end1 < acceptable position < end2

   3. Classify each intersection point as either entering or leaving the
      square.

   4. Sort the intersections points in order of increasing theta angle.  If
      the first one is a "leaving" point, add 360 degrees and move it to the
      end of the list.

   5. Iterate through the list and pick pairs. Assert that they are
       [entering,leaving].  Use Magick::DrawableArc for each pair.
*/


void CircleBlock::process(drawlist_t* drawq, Conversion di, options_t* opt, int size){

    drawq->push_back(Magick::DrawableStrokeColor(color));
    drawq->push_back(Magick::DrawableStrokeWidth(opt->ellipseStrokeWidth));
    drawq->push_back(Magick::DrawableFillOpacity(0.) );

    sides Square;
    Square.push_back(BoundaryOfSquare(HORIZONTAL,0,0,size,+1));
    Square.push_back(BoundaryOfSquare(VERTICAL,size,0,size,-1));
    Square.push_back(BoundaryOfSquare(HORIZONTAL,size,0,size,-1));
    Square.push_back(BoundaryOfSquare(VERTICAL,0,0,size,+1));

    for (std::size_t x=0; x<data.size(); ++x){
      std::vector<double> v = data[x];
      double xcen(di.double_image_x_to_display(v[0]));
      double ycen(di.double_image_y_to_display(v[1]));
      point_t center(xcen,ycen); // detector mm coordinates
      double radius = v[2]/di.ratio;
      arc_end_t intersections;
      bool circle_within_square = true;
      //Simplest algorithm takes too much time to draw
      // 7.7 seconds vs. 4.2 seconds with computed arcs
      //drawq->push_back(Magick::DrawableCircle(
      //  xcen, ycen,xcen, ycen+radius) );

      for (sides::const_iterator e=Square.begin(); e!=Square.end(); ++e) {
        e->store_line_intersection_points(center,radius,&intersections,
            &circle_within_square);
      }

      SCITBX_ASSERT(intersections.size()%2 == 0);

      if (circle_within_square) {
        drawq->push_back(Magick::DrawableCircle(xcen,ycen,xcen,ycen+radius));
      } else {
        if (intersections.size()>0) {
          Ran first = intersections.begin();
          Ran last = intersections.end();
          std::sort<Ran,angle_cmp>(first,last,angle_cmp());

          if (intersections.begin()->topo==LEAVING) {
              intersections.begin()->Angle_deg+=360.;
              Ran first = intersections.begin();
              Ran last = intersections.end();
              std::sort<Ran,angle_cmp>(first,last,angle_cmp());
          }
          for (int i = 0; i<intersections.size(); i+=2){
            drawq->push_back(Magick::DrawableArc( xcen-radius, ycen-radius,
                                                  xcen+radius, ycen+radius,
                                                  intersections[i].Angle_deg,
                                                  intersections[i+1].Angle_deg) );

          }
        }
      }
    }
}
