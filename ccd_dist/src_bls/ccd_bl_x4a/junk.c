	    case MDC_COM_BL_READY:
			strcpy(stat_scanner_op,"checking_beam_ready");
			send_status();
			ion_result = cm_get_ion(0);
			fprintf(stdout,"ccd_bl_x6a   : INFO:          at %s: bl_ready found ion reading: %.2f\n",
				ztime(), ion_result);
			if(ion_result >= MIN_ION_READ)
			{
				fprintf(stdout,"ccd_bl_x6a   : RSLT:          at %s: bl_ready says beam UP: %.2f\n",
				ztime());
				strcpy(local_reply_buf, "UP ");
			}
			else
			{
				fprintf(stdout,"ccd_bl_x6a   : RSLT:          at %s: bl_ready says beam DOWN: %.2f\n",
				ztime());
				strcpy(local_reply_buf, "DOWN ");
			}
			strcpy(stat_scanner_op,"idle");
			cm_putmotval();
			send_status();
			break;

