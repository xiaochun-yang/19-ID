#!/usr/bin/perl

# arguments: number of anomalous scatterer in molecule, number of residues
#Summary file ( to get f" and f' at three energies)
#or energies and  heavy atom  (edge should be optional)
#type of experiment - SAD or MAD

use warnings;
use strict;

#Input
#my $runName = "test-PE00044A" ;
#my $NA = 1;
#my $NRES = 125;
#my $exp = "MAD";
#my $atom = "Se";
#my energy1
#my energy2
#my energy3


if ($#ARGV != 7) { die "WARNING: Missing input for $0!. Cannot calculate the anomalous signal. \n";}

my $scanfile = $ARGV[0] ;
my $NA = $ARGV[1];
my $NRES = $ARGV[2] ;
my $exp = $ARGV[3] ;
my $atom = $ARGV[4] ;
my $energy1 = $ARGV[5] ;
my $energy2 = $ARGV[6] ;
my $energy3 = $ARGV[7] ;

if (($NA == 0) | ($NRES == 0)) {    
    die ("WARNING: No anomalous scatterers or number of residues provided. There is not information to calculate the anomalous signal. \n");
}


# Fixed definitions:

my $NATperRES = 8.1; #Average number of atoms in an aminoacid
my $Zeff = 6.7;  # average electrons contributing to scattering in an aminoacid atom (at zero angle)

my @fp = ();    
my @fpp = ();
my @line;
my $anomsig = 0;
my $dispsig = 0;
my $n = 0;

if (-e $scanfile ) {
    #print "summary scan file exists. \n"
    open FILE, $scanfile or die $!;
    while (<FILE>) {
        #looking for all the lines containing the energy in the scan summary file; there should be three (peak, remote and inflection)
        #sometimes not all are used - we want to get fp and fpp only from the energies that coincide with the input energy or energies
	if ($_  =~ /E=/) {
            @line = split /=/, $_ ;
	    my @rest = (abs($line[1] - $energy1), abs($line[1] - $energy2), abs($line[1] - $energy3));
            #print "@rest \n";
	    #print "@line \n";
	    $n = 0;
 
	    for my $i  (@rest)  {
		# The input and the scan file energy should be exactly identical, but will allow a difference of 0.1 eV here, just in case
                # If the energy in the scan file does not coincide with any of the input energies, we increase a counter. When it reaches 3
                # we know that the energy is not being used.
                if ( $i > 0.1 ) {
		    $n++ ;
		    #print "$n : $line[1] is not an input energy\n";
		}
	    }
	}
        # If the energy is not being used we ignore the two following lines in the scan file (they contain fp and fpp for the unused energy)
	if ($n == 3) {
	    my $toto = (readline (FILE));
	    #print "skipped line $. $toto  \n";
	    $toto = (readline (FILE));
	    #print "skipped line $. $toto \n";
	} else {

            #If the energies in the scan file and input coincide, we read  fpp and fpp
	    if ($_  =~ /Fpp/) {
		@line = split /=/, $_ ;
		@fpp = (@fpp ,  $line[1]);
		#print "fdoubprime is @fpp";
	    }
	    if ($_  =~ /Fp=/) {
		@line = split /=/, $_ ;
		@fp = (@fp ,  $line[1]);
		#print "fprime is @fp";
	    }

	}
            
    }  
 

} else {
    # We need a tool to obtain fpp and fp from the energy values and element
    die ("WARNING: $scanfile does not exist; There is not enough information to calculate the anomalous signal. \n");
}

#calculate things from input

my $NAT = $NATperRES*$NRES;
my $factor = ($NA/(2*$NAT))**(1/2) / ($Zeff);
#print "$NAT\n";

my $largest_anomsig = $anomsig;

for my $i (@fpp) {
    #print "$i\n";        
    $anomsig = $factor * (2*$i) ;
    if ($largest_anomsig < $anomsig )   {$largest_anomsig = $anomsig;}

    #printf "The anomalous signal for fpp = $i is \%5.3f\n", $anomsig;
}

#printf "The largest anomalous difference is \%5.3f\n", $largest_anomsig;

my $largest_dispsig = $dispsig;


if ($exp =~ "MAD") {
    for my $i (@fp) {
	for my $j (@fp) {
	    $dispsig = $factor * ($i - $j);
	    #if ($dispsig gt 0) {
		#printf "The dispersive signal for fp = $i and fp = $j is \%5.3f\n", $dispsig;
	    #}
	    if ($largest_dispsig < $dispsig )   {$largest_dispsig = $dispsig;}

	}
    }
#printf "The largest dispersive difference is \%5.3f\n", $largest_dispsig;

}

my $signal = ($largest_dispsig**2 + $largest_anomsig**2)**(1/2) ;
#printf "The total signal is \%5.3f\n", $signal;

printf "\%6.3f\%6.3f\%6.3f\n", $largest_anomsig, $largest_dispsig, $signal;

exit;

