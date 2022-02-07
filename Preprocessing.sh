#!/bin/bash

# WHAT IT DOES
# writes to path/pat/DWI a folder working_data with a copy of the data neded for the entire pipeline
# performs denoising and unringing of the diffusion image
# performs b0 distortion correction through synb0 ad writes the results in path/pat/DWI/synb0/OUTPUTS
# prepares data needed for synb0 and eddy correction if not provided already

# OUTPUT STRUCTURE
# the following data structure
# path/path
#       - original_data
#           - T1.nii.gz
#           - T1.mif
#           - T2.mif
#           - dwi_raw.mif
#           - postop_tra.nii
#       - DWI
#           - working_data
#               - T1.nii.gz
#               - T2.mif
#               - dwi_raw.mif
#               - dwi_den.mif
#               - dwi_den_unr.mif
#               - b0.nii.gz
#               - postop_tra.nii    
#           - synb0
#               - INPUTS
#                   -acqparam.txt
#                   - T1.nii.gz
#                   - b0.nii.gz
#               - OUTPUTS
#                   check https://github.com/MASILab/Synb0-DISCO for detailed explaination
#           - eddy
#               - index.txt
#               - acqparams.txt
#               - b0_bet.nii.gz
#               - b0_bet_mask.nii.gz
#               - bvals
#               - bvecs
#               - dwi_den_unr.nii.gz

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
check_folders $path/$pat


## Preserve the original data and only work with the working_data
cp -r $path/$pat/original_data $path/$pat/DWI/working_data
cd $path/$pat/DWI/working_data 

### Preprocessing

# Denoise, unring and extract b0
dwidenoise dwi_raw.mif dwi_den.mif
mrdegibbs dwi_den.mif dwi_den_unr.mif -axes '0,1' 
dwiextract dwi_den_unr.mif b0.nii.gz -bzero

### Prepare data and run synb0

# Copy the dwi and the t1 files in the synb0 input dir
cp -i T1.nii.gz $path/$pat/DWI/synb0/INPUTS/
cp -i b0.nii.gz $path/$pat/DWI/synb0/INPUTS/

# Run in a machine with big enough RAM
echo About to enter docker to run synb0 !
cd $path/$pat/DWI/synb0
docker run --rm \
  -v $(pwd)/INPUTS/:/INPUTS/ \
  -v $(pwd)/OUTPUTS:/OUTPUTS/ \
  -v /usr/local/freesurfer/license.txt:/extra/freesurfer/license.txt \
  --user $(id -u):$(id -g) \
  justinblaber/synb0_25iso
cd ..

### Eddy preparation
mrconvert working_data/dwi_den_unr.mif eddy/dwi_den_unr.nii.gz -export_grad_fsl eddy/bvecs eddy/bvals
mask_while $path/$pat/DWI working_data/b0.nii.gz eddy/b0_bet
