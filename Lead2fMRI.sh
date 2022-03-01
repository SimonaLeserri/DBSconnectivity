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
cd transformations

## 3. Transform the VTA in fsl MNI space and regrids

for_each $path/$pat/VTA_tracts/VTA* : mrtransform -warp mrtrix_warp_corrected.mif IN/vat_right.nii  IN/vat_right_FSL.mif
for_each $path/$pat/VTA_tracts/VTA* : mrgrid IN/vat_right_FSL.mif regrid -template $path/functional_HCP/Template4regridding.mif -interp nearest IN/vat_right_FSL_regridded.nii


for_each $path/$pat/VTA_tracts/VTA* : mrtransform -warp mrtrix_warp_corrected.mif IN/vat_left.nii  IN/vat_left_FSL.mif
for_each $path/$pat/VTA_tracts/VTA* : mrgrid IN/vat_left_FSL.mif regrid -template $path/functional_HCP/Template4regridding.mif -interp nearest IN/vat_left_FSL_regridded.nii
