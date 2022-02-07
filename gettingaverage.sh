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


compute_Brodmann_average $path/$pat/VTA_tracts/plot/functional/significant_Voxels_for_measure_MADRS.nii $path/$pat/VTA_tracts/plot/functional/significant_Voxels_for_measure_MADRS_averaged.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral_ATTEMPT.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/ciao
#compute_Brodmann_average $path/$pat/VTA_tracts/plot/functional/HAMD_optimal_connectivity_profile.nii $path/$pat/VTA_tracts/plot/functional/R_HAMD_averaged.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/bilateral

#$functional_image_path $output_path $LUT_path $separated_path

