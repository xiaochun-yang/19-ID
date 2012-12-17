# -v energy=XXX
BEGIN {
        e1 = 0.0;
        e2 = 0.0;
        energy = energy + 0.0;
        en_first = 0.0;
	isSmall = 0;
	isLarge = 0;
};


{
        if (($0 == "") && (start == 1)) {
             start = 0;
        }
        
        if (start == 1) {

            if (en_first == 0) {
                 en_first = $1;
                 flux_first = $2;

                 if (energy <= en_first) {
                     isSmall  = 1;
                 } else if (energy > en_first){
                     isLarge = 1;
                 }

            }
#energy increases
            if ( $1 >= en_first) {
               
                 flux1 = flux_first;
                 e1 = en_first;
                 flux2 = $2;
                 e2 = $1;
#DEBUG		 print ("energy increases");

                 if (isSmall == 1) {
                      flux2 = flux1;
                      start = 0;
                 }
                 en_first = e2;
                 flux_first = flux2;

#DEBUG		 print (flux1, e1, flux2, e2);
                 if (energy < en_first) {
                      start = 0;
                 }

            }
#energy decreases
            if ( $1 < en_first) {

                 flux2 = flux_first;
                 e2 = en_first;
                 flux1 = $2;
                 e1 = $1;

                 if (isLarge == 1) {
                     flux1 = flux2;
                     start = 0;
                 }

                 en_first = e1;
                 flux_first = flux1;
                 if (energy > en_first) {
                      start = 0;
                 }

            }


        }

};

/Energy/{
        start = 1;
};


END {   

  if (e2 == e1) {
    flux = 0;
  } else {
    flux = (flux2 - flux1)*(energy - e1)/(e2 - e1);}
        printf("%g  ", (flux + flux1));
#  print (e1, e2, flux1, flux2);

};
