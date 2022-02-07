#!/bin/bash
# OUTPUT STRUCTURE              (only additions shown)
# path/pat
#       - lead_recon
#         - anat_t1.nii.gz
#         - anat_t1_bet.nii.gz
#

source ./utils.sh

script_dir=$(pwd)

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

#mkdir -p 2patient #creates folder iff it is not already there
lead_path=$path/$pat/lead_recon
mrtrix_fsl=/usr/local/mrtrix3/share/mrtrix3/labelconvert
freesurfer_path=/usr/local/freesurfer
#
### We want to know where in the cortex the streamlines included in the VTA end
# convert fsl pacellation to nodes, an atlas that mrtrix can interpret
# following https://mrtrix.readthedocs.io/en/latest/reference/commands/labelconvert.html
# https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation
#
#labelconvert DWI/reconAll/mri/aparc+aseg.mgz $freesurfer_path/FreeSurferColorLUT.txt $mrtrix_fsl/fs_default.txt 2patient/nodes.mif

# move nodes.mif from t1 to diffusion space
#mrtransform 2patient/nodes.mif -linear DWI/tractography/diff2struct.txt -inverse  2patient/coregistered_nodes.mif

coreg_nodes=$path/$pat/2patient/coregistered_nodes.mif #should not contain IN magic word or for each would implode

#weighted
for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_weighted_fingerprint.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector
#raw count
for_each VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_fingerprint.csv -vector
#per streamline(matrix)
for_each  VTA_tracts/VTA* : tck2connectome IN/RIGHT_tracks_NAME.tck $coreg_nodes IN/R_NAME_weighted_fingerprint_matrix.csv -tck_weights_in IN/RIGHT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/R_NAME_per_tract_endpoints.txt

# Get the vector and matrix of connections left VTA-cortex

#weighted
for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_weighted_fingerprint.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -vector
#raw count
for_each VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_fingerprint.csv -vector
#per streamline(matrix)
for_each  VTA_tracts/VTA* : tck2connectome IN/LEFT_tracks_NAME.tck $coreg_nodes IN/L_NAME_weighted_fingerprint_matrix.csv -tck_weights_in IN/LEFT_tracks_NAME_sift2_weights_10mio_GROUP.csv -out_assignments IN/L_NAME_per_tract_endpoints.txt



