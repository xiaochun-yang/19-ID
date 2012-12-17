    ac = 0;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNmarginHeight, 0); ac++;
    XtSetArg(args[ac], XmNlabelString, 
        CONVERT(parent, "Reqest New Master", 
        XmRXmString, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNx, 5); ac++;
    XtSetArg(args[ac], XmNy, 5); ac++;
    XtSetArg(args[ac], XmNwidth, 140); ac++;
    XtSetArg(args[ac], XmNheight, 21); ac++;
    XtSetArg(args[ac], XmNalignment, XmALIGNMENT_END); ac++;
    XtSetArg(args[ac], XmNfontList, 
        CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
        XmRFontList, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    stars_make_any_cascadeButton = XmCreateCascadeButton(menuBar4,
        "stars_make_any_cascadeButton",
        args, 
        ac);
    XtManageChild(stars_make_any_cascadeButton);
    
    ac = 0;
    XtSetArg(args[ac], XmNx, 0); ac++;
    XtSetArg(args[ac], XmNy, 0); ac++;
    XtSetArg(args[ac], XmNwidth, 55); ac++;
    XtSetArg(args[ac], XmNheight, 27); ac++;
    XtSetArg(args[ac], XmNbackground, 
        CONVERT(parent, "Papaya Whip", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    XtSetArg(args[ac], XmNforeground, 
        CONVERT(parent, "Black", 
        XmRPixel, 0, &argok)); if (argok) ac++;
    stars_make_any_master_pulldownMenu = XmCreatePulldownMenu(XtParent(stars_make_any_cascadeButton),
        "stars_make_any_master_pulldownMenu",
        args, 
        ac);

    {	/* Intented code segment START */

	char	clientlabel[132];
	char	clientwidname[132];

	stars_n_client_buttons = 0;
	for(stars_n_client_buttons = 0; stars_n_client_buttons < MAX_CLIENTS; stars_n_client_buttons++)
	{
		sprintf(clientlabel,"       %2d         ", stars_n_client_buttons);
		sprintf(clientwidname,"stars_clientlist_buttons%d",stars_n_client_buttons);

		ac = 0;
		XtSetArg(args[ac], XmNbackground, 
		    CONVERT(parent, "Peach Puff", 
		    XmRPixel, 0, &argok)); if (argok) ac++;
		XtSetArg(args[ac], XmNhighlightThickness, 0); ac++;
		XtSetArg(args[ac], XmNtopShadowColor, 
		    CONVERT(parent, "White", 
		    XmRPixel, 0, &argok)); if (argok) ac++;
		XtSetArg(args[ac], XmNbottomShadowColor, 
		    CONVERT(parent, "Grey40", 
		    XmRPixel, 0, &argok)); if (argok) ac++;
		XtSetArg(args[ac], XmNalignment, XmALIGNMENT_BEGINNING); ac++;
		XtSetArg(args[ac], XmNmarginHeight, 2); ac++;
		XtSetArg(args[ac], XmNlabelString, 
		    CONVERT(parent, clientlabel, 
		    XmRXmString, 0, &argok)); if (argok) ac++;
		XtSetArg(args[ac], XmNfontList, 
		    CONVERT(parent, "-*-lucida-bold-r-*-*-*-120-75-75-*-*-iso8859-1", 
		    XmRFontList, 0, &argok)); if (argok) ac++;
		XtSetArg(args[ac], XmNforeground, 
		    CONVERT(parent, "Black", 
		    XmRPixel, 0, &argok)); if (argok) ac++;
		stars_clientlist_buttons[stars_n_client_buttons] = 
				XmCreatePushButton(stars_make_any_master_pulldownMenu,
				    clientwidname,
				    args, 
				    ac);
		XtManageChild(stars_clientlist_buttons[stars_n_client_buttons]);
		XtAddCallback(stars_clientlist_buttons[stars_n_client_buttons], 
		XmNactivateCallback, stars_new_master_activateCallback, (XtPointer)stars_n_client_buttons);
	}
    } /* Indented code segment END */

    ac = 0;
    XtSetArg(args[ac], XmNsubMenuId, stars_make_any_master_pulldownMenu); ac++;
    XtSetValues(stars_make_any_cascadeButton, args, ac);
