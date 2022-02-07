%% build average image
function Rebuild_Average_image(varargin)
    % given a txt file with the average functional information for BA
    % builds a .nii file by replacing each voxel belonging to a BA area with the average value in that area. 
    p = inputParser;
   
    pathExists = @(x) exist(x,'dir');
    fileExists = @(x) isfile(x);
    addRequired(p,'path_average_vals', fileExists); % path to the txt file with the average functional information per Brodmann area
    addRequired(p,'path_bilateral_BAs_folder',pathExists); % where the 47 Brodmann areas are stored
    parse(p,varargin{:});
   
    

    table = readtable(p.Results.path_average_vals,'Format','%d %s %f');
    for row=1:size(table,1)
        label = table(row,:).label{:};
        value = table(row,:).average_value;
        parcellation_nii = load_nii(fullfile(p.Results.path_bilateral_BAs_folder, strcat(label,'.nii')));
        flatten_parc = reshape(parcellation_nii.img, 1,[]);
        this_area_indexes = find(not(flatten_parc == 0));
        if row == 1
            output = NaN(size(flatten_parc));
        end
        output(this_area_indexes) = value;       

    end

    add_header_and_save3D(output, parcellation_nii, strcat(regexprep(p.Results.path_average_vals, '\.[^\.]*$', ''),'.nii'));
end
    
    
