#include "robotdefs.inc"

''==========================================================
''MODULE GONIOMETER CALIBRATION
''==========================================================
'' any tmp_ prefix means this varible cannot cross function call
''they can be used by any function.
Integer tmp_PIndex

''==========================================================
'' LOCAL varibles: because it crashes system when there are
'' a lot of local variables, many local variables are moved here
''=========================================================
Real GonioX
Real GonioY
Real GonioZ
Real GonioU
Real GNArcX
Real GNArcY
Real GNArcRadius
Real GNForce

Real BTStandbySteps(4)
Real GonioStandbySteps(4)

Boolean VBGNInit
Real VBGNDX
Real VBGNDY
Real VBGNDZ
Real VBGNDU
String VBGNTokens$(0)

Integer GNWait
Integer GNUpstreamDir

Integer GNPullTimes
Real GNFreeHorz
Real GNFreeVert

Real tmp_Real1
Real tmp_Real2
Real GNDwnStrmRad

''fromPoint should be P16 (right hand, most cases) or P26 (SSRL BL 11-3)
Function CheckTongBigChange As Boolean
	CheckTongBigChange = True
    ''check P76 to see if P16 was copied to P76 in previous run
    CheckPoint 76
    If CX(P76) = 0 Or CY(P76) = 0 Or CZ(P76) = 0 Then
        Exit Function
    EndIf
    
    ''check to see if P16 changed a lot
    
    If Dist(P16, P76) > 5 Then
        CheckTongBigChange = False
        g_RunResult$ = "P76 and P16 too big difference.  Run Manual Gonio CAL"
        Print g_RunResult$
        Exit Function
    EndIf
Fend

''support from P21 or P22
Function GoHomeFromGonio
    If Not g_SafeToGoHome Then
        Exit Function
    EndIf
    
    If isCloseToPoint(21) Then
		SetFastSpeed
		''detach
		Move P24
	EndIf
	
    If isCloseToPoint(24) Then
		''raise and check force
	    SetVerySlowSpeed
	    If ForceTouch(FORCE_ZFORCE, 10, False) Then
			g_SafeToGoHome = False
			g_RunResult$ = "tong touched something on its way home from goniometer. Need reset"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
			Motor Off
			Quit All
	    EndIf
		SetFastSpeed
		Move P22
	EndIf
    If isCloseToPoint(22) Then
		If g_LN2LevelHigh Then
			TurnOnHeater
		EndIf
		SetVeryFastSpeed
		Move P38 CP
		Arc P28, P18 CP
#ifdef MIXED_ARM_ORIENTATION
		Go P1
#else
		Move P1
#endif
		MoveTongHome
        Exit Function
    EndIf

    g_SafeToGoHome = False
Fend


Function GonioCalibraion(Init As Boolean, dx As Real, dy As Real, dz As Real, du As Real) As Boolean
    GonioCalibraion = False
    g_HoldMagnet = False
    g_SafeToGoHome = False
    
    InitForceConstants
    g_OnlyAlongAxis = True

    ''log file
    g_FCntGonio = g_FCntGonio + 1
    WOpen "GoniometerCal" + Str$(g_FCntGonio) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    Print #LOG_FILE_NO, "Goniometer calibration at ", Date$, " ", Time$
    Print #LOG_FILE_NO, "dx=", dx, "dy=", dy, ", dz=", dz, "du=", du

    SPELCom_Event EVTNO_CAL_STEP, "0 of 100"


    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    Tool 0
    If Not Init Then
        g_SafeToGoHome = True

        CheckPoint 20
        GonioX = CX(P20)
        GonioY = CY(P20)
        If GonioX = 0 Or GonioY = 0 Then
            g_RunResult$ = "P20 not defined yet, run GonioCalibration with Init first"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            SPELCom_Return 1
            ''not need recovery
            g_SafeToGoHome = False
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
            Exit Function
        EndIf
        
        If Not CheckTongBigChange() Then
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            SPELCom_Return 1
            ''not need recovery
            g_SafeToGoHome = False
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
            Exit Function
        EndIf

        GonioX = CX(P20)
        GonioY = CY(P20)
        GonioZ = CZ(P20)
        GonioU = CU(P20)
        
        ''adjust P20 to P21
        GonioX = GonioX + dx
        GonioY = GonioY + dy
        GonioZ = GonioZ + dz
        GonioU = GonioU + du
        P21 = P20 + XY(dx, dy, dz, du)
        
        GNDwnStrmRad = DegToRad(g_Perfect_DownStream_Angle)
        
        CalculateStepSize DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_GONIO_DETACH + GONIO_OVER_MAGNET_HEAD, GonioU, GonioStandbySteps()
        P23 = P21 +X(GONIO_X_SAFE_BUFFER * Cos(GNDwnStrmRad)) +Y(GONIO_X_SAFE_BUFFER * Sin(GNDwnStrmRad))
        P24 = P21 +X(GonioStandbySteps(1)) +Y(GonioStandbySteps(2))
        ''P22 take both offset of P23 and P24
        P22 = P23 +X(GonioStandbySteps(1)) +Y(GonioStandbySteps(2)) :Z(-1)

		tmp_Real1 = CX(P22) - CX(P18)
		tmp_Real2 = CY(P22) - CY(P18)
		
		''have to arc, moving exceeds arm limit.
		''1-0.707=0.293
		If Abs(tmp_Real1) > Abs(tmp_Real2) Then
			If tmp_Real1 * tmp_Real2 > 0 Then
				P38 = P18 +X(tmp_Real2) +Y(tmp_Real2)
				P28 = P18 +X(0.293 * tmp_Real2) +Y(0.707 * tmp_Real2)
			Else
				P38 = P18 -X(tmp_Real2) +Y(tmp_Real2)
				P28 = P18 -X(0.293 * tmp_Real2) +Y(0.707 * tmp_Real2)
			EndIf
		Else
			If tmp_Real1 * tmp_Real2 > 0 Then
				P38 = P18 +X(tmp_Real1) +Y(tmp_Real1)
				P28 = P18 +X(0.707 * tmp_Real1) +Y(0.293 * tmp_Real1)
			Else
				P38 = P18 +X(tmp_Real1) -Y(tmp_Real1)
				P28 = P18 +X(0.707 * tmp_Real1) -Y(0.293 * tmp_Real1)
			EndIf
		EndIf

		''remove after DEBUG                
        SavePoints "robot1.pnt"

        ''check current position
        If ( Not isCloseToPoint(0)) And ( Not isCloseToPoint(1)) Then
            g_RunResult$ = "must start from home"
            Print g_RunResult$
            g_SafeToGoHome = False
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: failed", g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, "aborted ", g_RunResult$
            Exit Function
        EndIf
        
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: move tong to dewar"

        ''check conditions
        If Not Check_Gripper Then
            ''not need recovery
            g_SafeToGoHome = False
            Close #LOG_FILE_NO
            Exit Function
        EndIf
        If Not Open_Lid Then
            ''not need recovery
            g_SafeToGoHome = False
            Close #LOG_FILE_NO
            Exit Function
        EndIf
        If Not Close_Gripper Then
            ''not need recovery
            g_SafeToGoHome = False
            Close #LOG_FILE_NO
            Exit Function
        EndIf

        SetFastSpeed
        
        Jump P1
                
        If g_LN2LevelHigh Then
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: cool tong 100 seconds"
            Jump P3
            ''Wait 100    ''double (40 seconds the same as mount/dismount)
			If g_IncludeStrip Then
				Move P* -Z(STRIP_PLACER_Z_OFFSET)
			EndIf
            For GNWait = 1 To 100
                If g_FlagAbort Then
                    SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
                    Close #LOG_FILE_NO
                    Exit Function
                EndIf
                Wait 1
            Next
            Move P* :Z(-2)
        EndIf
        
        If g_FlagAbort Then
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
            Exit Function
        EndIf

        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: move tong to goniometer"
        SetVeryFastSpeed
   #ifdef MIXED_ARM_ORIENTATION
   		Go P18 CP
   #else
        Move P18 CP
   #endif
		Arc P28, P38 CP
        Move P22

        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceResetAndCheck Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
			g_RunResult$ = "force sensor reset failed at start of GonioCalibration"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            Close #LOG_FILE_NO
			GoHomeFromGonio
			Exit Function
		EndIf

        If g_FlagAbort Then
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
			GoHomeFromGonio
            Exit Function
        EndIf
        
        ''move down to 10 mm above goniometer
        ''slowly down with force sensor on to goniometer level
        ''slowly side step to goniometer with force sensor on
        ''if any resistance, adjust and try to get it.
        ''if failed to get it, flag failed and go home
        SetFastSpeed
        Move P22 :Z(GonioZ + 10)
	    SetVerySlowSpeed
	    If ForceTouch(-FORCE_ZFORCE, 10, False) Then
            Close #LOG_FILE_NO

			Move P22
			GoHomeFromGonio

			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
			g_RunResult$ = "something blocked tong move to goniometer while it is touching down"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
			Exit Function
	    EndIf
        If g_FlagAbort Then
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
			Move P22
			GoHomeFromGonio
            Exit Function
        EndIf
	    
	    ''now side step to P24 with force sensor on
	    ''we know the direction should be up stream
	    ''we need to convert to our left or right
	    ''assume toolset 1 theta is very small
	    tmp_Real1 = NarrowAngle(g_Perfect_DownStream_Angle + 180 - GonioU)
	    ''tmp_Real is around +90 or -90
	    If tmp_Real1 > 0 Then
			GNUpstreamDir = DIRECTION_MAGNET_TO_CAVITY
	    Else
			GNUpstreamDir = DIRECTION_CAVITY_TO_MAGNET
	    EndIf
	    
	    ''try to side step in
	    ''remember start position in case need to try again
		P51 = P*
	    For GNPullTimes = 1 To 3
			If Not ForceTouch(GNUpstreamDir, (GONIO_X_SAFE_BUFFER - CAVITY_RADIUS), False) Then
				Exit For
			EndIf
			Select GNPullTimes
				Case 1
					''shift 1 mm back
					Move P51
					TongMove DIRECTION_CAVITY_TAIL, 1, False
					P51 = P*
				Case 2
					''shift 1 mm forwar from the original place
					Move P51
					TongMove DIRECTION_CAVITY_HEAD, 2, False
					P51 = P*
				Case 3
					g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
					g_RunResult$ = "something blocked tong move to goniometer while it is side stepping in"
					Print g_RunResult$
					SPELCom_Return 1
					SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
		            Close #LOG_FILE_NO

					Move P51
					Move P22
					GoHomeFromGonio
					Exit Function
			Send
	    Next
        If g_FlagAbort Then
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
			Move P22
			GoHomeFromGonio
            Exit Function
        EndIf
	    ''now push forward to touch goniometer head with cavity edge
		P51 = P*
        If Not ForceTouch(DIRECTION_CAVITY_HEAD, 10, True) Then
            g_RunResult$ = "FAILED: calibrate goniometer cannot touch the head after side step in"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Return 2
            Close #LOG_FILE_NO
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$

			Move P51
			Move P22
			GoHomeFromGonio
            Exit Function
        EndIf
		''now move in to cover goniometer head with cavity
		TongMove DIRECTION_CAVITY_TAIL, 1, False
		TongMove GNUpstreamDir, CAVITY_RADIUS, False
		P24 = P*
		TongMove DIRECTION_CAVITY_HEAD, 1 + GONIO_OVER_MAGNET_HEAD, False
    Else
        ''someone manually put the cavity over the goniometer
        GonioX = CX(P*)
        GonioY = CY(P*)
        GonioZ = CZ(P*)
        GonioU = CU(P*)
    EndIf

	''may adjust U so that tong cavity is at 0, 90, 180, 270.
	''we know cavity is same direction as dumbbell strong end
    Tool 1
	''this is the cavity direction
	tmp_Real1 = CU(P*)
    Tool 0
	While tmp_Real1 < 0
		tmp_Real1 = tmp_Real1 + 360.0
	Wend
	tmp_Real2 = 90.0 * Int(tmp_Real1 / 90.0 + 0.5)
	tmp_Real1 = tmp_Real2 - tmp_Real1
	
	If Abs(tmp_Real1) < 10.0 Then
		Go P* +U(tmp_Real1)
	EndIf
        
    Print "init position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "init position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"

    SPELCom_Event EVTNO_CAL_MSG, "gonio cal: adjust position for cut middle"

    g_CurrentSteps = 0
    g_Steps = 12
    SetVerySlowSpeed
    GNForce = ReadForce(DIRECTION_CAVITY_HEAD)
    If Abs(GNForce) >= Abs(GetTouchMin(DIRECTION_CAVITY_HEAD)) Then
        If Not ForceCross(DIRECTION_CAVITY_TAIL, GetTouchMin(DIRECTION_CAVITY_HEAD), 2, 4, False) Then
            g_RunResult$ = "too big force against goniometer"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal:", g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
            Close #LOG_FILE_NO
            If Not Init Then
                Move P24
                GoHomeFromGonio
            EndIf
            Exit Function
        EndIf
		TongMove DIRECTION_CAVITY_TAIL, 0.8, False
    Else
        ''If Not ForceTouch(DIRECTION_CAVITY_HEAD, 4, True) Then
        ''    g_RunResult$ = "failed to touch goniometer"
        ''    Print g_RunResult$
        ''    Print #LOG_FILE_NO, g_RunResult$
        ''    SPELCom_Event EVTNO_CAL_MSG, "gonio cal:", g_RunResult$
        ''    SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
        ''    Close #LOG_FILE_NO
        ''    If Not Init Then
        ''        Move P21
        ''        GoHomeFromGonio
        ''    EndIf
        ''    Exit Function
        ''EndIf
        
    EndIf

    ''find X
    If Not g_FlagAbort Then
        g_CurrentSteps = 12
        g_Steps = 24
        SPELCom_Event EVTNO_CAL_STEP, "12 of 100"
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: cut middle horizontally"

        GNFreeHorz = CutMiddleWithArguments(FORCE_YTORQUE, 0, GetForceThreshold(FORCE_YTORQUE), 3, 30)
        If g_CutMiddleFailed <> 0 Or GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
            g_RunResult$ = "Cut middle failed for X. abort"
	        If GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
	            g_RunResult$ = "Cut middle failed for X, freedom too big to be true. abort"
	        EndIf
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
            Close #LOG_FILE_NO
            If Not Init Then
                Move P24
                GoHomeFromGonio
            EndIf
            Exit Function
        EndIf

        Print #LOG_FILE_NO, "after cut middle for X (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    EndIf

    ''find Z
    If Not g_FlagAbort Then
        g_CurrentSteps = 36
        g_Steps = 24
        SPELCom_Event EVTNO_CAL_STEP, "36 of 100"
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: cut middle vertically"

        GNFreeVert = CutMiddleWithArguments(FORCE_ZFORCE, 0, GetForceThreshold(FORCE_ZFORCE), 3, 60)
        If g_CutMiddleFailed <> 0 Or GNFreeVert > ACCPT_THRHLD_GONIO_FREEDOM Then
            g_RunResult$ = "Cut middle failed for Z. abort"
	        If GNFreeVert > ACCPT_THRHLD_GONIO_FREEDOM Then
	            g_RunResult$ = "Cut middle failed for Z, freedom too big to be true. abort"
	        EndIf
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
            Close #LOG_FILE_NO
            If Not Init Then
                Move P24
                GoHomeFromGonio
            EndIf
            Exit Function
        EndIf
        Print #LOG_FILE_NO, "after cut middle for Z (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    EndIf

    ''find X again after Z centered
    If Not g_FlagAbort Then
        g_CurrentSteps = 60
        g_Steps = 24
        SPELCom_Event EVTNO_CAL_STEP, "60 of 100"
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: cut middle horizontally again"

        GNFreeHorz = CutMiddleWithArguments(FORCE_YTORQUE, 0, GetForceThreshold(FORCE_YTORQUE), 3, 30)
        If g_CutMiddleFailed <> 0 Or GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
            g_RunResult$ = "Cut middle failed for X after Z. abort"
	        If GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
	            g_RunResult$ = "Cut middle failed for X after Z, freedom too big to be true. abort"
	        EndIf
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
            Close #LOG_FILE_NO
            If Not Init Then
                Move P24
                GoHomeFromGonio
            EndIf
            Exit Function
        EndIf
        Print #LOG_FILE_NO, "after cut middle for X (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    EndIf

    GonioX = CX(P*)
    GonioY = CY(P*)
    GonioZ = CZ(P*)
    GonioU = CU(P*)

    ''find Y
    SetFastSpeed
    ''detach give extra buffer of SAFE_BUFFER_FOR_GONIO_DETACH
    TongMove DIRECTION_CAVITY_TAIL, 2 * SAFE_BUFFER_FOR_GONIO_DETACH + GONIO_OVER_MAGNET_HEAD, False
	''move cavity edge to the goniometer center
	GNDwnStrmRad = DegToRad(g_Perfect_DownStream_Angle)

    ''save position in case we need to come back
	P51 = P*
	Move P* +X(CAVITY_RADIUS * Cos(GNDwnStrmRad)) +Y(CAVITY_RADIUS * Sin(GNDwnStrmRad))
    SetVerySlowSpeed

    Wait TIME_WAIT_BEFORE_RESET
	If Not ForceResetAndCheck Then
		g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_GONIO
		g_RunResult$ = "force sensor reset failed at GonioCalibration before pressing tong"
		Print g_RunResult$
		SPELCom_Return 1
		SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Close #LOG_FILE_NO
        If Not Init Then
            Move P24
            GoHomeFromGonio
        EndIf
		Exit Function
	EndIf
    If Not g_FlagAbort Then
        g_CurrentSteps = 84
        g_Steps = 12
        SPELCom_Event EVTNO_CAL_STEP, "84 of 100"
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: press tong to gonio"

		P52 = P*
        If Not ForceTouch(DIRECTION_CAVITY_HEAD, 10, True) Then
            g_RunResult$ = "FAILED: calibrate goniometer failed at Y touch"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Return 2
            
            ''move tong back to position bebore finding Y
            Move P52
            Move P51
		    TongMove DIRECTION_CAVITY_HEAD, 2 * SAFE_BUFFER_FOR_GONIO_DETACH + GONIO_OVER_MAGNET_HEAD, False
        Else
            Print #LOG_FILE_NO, "touched goniometer for Y at (", CX(P*), ", ", CY(P*), ")"
            GonioCalibraion = True

            ''move in
            SPELCom_Event EVTNO_CAL_STEP, "96 of 100"
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: move in"
            SetFastSpeed
		    TongMove DIRECTION_CAVITY_TAIL, SAFE_BUFFER_FOR_GONIO_DETACH, False
            
            SPELCom_Event EVTNO_CAL_STEP, "97 of 100"
            
           	Move P* -X(CAVITY_RADIUS * Cos(GNDwnStrmRad)) -Y(CAVITY_RADIUS * Sin(GNDwnStrmRad))
            
            SPELCom_Event EVTNO_CAL_STEP, "98 of 100"
		    TongMove DIRECTION_CAVITY_HEAD, (SAFE_BUFFER_FOR_GONIO_DETACH + GONIO_OVER_MAGNET_HEAD), False
		    ForceCheck
            SPELCom_Event EVTNO_CAL_STEP, "99 of 100"
            Print "final (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
            Print #LOG_FILE_NO, "final (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
            
            If Not Init Then
                Print #LOG_FILE_NO, "old P20 (", CX(P20), ", ", CY(P20), ", ", CZ(P20), ", ", CU(P20), ")"
            EndIf
            P21 = P*
            P20 = P21 - XY(dx, dy, dz, du)
            Print "new P20 (", CX(P20), ", ", CY(P20), ", ", CZ(P20), ", ", CU(P20), ")"
            Print #LOG_FILE_NO, "new P20 (", CX(P20), ", ", CY(P20), ", ", CZ(P20), ", ", CU(P20), ")"
            
            ''save current P16 for next time adjust
            P76 = P16
            
            SavePointHistory 20, g_FCntGonio

            SPELCom_Event EVTNO_UPDATE, "new P20: (", CX(P20), ", ", CY(P20), ", ", CZ(P20), ", ", CU(P20), ") "
#ifdef AUTO_SAVE_POINT
            Print "saving points to file.....", 
            SavePoints "robot1.pnt"
            Print "done!!"
#endif
		    g_RunResult$ = "normal " + Str$(CX(P21)) + " " + Str$(CY(P21)) + " " + Str$(CZ(P21)) + " " + Str$(CU(P21))
		    SPELCom_Return 0
        EndIf
    EndIf
    Close #LOG_FILE_NO
    
    If Not g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
    Else
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: user abort"
    EndIf

    If Not Init Then
        If Not g_FlagAbort Then
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: move tong home"
        EndIf
        ''move tong home

        SetFastSpeed
        ''detach
        Move P24
        GoHomeFromGonio
    EndIf
    If g_FlagAbort Then
        g_RunResult$ = "user abort"
    Else
        SPELCom_Event EVTNO_CAL_MSG, "gonio cal: Done"
        g_TS_Goniometer$ = Date$ + " " + Time$
    EndIf
Fend

Function BeamToolCalibraion(Init As Boolean) As Boolean
	''this position is not along X or Y axes
    g_OnlyAlongAxis = False

    BeamToolCalibraion = False
    g_HoldMagnet = False
    g_SafeToGoHome = False
    
    InitForceConstants

    SPELCom_Event EVTNO_CAL_STEP, "0 of 100"

    ''log file
    g_FCntBeamTool = g_FCntBeamTool + 1
    WOpen "BeamToolCal" + Str$(g_FCntBeamTool) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    Print #LOG_FILE_NO, "BeamTool calibration at ", Date$, " ", Time$

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf

    Tool 0
    LimZ 0
    If Not Init Then
        g_SafeToGoHome = True
        CheckPoint 90
        GonioX = CX(P90)
        GonioY = CY(P90)
        GonioZ = CZ(P90)
        GonioU = CU(P90)
        If GonioX = 0 Or GonioY = 0 Then
            g_RunResult$ = "P90 not defined yet, run BeamToolCalibration with Init first"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            SPELCom_Return 1
            Close #LOG_FILE_NO
            ''not need recovery
            g_SafeToGoHome = False
            Exit Function
        EndIf

        ''generate P91 from P90
        CalculateStepSize DIRECTION_CAVITY_TAIL, 10, GonioU, BTStandbySteps()
        P91 = P90 +X(BTStandbySteps(1)) +Y(BTStandbySteps(2))

        ''check current position
        If ( Not isCloseToPoint(0)) And ( Not isCloseToPoint(1)) Then
            g_RunResult$ = "must start from home"
            Print g_RunResult$
            g_SafeToGoHome = False
            Close #LOG_FILE_NO
            SPELCom_Event EVTNO_CAL_MSG, "gonio cal: failed", g_RunResult$
            SPELCom_Event EVTNO_LOG_ERROR, "aborted ", g_RunResult$
            Exit Function
        EndIf
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: move tong to beamtool"
        If Not Close_Gripper Then
            SPELCom_Event EVTNO_CAL_MSG, "beamtool: close gripper failed at home"
            Close #LOG_FILE_NO
            ''not need recovery
            g_SafeToGoHome = False
            Exit Function
        EndIf
        
        SetFastSpeed
        Jump P91
        
        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceResetAndCheck Then
			g_RunResult$ = "force sensor reset failed at beamtool"
			Print g_RunResult$
			SPELCom_Return 1
			SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
            Close #LOG_FILE_NO
            Jump P0
			Exit Function
		EndIf
                
        If g_FlagAbort Then
            SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
            Close #LOG_FILE_NO
            Jump P0
            Exit Function
        EndIf
        Move P90
    Else
        ''someone manually put the cavity over the goniometer
        GonioX = CX(P*)
        GonioY = CY(P*)
        GonioZ = CZ(P*)
        GonioU = CU(P*)
    EndIf

    g_CurrentSteps = 0
    g_Steps = 12
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: adjust for cut middle"

    SetVerySlowSpeed
    GNForce = ReadForce(DIRECTION_CAVITY_HEAD)
    If Abs(GNForce) >= Abs(GetTouchMin(DIRECTION_CAVITY_HEAD)) Then
        ForceCross DIRECTION_CAVITY_TAIL, GetTouchMin(DIRECTION_CAVITY_HEAD), 2, 4, False
    Else
        ForceTouch DIRECTION_CAVITY_HEAD, 2, True
        
    EndIf
    TongMove DIRECTION_CAVITY_TAIL, 0.8, False

    If g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    
    Print "init position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"
    Print #LOG_FILE_NO, "init position (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"

    ''find X
    g_CurrentSteps = 12
    g_Steps = 24
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: cut middle horizontal"
    GNFreeHorz = CutMiddleWithArguments(FORCE_YTORQUE, 0, GetForceThreshold(FORCE_YTORQUE), 3, 30)
    If g_CutMiddleFailed <> 0 Or GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
        g_RunResult$ = "Cut middle failed for horz. abort"
	    If GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
	        g_RunResult$ = "Cut middle failed for horz, freedom too big to be true. abort"
	    EndIf
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
        
    If g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "after cut middle for XY (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"

    ''find Z
    g_CurrentSteps = 36
    g_Steps = 24
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: cut middle vertically"
    GNFreeVert = CutMiddleWithArguments(FORCE_ZFORCE, 0, GetForceThreshold(FORCE_ZFORCE), 3, 60)
    If g_CutMiddleFailed <> 0 Or GNFreeVert > ACCPT_THRHLD_GONIO_FREEDOM Then
        g_RunResult$ = "Cut middle failed for vert. abort"
	    If GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
	        g_RunResult$ = "Cut middle failed for vert, freedom too big to be true. abort"
	    EndIf
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    If g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "after cut middle for Z (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"

    g_CurrentSteps = 60
    g_Steps = 24
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: cut middle horizontal again"
    ''find XY again after Z centered
    GNFreeHorz = CutMiddleWithArguments(FORCE_YTORQUE, 0, GetForceThreshold(FORCE_YTORQUE), 3, 30)
    If g_CutMiddleFailed <> 0 Or GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
        g_RunResult$ = "Cut middle failed for 2nd horz. abort"
	    If GNFreeHorz > ACCPT_THRHLD_GONIO_FREEDOM Then
	        g_RunResult$ = "Cut middle failed for 2nd horz, freedom too big to be true. abort"
	    EndIf
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        SPELCom_Event EVTNO_LOG_ERROR, g_RunResult$
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    If g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
        Close #LOG_FILE_NO
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        Jump P0
        Exit Function
    EndIf
    Print #LOG_FILE_NO, "after cut middle for X (", CX(P*), ", ", CY(P*), ", ", CZ(P*), ", ", CU(P*), ")"

    
    ''find YX
    g_CurrentSteps = 84
    g_Steps = 12
    SPELCom_Event EVTNO_CAL_STEP, g_CurrentSteps, "of 100"
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: press tong again beamtool"
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, (SAFE_BUFFER_FOR_DETACH + GONIO_OVER_MAGNET_HEAD), False
    TongMove DIRECTION_CAVITY_TO_MAGNET, CAVITY_RADIUS, False
    g_SafeToGoHome = True

    If g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: user abort"
        Close #LOG_FILE_NO
        Jump P0
        Exit Function
    EndIf

    SetVerySlowSpeed
    Wait TIME_WAIT_BEFORE_RESET
	If Not ForceResetAndCheck Then
		g_RunResult$ = "force sensor reset failed at beamtool before touching along axis"
		Print g_RunResult$
		SPELCom_Return 1
		SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Close #LOG_FILE_NO
        Jump P0
		Exit Function
	EndIf
    If Not ForceTouch(DIRECTION_CAVITY_HEAD, 10, True) Then
        TongMove DIRECTION_CAVITY_TAIL, 10, False
        g_RunResult$ = "FAILED: calibrate beamtool failed at along axis touch"
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        SPELCom_Return 2
		SPELCom_Event EVTNO_CAL_MSG, g_RunResult$
        Close #LOG_FILE_NO
        Jump P0
		Exit Function
    EndIf
    
    Print #LOG_FILE_NO, "touched beamtool for Y at (", CX(P*), ", ", CY(P*), ")"
    BeamToolCalibraion = True

    ''move in
    SPELCom_Event EVTNO_CAL_MSG, "beamtool: moving in"
    SPELCom_Event EVTNO_CAL_STEP, "96 of 100"
    SetFastSpeed
    TongMove DIRECTION_CAVITY_TAIL, 2, False
    SPELCom_Event EVTNO_CAL_STEP, "97 of 100"
    TongMove DIRECTION_MAGNET_TO_CAVITY, CAVITY_RADIUS, False
    SPELCom_Event EVTNO_CAL_STEP, "98 of 100"
    TongMove DIRECTION_CAVITY_HEAD, (2 + GONIO_OVER_MAGNET_HEAD), False
    SPELCom_Event EVTNO_CAL_STEP, "99 of 100"
    CheckPoint 90
    Print #LOG_FILE_NO, "old P90 (", CX(P90), ", ", CY(P90), ", ", CZ(P90), ", ", CU(P90), ")"
    P90 = P*
    Print "new P90 (", CX(P90), ", ", CY(P90), ", ", CZ(P90), ", ", CU(P90), ")"
    Print #LOG_FILE_NO, "new P90 (", CX(P90), ", ", CY(P90), ", ", CZ(P90), ", ", CU(P90), ")"
    SavePointHistory 90, g_FCntBeamTool

    SPELCom_Event EVTNO_UPDATE, "new P90 (", CX(P90), ", ", CY(P90), ", ", CZ(P90), ", ", CU(P90), ")"

    ''generate P92 from P90
    CalculateStepSize DIRECTION_CAVITY_TO_MAGNET, 15, CU(P90), BTStandbySteps()
    P92 = P90 +X(BTStandbySteps(1)) +Y(BTStandbySteps(2))
    ''calculate P91 from P90
    CalculateStepSize DIRECTION_CAVITY_TAIL, 10, CU(P90), BTStandbySteps()
    P91 = P90 +X(BTStandbySteps(1)) +Y(BTStandbySteps(2))

#ifdef AUTO_SAVE_POINT
    Print "saving points to file.....", 
    SavePoints "robot1.pnt"
    Print "done!!"
#endif
    
    SPELCom_Event EVTNO_CAL_STEP, "100 of 100"
    If Not Init Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool: move tong home"
        ''move tong home
        SetFastSpeed
        TongMove DIRECTION_CAVITY_TAIL, (SAFE_BUFFER_FOR_DETACH + GONIO_OVER_MAGNET_HEAD), False
        LimZ 0
        Jump P0
    EndIf
    If Not g_FlagAbort Then
        SPELCom_Event EVTNO_CAL_MSG, "beamtool cal: done"
    Else
        SPELCom_Event EVTNO_CAL_MSG, "beamtool cal: user abort: already done"
    EndIf
    Close #LOG_FILE_NO
    g_RunResult$ = "normal OK"
    SPELCom_Return 0
Fend

Function VB_GonioCal

    ParseStr g_RunArgs$, VBGNTokens$(), " "
    
    tmp_PIndex = UBound(VBGNTokens$)

    If tmp_PIndex <> 4 Then
        g_RunResult$ = "bad argument: should be dx dy dz du"
        SPELCom_Return 1
        Exit Function
    EndIf

    VBGNInit = False
    
    Select VBGNTokens$(0)
    Case "1"
        VBGNInit = True
    Case "TRUE"
        VBGNInit = True
    Case "true"
        VBGNInit = True
    Case "True"
        VBGNInit = True
    Send

    VBGNDX = Val(VBGNTokens$(1))
    VBGNDY = Val(VBGNTokens$(2))
    VBGNDZ = Val(VBGNTokens$(3))
    VBGNDU = Val(VBGNTokens$(4))
    
    If Not GonioCalibraion(VBGNInit, VBGNDX, VBGNDY, VBGNDZ, VBGNDU) Then
        If g_FlagAbort Then
            g_RunResult$ = "user abort"
        EndIf
        SPELCom_Return 2
        Recovery
        Exit Function
    EndIf
    SPELCom_Return 0
Fend

Function VB_BLToolCal
    VBGNInit = False
    Select g_RunArgs$
    Case "1"
        VBGNInit = True
    Case "TRUE"
        VBGNInit = True
    Case "true"
        VBGNInit = True
    Case "True"
        VBGNInit = True
    Send
    If Not BeamToolCalibraion(VBGNInit) Then
        If g_FlagAbort Then
            g_RunResult$ = "user abort"
        EndIf
        SPELCom_Return 2
        Recovery
        Exit Function
    EndIf
    SPELCom_Return 0
Fend

