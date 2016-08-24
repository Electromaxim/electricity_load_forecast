%% Automate the Data Import Process
% This script imports data from the Zonal hourly spreadsheets provided by
% ISO New England. The folder containing these
% spreadsheets should be specified below. By default it is assumed to be a
% folder called "Data" in the same folder as this script. The data that is
% read in is saved as a MAT-file in the same folder.

folder = 'Data';
% Example: folder = 'C:\Temp\Data';

% By default the sheet name is ISONE CA. However, it can easily be changed
% to ME, CT, VT, NH, RI, SEMASS, WCMASS or NEMASSBOST to extract zonal data
sheetname = 'ISONE CA';

% Import data for 2004
if strcmp(sheetname, 'ISONE CA')
    NEData = dataset('XLSFile', sprintf('%s\\2004_smd_hourly.xls',folder,yr), 'Sheet', 'NEPOOL');
else
    NEData = dataset('XLSFile', sprintf('%s\\2004_smd_hourly.xls',folder,yr), 'Sheet', sheetname);
end
% Add a column 'Year'
NEData.Year = 2004 * ones(length(NEData),1);
    
% Import data for other years
for yr = 2005:2009

    % Read in data into a dataset array
	x = dataset('XLSFile', sprintf('%s\\%d_smd_hourly.xls',folder,yr), 'Sheet', sheetname);
    
    % Add a column 'Year'
    x.Year = yr*ones(length(x),1);
    
    % Concatenate the datasets together
    NEData = [NEData; x];
end

% Calculate numeric date
NEData.NumDate = datenum(NEData.Date, 'mm/dd/yyyy') + (NEData.Hour-1)/24;

save([folder '\' genvarname(sheetname) '_Data.mat'], 'NEData');