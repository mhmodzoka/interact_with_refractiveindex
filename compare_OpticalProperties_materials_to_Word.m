% compare different materials at different temperatures, and bandgaps
function compare_OpticalProperties_materials_to_Word
% inputs
list_of_materials_text = ['SiO2, Al2O3, MoO3, GaAs, MgF2, AlAs, GaN, GaP, GaS, AlSb, CaF2, Ge, Si, SiC, GaS, ZnSe, TiO2, ZnS, AlN, Si3N4, ZnO, GaAs, ZnO, SiC, AlSb, GaSb, InSb, MgO, Ta2O5'];
list_of_materials_text = ['main\W\Ordal']
ind_spaces = find(list_of_materials_text == ' '); list_of_materials_text(ind_spaces) = [];
list_of_materials = unique(strsplit(list_of_materials_text, ','));

list_of_temperatures = [1500];
list_of_bandgaps_eV = [0.7];


% start calculations
word = actxserver('Word.Application');      %start Word
word.Visible =1;                            %make Word Visible
document=word.Documents.Add;                %create new Document
selection=word.Selection;                   %set Cursor
selection.Font.Name='Calibri';          %set Font
selection.Font.Size=14;
selection.Paragraphs.LineUnitAfter=0.01;    %sets the amount of spacing
%between paragraphs(in gridlines)


for n_BG = 1 : length(list_of_bandgaps_eV)
	eV = list_of_bandgaps_eV(n_BG);
	for n_T = 1 : length(list_of_temperatures)
		T = list_of_temperatures(n_T);
		start_new_section
		for n_mat = 1 : length(list_of_materials)
			material_name = list_of_materials{n_mat};
			
			% text
			selection.TypeParagraph;                    %line break
			selection.TypeParagraph;                    %line break
			selection.TypeText([material_name]);         %write Text
			selection.TypeParagraph;                    %line break
			selection.TypeParagraph;                    %line break
			
			% plotting and pasting figure in Word
			display_data_refractiveindex_info([filesep, material_name, filesep], 'n', 'inter', 1);
			figtoprint = gcf;
			
% 			subplot(3,1,1), legend off
			set(findall(gcf,'type','axes'), 'XScale', 'log', 'XLim', [0.4, 50], 'XTick',[0.4 0.7 1 2 3 5 10 20 50], 'FontSize', 8, 'YLimMode', 'auto');			
			axes_all = findall(gcf,'type','axes');			
			for kkk = 1 : length(axes_all), ylim_old = get(axes_all(kkk), 'YLim'); set(axes_all(kkk), 'YLim', [0, ylim_old(2)]); end
			
			% plot horizontal line @ 1mm skin depth
			max_skindepth = 1e3;			
			axes_all(3); hold on, 
			current_ylim = get(gca, 'YLim');
			if (max_skindepth < current_ylim(2))
				line(get(gca, 'XLim'), [1e3, 1e3], 'LineStyle', '--', 'Color', 'red');
			end
			
			plot_blackbody_shadow(T, 'um', 'rad', 1)
% 			subplot(3,1,3), hold on, set(gca, 'YScale', 'log')
			
			plotting_interesting_freq_lines(z_convert_wavelength_freq(eV, 'eV', 'um'), 1)
			
			% pasting figure to Word
			print(figtoprint,'-dmeta');                 %print figure to clipboard
			invoke(word.Selection,'Paste');             %paste figure to Word
			close(figtoprint);
		end
		selection.TypeParagraph;                    %line break
	end
end

	function start_new_section		
		selection.TypeText(['T = ', num2str(T),' K, ', 'E_BG = ', num2str(eV),' eV ================']);         %write Text
		selection.TypeParagraph;                    %line break
		selection.TypeParagraph;                    %line break

		%
		% Mark Text -> change Font -> change Background color
		selection.MoveUp(5,1,1);                    %5=row mode
		%with this command we mark the previous row %1=amount
		%1=hold shift
		selection.Font.Bold=1;                      %set text to Bold
		selection.Shading.BackgroundPatternColorindex=7;
	end

end