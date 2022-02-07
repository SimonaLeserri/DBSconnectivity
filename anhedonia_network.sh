#!/bin/bash

path=/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data
pat=Patient1
cd $path/$pat
# GET ROIs (NAC/CAU/PFC) in native patient space

# NA/CAU in LI OCD ATLAS - already in the same space as lead and defined as individual files
OCD_atlas='/home/brainstimmaps/04_Codebase/stable/leaddbs25x/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/OCD Tract Target (Li 2020)/mixed'

mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif "$OCD_atlas"/Ca.nii.gz - | mrtransform - -linear 2patient/diff2anat1.txt -inverse 2patient/Ca_coreg.nii.gz
mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif "$OCD_atlas"/NAC.nii.gz - | mrtransform - -linear 2patient/diff2anat1.txt -inverse 2patient/NAC_coreg.nii.gz

# looking at the atlas description, we select only prefrontal ares (as defined in https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation ) and we store their codes
left_codes=(89 52 93 83 95 73 58 66 86 67)
right_codes=(38 1 42 32 44 22 7 15 35 16)

# we do a first for loop to extract these areas from the coregistered atlas
#this for works with the elements of the array
for i in ${left_codes[@]}; do mrcalc 2patient/Cerebra_coregistered.nii $i -eq "2patient/area_""$i"".mif";done
for i in ${right_codes[@]}; do mrcalc 2patient/Cerebra_coregistered.nii $i -eq "2patient/area_""$i"".mif";done

# we join them together - one hemisphere only with mrcalc -max 2 at a time
len="${#left_codes[@]}" # starts from 1
mrconvert 2patient/area_"${left_codes[0]}".mif 2patient/merged_left.mif
#this for loop works on the index, starts from 0
for i in $(seq 0 $(($len-1)));
do mrcalc 2patient/merged_left.mif 2patient/area_"${left_codes[$i]}".mif -max 2patient/merged_left.mif -force;
done


mrconvert 2patient/area_"${right_codes[0]}".mif 2patient/merged_right.mif
this for loop works on the index, starts from 0
for i in $(seq 0 $(($len-1)));
do mrcalc 2patient/merged_right.mif 2patient/area_"${right_codes[$i]}".mif -max 2patient/merged_right.mif -force;
done

tckedit DWI/tractography/tracks_10mio_GROUP.tck DWI/tractography/RIGHT_Anhedonia_network.tck \
-include 2patient/Ca_coreg.nii.gz -include 2patient/NAC_coreg.nii.gz -include 2patient/merged_right.mif \
-tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out DWI/tractography/Right_AN_weights.csv

tckedit DWI/tractography/tracks_10mio_GROUP.tck DWI/tractography/LEFT_Anhedonia_network.tck \
-include 2patient/Ca_coreg.nii.gz -include 2patient/NAC_coreg.nii.gz -include 2patient/merged_left.mif \
-tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out DWI/tractography/Left_AN_weights.csv



