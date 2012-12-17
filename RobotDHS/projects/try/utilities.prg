#include "robotdefs.inc"

''globals
''===========================================================
''left arm or right arm system

Global Preserve Boolean g_LeftarmSystem

Global Preserve Boolean g_IncludeStrip
''=========================================
''we support more generic orientation now.
''so these should be configured by SITE,
''not initialized by left or right arm anymore.
''these should be 0 or 90 or -90 or 180.
Global Preserve Real g_Perfect_Cradle_Angle
Global Preserve Real g_Perfect_U4Holder
Global Preserve Real g_Perfect_DownStream_Angle

''for right arm system, normally 90, 180, -90
''for left arm system normally, -90, 0, 90
Global Preserve Real g_Perfect_LeftCassette_Angle
Global Preserve Real g_Perfect_MiddleCassette_Angle
Global Preserve Real g_Perfect_RightCassette_Angle

''=================================================
''g_Jump_LimZ_LN2 should be the Limz to keep dumbell and cavity in LN2 but clear all obstacles
''g_Jump_LimZ_Magnet should be the same or lower then g_Jump_LimZ_LN2.
''need only clear the dumbell cradle.
Global Preserve Real g_Jump_LimZ_LN2
Global Preserve Real g_Jump_LimZ_Magnet

''==============================================================
''will hold the perfect value for current cassette in calibration
Global Real g_Perfect_Cassette_Angle

''===================================================================
''g_MagnetTransportAngle: transport angle in robot coordinates.
''In ideal world, this should by 90 degree from the X axis of robot.
''This variable is set by PickerTouchSeat
''In angle tranform, If current U == g_U4MagnetHolder,
''the dumb bell is in direction of g_MagnetTransportAngle in robot coordinate system
Global Preserve Real g_MagnetTransportAngle ''angle of dumbbell in post
Global Preserve Real g_U4MagnetHolder       ''angle of U when dumbbell in post

''theory value should be (10-9.44)/2 = 0.28
Global Preserve Real g_PickerWallToHead
Global Preserve Real g_PlacerWallToHead

''========================================================================
''for log file names
Global Preserve Integer g_FCntPost
Global Preserve Integer g_FCntPicker
Global Preserve Integer g_FCntPlacer
Global Preserve Integer g_FCntToolRough
Global Preserve Integer g_FCntToolFine
Global Preserve Integer g_FCntCassette
Global Preserve Integer g_FCntGonio
Global Preserve Integer g_FCntBeamTool
Global Preserve Integer g_FCntStrip
''==========================================================
''for toolset calibration
Global Preserve Real g_Picker_X
Global Preserve Real g_Picker_Y
Global Preserve Real g_Placer_X
Global Preserve Real g_Placer_Y
Global Preserve Real g_ToolSet_A
Global Preserve Real g_ToolSet_B
Global Preserve Real g_ToolSet_C
Global Preserve Real g_ToolSet_Theta

''the sliding freedom for dumbbell in cradle
''It is used to correct picker and placer calibration
Global Preserve Real g_Dumbbell_Free_Y

''=========================================================
''main function cannot have parameters so
Global Preserve Boolean g_IncludeFindMagnet
Global Preserve Boolean g_Quick
Global Preserve Boolean g_AtLeastOnce

''==============================================================
''time stamp for calibrations
Global Preserve String g_TS_Toolset$
Global Preserve String g_TS_Left_Cassette$
Global Preserve String g_TS_Middle_Cassette$
Global Preserve String g_TS_Right_Cassette$
Global Preserve String g_TS_Goniometer$

''==========================================================================
''scale factor for port probing: torque to millimeter
Global Preserve Double g_TQScale_Picker
Global Preserve Double g_TQScale_Placer

''================================================================
''if true, any move will be along X,Y Axis, no arbitory direction move.
Global Boolean g_OnlyAlongAxis

''============================================================
''for communication with SPELCOM active X clients
Global String g_RunArgs$
Global String g_RunResult$

''set by SPELCOM (C++), read by script
Global Boolean g_FlagAbort

''set by script, read by SPELCOM (C++)
Global Long g_RobotStatus

''tell lowlevel function to send +g_Steps to progress bar
''current step is g_CurrentSteps, you can increase by g_Steps in your function
Global Integer g_CurrentSteps
Global Integer g_Steps

''============================================================
''for recover action after abort:
''must make sure that it can jump P6 or jump P1
Global Boolean g_HoldMagnet
Global Boolean g_SafeToGoHome

''============================================================
''global constants for force sensor related functions
''============================================================
Boolean g_ConstantInited    ''to prevent repeated call for init constants

''====================================================
'' arm orientation
Global Integer g_ArmOrientation
''If not match with g_LeftarmSystem, nothing will run

''============================
''constants for force reading
Global Integer g_ReadForceTimes
Global Real g_WaitTimeBeforeRead
Global Real g_WaitTimeBetweenRead
Global Real g_rawForces(6, FORCE_READ_TIMES)

''============================
''Touching, Moving with force trigger
'These values are obtained by experiment with robot and force sensor'
'Big threshold used in any move intended without force trigger'
Global Real g_MaxFX
Global Real g_MaxFY
Global Real g_MaxFZ
Global Real g_MaxTX
Global Real g_MaxTY
Global Real g_MaxTZ

''Threshold used in step-scan
Global Real g_ThresholdFX
Global Real g_ThresholdFY
Global Real g_ThresholdFZ
Global Real g_ThresholdTX
Global Real g_ThresholdTY
Global Real g_ThresholdTZ

''Bigger threshold for long distance moving,
'' the noise is about 0.2, so it has to be bigger
''they are intended to be used in safe move or safe go
Global Real g_BigThresholdFX
Global Real g_BigThresholdFY
Global Real g_BigThresholdFZ
Global Real g_BigThresholdTX
Global Real g_BigThresholdTY
Global Real g_BigThresholdTZ

''any force or torque will be considered as zero if below following values
''and ignored in post calibration
Global Real g_MinFX
Global Real g_MinFY
Global Real g_MinFZ
Global Real g_MinTX
Global Real g_MinTY
Global Real g_MinTZ

''in ForceTouch
''we move with force triger using threshold
''then move back until the force reduced to Min
Global Real g_XYTouchThreshold
Global Real g_ZTouchThreshold
Global Real g_UTouchThreshold
Global Real g_XYTouchMin
Global Real g_ZTouchMin
Global Real g_UTouchMin
''init touch step size, at the end step size reduced to init/10
Global Real g_XYTouchInitStepSize
Global Real g_ZTouchInitStepSize
Global Real g_UTouchInitStepSize

''after scan steps, how many binary crossing should try if fineTune
''It will cut step size in 1/(2**n)
Global Integer g_BinaryCrossTimes

''Max range we will scan in Cut Middle
''try to find the min force by moving within this range.
Global Real g_MaxRangeXY
Global Real g_MaxRangeZ
Global Real g_MaxRangeU
Global Integer g_XYNumSteps
Global Integer g_ZNumSteps
Global Integer g_UNumSteps

''ratio from experiment to check whether force sensor is working properly.
''This is the data about how much force should change when moves 1 mm 
Global Real g_RateFZ
Global Real g_RateTX
Global Real g_RateTY
Global Real g_RateTZ

''check magnet
Global Real g_FCheckMagnet

''flag for cut middle failed
Global Integer g_CutMiddleFailed

''global always reflect current situation.
Global Real g_CurrentP(4)
''Global Real g_CurrentF(6)  ''to use this one, need to make sure index is positive
Global Real g_CurrentSingleF

''for IOMonitor: VB program use this counter to make sure IOMonitor is running
Global Preserve Long g_IOMCounter
Global Preserve Long g_LidOpened

''temperarily for LN2 level
Global Preserve Boolean g_LN2LevelHigh

''===============================================
''MODULE varible
''===============================================
'' any tmp_ prefix means this varible cannot cross function call
''they can be used by any function.
Real tmp_Real
Integer tmp_PIndex

''==========================================================
'' LOCAL varibles: because it crashes system when there are
'' a lot of local variables, many local variables are moved here
''=========================================================
''read force
''ReadForces
Integer RFSRepeatIndex
Real RFSMaxValue(6)
Real RFSMinValue(6)
Real RFSCurrentValue(6)
Integer RFSForceIndex
Integer RFSNumValidSamples
'cannot pass element of array by ref'
Real minV
Real maxV
Real RFCurrentV

''NarrowMinMax
Integer bin(10) ' 10 bins to cut from min to max'
Real binLength
Integer binIndex
Integer numValidSamples
Integer numDiscard
Integer numSamplesToCut
Integer numSamplesLeft
Integer numDiscard
Integer NMMRepeatIndex
Real NMMCurrentValue

''AverageForce
Integer AFRepeatIndex
Integer AFNumValidSamples
Real currentValue

''CalculateStepSize
Real CSSAngleInRad
Real CSSDumbBellAngle
Real CSSForceName

''binary cross
Real BCStepSize(4)
Real BCPerfectPosition(4)
Integer BCStepIndex
Real BCCurrentPosition(4)
Real BCCurrentForce
Real BCTempDF
Real BCBestPosition(4)
Real BCBestDF

''force scan
Real FSOldPosition(4)
Real FSForce
Real FSPrePosition(4)
Real FSPreForce
Real FSDesiredPosition(4)
Real FSStepSize(4)
Real FSHypStepSize
Integer FSStepIndex

''ForceCross
Real FCDestPosition(4)

''ForceTouch
Real FTHInitP(4)
Real FTHDestP(4)
Real FTHMidP(4)     ''rough scan stopped position and fine tune starting position
Real FTHThreshold
Real FTHFineTuneDistance
Integer FTHNumSteps
Integer FTHRetryTimes

''TongMove
Real TMChange(4)   ''to store where to move according to the direction.

''CutMiddle
Real CMInitP(4)
Real CMPlusP(4)
Real CMMinusP(4)
Real CMFinalP(4)
Real CMInitForce
Real CMPlusForce
Real CMMinusForce
Real CMThreshold
Real CMScanRange
Integer CMNumSteps
Real CMMinForce
''for progress bar
Integer CMStepStart
Integer CMStepTotal



''LidMonitor
Long IOPreInputValue
Long IOCurInputValue
Long IOPreOutputValue
Long IOCurOutputValue

''SavePointHistory
String SPHFileName$

''FromHomeToTakeMagnet
Integer FHTTMWait

''isCloseToPoint
Real ICTPDX
Real ICTPDY
Real ICTPDZ
Real ICTPDU

''ForceResetAndCheck
Real FCheck(6)
Integer FCKIndex
Boolean FCKAgain

''ForceChangeCheck
Real FCCDF
Real FCCRate
Real FCCStandord

''CheckMagnet
Real CKMForce
Integer CKMGripperClosed

Function InitForceConstants

    If g_ConstantInited Then Exit Function

#ifndef MIXED_ARM_ORIENTAION
	''check arm orientation
	P30 = P*
	g_ArmOrientation = POrient(P30)

	''init perfect values for left or right arm systems
	If g_LeftarmSystem Then
		If g_ArmOrientation <> Lefty Then
			Print "SEVERE arm orientation conflict"
			Quit All
		EndIf
		''these are now SITE configurable
		''g_Perfect_Cradle_Angle = -90
		''g_Perfect_U4Holder = -90
		''g_Perfect_DownStream_Angle = 0
	Else
		If g_ArmOrientation = Lefty Then
			Print "SEVERE arm orientation conflict"
			Quit All
		EndIf
		''these are now SITE configurable
		''g_Perfect_Cradle_Angle = 90
		''g_Perfect_U4Holder = 90
		''g_Perfect_DownStream_Angle = 180
	EndIf
#endif

	''If (g_Perfect_LeftCassette_Angle = 0) And (g_Perfect_MiddleCassette_Angle = 0) And (g_Perfect_RightCassette_Angle = 0) Then
	''	If g_LeftarmSystem Then
	''		g_Perfect_LeftCassette_Angle = -90
	''		g_Perfect_MiddleCassette_Angle = 0
	''		g_Perfect_RightCassette_Angle = 90
	''	Else
	''		g_Perfect_LeftCassette_Angle = 90
	''		g_Perfect_MiddleCassette_Angle = 180
	''		g_Perfect_RightCassette_Angle = -90
	''	EndIf
	''EndIf

    Print "InitForceConstants"
    If g_MagnetTransportAngle = 0 Then
        g_MagnetTransportAngle = g_Perfect_Cradle_Angle
    EndIf

    g_MaxFX = 4
    g_MaxFY = 4
    g_MaxFZ = 8
    g_MaxTX = 4
    g_MaxTY = 4
    g_MaxTZ = 4

    ''REMEMBER to change scan ranges and steps if you change threshold
    ''these data are from experiement.
    g_ThresholdFX = 0.2 'Lbs'
    g_ThresholdFY = 0.2
    g_ThresholdFZ = 0.5
    g_ThresholdTX = 0.5   ''0.2   'Lbs-in'
    g_ThresholdTY = 0.2
    g_ThresholdTZ = 0.2
    
    ''These threshold can be used to move with force trigger.
    ''The noise is about 0.2-0.4, so they must be greater than that.
    g_BigThresholdFX = 5
    g_BigThresholdFY = 5
    g_BigThresholdFZ = 15           '' 0.1mm off is about 10
    g_BigThresholdTX = 5
    g_BigThresholdTY = 5
    g_BigThresholdTZ = 1.5

    g_MinFX = 0.02
    g_MinFY = 0.02
    g_MinFZ = 0.02
    g_MinTX = 0.1
    g_MinTY = 0.05
    g_MinTZ = 0.05

    ''g_XYTouchThreshold = 1.5
    g_XYTouchThreshold = 1
    g_ZTouchThreshold = 4
    g_UTouchThreshold = 0.1
    
    g_XYTouchMin = 0.1
    g_ZTouchMin = 0.1
    g_UTouchMin = 0.05
    
    g_XYTouchInitStepSize = 1
    g_ZTouchInitStepSize = 0.25
    g_UTouchInitStepSize = 1

    g_BinaryCrossTimes = 6

    ''because the shape of the tong, XY have more flexible, Z and U are more rigid.
    g_MaxRangeXY = 2 'mm'
    g_MaxRangeZ = 0.5 'mm'
    g_MaxRangeU = 6 'degree'

    g_XYNumSteps = 40        ''step size is 0.05mm
    g_ZNumSteps = 20        ''step size is 0.025mm
    g_UNumSteps = 30        ''step size is 0.1 degree

    g_WaitTimeBeforeRead = 0.1    ''1.0
    g_WaitTimeBetweenRead = 0.001   ''0.01

    CheckPoint 6
    g_U4MagnetHolder = CU(P6)
    If g_U4MagnetHolder = 0 Then
        g_U4MagnetHolder = g_Perfect_U4Holder
    EndIf
    
    
    ''when tong is agaigst a solid wall and move 1 mm (or degree) in that direction
    g_RateFZ = 155
    g_RateTX = 3.0
    g_RateTY = 5.2
    g_RateTZ = 3.6
    
    g_FCheckMagnet = 0.5
    
    'default speeds'
    Power Low
    Accel VERY_SLOW_GO_ACCEL, VERY_SLOW_GO_DEACCEL
    Speed VERY_SLOW_GO_SPEED
    
    AccelS VERY_SLOW_MOVE_ACCEL, VERY_SLOW_MOVE_DEACCEL
    SpeedS VERY_SLOW_MOVE_SPEED
    
    g_ConstantInited = True
Fend

Function GetTouchThreshold(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_YFORCE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_ZFORCE
        GetTouchThreshold = g_ZTouchThreshold
    Case FORCE_XTORQUE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_YTORQUE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_ZTORQUE
        GetTouchThreshold = g_UTouchThreshold
    Default
        GetTouchThreshold = 0
    Send
    
    If forceName < 0 Then
        GetTouchThreshold = -GetTouchThreshold; 
    EndIf
Fend

Function GetTouchMin(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchMin = g_XYTouchMin
    Case FORCE_YFORCE
        GetTouchMin = g_XYTouchMin
    Case FORCE_ZFORCE
        GetTouchMin = g_ZTouchMin
    Case FORCE_XTORQUE
        GetTouchMin = g_XYTouchMin
    Case FORCE_YTORQUE
        GetTouchMin = g_XYTouchMin
    Case FORCE_ZTORQUE
        GetTouchMin = g_UTouchMin
    Default
        GetTouchMin = 0
    Send
    
    If forceName < 0 Then
        GetTouchMin = -GetTouchMin
    EndIf
Fend

Function GetTouchStepSize(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_YFORCE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_ZFORCE
        GetTouchStepSize = g_ZTouchInitStepSize
    Case FORCE_XTORQUE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_YTORQUE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_ZTORQUE
        GetTouchStepSize = g_UTouchInitStepSize
    Default
        GetTouchStepSize = 1E20
    Send
Fend

Function GetForceThreshold(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceThreshold = g_ThresholdFX
    Case FORCE_YFORCE
        GetForceThreshold = g_ThresholdFY
    Case FORCE_ZFORCE
        GetForceThreshold = g_ThresholdFZ
    Case FORCE_XTORQUE
        GetForceThreshold = g_ThresholdTX
    Case FORCE_YTORQUE
        GetForceThreshold = g_ThresholdTY
    Case FORCE_ZTORQUE
        GetForceThreshold = g_ThresholdTZ
    Default
        GetForceThreshold = 0
    Send
Fend

Function GetForceMin(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceMin = g_MinFX
    Case FORCE_YFORCE
        GetForceMin = g_MinFY
    Case FORCE_ZFORCE
        GetForceMin = g_MinFZ
    Case FORCE_XTORQUE
        GetForceMin = g_MinTX
    Case FORCE_YTORQUE
        GetForceMin = g_MinTY
    Case FORCE_ZTORQUE
        GetForceMin = g_MinTZ
    Default
        GetForceMin = 0
    Send
Fend

Function GetForceBigThreshold(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceBigThreshold = g_BigThresholdFX
    Case FORCE_YFORCE
        GetForceBigThreshold = g_BigThresholdFY
    Case FORCE_ZFORCE
        GetForceBigThreshold = g_BigThresholdFZ
    Case FORCE_XTORQUE
        GetForceBigThreshold = g_BigThresholdTX
    Case FORCE_YTORQUE
        GetForceBigThreshold = g_BigThresholdTY
    Case FORCE_ZTORQUE
        GetForceBigThreshold = g_BigThresholdTZ
    Default
        GetForceBigThreshold = 0
    Send
Fend

Function GetCutMiddleData(forceName As Integer, ByRef scanRange As Real, ByRef numSteps As Integer)
    Select Abs(forceName)
    Case FORCE_XFORCE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_YFORCE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_ZFORCE
        scanRange = g_MaxRangeZ
        numSteps = g_ZNumSteps
    Case FORCE_XTORQUE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_YTORQUE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_ZTORQUE
        scanRange = g_MaxRangeU
        numSteps = g_UNumSteps
    Send
Fend

'goal reduce valid samples to 50%-75% of total sample'
'minValue and maxValue are IN and OUT arguments'
'return value is the numValidSamples'
Function NarrowMinMax(ByVal forceName As Integer, ByRef minValue As Real, ByRef maxValue As Real) As Integer

    NarrowMinMax = 0

    If Abs(maxValue - minValue) < 0.0001 Then
        Exit Function
    EndIf

    If forceName <= 0 Or forceName > 6 Then
        Exit Function
    EndIf


    'find distribution'
    For binIndex = 1 To 10
        bin(binIndex) = 0
    Next
    numValidSamples = 0
    binLength = (maxValue - minValue) / 10
    For NMMRepeatIndex = 1 To FORCE_READ_TIMES
        NMMCurrentValue = g_rawForces(forceName, NMMRepeatIndex)
        If NMMCurrentValue >= minValue And NMMCurrentValue <= maxValue Then
            binIndex = Int((g_rawForces(forceName, NMMRepeatIndex) - minValue) / binLength) + 1
            If binIndex > 0 And binIndex <= 10 Then
                bin(binIndex) = bin(binIndex) + 1
                numValidSamples = numValidSamples + 1
#ifdef DEBUG
            Else
                Print "discard force=", g_rawForces(forceName, NMMRepeatIndex)
#endif
            EndIf
        EndIf
    Next
#ifdef DEBUG
    Print "total valid samples ", numValidSamples
    For binIndex = 1 To 10
        Print "bin(", binIndex, ")=", bin(binIndex)
    Next
#endif
    numSamplesToCut = numValidSamples / 4
    numSamplesLeft = numValidSamples

    'check bins'
    numDiscard = 0
    For binIndex = 1 To 10
        If (numDiscard + bin(binIndex) <= numSamplesToCut) Then
            numDiscard = numDiscard + bin(binIndex)
            minValue = minValue + binLength
#ifdef DEBUG
            Print "discard bin(", binIndex, ")=", bin(binIndex), ", new minValue=", minValue
#endif
        Else
            Exit For
        EndIf
    Next
    numSamplesLeft = numSamplesLeft - numDiscard
    
    numDiscard = 0
    For binIndex = 10 To 1 Step -1
        If (numDiscard + bin(binIndex) <= numSamplesToCut) Then
            numDiscard = numDiscard + bin(binIndex)
            maxValue = maxValue - binLength
#ifdef DEBUG
            Print "discard bin(", binIndex, ")=", bin(binIndex), ", new maxValue=", maxValue
#endif
        Else
            Exit For
        EndIf
    Next
    numSamplesLeft = numSamplesLeft - numDiscard

    NarrowMinMax = numSamplesLeft
Fend

Function AverageForce(forceName As Integer, minValue As Real, maxValue As Real) As Real

    'calculate the result'
    AFNumValidSamples = 0
    AverageForce = 0
    
    If forceName <= 0 Or forceName > 6 Then
        Exit Function
    EndIf
    
    For AFRepeatIndex = 1 To FORCE_READ_TIMES
        currentValue = g_rawForces(forceName, AFRepeatIndex)
        If currentValue >= minValue And currentValue <= maxValue Then
            AFNumValidSamples = AFNumValidSamples + 1
            AverageForce = AverageForce + currentValue
        EndIf
    Next
    If AFNumValidSamples > 0 Then
         AverageForce = AverageForce / AFNumValidSamples
#ifdef DEBUG
        Print "AverageForce, total valid sample ", AFNumValidSamples, ", result=", AverageForce
#endif
    EndIf
Fend
Function ReadForce(ByVal forceName As Integer) As Real
    ReadForce = 0
    RFSForceIndex = Abs(forceName)
    
    If RFSForceIndex <= 0 Or RFSForceIndex > 6 Then
        Exit Function
    EndIf
    
    maxV = -99999
    minV = 99999

    'Read the raw forces to the buffer'
    If g_WaitTimeBeforeRead > 0 Then Wait g_WaitTimeBeforeRead
    For RFSRepeatIndex = 1 To FORCE_READ_TIMES
        RFCurrentV = Force_GetForce(RFSForceIndex)
        g_rawForces(RFSForceIndex, RFSRepeatIndex) = RFCurrentV
        'update max/min'
        If RFCurrentV > maxV Then maxV = RFCurrentV
        If RFCurrentV < minV Then minV = RFCurrentV
        If g_WaitTimeBetweenRead > 0 Then Wait g_WaitTimeBetweenRead
    Next
#ifdef DEBUG
    Print "raw force, (min, max): (", minV, ", ", maxV, ")"
#endif

    '==============narrow max and min to exclude bad values==========='
    RFSNumValidSamples = NarrowMinMax(RFSForceIndex, minV, maxV)
    'check to see if need narrow again'
    If RFSNumValidSamples > 80 Then NarrowMinMax RFSForceIndex, minV, maxV
#ifdef DEBUG
    Print "new (min, max) for force ", RFSForceIndex, " : (", minV, ", ", maxV, ")"
#endif
    'calculate the result'
    If minV = 0 And maxV = 0 Then
        ''change to ignore them
        minV = -99999
        maxV = 99999
    EndIf
    ReadForce = AverageForce(RFSForceIndex, minV, maxV)
Fend

Function ReadForces(ByRef returnForces() As Real)

    'init'
    For RFSForceIndex = 1 To 6
        RFSMaxValue(RFSForceIndex) = -99999
        RFSMinValue(RFSForceIndex) = 99999
    Next

    'Read force values'
    If g_WaitTimeBeforeRead > 0 Then Wait g_WaitTimeBeforeRead
    For RFSRepeatIndex = 1 To FORCE_READ_TIMES
        Force_GetForces RFSCurrentValue()
        For RFSForceIndex = 1 To 6
            g_rawForces(RFSForceIndex, RFSRepeatIndex) = RFSCurrentValue(RFSForceIndex)
            'update max/min'
            If RFSCurrentValue(RFSForceIndex) > RFSMaxValue(RFSForceIndex) Then RFSMaxValue(RFSForceIndex) = RFSCurrentValue(RFSForceIndex)
            If RFSCurrentValue(RFSForceIndex) < RFSMinValue(RFSForceIndex) Then RFSMinValue(RFSForceIndex) = RFSCurrentValue(RFSForceIndex)
        Next
           If g_WaitTimeBetweenRead > 0 Then Wait g_WaitTimeBetweenRead
       Next

    '==============narrow max and min to exclude bad values and get results==========='
    For RFSForceIndex = 1 To 6
        minV = RFSMinValue(RFSForceIndex)
        maxV = RFSMaxValue(RFSForceIndex)
        RFSNumValidSamples = NarrowMinMax(RFSForceIndex, minV, maxV)
        'check to see if need narrow again'
        If RFSNumValidSamples > 80 Then NarrowMinMax RFSForceIndex, minV, maxV
#ifdef DEBUG
        Print "new (min, max) for force ", RFSForceIndex, " : (", minV, ", ", maxV, ")"
#endif
    
        'calculate the result'
        If minV = 0 And maxV = 0 Then
            ''change to ignore them
            minV = -99999
            maxV = 99999
        EndIf
        returnForces(RFSForceIndex) = AverageForce(RFSForceIndex, minV, maxV)
    Next
Fend

Function CalculateStepSize(ByVal forceName As Integer, ByVal stepDistance As Real, ByVal currentU As Real, ByRef stepSize() As Real)

    stepDistance = Abs(stepDistance)
    CSSForceName = Abs(forceName)

    CSSDumbBellAngle = UToDumbBellAngle(currentU)

    'init to all 0'
    stepSize(1) = 0
    stepSize(2) = 0
    stepSize(3) = 0
    stepSize(4) = 0

    If stepDistance = 0 Then Exit Function
                            
    Select CSSForceName
    Case FORCE_XFORCE
        'move in force sensor's X direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_XAXIS_ANGLE)

        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)

    Case FORCE_YTORQUE
        'move in force sensor's X direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_XAXIS_ANGLE)

#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(1) = stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = stepDistance * Sin(CSSAngleInRad)
#else
        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)
#endif
        
    Case FORCE_YFORCE
        'move in force sensor's Y direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_YAXIS_ANGLE)

        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)

    Case FORCE_XTORQUE
        'move in force sensor's Y direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_YAXIS_ANGLE)

#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)
#else
        stepSize(1) = stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = stepDistance * Sin(CSSAngleInRad)
#endif

    Case FORCE_ZFORCE
        stepSize(3) = stepDistance

    Case FORCE_ZTORQUE
#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(4) = -stepDistance
#else
        stepSize(4) = stepDistance
#endif
    Send

    If forceName < 0 Then
        stepSize(1) = -stepSize(1)
        stepSize(2) = -stepSize(2)
        stepSize(3) = -stepSize(3)
        stepSize(4) = -stepSize(4)
    EndIf
Fend


''This function will scan in related direction to find the position
''where the force sensor cross the threshold in desired direction.
''At the end, the robot will stop at the cross position.
''If the direction is - -> +, then the final force will be a little
''bigger than threshold.  If the cross dirction is + -> -, 
''then the final force value will be a little smaller than threshold
''When it moves the robot, it combines steps and force trigger.
''Input:
''   forceName:
''               +-FORCE_XFORCE   (rarely use, use FORCE_YTORQUE instead)
''               +-FORCE_YFORCE   (rarely use, use FORCE_XTORQUE instead)
''               +-FORCE_ZFORCE
''               +-FORCE_XTORQUE
''               +-FORCE_YTORQUE
''               +-FORCE_ZTORQUE
''
''   crossDirection:
''               +: rising cross
''               -: falling cross
''
''
''   threshold:  the desired force Threshold to cross
''
''
''   scanDistance:  max scan Distance from current position
''
''   numSteps:      numSteps to scan the distance
''
''This function is a wrapper for ForceScan.
''It make sure the robot will move to right and most effective direction to cross the threshold
Function ForceCross(forceName As Integer, threshold As Real, scanDistance As Real, numSteps As Integer, fineTune As Boolean) As Boolean
    ''calculate where is the best destination,
    CalculateStepSize forceName, scanDistance, CU(P*), FCDestPosition()
    FCDestPosition(1) = FCDestPosition(1) + CX(P*)
    FCDestPosition(2) = FCDestPosition(2) + CY(P*)
    FCDestPosition(3) = FCDestPosition(3) + CZ(P*)
    FCDestPosition(4) = FCDestPosition(4) + CU(P*)
    
    Print "ForceCross forceName: ", forceName, ", threshold: ", threshold, " distance: ", scanDistance
    Print "destination P ", 
    PrintPosition FCDestPosition()
    Print
    
    ''call ForceScan
    ForceCross = ForceScan(forceName, threshold, FCDestPosition(), numSteps, fineTune)
Fend

''touch. It must start from a neutral place for that force.
''the robot may come back to the starting place to do force sensor reset

Function ForceTouch(ByVal forceName As Integer, ByVal scanDistance As Real, ByVal fineTune As Boolean) As Boolean
    ForceTouch = False

    Print "ForceTouch ", forceName, ", ", scanDistance

    GetCurrentPosition FTHInitP()

    ''get destination position from the scan distance
    CalculateStepSize forceName, scanDistance, CU(P*), FTHDestP()
    FTHDestP(1) = FTHDestP(1) + CX(P*)
    FTHDestP(2) = FTHDestP(2) + CY(P*)
    FTHDestP(3) = FTHDestP(3) + CZ(P*)
    FTHDestP(4) = FTHDestP(4) + CU(P*)

    ''try move with trigger first, if failed, we will scan with steps.
    FTHThreshold = GetTouchThreshold(forceName)
    For FTHRetryTimes = 1 To 3
        If g_FlagAbort Then
            GenericMove FTHInitP(), False
            Exit Function
        EndIf

        ''set up trigger
        SetupForceTrigger forceName, (1.2 * FTHThreshold)
        ''move
        GenericMove FTHDestP(), True
        
        ''make sure that force is not too big
        g_CurrentSingleF = ReadForce(forceName)
        If ForcePassedThreshold(forceName, g_CurrentSingleF, (5 * FTHThreshold)) Then
            ''move back to starting position and retry
            GenericMove FTHInitP(), False
        EndIf
        ''check whether we moved at all
        GetCurrentPosition g_CurrentP()
        If HypDistance(g_CurrentP(), FTHInitP()) < 0.001 Then
            Print "reset force sensor in force touch"
            If Not ForceResetAndCheck Then
				Exit Function
            EndIf
        EndIf
    Next
    
    ''check to see if we need to step-scan to it if moving with force trigger not work
    g_CurrentSingleF = ReadForce(forceName)
    If Not ForcePassedThreshold(forceName, g_CurrentSingleF, FTHThreshold) Then
        ''prepare to step-scan
        GetCurrentPosition g_CurrentP()
        FTHNumSteps = HypDistance(g_CurrentP(), FTHDestP()) / GetTouchStepSize(forceName)
        FTHThreshold = GetTouchThreshold(forceName)
        If Not ForceScan(forceName, FTHThreshold, FTHDestP(), FTHNumSteps, False) Then
            Print "not touched within the range"
		    If g_FlagAbort Then
		        GenericMove FTHInitP(), False
		    EndIf
            Exit Function
        EndIf
    EndIf
    

    If fineTune Then
        ''save fine tune start position: we will come back to this position after we reset
        ''the force sensor in case it needs to.
        GetCurrentPosition FTHMidP()
        FTHThreshold = GetTouchMin(forceName)
        FTHFineTuneDistance = GetTouchStepSize(forceName) * 4
        For FTHRetryTimes = 1 To 3
            If ForceCross(-forceName, FTHThreshold, FTHFineTuneDistance, 40, True) Then
                Exit For
            Else
                If g_FlagAbort Then
                    GenericMove FTHInitP(), False
                    Exit Function
                EndIf
                Print "reset force sensor"
                GenericMove FTHInitP(), False
                Wait TIME_WAIT_BEFORE_RESET
                If Not ForceResetAndCheck Then
					Exit Function
                EndIf
                GenericMove FTHMidP(), False
            EndIf
        Next

        If FTHRetryTimes > 3 Then
            Print "cannot find min"
		    If g_FlagAbort Then
		        GenericMove FTHInitP(), False
		    EndIf
            Exit Function
        EndIf
    EndIf
    
    ForceTouch = True
    ''OK, here it is
    GetCurrentPosition g_CurrentP()
    g_CurrentSingleF = ReadForce(forceName)

    Print "ForceTouched at P:", 
    PrintPosition g_CurrentP()
    Print " force :", g_CurrentSingleF

    If g_FlagAbort Then
        GenericMove FTHInitP(), False
    EndIf
Fend

Function SetVerySlowSpeed
    Accel VERY_SLOW_GO_ACCEL, VERY_SLOW_GO_DEACCEL
    Speed VERY_SLOW_GO_SPEED
    
    AccelS VERY_SLOW_MOVE_ACCEL, VERY_SLOW_MOVE_DEACCEL
    SpeedS VERY_SLOW_MOVE_SPEED
Fend

Function SetFastSpeed
    Accel FAST_GO_ACCEL, FAST_GO_DEACCEL
    Speed FAST_GO_SPEED
    
    AccelS FAST_MOVE_ACCEL, FAST_MOVE_DEACCEL
    SpeedS FAST_MOVE_SPEED
Fend

Function isCloseToPoint(Num As Integer) As Boolean

    isCloseToPoint = True
    
    ICTPDX = CX(P*) - CX(P(Num))
    ICTPDY = CY(P*) - CY(P(Num))
    ICTPDZ = CZ(P*) - CZ(P(Num))
    ICTPDU = CU(P*) - CU(P(Num))

    ''These two, must be close in all XYZU
    If Num = 6 Or Num = 21 Then
        If Abs(ICTPDU) > 2 Then
            isCloseToPoint = False
        EndIf

        If Abs(ICTPDZ) > 2 Then
            isCloseToPoint = False
        EndIf
    EndIf

    If Sqr(ICTPDX * ICTPDX + ICTPDY * ICTPDY) > 2 Then
        isCloseToPoint = False
    EndIf
Fend

''dumbbell direction is the strong end direction.
'' we also require that force sensor Y axis is the same direction
Function UToDumbBellAngle(ByVal currentU As Real) As Real
    Integer currentToolset
    
    currentToolset = Tool
    If Tool <> 0 Then
        P50 = TLSet(currentToolset)
        currentU = currentU - CU(P50)
    EndIf

    UToDumbBellAngle = currentU - g_U4MagnetHolder + g_MagnetTransportAngle
    If g_OnlyAlongAxis Then
        ''we use currentToolset as a temp integer
        UToDumbBellAngle = UToDumbBellAngle / 90.0 + 0.5
        currentToolset = Int(UToDumbBellAngle)
        UToDumbBellAngle = 90 * currentToolset
    EndIf
Fend

''move by direction and distance
Function TongMove(ByVal direction As Integer, ByVal distance As Real, ByVal withTrigger As Boolean)

    CalculateStepSize direction, distance, CU(P*), TMChange()
    ''move
    StepMove TMChange(), withTrigger
Fend

Function ResetForceSensor As Boolean
	ResetForceSensor = False

    Print "Resetting force sensor"
    
    SetFastSpeed
    
    ''move up 10 mm
    Move P* +Z(10.0)
    
    ''reset force sensor
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
		Exit Function
    EndIf

    ''move back
    Move P* -Z(8.0)
    
    SetVerySlowSpeed
    Move P* -Z(2.0)
    Print "force sensor resetted"
    
    ResetForceSensor = True
Fend

Function TurnOnHeater
    On 13
    On 14
Fend

Function TurnOffHeater As Boolean
    TurnOffHeater = True
    Off 14
    Wait Sw(13) = 0, 60
    If TW = 1 Then
        TurnOffHeater = False
    EndIf
    Off 13
Fend

Function WaitHeaterHot(timeInSeconds As Integer) As Boolean
	On 13
	On 14
    WaitHeaterHot = False
    Wait Sw(13) = 1, timeInSeconds
    If TW = 1 Then
        WaitHeaterHot = False
    Else
        WaitHeaterHot = True
    EndIf
Fend

''get rid of water????
Function Dance
    Integer Dance_I
    
    Accel 10, 10
    
    Speed 1, 1, 1
    
    LimZ (CZ(P0) + 15)
    
    For Dance_I = 1 To 4
        Jump P0 +U(10)
        Jump P0 -U(10)
    Next
    
    Jump P0
    LimZ 0
Fend

Function MoveTongHome
    Tool 0

    InitForceConstants

    If g_LN2LevelHigh Then
        TurnOnHeater
    EndIf

    SetFastSpeed
    
    If isCloseToPoint(6) Then
        If Not Open_Gripper Then
            g_RunResult$ = "MoveTongHome: Open_Gripper Failed, may hold magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False ''P3
    EndIf
    
    SetVeryFastSpeed
    
    If Dist(P*, P0) > 3 Then
        Go P* :Z(-2)
        
#ifdef MIXED_ARM_ORIENTATION
        Go P1
#else
        Move P1
#endif
        
        Close_Lid
        
        Move P0 :Z(-1)
        Move P0
    EndIf

    If g_LN2LevelHigh Then
        If Not WaitHeaterHot(20) Then
            g_RunResult$ = "MoveTongHome: HEATER failed to reach high temperature"
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, g_RunResult$
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_CLEAR
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_HEATER_FAIL
        EndIf
    EndIf

    If Sw(13) = On Then
        ''wait
        Wait 60
        Dance
    EndIf
    TurnOffHeater
    LimZ 0
Fend

Function MoveTongOut
    Tool 0

    Move P* :Z(-1)
#ifdef MIXED_ARM_ORIENTATION
	Go P1
#else
    Move P1
#endif
Fend

Function GenericMove(ByRef position() As Real, tillForce As Boolean)
    If (CX(P*) <> position(1)) Or (CY(P*) <> position(2)) Or (CZ(P*) <> position(3)) Then
        If tillForce Then
            Move P* :X(position(1)) :Y(position(2)) :Z(position(3)) :U(position(4)) Till Force
        Else
            Move P* :X(position(1)) :Y(position(2)) :Z(position(3)) :U(position(4))
        EndIf
    Else
        If tillForce Then
            Go P* :U(position(4)) Till Force
        Else
            Go P* :U(position(4))
        EndIf
    EndIf
Fend

Function StepMove(ByRef stepSize() As Real, tillForce As Boolean)
    If (stepSize(1) <> 0) Or (stepSize(2) <> 0) Or (stepSize(3) <> 0) Then
        If tillForce Then
            Move P* + XY(stepSize(1), stepSize(2), stepSize(3), stepSize(4)) Till Force
        Else
            Move P* + XY(stepSize(1), stepSize(2), stepSize(3), stepSize(4))
        EndIf
    Else
        If tillForce Then
            Go P* +U(stepSize(4)) Till Force
        Else
            Go P* +U(stepSize(4)) Till Force
        EndIf
    EndIf
Fend

Function GetCurrentPosition(ByRef position() As Real)
    position(1) = CX(P*)
    position(2) = CY(P*)
    position(3) = CZ(P*)
    position(4) = CU(P*)
Fend

Function HypStepSize(ByRef stepSize() As Real) As Real
    HypStepSize = Sqr(stepSize(1) * stepSize(1) + stepSize(2) * stepSize(2) + stepSize(3) * stepSize(3) + stepSize(4) * stepSize(4))
Fend

Real tmp_Real
Function HypDistance(ByRef position1() As Real, ByRef position2() As Real) As Real
    HypDistance = 0
    For tmp_PIndex = 1 To 4
        tmp_Real = position1(tmp_PIndex) - position2(tmp_PIndex)
        HypDistance = HypDistance + tmp_Real * tmp_Real
    Next
    HypDistance = Sqr(HypDistance)
Fend


Function PositionCopy(ByRef dst() As Real, ByRef src() As Real)
    For tmp_PIndex = 1 To 4
        dst(tmp_PIndex) = src(tmp_PIndex)
    Next
Fend

Function PrintPosition(ByRef position() As Real)
    Print "(", position(1), ", ", position(2), ", ", position(3), ", ", position(4), ")", 
Fend

Function LogPosition(ByRef position() As Real)
    Print #LOG_FILE_NO, "(", position(1), ", ", position(2), ", ", position(3), ", ", position(4), ")", 
Fend


Function BinaryCross(forceName As Integer, ByRef previousPosition() As Real, previousForce As Real, threshold As Real, numSteps As Integer)

    Print "BinaryCross ", forceName, ", ", threshold

    ''check current condition
    If Abs(previousForce - threshold) < 0.01 Then
        Print "previousForce = threshold, exit"
        GenericMove previousPosition(), False
        Exit Function
    EndIf

    GetCurrentPosition BCCurrentPosition()
    BCCurrentForce = ReadForce(forceName)
    If Abs(BCCurrentForce - threshold) < 0.01 Then
        Print "BCCurrentForce = threshold, exit"
        Exit Function
    EndIf

    For tmp_PIndex = 1 To 4
        BCStepSize(tmp_PIndex) = BCCurrentPosition(tmp_PIndex) - previousPosition(tmp_PIndex)
    Next
    
    If HypStepSize(BCStepSize()) < 0.001 Then
        Print "step size already very small < 0.001, exit"
        Exit Function
    EndIf

    ''save best point
    If Abs(BCCurrentForce - threshold) > Abs(previousForce - threshold) Then
        PositionCopy BCBestPosition(), previousPosition()
        BCBestDF = Abs(previousForce - threshold)
    Else
        PositionCopy BCBestPosition(), BCCurrentPosition()
        BCBestDF = Abs(BCCurrentForce - threshold)
    EndIf


    If (previousForce - threshold) * (BCCurrentForce - threshold) > 0 Then
        Print "threshold must be in between previous force and current force"
        Exit Function
    EndIf

    GenericMove previousPosition(), False
    For BCStepIndex = 1 To numSteps
        If g_FlagAbort Then
            Exit Function
        EndIf

        For tmp_PIndex = 1 To 4
            BCStepSize(tmp_PIndex) = BCStepSize(tmp_PIndex) / 2   ''reduce stepsize to half
        Next
        If HypStepSize(BCStepSize()) < 0.0001 Then
            Print "step size already very small < 0.0001, exit"
            Exit Function
        EndIf
        StepMove BCStepSize(), False
        GetCurrentPosition g_CurrentP()
        g_CurrentSingleF = ReadForce(forceName)
        BCTempDF = Abs(g_CurrentSingleF - threshold)
        Print "step ", BCStepIndex, ", P: ", 
        PrintPosition g_CurrentP()
        Print " force :", g_CurrentSingleF
        ''save best
        If BCTempDF < BCBestDF Then
            PositionCopy BCBestPosition(), g_CurrentP()
            BCBestDF = BCTempDF
        EndIf

        If Abs(g_CurrentSingleF - threshold) < 0.01 Then
            Print "found threshold at step ", BCStepIndex, ", exit"
            Exit Function
        EndIf
        If (previousForce - threshold) * (g_CurrentSingleF - threshold) < 0 Then
            ''cross the threshold, so change current
            PositionCopy BCCurrentPosition(), g_CurrentP()
            BCCurrentForce = g_CurrentSingleF
            GenericMove previousPosition(), False
        Else
            ''not reach threshold yet, change previous
            PositionCopy previousPosition(), g_CurrentP()
            previousForce = g_CurrentSingleF
        EndIf
    Next

#ifdef CROSS_LINEAR_INTERPOLATE
    ''linear interpolation
    Print "Linear interpolation"
    Print "new previous: Force=", previousForce, ", P=", 
    PrintPosition previousPosition()
    Print
    
    Print "new current:  Force=", BCCurrentForce, ", P=", 
    PrintPosition BCCurrentPosition()
    Print
    Print " threshold Force=", threshold

    If Abs(previousForce - BCCurrentForce) < 0.0001 Then
        Print "too close , return middle"
        For tmp_PIndex = 1 To 4
            BCPerfectPosition(tmp_PIndex) = (previousPosition(tmp_PIndex) + BCCurrentPosition(tmp_PIndex)) / 2
        Next
    Else
        For tmp_PIndex = 1 To 4
            BCPerfectPosition(tmp_PIndex) = previousPosition(tmp_PIndex) + (BCCurrentPosition(tmp_PIndex) - previousPosition(tmp_PIndex)) * (threshold - previousForce) / (BCCurrentForce - previousForce)
        Next
    EndIf
    GenericMove BCPerfectPosition(), False
    Print "perfect P at ", 
    PrintPosition BCPerfectPosition()

#else
    GenericMove BCCurrentPosition(), False
    Print "keep same direction as caller,we move to ", 
    PrintPosition BCCurrentPosition()
#endif
    g_CurrentSingleF = ReadForce(forceName)
    BCTempDF = Abs(g_CurrentSingleF - threshold)
    Print " with force=", g_CurrentSingleF
    ''check best
    If BCBestDF < BCTempDF Then
        Print "best has small DF than perfect, so we go best"
        GenericMove BCBestPosition(), False
        g_CurrentSingleF = ReadForce(forceName)
        Print "best P at ", 
        PrintPosition BCBestPosition()
        Print " with force=", g_CurrentSingleF
    EndIf
Fend

Function SetupForceTrigger(ByVal forceName As Integer, ByVal threshold As Real)

    Force_ClearTrigger

    ''for torque, "less" is "greater". Will be changed if vendor fix this bug
#ifdef FORCE_TORQUE_WRONG_DIRECTION
    Select forceName
    Case FORCE_XFORCE
        Force_SetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_YFORCE
        Force_SetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_ZFORCE
        Force_SetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_XTORQUE
        Force_SetTrigger forceName, threshold, FORCE_LESS
    Case FORCE_YTORQUE
        Force_SetTrigger forceName, threshold, FORCE_LESS
    Case FORCE_ZTORQUE
        Force_SetTrigger forceName, threshold, FORCE_LESS
    Case -FORCE_XFORCE
        Force_SetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_YFORCE
        Force_SetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_ZFORCE
        Force_SetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_XTORQUE
        Force_SetTrigger -forceName, threshold, FORCE_GREATER
    Case -FORCE_YTORQUE
        Force_SetTrigger -forceName, threshold, FORCE_GREATER
    Case -FORCE_ZTORQUE
        Force_SetTrigger -forceName, threshold, FORCE_GREATER
    Send
#else
	If forceName > 0 Then
		Force_SetTrigger forceName, threshold, FORCE_GREATER
	Else
		Force_SetTrigger -forceName, threshold, FORCE_LESS
	EndIf
#endif
Fend

Function ForcePassedThreshold(ByVal forceName As Integer, ByVal currentForce As Real, ByVal threshold As Real) As Boolean
    ForcePassedThreshold = False
    If forceName > 0 Then
        If currentForce >= threshold Then
            ForcePassedThreshold = True
        EndIf
    Else
        If currentForce <= threshold Then
            ForcePassedThreshold = True
        EndIf
    EndIf
Fend


''This function has no safety check to make sure that moving toward the destination will change the force
''in the correct way.  Caller should make sure it works.
Function ForceScan(forceName As Integer, threshold As Real, ByRef destPosition() As Real, numSteps As Integer, fineTune As Boolean) As Boolean

    ForceScan = False
    
    'Save old position'
    GetCurrentPosition FSOldPosition()
    
    PositionCopy FSPrePosition(), FSOldPosition()
    FSPreForce = ReadForce(forceName)
    FSForce = FSPreForce
    Print "old P: ", 
    PrintPosition FSOldPosition()
    Print " old Force: ", FSForce

    ''check current force
    If ForcePassedThreshold(forceName, FSPreForce, threshold) Then
        Print "-ForceScan: OK, already pass the threshold:SHOULD NOT HAPPEND"
        ForceScan = True
#ifdef BINARY_CROSS
        If fineTune Then BinaryCross forceName, FSPrePosition(), FSPreForce, threshold, g_BinaryCrossTimes
#endif
        Exit Function
    EndIf
    
    ''check input parameter
    If numSteps <= 0 Then numSteps = 10
    
    If HypDistance(destPosition(), FSOldPosition()) < 0.001 Then
        Print "-ForceScan: not touched, alreay at the destination"
        Exit Function
    EndIf
    
    For tmp_PIndex = 1 To 4
        FSStepSize(tmp_PIndex) = (destPosition(tmp_PIndex) - FSOldPosition(tmp_PIndex)) / numSteps
    Next
        
    ''scan
    For FSStepIndex = 1 To numSteps
        If g_FlagAbort Then
            Exit Function
        EndIf

        For tmp_PIndex = 1 To 4
            FSDesiredPosition(tmp_PIndex) = FSOldPosition(tmp_PIndex) + FSStepSize(tmp_PIndex) * FSStepIndex
        Next
        
        ''safety re-check
        FSHypStepSize = HypStepSize(FSStepSize())
        If HypDistance(FSDesiredPosition(), FSPrePosition()) > 1.5 * FSHypStepSize Then
            Print "BAD BAD happened"
            Exit Function
        EndIf
        
        ''set up trigger and go
        SetupForceTrigger forceName, (1.2 * threshold)
        GenericMove FSDesiredPosition(), True
        GetCurrentPosition g_CurrentP()

        'check condition'
        g_CurrentSingleF = ReadForce(forceName)
        
        ''force reading check
        ForceChangeCheck forceName, FSHypStepSize, FSPreForce, g_CurrentSingleF

        ''whether we crossed the threshold
        If ForcePassedThreshold(forceName, g_CurrentSingleF, threshold) Then
            Print "step=", FSStepIndex, ", P: ", 
            PrintPosition g_CurrentP()
            Print " force: ", g_CurrentSingleF
            Print "we got it here"
            ForceScan = True
            Exit For
        EndIf
        
        ''whether we moved at all: this do happen, do not know reason
        If HypDistance(g_CurrentP(), FSDesiredPosition()) > 0.0001 Then
            ''Move without force sensor
            GenericMove FSDesiredPosition(), False
            GetCurrentPosition g_CurrentP()

            ''re-whether we crossed the threshold
            g_CurrentSingleF = ReadForce(forceName)
            Print "step=", FSStepIndex, ", NO TRIGGER P: "
            PrintPosition g_CurrentP()
            Print " force: ", g_CurrentSingleF

            If ForcePassedThreshold(forceName, g_CurrentSingleF, threshold) Then
                Print "we got it here"
                ForceScan = True
                Exit For
            EndIf
        Else
            Print "step=", FSStepIndex, ", P: "
            PrintPosition g_CurrentP()
            Print " Force: ", g_CurrentSingleF
        EndIf
        PositionCopy FSPrePosition(), g_CurrentP()
        FSPreForce = g_CurrentSingleF
    Next
    
#ifdef BINARY_CROSS
    If ForceScan Then
         If fineTune Then BinaryCross forceName, FSPrePosition(), FSPreForce, threshold, g_BinaryCrossTimes
    EndIf
#endif
Fend

Function PrintForces(ByRef forces() As Real)
    Print "FX: ", forces(1)
    Print "FY: ", forces(2)
    Print "FZ: ", forces(3)
    Print "TX: ", forces(4)
    Print "TY: ", forces(5)
    Print "TZ: ", forces(6)
Fend

Function LogForces(ByRef forces() As Real)
    Print #LOG_FILE_NO, "FX: ", forces(1)
    Print #LOG_FILE_NO, "FY: ", forces(2)
    Print #LOG_FILE_NO, "FZ: ", forces(3)
    Print #LOG_FILE_NO, "TX: ", forces(4)
    Print #LOG_FILE_NO, "TY: ", forces(5)
    Print #LOG_FILE_NO, "TZ: ", forces(6)
Fend

Function CutMiddle(ByVal forceName As Integer) As Real
    forceName = Abs(forceName)
    
    ''prepare for call with argument
    CMMinForce = GetForceMin(forceName)
    CMThreshold = GetForceThreshold(forceName)
    GetCutMiddleData forceName, CMScanRange, CMNumSteps
    
    CutMiddle = CutMiddleWithArguments(forceName, CMMinForce, CMThreshold, CMScanRange, CMNumSteps)
Fend

Function ForcedCutMiddle(forceName As Integer) As Real
    forceName = Abs(forceName)
    
    ''prepare for call with argument
    CMMinForce = 0 ''this will force the function to run
    CMThreshold = GetForceThreshold(forceName)
    GetCutMiddleData forceName, CMScanRange, CMNumSteps
    
    ForcedCutMiddle = CutMiddleWithArguments(forceName, CMMinForce, CMThreshold, CMScanRange, CMNumSteps)
Fend

Function CutMiddleWithArguments(forceName As Integer, minForce As Real, threshold As Real, scanRange As Real, numSteps As Integer) As Real
	g_CutMiddleFailed = 0
	CutMiddleWithArguments = 0

    ''InitForceConstants
    CMStepStart = g_CurrentSteps
    CMStepTotal = g_Steps
    
    forceName = Abs(forceName)

    CMMinForce = minForce
    CMThreshold = threshold
    CMScanRange = scanRange
    CMNumSteps = numSteps

    'Save old position'
    GetCurrentPosition CMInitP()

    'Find out current Force situation
    'It maybe out of our +-g_ThresholdTZ, may be within
    CMInitForce = ReadForce(forceName)
    Print "Init position ", 
    PrintPosition CMInitP()
    Print " force: ", CMInitForce

    'within min, ignore it'
    If Abs(CMInitForce) < CMMinForce Then
        Print #LOG_FILE_NO, "force too small, ignore"
        Exit Function
    EndIf

    If CMInitForce > CMThreshold Then
        g_Steps = CMStepTotal / 3
        'get +Threshold'
        If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
            Print "FTXTFallingCross ", CMThreshold, " failed, give up"
            Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf
        GetCurrentPosition CMPlusP()
        CMPlusForce = ReadForce(forceName)

        g_Steps = CMStepTotal / 3
        g_CurrentSteps = CMStepStart + CMStepTotal / 3
        SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
        
        'continue move pass -Threshold, then reverse get the -Threshold'
        If Not ForceCross(-forceName, -CMThreshold, CMScanRange, CMNumSteps, False) Then
            Print "FTXTFallingCross ", -CMThreshold, " failed, give up"
            Print #LOG_FILE_NO, "FTXTFallingCross ", -CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf

        g_Steps = CMStepTotal / 3
        g_CurrentSteps = CMStepStart + 2 * CMStepTotal / 3
        SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

        If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
            Print "FTXTRisingCross ", -CMThreshold, " failed, give up"
            Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf
        GetCurrentPosition CMMinusP()
        CMMinusForce = ReadForce(forceName)
    Else
        If CMInitForce < -CMThreshold Then
            g_Steps = CMStepTotal / 3
            'get -Threshold'
            If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
                Print "FTXTRisingCross ", -CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition CMMinusP()
            CMMinusForce = ReadForce(forceName)

            g_Steps = CMStepTotal / 3
            g_CurrentSteps = CMStepStart + CMStepTotal / 3
            SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

            'continue move pass +Threshold, then reverse get the +Threshold'
            If Not ForceCross(forceName, CMThreshold, CMScanRange, CMNumSteps, False) Then
                Print "FTXTRisingCross ", CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTRisingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal / 3
            g_CurrentSteps = CMStepStart + 2 * CMStepTotal / 3
            SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

            If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
                Print "FTXTFallingCross ", CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition CMPlusP()
            CMPlusForce = ReadForce(forceName)
        Else
            'OK we need to go both ways
            g_Steps = CMStepTotal / 4
            'move pass -Threshold, then reverse get the -Threshold
            If Not ForceCross(-forceName, -CMThreshold, CMScanRange, CMNumSteps, False) Then
                Print "FTXTFallingCross ", -CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTFallingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal / 4
            g_CurrentSteps = CMStepStart + CMStepTotal / 4
            SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

            If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
                Print "FTXTRisingCross ", -CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition CMMinusP()
            CMMinusForce = ReadForce(forceName)


            g_Steps = CMStepTotal / 4
            g_CurrentSteps = CMStepStart + CMStepTotal / 2
            SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

            'continue move pass +g_ThresholdTZ, then reverse get the +g_ThresholdTZ'
            If Not ForceCross(forceName, CMThreshold, CMScanRange, CMNumSteps, False) Then
                Print "FTXTRisingCross ", CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTRisingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal / 4
            g_CurrentSteps = CMStepStart + 3 * CMStepTotal / 4
            SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

            If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
                Print "FTXTFallingCross ", CMThreshold, " failed, give up"
                Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition CMPlusP()
            CMPlusForce = ReadForce(forceName)
        EndIf
    EndIf

    'calculate the perfect position'
    ''middle of the minus and plus is safer than linear interpolate
    For tmp_PIndex = 1 To 4
        CMFinalP(tmp_PIndex) = (CMMinusP(tmp_PIndex) + CMPlusP(tmp_PIndex)) / 2
    Next
    GenericMove CMFinalP(), False
    
    CMPlusForce = ReadForce(forceName)
    
    Select forceName
    Case FORCE_XFORCE
		CutMiddleWithArguments = Abs(CMMinusP(1) - CMPlusP(1))
    Case FORCE_YFORCE
		CutMiddleWithArguments = Abs(CMMinusP(2) - CMPlusP(2))
    Case FORCE_ZFORCE
		CutMiddleWithArguments = Abs(CMMinusP(3) - CMPlusP(3))
    Case FORCE_XTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(2) - CMPlusP(2))
    Case FORCE_YTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(1) - CMPlusP(1))
    Case FORCE_ZTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(4) - CMPlusP(4))
	Send

    Print "CutMiddle ", forceName, 
    Print "position moved from ", 
    PrintPosition CMInitP()
    Print " to ", 
    PrintPosition CMFinalP()
    Print ", force changed from ", CMInitForce, " to ", CMPlusForce

    Print #LOG_FILE_NO, "CutMiddle ", forceName, 
    Print #LOG_FILE_NO, "position moved from ", 
    LogPosition CMInitP()
    Print #LOG_FILE_NO, " to ", 
    LogPosition CMFinalP()
    Print #LOG_FILE_NO, ", force changed from ", CMInitForce, " to ", CMPlusForce
    
    Print "Freedom: ", CutMiddleWithArguments
    Print #LOG_FILE_NO, "Freedom: ", CutMiddleWithArguments
Fend

Function LidMonitor
    ''monitor IO bit and send VB event if desired bits are changed
    WOpen "LidMonitor.Txt" As #50
    Print #50, "LidMonitor at ", Date$, " ", Time$
    IOPreInputValue = InW(0)
    IOPreOutputValue = OutW(0)
    
    g_IOMCounter = 0
    g_LidOpened = 0
    
    Print "current IO input  Bit ", Hex$(IOPreInputValue)
    Print "current IO output Bit ", Hex$(IOPreOutputValue)
    Print #50, "current IO input  Bit ", Hex$(IOPreInputValue)
    Print #50, "current IO output Bit ", Hex$(IOPreOutputValue)

    SPELCom_Event EVTNO_INPUT, IOPreInputValue
    SPELCom_Event EVTNO_OUTPUT, IOPreOutputValue
    
    While Not SafetyOn
        IOCurInputValue = InW(0)
        IOCurOutputValue = OutW(0)

#ifndef NO_DEWAR_LID
        ''check if lid opened by human
        If BTst(IOCurOutputValue, OUT_LID_OPEN) = 0 And BTst(IOPreInputValue, BITNO_LID_CLOSE) = 1 And BTst(IOCurInputValue, BITNO_LID_CLOSE) = 0 Then
            SPELCom_Event EVTNO_LID_OPEN, "dewar lid is opened manually"
            Print #50, "dewar lid is opened at", Date$, " ", Time$
            Print "dewar lid is opened at", Date$, " ", Time$
            g_LidOpened = g_LidOpened + 1
        EndIf
#endif
        
        If IOCurInputValue <> IOPreInputValue Then
            Print #50, "IO input changed, new value: ", Hex$(IOCurInputValue)
            Print "IO input changed, new value: ", Hex$(IOCurInputValue)
            IOPreInputValue = IOCurInputValue
        EndIf

        ''alway send out the input bits
        SPELCom_Event EVTNO_INPUT, IOPreInputValue

		''only send out output bit if it is changed
        If IOCurOutputValue <> IOPreOutputValue Then
            Print #50, "IO output changed, new value: ", Hex$(IOCurOutputValue)
            Print "IO output changed, new value: ", Hex$(IOCurOutputValue)
            IOPreOutputValue = IOCurOutputValue
		    SPELCom_Event EVTNO_OUTPUT, IOPreOutputValue
        EndIf

        Wait 1
        g_IOMCounter = g_IOMCounter + 1
    Wend
    
    Close #50
Fend

Function VBGetIOMHeartBeat
    SPELCom_Return g_IOMCounter
Fend

Function VBGetLidOpened
    If g_LidOpened Then
        SPELCom_Return 1
    Else
        SPELCom_Return 0
    EndIf
Fend

Function CheckPoint(Number As Integer)
    Real x; 
    OnErr GoTo PointNotExist
    x = CX(P(Number))
    Exit Function
PointNotExist:
    EClr
    Print "Point ", Number, " not exist, init to all 0"
    P(Number) = XY(0, 0, 0, 0)
    OnErr GoTo 0
Fend

Function CheckToolSet(Number As Integer)
    OnErr GoTo ToolSetNotExit
    P51 = TLSet(Number)
    Exit Function
ToolSetNotExit:
    EClr
    TLSet Number, XY(0, 0, 0, 0)
    OnErr GoTo 0
    Exit Function
Fend

Function FromHomeToTakeMagnet As Boolean
    FromHomeToTakeMagnet = False
    
    If Not Check_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: check gripper failed at home"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: check gripper failed at home"
        Print "Check_Gripper failed at home, aborted"
        Exit Function
    EndIf
    If Not Open_Lid Then
        SPELCom_Event EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: open lid failed"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: open lid failed"
        Print "FromHomeToTakeMagnet: abort: open lid failed"
        Exit Function
    EndIf

    SetFastSpeed
    LimZ 0
    Tool 0
    Jump P1

    If g_FlagAbort Then
		Close_Lid
		Jump P0
        Exit Function
    EndIf

    ''take magnet
    Jump P3
    If g_LN2LevelHigh Then
        ''Wait 40    ''40 seconds the same as mount/dismount
        If g_IncludeStrip Then
			Move P* -Z(STRIP_PLACER_Z_OFFSET)
        EndIf
        For FHTTMWait = 1 To 40
            If g_FlagAbort Then
                Exit Function
            EndIf
            Wait 1
        Next
        Move P3
        ''check gripper again after cooling down
        If Not Check_Gripper Then
            Print "Check_Gripper failed after cooling down, aborting"
            SPELCom_Event EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: check gripper failed at cooling point"
            SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: check gripper failed at cooling point"
            Jump P1
            Close_Lid
            Jump P0
            MoveTongHome
            Exit Function
        EndIf
    EndIf

    If Not Open_Gripper Then
        Print "open gripper failed after cooling down, aborting"
        SPELCom_Event EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: open gripper failed at cooling point"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: open gripper failed at cooling point"
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Exit Function
    EndIf

    If g_FlagAbort Then
        Exit Function
    EndIf

    Move P6
    
    If Not CheckMagnet Then
		Exit Function
    EndIf

    Move P* +Z(20)

    If Not Close_Gripper Then
        Print "close gripper failed at holding magnet, aborting"
        SPELCom_Event EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: close gripper failed at magnet"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: close gripper failed at magnet"
        Move P6
        If Not Open_Gripper Then
            Print "open gripper failed at aborting from magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, "open gripper failed at aborting from magnet, need Reset"
            SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset"
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        Move P3
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Exit Function
    EndIf
    g_HoldMagnet = True
    FromHomeToTakeMagnet = True
Fend

Function DisplayToolSet(Tl As Integer)
    P51 = TLSet(Tl)
    Print #LOG_FILE_NO, "ToolSet[", Tl, "]=(", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print "ToolSet[", Tl, "]=(", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
Fend

Function VBGetLN2LevelHigh
    If g_LN2LevelHigh Then
        SPELCom_Return 1
    Else
        SPELCom_Return 0
    EndIf
Fend

Function VBSetAbort
    g_FlagAbort = True
    SPELCom_Return 0
Fend

Function VBClearAbort
    g_FlagAbort = False
    SPELCom_Return 0
Fend

Function Recovery
    Tool 0
    LimZ 0
    SetFastSpeed
	
    If isCloseToPoint(0) Or isCloseToPoint(1) Then
        Jump P0
        Close_Lid
        Exit Function
    EndIf

    If Not g_SafeToGoHome Then
        g_RunResult$ = "not safe to go home"
        SPELCom_Return 1
        Exit Function
    EndIf
    If g_HoldMagnet Then
        Move P* :Z(g_Jump_LimZ_LN2)
        Move P6 :Z(g_Jump_LimZ_LN2)
        Move P6 +Z(20)
        ''if we cannot open gripper, we will stop right here, not go home
        g_SafeToGoHome = False
        If Not Open_Gripper Then
            g_RunResult$ = "Recovery: Open_Gripper Failed, holding magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        Move P6
        Move P3
    EndIf
    MoveTongHome
    SPELCom_Return 0
Fend



''only used when it is in free space at beginning
Function QuickCutMiddle(ByVal forceName As Integer)

    ''InitForceConstants
    
    forceName = Abs(forceName)

    'Save old position'
    GetCurrentPosition CMInitP()

    'Find out current Force situation
    'It maybe out of our +-g_ThresholdTZ, may be within
    CMInitForce = ReadForce(forceName)
    Print "Init position ", 
    PrintPosition CMInitP()
    Print " force: ", CMInitForce

    CMThreshold = GetForceThreshold(forceName)
    ''CMThreshold = Abs(CMThreshold) ''no need, we already Abs(forceName)
    GetCutMiddleData forceName, CMScanRange, CMNumSteps

    If Not ForceTouch(forceName, CMScanRange, True) Then
        Print "ForceTouch failed, give up"
        Print #LOG_FILE_NO, "ForceTouch failed, give up"
        GenericMove CMInitP(), False
        Exit Function
    EndIf
    GetCurrentPosition CMPlusP()

    GenericMove CMInitP(), False

    If Not ForceTouch(-forceName, CMScanRange, True) Then
        Print "ForceTouch failed, give up"
        Print #LOG_FILE_NO, "ForceTouch failed, give up"
        GenericMove CMInitP(), False
        Exit Function
    EndIf
    GetCurrentPosition CMMinusP()

    'calculate the perfect position'
    ''middle of the minus and plus is safer than linear interpolate
    For tmp_PIndex = 1 To 4
        CMFinalP(tmp_PIndex) = (CMMinusP(tmp_PIndex) + CMPlusP(tmp_PIndex)) / 2
    Next
    GenericMove CMFinalP(), False
    
    CMPlusForce = ReadForce(forceName)

    Print "CutMiddle ", forceName, 
    Print "position moved from ", 
    PrintPosition CMInitP()
    Print " to ", 
    PrintPosition CMFinalP()
    Print ", force changed from ", CMInitForce, " to ", CMPlusForce

    Print #LOG_FILE_NO, "CutMiddle ", forceName, 
    Print #LOG_FILE_NO, "position moved from ", 
    LogPosition CMInitP()
    Print #LOG_FILE_NO, " to ", 
    LogPosition CMFinalP()
    Print #LOG_FILE_NO, ", force changed from ", CMInitForce, " to ", CMPlusForce
Fend

Function SavePointHistory(ByVal Number As Integer, ByVal Cnt As Integer)
    
    SPHFileName$ = CurDrive$ + ":\EpsonRC\projects\try\PointHistory"
    If Not FolderExists(SPHFileName$) Then
        MkDir SPHFileName$
    EndIf
    
    SPHFileName$ = SPHFileName$ + "\P" + Str$(Number) + ".csv"
    
    If FileExists(SPHFileName$) Then
        AOpen SPHFileName$ As #POINT_FILE_NO
    Else
        WOpen SPHFileName$ As #POINT_FILE_NO
        Print #POINT_FILE_NO, "Name,X,Y,Z,U,CAL_COUNT,TimeStamp"
    EndIf
    Print #POINT_FILE_NO, "P" + Str$(Number), ",", CX(P(Number)), ",", CY(P(Number)), ",", CZ(P(Number)), ",", CU(P(Number)), ",", Cnt, ",", Date$, " ", Time$
    Close #POINT_FILE_NO
Fend

Function SaveToolSetHistory(ByVal Number As Integer, ByVal Cnt As Integer)
    
    SPHFileName$ = CurDrive$ + ":\EpsonRC\projects\try\PointHistory"
    If Not FolderExists(SPHFileName$) Then
        MkDir SPHFileName$
    EndIf
    
    SPHFileName$ = SPHFileName$ + "\TLSET" + Str$(Number) + ".csv"
    
    If FileExists(SPHFileName$) Then
        AOpen SPHFileName$ As #POINT_FILE_NO
    Else
        WOpen SPHFileName$ As #POINT_FILE_NO
        Print #POINT_FILE_NO, "Name,X,Y,Z,U,CAL_COUNT,TimeStamp"
    EndIf
    P51 = TLSet(Number)
    Print #POINT_FILE_NO, "TLSET" + Str$(Number), ",", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ",", Cnt, ",", Date$, " ", Time$
    Close #POINT_FILE_NO
Fend

Function SetVeryFastSpeed
    Accel 30, 30, 30, 30, 30, 30
    Speed 5
    
    AccelS 200
    SpeedS 50
Fend

Function Open_Lid As Boolean
#ifdef NO_DEWAR_LID
   	Open_Lid = True
#else
    On OUT_LID_OPEN
    Wait Sw(12) = 1, 6
    If TW = 1 Then
    	Print "Open lid failed"
    	Open_Lid = False
    Else
    	Open_Lid = True
    EndIf
#endif
Fend

Function Close_Lid As Boolean
#ifdef NO_DEWAR_LID
   	Close_Lid = True
#else
    Off OUT_LID_OPEN
    Wait Sw(11) = 1, 6
    If TW = 1 Then
    	Print "Close lid failed"
    	Close_Lid = False
    Else
    	Close_Lid = True
    EndIf
#endif
Fend

Function Open_Gripper As Boolean
    Off 1
    Wait Sw(8) = 1, 2
    If TW = 1 Then
    	Print "Open gripper failed"
    	Open_Gripper = False
    Else
    	Open_Gripper = True
    EndIf
Fend

Function Close_Gripper As Boolean
    On 1
    Wait Sw(9) = 1, 2
    If TW = 1 Then
    	Print "Close gripper failed"
    	Close_Gripper = False
    Else
    	Close_Gripper = True
    EndIf
Fend

Function Check_Gripper As Boolean
    Check_Gripper = False

    ''Check_Gripper
    If Not Close_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "abort: failed to close gripper"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "abort: failed to close gripper"
        Exit Function
    EndIf
    If Not Open_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "abort: failed to open gripper"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "abort: failed to open gripper"
        Exit Function
    EndIf
    If Not Close_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "abort: failed to close gripper"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "abort: failed to close gripper"
        Exit Function
    EndIf
    
    Check_Gripper = True
Fend

Function ForceResetAndCheck As Boolean
    Force_Calibrate
    ForceResetAndCheck = ForceCheck
Fend

Function ForceCheck As Boolean
	ForceCheck = True
	FCKAgain = False
    ReadForces FCheck()
    For FCKIndex = 1 To 6
        If Abs(FCheck(FCKIndex)) > 5 * GetTouchMin(FCKIndex) Then
        	FCKAgain = True
        EndIf
    Next
    
    If Not FCKAgain Then
    	Exit Function
    EndIf

    Wait TIME_WAIT_BEFORE_RESET
    Force_Calibrate
    ReadForces FCheck()
    For FCKIndex = 1 To 6
        If Abs(FCheck(FCKIndex)) > 5 * GetTouchMin(FCKIndex) Then
            g_RunResult$ = "force sensor reading bad, please retry later"
            Print g_RunResult$, " force: ", FCKIndex, "=", FCheck(FCKIndex), " exceed: ", 5 * GetTouchMin(FCKIndex)
            SPELCom_Event EVTNO_CAL_MSG, "abort: force sensor bad: force(", FCKIndex, ")=", FCheck(FCKIndex), "right after reset"
            SPELCom_Event EVTNO_UPDATE, "abort: force sensor bad: force(", FCKIndex, ")=", FCheck(FCKIndex), "right after reset"
            ForceCheck = False
        EndIf
    Next
Fend

Function ForceChangeCheck(forceName As Integer, distance As Real, prevForce As Real, curForce As Real) As Boolean
	ForceChangeCheck = False
    distance = Abs(distance)
    forceName = Abs(forceName)

    If distance <= 0.0001 Then
        distance = 1
    EndIf

    FCCRate = Abs(curForce - prevForce) / distance

    Select Abs(forceName)
    Case FORCE_ZFORCE
        FCCStandord = g_RateFZ
    Case FORCE_XTORQUE
        FCCStandord = g_RateTX
    Case FORCE_YTORQUE
        FCCStandord = g_RateTY
    Case FORCE_ZTORQUE
        FCCStandord = g_RateTZ
    Default
        Exit Function
    Send
    
    ''check whether the change is too big to be true
    If FCCRate > (10 * FCCStandord) Then
        g_RunResult$ = "force sensor reading bad, check cable"
        SPELCom_Event EVTNO_CAL_MSG, "abort: force sensor bad: rate ", FCCRate, " too big for", forceName
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "abort: force sensor bad: rate ", FCCRate, " too big for", forceName
        Print g_RunResult$, " forcename=", forceName, " rate=", FCCRate, " exceed 10*", FCCStandord
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_ABORT
        ''Motor Off
        ''Quit All
        Exit Function
    EndIf
    
    ''check force value
    If Abs(prevForce) > 100 Or Abs(curForce) > 100 Then
        g_RunResult$ = "too strong force, check cable"
        SPELCom_Event EVTNO_CAL_MSG, "abort: force too strong, may be cable broken"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "abort: force too strong, may be cable broken"
        Print "too strong force, shutdown. prevF=", prevForce, " curF=", curForce
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_ABORT
        ''Motor Off
        ''Quit All
        Exit Function
    EndIf
	ForceChangeCheck = True
Fend

''check if magnet is really there
''should be called only when holding magnet
Function CheckMagnet As Boolean
	CheckMagnet = False

	CKMGripperClosed = Oport(1)

    If CKMGripperClosed = 0 Then
		If Not Close_Gripper Then
			Print "close gripper failed at checking magnet, aborting"
			SPELCom_Event EVTNO_CAL_MSG, "CheckManget: close gripper failed"
			SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "CheckManget: close gripper failed"

			If Not Open_Gripper Then
				Print "open gripper failed at aborting from magnet, need Reset"
				SPELCom_Event EVTNO_CAL_MSG, "open gripper failed at aborting from magnet, need Reset"
				SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset"
				g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
				g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
				Motor Off
				Quit All
			EndIf
			Move P3
			Jump P1
			Close_Lid
			Jump P0
			MoveTongHome
			Exit Function
		EndIf
	EndIf

    Wait TIME_WAIT_BEFORE_RESET
	If ForceResetAndCheck Then
	    TongMove DIRECTION_MAGNET_TO_CAVITY, 0.5, False
		CKMForce = ReadForce(FORCE_YTORQUE)
		TongMove DIRECTION_CAVITY_TO_MAGNET, 0.5, False
	
		If Abs(CKMForce) >= g_FCheckMagnet Then
			CheckMagnet = True
		Else
			g_RunResult$ = "maybe dumpbell not in cradle"
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
			SPELCom_Event EVTNO_WARNING, g_RunResult$
			SPELCom_Event EVTNO_UPDATE, g_RunResult$
		EndIf
	EndIf
	
    If CKMGripperClosed = 0 Then
		If Not Open_Gripper Then
			Print "open gripper failed at end of check magnet, need Reset"
			SPELCom_Event EVTNO_CAL_MSG, "open gripper failed at end of checking magnet, need Reset"
			SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at end of checking magnet, need Reset"
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
			g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
			Motor Off
			Quit All
		EndIf
	EndIf
	
	If Not CheckMagnet Then
		If Not Open_Gripper Then
			Print "open gripper failed after check magnet failed, need Reset"
			SPELCom_Event EVTNO_CAL_MSG, "open gripper failed after check magnet failed, need Reset"
			SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed after check magnet failed, need Reset"
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
			g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
			Motor Off
			Quit All
		EndIf
		Move P3
		Jump P1
		Close_Lid
		Jump P0
		MoveTongHome
		Exit Function
	EndIf
Fend
Function NarrowAngle(angle As Real) As Real
	NarrowAngle = angle
	While NarrowAngle <= -180.0
		NarrowAngle = NarrowAngle + 360.0
	Wend
	While NarrowAngle > 180.0
		NarrowAngle = NarrowAngle - 360.0
	Wend
Fend


