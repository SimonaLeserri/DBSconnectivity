function creating_permutations(varargin)

    % performs permutation test to find voxels whose correlation to a good 
    % outcome is statistically significant    
    p = inputParser;
   
    pathExists = @(x) exist(x,'dir');
    positiveInteger = @(x) (mod(x,1)==0 & x >0 );
    addRequired(p,'assessmentFolder', pathExists);
    addRequired(p,'save_R_path', pathExists);
    addRequired(p,'z_folder', pathExists);
    addRequired(p,'n_iterations', positiveInteger);
    parse(p,varargin{:});
    
    mkdir(p.Results.save_R_path,'permuted');
    all_percentages_impro = load(fullfile(p.Results.assessmentFolder,'perc_impro.mat'));
    
    %% VTA connectivity matrix sessions x voxels
    % for each fingerprint in the z(ordered) folder
    dir_content = dir(p.Results.z_folder);
    fingerprints = dir_content(~ismember({dir_content.name},{'.','..'}));

    voxel_connectivity = [];
    for f=1:length(fingerprints)
          fingerprint = load_nii(fullfile(p.Results.z_folder, fingerprints(f).name));
          voxel_connectivity = [voxel_connectivity; reshape(fingerprint.img,1,[])];
    end
    % voxel_connectivity has shape n_sessions x n_functional voxels
    
    %% outcomes
    outcome_matrix = [];
    fn = fieldnames(all_percentages_impro);
    for session=1:numel(fn)
        outcome_matrix = [ outcome_matrix; struct2cell(all_percentages_impro.(fn{session}))'];
    end
    assessment_names = fieldnames(all_percentages_impro.(fn{1}));

    outcome_table = cell2table(outcome_matrix);
    outcome_table.Properties.VariableNames = assessment_names;
    
    %% create permutations
    for i=1:length(assessment_names)
        
        name = assessment_names(i);
        if not(convertCharsToStrings(name{:}) == "BARS")
            mkdir (strcat(p.Results.save_R_path,'/permuted'),name{:});
            original_labels = outcome_table.(name{:});
            [R_max,R_min] = create_permutations(voxel_connectivity,p.Results.n_iterations,original_labels,strcat(p.Results.save_R_path,'/permuted/',name),name,fingerprint);
            struct_to_save.max = R_max;
            struct_to_save.min = R_min;
            where = fullfile(p.Results.save_R_path,'permuted',name{:}, strcat('summaries_',name, '.mat'));
            save(where{:}, '-struct','struct_to_save');
        end
    end  
    
end

function [R_max,R_min] = create_permutations(voxel_matrix,n_iterations,original_labels,save_R_path,measure_name,reference_image)
    R_max = [];
    R_min = [];
    
    already_seen = [];
    counter = 1;
    while counter < n_iterations +1
        permuted_labels = original_labels(randperm(length(original_labels)));
        if not(ismember(permuted_labels,already_seen)) | isempty(find(eq(sum(bsxfun(@eq,already_seen,permuted_labels),1),size(already_seen,1))))
            if not(eq(permuted_labels, original_labels))
                already_seen = [already_seen, permuted_labels];

                [r_max,r_min] = create_R(voxel_matrix, permuted_labels,save_R_path,measure_name,reference_image,counter);
                counter = counter +1;
                R_max = [R_max,r_max];
                R_min = [R_min, r_min];
            end
        end
    end
           
   
end

function [r_max,r_min] = create_R(voxel_connectivity_matrix, outcome_labels,save_R_path,measure_name,reference_image,iteration_number) % header id fingerpint.hdr
% voxel_connectivity_matrix has size(n_sessions,n_voxels=91*109*91)
% outcome_labels has size n_sessions
    Rmap = [];
    Pmap = [];
    for v=1:size(voxel_connectivity_matrix,2)
        [r_square,p_square] = corrcoef(voxel_connectivity_matrix(:,v), outcome_labels);
        r = r_square(1,2);
        p = p_square(1,2);
        Rmap = [Rmap, r];
        Pmap = [Pmap, p];
    end
    r_max = max(Rmap);
    r_min = min(Rmap);
    
    add_header_and_save3D(Rmap, reference_image,fullfile(save_R_path, strcat(num2str(iteration_number), '_',measure_name, '_', 'optimal_connectivity_profile.nii')));
    add_header_and_save3D(Pmap, reference_image,fullfile(save_R_path, strcat(num2str(iteration_number), '_',measure_name, '_', 'Pmap.nii')));

end


