c
c	Some simple interfaces to fortran's fast(er)
c	file I/O.
c
	integer function ff_for_initfile(fname,fno,fac,frecsize,nrec)
	character *(*)	fname
	integer		fno
	integer		fac
	integer		frecsize
	integer		nrec

	integer		isize
	integer		rsize

	isize = (511 + frecsize * nrec) / 512
	rsize = frecsize / 4

	if(fac .eq. 0) then

		open(unit=fno,file=fname,recl=rsize,
     1		    recordtype='fixed',status='old',
     2		    form='unformatted',access='direct',
     3		    err=9100)
		ff_for_initifile = 0
		return

9100		continue
		ff_for_initfile = -1
		return
	endif

	if(fac .eq. 1) then

		open(unit=fno,file=fname,recl=rsize,
     1		    recordtype='fixed',status='old',
     2		    form='unformatted',access='direct',
     3		    err=9200)
		ff_for_initifile = 0
		return

9200		continue
		ff_for_initfile = -1
		return
	endif
		if(isize .eq. 0) then
		open(unit=fno,file=fname,recl=rsize,
     1		    recordtype='fixed',status='new',
     2		    form='unformatted',access='direct',
     3		    err=9300)
		  else
		open(unit=fno,file=fname,recl=rsize,
     1		    recordtype='fixed',status='new',
     2		    form='unformatted',access='direct',
     3		    initialsize=isize,err=9300)
		endif
		ff_for_initifile = 0
		return

9300		continue
		ff_for_initfile = -1
		return

	end

	integer function ff_for_close(fno)
	integer	fno

	close(unit=fno)

	return
	end

	integer function ff_for_read(fno,buf,nbytes,avar)
	integer	fno
	byte buf(1)
	integer	nbytes
	integer avar

	integer i

	read(unit=fno,rec=avar,err=9100) (buf(i),i=1,nbytes)

	ff_for_read = 0
	return

9100	continue
	ff_for_read = -1
	return
	end

	integer function ff_for_write(fno,buf,nbytes,avar)
	integer	fno
	byte buf(1)
	integer	nbytes
	integer	avar

	integer i

	write(unit=fno,rec=avar,err=9100) (buf(i),i=1,nbytes)

	ff_for_write = 0
	return

9100	continue
	ff_for_write = -1
	return
	end

	integer function ff_for_rewind(fno)
	integer	fno

	rewind(unit=fno)
	ff_for_rewind = 0
	return
	end
