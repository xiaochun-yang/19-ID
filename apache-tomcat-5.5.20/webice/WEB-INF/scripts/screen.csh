#!/bin/csh -f

###########################################
# Run spotfinder and autoindexing
# on images found in a given root directory.
###########################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR  `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# silHost and silPort for the crystals server
# caHost and caPort for the crystal-analysis server
# dir is the root dir for this cassette
# silId is the silId of this cassette
if ($#argv != 11) then
echo "Error: wrong number of arguments for screen.csh"
echo "Usage: screen.csh <workDir> <silHost> <silPort> <caHost> <caPort> <user> <sessionId> <dir> <silId> <beamline> <depth>"
exit
endif

set workDir = $argv[1]

# Crystal host and port
set silHost = $argv[2]
set silPort = $argv[3]

# Crystal-analysis host and port
set caHost = $argv[4]
set caPort = $argv[5]

# User and sessionId to access the images and to create analysis out files.
set user = $argv[6]
set sessionId = $argv[7]

# Image dir
set dir = $argv[8]

# Cassette unique id
set silId = $argv[9]

set beamline = $argv[10]
set depth = $argv[11]

# Urls for crystals and crystal-analysis
set addCrystalImageUrl = "https://${silHost}:${silPort}/crystals/addCrystalImage.do"
set analyzeImageUrl = "https://${caHost}:${caPort}/crystal-analysis/jsp/analyzeImage.jsp"
set autoindexUrl = "https://${caHost}:${caPort}/crystal-analysis/jsp/autoindex.jsp"

# queue name for this job
# If we set it to user name, we can queue up
# jobs from each user separately so that one
# user can not submit too many jobs and hog the system.
set queue = $user

labelit.python << eof
import commands,urllib2
from labelit.command_line.grep_datasets import *

def getCrystalID(row):
  lsd = 1 + (row%8)
  msd = "ABCDEFGHIJKL"[row/8]
  return "%1s%1d"%(msd,lsd)

class QuickIterator:
 def __init__(self,filepath):
   self.dirlist=[]
   self.getdirlist(filepath,${depth})
   self.image_groups = []

   for dirpath in self.dirlist:
     argument_module = Spotspickle_argument_module(dirpath)
     frames = FileNames(argument_module)

     template_sort = {}
     for item in frames.FN:
       if not template_sort.has_key(item.template):
         template_sort[item.template] = FileNames(None)
       template_sort[item.template].FN.append(item)

     for value in template_sort.values():
       imfi = DatasetFiles(value)
       imfi.minimal_indexing_group()
       try:
         imfi.acceptable_use_tests()
         self.image_groups.append(imfi)
       except: pass

 def getdirlist(self,topdir,depth): #assumes topdir is a directory
   if depth==0: return
   self.dirlist.append(topdir)
   for item in os.listdir(topdir):
     fullpth = os.path.join(topdir,item)
     if os.path.isdir(fullpth):
       self.getdirlist(fullpth,depth-1)

 def show(self):
  for item in self.image_groups:
    print "group"
    for fn in item.filenames.FN:
      print fn.fullpath()

def sendurl(g):
  import time
  f = urllib2.urlopen(g)
  print f.code,
  for line in f: print line.strip()
  time.sleep(0.3)

if __name__=='__main__':
  import time
  Q = QuickIterator("${dir}")
  # Row number (from 0 -> NN) in the sil
  # One crystal per row
  row = -1
  for crystal in Q.image_groups:
    row+=1
    crystalID = getCrystalID(row)
    if len(crystal.filenames.FN)!=2: continue
    files=[]
    for group in [1,2]:
      imagepath = crystal.filenames.FN[group-1].fullpath()
      files.append(imagepath)
      image = os.path.basename(imagepath)
      dirname = os.path.dirname(imagepath)

      # Add one image per group for this row.
      url ="${addCrystalImageUrl}?userName=${user}&accessID=${sessionId}&silId=${silId}&row=%(row)s&group=%(group)d&name=%(image)s&dir=%(dirname)s"%vars()
      print "Adding image: url =",url
      sendurl(url)

  row = -1
  for crystal in Q.image_groups:
    row+=1
    crystalID = getCrystalID(row)
    if len(crystal.filenames.FN)!=2: continue
    files=[]
    for group in [1,2]:
      imagepath = crystal.filenames.FN[group-1].fullpath()
      files.append(imagepath)
      image = os.path.basename(imagepath)
      dirname = os.path.dirname(imagepath)
      # Analyze image: run spotfinder via crystal-analysis server
      # Note that forBeamLine parameter is used as a queue name
      # by the crystal-analysis. The name can be arbitrary.
      # This is so that we can set up a limit on a number
      # of jobs that can be run concurrently in each queue.
      # In this case, perhaps we should setup a queue per user.
      # This queue will be named, for example, penjit_spotfinder.
      url="${analyzeImageUrl}?userName=${user}&accessID=${sessionId}&silId=${silId}&row=%(row)s&imageGroup=%(group)d&imagePath=%(imagepath)s&crystalId=%(crystalID)s&forBeamLine=${beamline}"%vars()
      print "Analyzing image: url = ",url
      sendurl(url)

    # Autoindex image1 and image2 via crystal-analysis server
    # To run strategy, add "&strategy=true" to the url.
    # Note that uniqueID is used in the same way as crystalId parameter described above.
    # Autoindex result will go into
    # /data/<user>/webice/screening/<silId>/<uniqueID>/autoindex
    # This queue will be called, for example, penjitk_autoindex.
    # Notice that spotfinder and autoinex go into different queues
    # eventhough the queue prefix is the same. This is so that
    # fast spotfinder jobs will not be stuck behind slow(er) autoindex jobs.
    cdir = os.path.join(os.getcwd(),crystalID)
    autoindexdir = os.path.join(cdir,"autoindex")
    if not os.path.isdir(autoindexdir):
        #print "make",autoindexdir
        os.makedirs(autoindexdir)
    image1 = files[0]
    image2 = files[1]
    url="${autoindexUrl}?userName=${user}&accessID=${sessionId}&silId=${silId}&row=%(row)s&image1=%(image1)s&image2=%(image2)s&uniqueID=%(crystalID)s&forBeamLine=${beamline}&strategy=true"%vars()
    print "Autoindex: url = ",url
    sendurl(url)

eof
