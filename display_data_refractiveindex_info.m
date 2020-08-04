% this function display all the optical properties of materials with the given name

function display_data_refractiveindex_info(Part_from_MaterialName, n_or_eps, original_or_interp, plot_skin_depth)
if nargin < 4
	plot_skin_depth = 0;
end

if plot_skin_depth == 1
	n_subplots = 3;
else
	n_subplots = 2;
end

mfilepath = mfilename('fullpath'); ind_sep = find(mfilepath == filesep);
mfile_folder = mfilepath(1:ind_sep(end)); cd(mfile_folder);

load(['rii-database-2019-02-11', filesep, 'All_data_with_interpolation_processed.mat']);
all_MaterialName = {All_data.data(:).MaterialName};
ss = size(All_data.data); N_materials = ss(2);
lambda_um_interp = [All_data.ReadMe.lambda_um_univ_interp];

n_data_matches = 0;
for nn = 1 : ss(2)
	if contains(all_MaterialName{nn}, Part_from_MaterialName)
		n_data_matches = n_data_matches + 1;
		if contains(n_or_eps, 'n')
			if (n_data_matches == 1), figure_n = figure; end
			
			if contains(original_or_interp, 'interp')
				n_complex = [All_data.data(nn).n_complex_interpolated];
				lambda_um = lambda_um_interp;
			else
				n_complex = [All_data.data(nn).n_complex];
				lambda_um = [All_data.data(nn).lambda_um];
			end
			
			figure(figure_n);
			subplot(n_subplots,1,1)
			plot(lambda_um, real(n_complex), 'DisplayName', all_MaterialName{nn}), hold on
			xlabel('\lambda [\mum]'), ylabel('n')
			
			subplot(n_subplots,1,2)
			plot(lambda_um, imag(n_complex), 'DisplayName', all_MaterialName{nn}), hold on
			xlabel('\lambda [\mum]'), ylabel('k')			
			
			if plot_skin_depth == 1, Go_plot_skin_depth(lambda_um, n_complex, n_subplots, all_MaterialName{nn}), end
		end
		
		if contains(n_or_eps, 'eps')
			if (n_data_matches == 1), figure_e = figure; end
			
			if contains(original_or_interp, 'interp')
				eps_complex = [All_data.data(nn).epsilon_complex_interpolated];
				lambda_um = lambda_um_interp;
			else
				eps_complex = [All_data.data(nn).epsilon_complex];
				lambda_um = [All_data.data(nn).lambda_um];
			end
			
			figure(figure_e);
			subplot(n_subplots,1,1)
			plot(lambda_um, real(eps_complex), 'DisplayName', all_MaterialName{nn}), hold on
			xlabel('\lambda [\mum]'), ylabel('real(\epsilon)')
			
			subplot(n_subplots,1,2)
			plot(lambda_um, imag(eps_complex), 'DisplayName', all_MaterialName{nn}), hold on
			xlabel('\lambda [\mum]'), ylabel('imag(\epsilon)')
			
			if plot_skin_depth == 1, Go_plot_skin_depth(lambda_um, n_complex, n_subplots, all_MaterialName{nn}), end
		end
		
		
	end
end

if (n_data_matches > 0)
	if contains(n_or_eps, 'n')
		figure(figure_n); subplot(n_subplots,1,1), title(['All materials which name contains "',Part_from_MaterialName, '"']); legend off, legend show, linkaxes(findall(gcf,'type','axes'), 'x'), legend off
		subplot(n_subplots,1,2), ylim = get(gca, 'YLim'); set(gca, 'YLim', [0, ylim(2)]);
		
		if plot_skin_depth == 1, subplot(n_subplots,1,3), ylim = get(gca, 'YLim'); set(gca, 'YLim', [0, ylim(2)]); end
	end
	if contains(n_or_eps, 'eps')
		figure(figure_e); subplot(n_subplots,1,1), title(['All materials which name contains "',Part_from_MaterialName, '"']); legend off, legend show, linkaxes(findall(gcf,'type','axes'), 'x')
		if plot_skin_depth == 1, subplot(n_subplots,1,3), ylim = get(gca, 'YLim'); set(gca, 'YLim', [0, ylim(2)]); end
	end
end



n_data_matches


end


function Go_plot_skin_depth(lambda_um, n_complex, n_subplots, Material_name)
k_v = 2*pi ./ (lambda_um*1e-6);
SkinDepth = 1 ./ (k_v .* imag(n_complex));

subplot(n_subplots,1,3)
semilogy(lambda_um, SkinDepth*1e6, 'DisplayName', Material_name), hold on
xlabel('\lambda [\mum]'), ylabel('Skin Depth [\mum]')


end