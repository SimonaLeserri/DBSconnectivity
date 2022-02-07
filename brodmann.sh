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



brodmann_path=$path/AtlasCollection/Brodmann
lead_path=$path/$pat/lead_recon

#ive created the default just to have label in continuous increasing order
#python CreatingLUT.py --full_path $brodmann_path/BrodmannColorLUT.txt
cd $path/$pat
#
#labelconvert $brodmann_path/Brodmann_ICBM152.nii.gz $brodmann_path/BrodmannColorLUT.txt $brodmann_path/Brodmann_known_default.txt 2patient/Brodmann_known_nodesMNI.mif
##transform from MNI to anatt1 (nonlinear) using warp created in All_VTAs_to_diffusion staring from Glanatt1 - linear opnion needed cause atlas should have only positive integer values
## linear transform anatt1-diffusion using transformations created in All_VTAs_toDiffusion
#mrtransform -warp 2patient/mrtrix_warp_corrected_inv.mif  -interp nearest 2patient/Brodmann_known_nodesMNI.mif - | mrtransform - -linear 2patient/diff2anat1.txt -inverse 2patient/Brodmann_known_nodes_coreg.mif
#

coreg_nodes=2patient/Brodmann_known_nodes_coreg.mif

# weighted vector bilateral

for_each VTA_tracts/VTA* : tck2connectome IN/BOTH_tracks_NAME.tck $coreg_nodes IN/NAME_Brod_vec_weight.csv -tck_weights_in IN/Both_tracks_NAME_weights_GROUP.csv -vector -f
##weighted
#for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brod_vec_weight.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector -f
##raw count
#for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brod_vec_count.csv -vector -f
##per streamline(matrix)
#for_each  VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brod_mrx_weight.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/R_NAME_Brodmann_tract_points.txt -f
#
## Get the vector and matrix of connections left VTA-cortex
#
##weighted
#for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brod_vec_weight.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector -f
##raw count
#for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brod_vec_count.csv -vector -f
##per streamline(matrix)
#for_each  VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brod_mrx_weight.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/L_NAME_Brodmann_tract_points.txt -f
#


#OLD CONFUSING NAMING CONVECTIONS
##weighted
#for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brodmann_weighted_fingerprint.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector
##raw count
#for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brodmann_fingerprint.csv -vector
##per streamline(matrix)
#for_each  VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_Brodmann_weighted_fingerprint_matrix.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/R_NAME_Brodmann_per_tract_endpoints.txt
#
## Get the vector and matrix of connections left VTA-cortex
#
##weighted
#for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brodmann_weighted_fingerprint.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector
##raw count
#for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brodmann_fingerprint.csv -vector
##per streamline(matrix)
#for_each  VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_Brodmann_weighted_fingerprint_matrix.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/L_NAME_Brodmann_per_tract_endpoints.txt
