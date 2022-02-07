#!/bin/bash

# WHAT IT DOES
# estimates the response function
# estimates the fiber orientation distribution
# performs normal intensity normalization

# WHAT IT NEEDS
# The script Preprocessing2EDDY.sh already executed
# A good path/pat/DWI/eddy/dwi_den_unr_preproc_bet_mask.nii.gz 
# (visually inspect with mrview and change in a separate terminal using different -f values in bet, if needed)

# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - DWI
#           - preprocessing
#               - dwi_den_unr_preproc_bet_mask.mif
#               - wm.txt
#               - gm.txt
#               - csf.txt
#               - voxels.mif
#               - wm_fod.mif
#               - gm_fod.mif
#               - csf_fod.mif
#               - vf.mif
#               - wm_fod_norm.mif
#               - gm_fod_norm.mif
#               - csf_fod_norm.mif
#               - vf_norm.mif


#############################################################################

source ./utils.sh

# Data path of all the project
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

cd $path/$pat/DWI/preprocessing
mrconvert dwi_den_unr_preproc_bet_mask.nii.gz dwi_den_unr_preproc_bet_mask.mif

### Response function estimation for different tissues
dwi2response dhollander dwi_den_unr_preproc.mif wm.txt gm.txt csf.txt -voxels voxels.mif

# checking Red shows voxels used for CSF-response function estimation, blue GM and green WM.
mrview dwi_den_unr_preproc.mif -overlay.load voxels.mif

### Estimation of fiber orientation distribution (FOD)
dwi2fod msmt_csd dwi_den_unr_preproc.mif -mask dwi_den_unr_preproc_bet_mask.mif wm.txt wm_fod.mif gm.txt gm_fod.mif csf.txt csf_fod.mif

# checking
mrconvert -coord 3 0 wm_fod.mif - | mrcat csf_fod.mif gm_fod.mif - vf.mif #stands for volume fraction
mrview vf.mif -odf.load_sh wm_fod.mif #display the white matter FOD on a map which shows the estimated volume fraction of each tissue type

### Global intensity normalisation
mtnormalise wm_fod.mif wm_fod_norm.mif gm_fod.mif gm_fod_norm.mif csf_fod.mif csf_fod_norm.mif -mask dwi_den_unr_preproc_bet_mask.mif
mrconvert -coord 3 0 wm_fod_norm.mif - | mrcat csf_fod_norm.mif gm_fod_norm.mif - vf_norm.mif

# checking
mrview vf_norm.mif -odf.load_sh wm_fod_norm.mif