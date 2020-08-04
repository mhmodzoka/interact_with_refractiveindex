% material search scenarios

% inputs: -------
% search scenaroi: a string or a number that identify the scenario
% search parameters: a cell array of the different parameters required for the search

function optical_material_search(search_scenario, search_parameters)
mfilepath = mfilename('fullpath'); ind_sep = find(mfilepath == filesep);
mfile_folder = mfilepath(1:ind_sep(end)); cd(mfile_folder);

%% inputs
original_data_file_to_load = ['rii-database-2019-02-11', filesep, 'All_data_with_interpolation_04_12_2018_processed'];
plotting = 0;

%% calculation start


load(original_data_file_to_load);

c = 299792458; % speed of light [m/s]
all_n_complex = [All_data.data(:).n_complex_interpolated];
lambda_um = [All_data.ReadMe.lambda_um_univ_interp];
all_MaterialName = {All_data.data(:).MaterialName};
ss = size(All_data.data); N_materials = ss(2);

search_scenario_ = {
	'sort_n_in_given_wavelength'
	'sort_reflectance_SemiInfiniteBulk_in_given_wavelength'
	
	'sort_k_in_given_wavelength'
	'sort_SkinDepth_in_given_wavelength'
	};
% search_scenario = 'sort_n_in_given_wavelength';
% search_scenario = 'sort_k_in_given_wavelength';

wl_range = [0.4,0.7,2,5,10.20];


for kkk = 1 : length(search_scenario_)
	search_scenario = search_scenario_{kkk};
	switch search_scenario
		case 'sort_n_in_given_wavelength'
			%% sort_n_in_given_wavelength
			% include the material if its spectrum data partially fall within the range
			
			target_value = real(all_n_complex); % This is the value we are calculating its mean
			target_value_name = 'n';
			
			All_data = calc_storing_sorting_plotting_mean_value(All_data, target_value, target_value_name, lambda_um, wl_range, plotting);
			
		case 'sort_k_in_given_wavelength'
			%% sort_k_in_given_wavelength
			% include the material if its spectrum data partially fall within the range
			
			target_value  = imag(all_n_complex); % This is the value we are calculating its mean
			target_value_name = 'k';
			
			All_data = calc_storing_sorting_plotting_mean_value(All_data, target_value, target_value_name, lambda_um, wl_range, plotting);
			
		case 'sort_SkinDepth_in_given_wavelength'
			%% sort_skin_depth_in_given_wavelength
			k_v = 2*pi ./ (lambda_um*1e-6);
			
			target_value = 1 ./ (k_v .* imag(all_n_complex)); % This is the value we are calculating its mean
			target_value_name = 'SkinDepth';
			
			All_data = calc_storing_sorting_plotting_mean_value(All_data, target_value, target_value_name, lambda_um, wl_range, plotting);
			
		case 'sort_reflectance_SemiInfiniteBulk_in_given_wavelength'
			%% sort_reflectance_SemiInfiniteBulk_in_given_wavelength
			% 		all_R = [All_data.data(:).R_normal];
			
			R_normal = [All_data.data(:).R_normal];
			
			target_value  = R_normal; % This is the value we are calculating its mean
			target_value_name = 'R_normal';
			
			All_data = calc_storing_sorting_plotting_mean_value(All_data, target_value, target_value_name, lambda_um, wl_range, plotting);
			
		case 'sort_transmittance_ThinFilm_in_given_wavelength_given_thickness'
			%% sort_transmittance_ThinFilm_in_given_wavelength_given_thickness
			
		case 'sort_SelectiveEmission_SemiInfiniteBulk_around_given_wavelength_given_temp'
			%% sort_SelectiveEmission_SemiInfiniteBulk_around_given_wavelength_given_temp
			% calculate emissivity -> find the emitted power above and below wavelength -> calculate ratio
	end
end

% save as Matlab file
save([original_data_file_to_load, '_averaged'], 'All_data')

% saveas excel file
All_data_simplified = All_data.data;
All_data_simplified = rmfield(All_data_simplified, ...
	{'lambda_um', 'n_complex', 'epsilon_complex', 'n_complex_interpolated', 'epsilon_complex_interpolated', 'R_normal'});

T = struct2table(All_data_simplified);
writetable(T, [original_data_file_to_load, '_averaged.csv'])

end



function mean_value = find_mean_value_in_wl_range(target_value, lambda_um, wl_range)
ind_inrange = find( lambda_um >= wl_range(1) & ...
	lambda_um <= wl_range(2) );

k_inrange = target_value(ind_inrange,:);
mean_value = mean(k_inrange, 1);

inn = find(mean_value==0); mean_value(inn) = nan;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%
function All_data = calc_storing_sorting_plotting_mean_value(All_data, target_value, target_value_name, lambda_um, wl_range_array, plotting)
% [~,N_materials] = size(All_data.data);
N_materials = length(All_data.data);

for n_rng = 1 : (length(wl_range_array)-1)
	wl_range = [wl_range_array(n_rng), wl_range_array(n_rng+1)];
	
	target_value_mean_name = [target_value_name, '_mean_', num2str(floor(wl_range(1)*1000)), '_', num2str(floor(wl_range(2)*1000))];
	target_value_mean = find_mean_value_in_wl_range(target_value, lambda_um, wl_range);
	
	for mm = 1 : N_materials
% 		eval(['All_data.data(mm).', target_value_mean_name,' = target_value_mean(mm); '])
		All_data.data(mm).(target_value_mean_name) = target_value_mean(mm);
	end

	
	if plotting  == 1
		% sorting the data
		T = struct2table(All_data.data);
		T = sortrows(T, target_value_mean_name);
		All_data.data = table2struct(T);
		
		all_MaterialName_sorted = {All_data.data(:).MaterialName};
		eval(['target_value_mean_sorted = [All_data.data(:).',target_value_mean_name,'];']);
		
		% exclude zero and NaN
		ind_Zeros = find(target_value_mean_sorted == 0);
		ind_NaN = find(isnan(target_value_mean_sorted) == 1);
		ind_inf = find(isinf(target_value_mean_sorted) == 1);
		
		ind_all = 1:N_materials;
		ind_include = setdiff(ind_all, unique([ind_Zeros, ind_NaN, ind_inf]));
		
		% plotting
		
		all_MaterialName_sorted_incl = all_MaterialName_sorted(ind_include);
		target_value_mean_sorted_incl = target_value_mean_sorted(ind_include);
		
		figure, barh(target_value_mean_sorted_incl)
		set(gca,'YTick',[1:numel(target_value_mean_sorted_incl)], 'YTickLabel',all_MaterialName_sorted_incl, 'YTickLabelRotation', 0,...
			'YLim', [1,numel(target_value_mean_sorted_incl)], 'XScale','log');
		
		xlabel(['average ',target_value_name,' in the wavelength range ',num2str(wl_range(1)), ' - ',num2str(wl_range(2)) , ' \mum'])
	end
end
end