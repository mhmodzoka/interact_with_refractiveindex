% this file read the data from the downloaded file from refractiveindex.info, and store the data in a structure for later use (for example, material search).

function [epsilon_complex_interpolated, n_complex_interpolated] = load_optical_properties(materialfile_full_path, input_wavelength_freq, input_unit, save_data_to_file)
if nargin < 1
	materialfile_full_path = '*';
end

if nargin < 2
	% create a universal wavelength (this is based on my experience)
	lambda_um_univ_interp = unique([...
		linspace(8.266e-8, 0.001, 100), ...
		linspace(0.001, 0.228, 200), ...
		linspace(0.228, 51.68, 10000), ...
		linspace(51.68, 2.85e5, 100)]);
	lambda_um_univ_interp = lambda_um_univ_interp';
else
	if nargin < 3
		lambda_um_univ_interp = input_wavelength_freq;
	else
		lambda_um_univ_interp = z_convert_wavelength_freq(input_wavelength_freq, input_unit, 'um');
	end
	lambda_um_univ_interp = reshape(lambda_um_univ_interp, numel(lambda_um_univ_interp), 1);
end
	
if nargin < 4
	save_data_to_file = '1';
end


previous_directory = pwd;

% folder location that contains all the data
path_this_mfile = mfilename('fullpath');
inddd = find(path_this_mfile == filesep); path_directory_contain_this_mfile = path_this_mfile(1:inddd(end));

DataSource_main_folder = [path_directory_contain_this_mfile, filesep, 'rii-database-2019-02-11'];
DataSource = [DataSource_main_folder, filesep, 'database', filesep, 'data'];

% DataSource_main_folder = 'C:\Users\local-admin\Google Drive\elzouka_codes_library\MATLAB\optical_properties\from_RefractiveIndex.info\rii-database-2019-02-11';
% DataSource = [DataSource_main_folder,filesep,'database\data'];


% initializing
counter = 0; counter_for_errors = 0; All_data = [];
All_fieldnames = [];
n_complex_NaN = NaN*ones(size(lambda_um_univ_interp));
All_data.ReadMe.Notes = ['this data was generated from the data in the directory "' DataSource_main_folder , '", which was downloaded from RefractiveIndex.org'];
All_data.ReadMe.lambda_um_univ_interp = lambda_um_univ_interp;

% start looping over all files
cd(DataSource)
All_yml_files = subdir([materialfile_full_path, '.yml']); % All_yml_files = subdir('*.yml');
for j1 = 1 : length(All_yml_files)
% 	j1
	filepath = All_yml_files(j1).name;
	try
		x = YAML.read(filepath);
		for j2 = 1 : length(x)
			ThisMaterial = x(j2);
			All_fieldnames = unique([All_fieldnames ; fieldnames(ThisMaterial)]);
			DATA_here = ThisMaterial.DATA;
			n_complex_original = 0; n_complex_interpolated = 0; data_type_all = [];
			
			if     length(DATA_here) == 1
				DATA_here_here = ThisMaterial.DATA;
				data_type = DATA_here_here.type;
				data_type_all = [data_type];
				[lambda_um_original, n_complex_original_here, n_complex_interpolated_here] = getData_refindex;
				
				n_complex_original = n_complex_original_here;
				n_complex_interpolated = n_complex_interpolated + n_complex_interpolated_here;
				
				
			elseif length(DATA_here) == 2 % NOTE: some files has two tabulated values
				if iscell(ThisMaterial.DATA)
					type1 = ThisMaterial.DATA{1}.type;
					type2 = ThisMaterial.DATA{2}.type;
					
					DATA_here_here_1 = ThisMaterial.DATA{1};
					DATA_here_here_2 = ThisMaterial.DATA{2};
				else
					type1 = ThisMaterial.DATA(1).type;
					type2 = ThisMaterial.DATA(2).type;
					
					DATA_here_here_1 = ThisMaterial.DATA(1);
					DATA_here_here_2 = ThisMaterial.DATA(2);
				end
				
				data_type_all = [type1, ', ', type2];
				
				if strcmp(strtok(type1), 'tabulated') && strcmp(strtok(type2), 'tabulated')
					the_two_Datasets_kinds = 'both_tables';
				else
					the_two_Datasets_kinds = 'one_formula_one_table';
				end
				
				switch the_two_Datasets_kinds
					case 'both_tables'
						% get the complex refractive from the table
						DATA_here_here = DATA_here_here_1;
						data_type = type1;
						[lambda_um_original_tabl1, n_complex_original_here_tabl1, n_complex_interpolated_here_tabl1] = getData_refindex;
						
						DATA_here_here = DATA_here_here_2;
						data_type = type2;
						[lambda_um_original_tabl2, n_complex_original_here_tabl2, n_complex_interpolated_here_tabl2] = getData_refindex;
						
						lambda_um_original = unique([lambda_um_original_tabl1; lambda_um_original_tabl2]);
						
						BBBB = unique([lambda_um_original_tabl1, n_complex_original_here_tabl1], 'rows');
						BBBB = delete_non_unique_val(BBBB);
						n_complex_original_in_tabl1 = interp1(BBBB(:,1), BBBB(:,2), lambda_um_original);
						
						BBBB = unique([lambda_um_original_tabl2, n_complex_original_here_tabl2], 'rows');
						BBBB = delete_non_unique_val(BBBB);
						n_complex_original_in_tabl2 = interp1(BBBB(:,1), BBBB(:,2), lambda_um_original);
						
						n_complex_original = n_complex_original_in_tabl1 + n_complex_original_in_tabl2;
						n_complex_interpolated = n_complex_interpolated_here_tabl1 + n_complex_interpolated_here_tabl2;
						
					case 'one_formula_one_table'
						switch strtok(ThisMaterial.DATA{1}.type)
							case 'formula'
								ind_formula = 1; ind_table = 2;
							case 'tabulated'
								ind_formula = 2; ind_table = 1;
						end
						
						% get the complex refractive index from the formula
						DATA_here_here = ThisMaterial.DATA{ind_formula};
						data_type = ThisMaterial.DATA{ind_formula}.type;
						[lambda_um_original_form, n_complex_original_here_form, n_complex_interpolated_here_form] = getData_refindex;
						
						% get the complex refractive from the table
						DATA_here_here = ThisMaterial.DATA{ind_table};
						data_type = ThisMaterial.DATA{ind_table}.type;
						[lambda_um_original_tabl, n_complex_original_here_tabl, n_complex_interpolated_here_tabl] = getData_refindex;
						
						% interpolate over wavelength of the formula
						BBBB = unique([lambda_um_original_tabl, n_complex_original_here_tabl], 'rows');
						BBBB = delete_non_unique_val(BBBB);
						n_complex_original_in = interp1(BBBB(:,1), BBBB(:,2), lambda_um_original_form);
						
						n_complex_original = n_complex_original_in + n_complex_original_here_form;
						n_complex_interpolated = n_complex_interpolated_here_form + n_complex_interpolated_here_tabl;
						
						lambda_um_original = lambda_um_original_form;
				end
			end
			
			counter = counter+1;
			
			ind_data = strfind(filepath, [filesep,'data',filesep]);
			Material_name = filepath(ind_data+6 : end-4);
			
			epsilon_complex_interpolated = n_complex_interpolated.^2;
			
			%% saving the data to a structure array
			if save_data_to_file == 1
				All_data.data(counter).MaterialName = Material_name;
				All_data.data(counter).lambda_um = lambda_um_original;
				
				All_data.data(counter).n_complex = n_complex_original;
				All_data.data(counter).epsilon_complex = n_complex_original.^2;
				
				All_data.data(counter).n_complex_interpolated = n_complex_interpolated;
				All_data.data(counter).epsilon_complex_interpolated = epsilon_complex_interpolated;
				
				All_data.data(counter).data_type = data_type_all;
				
				% add any other field otherthan above
				fields_here = fieldnames(ThisMaterial);
				for kkk = 1 : length(fieldnames(ThisMaterial))
					All_data.data(counter).(fields_here{kkk}) = ThisMaterial.(fields_here{kkk});
				end
			end
		end
		
	catch ME
		counter_for_errors = counter_for_errors+1;
		indices_with_errors(counter_for_errors) = j1;
		disp(ME)
	end
end

if save_data_to_file == 1
	save([DataSource_main_folder,filesep,'All_data_with_interpolation_04_12_2018'], 'All_data')
	add_data % add more data to the database
end

% return back to original directory
cd(previous_directory);




	function [lambda_um_original, n_complex_original, n_complex_interpolated, n_complex_AsInTable] = getData_refindex
		n_complex = []; n_complex_AsInTable = [];
		for kk = 1 : 2 % repeat the calculation twice, one for the given wavelegnth range, while the other for the interpolated
			switch strtok(data_type)
				case 'formula'
					if kk == 1 % this is for the given and original lambda_um range
						wavelength_range = str2num(DATA_here_here.wavelength_range);
						lambda_um = linspace(wavelength_range(1), wavelength_range(2), 1000)';
						lambda_um_original = lambda_um;
					else % this is to make calculations on the interpolation lambda_um
						ind_incl = find(lambda_um_univ_interp >= wavelength_range(1) & ...
							lambda_um_univ_interp <= wavelength_range(2) );
						lambda_um = lambda_um_univ_interp(ind_incl);
					end
					C = str2num(DATA_here_here.coefficients);
					
				case 'tabulated'
					if kk == 1 % this is for the given and original lambda_um range
						A = str2num(DATA_here_here.data); lambda_um = A(:,1);
						lambda_um_original = lambda_um;
					else % this is to make calculations on the interpolation lambda_um
						n_complex_AsInTable = n_complex_original;
						
						ind_incl = find(lambda_um_univ_interp > min(lambda_um) & ...
							lambda_um_univ_interp < max(lambda_um) );
						lambda_um_int = lambda_um_univ_interp (ind_incl);
						
						% making sure that we have unique rows
						
						
						% 						% find indices with unique values
						% 						lambda_um_unq = unique(lambda_um);
						% 						for iii = 1 : length(lambda_um_unq)
						% 							inn = find(lambda_um == lambda_um_unq(iii));
						% 							n_complex_unq(iii, 1) = n_complex(inn(1));
						% 						end
						
						
						
						AAAA = unique([lambda_um, n_complex], 'rows');
						AAAA = delete_non_unique_val(AAAA);
						n_complex_int = interp1(AAAA(:,1), AAAA(:,2), lambda_um_int);
						n_complex = n_complex_int;
						
					end
			end
			
			switch data_type
				case {'formula 1', 'formula 2'} % Sellmeier (preferred), Sellmeier-2
					summ = C(1);
					for jj = 2 : 2 : length(C)-1
						summ = summ + C(jj).*lambda_um.^2 ./ (lambda_um.^2 - C(jj + 1).^2);
					end
					n_complex = sqrt(summ + 1);
					
				case 'formula 3' % Polynomial
					summ = C(1);
					for jj = 2 : 2 : length(C)-1
						summ = summ + C(jj) .* lambda_um.^C(jj+1);
					end
					n_complex = sqrt(summ);
					
				case 'formula 4' % RefractiveIndex.INFO
					summ = C(1);
					for jj = 2 : 4 : 6
						summ = summ + ...
							C(jj) .* lambda_um.^C(jj+1) ./ ...
							(lambda_um.^2 - C(jj+2).^C(jj+3));
					end
					
					for jj = 10 : 2 : length(C)-1
						summ = summ + C(jj).*lambda_um.^C(jj+1);
					end
					
					n_complex = sqrt(summ);
					
				case 'formula 5' % Cauchy
					summ = C(1);
					for jj = 2 : 2 : length(C)-1
						summ = summ + C(jj) .* lambda_um.^C(jj+1);
					end
					n_complex = summ;
					
				case 'formula 6' % Gases
					summ = C(1);
					for jj = 2 : 2 : length(C)-1
						summ = summ + C(jj) ./ (C(jj + 1) - lambda_um.^-2);
					end
					n_complex = summ + 1;
					
				case 'formula 7' % Herzberger
					summ = C(1) + C(2) ./ (lambda_um.^2 - 0.028) ...
						+ C(3) ./ (lambda_um.^2 - 0.028).^2;
					
					cntr = 0;
					for jj = 4 : length(C)
						cntr = cntr + 1;
						summ = summ + C(jj) .* lambda_um.^(2*cntr);
					end
					
					n_complex = summ;
					
				case 'formula 8' % Retro
					AA = C(1) + C(2) .* lambda_um.^2 ./ (lambda_um.^2 - C(3)) + C(4).*lambda_um.^2;
					n_complex = sqrt((1+2*AA)./(1-AA));
					
				case 'formula 9' % Exotic
					n_complex = sqrt( C(1) + C(2) ./ (lambda_um.^2 - C(3)) + C(4) .* ( lambda_um - C(5)              )    ./ ...
						((lambda_um - C(5)).^2 + C(6))  );
					
				case 'tabulated n'
					if kk == 1,	n_complex = A(:,2);				end
					
				case 'tabulated k'
					if kk == 1,	n_complex =          1i*A(:,2); end
					
				case 'tabulated nk'
					if kk == 1,	n_complex = A(:,2) + 1i*A(:,3); end
			end
			
			if kk == 1
				n_complex_original		= n_complex;
			else
				% try to fit the data with the same matrix size
				n_complex_interpolated = n_complex_NaN;
				n_complex_interpolated(ind_incl) = n_complex;
			end
		end
	end



end

function AAAA_cleaned = delete_non_unique_val(AAAA)
% find indices with unique values
lambda_um_unq = unique(AAAA(:,1));
AAAA_cleaned(:, 1) = lambda_um_unq;
for iii = 1 : length(lambda_um_unq)
	inn = find(AAAA(:,1) == lambda_um_unq(iii));
	
	AAAA_cleaned(iii, 2) = AAAA(inn(1), 2);
end
end