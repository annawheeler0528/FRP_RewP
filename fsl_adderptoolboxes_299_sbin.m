function fsl_adderptoolboxes_299_sbin
%
%Add erp toolboxes to Matlab path. 
%
%No input/output required
%The newer eeglab and fieldtrip toolboxes cannot have paths added manually.
%Running this script will add the paths correctly.

addpath('~/fieldtrip-20230716');
ft_defaults;

addpath(genpath('~/eeglab2023'));

addpath(genpath('~/EP_Toolkit_299_sbin'));
ep;

ep_tictoc('begin');

EPmain.scrsz = [1 1 1680 1050];

