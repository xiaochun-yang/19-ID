ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c     
      subroutine eqofline(x1,y1,x2,y2,m,c)
c     
c     
c     For a straight line described by the equation y=mx+c calculate
c     and return the values of m and c given the coordinates of any two
c     points on the line.
c     
      real x1,y1,x2,y2,m,c
c     
      m=(y1-y2)/(x1-x2)
      c=y1-(m*x1)
c     
      end
