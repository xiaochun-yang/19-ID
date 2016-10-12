c
c General PGPLOT routine
c
      subroutine topgplot ( npoints , fpp , fp )
c
c
c
      include 'size.fh'
      include 'energy.fh'
      include 'extrem.fh'
      include 'char.fh'
      include 'pgvars.fh'
      real fpp(isize) , fp(isize)
      real xmin,xmax,ymin,ymax
      integer pgopen , id1 , id3
      integer col0 , col1 , col2 , col3 , col4 , col5 , col6
c
c PGPLOT colours
c
c 0	black
c 1	white
c 0	white
c 1	black
c 2	red
c 3	green
c 4	blue
c 5	cyan
c 6	magenta
c 7	yellow
c 8	orange
c 9	lime green
c 10	dull green
c 11	medium blue
c 12	purple
c 13	pink
c 14	dark grey
c 15	light grey
c
c background
      col0=0
c axis labels
      col1=1
c text above plot and background fits
      col2=4
c some text and smoothed data
      col3=1
c curve plotting colour
      col4=2
c key code
      col5=1
c colour for zoom mode
      col6=6
c     
c
c Initialise pgplot
c
      id1=pgopen('/xwin')
      if(id1.lt.0)stop
      id3=pgopen('plot.ps/cps')
      if(id3.lt.0) stop
      call pgslct(id1)
c     
      xmin=ener(1)
      xmax=ener(npoints)
      emin1=xmin
      emax1=xmax
      ymin=fpinfl-0.5
      ymax=fpppeak+0.5
 501  call pgpap(9.0,0.7)
      call pgscr(0,1.0,1.0,1.0)
      call pgscr(1,0.0,0.0,0.0)
      call pgask(.false.)
      call pgslw(2)
      call pgscf(2)
      call pgsch(1.6)
      call pgsci(col1)
      call pgsvp(0.2,0.90,0.15,0.9)
      call pgswin(xmin,xmax,ymin,ymax)
      call pgbox('bcnts1',0.0,0,'bcnts1v',0.0,0)
      call pgscr(21,0.0,1.0,0.0)
      call pgmtxt('b',2.5,0.5,0.5,'X-ray Energy (eV)')
      call pgmtxt('l',4.0,0.5,0.5,'Anomalous scattering factors')
      call pgmtxt('rv',2.0,0.8,0.0,'f``')
      call pgmtxt('rv',2.0,0.2,0.0,'f`')
c
      ipow=-2
      call pgsci(col2)
      call pgsch(1.2)
      icor=int(eninfl*100)
      call pgnumb(icor,ipow,1,text,num)
      call pgmtxt('t',2.6,0.0,0.0,title)
      call pgsch(1.0)
      call pgmtxt('t',1.6,0.0,1.0,'E(infl) = ')
      call pgmtxt('t',1.6,0.25,1.0,text)
      call pgmtxt('t',1.6,0.3,1.0,'eV')
      icor=int(enpeak*100)
      call pgnumb(icor,ipow,1,text,num)
      call pgmtxt('t',1.6,0.6,1.0,'E(peak) = ')
      call pgmtxt('t',1.6,0.85,1.0,text)
      call pgmtxt('t',1.6,0.9,1.0,'eV')
c
c
c
      ipow=-2
      call pgsci(col2)
      call pgsch(1.0)
      icor=int(fpinfl*100)
      call pgnumb(icor,ipow,1,text,num)
      call pgmtxt('t',0.5,0.0,1.0,' f` min = ')
      call pgmtxt('t',0.5,0.25,1.0,text)
      call pgmtxt('t',0.5,0.3,1.0,'e')
      icor=int(fpppeak*100)
      call pgnumb(icor,ipow,1,text,num)
      call pgmtxt('t',0.5,0.6,1.0,'f`` max = ')
      call pgmtxt('t',0.5,0.85,1.0,text)
      call pgmtxt('t',0.5,0.9,1.0,'e')
c
c
c
      call pgsci(col5)
      call pgmtxt('LV',9.0,0.00,0.0,'Zoom (z)  ')
      call pgmtxt('LV',9.0,-0.05,0.0,'Redraw (r)  ')
      call pgmtxt('LV',9.0,-0.10,0.0,'PS file (p)  ')
      call pgmtxt('LV',9.0,-0.15,0.0,'Quit (q)')
      call pgsci(col4)
      call pgline(npoints,ener,fpp)
      call pgline(npoints,ener,fp)
c     
c Get command character from PGPLOT window
c
c 997  call pgcurs(xcor,ycor,ch)
      xold=1000.0
      yold=0.0
 997  call pgband(6,0,xcor,ycor,xcor,ycor,ch)
      if(ch.ne.'q'.or.ch.ne.'Q')then
         call pgsci(col0)
         call pgsch(1.0)
         icor=int(xold*100)
         call pgnumb(icor,ipow,2,text,num)
         call pgmtxt('lv',9.0,0.97,0.0,text)
         icor=int(xcor*100)
         call pgnumb(icor,ipow,2,text,num)
         call pgsci(col3)
         call pgmtxt('lv',9.0,0.97,1.0,'E = ')
         call pgmtxt('lv',9.0,0.97,0.0,text)
         call pgmtxt('lv',2.0,0.97,0.0,'eV')
         xold=xcor
c
c     
c
         call pgsci(col0)
         call pgsch(1.0)
         icor=int(yold*100)
         call pgnumb(icor,ipow,1,text2,num)
         call pgmtxt('lv',9.0,0.94,0.0,text2)
         icor=int(ycor*100)
         call pgnumb(icor,ipow,1,text2,num)
         call pgsci(col3)
         call pgmtxt('lv',9.0,0.94,1.0,'f = ')
         call pgmtxt('lv',9.0,0.94,0.0,text2)
         call pgmtxt('lv',5.0,0.94,0.0,'e')
         yold=ycor
      end if
c
c Zoom routine
c
      if(ch.eq.'z')then
         call pgsci(col0)
         call pgsch(1.0)
         icor=int(xold*100)
         call pgnumb(icor,ipow,1,text,num)
         call pgmtxt('t',0.5,0.0,1.0,'E = ')
         call pgmtxt('t',0.5,0.3,1.0,text)
         call pgmtxt('t',0.5,0.4,1.0,'eV')
         call pgsci(col2)
         call pgmtxt('T',-0.8,0.35,1.0
     +       ,' ... select lower E for replot')
         call pgband(6,0,xmin,xdum,xmin,xdum,ch)
         call pgsci(col0)
         call pgmtxt('T',-0.8,0.35,1.0
     +       ,' ... select lower E for replot')
         call pgsci(col2)
         call pgmtxt('T',-0.8,0.35,1.0
     +       ,' ... select upper E for replot')
         call pgband(6,0,xmax,xdum,xmax,xdum,ch)
         call pgsci(col0)
         call pgmtxt('T',-0.8,0.35,1.0
     +       ,' ... select upper E for replot')
         call pgpage
         goto 501
      end if
c
c Redraw original plot
c
      if(ch.eq.'r')then
        xmin=emin1
        xmax=emax1
        call pgpage
        goto 501
      end if
c
c Dump plot to file
c
      if(ch.eq.'p')then
         call pgslct(id3)
         call pgscf(2)
         call pgsch(1.2)
         call pgsci(col1)
         call pgsvp(0.2,0.90,0.15,0.9)
         call pgswin(xmin,xmax,ymin,ymax)
         call pgbox('bcnts1',0.0,0,'bcnts1v',0.0,0)
         call pgscr(21,0.0,1.0,0.0)
         call pgmtxt('b',2.5,0.5,0.5,'X-ray Energy (eV)')
         call pgmtxt('l',4.0,0.5,0.5,'Anomalous scattering factors')
         call pgmtxt('rv',2.0,0.8,0.0,'f``')
         call pgmtxt('rv',2.0,0.2,0.0,'f`')
c     
         ipow=-2
         call pgsch(1.2)
         icor=int(eninfl*100)
         call pgnumb(icor,ipow,1,text,num)
         call pgmtxt('t',2.6,0.0,0.0,title)
         call pgsch(1.0)
         call pgmtxt('t',1.6,0.0,1.0,'E(infl) = ')
         call pgmtxt('t',1.6,0.25,1.0,text)
         call pgmtxt('t',1.6,0.3,1.0,'eV')
         icor=int(enpeak*100)
         call pgnumb(icor,ipow,1,text,num)
         call pgmtxt('t',1.6,0.6,1.0,'E(peak) = ')
         call pgmtxt('t',1.6,0.85,1.0,text)
         call pgmtxt('t',1.6,0.9,1.0,'eV')
c     
c     
c     
         ipow=-2
         call pgsch(1.0)
         icor=int(fpinfl*100)
         call pgnumb(icor,ipow,1,text,num)
         call pgmtxt('t',0.5,0.0,1.0,' f` min = ')
         call pgmtxt('t',0.5,0.25,1.0,text)
         call pgmtxt('t',0.5,0.3,1.0,'e')
         icor=int(fpppeak*100)
         call pgnumb(icor,ipow,1,text,num)
         call pgmtxt('t',0.5,0.6,1.0,'f`` max = ')
         call pgmtxt('t',0.5,0.85,1.0,text)
         call pgmtxt('t',0.5,0.9,1.0,'e')
c     
         call pgline(npoints,ener,fpp)
         call pgline(npoints,ener,fp)
         call pgpage
         call pgslct(id1)
         call pgsch(1.2)
         goto 997
      end if
c
c Quit routine
c
 998  if(ch.eq.'q'.or.ch.eq.'Q')goto 999
      goto 997
 999  call pgend
c
c
c
      return
      end
