#!../../bin/linux-x86_64/testioc

## You may have to change testioc to something else
## everywhere it appears in this file

< envPaths

cd ${TOP}

## Register all support components
dbLoadDatabase "dbd/testioc.dbd"
testioc_registerRecordDeviceDriver pdbbase

## Load record instances
dbLoadRecords("db/db.template","PREFIX=TEST")
#dbLoadRecords("db/libera_env.template" , "PORT=ENV, DEVICE=LIBERA01:ENV:")
#dbLoadRecords("db/libera_adc.template", "DEVICE=LIBERA01:ADC:, NELM=102")
#dbLoadTemplate("db/libera.substitutions")
dbLoadRecords("db/libera_test.db")
cd ${TOP}/iocBoot/${IOC}
iocInit

## Start any sequence programs
#seq sncxxx,"user=andrejHost"
