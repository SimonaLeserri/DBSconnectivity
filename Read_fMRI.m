
function Read_fMRI(varargin) 
   % Converts the HCP subject data as provided by the MIPlab and stored in
   % functional_HCP_folder (external drive) in a matrix N x T per session
   % where N is the number of voxels and T is the time points.
   % Results are still saved on the external drive 
   % to avoid undesired copying mistaked (that have occurred)
   
   p = inputParser;   
   pathExists = @(x) exist(x,'dir');
   addRequired(p,'functional_HCP_folder', pathExists);
   parse(p,varargin{:});
   read_resting(p.Results.functional_HCP_folder); 
   p.Results
end

%% DOUBLE CHECKS
% all_volumes = load('/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data/functional_HCP/201111/rfMRI_REST1_LR/voxel_by_frame.mat');
% volume1=niftiread('/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data/functional_HCP/201111/rfMRI_REST1_LR/fMRIvols_GLMyes/Cov_frfMRI_REST1_LR0001.nii');
% volume2=niftiread('/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data/functional_HCP/201111/rfMRI_REST1_LR/fMRIvols_GLMyes/Cov_frfMRI_REST1_LR0002.nii');
% volume425=niftiread('/home/brainstimmaps/20xx_Projects/2023_Deep/03_Data/functional_HCP/201111/rfMRI_REST1_LR/fMRIvols_GLMyes/Cov_frfMRI_REST1_LR0425.nii');
% 
% isequal(all_volumes.all_volumes(:,2),reshape(volume2,[],1))
% isequal(all_volumes.all_volumes(:,1),reshape(volume1,[],1))
% isequal(all_volumes.all_volumes(:,425),reshape(volume425,[],1))
%%
function voxeltimecourse(path)
save_folder = extractBefore(path,'fMRIvols');
% collapse all the volums relative to the session and stored in path
% to a 4D nifti called all_session.nii saved in save_folder
MINEcollapse_nii_scan('Cov_frfMRI_REST*.nii',strcat(save_folder,'all_session'), path); %modified source :)
all_volumes = niftiread(strcat(save_folder,'all_session.nii'));
all_volumes = reshape(all_volumes,[],size(all_volumes,4));
save(fullfile( save_folder,'voxel_by_frame.mat'),'all_volumes','-v7.3');
% avoid memory errors
clear all_volumes;
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
    % Print folder names to command window.
   
end

function read_resting(data_path)
% Get all the subjects dirs
subjects = only_dirs(data_path);
for k = 1 : length(subjects)
    fprintf('now analysing %s\n',subjects(k).name);
    % Get all the resting-state sessions per subject
    sessions =  only_dirs(strcat(data_path,subjects(k).name));
    for s = 1 : length(sessions)
        fprintf('\t now analysing %s\n',sessions(s).name);
        folder_path = strcat(data_path,subjects(k).name,'/',sessions(s).name,'/fMRIvols_GLMyes/');
        tic
        % Transforms the sessions volumes to a N x T matrix
        voxeltimecourse(folder_path);
        elapsedTime = toc;
        fprintf('Time needed %f',elapsedTime);
    end
    
end

end