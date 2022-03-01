#!/bin/bash

#!/bin/bash
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


cd $path/$pat
# GET ROIs (NAC/CAU/PFC) in native patient space

# NA/CAU in LI OCD ATLAS - already in the same space as lead and defined as individual files
OCD_atlas='/home/brainstimmaps/04_Codebase/stable/leaddbs25x/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/OCD Tract Target (Li 2020)/mixed'

mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif "$OCD_atlas"/Ca.nii.gz - | mrtransform - -linear 2patient/diff2anat1.txt -inverse 2patient/Ca_coreg.nii.gz
mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif "$OCD_atlas"/NAC.nii.gz - | mrtransform - -linear 2patient/diff2anat1.txt -inverse 2patient/NAC_coreg.nii.gz

# looking at the atlas description in $path/AtlasCollection/Brodmann/Brodmann_Known_default.txt, we select only prefrontal areas
# BA 8-9-10-11-12-13-14-24-25-32-44-45-46-47
# and we store their codes
left_codes=(7 8 9 10 11 20 21 26 36 37 38 39)
right_codes=(46 47 48 49 50 59 60 65 75 78 77 78)

# we do a first for loop to extract these areas from the coregistered atlas
#this for works with the elements of the array
for i in ${left_codes[@]}; do mrcalc 2patient/Brodmann_known_nodes_coreg.mif $i -eq "2patient/area_""$i"".mif";done
for i in ${right_codes[@]}; do mrcalc 2patient/Brodmann_known_nodes_coreg.mif $i -eq "2patient/area_""$i"".mif";done

# we join them together - one hemisphere only with mrcalc -max 2 at a time
len="${#left_codes[@]}" # starts from 1
mrconvert 2patient/area_"${left_codes[0]}".mif 2patient/merged_left.mif
#this for loop works on the index, starts from 0
for i in $(seq 0 $(($len-1)));
do mrcalc 2patient/merged_left.mif 2patient/area_"${left_codes[$i]}".mif -max 2patient/merged_left.mif -force;
done


mrconvert 2patient/area_"${right_codes[0]}".mif 2patient/merged_right.mif
#this for loop works on the index, starts from 0
for i in $(seq 0 $(($len-1)));
do mrcalc 2patient/merged_right.mif 2patient/area_"${right_codes[$i]}".mif -max 2patient/merged_right.mif -force;
done

mrcalc 2patient/merged_right.mif 2patient/merged_left.mif -add 2patient/prefrontal_bilateral.mif

tckedit DWI/tractography/tracks_10mio_GROUP.tck DWI/tractography/Bilateral_Anhedonia_network.tck \
-include 2patient/Ca_coreg.nii.gz -include 2patient/NAC_coreg.nii.gz -include 2patient/prefrontal_bilateral.mif \
-tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out DWI/tractography/Bilateral_AN_weights.csv

for_each VTA_tracts/VTA* : tckedit DWI/tractography/Bilateral_Anhedonia_network.tck IN/Bilateral_AN_NAME_overlap.tck \
  -include IN/vat_bilateral_coreg.nii -tck_weights_in DWI/tractography/Bilateral_AN_weights.csv -tck_weights_out IN/Bilateral_NAME_overlap_weights.csv





