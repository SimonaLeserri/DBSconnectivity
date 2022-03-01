#!/bin/bash


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

for file in `find  $path/$pat/VTA_tracts/plot/functional/significant_Voxels_for_measure_*.nii -maxdepth 1`;do
  file_and_ext="${file##*/}"
  file_only="${file_and_ext%%.*}"
  echo $file_only

  compute_Brodmann_average_number $path/$pat/VTA_tracts/plot/functional/$file_only.nii $path/$pat/VTA_tracts/plot/functional/"${file_only}"_avg_nozero.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/bilateral/regridded

done
#compute_Brodmann_average_number $path/$pat/VTA_tracts/plot/functional/significant_Voxels_for_measure_SHAPS.nii $path/$pat/VTA_tracts/plot/functional/significant_Voxels_for_measure_SHAPS_avg.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/bilateral/regridded

#$functional_image_path $output_path $LUT_path $separated_path