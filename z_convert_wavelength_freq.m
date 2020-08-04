function output_number = z_convert_wavelength_freq(input_number, input_unit, desired_output_unit)
c=299792458; % speed of light
h_eV = 4.135667662e-15; % [eV.s]

% FIRST, switch all inputs to wavelength in m
switch input_unit
	case 'm',		wavelength_m = input_number;
	case 'cm',		wavelength_m = input_number * 1e-2;
	case 'mm',		wavelength_m = input_number * 1e-3;
	case 'um',		wavelength_m = input_number * 1e-6;
	case 'nm',		wavelength_m = input_number * 1e-9;
		
	case 'cm^-1',	wavelength_m = 1 ./ input_number * 1e-2; %%
		
	case 'Hz',		wavelength_m = c ./ input_number;
	case 'kHz',		wavelength_m = c ./ input_number * 1e-3;
	case 'MHz',		wavelength_m = c ./ input_number * 1e-6;
	case 'GHz',		wavelength_m = c ./ input_number * 1e-9;
	case 'THz',		wavelength_m = c ./ input_number * 1e-12;
		
	case {'rad/s', 'w_rads'},	wavelength_m = c ./ input_number * (2*pi);
	case 'Trad/s',	wavelength_m = c ./ input_number * (2*pi) * 1e-12;
		
	case 'eV',		wavelength_m = c ./ input_number * h_eV;
end


% SECOND, switch the wavelength in m to any desired output
switch desired_output_unit
	case 'm',		output_number = wavelength_m;
	case 'cm',		output_number = wavelength_m * 1e2;
	case 'mm',		output_number = wavelength_m * 1e3;
	case 'um',		output_number = wavelength_m * 1e6;
	case 'nm',		output_number = wavelength_m * 1e9;
		
	case 'cm^-1',	output_number = 1 ./ (wavelength_m*1e2); %%
		
	case 'Hz',		output_number = c ./ wavelength_m;
	case 'kHz',		output_number = c ./ wavelength_m * 1e-3;
	case 'MHz',		output_number = c ./ wavelength_m * 1e-6;
	case 'GHz',		output_number = c ./ wavelength_m * 1e-9;
	case 'THz',		output_number = c ./ wavelength_m * 1e-12;
		
	case {'rad/s', 'w_rads'},	output_number = c ./ wavelength_m * (2*pi);
	case 'Trad/s',	output_number = c ./ wavelength_m * (2*pi) * 1e-12;
		
	case 'eV', 		output_number = c ./ wavelength_m * h_eV;
end
end