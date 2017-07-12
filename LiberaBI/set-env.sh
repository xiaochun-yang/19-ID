#!/bin/bash

# Path to directory which contains
# module and dependency directories
DIR=$(pwd)

# Dependencies directory
DEP_DIR=$DIR"/dependencies/"

export TCLLIBPATH=$DIR"/DcsWidgets"
export TCLLIBPATH+=" "$DIR"/BluIceWidgets"

export TCLLIBPATH+=" "$DEP_DIR"itcl3.4"
export TCLLIBPATH+=" "$DEP_DIR"itk3.3"
export TCLLIBPATH+=" "$DEP_DIR"tcllib-1.6.1/modules/csv"
export TCLLIBPATH+=" "$DEP_DIR"tcllib-1.6.1/modules/base64"
export TCLLIBPATH+=" "$DEP_DIR"tcllib-1.6.1/modules/cmdline"
export TCLLIBPATH+=" "$DEP_DIR"tcllib-1.6.1/modules/mime"
export TCLLIBPATH+=" "$DEP_DIR"tcllib-1.6.1/modules/md5"
export TCLLIBPATH+=" "$DEP_DIR"itk3.3/library"
export TCLLIBPATH+=" "$DEP_DIR"iwidgets4.0.0"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/base"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/window"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/tga"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/ico"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/pcx"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/sgi"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/sun"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/xbm"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/xpm"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/ps"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/jpeg"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/libjpeg"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/png"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/libpng"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/zlib"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/tiff"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/libtiff"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/bmp"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/ppm"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/gif"
export TCLLIBPATH+=" "$DEP_DIR"tkimg1.4/pixmap"
export TCLLIBPATH+=" "$DEP_DIR"tls1.6.4"


export ITK_LIBRARY=$DEP_DIR"itk3.3/library"
export ITCL_LIBRARY=$DEP_DIR"itcl3.4/library"

export LD_LIBRARY_PATH=":"$DEP_DIR"itcl3.4"

echo "TCLLIBPATH: $TCLLIBPATH"
echo "ITK_LIBRARY: $ITK_LIBRARY"
echo "ITCL_LIBRARY: $ITCL_LIBRARY"
echo ""

echo "Env. vars set"
echo ""

export PS1="(bluice env) [\u@\h \W]\$ "

bash

