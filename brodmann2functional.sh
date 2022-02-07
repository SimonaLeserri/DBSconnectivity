#!/bin/bash

# WHAT IT DOES
# transforms broadmann atlas defined in  MNI ICBM 2009a Nonlinear Symmetric space into the FSL functional space (MNI152 nonlinear 6th generation)
# by doing antsRegistration (takes some time)
# regrids it to the FSL voxels representation
# relabels it with increasing codes (only known areas)
# finally it splits it into multiple files
# merges bilateral areas and creates LUT



# OUTPUT STRUCTURE              (only additions shown)
# path/pat


#############################################################################


source ./utils.sh

# Data path of all the project
echo "Enter the complete data path of the project: "
path=$(get_path ) #E.g. path="/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data"



cd $path/functional_HCP
fsl=$path/functional_HCP/MNI152_T1_1mm_brain.nii.gz # also found in /usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz, already unskulled
mkdir -p transformationsBrodmann
cd transformationsBrodmann

brodmann_path=/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/template/mni_icbm152_nlin_sym_09a
brodmann=$brodmann_path/mni_icbm152_t1_tal_nlin_sym_09a.nii

##Unskull the brodmann template using provided mask
fslmaths $brodmann -mul $brodmann_path/mni_icbm152_t1_tal_nlin_sym_09a_mask.nii $brodmann_path/t1_BRAIN.nii.gz

# 1. Get the transformation by doing ants Registration
# https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call
fixed=$fsl #fixed
moving=$brodmann_path/t1_BRAIN.nii.gz    #moving

echo moving: $moving
echo fixed : $fixed


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
mrtransform $moving -warp mrtrix_warp_corrected.mif brodmann_in_FSL.mif
warpinvert mrtrix_warp_corrected.mif mrtrix_warp_corrected_inv.mif
#

#apply transform to the atlas
mrtransform $brodmann_path/../../Brodmann_ICBM152.nii.gz -warp mrtrix_warp_corrected.mif -interp nearest brodmannATLAS_in_FSL.mif
mrgrid brodmannATLAS_in_FSL.mif regrid -template $path/functional_HCP/Template4regridding.mif -interp nearest brodmannATLAS_in_FSL_regridded.mif
##convert label as done in brodmann.sh to have increasing order that MRtrix likes
labelconvert brodmannATLAS_in_FSL_regridded.mif $brodmann_path/../../BrodmannColorLUT.txt $brodmann_path/../../Brodmann_known_default.txt Brodmann_known_nodesFSL.mif
mkdir separated_Known_Brodmann
while IFS= read -r line || [ -n "$line" ]; do #caputers also the last line,that has no newline at the end
    stringarray=($line)
    code=${stringarray[0]}
    label=${stringarray[1]}
    echo $code
    if ! [[ -z "${code// }" ]];
    then
      mrcalc Brodmann_known_nodesFSL.mif $code -eq separated_Known_Brodmann/$label.nii
    fi

done < <(tail +7 $path/AtlasCollection/Brodmann/Brodmann_known_default.txt)
cd separated_Known_Brodmann
mkdir bilateral
counter=1
for i in $(ls -tr | head -$(($code / 2)));
do

  area_nii=${i##*-}
  echo $counter ${area_nii%.*} >> $path/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt
  counter=$((counter+1))
  symmetric_files=$(find *${i##*-}) ;#everything after last occurrence of -
  #echo joining ${symmetric_files[0]} ${symmetric_files[1]}
  mrcalc ${symmetric_files[0]} ${symmetric_files[1]} -max bilateral/$area_nii
done;
