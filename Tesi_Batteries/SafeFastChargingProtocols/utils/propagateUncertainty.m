function [dpsi_wc,Vpsi] = propagateUncertainty(r,L,Vtheta)
% [dpsi_wc,Vpsi] = propagateUncertainty(r,L,Vtheta)
% Propagate uncertainty from MPET parameters to MPET outputs using 1st order power series expansion
%Inputs:
% r: chi-squared value at the desired confidence level alpha (see @chi2inv)
% L: 3D array, sentisitity values for the selected MPET outputs ("outputs")  [1st dimension] with respect to each selected MPET parameter ("uncParams") [2nd dimension] at each
% instant of time ("time")  [3rd dimension]  (see @computeSensitivitiesFD)
% Vtheta: matrix, covariance of uncertain parameters distribution
%Outputs:
% dpsi_wc: matrix, worst-case variation in each output
% Vpsi: 3D array,  covariance of outputs distribution at each time instant
%%
Vpsi=nan(size(L,1),size(L,1),size(L,3));
dpsi_wc=nan(size(L,3),size(L,1));
for i=1:size(L,3)
    Vpsi(:,:,i)=L(:,:,i)*Vtheta*L(:,:,i)';
    dpsi_wc(i,:)=sqrt(r.*diag(Vpsi(:,:,i)))';
end

end

