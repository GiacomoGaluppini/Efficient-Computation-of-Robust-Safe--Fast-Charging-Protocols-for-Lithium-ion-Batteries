function [outputs] = addVolPartOutput2SensAnalysis(outputs,outputname,electrodestr,Nvol,Npart)
%  [outputs] = addVolPartOutput2SensAnalysis(outputs,outputname,electrodestr,Nvol,Npart)
% add a set of "distributed" outputs to the list of outputs to be included in the sensitivity analysis
% Distributed output = output spanning over multipe volumes and/or
% particles (see MPET documentation)
%Inputs:
% outputs: cell array of strings, output names
% outputname: string, main name of "distributed" output to be included in "outputs"
% electrodestr: string, code of electrode (a,c,s)
% Nvol: scalar, number of volumes
% Npart: scalar, number of particles per volume
%Outputs:
% outputs: cell array of strings, output names, updated with the new ones
%%
electrodestr=lower(electrodestr);
for i=0:Nvol-1
    for j=0:Npart-1
        tmp=['partTrode',electrodestr,'vol',num2str(i),'part',num2str(j),'_',outputname];
        outputs{end+1}=[tmp];
    end
end

end

