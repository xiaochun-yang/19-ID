#include "robotdefs.inc"

''==========================================================
''MODULE MAGNET CALIBRATION
''==========================================================

'Min step: currently only used in Z-FZ'
Real m_MinZStep

''variables used in several functions in post calibration
Boolean m_AllOK
Boolean m_IgnoreFZForNow

'' any tmp_ prefix means this varible cannot cross function call
''they can be used by any function.
Integer tmp_PIndex
Real tmp_Real
Real tmp_Real2
Real tmp_Real3
Real tmp_DX
Real tmp_DY
Real tmp_DZ
Real tmp_DU

''==========================================================
'' LOCAL varibles: because it crashes system when there are
'' a lot of local variables, many local variables are moved here
''=========================================================
Integer PCCalledTimes(6)    ''how many times each "reduce" function called
Real Old_U4MagnetHolder
Boolean PCCBottomTouched        ''dumbbell touched bottom
                                ''this is used to deal with dumbbell may not touch
                                ''bottom and with a very small FZ.

Real MagLevelError
Real PostLevelError
String Magnet_Warning$


''select force to reduce
Real weightFactor(6)
Real forceWeight(6)
Integer SForceIndex
Integer NumToSelect

''ReduceFZ
Real RFZOldZ
Real RFZOldFZ
Real RFZNewZ
Real RFZNewFZ
Integer RFZStepStart
Integer RFZStepTotal

''FindZPosition
Real FZPOldZ
Real FZPNewZ
Real FZPOldFZ
Real FZPONewZMinus  'Z at -g_ThresholdTZ'
Real FZPFZAtMinus
Real FZPZPerfect
Real FZPNewFZ
Real FZPScanRange
Real FZPThreshold
Integer FZPStepStart
Integer FZPStepTotal


''pikcer touch cradle
Real PKTSRange
Real PKTSX1
Real PKTSX2
Real PKTSY1
Real PKTSY2
Real PKTSOldAngle
Integer PKTSStepStart
Integer PKTSStepTotal

''PickerCalibration
Real PKCInitX
Real PKCInitY
Real PKCInitZ
Real PKCInitU

Real m_MAPAStartX
Real m_MAPAStartY

Real PKCRange

Integer PKCStepStart
Integer PKCStepTotal

''good for placer cal
Real ISP16IdealX
Real ISP16IdealY
Real ISP16IdealZ
Real ISP16IdealU

Real ISP16DX
Real ISP16DY
Real ISP16DZ
Real ISP16DU

''PlacerCalibration
Real CPCInitX
Real CPCInitY
Real CPCInitZ
Real CPCInitU
Real CPCFinalX
Real CPCFinalY
Real CPCFinalZ
Real CPCFinalU
Real CPCMiddleX
Real CPCMiddleY
Real CPCMiddleZ
Real CPCMiddleU
Real CPCStepSize(4)
Integer CPCStepStart
Integer CPCStepTotal

''ABCThetaToToolSet
Real TSX
Real TSY
Real TSZ
Real TSU
Real TSTWX  ''twist off center
Real TSTWY

''CalculateToolset
Real TSa
Real TSb
Real TSc
Real TStheta
Real TSAdjust
Real CVa
Real CVb

''find magnet
Real FMLeftX
Real FMLeftY
Real FMRightX
Real FMRightY

Real FMFinalX
Real FMFinalY
Real FMFinalZ
Real FMFinalU
Real FMDX
Real FMDY
Real FMDistance
Integer FMStepStart
Integer FMStepTotal
Integer FMWait

''parallel grippers and cradle (in find magnet)
Real PGCOldU
Real PGCOldForce
Real PGCGoodForce
Real PGCGoodU
Real PGCNewU
Real PGCNewForce
Integer PGCStepIndex
Integer PGCDirection
Integer PGCScanIndex
Integer PGCNumSteps
Real PGCStepSize
Integer StepIndex

''pull out Z (in find magnet)
Real POZOldX
Real POZOldY
Real POZOldZ
Real StepSize

''post calibration
''This function will try to reduce FZ, TX, TY ,TZ
Real PCCurrentForces(6)
Integer PCRepeatIndex
Integer forceToReduce
Integer PCPreFTR
Integer PCCntPreFTR

Real PCOldForces(6)
Real PCOldPosition(4)
Real PCPushX
Real PCPushY

Integer PCStepStart
Integer PCStepTotal


''FineTuneToolSet
Real FTTSDestX
Real FTTSDestY
Real FTTSX(2)
Real FTTSY(2)
Real FTTSA
Real FTTSB
Real FTTSC
Real FTTSTheta
Real FTTSIndex
Real FTTSBMC
Real FTTSDeltaU
Real FTTSAdjust
Real FTTSZ

Integer FTTStepStart
Integer FTTStepTotal

Real FTTScaleF1
Real FTTScaleF2


''DiffPickerPlacer
Real DPPPickerZ
Real DPPPlacerZ

''VB Wrapper
String VBMCTokens$(0)
Integer VBMCArgC

''CheckRigidness
Real CKRNF1
Real CKRNF2

Function MagnetCalibration As Boolean
    MagnetCalibration = False
    ''init result
    Magnet_Warning$ = ""
    g_RunResult$ = ""
    
    InitForceConstants

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    g_HoldMagnet = False
    
    ''send message
    SPELCom_Event EVTNO_CAL_MSG, "toolset calibration"
    SPELCom_Event EVTNO_CAL_STEP, "0 of 100"

    If g_IncludeFindMagnet Then
        SPELCom_Event EVTNO_CAL_MSG, "find magnet"
        ''find magnet
        g_CurrentSteps = 0
        g_Steps = 20
        If Not FindMagnet() Then
            Print "Find magnet failed"
            g_RunResult$ = "Find magnet failed " + g_RunResult$
            SPELCom_Return 1
            SPELCom_Event EVTNO_CAL_MSG, "find magnet failed"
            SPELCom_Event EVTNO_LOG_SEVERE, g_RunResult$
            SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
            Exit Function
        EndIf
        SetFastSpeed
        Move P* +Z(20)
        If Not Close_Gripper Then
            Print "close gripper failed at holding magnet after finding it, aborting"
            SPELCom_Event EVTNO_CAL_MSG, "close gripper failed after find magnet"
            SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "close gripper failed at magnet after finding it"
            Move P6
            If Not Open_Gripper Then
                Print "open gripper failed at aborting from magnet after finding manget, NEED Reset"
                SPELCom_Event EVTNO_CAL_MSG, "open gripper failed in aborting"
                SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, NEED Reset"
                g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
                g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
                Motor Off
                Quit All
            EndIf
            Move P3
            LimZ 0
            Jump P1
            Close_Lid
            Jump P0
            MoveTongHome
            ''not need recovery
            g_SafeToGoHome = False
            Exit Function
        EndIf
        g_HoldMagnet = True
    Else
        SPELCom_Event EVTNO_CAL_MSG, "go to dumbbell post"
        If Not FromHomeToTakeMagnet Then
            g_RunResult$ = "FromHomeToTakeMagnet failed " + g_RunResult$
            Print g_RunResult$
            SPELCom_Return 1
            SPELCom_Event EVTNO_CAL_MSG, "failed in FromHomeToTakeMagnet"
            SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
            Exit Function
        EndIf
    EndIf
    
        
    ''reset force sensor
    SetFastSpeed
    Wait TIME_WAIT_BEFORE_RESET * 2
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    Move P* -Z(15)
    SetVerySlowSpeed
    Move P* -Z(3)
    
    ''continue with calibration    
    SPELCom_Event EVTNO_CAL_MSG, "dumbbell calibration"
    If g_IncludeFindMagnet Then
        SPELCom_Event EVTNO_CAL_STEP, "20 of 100"
        g_CurrentSteps = 20
        g_Steps = 30
    Else
        SPELCom_Event EVTNO_CAL_STEP, "10 of 100"
        g_CurrentSteps = 10
        g_Steps = 33
    EndIf
    If Not PostCalibration() Then
        g_RunResult$ = "magnet holder calibration failed"
        Print g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, "dumbbell cal failed"
        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
        SPELCom_Return 2
        Exit Function
    EndIf
    
    If g_Quick Then
        If Abs(CX(P6) - CX(P86)) < 0.1 And Abs(CY(P6) - CY(P86)) < 0.3 And Abs(CZ(P6) - CZ(P86)) < 0.1 Then
            MoveTongHome
            
            MagnetCalibration = True
            g_RunResult$ = "normal OK quick"
            SPELCom_Return 0
            SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
            SPELCom_Event EVTNO_CAL_MSG, "toolset cal done with quick option"
            Exit Function
        EndIf
    EndIf

    ''picker calibration    
    If g_IncludeFindMagnet Then
        SPELCom_Event EVTNO_CAL_STEP, "50 of 100"
        g_CurrentSteps = 50
        g_Steps = 15
    Else
        SPELCom_Event EVTNO_CAL_STEP, "43 of 100"
        g_CurrentSteps = 43
        g_Steps = 18
    EndIf
    SPELCom_Event EVTNO_CAL_MSG, "picker calibration"
    If Not PickerCalibration() Then
        g_RunResult$ = "picker calibration failed"
        Print g_RunResult$
        SPELCom_Return 3
        SPELCom_Event EVTNO_CAL_MSG, "picker cal failed"
        SPELCom_Event EVTNO_LOG_ERROR, "picker cal failed"
        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
        Exit Function
    EndIf
    If g_IncludeFindMagnet Then
        SPELCom_Event EVTNO_CAL_STEP, "65 of 100"
        g_CurrentSteps = 65
        g_Steps = 12
    Else
        SPELCom_Event EVTNO_CAL_STEP, "61 of 100"
        g_CurrentSteps = 43
        g_Steps = 14
    EndIf

    SPELCom_Event EVTNO_CAL_MSG, "placer calibration"
    If Not PlacerCalibration() Then
        g_RunResult$ = "placer calibration failed"
        Print g_RunResult$
        SPELCom_Return 4
        SPELCom_Event EVTNO_CAL_MSG, "placer cal failed"
        SPELCom_Event EVTNO_LOG_ERROR, "placer cal failed"
        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
        Exit Function
    EndIf

    If Not CalculateToolset() Then
        g_RunResult$ = "toolset failed"
        Print g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, "toolset rough cal failed"
        SPELCom_Return 5
    EndIf

    If g_IncludeFindMagnet Then
        SPELCom_Event EVTNO_CAL_STEP, "77 of 100"
        g_CurrentSteps = 77
        g_Steps = 18
    Else
        SPELCom_Event EVTNO_CAL_STEP, "75 of 100"
        g_CurrentSteps = 75
        g_Steps = 20
    EndIf
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset"
    If Not FineTuneToolSet() Then
        g_RunResult$ = "fine tune toolset failed"
        Print g_RunResult$
        SPELCom_Return 6
        SPELCom_Event EVTNO_CAL_MSG, "toolset fine cal failed"
        SPELCom_Event EVTNO_LOG_ERROR, "toolset fine cal failed"
        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
        Exit Function
    EndIf

    If g_IncludeStrip Then
	    SPELCom_Event EVTNO_CAL_STEP, "95 of 100"
	    g_CurrentSteps = 95
	    g_Steps = 5
	    SPELCom_Event EVTNO_CAL_MSG, "strip calibration"
	    If Not StripCalibration() Then
	        g_RunResult$ = "strip calibration failed"
	        Print g_RunResult$
	        SPELCom_Return 7
	        SPELCom_Event EVTNO_CAL_MSG, "strip cal failed"
	        SPELCom_Event EVTNO_LOG_ERROR, "strip cal failed"
	        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
	        Exit Function
	    EndIf
	EndIf

    SPELCom_Event EVTNO_CAL_MSG, "moving home"
    SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
    MoveTongHome
    
    MagnetCalibration = True
    g_RunResult$ = "normal OK"
	g_TS_Toolset$ = Date$ + " " + Time$
    SPELCom_Return 0
    SPELCom_Event EVTNO_CAL_MSG, "toolset cal done"
Fend

''09/02/03 Jinhu
''magnet is pushed to negative Y direction to hit the wall.
''This is because there is 0.5mm freedom in Y direction.
''We want the magnet move to one end, not seat in the middle of
''freedom.
Function PostCalibration As Boolean

    Tool 0

    PostCalibration = False
    
    PCStepStart = g_CurrentSteps
    PCStepTotal = g_Steps

    ''log file
    g_FCntPost = g_FCntPost + 1
    WOpen "PostCal" + Str$(g_FCntPost) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "PostCalibration at ", Date$, " ", Time$

    PCCalledTimes(0) = 0         ''this will be the FindZPosition call
    PCCalledTimes(1) = 0
    PCCalledTimes(2) = 0
    PCCalledTimes(3) = 0
    PCCalledTimes(4) = 0
    PCCalledTimes(5) = 0
    PCCalledTimes(6) = 0

    InitForceConstants
    Init_Magnet_Constants
    PCCBottomTouched = False
    m_IgnoreFZForNow = False

    Old_U4MagnetHolder = g_U4MagnetHolder
    g_U4MagnetHolder = CU(P*)
    ''set to CU(P6) if not in calibration

    g_OnlyAlongAxis = True
    ''within this tolerance, we will change X only to reduce TY
    '' and change Y only to reduce TX

    SetupTSForMagnetCal
   
    m_AllOK = False

    ''save old values to print at the end
    PCOldPosition(1) = CX(P*)
    PCOldPosition(2) = CY(P*)
    PCOldPosition(3) = CZ(P*)
    PCOldPosition(4) = CU(P*)
    ReadForces PCOldForces()

    'max repeat 12: we have 4 independant variables to reduce'
    'each will get 3 times average'

    ''For PCRepeatIndex = 1 To MAX_POST_CAL_STEP
    PCRepeatIndex = 1
    Do
        'read current forces'
        ReadForces PCCurrentForces()
        Print "step ", PCRepeatIndex
        Print " current forces: "
        PrintForces PCCurrentForces()
        
        ''log it
        Print #LOG_FILE_NO, "step ", PCRepeatIndex, " ", Date$, " ", Time$
        Print #LOG_FILE_NO, " current forces: "
        LogForces PCCurrentForces()

        If g_FlagAbort Then
            If Not Open_Gripper Then
                g_RunResult$ = "Post Cal: aborting: Open_Gripper Failed, holding magnet, need Reset"
                SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
                SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
                Print g_RunResult$
                g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
                g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
                Motor Off
                Quit All
            EndIf
            SetFastSpeed
		    TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False
            g_HoldMagnet = False
            g_SafeToGoHome = True
            Print #LOG_FILE_NO, " aborted by user"
            Close #LOG_FILE_NO
            Exit Function
        EndIf
        

        'check whether it is already in calbrated position'
        forceToReduce = SelectForceToReduce(PCCurrentForces())

        If g_AtLeastOnce And forceToReduce = 0 And PCCalledTimes(0) <> 0 Then
            If PCCalledTimes(FORCE_XTORQUE) = 0 Then
                Print "ADD call for XTorque"
                forceToReduce = FORCE_XTORQUE
            ElseIf PCCalledTimes(FORCE_YTORQUE) = 0 Then
                Print "ADD call for YTorque"
                forceToReduce = FORCE_YTORQUE
            ElseIf PCCalledTimes(FORCE_ZTORQUE) = 0 Then
                Print "ADD call for ZTorque"
                forceToReduce = FORCE_ZTORQUE
            EndIf
        EndIf

        ''compare with previous one
        If forceToReduce = PCPreFTR Then
            If forceToReduce = 0 Then
                ''check weather last time it touched bottom
                If PCCBottomTouched Then
                    PostCalibration = True
                    Exit Do
                EndIf
            Else
                PCCntPreFTR = PCCntPreFTR + 1
                If PCCntPreFTR > 1 Then
                    Print "failed, try to reduce ", forceToReduce, " in a row"
                    Print #LOG_FILE_NO, "failed, try to reduce ", forceToReduce, " in a row"
                    Close #LOG_FILE_NO
                    Exit Function
                EndIf
                ''reset the force sensor
                   ResetForceSensor    ''this will move up 10mm more and back
            EndIf
        Else
            PCPreFTR = forceToReduce
            PCCntPreFTR = 0
        EndIf
        
        g_Steps = PCStepTotal / MAX_POST_CAL_STEP
        g_CurrentSteps = PCStepStart + (PCRepeatIndex - 1) * PCStepTotal / MAX_POST_CAL_STEP
                        
        Select forceToReduce
        Case 0
            SPELCom_Event EVTNO_CAL_MSG, "dumbbell: find Z"
            PCCalledTimes(0) = PCCalledTimes(0) + 1
            Print "Find Z Position"
            Print #LOG_FILE_NO, "Find Z Position"
            PCCBottomTouched = FindZPosition()
        Case FORCE_ZFORCE
            SPELCom_Event EVTNO_CAL_MSG, "dumbbell: reduce FZ"
            PCCalledTimes(FORCE_ZFORCE) = PCCalledTimes(FORCE_ZFORCE) + 1
            Print "reduce FZ"
            Print #LOG_FILE_NO, "reduce FZ"
            ReduceFZ
        Case FORCE_XTORQUE
            SPELCom_Event EVTNO_CAL_MSG, "dumbbell: cut middle XTORQUE"
            PCCalledTimes(FORCE_XTORQUE) = PCCalledTimes(FORCE_XTORQUE) + 1
            Print "reduce TX"
            Print #LOG_FILE_NO, "reduce TX"
            g_Dumbbell_Free_Y = Abs(ForcedCutMiddle(FORCE_XTORQUE))
            If g_Dumbbell_Free_Y > ACCPT_THRHLD_MAGNET_FREE_Y Then
				Print "dumbbell has too big Y freedom in cradle ", g_Dumbbell_Free_Y
				Print #LOG_FILE_NO, "dumbbell has too big Y freedom in cradle ", g_Dumbbell_Free_Y
		        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "dumbbell has too big Y freedom in cradle ", g_Dumbbell_Free_Y
            EndIf
        Case FORCE_YTORQUE
            SPELCom_Event EVTNO_CAL_MSG, "dumbbell: cut middle YTORQUE"
            PCCalledTimes(FORCE_YTORQUE) = PCCalledTimes(FORCE_YTORQUE) + 1
            Print "reduce TY"
            Print #LOG_FILE_NO, "reduce TY"
            ForcedCutMiddle FORCE_YTORQUE
        Case FORCE_ZTORQUE
            SPELCom_Event EVTNO_CAL_MSG, "dumbbell: cut middle ZTORQUE"
            PCCalledTimes(FORCE_ZTORQUE) = PCCalledTimes(FORCE_ZTORQUE) + 1
            Print "reduce TZ"
            Print #LOG_FILE_NO, "reduce TZ"
            Tool 3
            ForcedCutMiddle FORCE_ZTORQUE
            Tool 0
        Send
        g_CurrentSteps = PCStepStart + PCRepeatIndex * PCStepTotal / MAX_POST_CAL_STEP
        SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
        PCRepeatIndex = PCRepeatIndex + 1
    Loop Until PCRepeatIndex > MAX_POST_CAL_STEP
    If PCRepeatIndex > 12 Then
        Print "FAILED: reached max retry before got the result"
        Print #LOG_FILE_NO, "FAILED: reached max retry before got the result"
    EndIf
 
    Print "reduce functions called times:"
    Print "FZ: ", PCCalledTimes(FORCE_ZFORCE)
    Print "TX: ", PCCalledTimes(FORCE_XTORQUE)
    Print "TY: ", PCCalledTimes(FORCE_YTORQUE)
    Print "TZ: ", PCCalledTimes(FORCE_ZTORQUE)
    Print "Find Z Postion called ", PCCalledTimes(0)

    ReadForces PCCurrentForces()
    Print "==================================================================="
    Print "Forces changes:"
    Print "FX: ", PCOldForces(1), " to ", PCCurrentForces(1)
    Print "FY: ", PCOldForces(2), " to ", PCCurrentForces(2)
    Print "FZ: ", PCOldForces(3), " to ", PCCurrentForces(3)
    Print "TX: ", PCOldForces(4), " to ", PCCurrentForces(4)
    Print "TY: ", PCOldForces(5), " to ", PCCurrentForces(5)
    Print "TZ: ", PCOldForces(6), " to ", PCCurrentForces(6)
    Print "==================================================================="
    Print "Position changes"
    Print "X: ", PCOldPosition(1), " to ", CX(P*)
    Print "Y: ", PCOldPosition(2), " to ", CY(P*)
    Print "Z: ", PCOldPosition(3), " to ", CZ(P*)
    Print "U: ", PCOldPosition(4), " to ", CU(P*)
    Print "==================================================================="
    

    Print #LOG_FILE_NO, "PostCalibration end at ", Date$, " ", Time$
    Print #LOG_FILE_NO, "reduce functions called times:"
    Print #LOG_FILE_NO, "FZ: ", PCCalledTimes(FORCE_ZFORCE)
    Print #LOG_FILE_NO, "TX: ", PCCalledTimes(FORCE_XTORQUE)
    Print #LOG_FILE_NO, "TY: ", PCCalledTimes(FORCE_YTORQUE)
    Print #LOG_FILE_NO, "TZ: ", PCCalledTimes(FORCE_ZTORQUE)
    Print #LOG_FILE_NO, "Find Z Postion called ", PCCalledTimes(0)
    Print #LOG_FILE_NO, "==================================================================="
    Print #LOG_FILE_NO, "Forces changes:"
    Print #LOG_FILE_NO, "FX: ", PCOldForces(1), " to ", PCCurrentForces(1)
    Print #LOG_FILE_NO, "FY: ", PCOldForces(2), " to ", PCCurrentForces(2)
    Print #LOG_FILE_NO, "FZ: ", PCOldForces(3), " to ", PCCurrentForces(3)
    Print #LOG_FILE_NO, "TX: ", PCOldForces(4), " to ", PCCurrentForces(4)
    Print #LOG_FILE_NO, "TY: ", PCOldForces(5), " to ", PCCurrentForces(5)
    Print #LOG_FILE_NO, "TZ: ", PCOldForces(6), " to ", PCCurrentForces(6)
    Print #LOG_FILE_NO, "==================================================================="
    Print #LOG_FILE_NO, "Position changes"
    Print #LOG_FILE_NO, "X: ", PCOldPosition(1), " to ", CX(P*)
    Print #LOG_FILE_NO, "Y: ", PCOldPosition(2), " to ", CY(P*)
    Print #LOG_FILE_NO, "Z: ", PCOldPosition(3), " to ", CZ(P*)
    Print #LOG_FILE_NO, "U: ", PCOldPosition(4), " to ", CU(P*)
    Print #LOG_FILE_NO, "==================================================================="

    ''save the result
    CheckPoint 6
    If PostCalibration Then
        P86 = P6
        P6 = P*
        Print "P6 moved from (", CX(P86), ", ", CY(P86), ", ", CZ(P86), ", ", CU(P86), ") ", 
        Print "to (", CX(P6), ", ", CY(P6), ", ", CZ(P6), ", ", CU(P6), ") "

        Print #LOG_FILE_NO, "P6 moved from (", CX(P86), ", ", CY(P86), ", ", CZ(P86), ", ", CU(P86), ") ", 
        Print #LOG_FILE_NO, "to (", CX(P6), ", ", CY(P6), ", ", CZ(P6), ", ", CU(P6), ") "
        
        SPELCom_Event EVTNO_UPDATE, "Old P6 (", CX(P86), ", ", CY(P86), ", ", CZ(P86), ", ", CU(P86), ")"
        SPELCom_Event EVTNO_UPDATE, "New P6 (", CX(P6), ", ", CY(P6), ", ", CZ(P6), ", ", CU(P6), ")"
        
        ''P3 is 20 mm from P6: cooling point
        tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
        P3 = P6 +X(20 * Cos(tmp_Real)) +Y(20 * Sin(tmp_Real))
        ''P2 is above P3
        P2 = P3 :Z(-2)
        g_U4MagnetHolder = CU(P*)
    Else
        ''restore old preserved global
        g_U4MagnetHolder = Old_U4MagnetHolder
    EndIf

#ifdef PUSH_MAGNET_ASIDE
    If PostCalibration Then
        PCPushX = CX(P*)
        PCPushY = CY(P*)
        If Not ForceTouch(DIRECTION_CAVITY_TAIL, 1, True) Then
            Print "Failed in push magnet aside to reduce freedom in operation"
            Print #LOG_FILE_NO, "Failed in push magnet aside to reduce freedom in operation"
        EndIf
    
        Print "Push Magnet to one side, X, Y moved from (", PCPushX, ", ", PCPushY, ") to (", CX(P*), ", ", CY(P*), ")"
        Print #LOG_FILE_NO, "Push Magnet to one side, X, Y moved from (", PCPushX, ", ", PCPushY, ") to (", CX(P*), ", ", CY(P*), ")"

        CheckPoint 7
        Print "P7 moved from (", CX(P7), ", ", CY(P7), ", ", CZ(P7), ", ", CU(P7), ") ", 
        Print #LOG_FILE_NO, "P7 moved from (", CX(P7), ", ", CY(P7), ", ", CZ(P7), ", ", CU(P7), ") ", 
        P7 = P*
        Print "to (", CX(P7), ", ", CY(P7), ", ", CZ(P7), ", ", CU(P7), ") "
        Print #LOG_FILE_NO, "to (", CX(P7), ", ", CY(P7), ", ", CZ(P7), ", ", CU(P7), ") "
        
        Move P6

    EndIf
#endif''PUSH_MAGNET_ASIDE

#ifdef AUTO_SAVE_POINT
    If PostCalibration Then
        Print "saving points to file.....", 
        SavePoints "robot1.pnt"
        Print "done!!"
        SavePointHistory 6, g_FCntPost
    EndIf
#endif

    Close #LOG_FILE_NO
    If g_FlagAbort Then
        If Not Open_Gripper Then
            g_RunResult$ = "after Post Cal: user abort: Open_Gripper Failed, holding magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_LOG_SEVERE, g_RunResult$
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        SetFastSpeed
	    TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False
        g_HoldMagnet = False
        g_SafeToGoHome = True
    EndIf
Fend

'forces is array of (6), it is read only'
'The return will be [0,6]'
'0: means all forces are within minimum.'
'1-6, normally 3-6, means you should reduce that force first'
'It does not involve any hardware access'
''It checks XYZ torques first, if all of them are within minimun,
''then it will return 0 without checking FZ.
''Otherwise, it will include FZ to select the largest force to reduce
Function SelectForceToReduce(ByRef forces() As Real) As Integer

    'init weights for each force'
    weightFactor(FORCE_XFORCE) = 0 'ignore'
    weightFactor(FORCE_YFORCE) = 0 'ignore'
    weightFactor(FORCE_ZFORCE) = 4

    weightFactor(FORCE_XTORQUE) = 2
    weightFactor(FORCE_YTORQUE) = 3
    weightFactor(FORCE_ZTORQUE) = 16

    ''check torques frist
    SelectForceToReduce = 0
    NumToSelect = 0

    For SForceIndex = FORCE_XTORQUE To FORCE_ZTORQUE
        If Abs(forces(SForceIndex)) < GetForceMin(SForceIndex) Or weightFactor(SForceIndex) = 0 Then
            forceWeight(SForceIndex) = 0
        Else
            forceWeight(SForceIndex) = Abs(forces(SForceIndex)) * weightFactor(SForceIndex)
            SelectForceToReduce = SForceIndex
            NumToSelect = NumToSelect + 1
        EndIf
    Next

    ''if no torque, then return 0, the caller will call FindZPosition
    If NumToSelect = 0 Then Exit Function

    ''OK, we need to count in FZ now 
    ''ZFORCE is special: we compare with the threshold, not min
    If Not m_IgnoreFZForNow And forces(FORCE_ZFORCE) <= (0 - GetForceThreshold(FORCE_ZFORCE)) Then
        forceWeight(FORCE_ZFORCE) = Abs(forces(FORCE_ZFORCE)) * weightFactor(FORCE_ZFORCE)
        SelectForceToReduce = FORCE_ZFORCE
        NumToSelect = NumToSelect + 1
    Else
        forceWeight(FORCE_ZFORCE) = 0
    EndIf

    ''only 1 and it is not FZ
    If NumToSelect = 1 Then Exit Function


    'we have more than 1, so try to find the max weight'
    For SForceIndex = FORCE_XTORQUE To FORCE_ZTORQUE
        If forceWeight(SForceIndex) > forceWeight(SelectForceToReduce) Then SelectForceToReduce = SForceIndex
    Next
Fend

Function Init_Magnet_Constants
    m_MinZStep = 0.002 '20 microns'
Fend

Function ReduceFZ

    ''InitForceConstants
    ''Init_Magnet_Constants
    RFZStepStart = g_CurrentSteps
    RFZStepTotal = g_Steps

    RFZOldZ = CZ(P*)

    'Find out current FZ situation'
    RFZOldFZ = ReadForce(FORCE_ZFORCE)
    Print "Reduce FZ"
    Print "old Z", RFZOldZ, " oldFZ ", RFZOldFZ

    If RFZOldFZ <= 0 And RFZOldFZ > -g_MinFZ Then
        Print "no need to reduce FZ, already < -g_MinFZ"
        Print #LOG_FILE_NO, "no need to reduce FZ, already > -g_MinFZ"
        Exit Function
    EndIf

    g_Steps = RFZStepTotal / 2
    If Not ForceCross(FORCE_ZFORCE, -g_ThresholdFZ, g_MaxRangeZ, g_ZNumSteps, False) Then
        RFZNewZ = CZ(P*)
        RFZNewFZ = ReadForce(FORCE_ZFORCE)
        m_IgnoreFZForNow = True ''we will deal with it in FindZPosition when all other forces are reduced.
        Print "force sensor need reset, ignore FZ for now"
        Print #LOG_FILE_NO, "force sensor need reset, ignore FZ for now"
        Print "FZRisingCross ", -g_ThresholdFZ, "failed"
        Print #LOG_FILE_NO, "FZRisingCross ", -g_ThresholdFZ, "failed"
        Print "ReduceFZ, Z moved from ", RFZOldZ, " to ", RFZNewZ, ", FZ from ", RFZOldFZ, " to ", RFZNewFZ
        Print #LOG_FILE_NO, "ReduceFZ, Z moved from ", RFZOldZ, " to ", RFZNewZ, ", FZ from ", RFZOldFZ, " to ", RFZNewFZ
        Exit Function
    EndIf

    g_Steps = RFZStepTotal / 2
    g_CurrentSteps = FMStepStart + FMStepTotal / 2
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    ForceCross FORCE_ZFORCE, -g_MinFZ, 2 * m_MinZStep, 2, False
    
    RFZNewZ = CZ(P*)
    RFZNewFZ = ReadForce(FORCE_ZFORCE)

    Print "ReduceFZ, Z moved from ", RFZOldZ, " to ", RFZNewZ, ", FZ from ", RFZOldFZ, " to ", RFZNewFZ
    Print #LOG_FILE_NO, "ReduceFZ, Z moved from ", RFZOldZ, " to ", RFZNewZ, ", FZ from ", RFZOldFZ, " to ", RFZNewFZ
Fend


''This function should only be called when other forces are already close to 0
Function FindZPosition As Boolean
    
    FindZPosition = False
    FZPStepStart = g_CurrentSteps
    FZPStepTotal = g_Steps

    ''InitForceConstants
    ''Init_Magnet_Constants
    FZPOldZ = CZ(P*)

    'Find out current FZ situation'
    FZPOldFZ = ReadForce(FORCE_ZFORCE)
    Print "FindZPosition: old Z", FZPOldZ, " FZPOldFZ ", FZPOldFZ

    ''reset force sensor
    m_IgnoreFZForNow = False
    Move P* +Z(2)
    SPELCom_Event EVTNO_CAL_MSG, "dumbbell: resetting force sensor"
    ResetForceSensor    ''this will move up 10mm more and back
    g_Steps = FZPStepTotal / 2
    g_CurrentSteps = FZPStepStart + g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "dumbbell: touching bottom"
    FindZPosition = ForceTouch(-FORCE_ZFORCE, 10, True)    ''force down to TZTouchMin
    If Not FindZPosition Then
        Print "not bottomed this time, try next time"
        Print #LOG_FILE_NO, "not bottomed this time, try next time"
    Else
        Move P* +Z(0.05)
    EndIf
Fend

''this function will set placer's init x to a module variable'
Function PickerTouchSeat As Boolean

    ''InitForceConstants
    PKTSStepStart = g_CurrentSteps
    PKTSStepTotal = g_Steps
    
    PickerTouchSeat = False

    ''find init position to ping the holder of magnet
    ''derive init value from magnet transport P6
    ''some distance from the transport

    ''move from P6 to the init point
    ''open gripper
    If Not Open_Gripper Then
        g_RunResult$ = "OPen_Gripper failed in picker touch seat, need Reset"
        Print g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
        Motor Off
        Quit All
    EndIf

    ''move away from the post, the 20mm is safe buffer to turn the tong around
    SetFastSpeed
    ''Move P* -X(DISTANCE_FROM_SEAT + 20)
    TongMove DIRECTION_MAGNET_TO_CAVITY, DISTANCE_FROM_SEAT + SAFE_BUFFER_FOR_U_TURN, False

    g_HoldMagnet = False

    If Not Close_Gripper Then
        g_RunResult$ = "Close_Gripper failed in picker touch seat, aborting"
        Print g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, g_RunResult$
        MoveTongHome
        ''not need recovery
        g_SafeToGoHome = False
        Exit Function
    EndIf

    Wait 2 * TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at pickerTouchingSeat"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf

    Go P* -Z(35) -U(180)  ''lower arm so that cavity will be within the height of seat
                            ''rotate 180 so that cavity, not the magnet, will be close to seat
                            ''we take -180 not +180, because we want to arc in the future
                            ''between magnet position, picker position, placer position
    
    ''Move P* +X(20)
    TongMove DIRECTION_MAGNET_TO_CAVITY, SAFE_BUFFER_FOR_U_TURN, False
        
    SetVerySlowSpeed

    ''go to touch the seat
    ''in ideal situation, the distance detween cavity and seat is
    '' DISTANCE_FROM_SEAT + H_DISTANCE_CAVITY_TO_GRIPPER - 7.06(cavity radius) - 5(half of holder thickness
    '' we give some overshoot to make sure it will touch the seat
    PKTSRange = DISTANCE_FROM_SEAT + H_DISTANCE_CAVITY_TO_GRIPPER

    ''reset force sensor before moving for touch
    ForceCheck

    g_Steps = PKTSStepTotal / 2
    If Not ForceTouch(DIRECTION_MAGNET_TO_CAVITY, PKTSRange, True) Then
        Print "touch seat failed at placer side"
        Exit Function
    EndIf
    g_Steps = PKTSStepTotal / 2
    g_CurrentSteps = PKTSStepStart + g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    Print "cavity touched placer side of seat at (", CX(P*), ", ", CY(P*), ")"

    PKTSX1 = CX(P*)
    PKTSY1 = CY(P*)

    ''touch the other end: detach the seat, then move along 20 mm to touch the picker end
    SetFastSpeed
    ''Move P*-X(DISTANCE_FROM_SEAT)
    TongMove DIRECTION_CAVITY_TO_MAGNET, DISTANCE_FROM_SEAT, False

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at pickerTouchingSeat other end"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    ''Move P* +Y(20)
    TongMove DIRECTION_CAVITY_TAIL, DISTANCE_BETWEEN_TWO_TOUCH, False
    ForceCheck
    
    SetVerySlowSpeed

    ''save start position
    PKTSX2 = CX(P*)
    PKTSY2 = CY(P*)

    If Not ForceTouch(DIRECTION_MAGNET_TO_CAVITY, PKTSRange, True) Then
        Print "touch seat failed at picker side for the first try"
        Move P* :X(PKTSX2) :Y(PKTSY2)
		If Not ForceResetAndCheck Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
			g_RunResult$ = "force sensor reset failed at pickerTouchingSeat picker side"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
			Exit Function
		EndIf
        TongMove DIRECTION_CAVITY_HEAD, DISTANCE_BETWEEN_TWO_TOUCH / 2, False
        ForceCheck
	    If Not ForceTouch(DIRECTION_MAGNET_TO_CAVITY, PKTSRange, True) Then
	    	Print "failed to touch seat at picke side"
	    	Print #LOG_FILE_NO, "failed to touch seat at picke side"
    	    Exit Function
    	EndIf
    EndIf

    PickerTouchSeat = True
    Print "picker cavity touched seat at (", CX(P*), ", ", CY(P*), ")"

    PKTSX2 = CX(P*)
    PKTSY2 = CY(P*)
    
    Print #LOG_FILE_NO, "touched seat at (", PKTSX1, ", ", PKTSY1, ") and (", PKTSX2, ", ", PKTSY2, ")"
    ''recheck
    If Abs(PKTSX1 - PKTSX2) > 2 Then
        SPELCom_Event EVTNO_CAL_MSG, "touching seat for picker may failed, please check"
        If PKTSX2 > PKTSX1 Then
            PKTSX2 = PKTSX1
            Move P* :X(PKTSX1)
            Print "X moved to ", PKTSX1
        EndIf
    EndIf
   
Fend

Function PickerCalibration As Boolean
    PKCStepStart = g_CurrentSteps
    PKCStepTotal = g_Steps

    Tool 0
    g_SafeToGoHome = True

    ''log file
    g_FCntPicker = g_FCntPicker + 1
    WOpen "PickerCal" + Str$(g_FCntPicker) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "picker calibration at ", Date$, " ", Time$
    Print "picker calibration at ", Date$, " ", Time$

    PickerCalibration = False

    ''safety check
    If Not isCloseToPoint(6) Then
        Print "FAILED: It must start from P6 position"
        Print #LOG_FILE_NO, "FAILED: It must start from P6 position"
        Close #LOG_FILE_NO
        Exit Function
    EndIf


    PKCInitX = CX(P*)
    PKCInitY = CY(P*)
    PKCInitZ = CZ(P*) + V_DISTANCE_CAVITY_TO_GRIPPER
    PKCInitU = CU(P*)

    InitForceConstants
    g_OnlyAlongAxis = True

    ''===========================================================
    ''Find roughly correct values for X, Y first,
    ''then we can touch to find Z
    ''then we can fine tune Y (reduce force)
    ''then fine tune X (reduce force)
    ''===========================================================

    ''find X by touching the seat using cavity
    g_Steps = PKCStepTotal / 3
    SPELCom_Event EVTNO_CAL_MSG, "picker cal: touching seat for X"
    If Not PickerTouchSeat Then
        Print "FAILED: did not touch the holder seat"
        Print #LOG_FILE_NO, "FAILED: did not touch the holder seat"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    g_Steps = PKCStepTotal / 6
    g_CurrentSteps = PKCStepStart + 2 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "picker cal: touching head for Y"
    ''move cavity to touch magnet head: X will be finalX minus cavity Radius

    SetFastSpeed

    ''detach seat
    ''Move P*-X(2)
    TongMove DIRECTION_CAVITY_TO_MAGNET, SAFE_BUFFER_FOR_DETACH, False
    
    ''move along the holder to picker side    
    ''Move P* +Y(25) :Z(PKCInitZ)
    ''we know when the cavity hit the seat, it is still with in the seat a lot, 15mm is good
    PKCRange = SAFE_BUFFER_FOR_RESET_FORCE + 15
    TongMove DIRECTION_CAVITY_TAIL, PKCRange, False
    Move P* :Z(PKCInitZ)
    ''move the edge of cavity to the center of magnet head
    ''Move P* :X(PKCFinalX - CAVITY_RADIUS)
    TongMove DIRECTION_MAGNET_TO_CAVITY, SAFE_BUFFER_FOR_DETACH + HALF_OF_SEAT_THICKNESS, False
    SetVerySlowSpeed

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at pickerCalibration"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not ForceTouch(DIRECTION_CAVITY_HEAD, PKCRange, True) Then
        Print "FAILED: calibrate picker failed at touch magnet head"
        Print #LOG_FILE_NO, "FAILED: calibrate picker failed at touch magnet head"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "touched magnet head at (", CX(P*), ", ", CY(P*), ")"
    g_Steps = PKCStepTotal / 6
    g_CurrentSteps = PKCStepStart + 3 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "picker cal: touching head for Z"

    ''now we have roughly X, Y, we can go above to find Z first
    ''move to above to touch Z
    SetFastSpeed
    ''Move P* +Y(10)
    TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_RESET_FORCE, False
    
    Move P* +Z(CAVITY_RADIUS + MAGNET_HEAD_RADIUS + SAFE_BUFFER_FOR_Z_TOUCH)
    ''Move P* :X(PKCFinalX) :Y(PKCFinalY)
    ''move cavity center to magnet center
    TongMove DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS, False
    ''mov to above magnet head
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_RESET_FORCE + OVER_LAP_FOR_Z_TOUCH, False

    SetVerySlowSpeed
    
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at pickerCalibration before z"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    
    If Not ForceTouch(-FORCE_ZFORCE, SAFE_BUFFER_FOR_Z_TOUCH + 10, True) Then
        Print "FAILED: did not touch magnet head when lower the cavity for picker"
        Print #LOG_FILE_NO, "FAILED: did not touch magnet head when lower the cavity for picker"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "touch magnet head at Z=", CZ(P*)
    ''PKCFinalZ = CZ(P*) - CAVITY_RADIUS - MAGNET_HEAD_RADIUS
    ''move a little up 
    Move P* +Z(0.05)

    g_Steps = PKCStepTotal / 6
    g_CurrentSteps = PKCStepStart + 4 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "picker cal: touching head for more accurate X"

    SetFastSpeed
    Move P* +Z(SAFE_BUFFER_FOR_DETACH)

    TongMove DIRECTION_CAVITY_TO_MAGNET, CAVITY_RADIUS + HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, False
    Move P* -Z(SAFE_BUFFER_FOR_DETACH + CAVITY_RADIUS + MAGNET_HEAD_RADIUS)
    m_MAPAStartX = CX(P*)
    m_MAPAStartY = CY(P*)
    SetVerySlowSpeed
    If Not ForceTouch(DIRECTION_MAGNET_TO_CAVITY, HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, True) Then
        Print "Failed for accurate post angle: touching picker head"
        Print #LOG_FILE_NO, "Failed for accurate post angle: touching picker head"
        g_PickerWallToHead = 0
        
        ''move to position for next step   
        SetFastSpeed
        Move P* :X(m_MAPAStartX) :Y(m_MAPAStartY)
        TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_RESET_FORCE + OVER_LAP_FOR_Z_TOUCH, False
        TongMove DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS + HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, False
    Else
        m_MAPAStartX = m_MAPAStartX - CX(P*)
        m_MAPAStartY = m_MAPAStartY - CY(P*)
        g_PickerWallToHead = Sqr(m_MAPAStartX * m_MAPAStartX + m_MAPAStartY * m_MAPAStartY) - SAFE_BUFFER_FOR_DETACH
        Print "g_PickerWallToHead=", g_PickerWallToHead
        Print #LOG_FILE_NO, "g_PickerWallToHead=", g_PickerWallToHead
        
        ''move to ready position for next step
        SetFastSpeed
        TongMove DIRECTION_CAVITY_TO_MAGNET, SAFE_BUFFER_FOR_DETACH, False
        TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_RESET_FORCE + OVER_LAP_FOR_Z_TOUCH, False
        TongMove DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS + MAGNET_HEAD_RADIUS + SAFE_BUFFER_FOR_DETACH, False
    EndIf
    g_Steps = PKCStepTotal / 6
    g_CurrentSteps = PKCStepStart + 5 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "picker cal: move in"
#ifdef FINE_TUNE_PICKER
    ''fine tune Y
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at pickerCalibration find tune"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    ''move back to where we hit the magnet head
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_RESET_FORCE, False
    ''save data for toolset calibration
    g_Picker_X = CX(P*)
    g_Picker_Y = CY(P*)

    SetVerySlowSpeed
    
    ''head thickness is 3.55, with 1mm freedom, so 10 is enough to cover that
    If Not ForceTouch(DIRECTION_CAVITY_HEAD, 10, False) Then
        Print "failed to touch magnet in Y direction"
        Print #LOG_FILE_NO, "FAILED: to touch magnet in Y direction"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    CutMiddle DIRECTION_CAVITY_HEAD
    CutMiddleWithArguments DIRECTION_MAGNET_TO_CAVITY, 0, GetForceBigThreshold(DIRECTION_MAGNET_TO_CAVITY), 3, 30
#else
    ''calculate final picker position from what we already have
    ''move back to where we hit the magnet head using cavity edge
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_RESET_FORCE, False
    ''save data for toolset calibration
    g_Picker_X = CX(P*)
    g_Picker_Y = CY(P*)

    SetVerySlowSpeed
    ''move in 3mm
    TongMove DIRECTION_CAVITY_HEAD, (PICKER_OVER_MAGNET_HEAD - g_Dumbbell_Free_Y / 2), False
    ForceCheck

#endif

    Print "SUCCESS: Picker position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "SUCCESS: Picker position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "picker calibration end at ", Date$, " ", Time$

    CheckPoint 16
    Print "P16 moved from (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ") ", 
    Print #LOG_FILE_NO, "P16 moved from (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ") ", 
    SPELCom_Event EVTNO_UPDATE, "Old P16 (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ")"
    P16 = P*
    Print "to (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ") "
    Print #LOG_FILE_NO, "to (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ") "
    SPELCom_Event EVTNO_UPDATE, "New P16 (", CX(P16), ", ", CY(P16), ", ", CZ(P16), ", ", CU(P16), ")"

#ifdef AUTO_SAVE_POINT
    Print "saving points to file.....", 
    SavePoints "robot1.pnt"
    SavePointHistory 16, g_FCntPicker
    Print "done!!"
#endif
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, STANDBY_DISTANCE, False
    Close #LOG_FILE_NO
    
    If Not g_FlagAbort Then
        PickerCalibration = True
    EndIf
Fend
Function PlacerCalibration As Boolean
    CPCStepStart = g_CurrentSteps
    CPCStepTotal = g_Steps

    g_SafeToGoHome = True
    Tool 0

    ''log file
    g_FCntPlacer = g_FCntPlacer + 1
    WOpen "PlacerCal" + Str$(g_FCntPlacer) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "placer calibration at ", Date$, " ", Time$
    Print "placer calibration at ", Date$, " ", Time$

    InitForceConstants
    g_OnlyAlongAxis = True

    PlacerCalibration = False

    ''pre-condition: current position: cavity should be Picker's place +Y(10)'
    If Not isGoodForPlacerCal Then
        Print "not a good place to start placer calibration,  It should be P16 +Y(10)"
        Print #LOG_FILE_NO, "FAILED: not a good place to start placer calibration,  It should be P16 +Y(10)"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf

    SPELCom_Event EVTNO_CAL_MSG, "placer cal: arc to placer side"

    CPCInitX = CX(P*)
    CPCInitY = CY(P*)
    CPCInitZ = CZ(P*)
    CPCInitU = CU(P*)

    ''calculate the final position from P6:
    ''from P6 move from Cavity to magnet of distance of CAVITY_TO_MAGNET,
    ''then move to weak magnet end DISTANCE_PLACER_FROM_MAGNET
    CalculateStepSize DIRECTION_CAVITY_TO_MAGNET, H_DISTANCE_CAVITY_TO_GRIPPER, CU(P6), CPCStepSize()
    CPCFinalX = CX(P6) + CPCStepSize(1)
    CPCFinalY = CY(P6) + CPCStepSize(2)

    ''in P6, the cavity tail is the direction where we want to move
    CalculateStepSize DIRECTION_CAVITY_TAIL, DISTANCE_PLACER_FROM_MAGNET, CU(P6), CPCStepSize()
    CPCFinalX = CPCFinalX + CPCStepSize(1)
    CPCFinalY = CPCFinalY + CPCStepSize(2)

    CalculateStepSize DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS, CU(P6), CPCStepSize()
    CPCFinalX = CPCFinalX + CPCStepSize(1)
    CPCFinalY = CPCFinalY + CPCStepSize(2)

    ''CPCFinalZ = CZ(P6) + V_DISTANCE_CAVITY_TO_GRIPPER
    CPCFinalZ = CZ(P*) ''in fact, this may  be better
    CPCFinalU = CU(P6)
    
    ''try to arc from picker to placer : turn +U(180)
    ''arc middle point
    CPCMiddleX = (CPCInitX + CPCFinalX + CPCFinalY - CPCInitY) / 2
    CPCMiddleY = (CPCInitY + CPCFinalY + CPCInitX - CPCFinalX) / 2
    CPCMiddleZ = (CPCInitZ + CPCFinalZ) / 2
    CPCMiddleU = (CPCInitU + CPCFinalU) / 2

    ''arc from picker to placer
    P51 = XY(CPCMiddleX, CPCMiddleY, CPCMiddleZ, CPCMiddleU)
    P52 = XY(CPCFinalX, CPCFinalY, CPCFinalZ, CPCFinalU)
	POrient(P51) = POrient(P6)
	POrient(P52) = POrient(P6)

    Print "init (", CPCInitX, ", ", CPCInitY, ") final (", CPCFinalX, ", ", CPCFinalY, ")"

    SetFastSpeed
    Arc P51, P52
    SetVerySlowSpeed

    g_Steps = CPCStepTotal / 5
    g_CurrentSteps = CPCStepStart + g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "placer cal: touching head for Y"

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at placerCalibration"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
        
    If Not ForceTouch(DIRECTION_CAVITY_HEAD, DISTANCE_PLACER_FROM_MAGNET, True) Then
        Print "FAILED: calibrate placer failed at touch magnet head"
        Print #LOG_FILE_NO, "FAILED: calibrate placer failed at touch magnet head"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf

    Print #LOG_FILE_NO, "touched magnet head at (", CX(P*), ", ", CY(P*), ")"

    g_Steps = CPCStepTotal / 5
    g_CurrentSteps = CPCStepStart + 2 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "placer cal: touching seat for X"

    ''try to touch seat for X with cavity.
    ''the free space here is very limited.
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_MAGNET_TO_CAVITY, HALF_OF_SEAT_THICKNESS * 2, False    ''5 is the wall, another 5 for safety
    ''here we do not need to give very big safe buffer like in placer calibration.
    ''the error is no way too big.

    Move P* -Z(20)

    TongMove DIRECTION_CAVITY_HEAD, DISTANCE_TOUCH_ARM + SAFE_BUFFER_FOR_DETACH, False
    ''should be change too much.  It is determined by the tong shape.
    
    SetVerySlowSpeed

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at placerCalibration before touching seat wall"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, HALF_OF_SEAT_THICKNESS * 2, True) Then
        Print "FAILED: to touch seat wall for placer"
        Print #LOG_FILE_NO, "FAILED: to touch seat wall for placer"
        Close #LOG_FILE_NO
        
        TongMove DIRECTION_CAVITY_TAIL, DISTANCE_TOUCH_ARM + SAFE_BUFFER_FOR_DETACH, False
        Exit Function
    EndIf
    
    ''we touched the holder arm:
    Print "cavity touched holder arm at (", CX(P*), ", ", CY(P*), ")"
    Print #LOG_FILE_NO, "cavity touched holder arm at (", CX(P*), ", ", CY(P*), ")"

    g_Steps = CPCStepTotal / 5
    g_CurrentSteps = CPCStepStart + 3 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "placer cal: touching head for Z"
    
    ''now we have roughly X, Y, we can go above to find Z first
    ''move to above to touch Z
    SetFastSpeed
    TongMove DIRECTION_MAGNET_TO_CAVITY, SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_CAVITY_TAIL, DISTANCE_TOUCH_ARM - OVER_LAP_FOR_Z_TOUCH, False
    Move P* +Z(20 + CAVITY_RADIUS + MAGNET_HEAD_RADIUS + SAFE_BUFFER_FOR_Z_TOUCH)

    ''move to above magnet head
    TongMove DIRECTION_CAVITY_TO_MAGNET, SAFE_BUFFER_FOR_DETACH + HALF_OF_SEAT_THICKNESS + CAVITY_RADIUS, False
    SetVerySlowSpeed

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at placerCalibration before touching z"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf

    If Not ForceTouch(-FORCE_ZFORCE, SAFE_BUFFER_FOR_Z_TOUCH + 10, True) Then
        Print "FAILED: did not touch magnet head when lower the cavity for picker"
        Print #LOG_FILE_NO, "FAILED: did not touch magnet head when lower the cavity for placer"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "touch magnet head at Z=", CZ(P*)
    ''CPCFinalZ = CZ(P*) - CAVITY_RADIUS - MAGNET_HEAD_RADIUS
    Move P* +Z(0.05)

    g_Steps = CPCStepTotal / 5
    g_CurrentSteps = CPCStepStart + 4 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "placer cal: touching head for more accurate X"

    SetFastSpeed
    Move P* +Z(SAFE_BUFFER_FOR_DETACH)

    Print "touch head in X direction to get more accurate position"
    TongMove DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS + HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, False
    Move P* -Z(SAFE_BUFFER_FOR_DETACH + CAVITY_RADIUS + MAGNET_HEAD_RADIUS)
    m_MAPAStartX = CX(P*)
    m_MAPAStartY = CY(P*)
    SetVerySlowSpeed
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, True) Then
        Print "Failed for accurate post angle: touching picker head"
        Print #LOG_FILE_NO, "Failed for accurate post angle: touching picker head"
        g_PlacerWallToHead = 0
        
        ''move to position for next step   
        SetFastSpeed
        Move P* :X(m_MAPAStartX) :Y(m_MAPAStartY)
        TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_RESET_FORCE + OVER_LAP_FOR_Z_TOUCH, False
        TongMove DIRECTION_CAVITY_TO_MAGNET, CAVITY_RADIUS + HALF_OF_SEAT_THICKNESS + SAFE_BUFFER_FOR_DETACH, False
    Else
        m_MAPAStartX = m_MAPAStartX - CX(P*)
        m_MAPAStartY = m_MAPAStartY - CY(P*)
        g_PlacerWallToHead = Sqr(m_MAPAStartX * m_MAPAStartX + m_MAPAStartY * m_MAPAStartY) - SAFE_BUFFER_FOR_DETACH
        Print "g_PlacerWallToHead=", g_PlacerWallToHead
        Print #LOG_FILE_NO, "g_PlacerWallToHead=", g_PlacerWallToHead
        
        ''move to ready position for next step
        SetFastSpeed
        TongMove DIRECTION_MAGNET_TO_CAVITY, SAFE_BUFFER_FOR_DETACH, False
        TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_RESET_FORCE + OVER_LAP_FOR_Z_TOUCH, False
        TongMove DIRECTION_CAVITY_TO_MAGNET, CAVITY_RADIUS + MAGNET_HEAD_RADIUS + SAFE_BUFFER_FOR_DETACH, False
    EndIf
        
#ifdef FINE_TUNE_PLACER
    '' fine tune Y
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at placerCalibration fine tune"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_RESET_FORCE, False
    ''save data for toolset calibration
    g_Placer_X = CX(P*)
    g_Plaver_Y = CY(P*)
    
    SetVerySlowSpeed

    If Not ForceTouch(DIRECTION_CAVITY_HEAD, 10, False) Then
        Print "failed to touch magnet in Y direction"
        Print #LOG_FILE_NO, "FAILED: to touch magnet in Y direction"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    CutMiddle DIRECTION_CAVITY_HEAD
    CutMiddleWithArguments DIRECTION_MAGNET_TO_CAVITY, 0, GetForceBigThreshold(DIRECTION_MAGNET_TO_CAVITY), 3, 30
#else
    ''move back to where we hit the magnet head with cavity edge
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_RESET_FORCE, False
    ''save data for toolset calibration
    g_Placer_X = CX(P*)
    g_Placer_Y = CY(P*)
    ''move in final position
    SetVerySlowSpeed
    TongMove DIRECTION_CAVITY_HEAD, PLACER_OVER_MAGNET_HEAD, False
    ForceCheck

#endif

    Print "SUCCESS: Placer position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "SUCCESS: Placer position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "placer calibration end at ", Date$, " ", Time$

    CheckPoint 26
    Print "P26 moved from (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ") ", 
    Print #LOG_FILE_NO, "P26 moved from (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ") ", 
    SPELCom_Event EVTNO_UPDATE, "Old P26 (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ")"
    P26 = P*
    Print "to (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ") "
    Print #LOG_FILE_NO, "to (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ") "
    SPELCom_Event EVTNO_UPDATE, "New P26 (", CX(P26), ", ", CY(P26), ", ", CZ(P26), ", ", CU(P26), ")"

#ifdef AUTO_SAVE_POINT
    Print "saving points to file.....", 
    SavePoints "robot1.pnt"
    SavePointHistory 26, g_FCntPlacer
    Print "done!!"
#endif
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, STANDBY_DISTANCE, False

    ''check post level error
    PostLevelError = Abs(CZ(P16) - CZ(P26))
    Print "post level error: ", PostLevelError, "mm"
    Print #LOG_FILE_NO, "post   level error: ", PostLevelError, "mm"
    If PostLevelError >= ACCPT_THRHLD_POST_LEVEL Then
        Print "Warning: post level error exceeded threshold (", ACCPT_THRHLD_POST_LEVEL, "mm)"
        Print #LOG_FILE_NO, "Warning: post level error exceeded threshold (", ACCPT_THRHLD_POST_LEVEL, "mm)"
        Magnet_Warning$ = Magnet_Warning$ + "Post Level Error Exceed Threshold "
        SPELCom_Event EVTNO_WARNING, Magnet_Warning$
    EndIf

    Close #LOG_FILE_NO
    
    If Not g_FlagAbort Then
        PlacerCalibration = True
    EndIf
Fend

Function ABCThetaToToolSets(a As Real, b As Real, c As Real, theta As Real)
    TSU = NarrowAngle(theta)
#ifdef USE_OLD_TOOLSET_DIRECTION
    TSU = TSU - 90
#endif
    theta = DegToRad(theta)
    ''for picker
    TSX = a * Sin(theta) + b * Cos(theta)
    TSY = -a * Cos(theta) + b * Sin(theta)

    ''twist off toolset
    TSTWX = (a + MAGNET_HEAD_RADIUS) * Sin(theta) + (b - SAMPLE_PIN_DEPTH) * Cos(theta)
    TSTWY = (-a - MAGNET_HEAD_RADIUS) * Cos(theta) + (b - SAMPLE_PIN_DEPTH) * Sin(theta)

    TSZ = 0

    Print "Toolset picker: (", TSX, ", ", TSY, ", ", TSZ, ", ", TSU, ")"
    Print #LOG_FILE_NO, "Toolset picker: (", TSX, ", ", TSY, ", ", TSZ, ", ", TSU, ")"
    
    P10 = XY(TSTWX, TSTWY, TSZ, TSU)
    Print "picker twist off toolset: (", TSTWX, ", ", TSTWY, ", ", TSZ, ", ", TSU, ")"
    Print #LOG_FILE_NO, "picker twist off toolset: (", TSTWX, ", ", TSTWY, ", ", TSZ, ", ", TSU, ")"
#ifdef AUTO_SAVE_POINT
    CheckToolSet 1
    P51 = TLSet(1)
    Print "old picker: (", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print #LOG_FILE_NO, "old picker: (", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print "saving new picker.....", 
    TLSet 1, XY(TSX, TSY, TSZ, TSU)
    Print "done!"
#endif

    ''for placer
    CheckToolSet 2
    P51 = TLSet(2)
    
    TSU = TSU + 180
    TSX = a * Sin(theta) - c * Cos(theta)
    TSY = -a * Cos(theta) - c * Sin(theta)
    TSZ = CZ(P51) ''keep the old Z offset.

    ''twist off toolset
    TSTWX = (a + MAGNET_HEAD_RADIUS) * Sin(theta) - (c - SAMPLE_PIN_DEPTH) * Cos(theta)
    TSTWY = (-a - MAGNET_HEAD_RADIUS) * Cos(theta) - (c - SAMPLE_PIN_DEPTH) * Sin(theta)
    P11 = XY(TSTWX, TSTWY, TSZ, TSU)
    Print "placer twist off toolset: (", TSTWX, ", ", TSTWY, ", ", TSZ, ", ", TSU, ")"
    Print #LOG_FILE_NO, "placer twist off toolset: (", TSTWX, ", ", TSTWY, ", ", TSZ, ", ", TSU, ")"

    Print "Toolset placer: (", TSX, ", ", TSY, ", ", TSZ, ", ", TSU, ")"
    Print #LOG_FILE_NO, "Toolset placer: (", TSX, ", ", TSY, ", ", TSZ, ", ", TSU, ")"
#ifdef AUTO_SAVE_POINT
    Print "old placer: (", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print #LOG_FILE_NO, "old placer: (", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print "saving new placerr.....", 
    TLSet 2, XY(TSX, TSY, TSZ, TSU)
    SavePoints "robot1.pnt"
    Print "done!"
#endif
Fend

Function CalCavityTwistOff(a As Real, b As Real, theta As Real)
    TSU = theta
#ifdef USE_OLD_TOOLSET_DIRECTION
    TSU = TSU - 90
#endif
    theta = DegToRad(theta)

    TSTWX = (-a + CAVITY_RADIUS) * Sin(theta) + b * Cos(theta)
    TSTWY = (a - CAVITY_RADIUS) * Cos(theta) + b * Sin(theta)
    P12 = P6
    P12 = XY(TSTWX, TSTWY, 0, TSU)
    Print "cavity twist off toolset: (", TSTWX, ", ", TSTWY, "0, ", TSU, ")"
    Print #LOG_FILE_NO, "cavity twist off toolset: (", TSTWX, ", ", TSTWY, "0, ", TSU, ")"

    TSTWX = (-a - CAVITY_RADIUS) * Sin(theta) + b * Cos(theta)
    TSTWY = (a + CAVITY_RADIUS) * Cos(theta) + b * Sin(theta)
    P13 = P6
    P13 = XY(TSTWX, TSTWY, 0, TSU)
    Print "cavity twist off toolset for left hand: (", TSTWX, ", ", TSTWY, "0, ", TSU, ")"
    Print #LOG_FILE_NO, "cavity twist off toolset for left hand: (", TSTWX, ", ", TSTWY, "0, ", TSU, ")"
Fend

Function CalculateToolset As Boolean
    
    CalculateToolset = False
    
    ''check data availability
    If g_Picker_X = 0 Or g_Picker_Y = 0 Or g_Placer_X = 0 Or g_Placer_X = 0 Or CY(P6) = 0 Then
        Print "do post, picker, and placer calibration first."
        Exit Function
    EndIf

    ''log file
    g_FCntToolRough = g_FCntToolRough + 1
    WOpen "ToolsetCal" + Str$(g_FCntToolRough) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    Print #LOG_FILE_NO, "toolset calibration at ", Date$, " ", Time$

    ''print out old toolset
    P51 = TLSet(1)
    SPELCom_Event EVTNO_UPDATE, "Old TLSet 1: (", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ")"
    P51 = TLSet(2)
    SPELCom_Event EVTNO_UPDATE, "Old TLSet 2: (", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ")"
    
    ''adjust because the the direction we move is not exactly X or Y
    ''this is rough calculation, we ignore second order error
    
    NumToSelect = Int(g_Perfect_Cradle_Angle) Mod 180
        
    If NumToSelect <> 0 Then
	    TSAdjust = Sin(DegToRad(g_MagnetTransportAngle))
	    ''we use TSa as the center of magnet in Y dirction now
	    TSa = (g_Picker_Y + g_Placer_Y) / 2.0
	    ''we use TSa as the difference beween magnet center and where U axis center
	    TSa = TSa - CY(P6)
	    TSa = TSa / TSAdjust
	    Print #LOG_FILE_NO, "center to hold: ", TSa
	    Print "center to hold: ", TSa
	    
	    TSb = MAGNET_LENGTH / 2.0 + TSa
	    TSc = MAGNET_LENGTH / 2.0 - TSa
	    
	    ''try to get TSa
	    ''we use TSX as distance between cavity and magnet
	    TSX = (g_Placer_X - CX(P6)) / TSAdjust
	    ''distance between cavity and U axis center
	    CVa = (g_Placer_X - g_Picker_X) / (2.0 * TSAdjust)
	    CVb = ((g_Picker_Y - g_Placer_Y) / TSAdjust - MAGNET_LENGTH) / 2.0
    Else
	    TSAdjust = -Cos(DegToRad(g_MagnetTransportAngle))
	    TSa = (g_Picker_X + g_Placer_X) / 2.0
	    ''we use TSa as the difference beween magnet center and where U axis center
	    TSa = TSa - CX(P6)
	    TSa = TSa / TSAdjust
	    Print #LOG_FILE_NO, "center to hold: ", TSa
	    Print "center to hold: ", TSa
	    
	    TSb = MAGNET_LENGTH / 2.0 + TSa
	    TSc = MAGNET_LENGTH / 2.0 - TSa
	    
	    ''try to get TSa
	    ''we use TSX as distance between cavity and magnet
	    TSX = (g_Placer_Y - CY(P6)) / TSAdjust
	    ''distance between cavity and U axis center
	    CVa = (g_Placer_Y - g_Picker_Y) / (2.0 * TSAdjust)
	    CVb = ((g_Placer_X - g_Picker_X) / TSAdjust - MAGNET_LENGTH) / 2.0
    EndIf
	TSa = TSX - CVa
	TStheta = g_MagnetTransportAngle - g_U4MagnetHolder
       
    Print "a=", TSa, ", b=", TSb, ", c=", TSc, ", theta=", TStheta
    Print #LOG_FILE_NO, "a=", TSa, ", b=", TSb, ", c=", TSc, ", theta=", TStheta

    ''save info
    Print "Old toolset A:", g_ToolSet_A, ", B:", g_ToolSet_B, ", C:", g_ToolSet_C, ", Theta:", g_ToolSet_Theta
    Print #LOG_FILE_NO, "Old toolset A:", g_ToolSet_A, ", B:", g_ToolSet_B, ", C:", g_ToolSet_C, ", Theta:", g_ToolSet_Theta
	
    SPELCom_Event EVTNO_UPDATE, "Old Toolset A:", g_ToolSet_A, ", B:", g_ToolSet_B, ", C:", g_ToolSet_C, ", Theta:", g_ToolSet_Theta
    g_ToolSet_A = TSa
    g_ToolSet_B = TSb
    g_ToolSet_C = TSc
    g_ToolSet_Theta = TStheta

    ''cavity twist off toolset
    CalCavityTwistOff CVa, CVb, TStheta

    ABCThetaToToolSets TSa, TSb, TSc, TStheta
    
    Close #LOG_FILE_NO

    SavePointHistory 12, g_FCntToolRough

    CalculateToolset = True
    Exit Function
Fend

Function isGoodForPlacerCal As Boolean

    isGoodForPlacerCal = True

	tmp_Real = DegToRad(g_Perfect_Cradle_Angle)
        
    ISP16IdealX = CX(P16) + STANDBY_DISTANCE * Cos(tmp_Real)
    ISP16IdealY = CY(P16) + STANDBY_DISTANCE * Sin(tmp_Real)
    ISP16IdealZ = CZ(P16)
    ISP16IdealU = CU(P16)
    
    
    ISP16DX = CX(P*) - ISP16IdealX
    ISP16DY = CY(P*) - ISP16IdealY
    ISP16DZ = CZ(P*) - ISP16IdealZ
    ISP16DU = CU(P*) - ISP16IdealU

    If Abs(ISP16DU) > 2 Then
        isGoodForPlacerCal = False
    EndIf

    If Abs(ISP16DZ) > 2 Then
        isGoodForPlacerCal = False
    EndIf

    If Sqr(ISP16DX * ISP16DX + ISP16DY * ISP16DY) > 2 Then
        isGoodForPlacerCal = False
    EndIf

    ''more safe, check against P6 also
    ISP16DU = Abs(CU(P*) - CU(P6))
    ISP16DU = ISP16DU - 180
    If Abs(ISP16DU) > 2 Then
        isGoodForPlacerCal = False
    EndIf
    
Fend

Function ParallelGripperAndCradle As Boolean
    ParallelGripperAndCradle = False

    PGCOldU = CU(P*)
    PGCOldForce = ReadForce(DIRECTION_CAVITY_TO_MAGNET)
    Print "ParallelGripperAndCradle: old U=", PGCOldU, ", old force=", PGCOldForce
    
    PGCGoodU = PGCOldU
    PGCGoodForce = Abs(PGCOldForce)

    ''scan twice, first stepsize = 1 degree, second time stepsize = 0.1 degree    
    For PGCScanIndex = 1 To 2
        Select PGCScanIndex
        Case 1
            PGCStepSize = PGC_INIT_STEPSIZE
            PGCNumSteps = PGC_MAX_SCAN_U
        Case 2
            PGCStepSize = PGC_FINAL_STEPSIZE
            PGCNumSteps = PGC_INIT_STEPSIZE / PGC_FINAL_STEPSIZE
        Send
    
        ''scan both direction
        For PGCDirection = 1 To 2
            For PGCStepIndex = 1 To PGCNumSteps
                If g_FlagAbort Then
                    Go P* :U(PGCOldU)
                    Exit Function
                EndIf
                Select PGCDirection
                Case 1
                    Go P* +U(PGCStepSize)
                Case 2
                    Go P* -U(PGCStepSize)
                Send
                PGCNewU = CU(P*)
                PGCNewForce = ReadForce(DIRECTION_CAVITY_TO_MAGNET)
                PGCNewForce = Abs(PGCNewForce)
                
                If PGCNewForce >= PGCGoodForce Then
                    Exit For
                Else
                    PGCGoodU = PGCNewU; 
                    PGCGoodForce = PGCNewForce
                EndIf
            Next ''For PGCStepIndex = 1 to PGCNumSteps
            If PGCStepIndex > PGCNumSteps Then
                Print "U moved out of range without reach min force"
                Go P* :U(PGCOldU)
                Exit Function
            EndIf
            SPELCom_Event EVTNO_CAL_STEP, (g_CurrentSteps + (PGCScanIndex * 2 + PGCDirection - 2) * g_Steps / 4), "of 100"
        Next ''For PGCDirection = 1 To 2
        Go P* :U(PGCGoodU)
    Next ''For PGCScanIndex = 1 to 2
    
    ParallelGripperAndCradle = True

    Print "U moved from ", PGCOldU, " to ", PGCGoodU, ", force reduced from ", PGCOldForce, " to ", PGCGoodForce
Fend

Function PullOutZ As Boolean
    PullOutZ = False
    
    POZOldX = CX(P*)
    POZOldY = CY(P*)
    POZOldZ = CZ(P*)

    For StepIndex = 1 To POZ_MAX_STEPS
        Move P* +Z(POZ_STEPSIZE)
        g_Steps = 0 ''to prevent ForceTouch update progress bar
        If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, 2 * SAFE_BUFFER_FOR_DETACH, False) Then
            Move P* +Z(POZ_STEPSIZE)''one more step for safety
            If Not g_FlagAbort Then
                PullOutZ = True
                Print "got Z at ", CZ(P*)
            Else
                TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False
            EndIf
            Exit Function
        EndIf
          Move P* :X(POZOldX) :Y(POZOldY)
    Next
    
    Print "not got top of cradle"
Fend

''09/02/03 Jinhu:
''FindMagnet now will utilize existing P6.  So, it should only be used
''after initial calibration.
''It will start from anyplace that can jump to P3
''It should work as long as DX < 5mm, DY < 5mm, DZ < 5mm, DU < 10 degree.
Function FindMagnet As Boolean
    SPELCom_Event EVTNO_CAL_MSG, "find magnet: move tong to dewar"

    Tool 0

    FMStepStart = g_CurrentSteps
    FMStepTotal = g_Steps

    g_SafeToGoHome = True
    g_HoldMagnet = False

    FindMagnet = False

    InitForceConstants
    g_OnlyAlongAxis = True

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    ''check conditions
    ''check current position
    If ( Not isCloseToPoint(0)) And ( Not isCloseToPoint(1)) Then
        g_RunResult$ = "must start from home"
        Print g_RunResult$
        g_SafeToGoHome = False
        SPELCom_Event EVTNO_CAL_MSG, "aborted ", g_RunResult$
        SPELCom_Event EVTNO_LOG_ERROR, "aborted ", g_RunResult$
        Exit Function
    EndIf

    If Not Check_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "find magnet: abort: check gripper failed"
        ''not need recovery
        g_SafeToGoHome = False
        Exit Function
    EndIf
    If Not Close_Gripper Then
        SPELCom_Event EVTNO_CAL_MSG, "find magnet: abort: failed to close gripper"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "find magnet: abort: failed to close gripper"
        ''not need recovery
        g_SafeToGoHome = False
        Exit Function
    EndIf

    If Not Open_Lid Then
        SPELCom_Event EVTNO_CAL_MSG, "find magnet: abort: failed to open Dewar lid"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "find magnet: abort: failed to open Dewar lid"
        ''not need recovery
        g_SafeToGoHome = False
        Exit Function
    EndIf
    
    SetFastSpeed
    LimZ 0
    Jump P1
    
    If g_FlagAbort Then
		Close_Lid
		Jump P0
		Exit Function
    EndIf

	''start position is 30 mm away from old position and shift so fingers are at center of cradle.
	tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
	tmp_Real2 = DegToRad(g_Perfect_Cradle_Angle)
	tmp_DX = 30 * Cos(tmp_Real) + Y_FROM_CRADLE_TO_MAGNET * Cos(tmp_Real2)
	tmp_DY = 30 * Sin(tmp_Real) + Y_FROM_CRADLE_TO_MAGNET * Sin(tmp_Real2)
	Jump P6 +X(tmp_DX) +Y(tmp_DY)
	
    Move P* -Z(Z_FROM_CRADLE_TO_MAGNET + FIND_MAGNET_Z_DOWN)
    SetVerySlowSpeed

    If g_LN2LevelHigh Then
        SPELCom_Event EVTNO_CAL_MSG, "find magnet wait 40 seconds cooling"
        ''Wait 40
        ''MagLevelError used here as relative depth
        MagLevelError = CZ(P6) - STRIP_PLACER_Z_OFFSET - CZ(P*)
        If g_IncludeStrip Then
			Move P* +Z(MagLevelError)
        EndIf
        For FMWait = 1 To 40
            Wait 1
            If g_FlagAbort Then
                Exit Function
            EndIf
        Next
        If g_IncludeStrip Then
			Move P* -Z(MagLevelError)
        EndIf
    Else
        Wait TIME_WAIT_BEFORE_RESET
    EndIf
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at findMagnet before touching seat"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    ''try to touch the cradle using the gripper
    
    SPELCom_Event EVTNO_CAL_MSG, "find magnet: touching seat"
    g_Steps = FMStepTotal / 10
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, 50, False) Then
        TongMove DIRECTION_MAGNET_TO_CAVITY, 2, False
        Print "Not find the cradle in 10 cm, give up"
        Exit Function
    EndIf
    g_CurrentSteps = FMStepStart + FMStepTotal / 10
    g_Steps = FMStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: parallel gripper with cradle"
    ''press it against the wall strongly
    TongMove DIRECTION_CAVITY_TO_MAGNET, 2, False
    ''try to get gripper parallel with cradle
    If Not ParallelGripperAndCradle Then
        g_RunResult$ = "ParallelGripperAndCradle failed"
        Print g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
    EndIf
    g_CurrentSteps = FMStepStart + 3 * FMStepTotal / 10
    g_Steps = FMStepTotal / 10
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    ''try to get the position of cradle
    TongMove DIRECTION_MAGNET_TO_CAVITY, 5, False
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, 7, True) Then
        TongMove DIRECTION_MAGNET_TO_CAVITY, 10, False
        Print "Strange, not touched the cradle after we detach it"
        Exit Function
    EndIf
        
    ''try to find the horizontal edges of cradle
    ''detach
    SetFastSpeed
    TongMove DIRECTION_MAGNET_TO_CAVITY, SAFE_BUFFER_FOR_DETACH, False

    g_CurrentSteps = FMStepStart + 2 * FMStepTotal / 5
    g_Steps = FMStepTotal / 10
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: touching left side"

    ''move along cradle to one end
    TongMove DIRECTION_CAVITY_HEAD, CRADLE_WIDTH + SAFE_BUFFER_FOR_DETACH, False
    ''move grapper in line with cradle
    TongMove DIRECTION_CAVITY_TO_MAGNET, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    ''touch it
    SetVerySlowSpeed

    Wait 2
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at findMagnet before touching left side"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not ForceTouch(DIRECTION_CAVITY_TAIL, CRADLE_WIDTH, True) Then
        TongMove DIRECTION_CAVITY_HEAD, 10, False
        Print "failed to touch left end"; 
        Exit Function
    EndIf
    FMLeftX = CX(P*)
    FMLeftY = CY(P*)
    
    ''try to touch the other end
    g_CurrentSteps = FMStepStart + FMStepTotal / 2
    g_Steps = FMStepTotal / 10
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: touching right side"
    SetFastSpeed
    TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_MAGNET_TO_CAVITY, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_CAVITY_TAIL, CRADLE_WIDTH + GRIPPER_WIDTH + 2 * SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_CAVITY_TO_MAGNET, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    SetVerySlowSpeed

    ''touch it
    Wait 2
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at findMagnet before touching right side"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not ForceTouch(DIRECTION_CAVITY_HEAD, CRADLE_WIDTH, True) Then
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Print "failed to touch right end"; 
        Exit Function
    EndIf
    FMRightX = CX(P*)
    FMRightY = CY(P*)
    FMDX = FMLeftX - FMRightX
    FMDY = FMLeftY - FMRightY
    FMDistance = Sqr(FMDX * FMDX + FMDY * FMDY)
    
    ''move to center of cradle
    g_CurrentSteps = FMStepStart + 3 * FMStepTotal / 5
    g_Steps = FMStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: pull out Z"
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_MAGNET_TO_CAVITY, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_CAVITY_HEAD, FMDistance / 2 + SAFE_BUFFER_FOR_DETACH, False
    Move P* +Z(FIND_MAGNET_Z_DOWN + 1)
    SetVerySlowSpeed

    ''pull up until force disappear
    Wait 2
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at findMagnet before pulling out"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not PullOutZ Then
        Exit Function
    EndIf
    
    FMFinalX = (FMLeftX + FMRightX) / 2
    FMFinalY = (FMLeftY + FMRightY) / 2
    Move P* :X(FMFinalX) :Y(FMFinalY)
    SetVerySlowSpeed
    
    ''try to find Z by touching out the top edge of cradle holder.
    g_CurrentSteps = FMStepStart + 4 * FMStepTotal / 5
    g_Steps = FMStepTotal / 10
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: touching top"
    Wait 2
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at findMagnet before touching top"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not ForceTouch(-FORCE_ZFORCE, 10, True) Then
        TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False
        Print "Failed to Z touch the cradle"
        Exit Function
    EndIf
    
    FMFinalZ = CZ(P*)
    FMFinalU = CU(P*)
    
    ''adjust and move to P6
    g_CurrentSteps = FMStepStart + 9 * FMStepTotal / 10
    g_Steps = FMStepTotal / 10
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    SPELCom_Event EVTNO_CAL_MSG, "find magnet: found it, move in"
    SetFastSpeed
    Move P* +Z(SAFE_BUFFER_FOR_DETACH)
    TongMove DIRECTION_MAGNET_TO_CAVITY, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    TongMove DIRECTION_CAVITY_TAIL, Y_FROM_CRADLE_TO_MAGNET, False
    Move P* +Z(Z_FROM_CRADLE_TO_MAGNET - SAFE_BUFFER_FOR_DETACH)
    
    If Not Open_Gripper Then
        g_RunResult$ = "After find magnet, Open_Gripper Failed"
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, g_RunResult$
        Print g_RunResult$
        Exit Function
    EndIf
    
    ''move in
    TongMove DIRECTION_CAVITY_TO_MAGNET, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    
    ''give a little bit of safety buffer in Z,
    ''we will easily touch bottom in post calibration
    Move P* +Z(0.5)
    
    If Not CheckMagnet Then
		Exit Function
    EndIf
    
    
    If g_FlagAbort Then
        TongMove DIRECTION_MAGNET_TO_CAVITY, OVERLAP_GRAPPER_CRADLE + SAFE_BUFFER_FOR_DETACH, False
    Else
        FindMagnet = True
    EndIf
Fend

Function FineTuneToolSet As Boolean

    FTTStepStart = g_CurrentSteps
    FTTStepTotal = g_Steps

    ''log file
    g_FCntToolFine = g_FCntToolFine + 1
    WOpen "ToolsetFine" + Str$(g_FCntToolFine) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    Print #LOG_FILE_NO, "toolset FineTune ", Date$, " ", Time$

    Tool 0
    
    LimZ g_Jump_LimZ_Magnet

    g_SafeToGoHome = True
    FineTuneToolSet = False

    InitForceConstants
    g_OnlyAlongAxis = True

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    ''==================get the magnet=================
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: take magnet"

    SetFastSpeed
    Jump P3
    If Not Open_Gripper Then
        g_RunResult$ = "fine tune ToolSet: Open_Gripper Failed at beginning"
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, g_RunResult$
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    If g_FlagAbort Then
        Print #LOG_FILE_NO, "user abort at home"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    Move P6

    Move P* +Z(20)

    If Not Close_Gripper Then
        Print "close gripper failed at holding magnet for toolset aborting"
        SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: close gripper failed"
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "TlSetFineTone: abort: close gripper failed at magnet"
        Move P6
        If Not Open_Gripper Then
            Print "open gripper failed at aborting from magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, "open gripper failed in aborting"
            SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset"
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Print #LOG_FILE_NO, "need reset in tlsetfinetune"
            Close #LOG_FILE_NO
            Motor Off
            Quit All
        EndIf
        Move P3
        LimZ 0
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Print #LOG_FILE_NO, "aborted: cannot close gripper"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    g_HoldMagnet = True

    LimZ g_Jump_LimZ_Magnet
    ''====================get absolute position of finger====================
    Tool 2
    ''dest point is the cradle's right holder center.
    ''it is used again in b-c
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle)
    FTTSDestX = CX(P*) + (MAGNET_HEAD_THICKNESS + FINGER_THICKNESS / 2.0) * Cos(tmp_Real)
    FTTSDestY = CY(P*) + (MAGNET_HEAD_THICKNESS + FINGER_THICKNESS / 2.0) * Sin(tmp_Real)
    
    ''standby point is away from cradle with magnet head align with finger
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
    tmp_DX = (SAFE_BUFFER_FOR_DETACH + MAGNET_HEAD_RADIUS + HALF_OF_SEAT_THICKNESS) * Cos(tmp_Real)
    tmp_DY = (SAFE_BUFFER_FOR_DETACH + MAGNET_HEAD_RADIUS + HALF_OF_SEAT_THICKNESS) * Sin(tmp_Real)

    tmp_Real2 = DegToRad(g_Perfect_Cradle_Angle + 180.0)
    tmp_DX = tmp_DX + MAGNET_HEAD_THICKNESS / 2.0 * Cos(tmp_Real2)
    tmp_DY = tmp_DY + MAGNET_HEAD_THICKNESS / 2.0 * Sin(tmp_Real2)

	P51 = XY((FTTSDestX + tmp_DX), (FTTSDestY + tmp_DY), CZ(P6), (g_Perfect_Cradle_Angle + 180.0))
	POrient(P51) = POrient(P6)

    g_Steps = FTTStepTotal / 8
    g_CurrentSteps = FTTStepStart + g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: touching for angle"
    ''===================== get theta first ========================
    ''this is fine tune, so theta almost there.
    ''we will try to see how much off by touch the dest point
    ''P51 will be standby position
    
    SetFastSpeed
    Tool 2
    Jump P51
    
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset before theta"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    SetVerySlowSpeed
    Tool 0
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, (2 * SAFE_BUFFER_FOR_DETACH), True) Then
        Print "placer failed to touch dest in theta"
        Print #LOG_FILE_NO, "placer failed to touch dest in theta"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    g_Steps = FTTStepTotal / 8
    g_CurrentSteps = FTTStepStart + 2 * FTTStepTotal / 8
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    
    FTTSX(1) = CX(P*)
    FTTSY(1) = CY(P*)
    SetFastSpeed
    
    ''move picker to the standby position by shift magnet length
    ''detach
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
    Move P* +X(SAFE_BUFFER_FOR_DETACH * Cos(tmp_Real)) +Y(SAFE_BUFFER_FOR_DETACH * Sin(tmp_Real))
    ''shift
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 180)
    tmp_DX = (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS) * Cos(tmp_Real)
    tmp_DY = (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS) * Sin(tmp_Real)
   	Move P* +X(tmp_DX) +Y(tmp_DY)

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset during touching for theta"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    SetVerySlowSpeed
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, (2 * SAFE_BUFFER_FOR_DETACH), True) Then
        Print "picker failed to touch dest in theta"
        Print #LOG_FILE_NO, "picker failed to touch dest in theta"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    FTTSX(2) = CX(P*)
    FTTSY(2) = CY(P*)
    SetFastSpeed
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
    Move P* +X(SAFE_BUFFER_FOR_DETACH * Cos(tmp_Real)) +Y(SAFE_BUFFER_FOR_DETACH * Sin(tmp_Real))

    ''calculate theta
    ''touch moving direction
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle - 90)
    tmp_Real2 = Cos(tmp_Real)
    tmp_Real3 = Sin(tmp_Real)
    
    FTTSDeltaU = (FTTSX(1) - FTTSX(2)) * tmp_Real2 + (FTTSY(1) - FTTSY(2)) * tmp_Real3
    FTTSDeltaU = FTTSDeltaU / (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS)
	''here is the one easy to understand   
    ''If g_Perfect_Cradle_Angle = 0 Then
	''    FTTSDeltaU = (FTTSY(2) - FTTSY(1)) / (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS)
    ''ElseIf g_Perfect_Cradle_Angle = 90 Then
	''    FTTSDeltaU = (FTTSX(1) - FTTSX(2)) / (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS)
    ''ElseIf g_Perfect_Cradle_Angle = 180 Then
	''    FTTSDeltaU = (FTTSY(1) - FTTSY(2)) / (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS)
    ''ElseIf g_Perfect_Cradle_Angle = -90 Then
	''    FTTSDeltaU = (FTTSX(2) - FTTSX(1)) / (MAGNET_LENGTH - MAGNET_HEAD_THICKNESS)
    ''Else
    ''    g_RunResult$ = "Cradle must be along one of axes"
    ''    SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
    ''    SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
    ''    Print g_RunResult$
    ''    Print #LOG_FILE_NO, g_RunResult$
    ''    Close #LOG_FILE_NO
    ''    Quit All
    ''EndIf
    
    FTTSDeltaU = Atan(FTTSDeltaU)
    FTTSAdjust = Cos(FTTSDeltaU)
    FTTSDeltaU = RadToDeg(FTTSDeltaU)
    
    Print "theta off: ", FTTSDeltaU, " degree"
    
    FTTSTheta = g_Perfect_Cradle_Angle - FTTSDeltaU  ''now theta is the magnet angle
    
    FTTSTheta = FTTSTheta - CU(P*)
    ''adjust global varialbe
    Print "Old g_MagnetTransportAngle =", g_MagnetTransportAngle
    Print #LOG_FILE_NO, "Old g_MagnetTransportAngle =", g_MagnetTransportAngle
    g_MagnetTransportAngle = FTTSTheta + g_U4MagnetHolder
    g_MagnetTransportAngle = NarrowAngle(g_MagnetTransportAngle)
    
    Print "new g_MagnetTransportAngle=", g_MagnetTransportAngle
    Print #LOG_FILE_NO, "new g_MagnetTransportAngle=", g_MagnetTransportAngle
    
    ''================get b, c====================
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: touching for b-c"

    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
    tmp_DX = (SAFE_BUFFER_FOR_DETACH + HALF_OF_SEAT_THICKNESS) * Cos(tmp_Real)
    tmp_DY = (SAFE_BUFFER_FOR_DETACH + HALF_OF_SEAT_THICKNESS) * Sin(tmp_Real)

	P51 = XY((FTTSDestX + tmp_DX), (FTTSDestY + tmp_DY), CZ(P6), (g_Perfect_Cradle_Angle - 90.0 + FTTSDeltaU))
	POrient(P51) = POrient(P6)

    For FTTSIndex = 1 To 2
        g_Steps = FTTStepTotal / 8
        g_CurrentSteps = FTTStepStart + (2 + FTTSIndex) * FTTStepTotal / 8
        SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

        Tool FTTSIndex
        Jump P51
        Tool 0

        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceResetAndCheck Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
			g_RunResult$ = "force sensor reset failed at fineTuneToolset during touching for b c"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
			Exit Function
		EndIf
        SetVerySlowSpeed
        Select FTTSIndex
            Case 1
                If Not ForceTouch(DIRECTION_CAVITY_HEAD, (SAFE_BUFFER_FOR_DETACH * 2), True) Then
                    Print "tool[", FTTSIndex, "] failed to touch dest"
                    Print #LOG_FILE_NO, "tool[", FTTSIndex, "] failed to touch dest"
                    Close #LOG_FILE_NO
                    
                    Exit Function
                EndIf
		        FTTSX(FTTSIndex) = CX(P*)
		        FTTSY(FTTSIndex) = CY(P*)
                FTTScaleF1 = ReadForce(DIRECTION_CAVITY_HEAD)
                TongMove DIRECTION_CAVITY_HEAD, 1, False
                FTTScaleF2 = ReadForce(DIRECTION_CAVITY_HEAD)
                g_TQScale_Picker = FTTScaleF2 - FTTScaleF1
            Case 2
                If Not ForceTouch(DIRECTION_CAVITY_TAIL, (SAFE_BUFFER_FOR_DETACH * 2), True) Then
                    Print "tool[", FTTSIndex, "] failed to touch dest"
                    Print #LOG_FILE_NO, "tool[", FTTSIndex, "] failed to touch dest"
                    Close #LOG_FILE_NO
                    
                    Exit Function
                EndIf
		        FTTSX(FTTSIndex) = CX(P*)
		        FTTSY(FTTSIndex) = CY(P*)
                FTTScaleF1 = ReadForce(DIRECTION_CAVITY_TAIL)
                TongMove DIRECTION_CAVITY_TAIL, 1, False
                FTTScaleF2 = ReadForce(DIRECTION_CAVITY_TAIL)
                g_TQScale_Placer = FTTScaleF2 - FTTScaleF1
        Send
        Tool FTTSIndex
        SetFastSpeed
        Move P51
    Next
    ''touch moving direction
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle - 90)
    tmp_Real2 = Cos(tmp_Real)
    tmp_Real3 = Sin(tmp_Real)
    FTTSBMC = (FTTSX(2) - FTTSX(1)) * tmp_Real2 + (FTTSY(2) - FTTSY(1)) * tmp_Real3
    ''easy to understand
    ''If g_Perfect_Cradle_Angle = 0 Then
	''    FTTSBMC = FTTSY(1) - FTTSY(2)
    ''ElseIf g_Perfect_Cradle_Angle = 90 Then
	''    FTTSBMC = FTTSX(2) - FTTSX(1)
    ''ElseIf g_Perfect_Cradle_Angle = 180 Then
	''    FTTSBMC = FTTSY(2) - FTTSY(1)
    ''ElseIf g_Perfect_Cradle_Angle = -90 Then
	''    FTTSBMC = FTTSX(1) - FTTSX(2)
    ''Else
    ''    g_RunResult$ = "Cradle must be along one of axes"
    ''    SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
    ''    SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
    ''    Print g_RunResult$
    ''    Print #LOG_FILE_NO, g_RunResult$
    ''    Close #LOG_FILE_NO
    ''    Quit All
    ''EndIf
    
    FTTSB = (MAGNET_LENGTH + FTTSBMC) / 2.0
    FTTSC = (MAGNET_LENGTH - FTTSBMC) / 2.0
    
    ''================try to find a===============================
    g_Steps = FTTStepTotal / 8
    g_CurrentSteps = FTTStepStart + 5 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: touching for a"

    Tool 0
    ''we use improved b, c, and theta with old a to get better toolset first
    If g_ToolSet_A <> 0 Then
        ABCThetaToToolSets g_ToolSet_A, FTTSB, FTTSC, FTTSTheta
    EndIf
    
    ''we will rotate 180 and put magback into cradle
    SetFastSpeed
    Jump P6 +Z(20)
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset before touching for a"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    Move P6 +Z(2)    ''the 2mm here is because both cradle and the magnet hold by tong may not level
    FTTSZ = CZ(P*)
    
    SetVerySlowSpeed
    If Not ForceTouch(DIRECTION_MAGNET_TO_CAVITY, 2, True) Then
        Print "failed to touch in cradle for a in P6"
        Print #LOG_FILE_NO, "failed to touch in cradle for a in P6"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    FTTSX(1) = CX(P*)
    FTTSY(1) = CY(P*)

    g_Steps = FTTStepTotal / 8
    g_CurrentSteps = FTTStepStart + 6 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    ''you can calculate the position, but with toolset, you can easily let robot do that for you:
    ''you just want picker and placer switch places.
    SetFastSpeed
    Move P6 +Z(2)
    Tool 1
    P51 = P*
    Tool 2
    Jump P51 +Z(18)

    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset during touching for a"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    Tool 0
    Move P* :Z(FTTSZ)
    CutMiddle FORCE_XTORQUE
    
    SetVerySlowSpeed
    If Not ForceTouch(DIRECTION_CAVITY_TO_MAGNET, 2, True) Then
        Print "failed to touch in cradle for a in P51"
        Print #LOG_FILE_NO, "failed to touch in cradle for a in P51"
        Close #LOG_FILE_NO
        
        Exit Function
    EndIf
    FTTSX(2) = CX(P*)
    FTTSY(2) = CY(P*)
        
	tmp_Real2 = FTTSX(2) - FTTSX(1)
	tmp_Real3 = FTTSY(2) - FTTSY(1)
	tmp_Real = tmp_Real2 * tmp_Real2 + tmp_Real3 * tmp_Real3 - FTTSBMC * FTTSBMC
	If tmp_Real < 0 Then
        Print "square of A less then 0 ", tmp_Real
        Print #LOG_FILE_NO, "square of A less then 0 ", tmp_Real
        tmp_Real = 0
	EndIf
	tmp_Real = Sqr(tmp_Real) / 2.0
	
    tmp_Real2 = Cos(DegToRad(g_MagnetTransportAngle))
    tmp_Real3 = Sin(DegToRad(g_MagnetTransportAngle))
	FTTSA = ((FTTSX(2) - FTTSX(1)) * tmp_Real3 - (FTTSY(2) - FTTSY(1)) * tmp_Real2) / 2.0
    ''double check
    If Abs(FTTSA * FTTSA - tmp_Real * tmp_Real) > 0.001 Then
        Print "A not match: from square: ", tmp_Real, ", from individual case: ", FTTSA
        Print #LOG_FILE_NO, "A not match: from square: ", tmp_Real, ", from individual case: ", FTTSA
        SPELCom_Event EVTNO_HARDWARE_LOG_WARNING, "A not match, look at log file detail"
    EndIf

    Print "new a:", FTTSA, ", b:", FTTSB, ", c:", FTTSC, ", theta:", FTTSTheta
    Print "old a:", g_ToolSet_A, ", b:", g_ToolSet_B, ", c:", g_ToolSet_C, ", theta:", g_ToolSet_Theta

    Print #LOG_FILE_NO, "new a:", FTTSA, ", b:", FTTSB, ", c:", FTTSC, ", theta:", FTTSTheta
    Print #LOG_FILE_NO, "old a:", g_ToolSet_A, ", b:", g_ToolSet_B, ", c:", g_ToolSet_C, ", theta:", g_ToolSet_Theta

	''give warning if changes are too big to be true.
	If g_ToolSet_A <> 0 And g_ToolSet_B <> 0 And g_ToolSet_C <> 0 Then
		If Abs(g_ToolSet_A - FTTSA) > 2 Then
			Print "Toolset A changes too big to be true"
			Print #LOG_FILE_NO, "Toolset A changes too big to be true"
			SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "Toolset A changes too big to be true"
		EndIf
		If Abs(g_ToolSet_B - FTTSB) > 2 Then
			Print "Toolset B changes too big to be true"
			Print #LOG_FILE_NO, "Toolset B changes too big to be true"
			SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "Toolset B changes too big to be true"
		EndIf
		If Abs(g_ToolSet_C - FTTSC) > 2 Then
			Print "Toolset C changes too big to be true"
			Print #LOG_FILE_NO, "Toolset C changes too big to be true"
			SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "Toolset C changes too big to be true"
		EndIf
		If Abs(g_ToolSet_Theta - FTTSTheta) > 10 Then
			Print "Toolset Theta changes too big to be true"
			Print #LOG_FILE_NO, "Toolset Theta changes too big to be true"
			SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, "Toolset Theta changes too big to be true"
		EndIf
	EndIf

    g_ToolSet_A = FTTSA
    g_ToolSet_B = FTTSB
    g_ToolSet_C = FTTSC
    g_ToolSet_Theta = FTTSTheta
    SPELCom_Event EVTNO_UPDATE, "New Toolset A:", g_ToolSet_A, ", B:", g_ToolSet_B, ", C:", g_ToolSet_C, ", Theta:", g_ToolSet_Theta
    ''========================== calculate ========================
    ABCThetaToToolSets FTTSA, FTTSB, FTTSC, FTTSTheta
    
    ''======================putback magnet=======================
    g_Steps = FTTStepTotal / 8
    g_CurrentSteps = FTTStepStart + 7 * g_Steps
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "fine tune toolset: Touching Z for Toolset 2"

    Tool 0
    SetFastSpeed
    Jump P6

    ''save absolute position of magnet so we can decide whether deware moved or tong bended
    CheckPoint 56
    Print "old (absolute magnet position) P56,", CX(P56), ",", CY(P56), ",", CZ(P56), ",", CU(P56)
    Print #LOG_FILE_NO, "old (absolute magnet position) P56,", CX(P56), ",", CY(P56), ",", CZ(P56), ",", CU(P56)
    Tool 1
    P56 = P*
    Print "new P56,", CX(P56), ",", CY(P56), ",", CZ(P56), ",", CU(P56), " ", Date$, " ", Time$
    Print #LOG_FILE_NO, "new P56,", CX(P56), ",", CY(P56), ",", CZ(P56), ",", CU(P56), " ", Date$, " ", Time$

    ''==============================Z offset for placer==========================
    ''get the center of cradle to touch Z
    Tool 2
    P51 = P* + P56
    P51 = XY((CX(P51) / 2), (CY(P51) / 2), (CZ(P51) / 2), (CU(P51) / 2))
    ''move out 3 mm to give more space to the fingers.
    tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
    tmp_DX = 3 * Cos(tmp_Real)
    tmp_DY = 3 * Sin(tmp_Real)
    P51 = P51 +X(tmp_DX) +Y(tmp_DY)
    POrient(P51) = POrient(P6)
    
    ''touch using picker
    Tool 1
    SetFastSpeed
    CU(P51) = CU(P6) - 60
    Jump P51
    Tool 0
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset before touching picker Z"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    SetVerySlowSpeed
    If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
        Print "failed to touch cradle for Z by picker"
        Print #LOG_FILE_NO, "failed to touch cradle for Z by picker"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    FTTSZ = CZ(P*) ''save picker's Z
    Print "picker touched cradle at Z=", CZ(P*)
    
    If Not CheckRigidness Then
        Print "Gripper finger loose at picker side"
        Print #LOG_FILE_NO, "Gripper finger loose at picker side"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    
    Tool 2
    SetFastSpeed
    CU(P51) = CU(P6) + 240
    Jump P51
    Tool 0
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at fineTuneToolset before touching placer Z"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    SetVerySlowSpeed
    If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
        Print "failed to touch cradle for Z by placer"
        Print #LOG_FILE_NO, "failed to touch cradle for Z by placer"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    Print "placer touched cradle at Z=", CZ(P*)
    FTTSZ = FTTSZ - CZ(P*)

    If Not CheckRigidness Then
        Print "Gripper finger loose at place side"
        Print #LOG_FILE_NO, "Gripper finger loose at placer side"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    SetFastSpeed
    Jump P6

    ''save Zoffset for placer toolset    
    Print "placer ZOffset: ", FTTSZ
    P51 = TLSet(2)
    TLSet 2, P51 :Z(FTTSZ)

    ''print out old toolset
    P51 = TLSet(1)
    SPELCom_Event EVTNO_UPDATE, "New TLSet 1: (", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ")"
    P51 = TLSet(2)
    SPELCom_Event EVTNO_UPDATE, "New TLSet 2: (", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ")"

#ifdef AUTO_SAVE_POINT
    Print "saving points to file.....", 
    SavePoints "robot1.pnt"
    SaveToolSetHistory 1, g_FCntToolFine
    SaveToolSetHistory 2, g_FCntToolFine
    SavePointHistory 10, g_FCntToolFine
    SavePointHistory 11, g_FCntToolFine
    SavePointHistory 56, g_FCntToolFine
    Print "done!!"
    SPELCom_Event EVTNO_UPDATE, "new P56: (", CX(P56), ", ", CY(P56), ", ", CZ(P56), ", ", CU(P56), ")"
#endif

    If Not Open_Gripper Then
        g_RunResult$ = "fine tune toolset: Open_Gripper Failed, holding magnet, need Reset"
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
        Motor Off
        Quit All
    EndIf

    Move P3
    g_HoldMagnet = False

    ''check magnet level error
    MagLevelError = Abs(FTTSZ)
    Print "magnet level error: ", MagLevelError, "mm"
    Print #LOG_FILE_NO, "magnet level error: ", MagLevelError, "mm"
    SPELCom_Event EVTNO_UPDATE, "level errors: magnet", MagLevelError, "mm, post", PostLevelError, "mm"
    If MagLevelError >= ACCPT_THRHLD_MAGNET_LEVEL Then
        Print "Warning: magnet level error exceeded threshold (", ACCPT_THRHLD_MAGNET_LEVEL, "mm)"
        Print #LOG_FILE_NO, "Warning: magnet level error exceeded threshold (", ACCPT_THRHLD_MAGNET_LEVEL, "mm)"
        Magnet_Warning$ = Magnet_Warning$ + "Magnet Level Error Exceed Threshold"
        SPELCom_Event EVTNO_WARNING, Magnet_Warning$
    EndIf

    Close #LOG_FILE_NO
    
    LimZ 0
    
    FineTuneToolSet = True
Fend

Function RunABCTheta
    WOpen "ABCTheta.Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    
    ABCThetaToToolSets g_ToolSet_A, g_ToolSet_B, g_ToolSet_C, g_ToolSet_Theta
    Close #LOG_FILE_NO
    
Fend

Function SetupTSForMagnetCal
    CheckToolSet 1
    CheckToolSet 2
       P51 = TLSet(1)
       P52 = TLSet(2)
       If CX(P51) <> 0 And CY(P51) <> 0 And CX(P52) <> 0 And CY(P52) <> 0 Then
           TLSet 3, XY(((CX(P51) + CX(P52)) / 2), ((CY(P51) + CY(P52)) / 2), ((CZ(P51) + CZ(P52)) / 2), CU(P51))
       Else
           TLSet 3, XY(-2, -15.75, 0, (g_MagnetTransportAngle - g_U4MagnetHolder))
       EndIf
Fend

Function DiffPickerPlacer As Real
    InitForceConstants
    Init_Magnet_Constants

    g_HoldMagnet = True
    g_SafeToGoHome = True

    DiffPickerPlacer = 0.0

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf
    
    Wait 2 * TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at DiffPickerPlacer"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf

    ''touch using picker
    If Not g_FlagAbort Then
        Tool 1
        P51 = P*
        Tool 0
        SetVerySlowSpeed
        If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
            Print "failed to touch a bottom in 20 mm"
            Exit Function
        EndIf
        DPPPickerZ = CZ(P*)
        SetFastSpeed
        Move P* +Z(5)
        Print "picker touched at ", DPPPickerZ
    EndIf

    ''touch using placer
    Wait 2 * TIME_WAIT_BEFORE_RESET
    ForceResetAndCheck
    If Not g_FlagAbort Then
        Tool 2
        Go P51
        Tool 0
        SetVerySlowSpeed
        If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
            Print "failed to touch a bottom in 20 mm"
            Exit Function
        EndIf
        DPPPlacerZ = CZ(P*)
        SetFastSpeed
        Move P* +Z(5)
        Print "placer touched at ", DPPPlacerZ
    EndIf
    
    ''calculate
    DiffPickerPlacer = DPPPickerZ - DPPPlacerZ
    If DiffPickerPlacer < 0 Then
        Print "Picker is higher than Placer for ", -DiffPickerPlacer, "mm"
    Else
        Print "Picker is lower than Placer for ", DiffPickerPlacer, "mm"
    EndIf

    P52 = TLSet(2)
    Print "old Z for Toolset 2: ", CZ(P52)

    ''go back to original place
    If Not g_FlagAbort Then
        Tool 1
        Go P51
        Tool 0
    EndIf
    Motor Off
Fend


Function VB_MagnetCal
    ''init result
    g_RunResult$ = ""
    
    ''parse argument from global
    ParseStr g_RunArgs$, VBMCTokens$(), " "
    ''check argument
    VBMCArgC = UBound(VBMCTokens$) + 1



    If VBMCArgC > 0 Then
        Select VBMCTokens$(0)
        Case "0"
               g_IncludeFindMagnet = False
        Case "1"
               g_IncludeFindMagnet = True
        Send
    EndIf
    If VBMCArgC > 1 Then
        Select VBMCTokens$(1)
        Case "0"
            g_Quick = False
        Case "1"
            g_Quick = True
        Send
    EndIf
    
    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    If Not MagnetCalibration() Then
        If g_FlagAbort Then
            g_RunResult$ = "User Abort"
        EndIf
        Recovery
        SPELCom_Return 1
    EndIf
    SPELCom_Return 0
Fend

Function StripCalibration As Boolean
    CPCStepStart = g_CurrentSteps
    CPCStepTotal = g_Steps

    ''prevent sub functions to update progress bar
    g_Steps = 0

	StripCalibration = False

    InitForceConstants
    g_OnlyAlongAxis = True
    g_SafeToGoHome = True

    ''log file
    g_FCntStrip = g_FCntStrip + 1
    WOpen "StripPosition" + Str$(g_FCntStrip) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "strip position calibration at ", Date$, " ", Time$
    Print "strip position calibration at ", Date$, " ", Time$


    ''safety check
    Tool 0
    If Not isCloseToPoint(3) Then
        Print "FAILED: It must start from P3 position"
        Print #LOG_FILE_NO, "FAILED: It must start from P3 position"
        Close #LOG_FILE_NO
        Exit Function
    EndIf
    
    g_HoldMagnet = False
    ''take magnet
    ''==================get the magnet=================
    SPELCom_Event EVTNO_CAL_MSG, "strip cal: take magnet"

    SetFastSpeed
    Go P3
    If Not Open_Gripper Then
        g_RunResult$ = "strip cal: Open_Gripper Failed at beginning"
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_ERROR, g_RunResult$
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    If g_FlagAbort Then
        Print #LOG_FILE_NO, "user abort at home"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    Move P6

    Move P* +Z(20)

    If Not Close_Gripper Then
        Print "close gripper failed at holding magnet for toolset aborting"
        SPELCom_Event EVTNO_CAL_MSG, "strip cal: abort: close gripper failed at magnet"
        SPELCom_Event EVTNO_LOG_ERROR, "Strip Cal: abort: close gripper failed at magnet"
        Move P6
        If Not Open_Gripper Then
            Print "open gripper failed at aborting from magnet, need Reset"
            SPELCom_Event EVTNO_CAL_MSG, "open gripper failed at aborting"
            SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset"
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Print #LOG_FILE_NO, "need reset in tlsetfinetune"
            Close #LOG_FILE_NO
            Motor Off
            Quit All
        EndIf
        Move P3
        LimZ 0
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Print #LOG_FILE_NO, "aborted: cannot close gripper"
        Close #LOG_FILE_NO
        Exit Function
    EndIf

    g_HoldMagnet = True

    LimZ g_Jump_LimZ_Magnet
    
    g_CurrentSteps = CPCStepStart + CPCStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

	''==================calculate the position first===============
	''move away from cradle STRIP_PLACER_X_OFFSET
	''shift to left STRIP_PLACER_Y_OFFSET
	tmp_Real = DegToRad(g_Perfect_Cradle_Angle + 90)
	tmp_DX = STRIP_PLACER_X_OFFSET * Cos(tmp_Real)
	tmp_DY = STRIP_PLACER_X_OFFSET * Sin(tmp_Real)

	tmp_Real2 = DegToRad(g_Perfect_Cradle_Angle)
	tmp_DX = tmp_DX + STRIP_PLACER_Y_OFFSET * Cos(tmp_Real2)
	tmp_DY = tmp_DY + STRIP_PLACER_Y_OFFSET * Sin(tmp_Real2)
	Tool 2
	''here 20 is from we moved tong to P6+20
	P8 = P* +X(tmp_DX) +Y(tmp_DY) -Z(STRIP_PLACER_Z_OFFSET + 20) +U(90)
	''P80 is standby point, away 10 mm
	tmp_DX = STANDBY_DISTANCE * Cos(tmp_Real)
	tmp_DY = STANDBY_DISTANCE * Sin(tmp_Real)
	P80 = P8 +X(tmp_DX) +Y(tmp_DY) +Z(STRIP_PLACER_LIFT_Z)

	''=================== calibration============================
	''touch out X first,
	''then try to moving and touch out Z
	''Y: we may touch out or we just use the calculation
	''U: we will use the calculation

	''touching X
	Jump P80
    Wait 2 * TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at StripCalibration"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not g_FlagAbort Then
	    SPELCom_Event EVTNO_CAL_MSG, "strip cal: touching for X"
	    g_SafeToGoHome = False
        SetVerySlowSpeed
        If Not ForceTouch(DIRECTION_CAVITY_TAIL, 14, True) Then
			Print "failed to touch the strip X"
			Print #LOG_FILE_NO, "failed to touch strip X"
			Close #LOG_FILE_NO
			
			Move P80
		    g_SafeToGoHome = True
			Exit Function
        EndIf
        CPCInitX = CX(P*)
        CPCInitY = CY(P*)
        ''detach
        SetFastSpeed
        TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_DETACH, False
        Move P* -Z(STRIP_PLACER_LIFT_Z)
        P81 = P*
        CPCInitZ = CZ(P*)
        CPCInitU = CU(P*)
        Print "strip X touched at ", CPCInitX
    EndIf

    g_CurrentSteps = CPCStepStart + 2 * CPCStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    
    ''=========touch out Z===========
    ''try to move in first, if failed, scan it
    If Not g_FlagAbort Then
	    SPELCom_Event EVTNO_CAL_MSG, "strip cal: touching for Z"
        If ForceTouch(DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_DETACH + 3, False) Then
			Print "need to scan Z for strip position"
			Print #LOG_FILE_NO, "scan Z for strip position"
			Move P81
			Move P* -Z(STRIP_PULL_OUT_Z_RANGE / 2.0)
			Wait 2
			If Not ForceResetAndCheck Then
				g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
				g_RunResult$ = "force sensor reset failed at StripCalibration during touch out z"
				Print g_RunResult$
				SPELCom_Return 1
				SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
				Exit Function
			EndIf
			If Not FindZForStripper Then
				Print "failed to scan strip Z"
				Print #LOG_FILE_NO, "failed to scan strip Z"

				Move P80
				g_SafeToGoHome = True
				Close #LOG_FILE_NO
				Exit Function
			EndIf
        EndIf
		CPCInitZ = CZ(P*)
    EndIf

    g_CurrentSteps = CPCStepStart + 3 * CPCStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"

    ''fine tune Z
    If Not g_FlagAbort Then
	    SPELCom_Event EVTNO_CAL_MSG, "strip cal: fine tune for Z"
		Print "moved in Z=", CPCInitZ, "and fine tune Z"
		Print #LOG_FILE_NO, "moved in at Z=", CPCInitZ, "fine tune Z"
		Move P* :X(CPCInitX)
		TongMove DIRECTION_CAVITY_TAIL, MAGNET_HEAD_THICKNESS / 2, False
		''ForcedCutMiddle FORCE_ZFORCE
    	CutMiddleWithArguments FORCE_ZFORCE, 0, GetForceThreshold(FORCE_ZFORCE), 2, 20
    EndIf

    g_CurrentSteps = CPCStepStart + 4 * CPCStepTotal / 5
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    
    ''OK
    If Not g_FlagAbort Then
		TongMove DIRECTION_CAVITY_HEAD, MAGNET_HEAD_THICKNESS / 2, False
		P8 = P*
        SavePoints "robot1.pnt"

	    SavePointHistory 8, g_FCntStrip
		StripCalibration = True
		Print "done, new P8=", P8
		Print #LOG_FILE_NO, "moved in at Z=", CPCInitZ, "fine tune Z"

		TongMove DIRECTION_CAVITY_HEAD, SAFE_BUFFER_FOR_DETACH, False
	    SPELCom_Event EVTNO_CAL_MSG, "strip cal: done"
    EndIf

    If Not StripCalibration Then
	    If Not g_FlagAbort Then
			Print "Strip Cal failed"
	    Else
			Print "Strip Cal user abort"
	    EndIf
	EndIf

	''put magnet back
	Move P80
    g_SafeToGoHome = True
	Tool 0
	SetFastSpeed
	Jump P6

    If Not Open_Gripper Then
        g_RunResult$ = "Open_Gripper Failed, holding magnet, need Reset"
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
        Motor Off
        Quit All
    EndIf

    Move P3
    g_HoldMagnet = False
	Close #LOG_FILE_NO
Fend

''modified from PullOutZ
Function FindZForStripper As Boolean
    SPELCom_Event EVTNO_CAL_MSG, "strip cal: pull out Z"
    FindZForStripper = False
    
    POZOldX = CX(P*)
    POZOldY = CY(P*)
    POZOldZ = CZ(P*)

	''step size
	StepSize = STRIP_PULL_OUT_Z_RANGE / STRIP_PULL_OUT_Z_STEP

    For StepIndex = 1 To STRIP_PULL_OUT_Z_STEP
        Move P* +Z(StepSize)
        If Not ForceTouch(DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_DETACH + 3, False) Then
            If Not g_FlagAbort Then
                FindZForStripper = True
                Print "got Z at ", CZ(P*)
            Else
                TongMove DIRECTION_CAVITY_HEAD, 20, False
            EndIf
            Exit Function
        EndIf
        Move P* :X(POZOldX) :Y(POZOldY)
    Next
    
    Print "not got Z for strip position"
Fend

Function CheckRigidness As Boolean
	''Raise 1 mm
	''reset force sensor
	''come back
	''pressure for 0.05mm
	''save the force and position then back off
	
	Move P* +Z(1)
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at CheckRigidness"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    
    Move P* -Z(1)
    CKRNF1 = ReadForce(FORCE_ZFORCE)
    
    Move P* -Z(0.05)
    CKRNF2 = ReadForce(FORCE_ZFORCE)
  	Move P* +Z(0.05)
  
  	''calculate the rigidness
  	If Abs(CKRNF2 - CKRNF1) < 1 Then
  		CheckRigidness = False
  	Else
  		CheckRigidness = True
  	EndIf
Fend

Function TestRigid
    InitForceConstants
    Init_Magnet_Constants

    g_HoldMagnet = True
    g_SafeToGoHome = True

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf
    
    Wait 2 * TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at TestRidid"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf

    ''touch using picker
    If Not g_FlagAbort Then
        Tool 1
        P51 = P*
        Tool 0
        SetVerySlowSpeed
        If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
            Print "failed to touch a bottom in 20 mm"
            Exit Function
        EndIf
        DPPPickerZ = CZ(P*)
        If Not CheckRigidness Then
        	Print "check rigidness failed"
        EndIf
        SetFastSpeed
        Move P* +Z(5)
        Print "picker touched at ", DPPPickerZ
    EndIf

    ''touch using placer
    Wait 2 * TIME_WAIT_BEFORE_RESET
    If Not ForceResetAndCheck Then
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
        g_RunResult$ = "force sensor reset failed at testRigid for placer"
        Print g_RunResult$
        SPELCom_Return 1
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Exit Function
    EndIf
    If Not g_FlagAbort Then
        Tool 2
        Go P51
        Tool 0
        SetVerySlowSpeed
        If Not ForceTouch(-FORCE_ZFORCE, 20, True) Then
            Print "failed to touch a bottom in 20 mm"
            Exit Function
        EndIf
        DPPPlacerZ = CZ(P*)
        If Not CheckRigidness Then
        	Print "check rigidness failed"
        EndIf
        SetFastSpeed
        Move P* +Z(5)
        Print "placer touched at ", DPPPlacerZ
    EndIf
    
    ''go back to original place
    If Not g_FlagAbort Then
        Tool 1
        Go P51
        Tool 0
    EndIf
    Motor Off
	
Fend

