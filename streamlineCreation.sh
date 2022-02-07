#!/bin/bash

# WHAT IT DOES
# coregisters DW image and T1
# creates and corrects wholebrain streamlines created with individual FOD, not used after.

# WHAT IT NEEDS
# The script ACT.sh already executed
# A good $path/$pat/DWI/working_data/b0_bet_mask.nii.gz
# A good $path/$pat/DWI/working_data/T1_unb_bet_mask.nii.gz
# (visually inspect with mrview and change in a separate terminal using different -f values in bet, if needed)

# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - DWI
#           - tractography
#               - diff2struct.mat
#               - diff2struct.txt
#               - 5tt_coreg.mif
#               - mu.txt
#               - sift2_weights_10mio.csv
#               - smallerTracks_200k-tck
#               - tracks_10mio.tck
#               - T1_coreg.mif
#           - working_data
#               - T1_unb.nii.gz
#               - T1_unb_bet.nii.gz
#               - T1_unb_bet_mask.nii.gz
#               - b0_bet.nii.gz
#               - b0_bet_mask.nii.gz


#############################################################################

source ./utils.sh

#Data path of all the project
echo "Enter the complete data path of the project: " 
path=$(get_path )  #E.g. path="/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data"

# Patient subfolder
echo "Enter the patient ID: " 
pat=$(get_patient )
pat_exist=$(check_original_data $path/$pat)

echo "${pat_exist% *}"

if [ "${pat_exist: -2}" = "-1" ] ; then
exit
fi

### Coregistration
cd $path/$pat/DWI/tractography
# Always use as reference image the modality with best resolution
flirt -in $path/$pat/DWI/working_data/b0_bet.nii.gz -ref $path/$pat/DWI/working_data/T1_unb_bet.nii.gz -dof 7 -cost normmi -omat diff2struct.mat
transformconvert diff2struct.mat $path/$pat/DWI/working_data/b0_bet.nii.gz $path/$pat/DWI/working_data/T1_unb_bet.nii.gz flirt_import diff2struct.txt

# apply the inverse of the found transformation matrix
mrtransform 5tt_nocoreg.mif -linear diff2struct.txt -inverse 5tt_coreg.mif
mrtransform $path/$pat/DWI/working_data/T1_unb_bet.nii.gz -linear diff2struct.txt -inverse T1_coreg.mif
echo SUCCESSFULL FLIRT

# # visually check the coregistration result
mrview $path/$pat/DWI/working_data/b0_bet.nii.gz -overlay.load $path/$pat/DWI/working_data/T1.nii.gz -overlay.colourmap 1 -overlay.load T1_coreg.mif -overlay.colourmap 2 


### Wholebrain streamlines creation done with the individual FOD, not used after --> commented out
#tckgen -act 5tt_coreg.mif -backtrack -crop_at_gmwmi -seed_dynamic $path/$pat/DWI/preprocessing/wm_fod_norm.mif -select 10M $path/$pat/DWI/preprocessing/wm_fod_norm.mif tracks_10mio.tck
#
## echo tckgen done!
#
#tcksift2 -act 5tt_coreg.mif -out_mu mu.txt tracks_10mio.tck $path/$pat/DWI/preprocessing/wm_fod_norm.mif  sift2_weights_10mio.csv
#
#tckedit tracks_10mio.tck –number 200k smallerTracks_200k.tck