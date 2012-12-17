# Expect -v matrix=xxx -v image=xxx -v spacegroup=xxx 
# -v type=complete|anom|testgen -v outputFile=xxx 
# -v phiStart=xxx -v phiEnd=xxx -v maxRes=xxx
# -v sep1=XXX -v sep2=XXX -v distance=xxx
# -v gain=XXX
BEGIN {

	# Set constants
	if (type == "complete") {
		scriptFile = "strategy.out";
		title = "strategy";
		command = "go\nstrategy auto\ngo\nstats\nexit\n\neof\n";
	} else if (type == "anom") {
		scriptFile = "strategy_anom.out";
		title = "anomalous strategy";
		command = "go\nstrategy anomalous\ngo\nstats\nexit\n\neof\n";
	} else if (type == "testgen") {
		scriptFile = "testgen.out";
		title = "testgen";
		command = "go\nseparation " sep1 " " sep2 "\ntestgen start " phiStart " end " phiEnd " overlap 3\ngo\nexit\n\neof\n";
	}
	
	directory = "DIRECTORY";
	template = "TEMPLATE"
	image = "IMAGE " image;
	bias = "BIAS 1\n";
#	gain = "GAIN 0.250000";
	gain = "GAIN " gain;
	limit = "";
	size = "";
	pixel = "";
	nullpix = "NULLPIX 5";
	overload = "OVERLOAD NOVER 1 CUTOFF 65500";
	genfile = "GENFILE";
	newmat = "NEWMAT " matrix;
	beam = "BEAM";
	wave = "WAVE";
	sync = "SYNCHROTRON";
	divergence = "DIVERGENCE";
	dispersion = "DISPERSION";
	mosaicity = "MOSAICITY";
	distance = "DISTANCE " distance;
	resolution = "RESOLUTION";
	twotheta = "TWOTHETA";
	symmetry = "SYMMETRY";
	matrix = "MATRIX " matrix;
	resolution = "RESOLUTION " maxRes;
	
};

/^DIRECTORY/{directory = $0}
/^TEMPLATE/{template = $0}
/^GAIN/{gain = $0}
/^LIMITS/{limit = $0}
/^SIZE/{size = $0}
/^PIXEL/{pixel = $0}
/^NULLPIX/{nullpix = $0}
/^OVERLOAD/{overload = $0}
/^GENFILE/{genfile = $0}
/^NEWMAT/{newmat = $0}
/^BEAM/{beam = $0}
/^WAVE/{wave = $0}
/^SYNCHROTRON/{sync = $0}
/^DIVERGENCE/{divergence = $0}
/^DISPERSION/{dispersion = $0}
/^MOSAICITY/{mosaicity = $0}
/^TWOTHETA/{twotheta = $0}
/^SYMMETRY/{symmetry = $1}


END {

	print "#!/bin/csh -f" >> outputFile;
	print "ipmosflm <<eof > " scriptFile >> outputFile;	
	
	print "TITLE " outputFile " " title "\n" >> outputFile;	
	print directory >> outputFile;
	print template >> outputFile;
	print image >> outputFile;
	print "#detector" >> outputFile;
	print limit >> outputFile;
	print size >> outputFile;
	print pixel >> outputFile;
	
	
	print bias >> outputFile;
	print gain >> outputFile;
	print nullpix >> outputFile;
	print overload "\n">> outputFile;
	
	print genfile >> outputFile;
	print newmat "\n">> outputFile;
	
	print beam "\n">> outputFile;
	
	print wave >> outputFile;
	print sync >> outputFile;
	print divergence >> outputFile;
	print dispersion >> outputFile;
	print mosaicity "\n">> outputFile;
	
	print distance >> outputFile;
	print resolution >> outputFile;
	print twotheta >> outputFile;
	print symmetry " " spacegroup >> outputFile;
	print matrix "\n">> outputFile;

	print command >> outputFile;
	
};

