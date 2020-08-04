

% This function gets data from refractiveindex.info
% if input wavelength is empty, then the function return the original data.

% example: [n_complex_intrp, eps_complex_intrp] = get_data_refractiveindex_info('main\Al2O3\Querry-o', 17.86, 'um')

function [n_complex_intrp, eps_complex_intrp, lambda_um_input] = get_data_refractiveindex_info(Part_from_MaterialName, wavelength_or_freq, unit_of_input)

mfilepath = mfilename('fullpath'); ind_sep = find(mfilepath == filesep);
mfile_folder = mfilepath(1:ind_sep(end)); cd(mfile_folder);

load(['rii-database-2019-02-11', filesep, 'All_data_with_interpolation_processed.mat']);
all_MaterialName = {All_data.data(:).MaterialName};
ss = size(All_data.data); N_materials = ss(2);
lambda_um_interp = [All_data.ReadMe.lambda_um_univ_interp];

lambda_um = [All_data.ReadMe.lambda_um_univ_interp];

n_data_matches = 0;
for nn = 1 : ss(2)
	if contains(all_MaterialName{nn}, Part_from_MaterialName)
		if ~isempty(wavelength_or_freq)
			n_complex = [All_data.data(nn).n_complex_interpolated];
			eps_complex = [All_data.data(nn).epsilon_complex_interpolated];
			
			lambda_um_input = z_convert_wavelength_freq(wavelength_or_freq, unit_of_input, 'um');
			
			n_complex_intrp = interp1(lambda_um, n_complex, lambda_um_input);
			eps_complex_intrp = interp1(lambda_um, eps_complex, lambda_um_input);
		else
			n_complex_intrp = [All_data.data(nn).n_complex];
			eps_complex_intrp = [All_data.data(nn).epsilon_complex];
			lambda_um_input = [All_data.data(nn).lambda_um];
		end
	end
end
end
