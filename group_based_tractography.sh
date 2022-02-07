#!/bin/bash

# WHAT IT DOES
# Creates group avrage response fuctions so as to enable comparison of Fiber Orientation distributions
# Computes individual fiber orientation distribution (FOD) based on common group average
# Performs Intensity normalisation of individual FOD

# WHAT IT NEEDS
# all the scripts of the Diffusion (Pre)processing group already executed
# for each patient
# OUTPUT STRUCTURE
# path/
#       - GROUP_RF
#           - group_average_response_wm.txt
#           - group_average_response_gm.txt
#           - group_average_response_csf.txt
         

#############################################################################

source ./utils.sh

#Data path of all the project
echo "Enter the complete data path of the project: " 
path=$(get_path )  #E.g. path="/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data"

cd $path

mkdir Group_RF

### Compute group average response functions - write each patient by hand
responsemean Patient1/DWI/preprocessing/wm.txt Patient2/DWI/preprocessing/wm.txt Patient3/DWI/preprocessing/wm.txt Group_RF/group_average_response_wm.txt
responsemean Patient1/DWI/preprocessing/gm.txt Patient2/DWI/preprocessing/gm.txt Patient3/DWI/preprocessing/gm.txt Group_RF/group_average_response_gm.txt
responsemean Patient1/DWI/preprocessing/csf.txt Patient2/DWI/preprocessing/csf.txt Patient3/DWI/preprocessing/csf.txt Group_RF/group_average_response_csf.txt

### Compute individual fiber orientation distribution (FOD) based on common group average
for_each Patient* : dwi2fod msmt_csd IN/DWI/preprocessing/dwi_den_unr_preproc.mif Group_RF/group_average_response_wm.txt IN/DWI/preprocessing/wmfod_group.mif \
Group_RF/group_average_response_gm.txt IN/DWI/preprocessing/gmfod_group.mif Group_RF/group_average_response_csf.txt IN/DWI/preprocessing/csffod_group.mif -mask IN/DWI/preprocessing/dwi_den_unr_preproc_bet_mask.mif

### Perform Intensity normalisation of individual FOD
for_each Patient* : mtnormalise IN/DWI/preprocessing/wmfod_group.mif IN/DWI/preprocessing/wmfod_group_norm.mif IN/DWI/preprocessing/gmfod_group.mif IN/DWI/preprocessing/gmfod_group_norm.mif \
IN/DWI/preprocessing/csffod_group.mif IN/DWI/preprocessing/csffod_group_norm.mif -mask IN/DWI/preprocessing/dwi_den_unr_preproc_bet_mask.mif

#Tracking 10M streamlines
for_each Patient* : tckgen -act IN/DWI/tractography/5tt_coreg.mif -backtrack -crop_at_gmwmi -seed_dynamic IN/DWI/preprocessing/wmfod_group_norm.mif \
-select 10M IN/DWI/preprocessing/wmfod_group_norm.mif IN/DWI/tractography/tracks_10mio_GROUP.tck
# SIFT2
for_each Patient* : tcksift2 -act IN/DWI/tractography/5tt_coreg.mif IN/DWI/tractography/tracks_10mio_GROUP.tck IN/DWI/preprocessing/wmfod_group_norm.mif \
IN/DWI/tractography/sift2_weights_10mio_GROUP.csv -out_mu IN/DWI/tractography/mu_GROUP.txt





