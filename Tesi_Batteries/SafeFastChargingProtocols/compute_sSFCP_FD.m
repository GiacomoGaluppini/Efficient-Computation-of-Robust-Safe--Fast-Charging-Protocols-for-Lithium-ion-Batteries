close all
clear all
clc

timetag=datestr(datetime(now,'ConvertFrom','datenum'),30);
%% script options
user='giek'

noBackoff=0;
resumeComputations=0;

parallelizza=true;
%% paths
if resumeComputations==0
    [PathStruct,MainFolder] = setPaths(user,'./configA123_optimalcontrol');
    
    switch user
        case 'giek'
            PathStruct.outputFolder_absPath='D:\Dropbox (Personale)\Tesi_Batteries\SafeFastChargingProtocols\simout';
        case 'braatz'
            PathStruct.outputFolder_absPath='C:\Users\galuppin\Documents\MATLAB\Tesi_Batteries\SafeFastChargingProtocols\simout';
        case 'tower'
            PathStruct.outputFolder_absPath='C:\Users\Windows\Documents\MATLAB\Tesi_Batteries\SafeFastChargingProtocols\simout';
        case 'towerdropbox'
            PathStruct.outputFolder_absPath='C:\Users\Windows\Dropbox\Tesi_Batteries\SafeFastChargingProtocols\simout';
    end
    
    statusFile=[MainFolder,'\SafeFastChargingProtocols\SimulationStatus.mat'];

    [PathStruct] = createTmpConfigFolder(PathStruct);
    
    
    addpath(genpath(MainFolder))
    cd([MainFolder,'\SafeFastChargingProtocols'])
    
    rmpath(genpath(PathStruct.historyFolder))
    
    
    %% READ SPECS
    
    [Nvol_a,Nvol_c,Nvol_s,Npart_a,Npart_c,ffrac_Tend,tend,tramp] = readConfigParams([PathStruct.configFolder,'\',PathStruct.configFileMain],...
        'Nvol_a','Nvol_c','Nvol_s','Npart_a','Npart_c','ffrac_Tend','tend','tramp');
    
    %% setup uncertainty propagation
    
    run setupUncertaintyPropagation.m
    
    [MultiPathStruct_p,MultiPathStruct_m]=createMultipleConfigFolders4FD(PathStruct,length(uncParams));
    setParam4FD(MultiPathStruct_p,MultiPathStruct_m,...
        {'CCsegments','false',1},{'profileType','useSA','tramp'},{'M','M','M'});

    checkpoint=3;
    itercount=1;
    last_t=0;
    n_samp_old=0;
    I_ref=nan;
    t_ref=nan;
    save(statusFile)
else
    statusFile=['SimulationStatus.mat'];
    load(statusFile)
end

%% setup parallel computations
if parallelizza
delete(gcp('nocreate'))
poolsize=min(4,length(uncParams))
parpool(poolsize);
else
    poolsize=1;
end
%%
while true
    %% preliminary + run master MPET sim
    if checkpoint==3
        
        if itercount==1
            activateBackoff(PathStruct,1)
            activateBackoff4FD(MultiPathStruct_p,MultiPathStruct_m,1);
            setOutFolderAsPrevDir(PathStruct,1)
            setOutFolderAsPrevDir4FD(MultiPathStruct_p,MultiPathStruct_m,1);
            
            tend=1;
            tsteps=max(2,ceil(2*tend));
            setParam(PathStruct,[tend,tsteps],{'tend','tsteps'},{'M','M'})
            setParam4FD(MultiPathStruct_p,MultiPathStruct_m,[tend,tsteps],{'tend','tsteps'},{'M','M'})
            
            clearOutputFolder=1; 
        end
        
        if itercount==2
            setOutFolderAsPrevDir(PathStruct,0);
            setOutFolderAsPrevDir4FD(MultiPathStruct_p,MultiPathStruct_m,0);
            
            if noBackoff==0
            activateBackoff(PathStruct,0);
            end
            
            
            tend=0.5;
            tsteps=2;
            setParam(PathStruct,[tend,tsteps],{'tend','tsteps'},{'M','M'})
            setParam4FD(MultiPathStruct_p,MultiPathStruct_m,[tend,tsteps],{'tend','tsteps'},{'M','M'})
            

            clearOutputFolder=0;
        end
        
        %master simulation
        verbose=0;
        [status] = runMPET(PathStruct,clearOutputFolder,verbose);
        
        load([PathStruct.outputFolder,'/output_data.mat'],'ffrac_a','phi_applied_times','last_constraint','current')

        
        if last_t==phi_applied_times(end) || status~=0
            open([PathStruct.configFolder,'/null'])
            warning('Error in MPET!!')
            keyboard
        end
        
        checkpoint=1;
        save(statusFile)

    end
    

    %% local, central finite difference sensitivity analysis and backoff
    
    if checkpoint==1
     
        if isnan(I_ref)
            [tt,~,I] = readDischargeCurve(PathStruct);
            I_ref=mean(I./current','omitnan');
            t_ref=mean(tt./phi_applied_times','omitnan');
            if isnan(I_ref)
                keyboard
            end
        end
        
        n_samp=length(current)-n_samp_old;
        
        timeS=phi_applied_times(end-n_samp+1:end)-phi_applied_times(end-n_samp+1);
        currentS=current(end-n_samp+1:end)*I_ref;
       
        timeS=timeS*t_ref/60;
        
        duration=diff(timeS);
        idxZero=find(duration==0);
        duration(idxZero)=[];
        currentS(idxZero)=[];
        
        segments.values=currentS;
        segments.duration=[duration timeS(end)-sum(duration)];
        
        setParam4FD(MultiPathStruct_p,MultiPathStruct_m,{segments},{'segments'},{'M'})
        
        stepPercent=10e-3;
        L=computeSensitivitiesFD(MultiPathStruct_p,MultiPathStruct_m,stepPercent,uncParamsVals,uncParamsTypes,uncParams,outputs,outputdims,phi_applied_times);
        [doutput] = propagateUncertainty(r,L,Vtheta);
    
        if noBackoff==0
            
            dout_bo=doutput(end,:);
            
            %%% STD DERIVATIVE
            dout_bo_old=doutput(end-n_samp+1,:);
           
            dt=tend/t_ref; 
            dout_bo_dt=(dout_bo-dout_bo_old)/dt;
                        
            
            if sum(isnan(dout_bo))>0
                keyboard
            end
           
            
            [backoff] = createBackoffStruct(outputs,outputdims,dout_bo,dout_bo_dt);
            save([PathStruct.configFolder,'/backoffs.mat'],'backoff')
            
        end
        
        checkpoint=2;
        save(statusFile)
        
        
    end
    
    %% save uncertainty 
    
    if checkpoint==2
        
        [uncertainty] = createUncertaintyStruct(outputs,outputdims,doutput);
        uncertainty.time=phi_applied_times;
        
        save([PathStruct.outputFolder,'/uncertainty.mat'],'uncertainty')
        save([PathStruct.configFolder,'/uncertainty.mat'],'uncertainty')
        
        if sum(last_constraint>=2)>0 && tramp>0
             setParam(PathStruct,0,{'tramp'},{'M'})
        end

        
        if length(ffrac_a)~=length(uncertainty.current)
            warning('Uncertainty samples misalignment')
            keyboard
        end
        
        display(['t=',num2str(phi_applied_times(end)*t_ref),' ffrac=',num2str(ffrac_a(end)),'/',num2str(ffrac_Tend),...
            '  iter=',num2str(itercount),...
            ' OM=',num2str(last_constraint(end))])
        
        n_samp_old=length(current);
        last_t=phi_applied_times(end);
        itercount=itercount+1;
        
        checkpoint=3;
        save(statusFile)
        
        test__Current4FD(length(uncParams),666)
        
                
        if ffrac_a(end)>=ffrac_Tend
            display('Done!!')
            break
        end
        

    end
    
end

status = copyfile('parameter_uncertainty', PathStruct.outputFolder);
status = copyfile(PathStruct.outputFolder, [PathStruct.outputFolder,'_',timetag]);
