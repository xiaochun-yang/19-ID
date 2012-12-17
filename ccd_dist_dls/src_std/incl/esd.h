/*
 *	This is the command TO the scanner definition, without
 *	loading any tables (which follows what you see below).
 *
 *	This structure will be modified to indicate the table
 *	structure at a future date.
 */

struct esd_command 
	{
	short	esd_number;
	short	esd_mode;
	int	esd_par_1;
	int	esd_par_2;
	short	esd_aux_1;
	short	esd_aux_2;
	char	esd_ascii[32];
	char	esd_unused[464];
	};

/*
 *	ESD controller status block definition.
 *
 *	The following is the layout of the ESD controller status block.
 *	It occupies the first two blocks of the controller memory.
 *
 *	Note the address following each entry is the beginning address
 *	of that element in the ESD controller, in hex.
 *
 *	Unfortunately, the layout in memory does not take into account
 *	that most compilers would make certain variable alignment
 *	decisions at odds with the ESD memory layout.  Therefore, it
 *	is not possible (on SGI machines) to just read and write this
 *	structure's contents to or from the ESD controller memory.
 *
 *	In particular, a short on a longword boundary followed by an
 *	int leaves a 2 byte gap in the structure definition, but not
 *	in the ESD controller.
 *
 *	Therefore, it is necessary to use a 1024 byte buffer when
 *	transferring data from the status block so that proper alignment
 *	occurs.  In particular, the user reads the first two blocks
 *	of scanner memory into a buffer "tank" and:
 *
 *			char			tank[1024];
 *			struct esd_status_block	b;
 *
 *	Then:
 *			mbytes(&tank[0],86,b.cmd_status);
 *			mbytes(&tank[86],42,&b.leaving_homepos);
 *			mbytes(&tank[128],896,&b.phi_ramp);
 *
 *	where mbytes is a c routine shich move the second argument's
 *	number of bytes from the first variable address to the last.
 *
 *	This may need to be custom for each compiler/architecture.
 */
struct esd_status_block
  {
	char	cmd_status[16][2];	/*  0000-001E = 32 bytes  */
	short	undefined_1_[16];	/* (0020-003E = 32 chars) */
/*
 * ----   so far      ....  together 64 chars ...
 *
 * ----   current updates of experimental settings:
 *
 */
	int	ion_chamber;		/* 0040      0       *1*	*/
	char	input_register_pit;	/* 0044      0      [*2*]	*/
	char	input_register_cio;	/* 0045      0      [*2*]	*/
	char	output_register_pit;	/* 0046      0      [*3*]	*/
	char	output_register_cio;	/* 0047      0      [*3*]	*/
	int	s_phi_axis_steps;	/* 0048      0       *4*	*/
	int	s_distance_steps;	/* 004C      0       *5*	*/
	int	omega_steps;		/* 0050      0       *6*	*/
	short	set_data_valid;		/* 0054      0       *7*	*/
/*
 *
 * ---- time_out ("DURation",[msec]) & speed parameters:
 *
 */
	int	leaving_homepos;	/* 0056  30000       *8*	*/
	int	searching_homepos;	/* 005A  60000       *9*	*/
	int	searching_index;	/* 005E  30000       *10*	*/
	int	try_to_lock_time;	/* 0062  30000       *11*	*/
	int	reset_time;		/* 0066  60000       *12*	*/
	int	lock_time;		/* 006A  60000       *13*	*/
	int	event_watchdog_time;	/* 006E  60000       *14*	*/
	int	quick_erase_time;	/* 0072  15000       *15*	*/
	short	reset_speed;		/* 0076  $A000       *16*	*/
	short	neg_reset_speed;	/* 0078  $6000       *17*	*/
	short	lock_speed;		/* 007A  $8064       *18*	*/
	short	home_speed;		/* 007C  $87D0       *19*	*/
	short	leaving_home_speed;	/* 007E  $7000       *20*	*/
	int	phi_ramp;		/* 0080      2       *21*	*/
	int	omega_ramp;		/* 0084      2       *22*	*/
	int	distance_ramp;		/* 0088      2       *23*	*/
	int	expose_phi_speed;	/* 008C    100       *24(?)*	*/
	int	exp_delta_phi_steps;	/* 0090      1       *25(?)*	*/
/*
 *	                ....  together 84 chars ...
 */
	int	undefined_2_[11];	/*(0094-00BC)	    *26(?)...*	*/
/*
 *	so far      ....  total : 192 chars ...
 */

/*
 * ----  internal step_motor control, etc.:
 */
	short  reserved_1_[8];		/*(00C0=00CE = 16 chars)	*/
/*
 * ----  memory addresses, and current pointers:
 */
	int	phys_d_ram_begin;	/* 00D0	*/
	int	phys_d_ram_end;		/* 00D4	*/
	int	phys_v_ram_begin;	/* 00D8	*/
	int	phys_v_ram_end;		/* 00DC	*/
	int	d_ram_readpointer;	/* 00E0	*/
	int	d_ram_writepointer;	/* 00E4	*/
	int	block_in_work;		/* 00E8	*/
	int	p_error_block;		/* 00EC	*/
/*
 *    so far      ....  total : 240 chars ...
 */

/*
 * ----  messages (rotating buffer; writepointer=1 if no message):
 */
	short	s_msg_readpointer;	/* 00F0		*/
	short	s_msg_writepointer;	/* 00F2		*/
	short	s_last_command;		/* 00F4		*/
	short	s_last_valid_data;	/* 00F6		*/
	short	reserved_2_[4];		/* 00F8-00FE	*/
/*
 *	At the end, padded to 2 blocks
 */
	char	message[32][24];	/* 0100-03FF */
  };

