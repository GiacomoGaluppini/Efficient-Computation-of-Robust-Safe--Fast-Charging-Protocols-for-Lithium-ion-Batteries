'''
Created on 13 apr 2022

@author: Giek
'''

import numpy as np
import scipy.io 


class BO_set:
    '''
    classdocs
    '''
    def __init__(self, config):
        
        if config['useBackoff']:
            mainfolder=config.path
            self.backoffs = self.load_backoff_file(mainfolder+'/'+config['backoffFile'])
        else:
            self.backoffs =  self.load_no_backoff(config)
        
    def load_backoff_file(self,path2file):
            
            mat = scipy.io.loadmat(path2file,struct_as_record=True)
            
            vals=mat['backoff'][0,0]
            keys=mat['backoff'][0,0].dtype.descr
            
            # Assemble the keys and values into variables with the same name as that used in MATLAB
            backoffs = {}
            for i in range(len(keys)):
                key = keys[i][0]
                val = np.squeeze(vals[key])  # squeeze is used to covert matlab (1,n) arrays into numpy (1,) arrays. 
                backoffs[key] = val
                
            return backoffs
     
    def load_no_backoff(self, config):   

        Nvol = config["Nvol"]
        Npart = config["Npart"]
        trodes = config["trodes"]
        
        backoffs = {}
        
        backoffs['phi_applied']=.0
        backoffs['current']=.0
        backoffs['Tavg']=.0
        backoffs['power']=.0
        backoffs['c_lyte_a']=np.zeros(Nvol['a'],dtype=float)
        backoffs['c_lyte_c']=np.zeros(Nvol['c'],dtype=float)
        
        backoffs['phi_applied_dt']=.0
        backoffs['current_dt']=.0
        backoffs['Tavg_dt']=.0
        backoffs['power_dt']=.0
        backoffs['c_lyte_a_dt']=np.zeros(Nvol['a'],dtype=float)
        backoffs['c_lyte_c_dt']=np.zeros(Nvol['c'],dtype=float)
          
        for trode in trodes:
            Nv = Nvol[trode]
            Np = Npart[trode]
            for vInd in range(Nv):
                for pInd in range(Np):
                    key='partTrode'+trode+'vol'+str(vInd)+'part'+str(pInd)+'_cbar'
                    backoffs[key]=.0
                    backoffs[key+'_dt']=.0
                    if trode=='a':
                        key='partTrode'+trode+'vol'+str(vInd)+'part'+str(pInd)+'_etaPlating'
                        backoffs[key]=.0 
                        backoffs[key+'_dt']=.0  
        
        return backoffs
        
        
        
        