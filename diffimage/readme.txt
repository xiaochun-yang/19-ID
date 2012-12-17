To build diffimage and imgsrv with ImageMagik markup support:

1. Build image magik 6.3.2 or above:

> tar ImageMagick-6.3.2-3.tar
> cd ImageMagick-6.3.2

For linux:
> ./configure \
  --enable-embeddable \
  --with-quantum-depth=8 \
  --without-perl --without-dps --without-jbig --without-jpeg \
  --without-jp2 --without-lcms --without-tiff --without-ttf \
  --without-xml --without-x --without-bzlib --without-zlib \
  --without-gslib --without-png --without-freetype \
  --disable-shared
> mkdir linux
> make
> cp ./magick/.libs/libMagick.a linux
> cp ./Magick++/lib/.libs/libMagick++.a linux
> cp ./wand/.libs/libWand.a linux

For irix with CC compiler:

> ./configure CC=cc CXX=CC \
CFLAGS="-O2 -OPT:Olimit=0 -MP:dsm=off -LANG:std=on -LANG:exceptions=on -no_prelink -ptused" \
CXXFLAGS="-MP:dsm=off -LANG:std=on -W1 -O2 -LANG:exceptions=on -no_prelink -ptused" \
CXXCPP="CC -LANG:std -E" \
CPPFLAGS="-I/home/scottm/code/working/jpeg-6b -I/usr/include -I/usr/local/include" \
LIBS="-lC -lc -lm -lpthread" \
--enable-embeddable --with-quantum-depth=8 --without-perl --without-dps --without-jbig \
--without-jpeg --without-jp2 --without-lcms --without-tiff --without-ttf --without-xml \
--without-x --without-bzlib --without-zlib --without-gslib --without-png --without-freetype \
--disable-shared --with-magick-plus-plus
> mkdir irix
> make
> cp ./magick/.libs/libMagick.a irix
> cp ./Magick++/lib/.libs/libMagick++.a irix
> cp ./wand/.libs/libWand.a irix

Before running make, check if /etc/compiler.defaults is -DEFAULT:abi=n32:isa=mips4
    
O2: request the best set of conservative optimizations; that is, 
    those that do not reorder statements and expressions.
Olimit: specifies the maximum size, in basic blocks, 
        of a routine that the compiler will optimize.
dsm=off: do not generate ii_files

Also need to modify configure so that have_magick_plus_plus is set to 'yes'.



For decunix:
> ./configure CC=cxx CXX=cxx \
CFLAGS="-pthread -DSEC_BASE -DSEC_NET  -D__USE_STD_IOSTREAM" \
CPPFLAGS="-I/home/code/jpeg-6b/release/decunix -I/usr/include/cxx -I/usr/local/include" \
LDFLAGS="-ptr ./decunix/cxx_repository" \
--enable-embeddable --with-quantum-depth=8 --without-perl --without-dps \
--without-jbig --without-jpeg --without-jp2 --without-lcms --without-tiff \
--without-ttf --without-xml --without-x --without-bzlib --without-zlib \
--without-gslib --without-png --without-freetype --disable-shared
> mkdir decunix
> make
> cp ./magick/.libs/libMagick.a decunix
> cp ./Magick++/lib/.libs/libMagick++.a decunix
> cp ./wand/.libs/libWand.a decunix

Template repository path is ./decunix/cxx_repository dir.



2. Build diffimage


> cd diffimage
> gmake clean
> gmake IMAGEMAGICK_MARKUP=TRUE


3. Build imgsrv

> cd imgsrv
> gmake clean
> gmake IMAGEMAGICK_MARKUP=TRUE



