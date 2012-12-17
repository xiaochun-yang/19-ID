    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Guard Aperature", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 43); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start); ac++;
    XtSetArg(args[ac], XmNwidth, 228); ac++;
    XtSetArg(args[ac], XmNheight, 55); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_aperature_label = XmCreateLabel(manual_controlDialog,
        "mc_guard_aperature_label",
        args, 
        ac);
    XtManageChild(mc_guard_aperature_label);

    ac = 0;
    XtSetArg(args[ac], XmNisHomogeneous, False); ac++;
    XtSetArg(args[ac], XmNborderWidth, 0); ac++;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNborderColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNresizeWidth, False); ac++;
    XtSetArg(args[ac], XmNresizeHeight, False); ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNorientation, XmHORIZONTAL); ac++;
    XtSetArg(args[ac], XmNspacing, 0); ac++;
    XtSetArg(args[ac], XmNisHomogeneous, False); ac++;
    XtSetArg(args[ac], XmNx, 219); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 30); ac++;
    XtSetArg(args[ac], XmNwidth, 138); ac++;
    XtSetArg(args[ac], XmNheight, 25); ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_radioBox = XmCreateRadioBox(manual_controlDialog,
        "mc_guard_hs_radioBox",
        args, 
        ac);
    XtManageChild(mc_guard_hs_radioBox);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Drive", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, True); ac++;
    XtSetArg(args[ac], XmNindicatorSize, 15); ac++;
    XtSetArg(args[ac], XmNindicatorOn, True); ac++;
    XtSetArg(args[ac], XmNselectColor, 
        CONVERT(parent, "#729fff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNwidth, 64); ac++;
    XtSetArg(args[ac], XmNheight, 17); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_drive_pushButton = XmCreateToggleButton(mc_guard_hs_radioBox,
        "mc_guard_hs_drive_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_hs_drive_pushButton);
    XtAddCallback(mc_guard_hs_drive_pushButton, XmNarmCallback, mc_guard_hs_armCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, SLIT_ZERO_STRING,
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNindicatorSize, 15); ac++;
    XtSetArg(args[ac], XmNindicatorOn, True); ac++;
    XtSetArg(args[ac], XmNselectColor, 
        CONVERT(parent, "#ff3232", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNwidth, 64); ac++;
    XtSetArg(args[ac], XmNheight, 17); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_zero_pushButton = XmCreateToggleButton(mc_guard_hs_radioBox,
        "mc_guard_hs_zero_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_hs_zero_pushButton);
    XtAddCallback(mc_guard_hs_zero_pushButton, XmNarmCallback, mc_guard_hs_armCallback, (XtPointer)0);
    
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
    XtSetArg(args[ac], XmNuserData, MC_OMEGA); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Apply", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 156); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 30); ac++;
    XtSetArg(args[ac], XmNwidth, 50); ac++;
    XtSetArg(args[ac], XmNheight, 27); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_apply_pushButton = XmCreatePushButton(manual_controlDialog,
        "mc_guard_hs_apply_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_hs_apply_pushButton);
    XtAddCallback(mc_guard_hs_apply_pushButton, XmNactivateCallback, mc_guard_hs_apply_Callback, (XtPointer)0);

    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Horiz Slit:", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 4); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 32); ac++;
    XtSetArg(args[ac], XmNwidth, 85); ac++;
    XtSetArg(args[ac], XmNheight, 25); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_label = XmCreateLabel(manual_controlDialog,
        "mc_guard_hs_label",
        args, 
        ac);
    XtManageChild(mc_guard_hs_label);

    ac = 0;
    XtSetArg(args[ac], XmNborderWidth, 0); ac++;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNborderColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 1); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "Grey65", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNresizeWidth, False); ac++;
    XtSetArg(args[ac], XmNx, 93); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 32); ac++;
    XtSetArg(args[ac], XmNwidth, 58); ac++;
    XtSetArg(args[ac], XmNheight, 23); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-medium-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNmarginWidth, 2); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_hs_textField = XmCreateTextField(manual_controlDialog,
        "mc_guard_hs_textField",
        args, 
        ac);
    XtManageChild(mc_guard_hs_textField);
    XtAddCallback(mc_guard_hs_textField, XmNactivateCallback, mc_guard_hs_apply_Callback, (XtPointer)0);
    XtAddCallback(mc_guard_hs_textField, XmNmodifyVerifyCallback, AdxVerifyNumericCB, (XtPointer)0);

    ac = 0;
    XtSetArg(args[ac], XmNisHomogeneous, False); ac++;
    XtSetArg(args[ac], XmNborderWidth, 0); ac++;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNborderColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNtraversalOn, False); ac++;
    XtSetArg(args[ac], XmNresizeWidth, False); ac++;
    XtSetArg(args[ac], XmNresizeHeight, False); ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNorientation, XmHORIZONTAL); ac++;
    XtSetArg(args[ac], XmNspacing, 0); ac++;
    XtSetArg(args[ac], XmNisHomogeneous, False); ac++;
    XtSetArg(args[ac], XmNx, 219); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 70); ac++;
    XtSetArg(args[ac], XmNwidth, 138); ac++;
    XtSetArg(args[ac], XmNheight, 25); ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_radioBox = XmCreateRadioBox(manual_controlDialog,
        "mc_guard_vs_radioBox",
        args, 
        ac);
    XtManageChild(mc_guard_vs_radioBox);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Drive", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, True); ac++;
    XtSetArg(args[ac], XmNindicatorSize, 15); ac++;
    XtSetArg(args[ac], XmNindicatorOn, True); ac++;
    XtSetArg(args[ac], XmNselectColor, 
        CONVERT(parent, "#729fff", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNwidth, 64); ac++;
    XtSetArg(args[ac], XmNheight, 17); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_drive_pushButton = XmCreateToggleButton(mc_guard_vs_radioBox,
        "mc_guard_vs_drive_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_vs_drive_pushButton);
    XtAddCallback(mc_guard_vs_drive_pushButton, XmNarmCallback, mc_guard_vs_armCallback, (XtPointer)0);
    
    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Grey40", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginWidth, 0); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, SLIT_ZERO_STRING, 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNindicatorSize, 15); ac++;
    XtSetArg(args[ac], XmNindicatorOn, True); ac++;
    XtSetArg(args[ac], XmNselectColor, 
        CONVERT(parent, "#ff3232", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNwidth, 64); ac++;
    XtSetArg(args[ac], XmNheight, 17); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_zero_pushButton = XmCreateToggleButton(mc_guard_vs_radioBox,
        "mc_guard_vs_zero_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_vs_zero_pushButton);
    XtAddCallback(mc_guard_vs_zero_pushButton, XmNarmCallback, mc_guard_vs_armCallback, (XtPointer)0);
    
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
    XtSetArg(args[ac], XmNuserData, MC_OMEGA); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_CENTER); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Apply", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 156); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 70); ac++;
    XtSetArg(args[ac], XmNwidth, 50); ac++;
    XtSetArg(args[ac], XmNheight, 27); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_apply_pushButton = XmCreatePushButton(manual_controlDialog,
        "mc_guard_vs_apply_pushButton",
        args, 
        ac);
    XtManageChild(mc_guard_vs_apply_pushButton);
    XtAddCallback(mc_guard_vs_apply_pushButton, XmNactivateCallback, mc_guard_vs_apply_Callback, (XtPointer)0);

    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Vert Slit:", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNrecomputeSize, False); ac++;
    XtSetArg(args[ac], XmNx, 4); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 72); ac++;
    XtSetArg(args[ac], XmNwidth, 85); ac++;
    XtSetArg(args[ac], XmNheight, 25); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_label = XmCreateLabel(manual_controlDialog,
        "mc_guard_vs_label",
        args, 
        ac);
    XtManageChild(mc_guard_vs_label);

    ac = 0;
    XtSetArg(args[ac], XmNborderWidth, 0); ac++;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "White", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNborderColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
    XtSetArg(args[ac], XmNshadowThickness, 1); ac++;
    XtSetArg(args[ac], XmNtopShadowColor, 
        CONVERT(parent, "Grey65", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNbottomShadowColor, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNresizeWidth, False); ac++;
    XtSetArg(args[ac], XmNx, 93); ac++;
    XtSetArg(args[ac], XmNy, manual_dialog_guard_start + 72); ac++;
    XtSetArg(args[ac], XmNwidth, 58); ac++;
    XtSetArg(args[ac], XmNheight, 23); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-medium-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 4); ac++;
    XtSetArg(args[ac], XmNmarginWidth, 2); ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    mc_guard_vs_textField = XmCreateTextField(manual_controlDialog,
        "mc_guard_vs_textField",
        args, 
        ac);
    XtManageChild(mc_guard_vs_textField);
    XtAddCallback(mc_guard_vs_textField, XmNactivateCallback, mc_guard_vs_apply_Callback, (XtPointer)0);
    XtAddCallback(mc_guard_vs_textField, XmNmodifyVerifyCallback, AdxVerifyNumericCB, (XtPointer)0);
