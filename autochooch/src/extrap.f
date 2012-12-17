c     
c===================================================================
c     Construct a full spectrum out to high and low energies using
c     McMasters tables of x-ray cross-sections.
c
c
      subroutine extrap ( npoints , name , z , fpptmp )
c
c
      include 'size.fh'
      include 'energy.fh'
c
      integer     z , er
      character*2 name
      character*1 unit
      real enadd
      real        energy(9) , xsec(10) , fly(4)
      real        fpptmp(nptot)
      real keven
      logical erfun
c
      erfun = .FALSE.
      unit  = 'B'
c
c     
c     extrapolate out to low energy regime
c     
      enadd=0.0
      do i = nsta - 1 , 1 , -1
         enadd = enadd + dx
         xener(i) = ener(1) - enadd
         keven = xener(i) / 1000.0
         call mucal ( keven , name , z , unit , xsec , energy , fly ,
     .         erfun , er )
c     
c     convert to fpptmp using optical theorem.
c     
c     f" = m_e * c * e_0 * E * e * mu
c          ----------------------
c              h/2pi * e * e
c
c     Reduce it a bit and we get this
c
c         fpptmp(i) = ( 9.10953 * 2.99792 * 8.85419 * xener(i) * xsec(4) 
c     .         * 1e-10) /( 1.054588 * 1.60219 )
c
c     Multiplying everything out comes to ....
c
         fpptmp(i) = 143.10935E-10 * xener(i) * xsec(4)
c     
      end do
c
c     Update actual elolim value
c
      elolim = xener(1)
      
c     extrapolate out in high energy regime
c     
      enadd=0.0
c      write(6,*) 'Doiny high enery extrap'
c      write(6,*) nend , nptot , npoints
      do i = nend + 1 , nptot
         enadd = enadd + dx
         xener(i) = ener(npoints) + enadd
         keven = xener(i) / 1000.0
         call mucal ( keven , name , z , unit , xsec , energy , fly ,
     .         erfun , er )
c     
c     convert to fpptmp using optical theorem.
c     
         fpptmp(i) = 143.10935E-10 * xener(i) * xsec(4)
C     
C     Test for high energy limit
C     
         if (xener(i) .ge. ehilim ) then
            ehilim=xener(i)
            npehi=i
            goto 45
         end if
      end do
c     write(6,1000)title
c     
c     If we run out of possible array points then high energy limit
c     ehilim is set to maximum possible given array sizes
c
c     Update actual ehilim value and number of points in extended
c     spectrum
c
      ehilim = xener(i)
      npehi = nptot
C
C
C
 45   return
      end





