      Program Benny
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c G.Evans     BENNY 27th March 1998
c             Fluorescence data normalisation
c             Manual or automated polynomial fitting to below
c             and above edge region.
c             Smoothing of raw data and derivative calculation
c
c     Incorporated subroutine by H.J. Woltring to smooth data using
c     splines and incorporated PGPLOT subroutines and my own code
c     to handle the fluorescence data and display it.
c
c     31st October 2000: Autobenny v1.0 by Ashley Deacon, still needs 
c     some tidying up, to divide main program into convenient subroutines
c
c     28th June  1999 : v3.01 Included recommendation by Dave Love for
c     a more robust determination of min amd max limits for raw 
c     data values.
c
c     17th March 1998 : v3.0  Incorporated subroutine by Shampine, L. F.,
c     Davenport, S. M. & Huddleston, R. E. to perform polynomial fit
c     to above and below edge data to enable better background 
c     subtraction.
c
c
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c--------editorial remark by Eric Grosse, 14 Jun 87-------------
c  If you plan to use this to automatically mininize GCV, read the
c  comments very carefully and run tests.  For example, on a problem
c  where the optimal smoothing parameter was about .69 I found that
c       spar=.7
c       gcvspl(...,2,spar,...)
c  failed, but
c       spar=.7
c       gcvspl(...,1,spar,...)
c       gcvspl(...,-2,spar,...)
c  worked fine.
c  On Unix systems, some of the less portable syntax can be removed by
c  filtering with the following:
c	sed '/!.*/s///
c		/TYPE/s//PRINT/
c		/ACCEPT/s//READ/
c		/^D/d'
c--------------------------------------------------------------------
C GCV.FOR, 1986-02-11
C
C Author: H.J. Woltring
C
C Organizations: University of Nijmegen, and
C                Philips Medical Systems, Eindhoven
C                (The Netherlands)
C
C**********************************************************************
C
C       Testprogramme for generalized cross-validatory spline smoothing
C       with subroutine GCVSPL and function SPLDER using the data of
C       C.L. Vaughan, Smoothing and differentiation of displacement-
C       time data: an application of splines and digital filtering.
C       International Journal of Bio-Medical Computing 13(1982)375-382.
C
C       The only subprogrammes to be conventionally called by a user
C       are subroutine GCVSPL for calculating the spline parameters,
C       and function SPLDER for calculating the spline function and its
C       derivatives within the knot range.  See the comments in the
C       headers of these subprogrammes for further details.
C
C       The programme types out statistics on the estimation procedure
C       and on the estimated second derivatives. If the DEBUG-lines are
C       compiled, also the raw data and the estimated spline values,
C       first and second derivatives at the knot positions are typed.
C
C**********************************************************************
C
c      PROGRAM GCV       !REAL*8
C
      IMPLICIT REAL*8 (A-H,O-Z), LOGICAL (L)
      PARAMETER ( K=1, NN=5000, MM=10, MM2=MM*2, NWK=NN+6*(NN*MM+1) )
      DIMENSION XTMP(NN), X(NN), Y(NN), WX(NN), C(NN), WK(NWK), Q(0:MM),
     +    V(MM2)
      DIMENSION XIN(NN)
      real ynor(NN),xout(NN),der0(NN),der1(NN),
     +     der2(NN),der3(NN),xraw(NN),yraw(NN)
      real yshift(NN),ycum(NN)
      real yfithi(NN),yfitlo(NN)
      real xmin,xmax,ymin,ymax,ymino,ymaxo,xcor,ycor,xold
      real xdum,ydum,ybelow,yabove,xlow,xhigh
      real ytotal,ymean,devsq,rmsd, shift_total, shift_mean
      real avder0,avder1,avder2,avder3,s_total,s,var,skew,sdev
      real dsqder0,dsqder1,dsqder2,dsqder3
      real rmsder0,rmsder1,rmsder2,rmsder3
      real dder0,dder1,dder2,dder3
      real sdev0,sdev1,sdev2,sdev3
      real presdev0,presdev1,presdev2,presdev3
      real postsdev0,postsdev1,postsdev2,postsdev3
      real preav0,preav1,preav2,preav3
      real postav0,postav1,postav2,postav3
      real varder0,varder1,varder2,varder3
      real min_edge, max_edge, biggest_size, biggest_width
      real previous_biggest_size
      real xprelo,xprehi,xpostlo,xposthi
      integer biggest_edge,old_edge_start,old_edge_end
      integer pgbeg
      integer num,icor,ipow,mord,npoints,npout
      integer col0,col1,col2,col3,col4,col5,col6,col7,col8,col9
      integer start_edge(NN),end_edge(NN),num_edges, edge_label(NN)
      character*1 ch
      character*80 title
      character*20 text1
      common/limits/xmin,xmax,ymin,ymax
      character*15 uniqueName
      character*25 smooth_exp
      character*26 smooth_norm
      character*4 bip
c
c
      SCALE = 125D-3 / DATAN(1D0)         !1/(2*PI)
C
C***  Create time array (knot array)
C
c
c     Read commandline arguments
      if (iargc().eq.1) then
        call getarg(1, uniqueName)
        bip='.bip'
        smooth_exp='smooth_exp' // uniqueName
        smooth_norm='smooth_norm' // uniqueName

        open(unit=1,name=('rawdata' // uniqueName),status='old')
c     	open(unit=2,name=('gcvout' // uniqueName),status='unknown')
        open(unit=3,name=('splinor' // uniqueName),status='unknown')
        open(unit=4,name=('splinor_raw' // uniqueName),
     6       status='unknown')
        open(unit=5,name=(smooth_exp // bip),status='unknown')
        open(unit=7,name=(smooth_norm // bip),status='unknown')
        open(unit=8,name=('pre_poly' // uniqueName),status='unknown')
        open(unit=9,name=('post_poly' // uniqueName),status='unknown')
      else
      	write(6, '(A20)') 'BAD'
        open(unit=1,name='rawdata',status='old')
c       open(unit=2,name='gcvout',status='unknown')
        open(unit=3,name='splinor',status='unknown')
        open(unit=4,name='splinor_raw',status='unknown')
        open(unit=5,name='smooth_exp.bip',status='unknown')
        open(unit=7,name='smooth_norm.bip',status='unknown')
        open(unit=8,name='pre_poly',status='unknown')
        open(unit=9,name='post_poly',status='unknown')
      end if
c
      write(6,'(/A43/)')' ******************************************'
      write(6, '(A43)' )'    AutoBenny - Version 1.0 31st Oct. 2000'
      write(6, '(A43)' )'    based on '
      write(6, '(A43)' )'    Benny - Version 3.01  28th June 1999   '
      write(6,'(/A43/)')' ******************************************'

      band=1.0e-4
c
c     Initialise a flag for the spline routine
c
      FLAG=0

c
c Initialise some variables
c
      ytotal=0.0
      ymean=0.0
      shift_total=0.0
      shift_mean=0.0
c
c Read raw data file
c
      write(6,*)' BENNY_STATUS: reading data '
      read(1,'(a80)') title
      read(1,*) npoints
      do IX = 1 , npoints
         read(1,*,end=2999)xraw(IX),yraw(IX)
         ytotal=ytotal+yraw(IX)
       if (IX.EQ.1) then
        ymin = yraw (IX)
        ymax = yraw (IX)
        yshift(IX) = 0
        ycum(IX) = yshift(IX)
       else  
        yshift(IX) = yraw(IX)-yraw(IX-1)
        shift_total = shift_total + yshift(IX)
        if ((ycum(IX-1).LE.0).AND.(yshift(IX).LE.0)) then
              ycum(IX) = ycum(IX-1) + yshift(IX)
        else if ((ycum(IX-1).GE.0).AND.(yshift(IX).GE.0)) then
              ycum(IX) = ycum(IX-1) + yshift(IX)
        else 
              ycum(IX) = yshift(IX)
        end if           
       
        if (xraw(IX) .LE. xraw(IX-1)) then
              write(6,'(A,I5)')' Error at data point ' , IX
              write(6,'(A)')' Energy scale not increasing '
              goto 2999
        end if
       end if
         if(yraw(IX).gt.ymax)ymax=yraw(IX)
         if(yraw(IX).lt.ymin)ymin=yraw(IX)
      end do

      write(6,'(A,F12.6,A)')' Scan of ' , xraw(npoints)-xraw(1), ' eV'
      write(6,'(A,I5,A)')' In ', npoints, ' steps (may be unequal)'
      ymino=ymin
      ymaxo=ymax
 19   xmin=xraw(1)
      xmax=xraw(npoints)
      ymean=ytotal/npoints
      write(6,'(A,F18.6)')' Minimum intensity is   ', ymin
      write(6,'(A,F18.6)')' Maximum intensity is   ', ymax
      write(6,'(A,F18.6)')' Mean intensity is      ', ymean
      shift_mean=shift_total/(npoints-1)

c
c Now calculate the rmsd
c
      write(6,*)' BENNY_STATUS: smoothing data '
      devsq=0.0
      do IX=2,npoints
       devsq=devsq+((yshift(IX)-shift_mean)*(yshift(IX)-shift_mean))
      end do
      rmsd=sqrt(devsq/(npoints-1))

c
c Now calculate the skewness
c
      var=0.0
      s_total=0.0
      skew=0.0
      do IX=1,npoints
       s=yraw(IX)-ymean
       s_total=s_total+s
       var=var+(s*s)
       skew=skew+(s*s*s) 
      end do
      var=(var-s_total**2/npoints)/(npoints-1)
      sdev=sqrt(var)
      if (var.ne.0.0) then
      skew=skew/(npoints*sdev**3)
      end if

c      write(6,'(A,F18.6)')' Skew for spectrum is ', skew
c      if (skew.lt.0) then 
c            write(6,*)'*** WARNING: skewness of scan is negative ***'
c      end if


c
c Cloned section from later added by Ashley to smooth the 
c experimental curve for autochooch to help find edge 
c
c End of cloned section is commented below
c
      do ix = 1 , npoints
         xin(ix)=xraw(ix)
         y(ix)=yraw(ix)
      end do
c
c Prepare data for Spline fitting routine
c
      do 910 ix=1,npoints
         wx(ix)=1d0
         wy=1d0
 910  continue
      xfst=xin(1)
      at=(xin(npoints)-xin(1))/(npoints-1)
      do 911 ix=1,nn
         x(ix) = xin(ix)-xfst
 911  continue
c
c Set flags for cubic spline fitting M, MODE, VAL
c
      m=3
      mode=2
      val=1
      n=npoints
c
c Get parameters (see comments in subroutine GCVSPL) or exit
c
 620  if (flag.gt.0) m=-1
      if ((n.lt.2*m).or.(n.gt.nn)) n = nn
      if ((mode.eq.0).or.(iabs(mode).gt.5).or.
     +   (   m.le.0).or.(m.gt.mm)) goto 998    !exit
c
c Assess spline coefficients and type resulting statistics
c
      call gcvspl (x,y,nn,wx,wy,m,n,k,mode,val,c,nn,wk,ier)
      if (ier.ne.0) then
         print 920, ier
 920     format (' error #',I3)
         if (ier.eq.2) write(6,*) 'Error in energy scale'
         flag=1
         go to 620              !next trial
      else
         var=wk(6)
         if (wk(4).eq.0d0) then
            fre= 5d-1/at
         else
            fre= scale*(wk(4)*at)**(-0.5/m)
         endif
      endif
c
c Reconstruct data, type i, x(i), y(i), s(i), s'(i), s''(i) [D]
c Assess and type acceleration mean and standard deviation
c

      idm=min0(3,m)
c      idm=3
      daccav=0d0
      daccsd=0d0
      q(2)=0d0
c
c Select energy step for splined data and set up array
c Choose to be equal to Si(111) energy width 1.4x10-4/4
c
      enstep=xin(1)*band/3
      write(6,*) 'The energy step for smoothing is', enstep
      erange=xin(npoints)-xin(1)
      npout=(erange/enstep)

      meander0=0
      meander1=0
      meander2=0
      meander3=0

      DO 640 I=1,npout
c
c Now read spline function at strictly evenly increasing energy points
c Create array of energy step equally spaced
c
         xtmp(I)=enstep*(I-1)
         J = I
         do 630 ider=0,idm
            q(ider) = splder(ider,m,n,xtmp(I),x,c,j,v)
 630     continue
         xout(I)=xtmp(I)+xfst
         der0(I)=Q(0) 
         avder0=avder0+der0(I)
         der1(I)=Q(1)
         avder1=avder1+der1(I)
         der2(I)=Q(2)
         avder2=avder2+der2(I)
         der3(I)=Q(3)
         avder3=avder3+der3(I)
         daccav = daccav + q(2)
         daccsd = daccsd + q(2)*q(2)
         write(4,751) xout(I),(q(ider), ider=0,idm)
 751     format(5F12.6)
 640  continue
      accav = daccav/n
      accsd = dsqrt((daccsd-accav*daccav)/(n-1))
      ymin=ymin-0.2
      ymax=ymax*1.1
c
c End of cloned section added by Ashley
c

c ***Output the smoothed spectrum to a file
c ***ie. xout and der0
c
c ***Write out header info to unit 5

      write(5,*)'_graph_title.text "Smoothed scan"'

      write(5,*)' '
      write(5,*)'_graph_axes.xLabel "Energy (eV)"'            
      write(5,*)'_graph_axes.yLabel "Fluoresence"'
      write(5,*)'_graph_axes.x2Label ""'            
      write(5,*)'_graph_axes.y2Label ""'

      write(5,*)' '
      write(5,*)'_graph_background.showGrid 1'

      write(5,*)' '
      write(5,*)'data_'
      write(5,*)'_trace.name smooth'            
      write(5,*)'_trace.xLabels "{Energy (eV)}"'
      write(5,*)'_trace.hide 0'

      write(5,*)' '
      write(5,*)'loop_'            
      write(5,*)'_sub_trace.name'
      write(5,*)'_sub_trace.yLabels'
      write(5,*)'_sub_trace.color'
      write(5,*)'_sub_trace.width'
      write(5,*)'_sub_trace.symbol'
      write(5,*)'_sub_trace.symbolSize'
      write(5,*)'smooth "{Smoothed fluoresence} {Fluoresence}" 
     + purple 2 none 2'
 
      write(5,*)' '
      write(5,*)'loop_'
      write(5,*)'_sub_trace.x'
      write(5,*)'_sub_trace.y1'

c***Write out data info to unit 5
      do 645 I=1,NPOUT
      write(5,*)xout(I),der0(I)
 645  continue 
      close(5)

      write(6,*) ' BENNY_STATUS: writing file smooth_exp.bip'

c
c Now analyze smoothed experimental spectrum to determine low 
c and high energy regions
c
      avder0=avder0/npout
      avder1=avder1/npout
      avder2=avder2/npout
      avder3=avder3/npout

c      write(6,'(A,F18.6)') ' Mean of der0 ', avder0
c      write(6,'(A,F18.6)') ' Mean of der1 ', avder1
c      write(6,'(A,F18.6)') ' Mean of der2 ', avder2
c      write(6,'(A,F18.6)') ' Mean of der3 ', avder3   

      dsqder0=0
      dsqder1=0
      dsqder2=0
      dsqder3=0
      dder0=0
      dder1=0
      dder2=0
      dder3=0
      varder0=0
      varder1=0
      varder2=0
      varder3=0

      do I=1,npout
        dsqder0=dsqder0+((der0(I)-avder0)*(der0(I)-avder0))     
        dsqder1=dsqder1+((der1(I)-avder1)*(der1(I)-avder1))     
        dsqder2=dsqder2+((der2(I)-avder2)*(der2(I)-avder2))     
        dsqder3=dsqder3+((der3(I)-avder3)*(der3(I)-avder3))     
        dder0=dder0+(der0(I)-avder0)
        dder1=dder1+(der1(I)-avder1)
        dder2=dder2+(der2(I)-avder2)
        dder3=dder3+(der3(I)-avder3)
      end do

      rmsder0=sqrt(dsqder0/npout)
      rmsder1=sqrt(dsqder1/npout)
      rmsder2=sqrt(dsqder2/npout)
      rmsder3=sqrt(dsqder3/npout)

c      write(6,'(A,F18.6)') ' RMSD of der0 ', rmsder0
c      write(6,'(A,F18.6)') ' RMSD of der1 ', rmsder1
c      write(6,'(A,F18.6)') ' RMSD of der2 ', rmsder2
c      write(6,'(A,F18.6)') ' RMSD of der3 ', rmsder3

c      write(6,'(A,F18.6)') ' d of der0 ', dder0
c      write(6,'(A,F18.6)') ' d of der1 ', dder1
c      write(6,'(A,F18.6)') ' d of der2 ', dder2
c      write(6,'(A,F18.6)') ' d of der3 ', dder3

c      write(6,'(A,F18.6)') 'dsq of der0 ',dsqder0-dder0**2
c      write(6,'(A,F18.6)') 'dsq of der1 ',dsqder1-dder1**2
c      write(6,'(A,F18.6)') 'dsq of der2 ',dsqder2-dder2**2
c      write(6,'(A,F18.6)') 'dsq of der3 ',dsqder3-dder3**2
    
      vpoints=npout

      dsqder0=(dsqder0-dder0**2/vpoints)/(vpoints-1)
      dsqder1=(dsqder1-dder1**2/vpoints)/(vpoints-1)
      dsqder2=(dsqder2-dder2**2/vpoints)/(vpoints-1)
      dsqder3=(dsqder3-dder3**2/vpoints)/(vpoints-1)

c      write(6,'(A,F18.6)') ' VAR of der0 ', dsqder0
c      write(6,'(A,F18.6)') ' VAR of der1 ', dsqder1
c      write(6,'(A,F18.6)') ' VAR of der2 ', dsqder2
c      write(6,'(A,F18.6)') ' VAR of der3 ', dsqder3

      sdev0 = sqrt(dsqder0)
      sdev1 = sqrt(dsqder1)
      sdev2 = sqrt(dsqder2)
      sdev3 = sqrt(dsqder3)

c      write(6,'(A,F18.6)') ' SDEV of der0 ', sdev0
c      write(6,'(A,F18.6)') ' SDEV of der1 ', sdev1
c      write(6,'(A,F18.6)') ' SDEV of der2 ', sdev2
c      write(6,'(A,F18.6)') ' SDEV of der3 ', sdev3

      num_edges=0
      do I=1,npout
      if ( (der1(I).gt.(avder1+2*sdev1)).OR. 
     +     (der1(I).lt.(avder1-2*sdev1)).OR.
     +     (der2(I).gt.(avder2+2*sdev2)).OR.
     +     (der2(I).lt.(avder2-2*sdev2)) ) then
           edge_label(I)=1
           if (I.EQ.1) then
                num_edges=num_edges+1
                start_edge(num_edges)=I
c                write(6,'(A,I8)')' Start of edge at ',I
           else if ((I.EQ.npout).AND.
     +             (edge_label(I-1).NE.1)) then
                   num_edges=num_edges+1
                   start_edge(num_edges)=I
c                   write(6,'(A,I8)')' Start of edge at ',I
                   end_edge(num_edges)=I
c                   write(6,'(A,I8)')' End of edge at ',I
           else if ((I.EQ.npout).AND.
     +             (edge_label(I-1).EQ.1)) then
                   end_edge(num_edges)=I 
c                   write(6,'(A,I8)')' End of edge at ',I
           else if (edge_label(I-1).EQ.0) then
                num_edges=num_edges+1
                start_edge(num_edges)=I
c                write(6,'(A,I8)')' Start of edge at ',I
           end if
      else
         edge_label(I)=0
         if ((I.NE.1).AND.(edge_label(I-1).EQ.1)) then
           end_edge(num_edges)=I-1
c           write(6,'(A,I8)')' End of edge at ',I-1         
         end if
      end if
      end do

c      write(6,'(A,I8)')' Total number of edges ',num_edges

      write(6,*)' BENNY_STATUS: normalising data '

c Identify most significant edge feature

      biggest_size=0.0
      previous_biggest_size=0.0
      biggest_width=0.0
      do I=1,num_edges
         min_edge=der0(start_edge(I))
         max_edge=der0(start_edge(I))

         do J=start_edge(I),end_edge(I)
            if (der0(J).LT.min_edge) then
               min_edge=der0(J)
            else if (der0(J).GT.max_edge) then
               max_edge=der0(J)
            end if
         end do

         if ((max_edge-min_edge).GT.biggest_size) then
            previous_biggest_size=biggest_size
            biggest_size=max_edge-min_edge
            biggest_edge=I
            biggest_width=xout(end_edge(I))- xout(start_edge(I))
c            write(6,'(A,I8)')' The biggest edge is # ',biggest_edge
c            write(6,'(A,F12.6)')' The size is  ',biggest_size
c            write(6,'(A,F12.6)')' Previous was ',previous_biggest_size
c            write(6,'(A,F12.6)')' The width is ', biggest_width
         else if ((max_edge-min_edge).GT.previous_biggest_size) then
            previous_biggest_size=max_edge-min_edge
c            write(6,'(A,F12.6)')' Previous was ',previous_biggest_size
         end if

      end do

 321  continue
c
c Check that the edge is significant and positioned reasonably
c
      edge_error=0.0

      if (xout(start_edge(biggest_edge))-xout(1).le.3.0) then
            write(6,*)
     +' BENNY_ERROR: edge too close start of scan, modify scan range *'
            edge_error=edge_error+1
      else if (xout(npout)-xout(end_edge(biggest_edge)).le.3.0) then
            write(6,*)
     +' BENNY_ERROR: edge too close to end of scan, modify scan range *'
            edge_error=edge_error+1
      end if

      if (edge_error.gt.0.0) then
c      write(6,*)'Number of edge errors is', edge_error
      stop 
      end if

      if (biggest_width.lt.3.0) then 
      write(6,*)' BENNY_WARNING: edge seems too narrow, noisy scan *'
      else if (biggest_width.GT.0.5*(xout(npout)-xout(1))) then
            write(6,*)
     +' BENNY_WARNING: edge takes up over 50% of scan, noisy scan *'
      end if
      
c
c Calculate pre-edge and post-edge sdevs
c
c Pre-edge region first
c
      preav0=0
      preav1=0
      preav2=0
      preav3=0

      do I=1, (start_edge(biggest_edge)-1)
         preav0=preav0+der0(I)
         preav1=preav1+der1(I)
         preav2=preav2+der2(I)
         preav3=preav3+der3(I)
      end do

      vpoints=(start_edge(biggest_edge)-1)

      preav0=preav0/vpoints
      preav1=preav1/vpoints
      preav2=preav2/vpoints
      preav3=preav3/vpoints

      dsqder0=0
      dsqder1=0
      dsqder2=0
      dsqder3=0
      dder0=0
      dder1=0
      dder2=0
      dder3=0
      varder0=0
      varder1=0
      varder2=0
      varder3=0

      do I=1,(start_edge(biggest_edge)-1)
        dsqder0=dsqder0+((der0(I)-preav0)*(der0(I)-preav0))     
        dsqder1=dsqder1+((der1(I)-preav1)*(der1(I)-preav1))     
        dsqder2=dsqder2+((der2(I)-preav2)*(der2(I)-preav2))     
        dsqder3=dsqder3+((der3(I)-preav3)*(der3(I)-preav3))     
        dder0=dder0+(der0(I)-preav0)
        dder1=dder1+(der1(I)-preav1)
        dder2=dder2+(der2(I)-preav2)
        dder3=dder3+(der3(I)-preav3)
      end do

      rmsder0=sqrt(dsqder0/vpoints)
      rmsder1=sqrt(dsqder1/vpoints)
      rmsder2=sqrt(dsqder2/vpoints)
      rmsder3=sqrt(dsqder3/vpoints)

      dsqder0=(dsqder0-dder0**2/vpoints)/(vpoints-1)
      dsqder1=(dsqder1-dder1**2/vpoints)/(vpoints-1)
      dsqder2=(dsqder2-dder2**2/vpoints)/(vpoints-1)
      dsqder3=(dsqder3-dder3**2/vpoints)/(vpoints-1)

      presdev0 = sqrt(dsqder0)
      presdev1 = sqrt(dsqder1)
      presdev2 = sqrt(dsqder2)
      presdev3 = sqrt(dsqder3)

c      write(6,'(A,F18.6)') ' Mean of pre-der0 ', preav0
c      write(6,'(A,F18.6)') ' Mean of pre-der1 ', preav1
c      write(6,'(A,F18.6)') ' Mean of pre-der2 ', preav2
c      write(6,'(A,F18.6)') ' Mean of pre-der3 ', preav3  

c      write(6,'(A,F18.6)') ' SDEV of pre-der0 ', presdev0
c      write(6,'(A,F18.6)') ' SDEV of pre-der1 ', presdev1
c      write(6,'(A,F18.6)') ' SDEV of pre-der2 ', presdev2
c      write(6,'(A,F18.6)') ' SDEV of pre-der3 ', presdev3
c
c Now do the post-edge region
c
      postav0=0
      postav1=0
      postav2=0
      postav3=0

      do I=(end_edge(biggest_edge)+1), npout
         postav0=postav0+der0(I)
         postav1=postav1+der1(I)
         postav2=postav2+der2(I)
         postav3=postav3+der3(I)
      end do

      vpoints=npout-(end_edge(biggest_edge)+1)+1

      postav0=postav0/vpoints
      postav1=postav1/vpoints
      postav2=postav2/vpoints
      postav3=postav3/vpoints

      dsqder0=0
      dsqder1=0
      dsqder2=0
      dsqder3=0
      dder0=0
      dder1=0
      dder2=0
      dder3=0
      varder0=0
      varder1=0
      varder2=0
      varder3=0

      do I=(end_edge(biggest_edge)+1),npout
        dsqder0=dsqder0+((der0(I)-postav0)*(der0(I)-postav0))     
        dsqder1=dsqder1+((der1(I)-postav1)*(der1(I)-postav1))     
        dsqder2=dsqder2+((der2(I)-postav2)*(der2(I)-postav2))     
        dsqder3=dsqder3+((der3(I)-postav3)*(der3(I)-postav3))     
        dder0=dder0+(der0(I)-postav0)
        dder1=dder1+(der1(I)-postav1)
        dder2=dder2+(der2(I)-postav2)
        dder3=dder3+(der3(I)-postav3)
      end do

      rmsder0=sqrt(dsqder0/vpoints)
      rmsder1=sqrt(dsqder1/vpoints)
      rmsder2=sqrt(dsqder2/vpoints)
      rmsder3=sqrt(dsqder3/vpoints)

      dsqder0=(dsqder0-dder0**2/vpoints)/(vpoints-1)
      dsqder1=(dsqder1-dder1**2/vpoints)/(vpoints-1)
      dsqder2=(dsqder2-dder2**2/vpoints)/(vpoints-1)
      dsqder3=(dsqder3-dder3**2/vpoints)/(vpoints-1)

      postsdev0 = sqrt(dsqder0)
      postsdev1 = sqrt(dsqder1)
      postsdev2 = sqrt(dsqder2)
      postsdev3 = sqrt(dsqder3)

c      write(6,'(A,F18.6)') ' Mean of post-der0 ', postav0
c      write(6,'(A,F18.6)') ' Mean of post-der1 ', postav1
c      write(6,'(A,F18.6)') ' Mean of post-der2 ', postav2
c      write(6,'(A,F18.6)') ' Mean of post-der3 ', postav3  

c      write(6,'(A,F18.6)') ' SDEV of post-der0 ', postsdev0
c      write(6,'(A,F18.6)') ' SDEV of post-der1 ', postsdev1
c      write(6,'(A,F18.6)') ' SDEV of post-der2 ', postsdev2
c      write(6,'(A,F18.6)') ' SDEV of post-der3 ', postsdev3

c
c Add any additional points to the edge
c

c      write(6,*) start_edge(biggest_edge), end_edge(biggest_edge)

      old_edge_start=start_edge(biggest_edge)
      old_edge_end=end_edge(biggest_edge)

      num_edges=0
      do I=1,npout
      if (I.LT.old_edge_start) then
         if ( (der1(I).gt.(preav1+3*presdev1)).OR. 
     +        (der1(I).lt.(preav1-3*presdev1)).OR.
     +        (der2(I).gt.(preav2+3*presdev2)).OR.
     +        (der2(I).lt.(preav2-3*presdev2)) ) then
            edge_label(I)=1
            if (I.EQ.1) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
            else if ((I.EQ.npout).AND.
     +               (edge_label(I-1).NE.1)) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
               end_edge(num_edges)=I
c               write(6,'(A,I8)')' End of edge at ',I
            else if ((I.EQ.npout).AND.
     +               (edge_label(I-1).EQ.1)) then
               end_edge(num_edges)=I 
c               write(6,'(A,I8)')' End of edge at ',I
            else if (edge_label(I-1).EQ.0) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
            end if
         else
            edge_label(I)=0
            if ((I.NE.1).AND.(edge_label(I-1).EQ.1)) then
               end_edge(num_edges)=I-1
c               write(6,'(A,I8)')' End of edge at ',I         
            end if
         end if
      else if (I.GT.old_edge_end) then
         if ( (der1(I).gt.(postav1+3*postsdev1)).OR. 
     +        (der1(I).lt.(postav1-3*postsdev1)).OR.
     +        (der2(I).gt.(postav2+3*postsdev2)).OR.
     +        (der2(I).lt.(postav2-3*postsdev2)) ) then
            edge_label(I)=1
            if (I.EQ.1) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
            else if ((I.EQ.npout).AND.
     +               (edge_label(I-1).NE.1)) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
               end_edge(num_edges)=I
c               write(6,'(A,I8)')' End of edge at ',I
            else if ((I.EQ.npout).AND.
     +               (edge_label(I-1).EQ.1)) then
               end_edge(num_edges)=I 
c               write(6,'(A,I8)')' End of edge at ',I
            else if (edge_label(I-1).EQ.0) then
               num_edges=num_edges+1
               start_edge(num_edges)=I
c               write(6,'(A,I8)')' Start of edge at ',I
            end if
         else
            edge_label(I)=0
            if ((I.NE.1).AND.(edge_label(I-1).EQ.1)) then
               end_edge(num_edges)=I-1
c               write(6,'(A,I8)')' End of edge at ',I         
            end if
         end if
      else if ( (I.GE.old_edge_start).AND.
     +          (I.LE.old_edge_end) ) then
         edge_label(I)=1
         if (I.EQ.1) then
             num_edges=num_edges+1
             start_edge(num_edges)=I
c             write(6,'(A,I8)')' Start of edge at ',I
         else if ((I.EQ.npout).AND.
     +           (edge_label(I-1).NE.1)) then
             num_edges=num_edges+1
             start_edge(num_edges)=I
c             write(6,'(A,I8)')' Start of edge at ',I
             end_edge(num_edges)=I
c             write(6,'(A,I8)')' End of edge at ',I
         else if ((I.EQ.npout).AND.
     +           (edge_label(I-1).EQ.1)) then
             end_edge(num_edges)=I 
c             write(6,'(A,I8)')' End of edge at ',I
         else if (edge_label(I-1).EQ.0) then
             num_edges=num_edges+1
             start_edge(num_edges)=I
c             write(6,'(A,I8)')' Start of edge at ',I
         end if  
      end if
      end do
c
c Identify biggest edge again
c

c      write(6,*) ' Repeating edge identification !!'

      biggest_size=0.0

      do I=1,num_edges
         min_edge=der0(start_edge(I))
         max_edge=der0(start_edge(I))

         do J=start_edge(I),end_edge(I)
            if (der0(J).LT.min_edge) then
               min_edge=der0(J)
            else if (der0(J).GT.max_edge) then
               max_edge=der0(J)
            end if
         end do

         if ((max_edge-min_edge).GT.biggest_size) then
            biggest_size=max_edge-min_edge
            biggest_edge=I
c            write(6,'(A,I8)')' The biggest edge is # ',biggest_edge
c            write(6,'(A,F12.6)')' The size is ',biggest_size
         end if
      end do

c      write(6,*) start_edge(biggest_edge), end_edge(biggest_edge)


      if ( (end_edge(biggest_edge)-start_edge(biggest_edge)).GT.
     +      (old_edge_end-old_edge_start)) then 
c      write(6,*)' Edge has increased in size!!!'
      go to 321
      end if
c
c Find first point in spectrum that is not labelled as an edge
c
       i=1
       do while (edge_label(i).NE.0)
         i=i+1
       end do

       xprelo=xout(i)
       j=start_edge(biggest_edge)-1
       xprehi=xout(j)
       do while (xprehi-xprelo.GE.150)
         j=j-1
         xprehi=xout(j) 
       end do
 
c       write(6,*)' Pre points ', start_edge(biggest_edge)-i
c       write(6,*)i,j 
c       write(6,*)' Pre-edge energy ', xprelo,xprehi

       i=npout
       do while (edge_label(i).NE.0)
         i=i-1
       end do

       xposthi=xout(i)
       j=end_edge(biggest_edge)+1
       xpostlo=xout(j)
       do while (xposthi-xpostlo.GE.150)
         j=j+1
         xpostlo=xout(j)                        
       end do

c       write(6,*)' Post points ', i-end_edge(biggest_edge)
c       write(6,*) j,i 
c       write(6,*)' Post-edge energy ', xpostlo,xposthi

c
c Use these points as the pre-edge and post edge polynominal regions
c     

c
c Calculate pre-edge polynominal 
c
      mord=1
      call polyset(npoints,mord,xprelo,xprehi,xraw,yraw,yfitlo)
      do 90 ix=1,npoints
         write(8,*)xraw(ix),yraw(ix),yfitlo(ix)
 90   continue

      close(8)

c
c Calculate post-edge polynominal
c
      mord=1 
      call polyset(npoints,mord,xpostlo,xposthi,xraw,yraw,yfithi)
      do 91 ix=1,npoints
         write(9,*)xraw(ix),yraw(ix),yfithi(ix)
 91   continue

      close(9)

c          
c Normalise data
c
      ymin=100000000
      ymax=0.000
      do ix = 1 , npoints
         xin(ix)=xraw(ix)
         y(ix)=(yraw(ix)-yfitlo(ix))/(yfithi(ix)-yfitlo(ix))
         ynor(ix)=(yraw(ix)-yfitlo(ix))/(yfithi(ix)-yfitlo(ix))
         if(ynor(ix).gt.ymax)ymax=ynor(ix)
         if(ynor(ix).lt.ymin)ymin=ynor(ix)
      end do

c
c ***Write out header info to unit 7

      write(7,*)'_graph_title.text "Normalised scan"'

      write(7,*)' '
      write(7,*)'_graph_axes.xLabel "Energy (eV)"'            
      write(7,*)'_graph_axes.yLabel "Fluoresence"'
      write(7,*)'_graph_axes.x2Label ""'            
      write(7,*)'_graph_axes.y2Label "Normalised fluoresence"'

      write(7,*)' '
      write(7,*)'_graph_background.showGrid 1'

      write(7,*)' '
      write(7,*)'data_'
      write(7,*)'_trace.name normal'            
      write(7,*)'_trace.xLabels "{Energy (eV)}"'
      write(7,*)'_trace.hide 0'

      write(7,*)' '
      write(7,*)'loop_'            
      write(7,*)'_sub_trace.name'
      write(7,*)'_sub_trace.yLabels'
      write(7,*)'_sub_trace.color'
      write(7,*)'_sub_trace.width'
      write(7,*)'_sub_trace.symbol'
      write(7,*)'_sub_trace.symbolSize'
      write(7,*)
     +'normal "{Normalised fluoresence}" blue 1 square 2'
 
      write(7,*)' '
      write(7,*)'loop_'
      write(7,*)'_sub_trace.x'
      write(7,*)'_sub_trace.y1'

c***Write out data info to unit 7
      do 655 I=1,npoints
      write(7,*)xin(I),ynor(I)
 655  continue
 
      close(7)
 
      write(6,*) ' BENNY_STATUS: writing file smooth_norm.bip'

c
c Prepare data for Spline fitting routine
c

 888  do 10 ix=1,npoints
         wx(ix)=1d0
         wy=1d0
 10   continue
      xfst=xin(1)
      at=(xin(npoints)-xin(1))/(npoints-1)
      do 11 ix=1,nn
         x(ix) = xin(ix)-xfst
 11   continue
c
c Set flags for cubic spline fitting M, MODE, VAL
c
      m=3
      mode=2
      val=1
      n=npoints
c
c Get parameters (see comments in subroutine GCVSPL) or exit
c

 20   if(flag.gt.0)m=-1

  710 format(2I10,E15.0,I10)
      if ((n.LT.2*m).OR.(n.GT.nn)) n = nn
      if ((mode.EQ.0).OR.(iabs(mode).GT.5).OR.
     1   (   m.LE.0).OR.(  m.GT.mm)) goto 998    !exit
c
c Assess spline coefficients and type resulting statistics
c
      call gcvspl(x,y,nn,wx,wy,m,n,k,mode,val,c,nn,wk,ier)
      if (ier.NE.0) then
         print 720, ier
  720    format(' error #',I3)
         if (ier.EQ.2) write(6,*) 'Error in energy scale'
         flag=1
         go to 20              !next trial
      else
         var = wk(6)
         if (wk(4).EQ.0d0) then
            fre=5d-1/at
         else
            fre=scale*(wk(4)*at)**(-0.5/m)
         end if
      end if
c
c Reconstruct data, type i, x(i), y(i), s(i), s'(i), s''(i) [D]
c Assess and type acceleration mean and standard deviation
c
c      idm= min0(3,m)
      idm=3
      daccav = 0d0
      daccsd = 0d0
      q(2)   = 0d0
c
c Select energy step for splined data and set up array
c Choose to be equal to Si(111) energy width 1.4x10-4/4
c
      enstep=xin(1)*band/4
      erange=xin(npoints)-xin(1)
      npout=(erange/enstep)
c
c Write header to output file 'splinor'
c
      write(3,739)title
 739  format(a80)
      write(3,741)npout
 741  format(i8)

      DO 40 i=1,npout
c
c Now read spline function at strictly evenly increasing energy points
c Create array of energy step equally spaced
c
         xtmp(i)=enstep*(i-1)
         j=i
         do 30 ider=0,idm
            Q(IDER) = splder(ider,m,n,xtmp(i),x,c,j,v)
   30    continue

         xout(I)=xtmp(i)+xfst
         der0(I)=q(0)
         der1(I)=q(1)
         der2(I)=q(2)
         der3(I)=q(3)
c
c Output smoothed data and derivitives on equi-distanced x scale
c
         write(3,750)XOUT(I), (Q(IDER), IDER=0,IDM)
 750     format(5F13.3)

         daccav=daccav+q(2)
         daccsd=daccsd+q(2)*q(2)
   40 continue

c
c ***Write out header info to unit 7
c
c      write(7,*)'_graph_title.text "Normalised scan"'
c
c      write(7,*)' '
c      write(7,*)'_graph_axes.xLabel "Energy (eV)"'            
c      write(7,*)'_graph_axes.yLabel "Fluoresence"'
c      write(7,*)'_graph_axes.x2Label ""'            
c      write(7,*)'_graph_axes.y2Label "Normalised fluoresence"'
c
c      write(7,*)' '
c      write(7,*)'_graph_background.showGrid 1'
c
c      write(7,*)' '
c      write(7,*)'data_'
c      write(7,*)'_trace.name normal'            
c      write(7,*)'_trace.xLabels "{Energy (eV)}"'
c      write(7,*)'_trace.hide 0'
c
c      write(7,*)' '
c      write(7,*)'loop_'            
c      write(7,*)'_sub_trace.name'
c      write(7,*)'_sub_trace.yLabels'
c      write(7,*)'_sub_trace.color'
c      write(7,*)'_sub_trace.width'
c      write(7,*)'_sub_trace.symbol'
c      write(7,*)'_sub_trace.symbolSize'
c      write(7,*)
c     +'normal "{Normalised fluoresence}" blue 1 circle 2'
c 
c      write(7,*)' '
c      write(7,*)'loop_'
c      write(7,*)'_sub_trace.x'
c      write(7,*)'_sub_trace.y1'
c
c***Write out data info to unit 7
c      do 655 I=1,NPOUT
c      write(7,*)xout(I),der0(I)
c 655  continue
c 
c      close(7)
c 
c      write(6,*) 'File smooth_norm.bip written'

      accav=daccav/n
      accsd=dsqrt((daccsd-accav*daccav)/(n-1))

      ymin=ymin-0.2
      ymax=ymax*1.1
c
c Save limits for redrawing if necessary
c

      emin1=xmin
      emax1=xmax

      xold=1000.0
      ipow=-2

 998  continue
      stop
 2999 write(6,*) ' ERROR: Input data - premature end of file *** '
      stop
      end
c
c*END OF MAIN PROGRAM*
c



C GCVSPL.FOR, 1986-05-12
C
C***********************************************************************
C
C SUBROUTINE GCVSPL (REAL*8)
C
C Purpose:
C *******
C
C       Natural B-spline data smoothing subroutine, using the Generali-
C       zed Cross-Validation and Mean-Squared Prediction Error Criteria
C       of Craven & Wahba (1979). Alternatively, the amount of smoothing
C       can be given explicitly, or it can be based on the effective
C       number of degrees of freedom in the smoothing process as defined
C       by Wahba (1980). The model assumes uncorrelated, additive noise
C       and essentially smooth, underlying functions. The noise may be
C       non-stationary, and the independent co-ordinates may be spaced
C       non-equidistantly. Multiple datasets, with common independent
C       variables and weight factors are accomodated.
C
C
C Calling convention:
C ******************
C
C       CALL GCVSPL ( X, Y, NY, WX, WY, M, N, K, MD, VAL, C, NC, WK, IER )
C
C Meaning of parameters:
C *********************
C
C       X(N)    ( I )   Independent variables: strictly increasing knot
C                       sequence, with X(I-1).lt.X(I), I=2,...,N.
C       Y(NY,K) ( I )   Input data to be smoothed (or interpolated).
C       NY      ( I )   First dimension of array Y(NY,K), with NY.ge.N.
C       WX(N)   ( I )   Weight factor array; WX(I) corresponds with
C                       the relative inverse variance of point Y(I,*).
C                       If no relative weighting information is
C                       available, the WX(I) should be set to ONE.
C                       All WX(I).gt.ZERO, I=1,...,N.
C       WY(K)   ( I )   Weight factor array; WY(J) corresponds with
C                       the relative inverse variance of point Y(*,J).
C                       If no relative weighting information is
C                       available, the WY(J) should be set to ONE.
C                       All WY(J).gt.ZERO, J=1,...,K.
C                       NB: The effective weight for point Y(I,J) is
C                       equal to WX(I)*WY(J).
C       M       ( I )   Half order of the required B-splines (spline
C                       degree 2*M-1), with M.gt.0. The values M =
C                       1,2,3,4 correspond to linear, cubic, quintic,
C                       and heptic splines, respectively.
C       N       ( I )   Number of observations per dataset, with N.ge.2*M.
C       K       ( I )   Number of datasets, with K.ge.1.
C       MD      ( I )   Optimization mode switch:
C                       |MD| = 1: Prior given value for p in VAL
C                                 (VAL.ge.ZERO). This is the fastest
C                                 use of GCVSPL, since no iteration
C                                 is performed in p.
C                       |MD| = 2: Generalized cross validation.
C                       |MD| = 3: True predicted mean-squared error,
C                                 with prior given variance in VAL.
C                       |MD| = 4: Prior given number of degrees of
C                                 freedom in VAL (ZERO.le.VAL.le.N-M).
C                        MD  < 0: It is assumed that the contents of
C                                 X, W, M, N, and WK have not been
C                                 modified since the previous invoca-
C                                 tion of GCVSPL. If MD < -1, WK(4)
C                                 is used as an initial estimate for
C                                 the smoothing parameter p.
C                       Other values for |MD|, and inappropriate values
C                       for VAL will result in an error condition, or
C                       cause a default value for VAL to be selected.
C                       After return from MD.ne.1, the same number of
C                       degrees of freedom can be obtained, for identical
C                       weight factors and knot positions, by selecting
C                       |MD|=1, and by copying the value of p from WK(4)
C                       into VAL. In this way, no iterative optimization
C                       is required when processing other data in Y.
C       VAL     ( I )   Mode value, as described above under MD.
C       C(NC,K) ( O )   Spline coefficients, to be used in conjunction
C                       with function SPLDER. NB: the dimensions of C
C                       in GCVSPL and in SPLDER are different! In SPLDER,
C                       only a single column of C(N,K) is needed, and the
C                       proper column C(1,J), with J=1...K should be used
C                       when calling SPLDER.
C       NC       ( I )  First dimension of array C(NC,K), NC.ge.N.
C       WK(IWK) (I/W/O) Work vector, with length IWK.ge.6*(N*M+1)+N.
C                       On normal exit, the first 6 values of WK are
C                       assigned as follows:
C
C                       WK(1) = Generalized Cross Validation value
C                       WK(2) = Mean Squared Residual.
C                       WK(3) = Estimate of the number of degrees of
C                               freedom of the residual sum of squares
C                               per dataset, with 0.lt.WK(3).lt.N-M.
C                       WK(4) = Smoothing parameter p, multiplicative
C                               with the splines' derivative constraint.
C                       WK(5) = Estimate of the true mean squared error
C                               (different formula for |MD| = 3).
C                       WK(6) = Gauss-Markov error variance.
C
C                       If WK(4) -->  0 , WK(3) -->  0 , and an inter-
C                       polating spline is fitted to the data (p --> 0).
C                       A very small value > 0 is used for p, in order
C                       to avoid division by zero in the GCV function.
C
C                       If WK(4) --> inf, WK(3) --> N-M, and a least-
C                       squares polynomial of order M (degree M-1) is
C                       fitted to the data (p --> inf). For numerical
C                       reasons, a very high value is used for p.
C
C                       Upon return, the contents of WK can be used for
C                       covariance propagation in terms of the matrices
C                       B and WE: see the source listings. The variance
C                       estimate for dataset J follows as WK(6)/WY(J).
C
C       IER     ( O )   Error parameter:
C
C                       IER = 0:        Normal exit
C                       IER = 1:        M.le.0 .or. N.lt.2*M
C                       IER = 2:        Knot sequence is not strictly
C                                       increasing, or some weight
C                                       factor is not positive.
C                       IER = 3:        Wrong mode  parameter or value.
C
C Remarks:
C *******
C
C       (1) GCVSPL calculates a natural spline of order 2*M (degree
C       2*M-1) which smoothes or interpolates a given set of data
C       points, using statistical considerations to determine the
C       amount of smoothing required (Craven & Wahba, 1979). If the
C       error variance is a priori known, it should be supplied to
C       the routine in VAL, for |MD|=3. The degree of smoothing is
C       then determined to minimize an unbiased estimate of the true
C       mean squared error. On the other hand, if the error variance
C       is not known, one may select |MD|=2. The routine then deter-
C       mines the degree of smoothing to minimize the generalized
C       cross validation function. This is asymptotically the same
C       as minimizing the true predicted mean squared error (Craven &
C       Wahba, 1979). If the estimates from |MD|=2 or 3 do not appear
C       suitable to the user (as apparent from the smoothness of the
C       M-th derivative or from the effective number of degrees of
C       freedom returned in WK(3) ), the user may select an other
C       value for the noise variance if |MD|=3, or a reasonably large
C       number of degrees of freedom if |MD|=4. If |MD|=1, the proce-
C       dure is non-iterative, and returns a spline for the given
C       value of the smoothing parameter p as entered in VAL.
C
C       (2) The number of arithmetic operations and the amount of
C       storage required are both proportional to N, so very large
C       datasets may be accomodated. The data points do not have
C       to be equidistant in the independant variable X or uniformly
C       weighted in the dependant variable Y. However, the data
C       points in X must be strictly increasing. Multiple dataset
C       processing (K.gt.1) is numerically more efficient dan
C       separate processing of the individual datasets (K.eq.1).
C
C       (3) If |MD|=3 (a priori known noise variance), any value of
C       N.ge.2*M is acceptable. However, it is advisable for N-2*M
C       be rather large (at least 20) if |MD|=2 (GCV).
C
C       (4) For |MD| > 1, GCVSPL tries to iteratively minimize the
C       selected criterion function. This minimum is unique for |MD|
C       = 4, but not necessarily for |MD| = 2 or 3. Consequently, 
C       local optima rather that the global optimum might be found,
C       and some actual findings suggest that local optima might
C       yield more meaningful results than the global optimum if N
C       is small. Therefore, the user has some control over the
C       search procedure. If MD > 1, the iterative search starts
C       from a value which yields a number of degrees of freedom
C       which is approximately equal to N/2, until the first (local)
C       minimum is found via a golden section search procedure
C       (Utreras, 1980). If MD < -1, the value for p contained in
C       WK(4) is used instead. Thus, if MD = 2 or 3 yield too noisy
C       an estimate, the user might try |MD| = 1 or 4, for suitably
C       selected values for p or for the number of degrees of
C       freedom, and then run GCVSPL with MD = -2 or -3. The con-
C       tents of N, M, K, X, WX, WY, and WK are assumed unchanged
C       if MD < 0.
C
C       (5) GCVSPL calculates the spline coefficient array C(N,K);
C       this array can be used to calculate the spline function
C       value and any of its derivatives up to the degree 2*M-1
C       at any argument T within the knot range, using subrou-
C       tines SPLDER and SEARCH, and the knot array X(N). Since
C       the splines are constrained at their Mth derivative, only
C       the lower spline derivatives will tend to be reliable
C       estimates of the underlying, true signal derivatives.
C
C       (6) GCVSPL combines elements of subroutine CRVO5 by Utre-
C       ras (1980), subroutine SMOOTH by Lyche et al. (1983), and
C       subroutine CUBGCV by Hutchinson (1985). The trace of the
C       influence matrix is assessed in a similar way as described
C       by Hutchinson & de Hoog (1985). The major difference is
C       that the present approach utilizes non-symmetrical B-spline
C       design matrices as described by Lyche et al. (1983); there-
C       fore, the original algorithm by Erisman & Tinney (1975) has
C       been used, rather than the symmetrical version adopted by
C       Hutchinson & de Hoog.
C
C References:
C **********
C
C       P. Craven & G. Wahba (1979), Smoothing noisy data with
C       spline functions. Numerische Mathematik 31, 377-403.
C
C       A.M. Erisman & W.F. Tinney (1975), On computing certain
C       elements of the inverse of a sparse matrix. Communications
C       of the ACM 18(3), 177-179.
C
C       M.F. Hutchinson & F.R. de Hoog (1985), Smoothing noisy data
C       with spline functions. Numerische Mathematik 47(1), 99-106.
C
C       M.F. Hutchinson (1985), Subroutine CUBGCV. CSIRO Division of
C       Mathematics and Statistics, P.O. Box 1965, Canberra, ACT 2601,
C       Australia.
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori (1983), Fortran
C       subroutines for computing smoothing and interpolating natural
C       splines. Advances in Engineering Software 5(1), 2-5.
C
C       F. Utreras (1980), Un paquete de programas para ajustar curvas
C       mediante funciones spline. Informe Tecnico MA-80-B-209, Depar-
C       tamento de Matematicas, Faculdad de Ciencias Fisicas y Matema-
C       ticas, Universidad de Chile, Santiago.
C
C       Wahba, G. (1980). Numerical and statistical methods for mildly,
C       moderately and severely ill-posed problems with noisy data.
C       Technical report nr. 595 (February 1980). Department of Statis-
C       tics, University of Madison (WI), U.S.A.
C
C Subprograms required:
C ********************
C
C       BASIS, PREP, SPLC, BANDET, BANSOL, TRINV
C
C***********************************************************************
C
      SUBROUTINE GCVSPL ( X, Y, NY, WX, WY, M, N, K, MD, VAL, C, NC,
     1                   WK, IER )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( RATIO=2D0, TAU=1.618033983D0, IBWE=7,
     1           ZERO=0D0, HALF=5D-1 , ONE=1D0, TOL=1D-6,
     2           EPS=1D-15, EPSINV=ONE/EPS )
      DIMENSION X(N), Y(NY,K), WX(N), WY(K), C(NC,K), WK(N+6*(N*M+1))
      SAVE M2, NM1, EL
      DATA M2, NM1, EL / 2*0, 0D0 /
C
C***  Parameter check and work array initialization
C
      IER = 0
C***  Check on mode parameter
      IF ((IABS(MD).GT.4) .OR.(  MD.EQ. 0  ) .OR.
     1  ((IABS(MD).EQ.1).AND.( VAL.LT.ZERO)).OR.
     2  ((IABS(MD).EQ.3).AND.( VAL.LT.ZERO)).OR.
     3  ((IABS(MD).EQ.4).AND.((VAL.LT.ZERO) .OR.(VAL.GT.N-M)))) THEN
         IER = 3      !Wrong mode value
         RETURN
      ENDIF
C***  Check on M and N
      IF (MD.GT.0) THEN
         M2  = 2 * M
         NM1 = N - 1
      ELSE
         IF ((M2.NE.2*M).OR.(NM1.NE.N-1)) THEN
            IER = 3      !M or N modified since previous call
            RETURN
         ENDIF
      ENDIF
      IF ((M.LE.0).OR.(N.LT.M2)) THEN
         IER = 1      !M or N invalid
         RETURN
      ENDIF
C***  Check on knot sequence and weights
      IF (WX(1).LE.ZERO) IER = 4
      DO 10 I=2,N
         IF (WX(I).LE.ZERO) IER = 4
         IF (X(I-1).GE.X(I)) IER = 2
         IF (IER.NE.0) RETURN
   10 CONTINUE
      DO 15 J=1,K
         IF (WY(J).LE.ZERO) IER = 4
         IF (IER.NE.0) RETURN
   15 CONTINUE
C
C***  Work array parameters (address information for covariance 
C***  propagation by means of the matrices STAT, B, and WE). NB:
C***  BWE cannot be used since it is modified by function TRINV.
C
      NM2P1 = N*(M2+1)
      NM2M1 = N*(M2-1)
C     ISTAT = 1            !Statistics array STAT(6)
C     IBWE  = ISTAT + 6      !Smoothing matrix BWE( -M:M  ,N)
      IB    = IBWE  + NM2P1      !Design matrix    B  (1-M:M-1,N)
      IWE   = IB    + NM2M1      !Design matrix    WE ( -M:M  ,N)
C     IWK   = IWE   + NM2P1      !Total work array length N + 6*(N*M+1)
C
C***  Compute the design matrices B and WE, the ratio
C***  of their L1-norms, and check for iterative mode.
C
      IF (MD.GT.0) THEN
         CALL BASIS ( M, N, X, WK(IB), R1, WK(IBWE) )
         CALL PREP  ( M, N, X, WX, WK(IWE), EL )
         EL = EL / R1      !L1-norms ratio (SAVEd upon RETURN)
      ENDIF
      IF (IABS(MD).NE.1) GO TO 20
C***     Prior given value for p
         R1 = VAL
         GO TO 100
C
C***  Iterate to minimize the GCV function (|MD|=2),
C***  the MSE function (|MD|=3), or to obtain the prior
C***  given number of degrees of freedom (|MD|=4).
C
   20 IF (MD.LT.-1) THEN
         R1 = WK(4)      !User-determined starting value
      ELSE
         R1 = ONE / EL      !Default (DOF ~ 0.5)
      ENDIF      
      R2 = R1 * RATIO
      GF2 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R2,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
   40 GF1 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R1,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
      IF (GF1.GT.GF2) GO TO 50
         IF (WK(4).LE.ZERO) GO TO 100            !Interpolation
         R2  = R1
         GF2 = GF1
         R1  = R1 / RATIO
         GO TO 40
   50 R3 = R2 * RATIO
   60 GF3 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R3,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
      IF (GF3.GT.GF2) GO TO 70
         IF (WK(4).GE.EPSINV) GO TO 100      !Least-squares polynomial
         R2  = R3      
         GF2 = GF3
         R3  = R3 * RATIO
         GO TO 60
   70 R2  = R3
      GF2 = GF3
      ALPHA = (R2-R1) / TAU
      R4 = R1 + ALPHA
      R3 = R2 - ALPHA
      GF3 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R3,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
      GF4 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R4,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
   80 IF (GF3.LE.GF4) THEN
         R2  = R4
         GF2 = GF4
         ERR = (R2-R1) / (R1+R2)
         IF ((ERR*ERR+ONE.EQ.ONE).OR.(ERR.LE.TOL)) GO TO 90
         R4  = R3
         GF4 = GF3
         ALPHA = ALPHA / TAU
         R3  = R2 - ALPHA
         GF3 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R3,EPS,C,NC,
     1             WK,WK(IB),WK(IWE),EL,WK(IBWE))
      ELSE
         R1  = R3
         GF1 = GF3
         ERR = (R2-R1) / (R1+R2)
         IF ((ERR*ERR+ONE.EQ.ONE).OR.(ERR.LE.TOL)) GO TO 90
         R3  = R4
         GF3 = GF4
         ALPHA = ALPHA / TAU
         R4 = R1 + ALPHA
         GF4 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R4,EPS,C,NC,
     1             WK,WK(IB),WK(IWE),EL,WK(IBWE))
      ENDIF
      GO TO 80
   90 R1 = HALF * (R1+R2)
C
C***  Calculate final spline coefficients
C
  100 GF1 = SPLC(M,N,K,Y,NY,WX,WY,MD,VAL,R1,EPS,C,NC,
     1          WK,WK(IB),WK(IWE),EL,WK(IBWE))
C
C***  Ready
C
      RETURN
      END
C BASIS.FOR, 1985-06-03
C
C***********************************************************************
C
C SUBROUTINE BASIS (REAL*8)
C
C Purpose:
C *******
C
C       Subroutine to assess a B-spline tableau, stored in vectorized
C       form.
C
C Calling convention:
C ******************
C
C       CALL BASIS ( M, N, X, B, BL, Q )
C
C Meaning of parameters:
C *********************
C
C       M               ( I )   Half order of the spline (degree 2*M-1),
C                               M > 0.
C       N               ( I )   Number of knots, N >= 2*M.
C       X(N)            ( I )   Knot sequence, X(I-1) < X(I), I=2,N.
C       B(1-M:M-1,N)    ( O )   Output tableau. Element B(J,I) of array
C                               B corresponds with element b(i,i+j) of
C                               the tableau matrix B.
C       BL              ( O )   L1-norm of B.
C       Q(1-M:M)        ( W )   Internal work array.
C
C Remark:
C ******
C
C       This subroutine is an adaptation of subroutine BASIS from the
C       paper by Lyche et al. (1983). No checking is performed on the
C       validity of M and N. If the knot sequence is not strictly in-
C       creasing, division by zero may occur.
C
C Reference:
C *********
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      SUBROUTINE BASIS ( M, N, X, B, BL, Q )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( ZERO=0D0, ONE=1D0 )
      DIMENSION X(N), B(1-M:M-1,N), Q(1-M:M)
C
      IF (M.EQ.1) THEN
C***         Linear spline
         DO 3 I=1,N
            B(0,I) = ONE
    3    CONTINUE
         BL = ONE
         RETURN
      ENDIF
C
C***  General splines
C
      MM1 = M - 1
      MP1 = M + 1
      M2  = 2 * M
      DO 15 L=1,N
C***     1st row
         DO 5 J=-MM1,M
            Q(J) = ZERO
    5    CONTINUE
         Q(MM1) = ONE
         IF ((L.NE.1).AND.(L.NE.N))
     1      Q(MM1) = ONE / ( X(L+1) - X(L-1) )
C***     Successive rows
         ARG = X(L)
         DO 13 I=3,M2
            IR = MP1 - I
            V  = Q(IR)
            IF (L.LT.I) THEN
C***               Left-hand B-splines
               DO 6 J=L+1,I
                  U     = V
                  V     = Q(IR+1)
                  Q(IR) = U + (X(J)-ARG)*V
                  IR    = IR + 1
    6          CONTINUE
            ENDIF
            J1 = MAX0(L-I+1,1)
            J2 = MIN0(L-1,N-I)
            IF (J1.LE.J2) THEN
C***               Ordinary B-splines
               IF (I.LT.M2) THEN
                  DO 8 J=J1,J2
                     Y     = X(I+J)
                     U     = V
                     V     = Q(IR+1)
                     Q(IR) = U + (V-U)*(Y-ARG)/(Y-X(J))
                     IR = IR + 1
    8             CONTINUE
               ELSE
                  DO 10 J=J1,J2
                     U     = V
                     V     = Q(IR+1)
                     Q(IR) = (ARG-X(J))*U + (X(I+J)-ARG)*V
                     IR    = IR + 1
   10             CONTINUE
               ENDIF
            ENDIF
            NMIP1 = N - I + 1
            IF (NMIP1.LT.L) THEN
C***           Right-hand B-splines
               DO 12 J=NMIP1,L-1
                  U     = V
                  V     = Q(IR+1)
                  Q(IR) = (ARG-X(J))*U + V
                  IR    = IR + 1
   12          CONTINUE
            ENDIF
   13    CONTINUE
         DO 14 J=-MM1,MM1
            B(J,L) = Q(J)
   14    CONTINUE
   15 CONTINUE
C
C***  Zero unused parts of B
C
      DO 17 I=1,MM1
         DO 16 K=I,MM1
            B(-K,    I) = ZERO
            B( K,N+1-I) = ZERO
   16    CONTINUE
   17 CONTINUE
C
C***  Assess L1-norm of B
C
      BL = 0D0
      DO 19 I=1,N
         DO 18 K=-MM1,MM1
            BL = BL + ABS(B(K,I))
   18    CONTINUE
   19 CONTINUE
      BL = BL / N
C
C***  Ready
C
      RETURN
      END
C PREP.FOR, 1985-07-04
C
C***********************************************************************
C
C SUBROUTINE PREP (REAL*8)
C
C Purpose:
C *******
C
C       To compute the matrix WE of weighted divided difference coeffi-
C       cients needed to set up a linear system of equations for sol-
C       ving B-spline smoothing problems, and its L1-norm EL. The matrix
C       WE is stored in vectorized form.
C
C Calling convention:
C ******************
C
C       CALL PREP ( M, N, X, W, WE, EL )
C
C Meaning of parameters:
C *********************
C
C       M               ( I )   Half order of the B-spline (degree
C                               2*M-1), with M > 0.
C       N               ( I )   Number of knots, with N >= 2*M.
C       X(N)            ( I )   Strictly increasing knot array, with
C                               X(I-1) < X(I), I=2,N.
C       W(N)            ( I )   Weight matrix (diagonal), with
C                               W(I).gt.0.0, I=1,N.
C       WE(-M:M,N)      ( O )   Array containing the weighted divided
C                               difference terms in vectorized format.
C                               Element WE(J,I) of array E corresponds
C                               with element e(i,i+j) of the matrix
C                               W**-1 * E.
C       EL              ( O )   L1-norm of WE.
C
C Remark:
C ******
C
C       This subroutine is an adaptation of subroutine PREP from the paper
C       by Lyche et al. (1983). No checking is performed on the validity
C       of M and N. Division by zero may occur if the knot sequence is
C       not strictly increasing.
C
C Reference:
C *********
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      SUBROUTINE PREP ( M, N, X, W, WE, EL )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( ZERO=0D0, ONE=1D0 )
      DIMENSION X(N), W(N), WE((2*M+1)*N)      !WE(-M:M,N)
C
C***  Calculate the factor F1
C
      M2   = 2 * M
      MP1  = M + 1
      M2M1 = M2 - 1
      M2P1 = M2 + 1
      NM   = N - M
      F1   = -ONE
      IF (M.NE.1) THEN
         DO 5 I=2,M
            F1 = -F1 * I
    5    CONTINUE
         DO 6 I=MP1,M2M1
            F1 = F1 * I
    6    CONTINUE
      END IF
C
C***  Columnwise evaluation of the unweighted design matrix E
C
      I1 = 1
      I2 = M
      JM = MP1
      DO 17 J=1,N
         INC = M2P1
         IF (J.GT.NM) THEN
            F1 = -F1
            F  =  F1
         ELSE
            IF (J.LT.MP1) THEN
                INC = 1
                F   = F1
            ELSE
                F   = F1 * (X(J+M)-X(J-M))
            END IF
         END IF
         IF ( J.GT.MP1) I1 = I1 + 1
         IF (I2.LT.  N) I2 = I2 + 1
         JJ = JM
C***     Loop for divided difference coefficients
         FF = F
         Y = X(I1)
         I1P1 = I1 + 1
         DO 11 I=I1P1,I2
            FF = FF / (Y-X(I))
   11    CONTINUE
         WE(JJ) = FF
         JJ = JJ + M2
         I2M1 = I2 - 1
         IF (I1P1.LE.I2M1) THEN
            DO 14 L=I1P1,I2M1
               FF = F
               Y  = X(L)
               DO 12 I=I1,L-1
                  FF = FF / (Y-X(I))
   12          CONTINUE
               DO 13 I=L+1,I2
                  FF = FF / (Y-X(I))
   13          CONTINUE
               WE(JJ) = FF
               JJ = JJ + M2
   14       CONTINUE
         END IF
         FF = F
         Y = X(I2)
         DO 16 I=I1,I2M1
            FF = FF / (Y-X(I))
   16    CONTINUE
         WE(JJ) = FF
         JJ = JJ + M2
         JM = JM + INC
   17 CONTINUE
C
C***  Zero the upper left and lower right corners of E
C
      KL = 1
      N2M = M2P1*N + 1
      DO 19 I=1,M
         KU = KL + M - I
         DO 18 K=KL,KU
            WE(    K) = ZERO
            WE(N2M-K) = ZERO
   18    CONTINUE
         KL = KL + M2P1
   19 CONTINUE
C
C***  Weighted matrix WE = W**-1 * E and its L1-norm
C
   20 JJ = 0
      EL = 0D0
      DO 22 I=1,N
         WI = W(I)
         DO 21 J=1,M2P1
            JJ     = JJ + 1
            WE(JJ) = WE(JJ) / WI
            EL     = EL + ABS(WE(JJ))
   21    CONTINUE
   22 CONTINUE
      EL = EL / N
C
C***  Ready
C
      RETURN
      END
C SPLC.FOR, 1985-12-12
C
C Author: H.J. Woltring
C
C Organizations: University of Nijmegen, and
C                Philips Medical Systems, Eindhoven
C                (The Netherlands)
C
C***********************************************************************
C
C FUNCTION SPLC (REAL*8)
C
C Purpose:
C *******
C
C       To assess the coefficients of a B-spline and various statistical
C       parameters, for a given value of the regularization parameter p.
C
C Calling convention:
C ******************
C
C       FV = SPLC ( M, N, K, Y, NY, WX, WY, MODE, VAL, P, EPS, C, NC,
C       1           STAT, B, WE, EL, BWE)
C
C Meaning of parameters:
C *********************
C
C       SPLC            ( O )   GCV function value if |MODE|.eq.2,
C                               MSE value if |MODE|.eq.3, and absolute
C                               difference with the prior given number of
C                               degrees of freedom if |MODE|.eq.4.
C       M               ( I )   Half order of the B-spline (degree 2*M-1),
C                               with M > 0.
C       N               ( I )   Number of observations, with N >= 2*M.
C       K               ( I )   Number of datasets, with K >= 1.
C       Y(NY,K)         ( I )   Observed measurements.
C       NY              ( I )   First dimension of Y(NY,K), with NY.ge.N.
C       WX(N)           ( I )   Weight factors, corresponding to the
C                               relative inverse variance of each measure-
C                               ment, with WX(I) > 0.0.
C       WY(K)           ( I )   Weight factors, corresponding to the
C                               relative inverse variance of each dataset,
C                               with WY(J) > 0.0.
C       MODE            ( I )   Mode switch, as described in GCVSPL.
C       VAL             ( I )   Prior variance if |MODE|.eq.3, and
C                               prior number of degrees of freedom if
C                               |MODE|.eq.4. For other values of MODE,
C                               VAL is not used.
C       P               ( I )   Smoothing parameter, with P >= 0.0. If
C                               P.eq.0.0, an interpolating spline is
C                               calculated.
C       EPS             ( I )   Relative rounding tolerance*10.0. EPS is
C                               the smallest positive number such that
C                               EPS/10.0 + 1.0 .ne. 1.0.
C       C(NC,K)         ( O )   Calculated spline coefficient arrays. NB:
C                               the dimensions of in GCVSPL and in SPLDER
C                               are different! In SPLDER, only a single
C                               column of C(N,K) is needed, and the proper
C                               column C(1,J), with J=1...K, should be used
C                               when calling SPLDER.
C       NC              ( I )   First dimension of C(NC,K), with NC.ge.N.
C       STAT(6)         ( O )   Statistics array. See the description in
C                               subroutine GCVSPL.
C       B (1-M:M-1,N)   ( I )   B-spline tableau as evaluated by subroutine
C                               BASIS.
C       WE( -M:M  ,N)   ( I )   Weighted B-spline tableau (W**-1 * E) as
C                               evaluated by subroutine PREP.
C       EL              ( I )   L1-norm of the matrix WE as evaluated by
C                               subroutine PREP.
C       BWE(-M:M,N)     ( O )   Central 2*M+1 bands of the inverted
C                               matrix ( B  +  p * W**-1 * E )**-1
C
C Remarks:
C *******
C
C       This subroutine combines elements of subroutine SPLC0 from the
C       paper by Lyche et al. (1983), and of subroutine SPFIT1 by
C       Hutchinson (1985).
C
C References:
C **********
C
C       M.F. Hutchinson (1985), Subroutine CUBGCV. CSIRO division of
C       Mathematics and Statistics, P.O. Box 1965, Canberra, ACT 2601,
C       Australia.
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      FUNCTION SPLC( M, N, K, Y, NY, WX, WY, MODE, VAL, P, EPS, C, NC,
     1              STAT, B, WE, EL, BWE)
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( ZERO=0D0, ONE=1D0, TWO=2D0 )
      DIMENSION Y(NY,K), WX(N), WY(K), C(NC,K), STAT(6),
     1         B(1-M:M-1,N), WE(-M:M,N), BWE(-M:M,N)
C
C***  Check on p-value
C
      DP = P
      STAT(4) = P
      PEL = P * EL
C***  Pseudo-interpolation if p is too small
      IF (PEL.LT.EPS) THEN
         DP = EPS / EL
         STAT(4) = ZERO
      ENDIF
C***  Pseudo least-squares polynomial if p is too large
      IF (PEL*EPS.GT.ONE) THEN
         DP = ONE / (EL*EPS)
         STAT(4) = DP
      ENDIF
C
C***  Calculate  BWE  =  B  +  p * W**-1 * E
C
      DO 40 I=1,N
         KM = -MIN0(M,I-1)
         KP =  MIN0(M,N-I)
         DO 30 L=KM,KP
            IF (IABS(L).EQ.M) THEN
               BWE(L,I) =          DP * WE(L,I)
            ELSE
               BWE(L,I) = B(L,I) + DP * WE(L,I)
            ENDIF
   30    CONTINUE
   40 CONTINUE
C
C***  Solve BWE * C = Y, and assess TRACE [ B * BWE**-1 ]
C
      CALL BANDET ( BWE, M, N )
      CALL BANSOL ( BWE, Y, NY, C, NC, M, N, K )
      STAT(3) = TRINV ( WE, BWE, M, N ) * DP      !trace * p = res. d.o.f.
      TRN = STAT(3) / N
C
C***  Compute mean-squared weighted residual
C
      ESN = ZERO
      DO 70 J=1,K
         DO 60 I=1,N
            DT = -Y(I,J)
            KM = -MIN0(M-1,I-1)
            KP =  MIN0(M-1,N-I)
            DO 50 L=KM,KP
               DT = DT + B(L,I)*C(I+L,J)
   50       CONTINUE
            ESN = ESN + DT*DT*WX(I)*WY(J)
   60    CONTINUE
   70 CONTINUE
      ESN = ESN / (N*K)
C
C***  Calculate statistics and function value
C
      STAT(6) = ESN / TRN             !Estimated variance
      STAT(1) = STAT(6) / TRN         !GCV function value
      STAT(2) = ESN                   !Mean Squared Residual
C     STAT(3) = trace [p*B * BWE**-1] !Estimated residuals' d.o.f.
C     STAT(4) = P                     !Normalized smoothing factor
      IF (IABS(MODE).NE.3) THEN
C***     Unknown variance: GCV
         STAT(5) = STAT(6) - ESN
         IF (IABS(MODE).EQ.1) SPLC = ZERO
         IF (IABS(MODE).EQ.2) SPLC = STAT(1)
         IF (IABS(MODE).EQ.4) SPLC = DABS( STAT(3) - VAL )
      ELSE
C***     Known variance: estimated mean squared error
         STAT(5) = ESN - VAL*(TWO*TRN - ONE)
         SPLC = STAT(5)
      ENDIF
C
      RETURN
      END
C BANDET.FOR, 1985-06-03
C
C***********************************************************************
C
C SUBROUTINE BANDET (REAL*8)
C
C Purpose:
C *******
C
C       This subroutine computes the LU decomposition of an N*N matrix
C       E. It is assumed that E has M bands above and M bands below the
C       diagonal. The decomposition is returned in E. It is assumed that
C       E can be decomposed without pivoting. The matrix E is stored in
C       vectorized form in the array E(-M:M,N), where element E(J,I) of
C       the array E corresponds with element e(i,i+j) of the matrix E.
C
C Calling convention:
C ******************
C
C       CALL BANDET ( E, M, N )
C
C Meaning of parameters:
C *********************
C
C       E(-M:M,N)       (I/O)   Matrix to be decomposed.
C       M, N            ( I )   Matrix dimensioning parameters,
C                               M >= 0, N >= 2*M.
C
C Remark:
C ******
C
C       No checking on the validity of the input data is performed.
C       If (M.le.0), no action is taken.
C
C***********************************************************************
C
      SUBROUTINE BANDET ( E, M, N )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION E(-M:M,N)
C
      IF (M.LE.0) RETURN
      DO 40 I=1,N
         DI = E(0,I)
         MI = MIN0(M,I-1)
         IF (MI.GE.1) THEN
            DO 10 K=1,MI
               DI = DI - E(-K,I)*E(K,I-K)
   10       CONTINUE
            E(0,I) = DI
         ENDIF
         LM = MIN0(M,N-I)
         IF (LM.GE.1) THEN
            DO 30 L=1,LM
               DL = E(-L,I+L)
               KM = MIN0(M-L,I-1)
               IF (KM.GE.1) THEN
                  DU = E(L,I)
                  DO 20 K=1,KM
                     DU = DU - E(  -K,  I)*E(L+K,I-K)
                     DL = DL - E(-L-K,L+I)*E(  K,I-K)
   20             CONTINUE
                  E(L,I) = DU
               ENDIF
               E(-L,I+L) = DL / DI
   30       CONTINUE
         ENDIF
   40 CONTINUE
C
C***  Ready
C
      RETURN
      END
C BANSOL.FOR, 1985-12-12
C
C***********************************************************************
C
C SUBROUTINE BANSOL (REAL*8)
C
C Purpose:
C *******
C
C       This subroutine solves systems of linear equations given an LU
C       decomposition of the design matrix. Such a decomposition is pro-
C       vided by subroutine BANDET, in vectorized form. It is assumed
C       that the design matrix is not singular. 
C
C Calling convention:
C ******************
C
C       CALL BANSOL ( E, Y, NY, C, NC, M, N, K )
C
C Meaning of parameters:
C *********************
C
C       E(-M:M,N)       ( I )   Input design matrix, in LU-decomposed,
C                               vectorized form. Element E(J,I) of the
C                               array E corresponds with element
C                               e(i,i+j) of the N*N design matrix E.
C       Y(NY,K)         ( I )   Right hand side vectors.
C       C(NC,K)         ( O )   Solution vectors.
C       NY, NC, M, N, K ( I )   Dimensioning parameters, with M >= 0,
C                               N > 2*M, and K >= 1.
C
C Remark:
C ******
C
C       This subroutine is an adaptation of subroutine BANSOL from the
C       paper by Lyche et al. (1983). No checking is performed on the
C       validity of the input parameters and data. Division by zero may
C       occur if the system is singular.
C
C Reference:
C *********
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      SUBROUTINE BANSOL ( E, Y, NY, C, NC, M, N, K )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION E(-M:M,N), Y(NY,K), C(NC,K)
C
C***  Check on special cases: M=0, M=1, M>1
C
      NM1 = N - 1
      IF (M-1) 10,40,80
C
C***  M = 0: Diagonal system
C
   10 DO 30 I=1,N
         DO 20 J=1,K
            C(I,J) = Y(I,J) / E(0,I)
   20    CONTINUE
   30 CONTINUE
      RETURN
C
C***  M = 1: Tridiagonal system
C
   40 DO 70 J=1,K
         C(1,J) = Y(1,J)
         DO 50 I=2,N            !Forward sweep
            C(I,J) =  Y(I,J) - E(-1,I)*C(I-1,J)
   50      CONTINUE
         C(N,J) = C(N,J) / E(0,N)
         DO 60 I=NM1,1,-1      !Backward sweep
            C(I,J) = (C(I,J) - E( 1,I)*C(I+1,J)) / E(0,I)
   60    CONTINUE
   70 CONTINUE
      RETURN
C
C***  M > 1: General system
C
   80 DO 130 J=1,K
         C(1,J) = Y(1,J)
         DO 100 I=2,N            !Forward sweep
            MI = MIN0(M,I-1)
            D  = Y(I,J)
            DO 90 L=1,MI
               D = D - E(-L,I)*C(I-L,J)
   90       CONTINUE
            C(I,J) = D
  100    CONTINUE
         C(N,J) = C(N,J) / E(0,N)
         DO 120 I=NM1,1,-1      !Backward sweep
            MI = MIN0(M,N-I)
            D  = C(I,J)
            DO 110 L=1,MI
               D = D - E( L,I)*C(I+L,J)
  110       CONTINUE
            C(I,J) = D / E(0,I)
  120    CONTINUE
  130 CONTINUE
      RETURN
C
      END
C TRINV.FOR, 1985-06-03
C
C***********************************************************************
C
C FUNCTION TRINV (REAL*8)
C
C Purpose:
C *******
C
C       To calculate TRACE [ B * E**-1 ], where B and E are N * N
C       matrices with bandwidth 2*M+1, and where E is a regular matrix
C       in LU-decomposed form. B and E are stored in vectorized form,
C       compatible with subroutines BANDET and BANSOL.
C
C Calling convention:
C ******************
C
C       TRACE = TRINV ( B, E, M, N )
C
C Meaning of parameters:
C *********************
C
C       B(-M:M,N)       ( I ) Input array for matrix B. Element B(J,I)
C                             corresponds with element b(i,i+j) of the
C                             matrix B.
C       E(-M:M,N)       (I/O) Input array for matrix E. Element E(J,I)
C                             corresponds with element e(i,i+j) of the
C                             matrix E. This matrix is stored in LU-
C                             decomposed form, with L unit lower tri-
C                             angular, and U upper triangular. The unit
C                             diagonal of L is not stored. Upon return,
C                             the array E holds the central 2*M+1 bands
C                             of the inverse E**-1, in similar ordering.
C       M, N            ( I ) Array and matrix dimensioning parameters
C                             (M.gt.0, N.ge.2*M+1).
C       TRINV           ( O ) Output function value TRACE [ B * E**-1 ]
C
C Reference:
C *********
C
C       A.M. Erisman & W.F. Tinney, On computing certain elements of the
C       inverse of a sparse matrix. Communications of the ACM 18(1975),
C       nr. 3, pp. 177-179.
C
C***********************************************************************
C
      REAL*8 FUNCTION TRINV ( B, E, M, N )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( ZERO=0D0, ONE=1D0 )
      DIMENSION B(-M:M,N), E(-M:M,N)
C
C***  Assess central 2*M+1 bands of E**-1 and store in array E
C
      E(0,N) = ONE / E(0,N)      !Nth pivot
      DO 40 I=N-1,1,-1
         MI = MIN0(M,N-I)
         DD  = ONE / E(0,I)      !Ith pivot
C***     Save Ith column of L and Ith row of U, and normalize U row
         DO 10 K=1,MI
            E( K,N) = E( K,  I) * DD      !Ith row of U (normalized)
            E(-K,1) = E(-K,K+I)      !Ith column of L
   10    CONTINUE
         DD = DD + DD
C***     Invert around Ith pivot
         DO 30 J=MI,1,-1
            DU = ZERO
            DL = ZERO
            DO 20 K=1,MI
               DU = DU - E( K,N)*E(J-K,I+K)
               DL = DL - E(-K,1)*E(K-J,I+J)
   20       CONTINUE
            E( J,  I) = DU
            E(-J,J+I) = DL
            DD = DD - (E(J,N)*DL + E(-J,1)*DU)
   30    CONTINUE
         E(0,I) = 5D-1 * DD
   40 CONTINUE
C
C***  Assess TRACE [ B * E**-1 ] and clear working storage
C
      DD = ZERO
      DO 60 I=1,N
         MN = -MIN0(M,I-1)
         MP =  MIN0(M,N-I)
         DO 50 K=MN,MP
            DD = DD + B(K,I)*E(-K,K+I)
   50    CONTINUE
   60 CONTINUE
      TRINV = DD
      DO 70 K=1,M
         E( K,N) = ZERO
         E(-K,1) = ZERO
   70 CONTINUE
C
C***  Ready
C
      RETURN
      END
C SPLDER.FOR, 1985-06-11
C
C***********************************************************************
C
C FUNCTION SPLDER (REAL*8)
C
C Purpose:
C *******
C
C       To produce the value of the function (IDER.eq.0) or of the
C       IDERth derivative (IDER.gt.0) of a 2M-th order B-spline at
C       the point T. The spline is described in terms of the half
C       order M, the knot sequence X(N), N.ge.2*M, and the spline
C       coefficients C(N).
C
C Calling convention:
C ******************
C
C       SVIDER = SPLDER ( IDER, M, N, T, X, C, L, Q )
C
C Meaning of parameters:
C *********************
C
C       SPLDER  ( O )   Function or derivative value.
C       IDER    ( I )   Derivative order required, with 0.le.IDER
C                       and IDER.le.2*M. If IDER.eq.0, the function
C                       value is returned; otherwise, the IDER-th
C                       derivative of the spline is returned.
C       M       ( I )   Half order of the spline, with M.gt.0.
C       N       ( I )   Number of knots and spline coefficients,
C                       with N.ge.2*M.
C       T       ( I )   Argument at which the spline or its deri-
C                       vative is to be evaluated, with X(1).le.T
C                       and T.le.X(N).
C       X(N)    ( I )   Strictly increasing knot sequence array,
C                       X(I-1).lt.X(I), I=2,...,N.
C       C(N)    ( I )   Spline coefficients, as evaluated by
C                       subroutine GVCSPL.
C       L       (I/O)   L contains an integer such that:
C                       X(L).le.T and T.lt.X(L+1) if T is within
C                       the range X(1).le.T and T.lt.X(N). If
C                       T.lt.X(1), L is set to 0, and if T.ge.X(N),
C                       L is set to N. The search for L is facili-
C                       tated if L has approximately the right
C                       value on entry.
C       Q(2*M)  ( W )   Internal work array.
C
C Remark:
C ******
C
C       This subroutine is an adaptation of subroutine SPLDER of
C       the paper by Lyche et al. (1983). No checking is performed
C       on the validity of the input parameters.
C
C Reference:
C *********
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      REAL*8 FUNCTION SPLDER ( IDER, M, N, T, X, C, L, Q )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER ( ZERO=0D0, ONE=1D0 )
      DIMENSION X(N), C(N), Q(2*M)
C
C***  Derivatives of IDER.ge.2*M are alway zero
C
      M2 =  2 * M
      K  = M2 - IDER
      IF (K.LT.1) THEN
         SPLDER = ZERO
         RETURN
      ENDIF
C
C***  Search for the interval value L
C
      CALL SEARCH ( N, X, T, L )
C
C***  Initialize parameters and the 1st row of the B-spline
C***  coefficients tableau
C
      TT   = T
      MP1  =  M + 1
      NPM  =  N + M
      M2M1 = M2 - 1
      K1   =  K - 1
      NK   =  N - K
      LK   =  L - K
      LK1  = LK + 1
      LM   =  L - M
      JL   =  L + 1
      JU   =  L + M2
      II   =  N - M2
      ML   = -L
      DO 2 J=JL,JU
         IF ((J.GE.MP1).AND.(J.LE.NPM)) THEN
            Q(J+ML) = C(J-M)
         ELSE
            Q(J+ML) = ZERO
         ENDIF
    2 CONTINUE
C
C***  The following loop computes differences of the B-spline
C***  coefficients. If the value of the spline is required,
C***  differencing is not necessary.
C
      IF (IDER.GT.0) THEN
         JL = JL - M2
         ML = ML + M2
         DO 6 I=1,IDER
            JL = JL + 1
            II = II + 1
            J1 = MAX0(1,JL)
            J2 = MIN0(L,II)
            MI = M2 - I
            J  = J2 + 1
            IF (J1.LE.J2) THEN
               DO 3 JIN=J1,J2
                  J  =  J - 1
                  JM = ML + J
                  Q(JM) = (Q(JM) - Q(JM-1)) / (X(J+MI) - X(J))
    3          CONTINUE
            ENDIF
            IF (JL.GE.1) GO TO 6
               I1 =  I + 1
               J  = ML + 1
               IF (I1.LE.ML) THEN
                  DO 5 JIN=I1,ML
                     J    =  J - 1
                     Q(J) = -Q(J-1)
    5             CONTINUE
               ENDIF
    6    CONTINUE
         DO 7 J=1,K
            Q(J) = Q(J+IDER)
    7    CONTINUE
      ENDIF
C
C***  Compute lower half of the evaluation tableau
C
      IF (K1.GE.1) THEN      !Tableau ready if IDER.eq.2*M-1
         DO 14 I=1,K1
            NKI  =  NK + I
            IR   =   K
            JJ   =   L
            KI   =   K - I
            NKI1 = NKI + 1
C***        Right-hand B-splines
            IF (L.GE.NKI1) THEN
               DO 9 J=NKI1,L
                  Q(IR) = Q(IR-1) + (TT-X(JJ))*Q(IR)
                  JJ    = JJ - 1
                  IR    = IR - 1
    9          CONTINUE
            ENDIF
C***        Middle B-splines
            LK1I = LK1 + I
            J1 = MAX0(1,LK1I)
            J2 = MIN0(L, NKI)
            IF (J1.LE.J2) THEN
               DO 11 J=J1,J2
                  XJKI  = X(JJ+KI)
                  Z     = Q(IR)
                  Q(IR) = Z + (XJKI-TT)*(Q(IR-1)-Z)/(XJKI-X(JJ))
                  IR    = IR - 1
                  JJ    = JJ - 1
   11          CONTINUE
            ENDIF
C***        Left-hand B-splines
            IF (LK1I.LE.0) THEN
               JJ    = KI
               LK1I1 =  1 - LK1I
               DO 13 J=1,LK1I1
                  Q(IR) = Q(IR) + (X(JJ)-TT)*Q(IR-1)
                  JJ    = JJ - 1
                  IR    = IR - 1
   13          CONTINUE
            ENDIF
   14    CONTINUE
      ENDIF
C
C***  Compute the return value
C
      Z = Q(K)
C***  Multiply with factorial if IDER.gt.0
      IF (IDER.GT.0) THEN
         DO 16 J=K,M2M1
            Z = Z * J
   16    CONTINUE
      ENDIF
      SPLDER = Z
C
C***  Ready
C
      RETURN
      END
C SEARCH.FOR, 1985-06-03
C
C***********************************************************************
C
C SUBROUTINE SEARCH (REAL*8)
C
C Purpose:
C *******
C
C       Given a strictly increasing knot sequence X(1) < ... < X(N),
C       where N >= 1, and a real number T, this subroutine finds the
C       value L such that X(L) <= T < X(L+1).  If T < X(1), L = 0;
C       if X(N) <= T, L = N.
C
C Calling convention:
C ******************
C
C       CALL SEARCH ( N, X, T, L )
C
C Meaning of parameters:
C *********************
C
C       N       ( I )   Knot array dimensioning parameter.
C       X(N)    ( I )   Stricly increasing knot array.
C       T       ( I )   Input argument whose knot interval is to
C                       be found.
C       L       (I/O)   Knot interval parameter. The search procedure
C                       is facilitated if L has approximately the
C                       right value on entry.
C
C Remark:
C ******
C
C       This subroutine is an adaptation of subroutine SEARCH from
C       the paper by Lyche et al. (1983). No checking is performed
C       on the input parameters and data; the algorithm may fail if
C       the input sequence is not strictly increasing.
C
C Reference:
C *********
C
C       T. Lyche, L.L. Schumaker, & K. Sepehrnoori, Fortran subroutines
C       for computing smoothing and interpolating natural splines.
C       Advances in Engineering Software 5(1983)1, pp. 2-5.
C
C***********************************************************************
C
      SUBROUTINE SEARCH ( N, X, T, L )
C
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION X(N)
C
      IF (T.LT.X(1)) THEN
C***     Out of range to the left
         L = 0
         RETURN
      ENDIF
      IF (T.GE.X(N)) THEN
C***     Out of range to the right
         L = N
         RETURN
      ENDIF
C***  Validate input value of L
      L = MAX0(L,1)
      IF (L.GE.N) L = N-1
C
C***  Often L will be in an interval adjoining the interval found
C***  in a previous call to search
C
      IF (T.GE.X(L)) GO TO 5
      L = L - 1
      IF (T.GE.X(L)) RETURN
C
C***  Perform bisection
C
      IL = 1
    3 IU = L
    4 L = (IL+IU) / 2
      IF (IU-IL.LE.1) RETURN
      IF (T.LT.X(L)) GO TO 3
      IL = L
      GO TO 4
    5 IF (T.LT.X(L+1)) RETURN
      L = L + 1
      IF (T.LT.X(L+1)) RETURN
      IL = L + 1
      IU = N
      GO TO 4
C
      END
c
c
c
c
ccccccccccccccccccccccccacccccccccccccccccccccccccccccccccccccccccc
      subroutine polyset(npoints,maxdeg,xlow,xhigh,xraw,yraw,yfit)
c
c
c
      real xraw(1000),yraw(1000),xpol(1000),ypol(1000)
      real wpol(1000),r(1000)
      real yp(1000),yfit(1000)
      real a(3100)
      real xlow,xhigh,eps
c
c
      integer npoints,npol,maxdeg,ndeg,ierr
      common/limits/xmin,xmax,ymin,ymax
c
      m=0
      do 877 i=1,npoints
         if(xraw(i).gt.xlow.and.xraw(i).lt.xhigh)then
            m=m+1
            xpol(m)=xraw(i)
            ypol(m)=yraw(i)
            wpol(m)=1.0
         end if
 877  continue
      npol=m
c
c     Prepare for polynomial fit with POLFIT
c
      eps=0.0
      call polfit(npol,xpol,ypol,wpol,maxdeg,ndeg,eps,r,ierr,a)
c      write(6,2001)maxdeg,ndeg,eps,ierr
 2001 format(' maxdeg=',i3,'; ndeg=',i3,';eps=',f6.2,';ierr=',i3)
      do 878 i=1,npoints
      call pvalue(maxdeg,1,xraw(i),yfit(i),yp(i),a)
 878  continue
c
      end



