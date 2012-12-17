#include	"ext.h"

/*
 *	This routine handles most of the duties associated with parsing
 *	the input buffer.
 *
 *	The command and modifier enums are found in defs.h
 *	The command and modifier list using these enums are found below.
 *
 *	Command format:
 *
 *	command
 *	modifiers
 *	end_of_det
 *
 *	command:
 *		Always a one word line selected from command_list[]
 *
 *	modifiers:
 *		These have the following syntax, selected from modifier_list[]:
 *
 */

/*
 *	Commands.
 */

struct input_pair command_list[] = 
{
	COPY_CMD, 		"copy",
	XFORM_CMD,		"xform",
	RESET_CMD,		"reset",
	SETPARAM_CMD,		"setparam",
	GETPARAM_CMD,		"getparam",
	STATUS_CMD,		"status",
	EXIT_CMD,		"exit",
	-1,			NULL,
};

struct input_pair modifier_list[] =
{
	END_OF_DET_MOD,		"end_of_det",
	INFILE_MOD,		"infile",
	OUTFILE_MOD,		"outfile",
	RAWFILE_MOD,		"rawfile",
	KIND_MOD,		"kind",
	SAVE_RAW_MOD,		"save_raw",
	ROW_BIN_MOD,		"row_bin",
	COL_BIN_MOD,		"col_bin",
	ROW_XFER_MOD,		"row_xfer",
	COL_XFER_MOD,		"col_xfer",
	HEADER_SIZE_MOD,	"header_size",
	ROW_MM_MOD,		"row_mm",
	COL_MM_MOD,		"col_mm",
	DIST_MM_MOD,		"dist_mm",
	TWO_THETA_MOD,		"two_theta",
	REPLY_MOD,		"reply",
	ALL_MOD,		"all",
	COMPRESS_MOD,		"compress",
	DZRATIO_MOD,		"dzratio",
	OUTFILE_TYPE_MOD,	"outfile_type",
	DETECTOR_SN_MOD,	"detector_sn",
	STRIP_AVE_MOD,		"strip_ave",
	MERGE_HEADER_BYTES_MOD,	"merge_header_bytes",
	-1,			NULL,
};

int 	get_line(char *buf,int start,int end)
{
	int 	i;

	for(i = start; i < end; i++)
		if(buf[i] == '\n')
			break;
	if(i >= end)
		return(-1);
	return(i + 1);
}

/*
 *	bad_command(msg)  - reply to caller concerning a bad command,
 *			    then flush out any remaining data which might
 *			    be present in the socket.
 */

bad_command(char *msg)
{
	inbufind = 0;
	processing_command = SCANNING_FOR_COMMAND;

	while(0 < read_port_raw(command_fd,inbuf,INBUFSIZE));
	sleep(1);
	while(0 < read_port_raw(command_fd,inbuf,INBUFSIZE));

	sprintf(replybuf,"ERROR\n%send_of_det\n",msg);
	fprintf(stderr,"ccd_xform_api: bad_command: Sending: %s",replybuf);
	if(-1 == rep_write(command_fd,replybuf,strlen(replybuf)))
	{
		notify_server_eof(command_fd);
		return;
	}
}

/*
 *	process_buffer  -  take input in the buffer and parse.
 */

int	process_buffer()
{
	int	i,j;
	int	look_for_header;
	int	cind,eind,mod_number;
	char	hold[256],errorbuf[512];
	char	str1[256],str2[256];
	char	*cpx;

	cind = 0;
	look_for_header = 0;

	while(1)
	{
		switch(processing_command)
		{
		case SCANNING_FOR_COMMAND:
			if(-1 == (eind = get_line(inbuf,cind,inbufind)))
			{
				for(i = 0, j = cind; j < inbufind; i++, j++)
					inbuf[i] = inbuf[j];
				inbufind -= cind;
				break;
			}
			for(i = cind, j = 0; i < eind - 1; i++,j++)
				hold[j] = inbuf[i];
			hold[j] = '\0';

			for(i = 0; command_list[i].cmd_string != NULL; i++)
				if(0 == strcmp(command_list[i].cmd_string, hold))
					break;

			if(command_list[i].cmd_tag == -1)
			{
				sprintf(errorbuf,"unknown command: %s\n",hold);
				bad_command(errorbuf);
				return(0);
			}
			command_number = command_list[i].cmd_tag;

			processing_command = SCANNING_FOR_MODIFIERS;

			switch(command_number)
			{
			case GETPARAM_CMD:
			case STATUS_CMD:
				replybuf[0] = '\0';
				rbufind = 0;
				break;
			default:
				break;
			}
			cind = eind;
			break;

		case SCANNING_FOR_MODIFIERS:
			if(-1 == (eind = get_line(inbuf, cind, inbufind)))
			{
				for(i = 0, j = cind; j < inbufind; i++, j++)
				inbuf[i] = inbuf[j];
				inbufind -= cind;
				break;
			}
			for(i = cind, j = 0; i < eind - 1; i++,j++)
				hold[j] = inbuf[i];
			hold[j] = '\0';
			i = sscanf(hold, "%s %s", str1, str2);
			if(i == 0)
			{
				cind = eind;
				continue;
			}
			if(i == 1)
				str2[0] = '\0';

			cind = eind;

			for(i = 0; modifier_list[i].cmd_string != NULL; i++)
				if(0 == strcmp(modifier_list[i].cmd_string, str1))
			break;

			mod_number = modifier_list[i].cmd_tag;
			if(mod_number == -1)
			{
				sprintf(errorbuf,"unknown modifier: %s\n",str1);
				bad_command(errorbuf);
				return(0);
			}
			if(command_number == GETPARAM_CMD)
			{
				getparam_action(mod_number);
				if(mod_number != END_OF_DET_MOD)
					break;
			}
			switch(mod_number)
			{
			case END_OF_DET_MOD:
				for(i = 0, j = cind; j < inbufind; i++, j++)
					inbuf[i] = inbuf[j];
				inbufind -= cind;
				inbuf[inbufind] = '\0';
				cind = 0;
				merge_header_ind = 0;
				if(merge_header_bytes > 0)
				{
					processing_command = SCANNING_FOR_MERGE_HEADER;
				}
				else
				{
					processing_command = SCANNING_FOR_COMMAND;
					return(1);
				}
				break;
			default:
				setparam_action(mod_number, str2);
				break;
			}

			break;
		case SCANNING_FOR_MERGE_HEADER:
			for(i = 0, j = merge_header_ind; i < inbufind && j < merge_header_bytes; i++, j++)
				merge_header[j] = inbuf[i];
			merge_header_ind += i;
			cind = i;

			if(merge_header_ind >= input_header_size)
			{
				for(j = 0; i < inbufind; i++, j++)
					inbuf[j] = inbuf[i];
				inbufind -= cind;
				inbuf[inbufind] = '\0';
				cind = 0;
				processing_command = SCANNING_FOR_COMMAND;
				return(1);
			}

			inbufind = 0;
			inbuf[inbufind] = '\0';
			return(0);

			break;
		}
	}
}
