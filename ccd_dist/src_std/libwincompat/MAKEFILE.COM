$!
$! Make the auxiallary library for VMS systems.
$!
$ cc trnlog.c
$ cc timer.c
$ cc mdcclock.c
$ cc swapfcns.c
$ cc fio_for_vms.c
$ for fileops.for
$ lib/create [--.lib]auxlib.olb
$ lib/replace [--.lib]auxlib.olb trnlog.obj,timer.obj,mdcclock.obj,swapfcns.obj,-
	fio_for_vms.obj,fileops.obj
$ purge [--.lib]auxlib.olb
