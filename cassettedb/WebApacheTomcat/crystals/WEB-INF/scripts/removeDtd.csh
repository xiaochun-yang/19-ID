#!/bin/csh -f

# Convert the following line 
# <!DOCTYPE Sil SYSTEM "sil-1_0.dtd">
# to
# <!DOCTYPE Sil>

set scriptDir = `dirname $0`

echo "scriptDir = $scriptDir"

cd $scriptDir
cd ../..
set rootDir = `pwd`

echo "rootDir = $rootDir"

if ($#argv != 1) then
echo "Usage: removeDtd.csh <cassette root dir>"
exit
endif

set cassetteDir = $1

cd $cassetteDir

foreach userDir (`ls`)
  echo "user dir = $userDir"
  if (! -d $userDir) then
  	continue
  endif
  cd $userDir
  rm -rf tmp
  grep dtd excelData*_sil.xml > tmp
  set files = (`awk -F: '/excelData/,/sil-1_0.dtd/{print $1;}' tmp`)
  foreach cassetteFile ($files)
  	echo "Found old cassette = $cassetteFile"
	awk '/sil-1_0.dtd/{ print "<\!DOCTYPE Sil>"; } $0 !~/sil-1_0.dtd/{ print $0; }' $cassetteFile > tmp1
	mv $cassetteFile ${cassetteFile}.bak
	mv tmp1 $cassetteFile
  end
#  rm -rf tmp
  cd ..
end







