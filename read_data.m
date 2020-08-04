% this file read the data from the downloaded file from refractiveindex.info, and store the data in a structure for later use (for example, material search).

function read_data
% folder location that contains all the data
DataSource = 'C:\Users\local-admin\Google Drive\elzouka_codes_library\MATLAB\optical_properties\from_RefractiveIndex.info\rii-database-2019-02-11';
DataSource = [DataSource,filesep,'database\data'];
cd(DataSource)
All_yml_files = subdir('*.yml');


counter = 0; counter_for_errors = 0; All_data = [];

for j1 = 1 : length(All_yml_files)
	
	filepath = All_yml_files(j1).name;
	try
		x = YAML.read(filepath);
		for j2 = 1 : length(x)
			ThisMaterial = x(j2);
			DATA_here = ThisMaterial.DATA;
			if length(DATA_here) > 0
				for j3 = 1 : length(DATA_here)
					if length(DATA_here) == 1
						DATA_here_here = ThisMaterial.DATA(j3);
					else
						DATA_here_here = ThisMaterial.DATA{j3};
					end
					counter = counter+1;
					% 					Material_Here = ThisMaterial{j3};
					data_type = DATA_here_here.type;
					data_types{counter, 1} = data_type;
					[lambda_um, n_complex] = getData_refindex;
				end
			else
				DATA_here_here = ThisMaterial.DATA;
				counter = counter+1;
% 				Material_Here = ThisMaterial;
				data_type = DATA_here_here.type;
				data_types{counter, 1} = data_type;
				[lambda_um, n_complex] = getData_refindex;
			end			
		end
	catch ME
		counter_for_errors = counter_for_errors+1;
		indices_with_errors(counter_for_errors) = j1;
		disp(ME)
	end	
end



	function [lambda_um, n_complex] = getData_refindex
		switch strtok(data_type)
			case 'formula'				
				wavelength_range = DATA_here_here.wavelength_range;				
				lambda_um = linspace(wavelength_range(1), wavelength_range(2), 1000);				
				C = str2num(DATA_here_here.coefficients);
				n_complex = [];
			case 'tabulated'
				A = str2num(DATA_here_here.data); lambda_um = A(:,1);
				n_complex = [];
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
				
			case 'tabulated k'				
				n_complex = A(:,2);
			case 'tabulated n'				
				n_complex =          1i*A(:,2);
			case 'tabulated nk'				
				n_complex = A(:,2) + 1i*A(:,3);
		end
	end
end