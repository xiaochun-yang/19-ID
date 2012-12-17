BEGIN{
}

/<laueGroup/{
	print "    <laueGroup>" laueGroup "</laueGroup>";
	done = 1;
}

/<unitCell/{
	print "    <unitCell a=\"" a "\" b=\"" b "\" c=\"" c "\" alpha=\"" alpha "\" beta=\"" beta "\" gamma=\"" gamma "\"/>";
	done = 1;
}

{
	if (done != 1) {
		print $0;
	}
	done = 0;
}

END{
}

