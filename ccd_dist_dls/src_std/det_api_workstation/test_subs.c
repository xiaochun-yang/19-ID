#include	"ext.h"

#define	MAX_EXCEPTIONS	10

int		read_serial_number(bn_arg, pserialnum)
int		bn_arg;
int		*pserialnum;
  {
  	int		dwPVAPI_result,other_result;
	WORD	offset;
	HANDLE	hEvent;

  	LPVOID	lpFrame;
	SETOP	soOpts;
	DWORD	dwSize;
	DWORD	dwStatFrameWidth = 256;
	DWORD	dwStatFrameHeight = 1;
	DWORD	dwStatFramePixelDepth = 16;
	DWORD	dwStatFrameTimeout = 4000;
	DWORD	dwStatFrameChannels = 1;
	BYTE	bn;
	PUSHORT	uSerialNum;
	USHORT	act_ser;
	int		except_ctr;
	int		get_adc_dump(BYTE bn, char *cres);

	bn = (BYTE) bn_arg;

	dwPVAPI_result = -100;
	for(except_ctr = 0; dwPVAPI_result != 0; except_ctr++)
	{
#ifdef WINNT
		__try
		{
#endif /* WINNT */
			Sleep(100);
			dwPVAPI_result = pvSendSerialCommandEx(bn, 'U', 0x5555, TRUE);
			Sleep(100);
#ifdef WINNT
		}
		__except(-1)
		{
#endif /* WINNT */
			if(except_ctr < MAX_EXCEPTIONS)
				continue;
			return(dwPVAPI_result);
#ifdef WINNT
		}
#endif /* WINNT */
	}

	offset = 0x40;
	pvInitCapture(bn);

	dwPVAPI_result = pvGetOptions(bn, &soOpts);

	if(dwPVAPI_result != 0)
	  {
		return(dwPVAPI_result);
	  }

	/*
	 *	Calculate the frame size in bytes.
	 */

	dwSize = dwStatFrameWidth * dwStatFrameHeight *
			(dwStatFramePixelDepth / 8) * dwStatFrameChannels;

	lpFrame = LocalAlloc(LMEM_FIXED, dwSize);

	if(!lpFrame)
	    return(ERROR_MEMORY_ALLOCATION_FAILED);

	dwPVAPI_result = pvSetOptions(bn,
					 dwStatFrameWidth,
					 dwStatFrameHeight,
					 dwStatFramePixelDepth,
					 dwStatFrameTimeout,
					 dwStatFrameChannels);

	if(dwPVAPI_result != 0)
	    return(dwPVAPI_result);

	Sleep(100);
	dwPVAPI_result = pvCaptureToBuffer(bn,
					   &hEvent,
					   PV_NO_EXPOSURE | PV_LINEINT,
					   1,
					   lpFrame,
					   0,
					   NULL);
	Sleep(100);
	if(dwPVAPI_result == 0)
	  {
	    dwPVAPI_result = pvSendSerialCommand(bn, '%', offset, TRUE); 
		Sleep(100);
	    if(dwPVAPI_result == 0)
	      {
	        if(WaitForSingleObject(hEvent, dwStatFrameTimeout) == WAIT_TIMEOUT)
			  {
				dwPVAPI_result = ERROR_CAPTURE_TIME_OUT;
				return(dwPVAPI_result);
			  }
	      }
	  }

	other_result = pvSetOptions(bn,
								soOpts.sFrameWidth,
								soOpts.sFrameHeight,
								soOpts.sPixelDepth,
							    soOpts.sTimeout,
							    soOpts.sChannels);
	Sleep(100);

	if(dwPVAPI_result == 0)
	  {
	    int		len;
	    char	*szsig, *szdate, *sztime, *szhead;

	    szsig = (char *) lpFrame;
	    len = strlen(szsig);
	    szdate = szsig + len + 1;
	    len = strlen(szdate);
	    sztime = szdate + len + 1;
	    len = strlen(sztime);
		szhead = sztime + len + 1;
	    uSerialNum = (PUSHORT) (sztime + len + 1);
		act_ser = *uSerialNum;
	  }
	LocalFree(lpFrame);
	*pserialnum = (int)act_ser;

	return(dwPVAPI_result);
  }

int reset_controller(bn)
int	bn;
{
	BYTE	bbn;

	bbn = (BYTE) bn;
	return(pvInitCapture(bbn));
}

int	test_communications(bn, padc, pser)
int	bn;
int	*padc, *pser;
{
	int		retval;

	if(-14 == (retval = reset_controller(bn)))
		return(retval);

	return(read_serial_number(bn, pser));

}

int	find_controller_type(serial)
int	serial;
{
	FILE	*fptype;
	char	line[132];
	int		fser;
	char	fkind[32];

	if(NULL == (fptype = fopen("controller_kind.txt","r")))
		return(-1);
	while(NULL != fgets(line,sizeof line, fptype))
	{
		if(line[0] == '#')
			continue;
		if(2 == sscanf(line,"%x %s",&fser, fkind))
		{
			if(serial == fser)
			{
				fclose(fptype);
				if(0 == strcmp(fkind,"master"))
					return(1);
				  else
					return(0);
			}
		}
	}
	fclose(fptype);
	return(-1);
}

int	find_controller_info(serial, pconk)
int	serial;
struct q_conkind	*pconk;
{
	FILE	*fptype;
	char	line[132];
	int		fser,i,ni,i0,i1,j0,j1,j2,j3,k0,k1,k2,k3;
	char	fkind[32];
	float	ftweak_m, ftweak_b;

	if(NULL == (fptype = fopen("controller_kind.txt","r")))
		return(-1);
	while(NULL != fgets(line,sizeof line, fptype))
	{
		if(line[0] == '#' || line[0] == '\n')
			continue;
		if(2 == sscanf(line,"%x %s",&fser, fkind))
		{
			if(serial == fser)
			{
				fclose(fptype);
				if(0 == strcmp(fkind,"master"))
					pconk->qc_type = 0;
				  else if(0 == strcmp(fkind,"slave"))
					pconk->qc_type = 1;
				      else if(0 == strcmp(fkind,"virtual"))
						  pconk->qc_type = 2;
				pconk->qc_serial = fser;
			}
			else
				continue;
		}
		pconk->qc_te_tweak_b = (float) 0.0;
		pconk->qc_te_tweak_m = (float) 0.0;
		pconk->qc_te_gain = 0;
		pconk->qc_te_offset = 0;
		for(i = 0; i < 4; i++)
		{
			pconk->qc_gain[i] = 0;
			pconk->qc_offset[i] = 0;
		}
		if(4 == (ni = sscanf(line,"%x %s %f %f",&fser, fkind, &ftweak_m, &ftweak_b)))
		{
			pconk->qc_te_tweak_m = ftweak_m;
			pconk->qc_te_tweak_b = ftweak_b;
		}
		if(6 == sscanf(line,"%x %s %f %f %d %d",
			&fser, fkind, &ftweak_m, &ftweak_b,&i0,&i1))
		{
			pconk->qc_te_gain = i0;
			pconk->qc_te_offset = i1;
		}
		if(14 == sscanf(line,"%x %s %f %f %d %d %d %d %d %d %d %d %d %d",
			&fser, fkind, &ftweak_m,&ftweak_b,&i0,&i1,&j0,&k0,&j1,&k1,&j2,&k2,&j3,&k3))
		{
			pconk->qc_gain[0] = k0;
			pconk->qc_offset[0] = j0;
			pconk->qc_gain[1] = k1;
			pconk->qc_offset[1] = j1;
			pconk->qc_gain[2] = k2;
			pconk->qc_offset[2] = j2;
			pconk->qc_gain[3] = k3;
			pconk->qc_offset[3] = j3;
		}
		return(pconk->qc_type);

	}
	fclose(fptype);
	return(-1);
}

int	set_analog_vals(struct q_conkind *pconk)
{
	int	n, i;

	for(n = 0; n < MAX_CONTROLLERS;pconk++, n++)
		if(qmod[n].q_def == 1 && qmod[n].q_type != 2)
		{
			fprintf(stdout,"Board %d (gain,offset): ",n);
			for(i = 0; i < 4; i++)
			{
				pvSetAnalogGainAndOffset((BYTE) n,
										 (BYTE) i,
										 (WORD) pconk->qc_gain[i],
										 (WORD) pconk->qc_offset[i]);
				fprintf(stdout,"(%4d,%4d) ",pconk->qc_gain[i],
											pconk->qc_offset[i]);
			}
			fprintf(stdout,"\n");
		}
	return(1);
}

int	ccd_powerupinit()
{
	int		n;
	int		send_serial(int	bn_arg, char c, int value);


	for(n = 0; n < n_ctrl; n++)
		if(qmod[n].q_def == 1 && qmod[n].q_type != 2)
		{
			fprintf(stdout,"Initializing board %d\n",n);
			send_serial(n, '7', 0x0000);	/* boot to page 7 */
			send_serial(n, 'U', 0x5555);	/* send until ack */
			send_serial(n, 'a', 0x044c);	/* 1100 pixels per flush row or ROD row*/
			send_serial(n, 'i', 0x0001);	/* 1 ROI, this is full size */
			send_serial(n, 'g', 0x0001);	/* delay after row shift before pix readout, set to min val of 1 */
			send_serial(n, 'h', 0x049f);	/* delay after end of exposure.  Set to this val to allow sw time to begin receipt of data */
			send_serial(n, 'f', 0x002d);
			send_serial(n, 'n', 0x0000);
			send_serial(n, 'D', 0x0008);
			send_serial(n, 'A', 0x0000);
			send_serial(n, 'B', 0x040f);
			send_serial(n, 'B', 0x0008);
			send_serial(n, 'B', 0x0000);
			send_serial(n, 'B', 0x0008);
			send_serial(n, 'e', 0x0001);
			send_serial(n, 'j', 0x0001);
			send_serial(n, 'c', 0x0000);
			send_serial(n, 'k', 0x0000);
			send_serial(n, 'l', 0x044c);
			send_serial(n, 'm', 0x0000);
			send_serial(n, 'G', 0x0001);	/* high gain */
			send_serial(n, 'H', 0x0001);	/* high bandwidth */
			/* this always must be last */
			send_serial(n, 's', 0x0000);	/* camera gated exposure mode */
		}
	return(1);
}

int	ccd_powerupinit_better(struct q_conkind *pc)
{
	int		adc,ser,n,res;
	char	libname[132];
	struct	q_conkind	*pconk;
	int	send_serial(int	bn_arg, char c, int value);


	for(n = 0, pconk = pc; n < MAX_CONTROLLERS;pconk++, n++)
		if(pconk->qc_type == 0)		/* master first */
		{
			sprintf(libname, "POWERUP_%4x", pconk->qc_serial);
			res = pvUseLibraryEx( (BYTE) n, libname, (BOOL) 1);
			fprintf(stdout,"Initializing serial %x with %s res: %d\n",
					pconk->qc_serial, libname,res);
			send_serial(n, '7', 0);
			Sleep(500);
			test_communications(n, &adc, &ser);
			Sleep(500);
		}

	for(n = 0, pconk = pc; n < MAX_CONTROLLERS;pconk++, n++)
		if(pconk->qc_type == 1)		/* do slaves last */
		{
			sprintf(libname, "POWERUP_%4x", pconk->qc_serial);
			res = pvUseLibraryEx( (BYTE) n, libname, (BOOL) 1);
			fprintf(stdout,"Initializing serial %x with %s res: %d\n",
					pconk->qc_serial, libname,res);
			send_serial(n, '7', 0);
			Sleep(500);
			test_communications(n, &adc, &ser);
			Sleep(500);
		}

	return(1);
}
int	ccd_powerupinit_noimprove(struct q_conkind *pc)
{
	int		adc,ser,n,res,mastern;
	char	libname[132],mlibname[132];
	struct	q_conkind	*pconk,*pconm;


	for(n = 0, pconk = pc; n < MAX_CONTROLLERS;pconk++, n++)
		if(pconk->qc_type == 0)		/* master first */
		{
			sprintf(mlibname, "POWERUP_%4x", pconk->qc_serial);
			pconm = pconk;
			mastern = n;
		}

	for(n = 0, pconk = pc; n < MAX_CONTROLLERS;pconk++, n++)
		if(pconk->qc_type == 1)		/* do slaves last */
		{
			res = pvUseLibraryEx( (BYTE) mastern, mlibname, (BOOL) 1);
			fprintf(stdout,"Initializing serial %x with %s res: %d\n",
					pconm->qc_serial, mlibname,res);
			Sleep(500);
			test_communications(mastern, &adc, &ser);
			Sleep(500);

			sprintf(libname, "POWERUP_%4x", pconk->qc_serial);
			res = pvUseLibraryEx( (BYTE) n, libname, (BOOL) 1);
			fprintf(stdout,"Initializing serial %x with %s res: %d\n",
					pconk->qc_serial, libname,res);
			Sleep(500);
			test_communications(n, &adc, &ser);
			Sleep(500);
		}

	return(1);
}
