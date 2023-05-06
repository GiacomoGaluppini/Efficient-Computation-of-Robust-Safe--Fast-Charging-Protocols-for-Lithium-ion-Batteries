%% setup uncertain params

% alfa=0.05;
alfa=0.01;


uncParams={'h_h','k0','c0','V_nuc'};
uncParamsVals=[1,40,1100,0.06];
uncParamsTypes={'M','A','M','A'};

% Vtheta=blkdiag(0.025,5,50,0.0005);

stddeviats=[0.9,20,100,0.01];
Vtheta=diag(stddeviats.^2);

r=chi2inv(1-alfa,length(uncParams));

save('parameter_uncertainty')

figure(1992)
for i=1:length(uncParams)
    subplot(1,length(uncParams),i)
    xx = linspace(uncParamsVals(i)-3*stddeviats(i),uncParamsVals(i)+3*stddeviats(i),1e3);
    yy = normpdf(xx,uncParamsVals(i),stddeviats(i));
    plot(xx,yy)
    title([uncParams{i},' ',uncParamsTypes{i}])
end


%% setup outputs

outputs={'phi_applied','current','power','Tavg'};

[outputs] = addVolPartOutput2SensAnalysis(outputs,'etaPlating','a',Nvol_a,Npart_a);

outputs=[outputs {'c_lyte_a','c_lyte_c'}];

[outputs] = addVolPartOutput2SensAnalysis(outputs,'cbar','a',Nvol_a,Npart_a);
[outputs] = addVolPartOutput2SensAnalysis(outputs,'cbar','c',Nvol_c,Npart_c);

outputdims=[1 1 1 1 ones(1,Nvol_a*Npart_a) Nvol_a Nvol_c ones(1,Nvol_a*Npart_a) ones(1,Nvol_c*Npart_c)];



