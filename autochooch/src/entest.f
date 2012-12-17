cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c     
      subroutine entest(energy,divjmp,iedge)
c     
c     
c     Subroutine finding out the necessary values for input into
c     the McMaster calculation subroutine. i.e. near which edge
c     the energy is at and if necessary the edge jump value to be 
c     used.
c     
      common enk,enl1,enl2,enl3,enm,ajmpl1,ajmpl2,ajmpl3,ajmpk
      real energy,divjmp
      integer iedge
c     
      if(energy.gt.enk)then
        iedge=4
        divjmp=1.0
      end if
      if(energy.le.enk.and.energy.gt.enl1)then
        iedge=3
        divjmp=1.0
      end if
      if(energy.le.enl1.and.energy.gt.enl2)then
        iedge=3
        divjmp=ajmpl1
      end if
      if(energy.le.enl2.and.energy.gt.enl3)then
        iedge=3
        divjmp=ajmpl1*ajmpl2
      end if
      if(energy.le.enl3.and.energy.gt.enm)then
        iedge=2
        divjmp=1.0
      end if
      if(energy.le.enm)then
        iedge=1
        divjmp=1.0
      end if
      end
