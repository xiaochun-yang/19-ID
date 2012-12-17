/*
|| inquire - print formatted SCSI Inquiry (0x12) results
||
|| usage:  inquire  <device>  ...
||
|| Copyright 1989, by
||   Gene Dronek (Vulcan Laboratory) and
||   Rich Morin  (Canta Forda Computer Laboratory).
|| Freely redistributable as long as this notice is preserved.
*/
#ident "inquire.c: $Revision $"

#include <sys/types.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <dslib.h>


typedef	struct
{
	unchar	pqt:3;	/* peripheral qual type */
	unchar	pdt:5;	/* peripheral device type */
	unchar	rmb:1,	/* removable media bit */
		dtq:7;	/* device type qualifier */
	unchar	iso:2,	/* ISO version */
		ecma:3,	/* ECMA version */
		ansi:3;	/* ANSI version */
	unchar	aenc:1,	/* async event notification supported */
		trmiop:1,	/* device supports 'terminate io process msg */
		res0:2,	/* reserved */
		respfmt:3;	/* SCSI 1, CCS, SCSI 2 inq data format */
	unchar	ailen;	/* additional inquiry length */	
	unchar	res1;	/* reserved */
	unchar	res2;	/* reserved */
	unchar	reladr:1,	/* supports relative addressing (linked cmds) */
		wide32:1,	/* supports 32 bit wide SCSI bus */
		wide16:1,	/* supports 16 bit wide SCSI bus */
		synch:1,	/* supports synch mode */
		link:1,	/* supports linked commands */
		res3:1,	/* reserved */
		cmdq:1,	/* supports cmd queuing */
		softre:1;	/* supports soft reset */
	unchar	vid[8];	/* vendor ID */
	unchar	pid[16];	/* product ID */
	unchar	prl[4];	/* product revision level*/
	unchar	vendsp[20];	/* vendor specific; typically firmware info */
	unchar	res4[40];	/* reserved for scsi 3, etc. */
	/* more vendor specific information may follow */
} inqdata;


#define hex(x) "0123456789ABCDEF" [ (x) & 0xF ]

/* only looks OK if nperline a multiple of 4, but that's OK.
 * value of space must be 0 <= space <= 3;
 */
hprint(unsigned char *s, int n, int nperline, int space)
{
	int   i, x, startl;

	for(startl=i=0;i<n;i++)  {
		x = s[i];
		printf("%c%c", hex(x>>4), hex(x));
		if(space)
			printf("%.*s", ((i%4)==3)+space, "    ");
		if ( i%nperline == (nperline - 1) ) {
			putchar('\t');
			while(startl < i) {
				if(isprint(s[startl]))
					putchar(s[startl]);
				else
					putchar('.');
				startl++;
			}
			putchar('\n');
		}
	}
	if(space && (i%nperline))
		putchar('\n');
}

/* aenc, trmiop, reladr, wbus*, synch, linkq, softre are only valid if
 * if respfmt has the value 2 (or possibly larger values for future
 * versions of the SCSI standard). */

static char pdt_types[][16] = {
	"Disk", "Tape", "Printer", "Processor", "WORM", "CD-ROM",
	"Scanner", "Optical", "Jukebox", "Comm", "Unknown"
};
#define NPDT (sizeof pdt_types / sizeof pdt_types[0])

void
printinq(struct dsreq *dsp, inqdata *inq, int allinq)
{
	int neednl = 1;

	if(DATASENT(dsp) < 1) {
		printf("No inquiry data returned\n");
		return;
	}
	printf("%-10s", pdt_types[(inq->pdt<NPDT) ? inq->pdt : NPDT-1]);
	if (DATASENT(dsp) > 8)
		printf("%12.8s", inq->vid);
	if (DATASENT(dsp) > 16)
		printf("%.16s", inq->pid);
	if (DATASENT(dsp) > 32)
		printf("%.4s", inq->prl);
	printf("\n");
	if(DATASENT(dsp) > 1)
		printf("ANSI vers %d, ISO ver: %d, ECMA ver: %d; ",
			inq->ansi, inq->iso, inq->ecma);
	if(DATASENT(dsp) > 2) {
		unchar special = inq->vid[-1];
		if(inq->respfmt >= 2 || special) {
			if(inq->respfmt < 2)
				printf("\nResponse format type %d, but has "
				  "SCSI-2 capability bits set\n", inq->respfmt);
			
			printf("supports: ");
			if(inq->aenc)
				printf(" AENC");
			if(inq->trmiop)
				printf(" termiop");
			if(inq->reladr)
				printf(" reladdr");
			if(inq->wide32)
				printf(" 32bit");
			if(inq->wide16)
				printf(" 16bit");
			if(inq->synch)
				printf(" synch");
			if(inq->synch)
				printf(" linkedcmds");
			if(inq->cmdq)
				printf(" cmdqueing");
			if(inq->softre)
				printf(" softreset");
		}
		if(inq->respfmt < 2) {
			if(special)
				printf(".  ");
			printf("inquiry format is %s",
				inq->respfmt ? "SCSI 1" : "CCS");
		}
		if(allinq) {
			if (DATASENT(dsp) > offsetof(inqdata, vendsp)) {
				printf("\nvendor specific data:\n");
				/* bprint uses stderr, so can't use it */
				hprint(inq->vendsp, DATASENT(dsp)
					- offsetof(inqdata, vendsp), 16, 1);
				neednl = 0;
			}
			if (DATASENT(dsp) > offsetof(inqdata, res4)) {
				printf("reserved (for SCSI 3) data:\n");
				hprint(inq->res4, DATASENT(dsp)
					- offsetof(inqdata, res4), 16, 1);
			}
		}
	}
	if(neednl)
		putchar('\n');
	printf("Device is  ");
	/*	do test unit ready only if inquiry successful, since many
		devices, such as tapes, return inquiry info, even if
		not ready (i.e., no tape in a tape drive). */
	if(testunitready00(dsp) != 0)
		printf("%s\n",
			(RET(dsp)==DSRT_NOSEL) ? "not responding" : "not ready");
	else
		printf("ready");
	printf("\n");
}

/* inquiry cmd that does vital product data as spec'ed in SCSI2 */
vpinquiry12( struct dsreq *dsp, caddr_t data, long datalen, char vu,
  int page)
{
  fillg0cmd(dsp, (uchar_t *)CMDBUF(dsp), G0_INQU, 1, page, 0, B1(datalen),
	B1(vu<<6));
  filldsreq(dsp, (uchar_t *)data, datalen, DSRQ_READ|DSRQ_SENSE);
  return(doscsireq(getfd(dsp), dsp));
}

int
myinquiry12(struct dsreq *dsp, caddr_t data, long datalen, int vu, int neg)
{
  fillg0cmd(dsp, CMDBUF(dsp), G0_INQU, 0, 0, 0, B1(datalen), B1(vu<<6));
  filldsreq(dsp, data, datalen, DSRQ_READ|DSRQ_SENSE|neg);
  return(doscsireq(getfd(dsp), dsp));
}


gethaflags(struct dsreq *dsp)
{
	int flags;
	if(ioctl(getfd(dsp), DS_GET, &flags)) {
		perror("unable to get hostadapter status flags");
		return 1;
	}
	if(!flags)
		printf("no status bits set; adapater may not support reporting\n");
	else {
		printf("host adapter status: ");
		if(flags & DSG_CANTSYNC)
			printf(" cantsync,");
		if(flags & DSG_SYNCXFR)
			printf(" sync,");
		if(flags & DSG_TRIEDSYNC)
			printf(" sync negotiated,");
		if(flags & DSG_BADSYNC)
			printf(" badsync,");
		if(flags & DSG_NOADAPSYNC)
			printf(" sync disabled,");
		if(flags & DSG_WIDE)
			printf(" wide scsi,");
		if(flags & DSG_DISC)
			printf(" disconnect enabled,");
		if(flags & DSG_TAGQ)
			printf(" tagged queueing,");
		printf("\n");
	}
	return 0;
}

dsreset(struct dsreq *dsp)
{
  return ioctl(getfd(dsp), DS_RESET, dsp);
}

usage(char *prog)
{
    fprintf(stderr,
		"Usage: %s [-d (debug)] [-e (exclusive)] [-s (sync) | -a (async)]\n"
	    "\t[-l (long)] [-v (vital proddata)] [-r (reset)] scsidevice [...]\n",
		prog);
    exit(1);
}

main(int argc, char **argv)
{
	struct dsreq *dsp;
	char *fn;
	/* int because they must be word aligned. */
	int inqbuf[sizeof(inqdata)/sizeof(int)];
	int vpinqbuf[256/sizeof(int)];
	int errs = 0, c;
	int vital=0, doreset=0, exclusive=0, dosync=0, allinq=0, getflags=0;
	extern char *optarg;
	extern int optind, opterr;

	opterr = 0;	/* handle errors ourselves. */
	while ((c = getopt(argc, argv, "aserdvlg")) != -1)
	switch(c) {
	case 'g':
		getflags = 1;	/* get host adapter driver status bigs */
		break;
	case 'r':
		doreset = 1;	/* do a scsi bus reset */
		break;
	case 'e':
		exclusive = O_EXCL;
		break;
	case 'd':
		dsdebug++;	/* enable debug info */
		break;
	case 'l':
		allinq = 1;	/* show the vendor specific and scsi3 data also */
		break;
	case 'v':
		vital = 1;	/* set evpd bit for scsi 2 vital product data */
		break;
	case 's':
		dosync = DSRQ_SYNXFR;	/* attempt to negotiate sync scsi */
		break;
	case 'a':
		dosync = DSRQ_ASYNXFR;	/* attempt to negotiate async scsi */
		break;
	default:
		usage(argv[0]);
	}

	if(optind >= argc)	/* need at 1 arg */
		usage(argv[0]);

	while (optind < argc) {
		fn = argv[optind++];
		printf("%s:  ", fn);
		if((dsp = dsopen(fn, O_RDONLY|exclusive)) == NULL) {
			/* if open fails, try pre-pending /dev/scsi */
			char buf[256];
			strcpy(buf, "/dev/scsi/");
			if((strlen(buf) + strlen(fn)) < sizeof(buf)) {
				strcat(buf, fn);
				dsp = dsopen(buf, O_RDONLY|exclusive);
			}
			if(!dsp) {
				fflush(stdout);
				perror("cannot open");
				errs++;
				continue;
			}
		}

		if(doreset) {
			if(dsreset(dsp) != 0) {
				extern int errno;
				printf("%-10s reset failed: %s\n", "---",
					strerror(errno));
				errs++;
			}
			else
				printf("%-10s reset succeeded\n", "---");
		}

		if(getflags && gethaflags(dsp))
				errs++;

		if(myinquiry12(dsp, (char *)inqbuf, sizeof inqbuf, 0, dosync)) {
			printf("%-10s inquiry failure\n", "---");
			errs++;
		}
		else
			printinq(dsp, (inqdata *)inqbuf, allinq);

		if(vital) {
			unsigned char *vpinq;
			int i, serial = 0, asciidef = 0;
			if(vpinquiry12(dsp, (char *)vpinqbuf,
				sizeof(vpinqbuf)-1, 0, 0)) {
				printf("%-10s inquiry (vital data) failure\n", "---");
				errs++;
				continue;
			}
			if(DATASENT(dsp) <4) {
				printf("vital data inquiry OK, but says no"
					"pages supported (page 0)\n");
				continue;
			}
			vpinq = (unsigned char *)vpinqbuf;
			printf("Supported vital product pages: ");
			for(i = vpinq[3]+3; i>3; i--) {
				if(vpinq[i] == 0x80)
					serial = 1;
				if(vpinq[i] == 0x82)
					asciidef = 1;
				printf("%2x  ", vpinq[i]);
			}
			printf("\n");
			if(serial) {
			    if(vpinquiry12(dsp, (char *)vpinqbuf,
				    sizeof(vpinqbuf)-1, 0, 0x80) != 0) {
				    printf("%-10s inquiry (serial #) failure\n",
					"---");
				    errs++;
			    }
			    else if(DATASENT(dsp)>3) {
				    printf("Serial #: ");
				    fflush(stdout);
				    /* use write, because there may well be
				     *nulls; don't bother to strip them out */
				    write(1, vpinq+4, vpinq[3]);
				    printf("\n");
			    }
			}
			if(asciidef) {
			    if(vpinquiry12(dsp, (char *)vpinqbuf,
				sizeof(vpinqbuf)-1, 0, 0x82) != 0) {
				printf("%-10s inquiry (ascii definition) failure\n",
				    "---");
				errs++;
			    }
			    else if(DATASENT(dsp)>3) {
				printf("Ascii definition: ");
				fflush(stdout);
				/* use write, because there may well be
				 *nulls; don't bother to strip them out */
				write(1, vpinq+4, vpinq[3]);
				printf("\n");
			    }
			}
			/* could dump other pages (1,7f) here, perhaps */
		}
		dsclose(dsp);
	}
	return(errs);
}
