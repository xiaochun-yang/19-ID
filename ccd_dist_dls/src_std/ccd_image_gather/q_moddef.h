/*
 *	Module definition structure.
 */

/*
 *	Topological information.  Types, ports, rotations, module placement
 *	assignment and so forth.
 */

struct 	q_moddef {
		  int	q_def;			/* 1 if defined, 0 if not */
		  int	q_type;			/* 0 for master, 1 for slave, 2 for not installed */
		  int	q_serial;		/* controller serial number */
		  int	q_bn;			/* board number */
		  char	q_assign;		/* W, X, Y, or Z */
		  int	q_rotate;		/* 0, 90, 180, or 270 */
		  char	q_host[256];	/* hostname for this module */
		  int	q_port;			/* port number */
		  int	q_dport;		/* port number for data */
		  int	q_sport;		/* port number, secondary commands */
		 };

/*
 *	Hardware parameter information.  Temperature control and gains.
 */

struct	q_conkind {
		  int	qc_type;		/* 0 for master, 1 for slave */
		  int	qc_serial;		/* serial number */
		  int	qc_te_gain;		/* temp te gain */
		  int	qc_te_offset;	/* temp te offset */
		  float	qc_te_tweak_b;	/* temperature tweak intercept */
		  float	qc_te_tweak_m;	/* temperature tweak, slope */
		  int	qc_offset[4];	/* balance tool type offsets for each quadrant */
		  int	qc_gain[4];		/* balance tool type gains for each quadrant */
		};