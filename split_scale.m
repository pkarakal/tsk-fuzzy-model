function [set1,set2,set3] = split_scale(data,splitRatio, standardize)
    if (sum(splitRatio) ~= 1)
        disp('Sum of rations is not 1, aborting...');
        return
    end
    % Randomly permutate the row indexes of the data
    idx=randperm(length(data));
    
    % Assign the indexes of set1
    set1Idx=idx(1:round(length(idx)*splitRatio(1)));
    % Assign the indexes of set2
    cumSumRatio2 = splitRatio(1) + splitRatio(2);
    set2Idx=idx(round(length(idx)*splitRatio(1))+1:round(length(idx)*cumSumRatio2));
    % Assign the indexes of set3
    set3Idx=idx(round(length(idx)*cumSumRatio2)+1:end);
    
    % Split data (minus the last column (class))
    set1=data(set1Idx,1:end-1);
    set2=data(set2Idx,1:end-1);
    set3=data(set3Idx,1:end-1);
    if standardize == 1
        mu=mean(data(:,1:end-1));
        sig=std(data(:,1:end-1));
        set1=(set1-repmat(mu,[length(set1) 1]))./repmat(sig,[length(set1) 1]);
        set2=(set2-repmat(mu,[length(set2) 1]))./repmat(sig,[length(set2) 1]);
        set3=(set3-repmat(mu,[length(set3) 1]))./repmat(sig,[length(set3) 1]);
    end
    % Add the last column to the normalized features
    set1=[set1 data(set1Idx,end)];
    set2=[set2 data(set2Idx,end)];
    set3=[set3 data(set3Idx,end)];
end