#!/bin/bash

# copy fMRI already preprocessed from Dimitri's lab to ours (on external drive) :)
echo "Where do you want to save the HCP functional data? " 
read HCP_path
#echo $HCP_path
echo ----------------------------------------
# you should cd till you are in the data path, the one that contains the subjects subfolder
# then run complete/path/to/this/script/getting_HCP.sh

#this returns argument list too long --> doesnt work
# for file in `find */rf*/fMRIvols_GLMyes/*.nii`; do
# echo $file
# base=${file%/*} 
# mkdir -p $HCP_path/$base
# cp $file $HCP_path/$base
# done


for subject in $(find ${PWD} -maxdepth 1 -mindepth 1 -type d);do #only directories one step away from current dir
#echo $subject
   
    subj=${subject##*/} #after last occurrence of /
    if [ -d "$HCP_path/$subj" ]; then
     echo "${subj} already written"

    else
    for file in `find ${PWD}/${subj}/rf*/fMRIvols_GLMyes/*.nii`;do
    from_subj_on=${file#"$PWD"/}
    Complete_Destination=$HCP_path$from_subj_on
    Destination_Folder=${Complete_Destination%/*}

    echo From : $PWD/$from_subj_on
    echo Destination folder : $Destination_Folder

    # create the dir first
    mkdir -p $Destination_Folder
    cp $file $Destination_Folder 
    
    done
    fi
done