function [backoff] = createBackoffStruct(outputs,outputdims,doutput,doutput_dt)
% [backoff] = createBackoffStruct(outputs,outputdims,doutput,doutput_dt)
% create structure with backoff values (corresponding to worst-case deviations) at the current time instant for the desired MPET outputs, to be
% passed to MPET for the next iteration
%Inputs:
% outputs: cell array of strings, output names
% outputdims: array, dimension of each element in outputs
% doutput: backoff values (corresponding to worst-case deviations) at the
% current time instant for the desired MPET outputs  ("outputs")
% doutput_dt: time-derivative backoff values (corresponding to time-derivative of worst-case deviations) at the
% current time instant for the desired MPET outputs  ("outputs")
%Outputs:
% backoff: struct, fieldnames corresponding to outputs names ("outputs"). "_dt" is appended to indicate a derivative value
%%
    for i=1:length(outputs)
            backoff.([outputs{i}])=doutput(:,1:outputdims(i));
            backoff.([outputs{i},'_dt'])=doutput_dt(:,1:outputdims(i));
            doutput(:,1:outputdims(i))=[];
            doutput_dt(:,1:outputdims(i))=[];
    end
end

