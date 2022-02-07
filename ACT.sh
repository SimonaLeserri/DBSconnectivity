#!/bin/bash

# WHAT IT DOES
# performs cortical reconstruction (recon-all)
# creates a  tissue type mask for Anatomically Constrained Tomography
# performs preliminary step to improve coregistration

# WHAT IT NEEDS
# a freesurfer license
# a zip package working on the terminal
# the same folder structure as defined in the previous scripts.
# ACT (in particular reconAll) is otherwise independent from the other ones


# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - DWI
#           - reconAll
#           - tractography
#               -5tt_nocoreg.mif
#               -5tt_nocoreg_WM.mif
#           - working_data
#               - T2.nii.gz
#               - T1_unb.nii.gz
#               - T1_unb_bet.nii.gz
#               - T1_unb_bet_mask.nii.gz
#               - b0_bet.nii.gz
#               - b0_bet_mask.nii.gz



#############################################################################

source ./utils.sh

#Data path of all the project
echo "Enter the complete data path of the project: " 
path=$(get_path ) #E.g. path="/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data"

# Patient subfolder
echo "Enter the patient ID: " 
pat=$(get_patient )
pat_exist=$(check_original_data $path/$pat)

echo "${pat_exist% *}"

if [ "${pat_exist: -2}" = "-1" ] ; then
exit
fi

# path to freesurfer subject directory
echo "Add the complete path to FSL's subject directory"
fsl_path=$(get_fsl_subject_path ) #E.g. fsl_path="/home/brainstimmaps/04_Codebase/stable/freesurfer/subjects" 

# need for the license in free surfer folder
cd $fsl_path/..
if [ ! -f "license.txt" ]; then
    echo 'Add the license file in the freesurfer directory!'
    exit
fi

### Run cortical reconstruction and place it in a new folder

mrconvert $path/$pat/DWI/working_data/T2.mif $path/$pat/DWI/working_data/T2.nii.gz
#given the blurry quality of t2 images for Patient2, they were not used for improved recon-all
echo "Do you want to include a (GOOD QUALITY) T2 image for improved cortical reconstruction? [y/n]"
T2_answer=$(ask_T2 )

if [ $T2_answer == "y" ];
then
    echo "Using T2 for cortical reconstruction (recon-all) "
    recon-all -subject $pat -i $path/$pat/DWI/working_data/T1.nii.gz -T2 $path/$pat/DWI/working_data/T2.nii.gz -T2pial -all
else
    echo "Cortical reconstruction (recon-all) without T2"
    recon-all -subject $pat -i $path/$pat/DWI/working_data/T1.nii.gz -all
fi

zip -r $fsl_path/$pat.zip $fsl_path/$pat
unzip $fsl_path/$pat.zip -d $path/$pat/DWI
mv $path/$pat/DWI/$pat $path/$pat/DWI/reconAll
rm -r $path/$pat/DWI/reconAll/$pat

### Create 5tt mask
cd $path/$pat/DWI 
mkdir tractography

5ttgen hsvs $path/$pat/DWI/reconAll tractography/5tt_nocoreg.mif
# Get a white matter mask
mrconvert -coord 3 2 -axes 0,1,2 tractography/5tt_nocoreg.mif tractography/5tt_nocoreg_WM.mif

### Getting ready to FLIRT = coregistering the T1 and DWI images

# improve flirt performance through unbiasing and skull stripping
# if normal t1 bet includes too much neck, unbias it and repeat bet
N4BiasFieldCorrection -i $path/$pat/DWI/working_data/T1.nii.gz -o $path/$pat/DWI/working_data/T1_unb.nii.gz

mask_while $path/$pat/DWI/working_data T1_unb.nii.gz T1_unb_bet
mask_while $path/$pat/DWI/working_data b0.nii.gz b0_bet

## For patient 2 too much neck was included, so we used bet T1_unb T1_unb_bet -m -f 0.7 -R
