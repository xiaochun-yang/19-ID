#!/bin/csh -fv

# arg1 = solution number
# arg2 = image_root_name
# arg3 iteration

set dir = ../solution02
set space_group = P21         # from LABELIT/scala_symmetry.out       
set image_root_name = sp1_nat2_4	 # rootname
set iteration = 2              # how many times have we integrated with mosflm, extracted from name1

#set nresidue = 364         # not used yet
#set ano_atom = se          # not used yet
#set nanom  = 4             # nnot used yet
#set seq = tutorial/seq.pir # Not used yet
#set sites =   # not used yet

unset noclobber


# Set environment variables

setenv  /home/webserverroot/servlets/tomcat-smbws1/webice/WEB-INF/scripts/setup_env.csh

set name1 = ${image_root_name}_${iteration}	 # rootname + iteration number

# Checking space group

set s_g =
if ($space_group != '') then
    date +"%T"; echo 'Will change space group to '$space_group'\n'
    set s_g="SYMM $space_group"
    set id = "reindex_${name1}"  
reindex hklin ${dir}/${name1}.mtz hklout ${id} <<EOF-reindex>${id}.out
${s_g}
end
EOF-reindex

echo "hello"
date +"%T" ; echo 'reindex done  - output: '$id'.mtz - log: '$id'.out\n'

set sort${iteration} = ${dir}/${name1}.mtz

endif	# endif space_group
    

set id = "sort_${name1}"

echo "H K L M/ISYM BATCH" > batch.txt
set it = 1
while ($it <= $iteration)
echo "it = $it"
set sort = reindex_${image_root_name}_${it}.mtz
echo "${sort}" >> batch.txt
@ it++
end # end loop

sortmtz hklout ${id} < batch.txt > ${id}.out

date +"%T"; echo 'sort done  - output: '$id'.mtz - log: '$id'.out\n'

scale: 

set id = "scala_${name1}"

scala hklin sort_${name1}  hklout ${id} \
  scales   ${id}.scales \
  rogues   ${id}.rogues \
  normplot ${id}.norm \
  anomplot ${id}.anom \
  correlplot ${id}.correlplot \
  plot ${id}.plot \
     << eof_ref > ${id}.out
scales rotation spacing 10 bfactor off secondary 6
tie surface 0.001
anomalous on
reject 4
eof_ref
date +"%T"; echo 'scala done  - output: '$id'.mtz - log: '$id'.out\n'

exit
