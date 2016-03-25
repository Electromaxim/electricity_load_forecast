%% Predictor Comparison
% This script analyzes the predictive power of different sets of predictors
% on day-ahead electricity price forecasting

%% Import data and generate all predictors

% Fetch price data
load Data\DBPriceData.mat

% Import holidays
[num, text] = xlsread('..\Data\Holidays.xls');
holidays = text(2:end,1);

% Create predictors
term = 'short';
[X, dates, labels] = genPredictors(data, term, holidays);

% Interpolate missing values
ind = data.ElecPrice==0;
data.ElecPrice(ind) = interp1(find(~ind), data.ElecPrice(~ind), find(ind));

% Create training set
trainInd = data.NumDate < datenum('2008-01-01');
trainX = X(trainInd,:);
trainY = data.ElecPrice(trainInd);

% Create test set and save for later
testInd = data.NumDate >= datenum('2008-01-01');
testX = X(testInd,:);
testY = data.ElecPrice(testInd);
testDates = dates(testInd);

clear X data trainInd testInd term holidays dates ans num text

%% Load pre-trained networks
load Models\SubsetNets

%% Baseline performance with all predictors
% Compute performance of best neural network with all predictors
load Models\NNModel
forecastPrice = sim(net, testX')';
err = testY-forecastPrice;
errpct = abs(err)./testY*100;
baselineErr = [mean(abs(err)) mean(errpct)];

%% Price, Load & Fuel
% Do the hour, weekday, holiday and temperature variables provide any
% predictive power when the load is known?
ind = 6:length(labels);
disp('Selected Predictors:')
disp(char(labels(ind)'));
[subsetErr(1,:), nets{1}] = trainAndTestNN(trainX, trainY, testX, testY, ind, nets{1}, baselineErr);
save Models\SubsetNets nets

%% No Load Information 
% How accurate is the prediction if the load information is not known?
ind = [1:5 10:14];
disp('Selected Predictors:')
disp(char(labels(ind)'))
[subsetErr(2,:), nets{2}] = trainAndTestNN(trainX, trainY, testX, testY, ind, nets{2}, baselineErr);
save Models\SubsetNets nets

%% No Current Load Information 
% How accurate is the prediction if the real-time load is not known?
ind = [1:5 7:14];
disp('Selected Predictors:')
disp(char(labels(ind)'))
[subsetErr(3,:), nets{3}] = trainAndTestNN(trainX, trainY, testX, testY, ind, nets{3}, baselineErr);
save Models\SubsetNets nets
