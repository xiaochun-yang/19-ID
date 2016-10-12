      program chooch
c***********************************************************************
c
c     apply McMasters type absorption curve to normalised
c     splined fluorescence data using CROSSEC data.
c
c***********************************************************************
c
c     27th September 1999 : Separated Main source file into separate
c     subroutine files and header files including common blocks for ease
c     of coding.
c     Also created a atom.lib file containing CROSSEC values for all
c     elements and all edge of interest (I hope).
c     Made program fully self contained such that users no longer have
c     top worry about making new data files for a new element etc.
c     Use of the mucal.f subroutine from (See file mucal.help supplied
c     with distribution for full acknowledgments) allows determination
c     of the McMasters coefficients 'on the fly'.
c
c  31st October 2000 : modified for Autochooch v1.0 by Ashley Deacon
c
c     5th April 2000 : Bug fix - assignment of detmp1(m), detmp2(m) and
c                      detmp3(m) was incorrect. Before the index n was
c                      used meaning that the derivatives were not being
c                      included in the f' calculation (probably an
c                      error of 0.5e introduced on average)
c     
c     15th July 1998 : Data file 'atomdata' with elemental parameters used
c                      to replace element specific information on input 
c                      data cards
c
c     28th Sept 1995 : format statement for 
c                      reading from splinor removed
c     
c     13th Sept 1994 : Used f" values form CROSSEC as better estimates
c                      of theoretical values in vicinity of absorption 
c                      edge. McMasters values still used to extrapolate 
c                      to high and low energy regime.
c     
c     
c***********************************************************************
c
c     Include files with parameter statements and common blocks
c     
      include 'size.fh'
      include 'energy.fh'
      include 'extrem.fh'
      include 'char.fh'
c     
c     initialise arrays
c
      real ynor(isize)
      real deriv1(isize) , deriv2(isize) , deriv3(isize) ,
     +     detmp1(isize) , detmp2(isize) , detmp3(isize)
      real fp(isize)     , fpp(isize)    , fpptmp(nptot)
c     
c     initialise variables
c
      integer atnumb
      real etotmc
      real x1above , y1above , x2above , y2above
      real x1below , y1below , x2below , y2below
      real yabove , ybelow , mabove , mbelow , cabove , cbelow
      character*2 element , name , abedge
      character*15 uniqueName
      character*21 fp_fpp
      character*4 bip
c
c     Dummy variables
c
      real tmp1 , tmp2 , tmp3
      character*2 dummy
c     
c     Read in definitions of physical constants
c     
      include 'constants.fh'
c     
c     Version history
c
c      write(6,*)' Chooch - Version 1.3  28th Sept. 1995'
c      write(6,*)' Chooch - Version 2  28th March. 1998'
c      write(6,*)' Chooch - Version 2.1  15th July. 1998'
c      write(6,*)' Chooch - Version 3.0  13th October. 1998'
      write(6,'(/A43/)')' ******************************************'      
      write(6, '(A43)' )'    AutoChooch - Version 1.0 31st October 2000'
      write(6, '(A43)' )'    based on '
      write(6, '(A43)' )'    Chooch - Version 4.0   27 September 1999 '
      write(6, '(A43)' )'    Gwyndaf Evans                        '
      write(6, '(A43)' )'    MRC Laboratory of Molecular Biology  '
      write(6, '(A43)' )'    Hills Road, Cambridge CB2 2QH, UK.   '
      write(6,'(/A43/)')' ******************************************'
c     
c     open input and output files
c
c     Read commandline arguments
      if (iargc().eq.1) then
        call getarg(1, uniqueName)
        bip='.bip'
        fp_fpp='fp_fpp' // uniqueName

        open(unit=1,name=('splinor' // uniqueName),status='old')
        open(unit=2,name=('anomfacs' // uniqueName),status='unknown')
        open(unit=3,name=('valuefile' // uniqueName),status='unknown')
        open(unit=4,name=('atomdata' // uniqueName),status= 'old')
        open(unit=8,name=(fp_fpp // bip),status = 'unknown')
        open(unit=11,name=('atomname' // uniqueName),status='old')
      else
        open(unit =  1 , name = 'splinor' ,    status = 'old'     )
        open(unit =  2 , name = 'anomfacs',    status = 'unknown' )
        open(unit =  3 , name = 'valuesfile' , status = 'unknown' )
        open(unit =  4 , name = 'atomdata' ,   status = 'old'     )
        open(unit =  8 , name = 'fp_fpp.bip' , status = 'unknown' )
        open(unit = 11 , name = 'atomname' ,   status = 'old'     )
      end if
c
c     initialize some variables
c     
      fpinfl=0.0
      fpppeak=0.0
c
c     Read atom name and absorption edge from file atomname and force to
c     uppercase
c      
      read(11,'(a2)') name
      read(11,'(a2)') abedge
      call upcase( name )
      call upcase( abedge )
      close(11)

      write(6,*)' CHOOCH_STATUS: Chooch transform data '

c
c=================================================================
c
c     Read in smoothed data and derivatives from Benny
c
      read( 1 , '(a80)' ) title
      read( 1 , '(i8)'  ) npoints
      write(6,*) 'The number of points is',npoints
c
      do i = 1 , npoints
        read(1,*) ener(i) , ynor(i) , deriv1(i) , deriv2(i) , deriv3(i)
      end do
c
c=====================================================================
c
c     Check atomname against atom library atom.lib and read in
c     . Cromer Libermann correction term etotmc
c     . Lower and upper integration limits
c     . Points on C&L crossec f" curves above and below edge
c
      elolim = -999
c
      do i = 1 , 1000
         read( 4 , '(A2,F8.3)' , end=100 ) element , tmp1
c
c     Test if this is correct atom
c
         if (element .eq. name) then
c
c     If yes then assign etotmc
c
            etotmc = tmp1
c     and search for correct absorption edge parameters
            do k = 1 , 10
               read( 4 , '(A2,2F10.2)', end=100 ) dummy , tmp2 , tmp3
c
c     Is it the correct edge
c
               if (dummy .eq. abedge) then
c
c     If yes then assign integration limits and read following
c     CROSSEC data
c
                  elolim = tmp2
                  ehilim = tmp3
                  read( 4 , * , end=100 ) x1below , y1below , x2below ,
     .                  y2below , x1above , y1above , x2above ,y2above
                  write(6,*) 'Element = ',name,'  Abs. edge = ', abedge
               end if
            end do
         end if
      end do
c
c=======================================================================
c
c     Echo a few things as a check
c

 100   continue
c      write(6 , '(A9,F8.3)'  ) ' C & L Correction term = ' , etotmc
c      write(6 , '(A9,F10.2)' ) 'Lower integration limit = ' , elolim
c      write(6 , '(A9,F10.2)' ) 'Upper integration limit = ' , ehilim
c      write(6, '(2(F10.2,F8.3))' )x1below,y1below,x2below,y2below
c      write(6, '(2(F10.2,F8.3))' )x1above,y1above,x2above,y2above

      if (elolim .lt. 0 ) goto 999
c
      enadd = 0.0
c
c     Finished reading in data and atom parameters so now 
c     we set up the data
c
      k = 0
c
c     set up - find energy difference between adjacent points 
c     extrapolation will be made out to the low and high energy limits 
c
      dx   = ( ener(npoints) - ener(1) ) / float ( npoints - 1 )
      nsta = int ( ( ener(1) - elolim ) / dx )
      nend = nsta - 1 + npoints
c      write(6,*) 'ener(1)       = ' , ener(1)
c      write(6,*) 'ener(npoints) = ' , ener(npoints)
c      write(6,*) 'ehilim = ' , ehilim , '  elolim = ' , elolim
c      write(6,*) 'nsta= ',nsta,'    nend= ', nend
c
c     write experimental spectrum to middle of array 
c
c     This section updated so as to take values of fpp from the crossec
c     program. The form of the fpp curve is assumed to be a straight
c     line and the  values of m and c (y-mx+c) are calculated in
c     subroutine eqofline given two points on the CROSSEC curve. This is
c     done above and below the edge to yield two lines which are then
c     used in a similar fashion as the McMasters curves were. 
c     Gwyndaf Evans 13th September 1994. 
c
      m=0
c      
      call eqofline (x1above , y1above , x2above , y2above , mabove ,
     .      cabove)
      call eqofline (x1below , y1below , x2below , y2below , mbelow ,
     .      cbelow)
c     
      do n = nsta , nend
        ybelow = 0.0
        yabove = 0.0
        m = m + 1
c     
        xener(n) = ener(m)
        yabove = ( mabove * xener(n) ) + cabove
        ybelow = ( mbelow * xener(n) ) + cbelow
c     
        fpptmp(n) = (   ynor(m) * ( yabove - ybelow ) ) + ybelow
        detmp1(m) = ( deriv1(m) * ( yabove - ybelow ) ) + ybelow
        detmp2(m) = ( deriv2(m) * ( yabove - ybelow ) ) + ybelow
        detmp3(m) = ( deriv3(m) * ( yabove - ybelow ) ) + ybelow
      end do
c     
c===================================================================
c     Construct a full spectrum out to high and low energies using
c     McMasters tables of x-ray cross-sections.
c
      call extrap ( npoints , name , atnumb , fpptmp )
c
c     Write debug spectrum file
c
c      open(unit=20 , name='spectrum.dat' , status='unknown' )
c      do k = 1 , npehi
c         write(20,'(i5,f13.2,f20.4)') k , xener(k) , fpptmp(k)
c      end do
c      close(20)
c     
c     
c============================================================
c
c   Now do the Kramers-Kronig integration.
c     
c     Simpson's rule part.  Integration procedure.
c     
c     Start loop for fprime
c     
      m = 1
      do i = nsta , nend
c     
         e0    = xener(i)
         e02   = e0 * e0
         area1 = 0.0
         area2 = 0.0
c     
c     
c     
c     test for (i-1) odd or even
c     
        z  = float ( i - 1 )
        z2 = z / 2.0
        l  = ( i - 1 ) / 2
        z3 = float( l )
        zd = z2 - z3
c     
        if ( zd .ne. 0.0 ) then
c     odd
           itest = 1
        else
c     even
           itest = 0
        endif
c     
c     
c     loop for fpptmp function and segment area calculation
c     below singularity
c     
        do 310 j = 1 , i - 1
c     
           fun1 = xener(j) * fpptmp(j) / ( e02 - xener(j) * xener(j) )
c     
           if( j .eq. (i-1) ) then
              area  = dx * fun1 / 3.0
              area1 = area1 + area
              goto 320
           endif
c     
c     odd
           if( itest .eq. 1 .and. j .eq. 1 ) then
              area  = dx * fun1 / 3.0
              area1 = area1 + area
              goto 310
           endif
c     
c     even
           if( itest .eq. 0 .and. j .eq. 1 ) goto 310
c     
           if( itest .eq. 0 .and. j .eq. 2 ) then
              area  = dx * fun1 / 3.0
              area1 = area1 + area
c     
c     first slice by Trapezium rule.
c     
              fun2  = xener(1) * fpptmp(1) / ( e02 - xener(1) * xener(1)
     .              )
              area  = dx* ( ( fun1 + fun2 ) / 2.0 )
              area1 = area1 + area
              goto 310
           endif
c     
c     Shift j value by +1 to n  so that Simpsons rule work
c     correctly when itest is 0 and 1.
c     
          n = j
          if( itest .eq. 0 ) n = j + 1
c     
c     test for n odd or even to apply 4.0* or 2.0* 
c     in Simpson's rule.
c     
          z  = float(n)
          z2 = z / 2.0
          l  = n / 2
          z3 = float(l)
          zd = z2 - z3
          if( zd .ne. 0.0 ) then
c     if odd
            area  = dx * 2.0 * fun1 / 3.0
            area1 = area1 + area
          else
c     if even
            area  = dx * 4.0 * fun1 / 3.0
            area1 = area1 + area
          endif
 310   continue
c     
 320   tntbel = 2.0 * area1 / pi
c     
c     Loop for integration above singularity
c     
       do 330 j = i + 1 , npehi
c     
c     N.B. for npehi points : if the number of Simpson's rule points
c     was odd below the singularity then it's even above.
c     
c     
          fun2 = xener(j) * fpptmp(j) / ( e02 - xener(j) * xener(j) )
c     
          if( j .eq. i + 1 ) then
            area  = dx * fun2 / 3.0
            area2 = area2 + area
            goto 330
          endif
c     
c     odd
          if( itest .eq. 0 .and. j .eq. npehi - 1 ) then
            area  = dx * fun2 / 3.0
            area2 = area2 + area
            goto 340
          endif
c     
c     even
          if( itest .eq. 1 .and. j .eq. npehi - 2 ) then
            area  = dx * fun2 / 3.0
            area2 = area2 + area
c     
c     last slice by Trapezium rule.
c     
            fun3 = xener ( npehi - 2 ) * fpptmp(npehi - 2) / ( e02 -
     .            xener(npehi - 2) * xener(npehi - 2) )
            fun4 = xener (npehi - 1) * fpptmp(npehi - 1) / ( e02 -
     .            xener(npehi - 1) * xener(npehi - 1) )
            area  = dx * ( ( fun3 + fun4 ) / 2.0 )
            area2 = area2 + area
            goto 340
          endif
c     
          k = j - i            
          z = float(k)
          z2 = z / 2.0
          l = k / 2
          z3 = float(l)
          zd =z2 - z3
          if( zd .ne. 0.0 ) then
c     odd
            area  = dx * 2.0 * fun2 / 3.0
            area2 = area2 + area
          else
c     even
            area  = dx * 4.0 * fun2 / 3.0
            area2 = area2 + area
          endif
 330   continue
c     
 340   tntbov = 2.0 * area2 / pi
c     
c     Now for the singularity itself.
c     
       a = xener(i-1)
       b = xener(i+1)
       fun5 = -fpptmp(i-1) / (e0+a)
       fun6 = -fpptmp(i) / (e0+e0)
       fun7 = -fpptmp(i+1) / (e0+b)
       term1 = dx * ( fun5 + 4.0 * fun6 + fun7 ) / 3.0
c     
       xmod1 = sqrt( (b-e0) * (b-e0) )
       xmod2 = sqrt( (a-e0) * (a-e0) )
       term2 = log(xmod1) - log(xmod2)
c     
       term3 = -detmp1(m) * (b-a)
c     
       term4 = -(detmp2(m) * (b-e0) * (b-e0)/4.0)-((a-e0) * (a-e0))
c     
       term5 = -(detmp3(m) * (b-e0) * (b-e0) * (b-e0)
     .       /18.0)-((a-e0) * (a-e0) * (a-e0))
c     
        tntsin = (term1-term2+term3+term4+term5)/pi
c     
        fp(m) = tntbel+tntsin+tntbov+etotmc
        fpp(m) = fpptmp(i)
c      write(6,*)m,ener(m)
c      write(6,*)ener(m),fp(m),fpp(m)
      if( fp(m) .lt.fpinfl)then
           fpinfl = fp(m)
           fppinfl = fpp(m)
           eninfl = ener(m)
        end if
        if(fpp(m).gt.fpppeak)then
           fpppeak = fpp(m)
           fppeak = fp(m)
           enpeak = ener(m)
        end if
c        write(6,1004)m,npoints
c 1004   format(' Done ',i4,'/',i4,' points')
        m = m + 1
c     
      end do
c     
c     Write output data file containing anomalous scattering
c     factors versus x-ray energy.
c     
      write(2,'(a80)') title
      write(2,'(i8)') npoints                 
      write(2,'(3f10.2)') (ener(i) , fpp(i) , fp(i) , i = 1 , npoints)

c***
c*** Write out data file for BLU-ICE display
c***
      write(8,*)
     +'_graph_title.text "Fp and Fpp from Kramers-Kronig transform"'

      write(8,*)' '
      write(8,*)'_graph_axes.xLabel "Energy (eV)"'            
      write(8,*)'_graph_axes.yLabel "Fp (Electrons)"'
      write(8,*)'_graph_axes.x2Label ""'            
      write(8,*)'_graph_axes.y2Label "Fpp (Electrons)"'

      write(8,*)' '
      write(8,*)'_graph_background.showGrid 1'

      write(8,*)' '
      write(8,*)'data_'
      write(8,*)'_trace.name Transform'            
      write(8,*)'_trace.xLabels "{Energy (eV)}"'
      write(8,*)'_trace.hide 0'

      write(8,*)' '
      write(8,*)'loop_'            
      write(8,*)'_sub_trace.name'
      write(8,*)'_sub_trace.yLabels'
      write(8,*)'_sub_trace.color'
      write(8,*)'_sub_trace.width'
      write(8,*)'_sub_trace.symbol'
      write(8,*)'_sub_trace.symbolSize'
      write(8,*)'fp "{Electrons} {Fp (Electrons)}" red 2 none 2'
      write(8,*)'fpp "{Electrons} {Fpp (Electrons)}" green 2 none 2'
 
      write(8,*)' '
      write(8,*)'loop_'
      write(8,*)'_sub_trace.x'
      write(8,*)'_sub_trace.y1'
      write(8,*)'_sub_trace.y2'

c***Write out data info to unit 8
      do 645 I=1,npoints
      write(8,*)ener(I),fp(I),fpp(i)
 645  continue 

      close(8)

      write(6,*)' CHOOCH_STATUS: writing file fp_fpp.bip'

c
c     Write results to terminal and to the '.inf' file
c     
      write(3,'(a80)')title
      write(3,1008)npehi
      write(3,1004)elolim,ehilim
      write(3,1009)ener(1),ener(npoints)
      write(3,1010)dx
      write(3,*)
      write(3,1001)
      write(3,1002)eninfl,fpinfl,fppinfl
      write(3,1003)enpeak,fppeak,fpppeak
 1001 format(' |             |   E (eV)   |    fp   |   fpp   |'
     .      )
 1002 format(' | Fp minimum  |' ,f10.2,'  | ',f6.1,'  | ',f6.1
     .      ,'  |')
 1003 format(' | Fpp maximum |' ,f10.2,'  | ',f6.1,'  | ',f6.1
     .      ,'  |')
 1004 format(' Integration limits low/high : ',2f10.2)
 1010 format(' Energy scale increment      : ',f6.3)
 1009 format(' First/last data points at   : ',2f10.2)
 1008 format(' Total points integrated     : ',i10)
      write(6,*)
      write(6,1001)
      write(6,1002)eninfl,fpinfl,fppinfl
      write(6,1003)enpeak,fppeak,fpppeak
      write(6,*)
   
      write(6,*) 'Inflection_info', eninfl,fpinfl,fppinfl
      write(6,*) 'Peak_info', enpeak,fppeak,fpppeak


c
c     PGPLOT routine to create xwindow plot of anomalous scattering
c     factors and create PostScript plot if requested.
c
c      call efsplot ( npoints , fpp , fp )
c
c     Close down files
c
      close(1)
      close(2)
      close(3)
      close(4)
c
      stop
c
c
c
 999  write(6,*) 'ERROR - *** Element name symbol not recognised *** '
c     
      end
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
