#!/bin/bash

get_path(){ 
    read base_path
    echo $base_path
}

get_patient(){ 
    read patient_id
    echo $patient_id
}

get_fsl_subject_path(){ 
    read fsl_path
    echo $fsl_path
}

compute_Brodmann_average()
{
  functional_image_path="$1"

  output_path="$2"

  LUT_path="$3"

  separated_path="$4"

  echo code label average_value >> $output_path
  while IFS= read -r line; do
      stringarray=($line)
      code=${stringarray[0]}
      label=${stringarray[1]}
      if ! [[ -z "${code// }" ]]; # we remove the blank space between left ans right hemisphere - specific to bradmann known parcellation
      then

        average_in_this_area=$(mrstats -output mean -mask $separated_path/$label.nii $functional_image_path)
        echo $code $label $average_in_this_area >> $output_path
      fi

  done<$LUT_path #bilateral
  #when reading from 78 brodmann LUT use done< <(tail +7 $LUT_path) cause we know that in there the header is 7 lines long
}

compute_Brodmann_average_number()
{
  functional_image_path="$1"

  output_path="$2"

  LUT_path="$3"

  separated_path="$4"

  echo code label average_value n_voxels perthousand_sig_on_area >> $output_path
  while IFS= read -r line; do
      stringarray=($line)
      code=${stringarray[0]}
      label=${stringarray[1]}
      if ! [[ -z "${code// }" ]]; # we remove the blank space between left ans right hemisphere - specific to bradmann known parcellation
      then

        average_in_this_area=$(mrstats -output mean -ignorezero -mask $separated_path/$label.nii  $functional_image_path)
        echo $average_in_this_area
        if [ -z "$average_in_this_area" ]
        then
              echo "\$average_in_this_area is empty"
              N_sig_voxels_in_this_area=0
        else
              echo "\$average_in_this_area is NOT empty"
              N_sig_voxels_in_this_area=$(mrstats -output count -ignorezero -mask $separated_path/$label.nii $functional_image_path)
        fi
        N_voxels_in_this_area=$(mrstats -output count $separated_path/$label.nii)
        perthousand_significant_on_area=$(bc <<< "scale=2;$N_sig_voxels_in_this_area*1000/$N_voxels_in_this_area")
        echo $code $label $average_in_this_area $N_sig_voxels_in_this_area $perthousand_significant_on_area>> $output_path
      fi

  done<$LUT_path #bilateral
  #when reading from 78 brodmann LUT use done< <(tail +7 $LUT_path) cause we know that in there the header is 7 lines long
}
check_original_data()

# warns if the needed images (T1.mif T2.mif dwi_raw.mif postop_tra.nii)
# can not be found in the folder path/pat/original_data
{
    complete_path="$1"
    
    if [ -d "$complete_path" ] 
    then
        if [ ! -d "$complete_path/original_data" ]; then
            echo "Could not find folder original data :("
            echo -1        
        else
        for i in T1.mif T2.mif dwi_raw.mif postop_tra.nii
        do
        FILE=$complete_path/original_data/$i
            if [ ! -f "$FILE" ]; then
                echo "$FILE does not exists in original_data!"
                echo "You might have problems at some point :("        
            fi
            if [ $i == 'T1.mif' ] && [ ! -f $complete_path/original_data/T1.nii.gz ]; then
                
                mrconvert $complete_path/original_data/T1.mif $complete_path/original_data/T1.nii.gz
            fi
        done
        fi
    
    else
    echo There is no such patient "$complete_path"
    echo -1
    fi
    
}

check_folders(){
    complete_path="$1"
    directory=$complete_path/DWI
    if [ ! -d "$directory" ]; then
        echo 'I am creating the files needed for the preprocessing'
        mkdir $directory
        mkdir $directory/eddy
        mkdir $directory/synb0
        mkdir $directory/synb0/INPUTS
        mkdir $directory/synb0/OUTPUTS
        #mrinfo $complete_path/original_data/dwi_raw.mif -json_all $directory/synb0/dwi_head.json
        PhaseEncodingDirection=$(mrinfo $complete_path/original_data/dwi_raw.mif -property PhaseEncodingDirection ) 
        
        TotalReadoutTime=$(mrinfo $complete_path/original_data/dwi_raw.mif -property TotalReadoutTime )
        
        Dimensions=$(mrinfo $complete_path/original_data/dwi_raw.mif -size)
        Directions="${Dimensions##* }"
        
        python writing.py --CompletePath $complete_path --PhaseEncodingDirection $PhaseEncodingDirection --TotalReadoutTime $TotalReadoutTime --Directions $Directions
        #cp -r $complete_path/DWI/synb0/INPUTS/acqparams.txt $complete_path/DWI/eddy/acqparams.txt
        echo 'Files are ready!'
    else
        
        if [[ -f "$directory/synb0/INPUTS/acqparams.txt" && -f "$directory/eddy/index.txt" ]]; then
            echo 'I will be using the files acqparams.txt and index.txt you provided'
        fi
    fi

}

mask_while(){
    general_path=$1
    input=$2
    output=$3
    while [[  "$ANSWER" != "y" ]]
    do
    read -s -p " what f value should I try? :" F
    echo $F
    bet $general_path/$input $general_path/$output -m -f $F
    mrview $general_path/$input -overlay.load "${general_path}/${output}_mask.nii.gz" 
    read -s -p "Are you happy with the result? [y/n]: " ANSWER
    echo $ANSWER
    done
    echo 'Mask saved!'
}

ask_T2(){
    read T2_answer
    echo $T2_answer
}