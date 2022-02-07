
function manualVTA(varargin)
   
    pathExists = @(x) exist(x,'dir');
    addRequired(p,'patientfolder', pathExists);
    parse(p,varargin{:});

    leadFolder = fullfile(p.results.patientFolder,'lead_recon/')
    load(fullfile(leadFolder,'all_VTAs.mat'))

    fn = fieldnames(all_VTAs);
    for k=1:numel(fn)
        single_VTA = all_VTAs.(fn{k});
        % converting lists into cells
        single_VTA.amplitude={single_VTA.amplitude(1,:), single_VTA.amplitude(2,:)};
        single_VTA.activecontacts={single_VTA.activecontacts(1,:), single_VTA.activecontacts(2,:)};
        % Get patient options
        options = ea_getptopts(leadFolder);

        % Save original native flag
        options.orignative = options.native;

        % Fix missing atlasset in options
        options.atlasset = 'DISTAL Nano (Ewert 2017)';

        ea_genvat_horn([], single_VTA, 1, options, single_VTA.label);
        fprintf('RIGHT DONE !!!!!!!!!!!!!!!!!!')
        ea_genvat_horn([], single_VTA, 2, options, single_VTA.label);
        fprintf('LEFT DONE !!!!!!!!!!!!!!!!!!!!')

        movefile(fullfile(leadFolder, 'stimulations/MNI_ICBM_2009b_NLIN_ASYM/',single_VTA.label,'/'),  fullfile(patientFolder,'VTA_tracts/'))
    end

   
end
