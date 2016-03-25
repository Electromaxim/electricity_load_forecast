function y = loadForecast(date, temperature, isHoliday)
% LOADFORECAST performs a day-ahead load forecast using a pre-trained
% Neural-Network or Bagged Regression Tree model
%
% USAGE:
% y = loadForecast(model, date, hour, temperature, isWorkingDay))

% Process inputs
date = datenum(date);
if date < 7e5 % Convert from Excel numeric date to MATLAB numeric date if necessary
    date = x2mdate(date);
end

% Check if date is a holiday
if iscell(isHoliday)
    isHoliday = isHoliday{1};
end
if ischar(isHoliday)
    if strcmpi(isHoliday(1),'N')
        isWorkingDay = true;
    else
        isWorkingDay = false;
    end
else
    isWorkingDay = ~isHoliday;
end
isWorkingDay = logical(isWorkingDay) & ~ismember(weekday(date),[1 7]);

% Import historical loads from the database
try
    data = fetchDBLoadData(date-7, date-1);
catch ME %#ok<NASGU>
    % Import historical loads from MAT file
    s = load('Data\DBLoadData.mat');
    data = s.data;
    ind = data.NumDate >= date-7 & floor(data.NumDate) <= date-1;
    data.Hour = data.Hour(ind);
    data.DryBulb = data.DryBulb(ind);
    data.DewPnt = data.DewPnt(ind);
    data.SYSLoad = data.SYSLoad(ind);
    data.NumDate = data.NumDate(ind);
end
if isempty(data.SYSLoad)
    error('Not enough historical data for forecast.');
end
    
ave24 = filter(ones(24,1)/24, 1, data.SYSLoad);
loadPredictors = [data.SYSLoad(1:24) data.SYSLoad(end-23:end) ave24(end-23:end)];

% Create predictor matrix
% Drybulb, Dewpnt, Hour, Day, isWkDay, PrevWeek, PrevDay, Prev24
X = [temperature (1:24)' weekday(date)*ones(24,1) isWorkingDay*ones(24,1) loadPredictors];

% Load models
try
    % Load from a location where updated models can be stored
    model1 = load('C:\Temp\Forecaster\NNModel.mat');
    model2 = load('C:\Temp\Forecaster\TreeModel.mat');
catch %#ok<CTCH>
    model1 = load('Models\NNModel.mat');
    model2 = load('Models\TreeModel.mat');
end

% Perform prediction
try
    y1 = sim(model1.net, X')';
catch ME
    % For debugging purposes if necessary
    save C:\error.mat ME model1 model2
    y1 = zeros(24,1);
end
y2 = predict(model2.model, X);

% Create load profile plot
fig = clf;
if isdeployed
    set(fig,'Visible','off')
end
plot([y1 y2]/1e3, '.-'); 
xlabel('Hour');
ylabel('Load (x1000 MW)');
title(sprintf('Load Forecast Profile for %s', datestr(date)))
grid on;
legend('NeuralNet','BaggedTree','Location','best');
print -dmeta

y = [y1 y2];

%#function TreeBagger
%#function CompactTreeBagger
%#function network
%#function network\sim
%#function mae