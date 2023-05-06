function [Uncertainty] = createUncertaintyStruct(outputs,outputdims,doutput)
% [Uncertainty] = createUncertaintyStruct(outputs,outputdims,doutput)
% create structure with worst-case deviations for the desired MPET outputs, up to the current time instant
%Inputs:
% outputs: cell array of strings, output names
% outputdims: array, dimension of each element in outputs
% doutput:  worst-case deviations for the desired MPET outputs ("outputs") up to the
% current time instant 
%Outputs:
% Uncertainty: struct, fieldnames corresponding to outputs names ("outputs").
%%
    for i=1:length(outputs)
            Uncertainty.([outputs{i}])=doutput(:,1:outputdims(i));
            doutput(:,1:outputdims(i))=[];
    end
end

