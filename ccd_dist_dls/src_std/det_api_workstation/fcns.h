/*
 *	Function prototypes collected here.
 */

void	cleanexit(int status);
int 	process_buffer(int fd);
int 	execute_command(int fd_used);
void	notify_server_eof(int fd);
char	*ztime();

int 	start_ccd_exposure();
int 	transmit_data(int i);
int 	stop_ccd_exposure(int   abort);
int 	stop_ccd_exposure_r(int abort);
int 	stop_ccd_exposure_w(int abort);
void	initial_defaults();
int 	ccd_soft_reset();
int		get_ccd_status(char *s);
void	send_to_ccd_gather(int *fd);
void	send_to_ccd_gather_mserv(int *fd);
void	operate_j5shutter();
void	temperature_control(int cmd_no);
int 	ccd_hw_reset();
int 	ccd_powerupinit();
void	ldcon_setdefaults(int adc, int trig, int bin);

int 	amic_init();
int 	ccd_hw_cleanup();
void	process_input();
int 	ccd_hw_init();
int 	get_moddb(struct q_moddef *qm, int max_c, char *fname, int ignorehost);
void	print_moddb(struct q_moddef *qm, int max_c);
int 	get_moddb_eev(struct q_moddef *qm, int max_c, char *fname, int ignorehost);
void	print_moddb_eev(struct q_moddef *qm, int max_c);
int 	find_controller_info(int serial, struct q_conkind *pconk);
void	order_modules(struct q_moddef *qm, int maxc, int *pvec);
void	print_moddb_local();

int		WINAPI pvWriteBoardIO( BYTE  byBoardNum,
                            DWORD dwOffset,
                            DWORD dwData);
int		WINAPI pvReadBoardIO( BYTE  byBoardNum,
                            DWORD dwOffset,
                            DWORD *dwData);

int 	WINAPI pvGetCaptureStats( BYTE  byBoardNum, BOOL bReset, PCAPSTATS caps);

int 	get_temp_centegrade(BYTE bn, double *result);

int 	rdfile (char* filename, char** head, int *lhead, char** array, int* naxis, int* axis, int *type);

void	new_pedestal_correct( char *header, unsigned short *data,int uniform_pedestal, int size, int nctrl, int rot_mod, int offset);
void	new_pedestal_correct_bin( char *header, unsigned short *data,int uniform_pedestal, int size, int nctrl, int rot_mod, int offset);
void	xf_main_sub(int nmod, int *modnos, int *modrot, char *dirname);
void	xf_main_sub_2bin(int nmod, int *modnos, int *modrot, char *dirname, int ext_hb, char *hb_string, int *offsets);
void	xf_put_header_buf(int mod, char *hd, int hdlen, int kind);
void	xf_put_data_buf(int mod, unsigned short *data, int len_ushort, int kind);
void	xf_exec_buffer(int mod, int raw_action, int xform_action, int kind);
void	xf_get_cor_header_buf(int mod, char *hd, int *hdlen);
void	xf_get_cor_data_buf(int mod, unsigned short *cor_data);
void	xf_set_params(int bin, int nrows, int ncols, int image_size, int use_stored_dark);
void	xf_set_params_new(int bin, int nrows, int ncols, int image_size, int hw_bin, int use_stored_dark);
void	xf_set_params_q4(int bin, int nrows, int ncols, int image_size, int adc, int use_stored_dark);
char	*xf_get_raw_header_buf(int  mn);
unsigned short  *xf_get_raw_data_buf(int mn);
void	mserver_queue(struct mserver_buf *mp);
struct	mserver_buf *mserver_get_buffer(struct mserver_buf *mp);

int 	read_port_raw(int fd, char *ptr, int len);
int 	rep_write(int fd, char *ptr, int len);
int 	check_port_raw(int fd);
int 	read_until(int fd, char *buf, int size, char *term);

int 	dynamic_init();
void	initial_defaults();
int 	ccd_was_init();
int 	loadfile();
int 	recover_from_error();
int		ccddet_init_all();


int		clock_heartbeat();
void    tempcon_update();
int 	time_since_last_temp_read();
void	do_temperature_read_cycle();


int 	get_temp_centegrade(BYTE bn, double *tval);
int 	set_temp_centegrade(int  bn, double tval, double *aval);


/*
 * Routines to deal with byte order
 */
int		getbo(void);
int		swpbyt(int mode, int length, char* array);
 
/*
 * Routines to deal with the header
 */
void	clrhd ( char* header );
void	gethd ( char* field, char* value, char* header );
int		gethdl ( int* headl, char* head );
int		gethddl ( int* headl, char* head );
int		gethdn ( int n, char* field, char* value, char* header );
void	puthd (char* field, char* value, char* header);
void	padhd (char* header, int size);

void	mult_host_dbfd_setup();
int 	which_module_number(char assign_char);
void	modify_lineaux_entries();
void	modify_lineaux_entries_hb();
void	process_input_control_dets();
void	det_xf_interface_init();

int 	local_rep_write(int fd, void *p, int len);
int     read_module_from_disk(int im_type, char *info, int ndet, unsigned short *data_buffer, char *header_buffer);
void    create_simdata(int im_type, char *info, int ndet, unsigned short *data_buffer, char *input_header_buffer, char *output_header_buffer);

void    crop_bin_270(unsigned short *in, unsigned short *out, int in_x_org, int in_y_org, int in_x_size,  int out_x_org, int out_y_org, int out_x_size, int ped);
void    crop_bin_180(unsigned short *in, unsigned short *out, int in_x_org, int in_y_org, int in_x_size,  int out_x_org, int out_y_org, int out_x_size, int ped);
void    crop_bin_90(unsigned short *in, unsigned short *out, int in_x_org, int in_y_org, int in_x_size,  int out_x_org, int out_y_org, int out_x_size, int ped);
void    crop_bin_0(unsigned short *in, unsigned short *out, int in_x_org, int in_y_org, int in_x_size,  int out_x_org, int out_y_org, int out_x_size, int ped);
void	crop_square(unsigned short *in, unsigned short *out, int in_size, int out_size, int corner_x, int corner_y);

void	rotate2(unsigned short *data_buffer, int xsize, int ysize, int rot);
void	rotate_im_180(unsigned short *data_buffer, int xsize, int ysize);

int 	get_im_header(int which, char *header);
int 	ccddet_cleanup(int mode);
int 	ccddet_init();
int 	ccddet_startdc();
int 	ccddet_stopdc();
int 	ccddet_stopdcr();
int 	ccddet_stopdcw();

void	temperature_init();
int		ccd_start_hw_thread();
void	set_mserver_thread(HANDLE h);
void	suspend_mserver(char *who);
void	resume_mserver(char *who);
void	sync_timers();

/*
 *	Covers for NT functions under unix.
 */
#ifdef unix
int		timeGetTime();
int		WaitForSingleObject(HANDLE h, int timeout);
#endif /* unix */

#ifdef WINNT
void	_endthread(void);
#endif /* WINNT */
