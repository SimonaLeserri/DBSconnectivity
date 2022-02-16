function reading_permutations(varargin)

    p = inputParser;
   
    pathExists = @(x) exist(x,'dir');
    positiveInteger = @(x) (mod(x,1)==0 & x >0 );
    positiveFloatLessOne = @(x) (x>0 & x<1 & isfloat(x));
    addRequired(p,'n_iterations', positiveInteger);
    addRequired(p, 'alpha_val', positiveFloatLessOne);
    addRequired(p,'empirical_folder', pathExists);
    addRequired(p,'permutation_folder', pathExists);
    parse(p,varargin{:});
    
    alpha = p.Results.alpha_val;
    N = p.Results.n_iterations+1;
    index_threshold = floor(alpha*N)+1;
    measures = only_dirs(p.Results.permutation_folder);
    
    for k = 1 : length(measures)
        extremes = load(fullfile(p.Results.permutation_folder,measures(k).name,strcat('summaries_',measures(k).name,'.mat' )));
        R_max = extremes.max;
        R_min = extremes.min; 
        
        sorted_R_max = sort(R_max,'descend');
        threshold_max = sorted_R_max(index_threshold); % you consider significant voxel higher than this threshold
        sorted_R_min = sort(R_min,'ascend');
        threshold_min = sorted_R_min(index_threshold); %you consider significant voxels smaller than this threshold
        
        empirical_R = fullfile(p.Results.empirical_folder, strcat(measures(k).name,'_optimal_connectivity_profile.nii'));
        create_significant_image_bilateral(empirical_R,measures(k).name,threshold_max,threshold_min,p.Results.empirical_folder)
%         create_significant_image(empirical_R,measures(k).name, 'RMAX', threshold_max, p.Results.empirical_folder)
%         create_significant_image(empirical_R,measures(k).name, 'RMIN', threshold_min, p.Results.empirical_folder)

        
    end
    
    
end

function create_significant_image_bilateral(full_path_empirical_R_image, measure,threshold_max,threshold_min, save_folder)
    empiricalR = load_nii(full_path_empirical_R_image);
    empiricalmatrix = empiricalR.img;
    
    nonsignificant = find(empiricalmatrix>threshold_min & empiricalmatrix<threshold_max);
    
    empirical_linear = reshape(empiricalmatrix,[],1);
    copy = empirical_linear;
    copy(nonsignificant) = NaN ;
    filename = strcat('significant_Voxels_for_measure_',measure,'.nii');
    add_header_and_save3D(copy, empiricalR,fullfile(save_folder, filename));
    
end

function create_significant_image(full_path_empirical_R_image, measure, mode, threshold, save_folder)
    empiricalR = load_nii(full_path_empirical_R_image);
    empiricalmatrix = empiricalR.img;
    if mode == 'RMAX'
        nonsignificant = find(empiricalmatrix<threshold);
    else
        nonsignificant = find(empiricalmatrix>threshold);
    end
    
    empirical_linear = reshape(empiricalmatrix,[],1);
    copy = empirical_linear;
    copy(nonsignificant) = NaN ;
    filename = strcat('significant_',mode, '_Voxels_for_measure_',measure,'.nii');
    add_header_and_save3D(copy, empiricalR,fullfile(save_folder, filename));
    
end

function subFolders = only_dirs(path)
    % Get a list of all files and folders in this folder.
    files = dir(path);
    % Get a logical vector that tells which is a directory.
    dirFlags = [files.isdir];
    % Extract only those that are directories.
    subFolders = files(dirFlags);
    % Remove . and .. hidden subfolders
    subFolders = subFolders(~ismember({subFolders.name},{'.','..'}));
    
   
end