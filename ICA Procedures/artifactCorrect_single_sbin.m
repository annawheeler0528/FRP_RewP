function artifactCorrect_single_sbin(file)
%runs the ERP PCA Toolkit for ERP processing (designed for cluster)
%
%artifactCorrect_single(file)
%
%Input:
%  file - location of file to be processed
%
%Output:
%  This function does not output any variables to the Matlab workspace. The
%   processed files will be saved with the original file
%


%Function to run Joe Dien's ERP PCA Toolkit artifact correction. This
%runs the artifact correction script an individual subject.
%The script runs eyeblink correction (using ICA), motion and saccade correction
%(using PCA), and it performs bad channel replacement.
%
%Custom scripts called
%  setArtifactCorrectPrefs - script containing all preferences used for
%   data processing. Location of this file is assumed to be in the home
%    directory for the supercomputer user
%  fsl_adderptoolboxes - script for adding the toolboxes to the Matlab path

%History
% by Peter Clayson (10/6/17)
% peter.clayson@gmail.com
%
%8/29/18 PC
% made changes to allow for selecting different artifactcorrectprefs based
%  on prefixes bdf, mmf, cnt for multisite anxiety replication study

%load necessary toolboxes
fsl_adderptoolboxes_299_sbin;

%load the preference file to define parameters for processing
%path and name of the function are specified in prefslocation
prefs = setArtifactCorrectPrefs_sc_sbin;
 
%Define input arguments so the ERP PCA Toolkit can read them. The EP
%toolkit uses somersaulting so each parameter will be preceded by the
%appropriate keyword

global EPmain

EPmain.preferences.advanced.parallel = 0;

inArg{1}='format';
inArg{end+1}=prefs.inputFormat;
inArg{end+1}='type';
inArg{end+1}=prefs.type;
inArg{end+1}='outputFormat';
inArg{end+1}=prefs.outputFormat;
inArg{end+1}='template';
inArg{end+1}=prefs.template;
inArg{end+1}='channelMode';
inArg{end+1}=prefs.channelMode;
inArg{end+1}='saturation';
inArg{end+1}=prefs.saturation;
inArg{end+1}='window';
inArg{end+1}=prefs.window;
inArg{end+1}='minmax';
inArg{end+1}=prefs.minmax;
inArg{end+1}='badnum';
inArg{end+1}=prefs.badnum;
inArg{end+1}='saccademin';
inArg{end+1}=prefs.saccademin;
inArg{end+1}='neighbors';
inArg{end+1}=prefs.neighbors;
inArg{end+1}='maxneighbor';
inArg{end+1}=prefs.maxneighbor;
inArg{end+1}='badchan';
inArg{end+1}=prefs.badchan;
inArg{end+1}='blink';
inArg{end+1}=prefs.blink;
inArg{end+1}='badtrials';
inArg{end+1}=prefs.badtrials;
inArg{end+1}='chunkSize';
inArg{end+1}=prefs.chunkSize;
inArg{end+1}='minTrialsPerCell';
inArg{end+1}=prefs.minTrialsPerCell;
inArg{end+1}='noadjacent';
inArg{end+1}=prefs.noadjacent;
inArg{end+1}='trialMode';
inArg{end+1}=prefs.trialMode;
inArg{end+1}='trialminmax';
inArg{end+1}=prefs.trialminmax;
inArg{end+1}='movefacs';
inArg{end+1}=prefs.movefacs;
inArg{end+1}='noFigure';
inArg{end+1}=prefs.noFigure;
inArg{end+1}='saccTemplate';
inArg{end+1}=prefs.sacctemplate;
inArg{end+1}='saccadeFile';
inArg{end+1}=prefs.saccadeFile;
inArg{end+1}='saccade';
inArg{end+1}=prefs.saccade;
inArg{end+1}='eog';
inArg{end+1}=prefs.eog;
inArg{end+1}='editMode';
inArg{end+1}=prefs.editMode;
inArg{end+1}='detrend';
inArg{end+1}=prefs.detrend;
inArg{end+1}='fMRI';
inArg{end+1}=prefs.fMRI;
%inArg{end+1}='elecPrefs';
%inArg{end+1}=prefs.elecPrefs;
inArg{end+1}='baseline';
inArg{end+1}=prefs.baseline;
% inArg{end+1}='timePoints';
% inArg{end+1}=prefs.timePoints;
inArg{end+1}='blinkFile';
inArg{end+1}=prefs.blinkFile;
inArg{end+1}='currReference';
inArg{end+1}=prefs.currReference;
inArg{end+1}='screenSize';
inArg{end+1}=prefs.scrsz;
inArg{end+1}='subjectSpecSuffix';
inArg{end+1}=prefs.subjectSpecSuffix;
inArg{end+1}='specSuffix';
inArg{end+1}=prefs.specSuffix;
inArg{end+1}='EMG';
inArg{end+1}=prefs.EMG;
inArg{end+1}=prefs.EMGratio;
inArg{end+1}=prefs.EMGthresh;
inArg{end+1}='sacpot';
inArg{end+1}=prefs.sacpot;
inArg{end+1}='textPrefs';
inArg{end+1}=prefs.textprefs;
inArg{end+1}='SMIsuffix';
inArg{end+1}=prefs.smisuffix;
inArg{end+1}='FontSize';
inArg{end+1}=prefs.fontsize;
inArg{end+1}='alpha';
inArg{end+1}=prefs.alpha;
inArg{end+1}='noFigure';
inArg{end+1}=prefs.noFigure;
inArg{end+1}='eogMethod';
inArg{end+1}='ICA';
inArg{end+1}='SPmethod';
inArg{end+1}='Infomax';
inArg{end+1}='blinkMethod';
inArg{end+1}='Infomax';
inArg{end+1}='saccMethod';
inArg{end+1}='Infomax';
inArg{end+1}='SPtemplate';
inArg{end+1}='autoTemplate';
%inArg{end+1}='chunkSize';
%inArg{end+1}=1000000000000;

inArg{end+1} = 'files';

%**************************************************************************
%Process data in ERP PCA Toolkit
%**************************************************************************

%Start the timer for the whole run
t1 = tic;

disp('*************************************************************************');
disp(['Working on ' file ' at ' datestr(now)]);
disp('*************************************************************************');

inArgComplete = {inArg{:}, cellstr(file)};     %#ok<CCAT>

ep_artifactCorrection(inArgComplete{:});


%Stop the timer and display a message about the time
t2 = toc(t1);
tMinutes = round(t2/60);

disp('*************************************************************************');
disp(['It took ' num2str(tMinutes) ' minutes to process']);
disp('*************************************************************************');


end
