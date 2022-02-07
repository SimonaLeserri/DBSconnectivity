#!/bin/bash

path=/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data
pat=Patient1
cd $path/$pat

for_each VTA_tracts/VTA* : tckedit DWI/tractography/RIGHT_Anhedonia_network.tck IN/RIGHT_AN_NAME_overlap.tck \
  -include IN/vat_right_coreg.nii.gz -tck_weights_in DWI/tractography/Right_AN_weights.csv -tck_weights_out IN/Right_NAME_overlap_weights.csv

for_each VTA_tracts/VTA* : tckedit DWI/tractography/LEFT_Anhedonia_network.tck IN/LEFT_AN_NAME_overlap.tck \
  -include IN/vat_left_coreg.nii.gz -tck_weights_in DWI/tractography/Left_AN_weights.csv -tck_weights_out IN/Left_NAME_overlap_weights.csv