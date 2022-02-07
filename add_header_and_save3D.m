function add_header_and_save3D(flatten_voxels, reference_nii,save_path)

    output_3D = reshape(flatten_voxels, size(reference_nii.img));

    output_3D = make_nii(output_3D);
    output_headers = output_3D;
    output_headers.hdr.dime.pixdim = reference_nii.hdr.dime.pixdim;
    output_headers.hdr.dime.scl_slope = reference_nii.hdr.dime.scl_slope;
    output_headers.hdr.dime.xyzt_units = reference_nii.hdr.dime.xyzt_units;
    output_headers.hdr.hist.qoffset_x = reference_nii.hdr.hist.qoffset_x;
    output_headers.hdr.hist.qoffset_y = reference_nii.hdr.hist.qoffset_y;
    output_headers.hdr.hist.qoffset_z = reference_nii.hdr.hist.qoffset_z;
    output_headers.hdr.hist.srow_x = reference_nii.hdr.hist.srow_x;
    output_headers.hdr.hist.srow_y = reference_nii.hdr.hist.srow_y;
    output_headers.hdr.hist.srow_z = reference_nii.hdr.hist.srow_z;
    output_headers.hdr.hist.magic =  reference_nii.hdr.hist.magic;
    output_headers.hdr.hist.originator = reference_nii.hdr.hist.originator;
   
    if iscell(save_path)
        save_nii(output_headers,save_path{:});
    else
        save_nii(output_headers,save_path);

end