
{
	x = $1;
   ival = int(x);    # integer part, int() truncates

   # see if fractional part
   if (ival == x) {
   	  # no fraction
      print x;
   } else {
   	if (x < 0) {
      print ival - 1;
   	} else {
      print ival + 1;
   	}
   }
}

