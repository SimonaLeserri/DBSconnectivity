#!/bin/bash

# WHAT IT DOES
# transforms leadDBS fixed() in FSL fixed (), where fMRi images are defined
# by doing antsRegistration (takes some time)


# WHAT IT NEEDS
# The transformation diff2struct.txt created in streamlineCreation.sh


# OUTPUT STRUCTURE              (only additions shown)
# path/pat


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


cd $path/functional_HCP
mkdir -p transformations
cd transformations
fsl=/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz #already unskulled
lead_path=/home/brainstimmaps/04_Codebase/stable/leaddbs25x/templates/space/MNI_ICBM_2009b_NLIN_ASYM
lead=$lead_path/t1.nii
##
###Unskull the lead template using provided mask
#fslmaths $lead -mul $lead_path/brainmask.nii.gz $lead_path/t1_BRAIN.nii.gz
#
## 1. Get the transformation by doing ants Registration
## https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call
fixed=$fsl #fixed
moving=$lead_path/t1_BRAIN.nii.gz       #moving

echo $moving
echo $fixed


# order is always fixed moving
antsRegistration --verbose 1 --dimensionality 3 --float 0 \
--output [ants,moving_in_fixed_warped.nii.gz,fixed_in_moving_InverseWarped.nii.gz] \
--interpolation Linear \
--winsorize-image-intensities [0.005,0.995] \
--use-histogram-matching 1 \
--initial-moving-transform [$fixed,$moving,1] \
--transform Rigid[0.1] \
--metric CC[$fixed,$moving,1,4,Regular,0.1] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 8x4x2x1 \
--smoothing-sigmas 3x2x1x0vox \
--transform Affine[0.1] \
--metric CC[$fixed,$moving,1,4,Regular, 0.2] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 8x4x2x1 \
--smoothing-sigmas 3x2x1x0vox \
--transform SyN[0.1,3,0] \
--metric CC[$fixed,$moving,1,4] \
--convergence [100x70x50x20,1e-6,10] \
--shrink-factors 4x2x2x1 \
--smoothing-sigmas 2x2x1x0vox

# 2. Apply the warp antsApplyTransform
# convert t1 to mif in transformations directory
only_file="${moving##*/}"; #take all after last occurrence of /
no_extension="${only_file%%.*}"
echo $no_extension
mrconvert $moving $no_extension.mif
warpinit $no_extension.mif identity_warp[].nii
for i in {0..2};
do antsApplyTransforms -d 3 -e 0 -i identity_warp${i}.nii -o mrtrix_warp${i}.nii -r $fixed -t ants1Warp.nii.gz -t ants0GenericAffine.mat --default-value 2147483647;
done
warpcorrect mrtrix_warp[].nii mrtrix_warp_corrected.mif -marker 2147483647
mrtransform $moving -warp mrtrix_warp_corrected.mif lead_in_FSL.mif
warpinvert mrtrix_warp_corrected.mif mrtrix_warp_corrected_inv.mif
#

