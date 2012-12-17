    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNshadowType, XmSHADOW_ETCHED_IN); ac++;
    XtSetArg(args[ac], XmNresizePolicy, XmRESIZE_GROW); ac++;
    XtSetArg(args[ac], XmNx, 62); ac++;
    XtSetArg(args[ac], XmNy, 470); ac++;
    XtSetArg(args[ac], XmNwidth, 140); ac++;
    XtSetArg(args[ac], XmNheight, 70); ac++;
    driveby_form = XmCreateBulletinBoard(manual_controlDialog,
        "driveby_form",
        args, 
        ac);
    XtManageChild(driveby_form);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_180); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "180", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 72); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    drive_phi180_pushButton = XmCreatePushButton(driveby_form,
        "drive_phi180_pushButton",
        args, 
        ac);
    XtManageChild(drive_phi180_pushButton);
    XtAddCallback(drive_phi180_pushButton, XmNactivateCallback, drive_phi_activateCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_90); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "90", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 15); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    drive_phi90_pushButton = XmCreatePushButton(driveby_form,
        "drive_phi90_pushButton",
        args, 
        ac);
    XtManageChild(drive_phi90_pushButton);
    XtAddCallback(drive_phi90_pushButton, XmNactivateCallback, drive_phi_activateCallback, (XtPointer)0);
    
/* Start driveto */

    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNshadowType, XmSHADOW_ETCHED_IN); ac++;
    XtSetArg(args[ac], XmNresizePolicy, XmRESIZE_GROW); ac++;
    XtSetArg(args[ac], XmNx, 12); ac++;
    XtSetArg(args[ac], XmNy, 470); ac++;
    XtSetArg(args[ac], XmNwidth, 240); ac++;
    XtSetArg(args[ac], XmNheight, 70); ac++;
    driveto_form = XmCreateBulletinBoard(manual_controlDialog,
        "driveto_form",
        args, 
        ac);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_180); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "180", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 119); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    driveto_phi180_pushButton = XmCreatePushButton(driveto_form,
        "driveto_phi180_pushButton",
        args, 
        ac);
    XtManageChild(driveto_phi180_pushButton);
    XtAddCallback(driveto_phi180_pushButton, XmNactivateCallback, driveto_phi_activateCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_90); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "90", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 62); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    driveto_phi90_pushButton = XmCreatePushButton(driveto_form,
        "driveto_phi90_pushButton",
        args, 
        ac);
    XtManageChild(driveto_phi90_pushButton);
    XtAddCallback(driveto_phi90_pushButton, XmNactivateCallback, driveto_phi_activateCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_0); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "0", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 5); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    driveto_phi0_pushButton = XmCreatePushButton(driveto_form,
        "driveto_phi0_pushButton",
        args, 
        ac);
    XtManageChild(driveto_phi0_pushButton);
    XtAddCallback(driveto_phi0_pushButton, XmNactivateCallback, driveto_phi_activateCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Peach Puff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 2); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNuserData, PHI_270); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "270", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 171); ac++;
    XtSetArg(args[ac], XmNy, 18); ac++;
    XtSetArg(args[ac], XmNwidth, 51); ac++;
    XtSetArg(args[ac], XmNheight, 34); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    driveto_phi270_pushButton = XmCreatePushButton(driveto_form,
        "driveto_phi270_pushButton",
        args, 
        ac);
    XtManageChild(driveto_phi270_pushButton);
    XtAddCallback(driveto_phi270_pushButton, XmNactivateCallback, driveto_phi_activateCallback, (XtPointer)0);
    
/* End driveto */

