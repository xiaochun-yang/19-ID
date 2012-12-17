#include	"ext.h"

/*
 *	Module to handle the execution of commands.
 */

static char reply_term[] = REPLY_TERM_STRING;

void	reply_cmd(char *reply, char *info)
{
	int 	len;

	if(standalone == 1)
	{
		len = strlen(reply);
		write(2,reply,len);
		if(info != NULL)
		{
			len = strlen(info);
			write(2,info,len);
		}
		return;
	}

	if(reply_to_sender == 0)
		return;

	len = strlen(reply);
	if(-1 == rep_write(command_fd,reply,len))
	{
		notify_server_eof(command_fd);
		return;
	}
	if(info != NULL)
	{
		len = strlen(info);
		if(-1 == rep_write(command_fd,info,len))
		{
			notify_server_eof(command_fd);
			return;
		}
	}
	len = strlen(reply_term);
	if(-1 == rep_write(command_fd,reply_term,len))
	{
		notify_server_eof(command_fd);
		return;
	}
}

/*
 *	Execute command "command_number" with parameters as set in the globals.
 */

int	execute_command()
{
	int 	retval,res,use_sum,i,j;
	char	field[132],value[132];
	FILE	*fpjunk;

	retval = 0;

	switch(command_number)
	  {
	    /*
	     *	XFORM and COPY use the same basic code.
	     */

	    case XFORM_CMD:
	    case COPY_CMD:
		switch(image_kind)
		  {
		    case KIND_DARK_0:
		    case KIND_DARK_1:
		    case KIND_DARK_2:
		    case KIND_DARK_3:
			dkc_data_size[image_kind - KIND_DARK_0] = ccd_row_xfersize * ccd_col_xfersize;
			dkc_header_size[image_kind - KIND_DARK_0] = input_header_size;
			dkc_seen[image_kind - KIND_DARK_0] = 1;

			if(save_raw_images)
			{
				receive_data_raw(image_kind);
				save_image(image_kind,0,compress_mode);
			}
			reply_cmd(REPLY_OK_STRING,NULL);
			break;

		    case KIND_RAW_0:
		    case KIND_RAW_1:
			raw_data_size[image_kind - KIND_RAW_0] = ccd_row_xfersize * ccd_col_xfersize;
			raw_header_size[image_kind - KIND_RAW_0] = input_header_size;

			raw_seen[image_kind - KIND_RAW_0] = 1;
			if(save_raw_images)
			{
				receive_data_raw(image_kind);
				save_image(image_kind,0,compress_mode);
			}

			if(command_number == XFORM_CMD && image_kind == KIND_RAW_1)
			{

				receive_data_cor(KIND_RAW_1);

				if(outfile_type < OUTFILE_CBF)
					save_image_with_convert_smv(compress_mode);
				    else
					save_image_with_convert_cbf(compress_mode);
			}
			reply_cmd(REPLY_OK_STRING,NULL);
			break;
		  }
		break;
	    case RESET_CMD:
		initial_defaults();
        	ccd_bufind = 0;
        	raw_header_size[0] = 0;
        	raw_header_size[1] = 0;
        	ccd_data_valid[0] = 0;
        	ccd_data_valid[1] = 0;
		reply_cmd(REPLY_OK_STRING,NULL);
		break;
	    case SETPARAM_CMD:
		reply_cmd(REPLY_OK_STRING,NULL);
		break;
	    case GETPARAM_CMD:
		reply_cmd(REPLY_OK_STRING,replybuf);
		break;
	    case STATUS_CMD:
		get_xform_status(replybuf);
		reply_cmd(REPLY_OK_STRING,replybuf);
		break;
	    case EXIT_CMD:
		retval = 1;
		break;
	  }
	return(retval);
}

/*
 *	Turn an integer into xxx.  Used in image numbers.
 */

util_3digit(s1,val)
char	*s1;
int	val;
{
	int 	i,j;

	i = val;
	j = i / 100;
	*s1++ = (char ) ('0' + j);
	i = i - 100 * j;
	j = i / 10;
	*s1++ = (char ) ('0' + j);
	i = i - 10 * j;
	*s1++ = (char ) ('0' + i);
	*s1++ = '\0';
}
