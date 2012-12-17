#include	"detcon_ext.h"

/*
 *	These functions form the core of the detector control library.
 */

/*
 *	Begin an exposure.
 */

int	CCDStartExposure()
  {
	dtc_last = CCD_LAST_START;
	exec_ccd_start_exposure();
  }

/*
 *	Stop the current exposure, causing data to be transferred from
 *	the CCDs to local memory in the W95 PC.
 */

int	CCDStopExposure()
  {
	dtc_last = CCD_LAST_STOP;
	exec_ccd_stop_exposure();
  }

/*
 *	Return a string indicating the current state of the detector.
 *
 *	This string will be used to display status on the user GUI.
 */

char	*CCDStatus()
  {
	return(dtc_status_string);
  }

/*
 *	Return the state of the detector.  Enum in ../incl/detcon_state.h
 */

int	CCDState()
  {
	return(dtc_state);
  }

/*
 *	Set a file parameter.  Parameter enums found in ../incl/detcon_par.h
 */

int	CCDSetFilePar(which_par,p_value)
int	which_par;
char	*p_value;
  {
	detcon_set_file_param(which_par,p_value);
  }

/*
 *	Return a file parameter.  enums found in ../incl/detcon_par.h
 */

int	CCDGetFilePar(which_par,p_value)
int	which_par;
char	*p_value;
  {
	detcon_get_file_param(which_par,p_value);
  }

/*
 *	Set a Hardware Parameter.  enums found in ../incl/detcon_par.h
 */

int	CCDSetHwPar(which_par,p_value)
int	which_par;
char	*p_value;
  {
	detcon_set_hw_param(which_par,p_value);
  }

/*
 *	Return a Hardware Parameter.  Enums found in ../incl/detcon_par.h
 */

int	CCDGetHwPar(which_par,p_value)
int	which_par;
char	*p_value;
  {
	detcon_get_hw_param(which_par,p_value);
  }

/*
 *	Set binning.  1 for 1x1, 2 for 2x2.
 */

int	CCDSetBin(val)
int	val;
  {
  }

/*
 *	Return current binning value.  1 for 1x1, 2 for 2x2.
 */

int	CCDGetBin()
  {
  }

/*
 *	Cause the image stored in the W95 PC, which has been previously
 *	transferred from the CCDs to local PC memory, to be transmitted
 *	to the transform process.  This will cause whatever defaults are
 *	in effect (output raws, transform image, etc.) to be carried out.
 *	No further calls are required to produce appropriate files on disk.
 *
 *	"last" is 1 if this is the last image in a sequence, otherwise 0.
 *	This is required since the data is double-buffered in the W95 PC
 *	so it it necessary to know when this data must be "flushed".  This
 *	variable must be set to 1 for a single image or the last image in
 *	a run.
 */

int	CCDGetImage()
  {
	dtc_last = CCD_LAST_GET;
	exec_ccd_get_image(dtc_lastimage);
  }

/*
 *	This call is not necessary, but is here, since this funciton is
 *	automatically carried out by CCDGetImage above.
 */

int	CCDCorrectImage()
  {
  }

/*
 *	This call is not necessary, but is here, since this function is
 *	automatically carried out by CCDGetImage above.
 */

int	CCDWriteImage()
  {
	exec_ccd_get_image(dtc_lastimage);
  }

/*
 *	Return the last error, "none" if there is no error in effect.
 */

char	*CCDGetLastError()
  {
	return(dtc_lasterror_string);
  }

/*
 *	Abort the current image in progress, if any.
 */

int	CCDAbort()
  {
	exec_ccd_abort();
  }

/*
 *	Reset the state of the detector control software to a useful state.
 *	A call to this function will cause the detector to reset to a known
 *	state and various error indicators reset.  Designed to be called after
 *	an error occurs or an abort is issued.
 */

int	CCDReset()
  {
	exec_reset();
  }

/*
 *	Initialize the state of the CCD acquistion software.  This function MUST
 *	be called before ANY hardware functions may be called.  This call will
 *	bring up the network connections between the PC, the transform process,
 *	and this control library.  The "state" will be returned as "idle" when
 *	all connections are made and the control software is capable of collecting
 *	an image.
 */

int	CCDInitialize()
  {
	exec_initialize();
  }

int	CCD_HWReset()
{
	exec_hw_reset();
}
