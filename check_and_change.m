% double check class 

function check_and_change(varargin) 
   % convert to double the N x T matrices created in Read_fMRI and copied
   % locally
  
   p = inputParser;
   
   pathExists = @(x) exist(x,'dir');
   addRequired(p,'local_functional_HCP_folder', pathExists);
   parse(p,varargin{:});
   
   check_resting(p.Results.local_functional_HCP_folder); %('/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/functional_HCP')
end


function checking(path)
    if isfile(fullfile( path,'voxel_by_frame_double.mat'))
        fprintf('already converted')
    else
        full_path = strcat(path,'voxel_by_frame.mat');
        matrix = load(full_path);
        if isa(matrix.all_volumes,'single')
            double_matrix = double(matrix.all_volumes);
            save(fullfile( path,'voxel_by_frame_double.mat'),'double_matrix','-v7.3');
            clear double_matrix
        end
        clear matrix
    end
   
    
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

function check_resting(data_path)
% reads all the rs-fMRI files, for each session and subject present in data_path
subjects = only_dirs(data_path);
for k = 1 : length(subjects)
    
    fprintf('now analysing subject %s\n',subjects(k).name);
    sessions =  only_dirs(strcat(data_path,'/',subjects(k).name));
    for s = 1 : length(sessions)
        fprintf('\t now analysing session %s \t',sessions(s).name);
        folder_path = strcat(data_path,'/',subjects(k).name,'/',sessions(s).name,'/');
        tic
        checking(folder_path);
        elapsedTime = toc;
        fprintf('Time needed %f \n',elapsedTime);
    end
    
    
end
end