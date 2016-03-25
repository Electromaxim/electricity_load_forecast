function [errors, net] = trainAndTestNN(trainX, trainY, testX, testY, ind, net, baselineErr)
% Train and test a neural network for a given set of training and test
% data. The MAE metric is used to train a feed forward neural network with
% 20 neurons in the hidden layer. The mean absolute error is also reported
% for the test set

if nargin < 5
    ind = 1:size(trainX,2);
    numAllPred = 14;
else
    assert(max(ind) <= size(trainX,2));
    numAllPred = size(trainX,2);
end

if nargin < 6 || isempty(net)
    net = newfit(trainX(:,ind)', trainY', 20);
    net.performFcn = 'mae';
    net = train(net, trainX(:,ind)', trainY');
end

predY = sim(net, testX(:,ind)')';
err = testY - predY;
errpct = abs(err)./testY*100;

errors = [mean(abs(err)) mean(errpct)];

if nargin > 6
    fprintf('\nBaseline error with %2d predictors: MAE = $%0.2f, MAPE = %0.2f%%\n', numAllPred, baselineErr);
end
fprintf('Error with selected %2d predictors: MAE = $%0.2f, MAPE = %0.2f%%\n\n', length(ind), errors);


