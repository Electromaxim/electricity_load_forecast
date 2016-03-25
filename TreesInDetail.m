%% Further Refinements of the Bagged Regression Tree Model
% An important task when building such artificial intelligence models is
% the choice of model architecture, for example, the number of layers in a 
% Neural network or the choice of a kernal function in a Support Vector
% Machine. In the case of bagged trees, some of these model architecture
% parameters include, 
% * Number of trees
% * Minimum leaf size
% * The choice of predictors/inputs
% 
% The choice of model architecture usually requires some fundamental
% knowledge about the problem being solved, for example the predictive
% power of a input.  However, the flexibility of MATLAB and built-in
% functions in the Treebagger classl enable us to use a data driven
% approach to help determine these model structure parameters.
% 
% In the next two sections we demonstrate a data driven approach that uses
% built-in methods of the TreeBagger object to help determine appropriate
% choice of model architecture.

%% Determine Number of Trees and Appropriate Leaf Size
% The number of trees in the ensemble and their minimum leaf size governs 
% the accuracy of the model and can be selected to offer an appropriate tradeoff
% between precision, overfitting and speed. Here we compare the out-of-sample prediction
% error for a leaf size of 10, 20, 40 and 50. We can test this by
% turning on the parameter _oobpred_ which returns out-of-bag prediction
% errors during the training procedure. 

oobError = [];
leafSizes = [10 20 40 50];
for i = 1:length(leafSizes)
    model = TreeBagger(20, trainX, trainY, 'method', 'regression', ...
                       'oobpred', 'on', 'minleaf', leafSizes(i));
    oobError = [oobError model.oobError];
    
    figure(1), plot(oobError);
    xlabel('Number of grown trees'), ylabel('Out-of-bag Regression Error');
    title(sprintf('Regression Error versus Number of Trees & Leaf Size'));
    legend(num2str(leafSizes(1:i)')), drawnow;
end

%% Determine Feature Importance
% Of each of the predictors, which ones provide the most predictive power?
% Turning on the _oobVarImp_ parameter shows you out-of-bag estimates of this
% relative feature (input) importance. 

model = TreeBagger(20, trainX, trainY, 'method', 'regression', ...
                   'oobvarimp', 'on', 'minleaf', 30);

figure(2);
barh(model.OOBPermutedVarDeltaError);
ylabel('Feature');
xlabel('Out-of-bag feature importance');
title('Feature importance results');
set(gca, 'YTickLabel', labels)

