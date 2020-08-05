warning('off','all') % to turn off all warning messages

% getting the folder path of this mfile
%mfile_name = mfilename; mfile_fillpath = mfilename('fullpath'); mfile_folder = strrep(mfile_fillpath, mfile_name, '');

set(0,'defaultfigurecolor',[1 1 1])

addpath ('.')

% cd to the main MATLAB folder
% cd(mfile_folder)

All_m_files = subdir('*.m');
ss = size(All_m_files);
for jj = 1 : ss(1)
    addpath(All_m_files(jj).folder)
end
savepath
