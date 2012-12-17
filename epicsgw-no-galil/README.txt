This is the new epicsgw.

The goal is to make it easy to expand, to add new device, like new motor
types.

===================================================
MAP localName to PV names for motor:
===================================================
pattern 1:  Append some field name to the localName.
Like in APS motor, if localName is "D234F344:STPMTR1",
we know the fields will be:

set point:    localName + ".VAL"
feedback:     localName + ".RBV"
done moving:  localName + ".DMOV"
stop:         localName + ".STOP"

pattern 2:  fixed pattern to map, but not just append at the end.
Like in CLS Motor, if the localName for motor sample_x is
"SMTR99993I1012:mm".

We parse it into clsName "SMTR99993I1012" and units: "mm", so we can 
generate the PV names from them:

set point:   $(clsName):$(units)
feedback:    $(clsName):$(units):fbk
status:      $(clsName):status
stop:        $(clsName):stop

pattern 3: In case there is no pattern between localName and PV names, you can
use config file to explicitly specify the mapping.

This can be used together with pattern 1 and 2 if most of PV names can be
generated from the localName.

ASPMotor is implemented as an example of this pattern.  The localName is
required to put as "$(DEVICE):${MRN)"

For example, if localName is "SR03BM01SLM01:XI_MTR",
the set point PV will be "SR03BM01SLM01:XI_MTR_SP",

If the set point PV is not that, you can define following line in the config
file,
SR03BM01SLM01:XI_MTR_SP=SET_POINT_PV_NAME

Then the gateway will use "SET_POINT_PV_NAME" as the set point PV name.

If the gateway cannot find that line, it will just use
"SR03BM01SLM01:XI_MTR_SP" as the PV name.

=============================
Operation "dumpDevice"
You can use operation dumpDevice to inspect the device information on the
gateway.

"dumpDevice sample_x" will display the status and PV mappings for device
"samplex", which can be a motor, or a string, as long as it is a device on the
gateway.

"dumpDevice sample_x 0" will display detailed information about its PV[0].



============================

dcs/dcss/linux/dumpxxxxxx
===================================
epics_gateway
3
blctl15.slac.stanford.edu 2

epics_string1
13
epics_gateway SRF1:CAV1:VACMLOG
0 0 0 0 0
0 0 0 0 0
dummy init value

stepper_motor1
2
epics_gateway SRF1:CAV1TUNR:STEP:MOTOR
0 1 1 1 1
0 0 0 0 0
0
-1.176780 100.000000 -100.000000 1 1 1 0 mm
0

stepper_motor4
1
epics_gateway SRF1:CAV4TUNR:STEP:MOTOR
0 1 1 1 1
0 0 0 0 0
0
4.102114 10.000000 -10.000000 17500.000000 5000 100 0 0 0 0 0 0 0 mm

sample_x
1
epics_gateway SMTR99993I1012:mm
0 1 1 1 1
0 1 1 1 1
0
0.000000 500.000000 -500.000000 6768.189510 1000 5000 10 1 1 0 1 0 0 mm

getEPICSPV
11
epics_gateway getPV
1 1 1 1 1
0 0 0 0 0

putEPICSPV
11
epics_gateway putPV
1 1 1 1 1
0 0 0 0 0

forceReadString
11
epics_gateway forceReadString
1 1 1 1 1
0 0 0 0 0
==============================================

config file
dcs/dcsconfig/data/BL1-5.config
===================================
########## same name as in the database file
epicsgw.name=epics_gateway

#### update rate is ticks; 1 tick is about 0.1 seconds
#### 0 means immediately update up on receiving epics message
#epicsgw.default.UpdateRate=0
#class wide rate
#epicsgw.String.UpdateRate=3
#epicsgw.Motor.UpdateRate=1
#epicsgw.Shutter.UpdateRate=1
# object wide rate
#epicsgw.epics_string1.UpdateRate=0
#epicsgw.epics_motor1.UpdateRate=10

epicsgw.defaultMotorType=CLSMotor
#epicsgw.defaultMotorType=APSMotor
#epicsgw.defaultMotorType=stepperMotor
SRF1:CAV1TUNR:STEP:MOTOR=stepperMotor
SMTR99993I1012:mm=CLSMotor


3)command to start the gateway
./epicsgw BL1-5
