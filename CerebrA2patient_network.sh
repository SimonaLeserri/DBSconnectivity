#!/bin/bash

# WHAT IT DOES
# transforms Cerebra Atlas (unique nii file) and corresponding template(2009cSym) in diffusion patient space
# by doing antsRegistration (takes some time)

# WHAT IT NEEDS
# The transformation diff2struct.txt created in streamlineCreation.sh
# Download from http://nist.mni.mcgill.ca/icbm-152-nonlinear-atlases-2009/ both the atlas, CerebrA and the template(symmetric)
# place both extracted folders in the newly created path/AtlasCollection/CerebrA

# OUTPUT STRUCTURE              (only additions shown)



#############################################################################


# Data path of all the project
path=/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data
# Patient subfolder
pat=Patient1
#Leaddbs reconstruction path 
#mkdir $path/$pat/2patient/cerebra
cd $path/$pat/2patient/cerebra
cerebra=$path/AtlasCollection/CerebrA
#
##get the skulled template
#skulled_temp=$cerebra/mni_icbm152_nlin_sym_09c_nifti/mni_icbm152_nlin_sym_09c/mni_icbm152_t1_tal_nlin_sym_09c.nii
atlas=$cerebra/mni_icbm152_nlin_sym_09c_CerebrA_nifti/mni_icbm152_CerebrA_tal_nlin_sym_09c.nii
#mask=$cerebra/mni_icbm152_nlin_sym_09c_nifti/mni_icbm152_nlin_sym_09c/mni_icbm152_t1_tal_nlin_sym_09c_mask.nii
#
##Unskull the template using provided mask
#fslmaths $skulled_temp -mul $mask $cerebra/mni_icbm152_t1_tal_nlin_sym_09c_BRAIN.nii
#
#
## 1. Get the transformation by doing ants Registration
## https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call
template=$cerebra/mni_icbm152_t1_tal_nlin_sym_09c_BRAIN.nii.gz  #fixed
t1brain=$path/$pat/DWI/working_data/T1_unb_bet.nii.gz           #moving

echo $t1brain
echo $template


# order is always fixed moving
#antsRegistration --verbose 1 --dimensionality 3 --float 0 \
#--output [ants,moving_in_fixed_warped.nii.gz,fixed_in_moving_InverseWarped.nii.gz] \
#--interpolation Linear \
#--winsorize-image-intensities [0.005,0.995] \
#--use-histogram-matching 1 \
#--initial-moving-transform [$template,$t1brain,1] \
#--transform Rigid[0.1] \
#--metric CC[$template,$t1brain,1,4,Regular,0.1] \
#--convergence [1000x500x250x100,1e-6,10] \
#--shrink-factors 8x4x2x1 \
#--smoothing-sigmas 3x2x1x0vox \
#--transform Affine[0.1] \
#--metric CC[$template,$t1brain,1,4,Regular, 0.2] \
#--convergence [1000x500x250x100,1e-6,10] \
#--shrink-factors 8x4x2x1 \
#--smoothing-sigmas 3x2x1x0vox \
#--transform SyN[0.1,3,0] \
#--metric CC[$template,$t1brain,1,4] \
#--convergence [100x70x50x20,1e-6,10] \
#--shrink-factors 4x2x2x1 \
#--smoothing-sigmas 2x2x1x0vox


# 2. Apply the warp antsApplyTransform
# convert t1 to mif in temp_atlas directory
#only_file="${t1brain##*/}"; #take all after last occurrence of /
#no_extension="${only_file%%.*}"
#echo $no_extension
#mrconvert $t1brain $no_extension.mif -force
#warpinit $no_extension.mif identity_warp[].nii -f
#for i in {0..2};
#do antsApplyTransforms -d 3 -e 0 -i identity_warp${i}.nii -o mrtrix_warp${i}.nii -r $template -t ants1Warp.nii.gz -t ants0GenericAffine.mat --default-value 2147483647;
#done
#warpcorrect mrtrix_warp[].nii mrtrix_warp_corrected.mif -marker 2147483647 -f
#mrtransform $t1brain -warp mrtrix_warp_corrected.mif T1inMNI.mif -force
#warpinvert mrtrix_warp_corrected.mif mrtrix_warp_corrected_inv.mif -f

# 3. Transform the atlas in native space
mrtransform $atlas -warp mrtrix_warp_corrected_inv.mif -interp nearest - | mrtransform - -linear $path/$pat/DWI/tractography/diff2struct.txt -inverse $path/$pat/2patient/Cerebra_coregistered.nii