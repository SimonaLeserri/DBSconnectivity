#!/bin/bash

# WHAT IT DOES
# performs eddy current correction, yielding (among the other files) dwi_den_unr_preproc.mif)
# creates a brain mask (dwi_den_unr_preproc_bet_mask.nii.gz)

# WHAT IT NEEDS
# The script Preprocessing.sh already executed
# A good path/pat/DWI/eddy/b0_bet_mask.nii.gz 
# (visually inspect with mrview and change in a separate terminal using different -f values in bet, if needed)

# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - DWI
#           - eddy              (only most relevant shown)
#               - output_eddy.nii.gz
#           - preprocessing
#               - dwi_den_unr_preproc.mif
#               - dwi_den_unr_preproc.nii.gz
#               - dwi_den_unr_preproc_bet.nii.gz
#               - dwi_den_unr_preproc_bet_mask.nii.gz


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

### Eddy current correction

cd $path/$pat/DWI/eddy
echo starting eddy!

eddy_openmp --imain=$path/$pat/DWI/eddy/dwi_den_unr.nii.gz --mask=b0_bet_mask.nii.gz \
--acqp=acqparams.txt --index=index.txt --bvecs=bvecs --bvals=bvals \
 --topup=$path/$pat/DWI/synb0/OUTPUTS/topup --repol --data_is_shelled --out=output_eddy --cnr_maps --verbose

echo Eddy is over!

### Brain mask estimation

cd ..
mkdir preprocessing
cd preprocessing

mrconvert ../eddy/output_eddy.nii.gz dwi_den_unr_preproc.mif -fslgrad ../eddy/output_eddy.eddy_rotated_bvecs ../eddy/bvals
mrconvert dwi_den_unr_preproc.mif dwi_den_unr_preproc.nii.gz

# For brain mask estimation, dwi2mask should be used
# but as it gives you little control over the mask creation,
# you can use bet instead and try different f values.

mask_while $path/$pat/DWI/preprocessing dwi_den_unr_preproc.nii.gz dwi_den_unr_preproc_bet

# Visually inspect bet result, modify f value if needed
mrview dwi_den_unr_preproc.nii.gz -overlay.load dwi_den_unr_preproc_bet_mask.nii.gz

