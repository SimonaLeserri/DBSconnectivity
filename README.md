# Connectivity pipeline

Here is the pipeline for the analysis of Deep Brain Stimulation (DBS) connectivity for patients with Treatment Resistant Depression.
It contains the code for my master thesis at the ['Brain Stimulation Mapping group at Inselspital and ARTORG Bern'](https://www.brainstimmapping.science/)
Starting from patient-specific structural and diffusion MRI images we will obtain:  

1. wholebrain streamlines reconstruction based on diffusion weighted imaging and probabilistic tractography (using ['MRtrix3](https://github.com/MRtrix3/mrtrix3))
2. Lead reconstruction and Volume of Activated Tissue (VTA) estimation (using ['LeadDBS](https://github.com/netstim/leaddbs))
3. VAT to cortex structural connectivity
4. Functional connectivity based on Human Connectome Project resting state information
5. Correlation of connectivity with MDD clinical outcome

## WHAT IT NEEDS - MUST
the following data structure
path/pat

    - original_data

        - T1.nii.gz         

        - T2.mif

        - dwi_raw.mif

        - postop_tra.nii

External software needed includes : ANTs, FSL, Freesurfer, MRtrix
Moreover, we employed MATLAB and the packages LeadDBS, BrainNet Viewer and Nifti

## WHAT IT NEEDS - OPTIONAL
the following data structure
path/pat
    - DWI 

        - synb0

            - INPUTS

                -acqparam.txt 

            - OUTPUTS

        - eddy

            - index.txt    

            - acqparams.txt    

    - lead_recon

**When should I provide the DWI folder and its content?**
When you are aware of acquisition protocols different from the standard one described below.

**What is the standard synb0/acqparams.txt?**

Is a file with acquisition parameters needed to run Synb0-DISCO.
Synb0-Disco is the implementation of the paper [“Synthesized b0 for diffusion distortion correction”](https://pubmed.ncbi.nlm.nih.gov/31075422/) whose code is stored in the [docker container](https://hub.docker.com/r/hansencb/synb0).
It aims at having the same beneficial distortion correction as in TOPUP with only a) a raw distorted dwi image and b) an undistorted structural image T1, through a deep NN.
Basically, the network synthesizes the dwi b0 in the missing encoding direction, then performs FSL’s TOPUP (included). 
Synb0-Disco replaces the EPI  correction (see step 2.4 of the BATMAN tutorial)

In the first line, the first three columns represent the phase encoding direction for the distorted image. The fourth and last column refers to the readout time. Both information can be found through mrview. In particular from mrview, open the dwi_raw,mif image , then open Image/Properties/ and check the key value pairs. Refer to https://mrtrix.readthedocs.io/en/latest/concepts/pe_scheme.html to correctly interpret the found information.
The second line refers instead to the synthetized image.
_“Importantly, when setting up the acquisition parameters, the readout time (i.e., time between the center of the first echo and center of last echo) for the synthesized image is set to 0 (while the real b0 retains the correct readout time). This tells the algorithm that the synthesized b0 has an infinite bandwidth in the PE direction, with no distortions, thus fixing its geometry when estimating the susceptibility field.”_
Therefore, the second line should be identical to the first line but the fourth column should be set to 0.

**What is the standard eddy/index.txt?**
Applying the guidelines found here, https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#A--index and considering our acquisition protocol, in our case index.txt is a file containing with as many ones as there are directions (namely 123, see 4th dimensions of file using mrinfo).

**What is the standard eddy/acqparams.txt?**
Is a file with acquisition parameters needed to run eddy motion correction. 
In the first line, the first three columns represent the phase encoding direction. The fourth and last column refers to the readout time.
In the second line, the first three columns represent the reversed phase encoding direction (that is to say, first line with second element flipped). The fourth and last column refers to the readout time.

## HOW TO RUN
The entire pipeline, shown in picture is to be performed in different steps, so as to ensure visual inspections of some crucial intermediate points.
More detailed descriptions are provided for each step in the corresponding script.
NOTE: 
I stands for individual: the script is meant to work for each subject separately; 
G stands for group : the script works on the overall patient group;
O stands for once : you only need to perform the operation once.
Open a terminal where these scripts are stored and

**Diffusion (Pre)processing**
1. I. Run Preprocessing.sh
2. I. Run Preprocessing2EDDY.sh
3. I. Run PostEDDY.sh
4. I. Run ACT.sh
5. I. Run streamlineCreation.sh
6. G. Run group_based_tractography.sh

**DBS reconstruction**

7. I. Create the folder lead_recon and copy the necessary files to perform lead reconstruction through lead-DBS. Follow the naming convention carefully.

8. I. Run create_patient_instance.py

        DATA WRANGLING 
        1. I. Run Read_stimulation_parameters.py

        2. I. Copy the jupyter notebook Correcting VTAs and adapt it to the patient's specific error - Not provided for privacy reasons *

        3. I. Run VTA_ready4MATLAB.py

9. I. Run manualVTA.m

10. I. Run All_VTAs_to_diffusion.sh 

**Tractography** 

11. I. Run brodmann.sh 

12. I. Run plottingVideo.py 

13. I. Run PlotOutcomes.py

14. G. create_tables.py

15. I. Run ranked_structural_connectivity.py (include area/16 notebook) *

**Functional**

14. O. Getting_HCP.sh

15. O. Copy a T1 subject specific image to use as a template for regridding (we used the Cov_frfMRI_REST1_LR0001 of subject 100307)

16. O. Read fMRI.sh

17. O. CopyVoxelsEvolutions.sh

18. O. check_and_change.m

19. O. Run Lead2fMRI_transformations.sh

20. I. Run Lead2fMRI.sh

21. I. fingerprint_all_sessions.m

22. I. functional_profiles.py

22. I. creatingRmap.m

23. I. creating_permutations.m

24. I. reading_permutations.m

25. I. brodmann2functional.sh 

26. I. averageOptimalConnectivity.sh

27. I. significant_funkOutcomes_tables.py

27. I. gettingaverage.sh

28. G. best worst *
**Network**

28. I. anhedonia_network.sh

29. I. network_overlap.py