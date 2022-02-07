#!/bin/bash

# to run in functional_HCP folder on the external drive, that one containing one subdir per subject
echo "Where are the functional voxels evolutions for all sessions and patients? "
read read_path

# locally
echo "Where do you want to save the functional voxels evolutions for all sessions and patients? "
read save_path

echo ----------------------------------------

cd $read_path
 for file in `find */rf* -maxdepth 1 -mindepth 1 -type f`; do # only files - not subdir - two levels down == at the session level
 echo $file
 base=${file%/*}
 echo $save_path/$base
 mkdir -p $save_path/$base
 cp $file $save_path/$base
 done