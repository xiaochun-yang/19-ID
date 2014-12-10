USR_CFLAGS += -DEXCLUDE_CAMAC -DEXCLUDE_DXP4C -DEXCLUDE_DXP4C2X -DEXCLUDE_XMAP -DEXCLUDE_PLX -DLINUX
USR_CFLAGS += -DEXCLUDE_UDXP -DEXCLUDE_UDXPS -DEXCLUDE_DGF200 -DEXCLUDE_POLARIS  -DEXCLUDE_MERCURY
USR_CFLAGS += -DEXCLUDE_SERIAL -DEXCLUDE_ARCNET -DEXCLUDE_VEGA -DEXCLUDE_EPP

#handel_SRCS += x10p.c x10p_psl.c md_linux.c epplib.c usblib_linux.c
handel_SRCS += x10p.c x10p_psl.c md_linux.c usblib_linux.c
handel_SRCS += xerxes.c
handel_SRCS += xerxes_log.c
handel_SRCS += md_log.c
handel_SRCS += handel.c
handel_SRCS += fdd.c
handel_SRCS += psl.c
handel_SRCS += handel_dbg.c
handel_SRCS += handel_detchan.c
handel_SRCS += handel_dyn_default.c
handel_SRCS += handel_dyn_detector.c
handel_SRCS += handel_dyn_firmware.c
handel_SRCS += handel_dyn_module.c
handel_SRCS += handel_file.c
handel_SRCS += handel_log.c
handel_SRCS += handel_run_control.c
handel_SRCS += handel_run_params.c
handel_SRCS += handel_sort.c
handel_SRCS += handel_system.c
handel_SRCS += handel_xerxes.c
handel_SRCS += xia_file.c
handel_SRCS += xia_ll.c
handel_SRCS += xia_mem.c
handel_SRCS += xia_mem_point.c

#handel_OBJS += x10p.o x10p_psl.o md_linux.o epplib.o usblib_linux.o
handel_OBJS += x10p.o x10p_psl.o md_linux.o usblib_linux.o
handel_OBJS += xerxes.o
handel_OBJS += xerxes_log.o
handel_OBJS += md_log.o
handel_OBJS += handel.o
handel_OBJS += fdd.o
handel_OBJS += psl.o
handel_OBJS += handel_dbg.o
handel_OBJS += handel_detchan.o
handel_OBJS += handel_dyn_default.o
handel_OBJS += handel_dyn_detector.o
handel_OBJS += handel_dyn_firmware.o
handel_OBJS += handel_dyn_module.o
handel_OBJS += handel_file.o
handel_OBJS += handel_log.o
handel_OBJS += handel_run_control.o
handel_OBJS += handel_run_params.o
handel_OBJS += handel_sort.o
handel_OBJS += handel_system.o
handel_OBJS += handel_xerxes.o
handel_OBJS += xia_file.o
handel_OBJS += xia_ll.o
handel_OBJS += xia_mem.o
handel_OBJS += xia_mem_point.o

all:
	-mkdir linux
	gcc $(USR_CFLAGS) $(USR_CFLAGS_x86_64) -c -fPIC $(handel_SRCS) $(handel_SRCS_x86_64)  
	ar rcs linux/libhandel.a $(handel_OBJS) $(handel_OBJS_x84_64) 

clean:
	-rm  *.o

uninstall:
	-rm -r  linux


