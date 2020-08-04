% this file read the data from the downloaded file from refractiveindex.info, and store the data in a structure for later use (for example, material search).

function read_data_2
% folder location that contains all the data
DataSource_main_folder = 'C:\Users\local-admin\Google Drive\elzouka_codes_library\MATLAB\optical_properties\from_RefractiveIndex.info\rii-database-2019-02-11';
DataSource = [DataSource_main_folder,filesep,'database\data'];
cd(DataSource)
All_yml_files = subdir('*.yml');

% create a universal wavelength (this is based on my experience)
lambda_um_univ_interp = unique([...
	linspace(8.266e-8, 0.001, 100), ...
	linspace(0.001, 0.228, 200), ...
	linspace(0.228, 51.68, 10000), ...
	linspace(51.68, 2.85e5, 100)]);
lambda_um_univ_interp = lambda_um_univ_interp';

counter = 0; counter_for_errors = 0; All_data = [];
All_fieldnames = [];

n_complex_NaN = NaN*ones(size(lambda_um_univ_interp));

for j1 = 1 : length(All_yml_files)	
	j1
	filepath = All_yml_files(j1).name;
% 	try
		x = YAML.read(filepath);
		for j2 = 1 : length(x)
			ThisMaterial = x(j2);
			All_fieldnames = unique([All_fieldnames ; fieldnames(ThisMaterial)]);
			DATA_here = ThisMaterial.DATA;
			n_complex_original = 0; n_complex_interpolated = 0; data_type_all = [];
			for j3 = 1 : length(DATA_here)
				if     length(DATA_here) == 1
					DATA_here_here = ThisMaterial.DATA(j3);
				elseif length(DATA_here) == 2
					DATA_here_here = ThisMaterial.DATA{j3};
					% For this case, k is tabulated, and n is calculated from formula.
				else
					More_than_two_data=1
					j2
					DATA_here_here = ThisMaterial.DATA{j3};
				end
				data_type = DATA_here_here.type;
% 				data_type_all{j3} = data_type;
				data_type_all = [data_type_all, ', ', data_type];
				[lambda_um_original, n_complex_original_here, n_complex_interpolated_here] = getData_refindex;
				
				n_complex_interpolated = n_complex_interpolated + n_complex_interpolated_here;
				
				n_complex_original = n_complex_original_here;
% 				n_complex_original = n_complex_original + n_complex_original_here; % by the way, if the material has two datasets, then one is usually for n and the other for k
			end
			counter = counter+1;
			data_types{counter, 1} = data_type_all;
			
			ind_data = strfind(filepath, [filesep,'data',filesep]);
			Material_name = filepath(ind_data+6 : end-4);
			
			%% saving the data to a structure array
			All_data(counter).MaterialName = Material_name;
			All_data(counter).lambda_um = lambda_um_original;
			All_data(counter).n_complex = n_complex_original;
			All_data(counter).epsilon_complex = n_complex_original.^2;
			All_data(counter).data_type = data_type_all;
			
			% add any other field otherthan above
			fields_here = fieldnames(ThisMaterial);
			for kkk = 1 : length(fieldnames(ThisMaterial))
				if ~strcmp(fields_here{kkk}, 'DATA')
					eval(['All_data(counter).', fields_here{kkk},' = ThisMaterial.', fields_here{kkk}, ';']);
				end
			end
			
		end
% 	catch ME
% 		counter_for_errors = counter_for_errors+1;
% 		indices_with_errors(counter_for_errors) = j1;
% 		disp(ME)
% 	end
end
All_fieldnames2
save([DataSource_main_folder,filesep,'All_data_with_interpolation'], 'All_data')



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
						
						ind_incl = find(lambda_um_univ_interp >= min(lambda_um) & ...
										lambda_um_univ_interp <= max(lambda_um) );
						lambda_um_int = lambda_um_univ_interp (ind_incl);
						
						n_complex_int = interp1(lambda_um, n_complex, lambda_um_int);
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
					n_complex = C(1) + C(2) ./ (lambda_um.^2 - 0.028) ...
						+ C(3) ./ (lambda_um.^2 - 0.028).^2 ...
						+ C(4) .* lambda_um.^2 ...
						+ C(5) .* lambda_um.^4 ...
						+ C(6) .* lambda_um.^6;
					
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