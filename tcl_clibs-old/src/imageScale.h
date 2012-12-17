extern "C" {
int imageScaleBilinear( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

int imageResizeBilinear( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

//like subsampling but take average of the block.
int imageSubSampleAvg( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

int imageDownsizeAreaSample( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );
};
