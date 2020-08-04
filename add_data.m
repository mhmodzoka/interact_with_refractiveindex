function add_data
mfilepath = mfilename('fullpath'); ind_sep = find(mfilepath == filesep);
mfile_folder = mfilepath(1:ind_sep(end)); cd(mfile_folder);

% Add data to the existing dataset
tic
original_data_file_to_load = ['rii-database-2019-02-11', filesep, 'All_data_with_interpolation_04_12_2018'];
load(original_data_file_to_load);
all_n_complex = [All_data.data(:).n_complex_interpolated];
all_eps_complex = [All_data.data(:).epsilon_complex_interpolated];
lambda_um = [All_data.ReadMe.lambda_um_univ_interp];
c = 299792458;


%% add reflectance_SemiInfiniteBulk
reshape_factor = reshape(1, [1 1 1]);
w = c ./ (lambda_um*1e-6) * 2*pi;

k_v = w /c .* reshape_factor;				% wavevector of electromagnetic wave in vacuum
k_z_vacuum = k_v;
eps_vacuum = ones(size(lambda_um));

ss = size(All_data.data);
k_z_here(:,1,:) = k_z_vacuum;
for kk = 1 : ss(2)
	k = all_n_complex(:,kk) .* k_v .* reshape_factor;			% array of wave vectors corresponding to media in each layer
	k_z_material = k; % assuming normal incidence

	k_z_here(:,2,:) = k_z_material;
	[~, ~, ~, ~, r_TE, r_TM, t_TE, t_TM] = Z_refl_refr_vectorized_freq_angle (k_z_here, [eps_vacuum, all_eps_complex(:,kk)], [], 0);
	R_normal = abs(r_TE.^2);
	
	All_data.data(kk).R_normal = R_normal;
end

%% add data to chunked spectrum
spectrum_chunk_points = unique([0.4:0.1:1, 2:10, 12:20, 20:10:100]);

save([original_data_file_to_load, '_processed'], 'All_data')

toc


end

function mean_value = find_mean_value_in_wl_range(target_value, lambda_um, wl_range)
ind_inrange = find( lambda_um >= wl_range(1) & ...
					lambda_um <= wl_range(2) );

k_inrange = target_value(ind_inrange,:);
mean_value = mean(k_inrange, 1);

inn = find(mean_value==0); mean_value(inn) = nan;
end