close all; clear; clc;

data = load('airfoil_self_noise.dat');

data = data(randperm(size(data,1)),:);

Dtrn = data(1:floor(size(data,1)*0.6),:);
Dval = data(size(Dtrn,1)+1:size(Dtrn,1)+ceil(size(data,1)*0.2),:);
Dchk = data(size(Dtrn,1)+size(Dval,1)+1:end, :);

[Dtrn,PS] = mapminmax(Dtrn',0,1);
Dtrn = Dtrn';
Dval = mapminmax('apply',Dval',PS);
Dval= Dval';
Dchk = mapminmax('apply',Dchk',PS);
Dchk= Dchk';

opt = generate_opts();
if not(isfolder('data'))
    mkdir('data')
end
fd = fopen('data/results.txt','a+');
for i = 1:4
    Tsk_model(i) = genfis(Dtrn(:,1:end-1),Dtrn(:,end),opt(i));
    trn_options = anfisOptions('InitialFis',Tsk_model(i),'EpochNumber',30);
    trn_options.ValidationData = [Dval(:,1:end-1) Dval(:,end)];
    [trnFis,trnError,stepSize,valFis,valError] = anfis([Dtrn(:,1:end-1) Dtrn(:,end)],trn_options);
    
    figure('Renderer', 'painters', 'Position', [5 5 1200 800], 'Name', strcat('TSK model ', int2str(i)));
    sgtitle(strcat('TSK model ', int2str(i)));
    
    subplot(1,5,1)
    plotmf(valFis,'input',1);
    xlabel('Frequency')
    
    subplot(1,5,2)
    plotmf(valFis,'input',2);
    xlabel('Angle of attack')
    
    subplot(1,5,3)
    plotmf(valFis,'input',3);
    xlabel('Chord length')
    subtitle('After training');
    
    subplot(1,5,4)
    plotmf(valFis,'input',4);
    xlabel('Free-stream velocity')
    
    subplot(1,5,5)
    plotmf(valFis,'input',5);
    xlabel('Suction side displacement thickness')
    name =  strcat('TSK_model_',int2str(i), '_MFs');
    saveas(gcf,name,'png'); 
    
    y_out = evalfis(valFis, Dchk(:,1:end-1)); 
    SSres = sum((Dchk(:,end) - y_out).^2);
    SStot = sum((Dchk(:,end) - mean(Dchk(:,end))).^2);
    R2 = 1- SSres/SStot;
    NMSE = 1-R2;
    RMSE = sqrt(mse(y_out,Dchk(:,end)));
    NDEI = sqrt(NMSE);
    pred_error = Dchk(:,end) - y_out;
    fprintf(fd,strcat('TSK_model_',int2str(i), '\n'));
    fprintf(fd,'\nRMSE = %f\nNMSE = %f\nNDEI = %f\nR2 = %f', RMSE, NMSE, NDEI, R2);
    
    figure;
    plot([trnError valError], 'LineWidth',2);
    xlabel('Epoch');
    ylabel('Error');
    legend('Training Error', 'Validation Error');
    title(strcat("Tsk model ", strcat(int2str(i), " Learning Curve")));
    name = strcat('TSK_model_',int2str(i), '_learning_curve');
    saveas(gcf,name,'png'); 

    figure;
    stem(pred_error, 'LineWidth',2);
    xlabel('Testing Data');
    ylabel('Error');
    title(strcat("Tsk model ", strcat(int2str(i), " Prediction Error")));
    name = strcat('tsk_model_',int2str(i), '_prediction_error');
    saveas(gcf,name,'png'); 

    figure, errorbar(y_out, y_out, min(-pred_error,0),max(-pred_error,0))
            xlabel('True output');
    ylabel('Predicted');
    title(strcat("Tsk model ", strcat(int2str(i), " with error bars")));
    name = strcat('TSK_model_',int2str(i), '_with_error_bars');
    saveas(gcf,name,'png'); 
    
    figure, histogram(pred_error,50)
    title(strcat("Tsk model ", strcat(int2str(i), " histogram of the prediction errors")));
    name = strcat('tsk_model_',int2str(i), '_histogram_of_the_prediction_errors');
    saveas(gcf,name,'png'); 
end
fclose(fd);