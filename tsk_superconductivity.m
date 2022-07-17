close all; clear; clc;

data = importdata('train.csv');
colHeaders = data.colheaders;
data = data.data;

[trainData,testData,~] = split_scale(data,[0.8 0.2 0],1);

Rsq = @(yhat,y) 1-sum((yhat-y).^2)/sum((y-mean(y)).^2);

features = 1:2:9;
clusterRadius = 0.1:0.1:1;
k_folds = 5;

% Grid Search MSE results for each model
gridMSE = NaN*ones(length(features),length(clusterRadius));
% Number of rules for each model
numRules = NaN*ones(length(features),length(clusterRadius));

[importanceIndexes,importanceWeights] = relieff(trainData(:,1:end-1),trainData(:,end),10);

for nF = 1:length(features)
    % Extract the specific number of features before proceeding
    tdr = trainData(:,importanceIndexes(1:features(nF)));
    % Include target column
    tdr = [tdr trainData(:,end)];
    for cR = 1:length(clusterRadius)
        cvObject = cvpartition(size(trainData,1),'KFold',k_folds);
        
        % MSEs vector for the #k_folds iterations of cross validation
        MSEs = NaN*ones(1,k_folds);
        % Perform k-fold cross validation
        for k=1:k_folds
            % Split the training data into training and validation
            trainDataCV = tdr(training(cvObject,k),:);
            valDataCV = tdr(test(cvObject,k),:);
            
            % Proceed to train the model and measure its performance
            fis_options = genfisOptions('SubtractiveClustering',...
                'ClusterInfluenceRange',clusterRadius(cR));
            inFis = genfis(trainDataCV(:,1:end-1),trainDataCV(:,end),fis_options);
            
            % If there haven't been at least two rules generated, anfis
            % will throw an error, so skip ahead, nothing to be done
            if (size(inFis.Rules,2) < 2)
                continue;
            end
            
            anfis_options = anfisOptions('InitialFis',inFis,'EpochNumber',25,...
                'ValidationData',valDataCV);
            
            [trainFis,trainRMSE,stepSize,bestValFis,valRMSE] = anfis(trainDataCV,anfis_options);
            
            MSEs(k) = min(valRMSE.*valRMSE);
        end
        gridMSE(nF,cR) = mean(MSEs);
        numRules(nF,cR) = size(inFis.Rules,2);
    end
end
% better safe than sorry. this takes a huuuuuuuuge amount of time
save('workspace_mid_TSK_regression_2');

figure('Position',[75 70 1400 680]);
% Flatten numRules and gridMSE
numRulesFlat = reshape(numRules,1,[]);
gridMSEFlat = reshape(gridMSE,1,[]);
subplot(1,2,1),scatter(numRulesFlat,gridMSEFlat), hold on;
xlabel('Number of Rules');
ylabel('MSE');
title('Error Relative to Number of Rules');
% Run x-lines for clarity (and style)
lineColors = {'red','green','blue','yellow'};
rep = 0;
for i=min(numRulesFlat): max(numRulesFlat)
    xline(i,lineColors{mod(rep,4) + 1});
    rep = rep + 1;
end
subplot(1,2,2),boxplot(gridMSE',features);
xlabel('Number of Features');
ylabel('MSE');
title('Error Relative to Number of Features');

% Build optimal model
[~,bestMSEindexLinear] = min(gridMSE,[],'all','omitnan','linear');
[bestMSErow,bestMSEcol] = ind2sub(size(gridMSE),bestMSEindexLinear);
bestfeatures = features(bestMSErow);
bestClusterRadius = clusterRadius(bestMSEcol);

% Extract the best number of features before proceeding
tdr_best = trainData(:,importanceIndexes(1:bestfeatures));
testData_reduced_best = testData(:,importanceIndexes(1:bestfeatures));
% Include target column
tdr_best = [tdr_best trainData(:,end)];
testData_reduced_best = [testData_reduced_best testData(:,end)];

[tdr_best, valData_reduced_best] = split_scale(tdr_best,...
    [0.75 0.25 0], 0);

fis_options_best = genfisOptions('SubtractiveClustering',...
    'ClusterInfluenceRange',bestClusterRadius);

inFis_best = genfis(tdr_best(:,1:end-1),...
    tdr_best(:,end),fis_options_best);

anfis_options_best = anfisOptions('InitialFis',inFis_best,'EpochNumber',25,...
    'ValidationData',valData_reduced_best);

[trainFis_best,trainRMSE_best,~,bestValFis_best,valRMSE_best] = ...
    anfis(tdr_best,anfis_options_best);

% eval best model
pred = evalfis(bestValFis_best,testData_reduced_best(:,1:end-1));
bestMSE = mse(pred,testData_reduced_best(:,end));
bestRMSE = sqrt(bestMSE);
bestR2 = Rsq(pred,testData_reduced_best(:,end));
%R2 = 1 - NMSE
bestNMSE = 1 - bestR2;
bestNDEI = sqrt(bestNMSE);
bestModelPerf = array2table([bestRMSE bestNMSE bestNDEI bestR2],'VariableNames',{'RMSE' 'NMSE' 'NDEI' 'R2'});

plotregression(testData_reduced_best(:,end),pred);
title('Best model''s pred vs Target Values');
xlabel('Target Values');
ylabel('pred');
saveas(gcf,'pred_vs_Target.png');

% Make a histogram of the prediction errors
figure();
predErrors = pred-testData_reduced_best(:,end);
predErrorsPercent = predErrors./testData_reduced_best(:,end);
histogram(predErrorsPercent,round(length(predErrorsPercent)*15));
title('Errors of Best Model');
ylabel('Frequency');
xlabel('Prediction Error (%)');
xlim([-3 10]);
saveas(gcf,'Prediction_Errors_Hist.png');

figure();
plot(trainRMSE_best,'red');
hold on;
plot(valRMSE_best,'green');
title('Best model''s Error Curve');
xlabel('Iteration');
ylabel('RMSE');
legend('Training RMSE','Validation RMSE','Location','Best');
saveas(gcf,'Learning_Curve.png');

figure('Position',[25 50 1500 730]);
subplot(2,3,1),plotmf(inFis_best,'input',4);
subplot(2,3,2),plotmf(inFis_best,'input',6);
subplot(2,3,3),plotmf(inFis_best,'input',9);
subplot(2,3,4),plotmf(bestValFis_best,'input',4);
subplot(2,3,5),plotmf(bestValFis_best,'input',6);
subplot(2,3,6),plotmf(bestValFis_best,'input',9);
saveas(gcf,'Fuzzy_Sets.png');

% again, better safe than sorry
save('workspace_end_TSK_regression_2');