
function creatingRmap(varargin) %path, pat, assessment
  
    p = inputParser;

    pathExists = @(x) exist(x,'dir');
    addRequired(p,'assessmentFolder', pathExists);
    addRequired(p,'save_R_path',pathExists);
    addRequired(p,'z_folder',pathExists);
    parse(p,varargin{:});

    mkdir(p.Results.save_R_path);

    % for each fingerprint in the z( time ordered) folder
    dir_content = dir(p.Results.z_folder);
    fingerprints = dir_content(~ismember({dir_content.name},{'.','..'}));
  
    voxel_connectivity = [];
    % load the fingerprint of the functional connectivity for each VTA
    for f=1:length(fingerprints)
          fingerprint = load_nii(fullfile(p.Results.z_folder, fingerprints(f).name));
          voxel_connectivity = [voxel_connectivity; reshape(fingerprint.img,1,[])];
    end
    % voxel connectivity now is a matrix n_session x n_fMRI voxels
    
    % read and store the outcome
    all_percentages_impro = load(fullfile(p.Results.assessmentFolder,'perc_impro.mat'));
    outcome_matrix = [];
    fn = fieldnames(all_percentages_impro);
    for session=1:numel(fn)
        outcome_matrix = [ outcome_matrix; struct2cell(all_percentages_impro.(fn{session}))'];
    end
    % outcome_matrix is now a matrix
    % n_sessions x n_of_MDD_assessments_measures
    assessment_names = fieldnames(all_percentages_impro.(fn{1}));
    % create a table to keep the information of the varibale name
    outcome_table = cell2table(outcome_matrix);
    outcome_table.Properties.VariableNames = assessment_names;
    
    % for each MDD assessment variable
    for var_id = 1:length(assessment_names)
    
        Rmap = [];
        Pmap = [];
        variable = assessment_names(var_id);   

        for v=1:size(voxel_connectivity,2)
            [r_square,p_square] = corrcoef(voxel_connectivity(:,v), outcome_table.(variable{:}));
            r = r_square(1,2);
            p = p_square(1,2);
            Rmap = [Rmap, r];
            Pmap = [Pmap, p];
        end
        
        % get the nifti Rmap
        % what's the correlation of each voxel to the outcome?
        add_header_and_save3D(Rmap, fingerprint, fullfile(p.Results.save_R_path, strcat('/',variable{:}, '_', 'optimal_connectivity_profile.nii')));
        
        Rmap_3d = reshape(Rmap, size(fingerprint.img));

        % get the nifti rmap
        add_header_and_save3D(Pmap, fingerprint, fullfile(p.Results.save_R_path,strcat('/',variable{:}, '_', 'Pmap.nii')));

    end
   
end

