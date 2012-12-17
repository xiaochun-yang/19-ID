#include	"detcon_ext.h"

/*
 *	Function to begin the hardware "heartbeat" for simulation
 *	operation.  Each beat will be one second.  A "pause" is done
 *	in this routine to idle out the unused time.
 */


detcon_clockstart()
  {
	int	i;
	void	detcon_server_update();

	enqueue_fcn(detcon_server_update,0,1.0);

	init_clock();
  }
