%% For all patient-specific VTAs

function fingerprint_all_sessions(varargin) %path, pat, assessment
   % Reads and concatenates each HCP subjects session
   % computes the correlation between the mean activity of voxels included
   % in the each VTA and all the non-VTA voxels
   % averages and z transforms the results to create a fingerprint for each
   % of the subject vtas
   % add the z_fingerprint obtained in the relative VTA folder as well as
   % in the time_ordered_z folder for further analysis and visualizations
   % and creates a 4D fingerprint evolution
   
   % BEWARE Takes some times and better designs lead to memory errors
   
   p = inputParser;
   
   pathExists = @(x) exist(x,'dir');
   fileExists = @(x) isfile(x);
   addRequired(p,'vtas_path', pathExists); % subject specific VTA_tracts folder
   addRequired(p,'HCP_path',pathExists); %local
   addRequired(p, 'order', fileExists); % path till plot/sorted code list created in 
   parse(p,varargin{:});
   
   vta = only_dirs(p.Results.vtas_path);

   for f = 1 : length(vta)
       % vta folder end with a number
        [numb, logic_val] = str2num(vta(f).name(end-1:end));
        if logic_val == 1        
                vta_subfolder_path = strcat(p.Results.vtas_path, '/',vta(f).name,'/');
                if exist(fullfile(vta_subfolder_path, 'z_fingerprint.nii')) == 0
                    create_vta_fingerprint(vta_subfolder_path,p.Results.HCP_path);
                else
                    sprintf('already done')
                end
        end
   end
   
   plot_path = fullfile(p.Results.vtas_path,'plot');
   mkdir(plot_path,'time_ordered_z');


    for i = 1:length(p.Results.order)    
        if i < 10
            name = strcat('0',num2str(i));
        else
            name = num2str(i);
        end
        if order(i) < 10
            to_add = strcat('0',num2str(order(i)));
        else
            to_add = num2str(order(i));
        end
        VTA_label = strcat("VTA_",to_add);
        copyfile(fullfile(p.Results.vtas_path, VTA_label,'z_fingerprint.nii'),fullfile(plot_path,'time_ordered_z',strcat('VTA_',name,'.nii')))
    end

    MINEcollapse_nii_scan('VTA*.nii', fullfile(plot_path,'fingerprint_evolution'),fullfile(plot_path,'time_ordered_z'));
    
   
end



function create_vta_fingerprint(vta_subfolder_path,HCP_path)
    % Get the voxels included in the bilateral VTA
    left = load_nii(strcat(vta_subfolder_path,'vat_left_FSL_regridded.nii'));
    voxels_l = reshape(double(left.img),[],1);
    clear left
    on_indx_l = find(voxels_l);

    right = load_nii(strcat(vta_subfolder_path,'vat_right_FSL_regridded.nii'));
    voxels_r = reshape(double(right.img),[],1);
    on_indx_r = find(voxels_r);

    on_ind = [on_indx_l;on_indx_r];
    
    % creates a matrix number_HCP_subjects x number_non_VTA_voxels
    pearson_correlations = read_HCPsubjects(on_ind, HCP_path);
    
    % creates a matrix number_HCP_subjects x number_of_fMRI_voxels 
    % the value of the VTA voxels is set to NaN
    rebuilt = pearson_correlations;
    insert = @(a, x, n)cat(2,  x(:,1:n), a, x(:, n+1:end)); % element to add, what to add to, index
    for idx=1:length(on_ind)
        vta_ind = on_ind(idx);
        rebuilt = insert(NaN(size(pearson_correlations,1),1),rebuilt,vta_ind);
    end

    %  z corr and then average --> different than average then z corr 
    % first average is what other people do - and righlty so
        
    avg_subjects = mean(rebuilt,1); % average across subjects 1 x number_of_fMRI_voxels
    z_correlations = atanh(avg_subjects);
    
    add_header_and_save3D(z_correlations, right,strcat(vta_subfolder_path, 'z_fingerprint.nii'));
    fprintf('done with %s', vta_subfolder_path);

end

function rho = one_sub_corr(vta_indexes, voxel_by_frame)
    % given the N x 4T voxel_by_frame of a specific HCp subjects
    % returns a vector 1,n_voxel_not_in_vta with the correlation between
    % that voxel and the mean activity of voxels inside VTA
    
    vta_voxels = voxel_by_frame(vta_indexes,:);
%     figure;
%     hold on
%     for i= 1:size(vta_voxels,1)
%         plot(vta_voxels(i, :));
%     end
%     plot(mean(vta_voxels,1), 'r-.');
    
    not_vta_indx = setdiff(1:size(voxel_by_frame,1),vta_indexes);
    % nan input would result in nan correlations (pathologic)
    % but also contant values ( as those found at the border of the image)
    % result in NaN (physiologic)
    are_there_nan_mean = isnan(mean(vta_voxels,1)');
    %fprintf('%d nan in mean? \n',sum(are_there_nan_mean));
    are_there_nan_other = isnan(voxel_by_frame(not_vta_indx,:)');
    %fprintf('%d nan in mean? \n',sum(are_there_nan_other));
    if or(are_there_nan_mean == 1, are_there_nan_other == 1)
        fprintf('there are nan in the input, better double check before computing the correlation');
        return
    end
    rho = corr(mean(double(vta_voxels),1)',voxel_by_frame(double(not_vta_indx),:)');
    
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

function VTAfingerprint = read_HCPsubjects(vta_indexes, data_path)
% reads all the rs-fMRI files, for each session and subject present in data_path
% creates the correlation to the VTA-voxels
subjects = only_dirs(data_path);
VTAfingerprint = [];

for k = 1 : length(subjects)
    % reads only the folders relative to HCp subjects, each identified by a
    % numeric code
    [numb, logic_val] = str2num(subjects(k).name);
    if logic_val == 0
        continue
    end
    fprintf('now analysing subject %s\n',subjects(k).name);    
    sessions =  only_dirs(strcat(data_path,subjects(k).name));
    
    concat_session = [];
    for s = 1 : length(sessions)
        %fprintf('\t now analysing session %s \t',sessions(s).name);
         % Loads the not double matrix otherwise we have memory problems
        file_path = strcat(data_path,subjects(k).name,'/',sessions(s).name,'/voxel_by_frame.mat');
        session = load(file_path);
        voxel_by_frame = session.all_volumes;
        clear session
        % concatenating sessions to obtain N x 4T frame
        concat_session = [concat_session, voxel_by_frame];
        clear voxel_by_frame
       
        %fprintf('the concatenated session has dimensions %s', size(concat_session));

    end
    
    rho = one_sub_corr(vta_indexes,concat_session);
    % concatenate info of all HCP subjects
    VTAfingerprint = [VTAfingerprint ; rho];
        
    
end

end