#!/bin/bash
# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - lead_recon
#         - anat_t1.nii.gz
#         - anat_t1_bet.nii.gz
#

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

mkdir -p 2patient #creates folder iff it is not already there
lead_path=$path/$pat/lead_recon
#
# AIM Get transformation matrix diffusion - anat_t1
mask_while $lead_path anat_t1.nii anat_t1_bet # for patient 3 and 2 too much neck included, we manually repeated the bet with -R option

flirt -in DWI/working_data/b0_bet.nii.gz -ref $lead_path/anat_t1_bet.nii.gz -omat 2patient/diff2anat1.mat -out 2patient/dwi2anat_coreg.nii.gz -cost normmi -dof 7
mrview  $lead_path/anat_t1.nii -overlay.load 2patient/dwi2anat_coreg.nii.gz
echo successfull flirt!

transformconvert 2patient/diff2anat1.mat  DWI/working_data/b0_bet.nii.gz $lead_path/anat_t1_bet.nii.gz flirt_import 2patient/diff2anat1.txt
mrtransform $lead_path/anat_t1_bet.nii.gz -linear 2patient/diff2anat1.txt -inverse 2patient/anat2dwi_coreg.nii.gz
mrview DWI/working_data/b0_bet.nii.gz -overlay.load $lead_path/anat_t1_bet.nii.gz -overlay.colourmap 1 -overlay.load 2patient/anat2dwi_coreg.nii.gz -overlay.colourmap 2


#1. Get the warp (non-linear coregistration) and its inverse to map MNI and anat t1
mrconvert $lead_path/anat_t1.nii $lead_path/anat_t1_leaddbs.mif
warpinit $lead_path/anat_t1_leaddbs.mif 2patient/identity_warp[].nii #identity warp contains 3 volumes
for i in {0..2};
do antsApplyTransforms -d 3 -e 0 -i 2patient/identity_warp${i}.nii -o 2patient/mrtrix_warp${i}.nii -r $lead_path/anat_t1.nii -t $lead_path/glanatComposite.nii.gz --default-value 2147483647;
done
warpcorrect 2patient/mrtrix_warp[].nii 2patient/mrtrix_warp_corrected.mif -marker 2147483647
mrtransform $lead_path/anat_t1.nii -warp 2patient/mrtrix_warp_corrected.mif $lead_path/anat_t1_inMNIlead.mif
warpinvert 2patient/mrtrix_warp_corrected.mif 2patient/mrtrix_warp_corrected_inv.mif


## Coregister vat_left/right.nii from MNI to diffusion space             ##### stim at effect
for_each VTA_tracts/VTA* : mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif IN/vat_left.nii -\| \
  mrtransform - -linear 2patient/diff2anat1.txt -inverse IN/vat_left_coreg.nii.gz

for_each VTA_tracts/VTA* : mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif IN/vat_right.nii -\| \
  mrtransform - -linear 2patient/diff2anat1.txt -inverse IN/vat_right_coreg.nii.gz

for_each VTA_tracts/VTA* : mrcalc IN/vat_right_coreg.nii.gz IN/vat_left_coreg.nii.gz -max IN/vat_bilateral_coreg.nii

for_each VTA_tracts/VTA* : tckedit DWI/tractography/tracks_10mio_GROUP.tck IN/BOTH_tracks_NAME.tck \
  -include IN/vat_bilateral_coreg.nii -tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out IN/Both_tracks_NAME_weights_GROUP.csv

#for_each VTA_tracts/VTA* : tckedit DWI/tractography/tracks_10mio_GROUP.tck IN/LEFT_tracks_NAME.tck \
#  -include IN/vat_left_coreg.nii.gz -tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv
#
#for_each VTA_tracts/VTA* : tckedit DWI/tractography/tracks_10mio_GROUP.tck IN/RIGHT_tracks_NAME.tck \
#  -include IN/vat_right_coreg.nii.gz -tck_weights_in DWI/tractography/sift2_weights_10mio_GROUP.csv -tck_weights_out IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv

#INDIVIDUAL
#for_each VTA_tracts/VTA* : tckedit DWI/tractography/tracks_10mio.tck IN/LEFT_tracks_NAME_individual.tck \
#  -include IN/vat_left_coreg.nii.gz -tck_weights_in DWI/tractography/sift2_weights_10mio.csv -tck_weights_out IN/LEFT_tracks_NAME_sift2_weights_10mio.csv
#
#for_each VTA_tracts/VTA* : tckedit DWI/tractography/tracks_10mio_GROUP.tck IN/RIGHT_tracks_NAME_individual.tck \
#  -include IN/vat_right_coreg.nii.gz -tck_weights_in DWI/tractography/sift2_weights_10mio.csv -tck_weights_out IN/RIGHT_tracks_NAME_sift2_weights_10mio.csv

