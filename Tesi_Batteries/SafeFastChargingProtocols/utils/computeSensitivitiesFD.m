function [L] = computeSensitivitiesFD(MultiPathStruct_p,MultiPathStruct_m,stepPercent,uncParamsVals,uncParamsTypes,uncParams,outputs,outputdims,time)
% [L] = computeSensitivitiesFD(MultiPathStruct_p,MultiPathStruct_m,stepPercent,uncParamsVals,uncParamsTypes,uncParams,outputs,outputdims,time)
% Compute sensitivities of the desired outputs of MPET, with respect to the
% desired parameters of MPET, at the desired time instants
%Inputs:
% MultiPathStruct_p: struct array, with reuired paths to python, mpetrun and mpetplot,
% as well as paths to configuration folders and configuration filenames (see @createMultipleConfigFolders4FD)
% MultiPathStruct_m: struct array, with reuired paths to python, mpetrun and mpetplot,
% as well as paths to configuration folders and configuration filenames (see @createMultipleConfigFolders4FD)
% stepPercent: scalar in (0;1), size of perturbation (as percentage of central value) to be used for central finite
% difference derivative approxiation
% uncParamsVals: array or cell array of scalars,  parameter values
% uncParamsTypes: cell array of strings, parameter file identifier (A,C,M)
% uncParams: cell array of strings, parameter names
% outputs: cell array of strings, output names
% outputdims: array, dimension of each element in outputs
% time: array, time instants at which evaluate the MPET outputs (by interpolation/extrapolation if necessary)
%Outputs:
% L: 3D array, sentisitity values for the selected MPET outputs ("outputs")  [1st dimension] with respect to each selected MPET parameter ("uncParams") [2nd dimension] at each
% instant of time ("time")  [3rd dimension] 
%%
H_plus=nan(size(uncParamsVals));
H_minus=nan(size(uncParamsVals));
    
parfor i=1:length(uncParamsVals)%parfor
    
    p_plus=uncParamsVals;
    H_plus(i)=uncParamsVals(i)*stepPercent;
    p_plus(i)=uncParamsVals(i)+H_plus(i);

    [tmp_plus{i}]=runMPETandRead(MultiPathStruct_p(i),p_plus,uncParams,uncParamsTypes,outputs,time);  
    
end

parfor i=1:length(uncParamsVals)%parfor
    
    p_minus=uncParamsVals;
    H_minus(i)=uncParamsVals(i)*stepPercent;
    p_minus(i)=uncParamsVals(i)-H_minus(i);
    
    [tmp_minus{i}]=runMPETandRead(MultiPathStruct_m(i),p_minus,uncParams,uncParamsTypes,outputs,time);   
    
end

y_plus=[];
y_minus=[];
for i=1:length(uncParamsVals)
    y_plus=cat(2,y_plus,tmp_plus{i});
    y_minus=cat(2,y_minus,tmp_minus{i});
end

L=nan(size(y_plus));
for i=1:length(uncParamsVals)
        L(:,i,:)=(y_plus(:,i,:)-y_minus(:,i,:))./(H_plus(i)+H_minus(i));
end

end

function [y]=runMPETandRead(PathStruct,uncParamsVals,uncParams,uncParamsTypes,outputs,time)
% [y]=runMPETandRead(PathStruct,uncParamsVals,uncParams,uncParamsTypes,outputs,time)
% Run MPET simulation and read the desired outputs
%Inputs:
% PathStruct: struct, with reuired paths to python, mpetrun and mpetplot,
% as well as paths to configuration folders and configuration filenames (see @setPaths)
% uncParamsVals: array or cell array of scalars,  parameter values
% uncParamsTypes: cell array of strings, parameter file identifier (A,C,M)
% uncParams: cell array of strings, parameter names
% outputs: cell array of strings, output names
% time: array, time instants at which evaluate the MPET outputs (by interpolation/extrapolation if necessary)
%Outputs:
% y: 3D array,  selected MPET outputs ("outputs") [1st dimension] at each
% instant of time ("time") [3rd dimension]. 2nd dimension is still empty here, and will be used 
% to accomodate outputs resulting from different parameter perturbations
%%

[uncParamsStruct] = createParamStruct(uncParamsVals,uncParams,uncParamsTypes);
setConfigurationFiles(PathStruct,uncParamsStruct);

verbose=0;
[status] = runMPET(PathStruct,0,verbose);

if status~=0
    error('Error running MPET in FD')
end

load([PathStruct.outputFolder,'/output_data.mat'])
[this_t,idxa]=unique(phi_applied_times);


y=[];
for i=1:length(outputs)
    nome=outputs{i};
    x=eval(nome);
    
    if size(x,1)==1
    x = interp1(this_t,x(idxa),time,'linear','extrap');
    else
        x = interp1(this_t,x(idxa,:),time,'linear','extrap');
    end
    
    tmp=reshapeOutput(x);
    y=cat(1,y,tmp);
end

    
end

function [y] = reshapeOutput(y)
% [y] = reshapeOutput(y)
% reshape the output from 2D to 3D 
%Inputs:
% y: matrix,  selected MPET outputs ("outputs") [1st dimension] at each
% instant of time ("time") [2nd dimension]. 
%Outputs:
% y: 3D array,  selected MPET outputs ("outputs") [1st dimension] at each
% instant of time ("time") [3rd dimension]. 2nd dimension is still empty here, and will be used 
% to accomodate outputs resulting from different parameter perturbations
%%
if size(y,1)==1
    y=y';
    yold=y;
    y=permute(yold,[2 3 1]);
else
    yold=y;
    y=permute(yold,[2 3 1]);
end
end

