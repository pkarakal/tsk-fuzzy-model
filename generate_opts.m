function opt = generate_opts() 
    opt(1) = genfisOptions('GridPartition');
    opt(1).InputMembershipFunctionType = 'gbellmf';
    opt(1).NumMembershipFunctions = 2;
    opt(1).OutputMembershipFunctionType = 'constant'; %Singelton
    
    opt(2) = genfisOptions('GridPartition');
    opt(2).InputMembershipFunctionType = 'gbellmf';
    opt(2).NumMembershipFunctions = 3;
    opt(2).OutputMembershipFunctionType = 'constant';%Singelton
    
    opt(3) = genfisOptions('GridPartition');
    opt(3).InputMembershipFunctionType = 'gbellmf';
    opt(3).NumMembershipFunctions = 2;
    opt(3).OutputMembershipFunctionType = 'linear'; %Polynomial
    
    opt(4) = genfisOptions('GridPartition');
    opt(4).InputMembershipFunctionType = 'gbellmf';
    opt(4).NumMembershipFunctions = 3;
    opt(4).OutputMembershipFunctionType = 'linear';%Polynomial
end