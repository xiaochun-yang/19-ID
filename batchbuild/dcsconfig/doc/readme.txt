dcsconfig
=========

1. Overview
2. Format
3. Descriptions of some known config


1. Overview
===========

dcsconfg consists of an API used to retrieve and store configuration
data used by applications in the DCS system including Blu-ice, DHS,
and DCSS. It uses the XosConfig format where each config is a line
containg name and value separated by an equal sign (=). See Details
about the format in the next section.

This API is written in an effort to unify the configuration data
and to create a single format all applications in the DCS system
without use of database. 

An application creates a DcsConfig object by giving it a beamline
name. The API loads a config from ../../dcsconfig/data/<beamline>.config 
and ../../dcsconfig/data/default.config files. In effect, the application
must be installed under the parent directory as the dcsconfig. All it
needs to know is the beamline name.

When an application requests for a config via a DcsConfig method,
for example, get("imperson.host") of the DcsConfig class will return
the config value from the given beamline. If the config is not found,
it will return the value from the default.config file. If the config
if not found in neither file, null will be returned.



2. Format
=========

The file name must be the name of a beamline with an extension .config.

A config entry is a line in the file consisting of a name and value 
pair separated by an equal sign (with no space in between). For example,

dcss.logStdout=true

A comment line is allowed and must begins with a hash sign (#). An empty
line or a ling without an equal sign will be ignored. Name does not have
to be unique. The API provides a method to retrieve all values of the 
given name. For example,

dcss.display=local bl91b.slac.stanford.edu :0.0
dcss.display=local bl91b.slac.stanford.edu :1.0
dcss.display=local biotest.slac.stanford.edu :0

The method getReange("dcss.display") of the DcsConfig class will return a list 
of all values above.

3. Descriptions of some known config
====================================

3.1 dcss config
---------------

- dcss.dir
	Directory where shared files will be stored. Shared files are those 
	that can be viewed by any Blu-ice users, for example, last scan file.
	
- dcss.host
	Host name where dcss is running. Used by DHS to find the dcss to connect to.
	
- dcss.scriptPort
	Port number for the scripting engine to connect to the dcss.
	
- dcss.hardwarePort
	Port number for the DHS to connect to the dcss.
	
- dcss.guiPort
 	Port number for Blu-ice to connect to dcss.
 	
- dcss.authProtocol
	Authentication procotol for the DHS and Blu-ice to use 
	when connecting to this dcss. DCSS v4.0 currently supports
	protocol 1 and 2.
	
- dcss.validationRate
	Time interval in milliseconds before the DCSS validates the users
	session ids. 
	
- dcss.display
	A Blu-ice display name accepted by this DCSS. The display 
	name is sent as part of the connection protocol from Blu-ice.
	If the display sent from Blu-ice is not on the list, DCSS will
	reject the connection. There can be more than one entry for this
	config.
	
- dcss.logStdout
	Set to true or false. If true the log messages will be 
	printed out to the terminal.
	
- dcss.logUdpHost
	Host name to which to send log messages as UDP packets. 
	Only when dcss.logUdpHost and dcss.logUdpPort are set,
	the log messages will be sent out as UDP packets.
	
- dcss.logFilePattern
	Name of log file to be generated. If not set, log file 
	will not be created. The file name can contain the following
	patterns will be replaced at runtime:
	
	/  the local pathname separator
	%t the system temporary directory defined by TMP_DIR env variable
	%h the value of the HOME_DIR env variable
	%g the generation number to distinguish rotated logs 
	   (see dcss.logFileMax and dcss.logFileSize)
	%u a unique number to resolve conflicts
	%d a timestamp when the file is created. Time is in seconds from Jan 1970.
	%% translates to a single percent sign %
	
	For example, 
	
	%t/dcss_log.txt ==> /tmp/dcss_log.txt
	
	%t/dcss_%g.txt  ==> /tmp/dcss_0.txt, /tmp/dcss_1.txt, /tmp/dcss_2.txt
	if dcss.logFileMax is 3. These files are generated in rotation once a
	file is full (specified by dcss.logFileSize), the rotation number 
	will be incremented. The number is reset to 0 when it's equaled
	to dcss.logFileMax-1.
	
	%t/dcss_%u.txt ==> /tmp/dcss_0.txt
	Normally the "%u" unique field is set to 0. However, if the FileHandler
	tries to open the filename and finds the file is currently in use by
	another process it will increment the unique number field and try again.
	This will be repeated until FileHandler finds a file name that is not
	currently in use. 
	
	%t/dcss_%g_%u.txt ==> /tmp/dcss_0_0.txt, /tmp/dcss_1_0.txt, /tmp/dcss_2_0.txt.
	If, for example, /tmp/dcss_0_0.txt is locked, the logger will try to 
	create /tmp/dcss_0_1.txt instead. If /tmp/dcss_0_1.txt is also locked,
	it will try /tmp/dcss_0_2.txt and so on.
	
	%t/dcss_%d.txt ==> /tmp/dcss_738473246233.txt
	
	
- dcss.logFileSize
	Maximum size of a log gile in bytes. If the file has reached the max size,
	the logger will either overwrite the same file, or create a new file with 
	an incremented rotating number (if %g) is used, or create a new file
	with a timestamp (if %d) is used.
	
- dcss.logFileMax
	Maximum rotating file number used with %g in dcss.logFilePattern
	
- dcss.logLevel
	Log level: ALL, FINIST, FINE, INFO, CONFIG, WARNING, SEVERE, OFF
	
- dcss.logLibs
	Turn on logging in libraries used by DCSS. Not used at the moment.


Example

# dcss server
dcss.dir=/tmp/blctlxx/dcss
dcss.host=blctlxx.slac.stanford.edu
dcss.scriptPort=14341
dcss.hardwarePort=14342
dcss.guiPort=14343
dcss.authProtocol=2
dcss.validationRate = 200
dcss.display=local bl91b.slac.stanford.edu :0.0 #Scott's office
dcss.display=local bl91b.slac.stanford.edu :1.0
dcss.display=local biotest.slac.stanford.edu :0 #Ana's office
dcss.display=local smblx5.slac.stanford.edu :0 #Scott's office
dcss.display=local smblx6.slac.stanford.edu :0.0 #Guenter's Office
dcss.display=local blctlxx.slac.stanford.edu :0.0
dcss.logStdout=true
dcss.logUdpHost=
dcss.logUdpPort=
dcss.logFilePattern=./dcss_log_%d.txt
dcss.logFileSize=31457280
dcss.logFileMax=3
dcss.logLevel=ALL
dcss.logLibs=auth_client|http_cpp


3.2 impdhs config
-----------------

- impdhs.name
	Name of this DHS instance. This is the name used to register this DHS
	to the DCSS. Must match to an entry defined in database.dat 

- impdhs.tmpDir
	Tmp directory used to store temporary file generated by scripts
	run by this dhs via the impersonation server.
	
- impdhs.choochBinDir
	Directory where autochooch is installed. See impdhs/doc/readme.txt
	and autochooch/doc/readme.txt for detailed.

- impdhs.choochDatDir
	Directory where autochooch data files are installed.
	See impdhs/doc/readme.txt and autochooch/doc/readme.txt for detailed.
	
- impdhs.cameraHost
	Host name for the axis camera server. Used by the snap operation
	to create a snap shot of a video image.

- impdhs.cameraPort
	Port number for the axis camera server. Used by the snap operation
	to create a snap shot of a video image.

- impdhs.impHost
	Host name for the impersonation server used to run script remotely.
	If it is not defined here, the value of imperson.host config will 
	be used instead. It is defined here as a separate config so that
	the impdhs can use a different instance of the impersonation server
	to run certain tasks, for example, running a script on a designated 
	machine. The imperson.host config is used by all most
	applications in the system, typically, for accessing files.

- impdhs.impPort
	Port number for the imperson server. See above.


Example

# imperson dhs
impdhs.name=imperson
impdhs.tmpDir=/tmp
impdhs.choochBinDir=/tmp/autochooch/bin
impdhs.choochDatDir=/tmp/autochooch/data
impdhs.cameraHost=smb.slac.stanford.edu
impdhs.cameraPort=80
impdhs.impHost=blctlxx.slac.stanford.edu
impdhs.impPort=61001


3.3. epics dhs config
---------------------

- epicsdhs.name
	Name of the instance of this dhs registered with the DCSS. Must match 
	an entry in database.dat of the dcss.
	
- epicsdhs.pvFile
	Input file name containing PV mapping. See epicsdhs/doc/readme.txt 
	for more details.
	
- epicsdhs.EPICS_CA_ADDR_LIST
	Environement variable required to start up epics client. It's a list
	of epics hosts the client can connect to.
	
- epicsdhs.EPICS_TS_MIN_WEST
	Another epics env variables


Example,

# epics dhs
epicsdhs.name=spear_epics
epicsdhs.pvFile=../data/epics.config
epicsdhs.EPICS_CA_ADDR_LIST=spear3 prymatt b132-iocrf b117-iocmu b118-iocps b117-iocorbit b117-iocfdbk
epicsdhs.EPICS_TS_MIN_WEST=480


3.4 image server config
-----------------------

- imgsrv.host
	Host name for the image server. This is so that 
	Blu-ice can find the image server.
	
- imgsrv.guiPort=14005
	Port number for blu-ice to connect to the image server.
	
- imgsrv.webPort=14006
	Port number for the old web image viewer to connect to the image server.
	
- imgsrv.httpPort=14007
	Port number for the new web image viewer in webice or web browser to 
	connect to the image server.
	
- imgsrv.tmpDir=/home/penjitk/code/20030910/imgsrv/scratch
	Directory to store the requested JPEG image file and header file
	for the old web image viewer to pick up. 

- imgsrv.maxIdleTime=60
	Time interval in milliseconds before the session remains in cache without 
	revalidation for the next request.


Example,

# image server
imgsrv.host=blctlxx.slac.stanford.edu
imgsrv.guiPort=14005
imgsrv.webPort=14006
imgsrv.httpPort=14007
imgsrv.tmpDir=/home/penjitk/code/20030910/imgsrv/scratch
imgsrv.maxIdleTime=60


3.5 Authentication server config
--------------------------------

- auth.host
	Host name of the authentication server.

- auth.port
	Port number of the authentication server.

- auth.secureHost
	Host name of the authentication server for connection using SSL.

- auth.securePort
	Port number of the authentication server for connection using SSL.

Example,

# authentication server
auth.host=smb.slac.stanford.edu
auth.port=8180
auth.secureHost=smb.slac.stanford.edu
auth.securePort=8543

3.5 Impersonation server config
-------------------------------

- imperson.host
	Host name for the impersonation server. Used by DCS applications
	to access files/directories or runs scripts remotely on 
	behalf of users.

- imperson.port
	Host name for the impersonation server. Used by DCS applications
	to access files/directories (e.g. copy/read/delete file and
	list/create/delete directory) or runs scripts remotely on 
	behalf of users.

- imperson.readonlyHost
	Same as imperson.host but only allow operations which do not require 
	write access to file system such as reading file, listing 
	directory, and get file status.
	
- imperson.readonlyPort
	Same as imperson.port but only allow operations which do not require 
	write access to file system such as reading file, listing 
	directory, and get file status.


Example,

# impersoanation server
imperson.host=smb.slac.stanford.edu
imperson.port=61001
imperson.readonlyHost=smb.slac.stanford.edu
imperson.readonlyPort=61002

