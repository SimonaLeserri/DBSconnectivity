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

#cd $path/$pat/VTA_tracts

for subdir in `find $path/$pat/VTA_tracts/VTA* -maxdepth 0 -type d`; do
compute_Brodmann_average  $subdir/z_fingerprint.nii $subdir/averaged_z_fingerprint.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/bilateral/regridded
python bimodal_plot.py --patient_path $path/$pat --plot_path $path/$pat/VTA_tracts/plot --save_path $subdir --VTA_code $subdir
done


#compute_Brodmann_average $path/$pat/VTA_tracts/plot/functional/HAMD_optimal_connectivity_profile.nii $path/$pat/VTA_tracts/plot/functional/R_HAMD_averaged.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default_bilateral.txt /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP/transformationsBrodmann/separated_Known_Brodmann/bilateral

#$functional_image_path $output_path $LUT_path $separated_path

