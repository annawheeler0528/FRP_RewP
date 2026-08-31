function prefs = setArtifactCorrectPrefs_sc_set
%setArtifactCorrectPrefs defines the preferences to be used for running
%files in parallel using the ERP PCA toolkit. This scripts is called by
%artifactCorrecetParallel to pull its preferences for processing.
%
%setArtifactCorrectPrefs
%
%Input:
%   The script call requires no inputs
%   Changes to inputs are made directly below. Each preference has a
%    description just above it with recommended settings.
%
%Output:
%   prefs - A cell strcture containing preferences for the ERP PCA Toolkit
%

%History
% by Peter Clayson (11/2/15)
% peter.clayson@gmail.com
%Add in the manually defined inputs in artifactCorrectParallel
% (descriptions at the end of this script)
%05/26/20
% changes to run on EP Toolkit v 2.89 (had to make a bunch of changes to
%  run ep_artifactCorrect to remove global variables)

%create an empty structure array where artifact correct preferences will be
%stored
prefs = struct;

%*************************************************************************%
%Things you MUST change:
%*************************************************************************%
     %path and name of the blink file if using the FileTemplate or
    %bothTemplate options. This template must be created before running the
    %scripts. Be sure to save the template with a .mat suffix.
    prefs.blinkFile = '/fslhome/awheel28/EP_templates/blinks_adult.mat';

    %path and name of the saccade file if using the FileTemplate option.
    %This template must be created before running the scripts. Be sure to
    %save the template with a .mat suffix.
    prefs.saccadeFile = '/fslhome/awheel28/EP_templates/saccades_adult.mat';

%*************************************************************************%
%Things you want to think about changing
%*************************************************************************%

    %input file format. Options are 'ep_mat' for ept and 'egi_egis' for EGIS files.
    prefs.inputFormat = 'eeglab_set';

    %input file type. Should be 'single_trial'.
    prefs.type = 'single_trial';

    %output file format. Options are 'ep_mat' for ept and 'egi_egis' for EGIS files.
    prefs.outputFormat = 'ep_mat';

    %array of sample numbers to permanently baseline correct the trials with.
    %[] means don't correct. (default: [])
    prefs.baseline = 1:50; %250Hz

    %followed by source of blink template (fileTemplate: load blink format file
    %autoTemplate: automatically generate blink template
    %bothTemplate: use both file and automatic template at the same time)
    %(default: autotemplate)
    prefs.template = 'bothTemplate';

    %source of saccade template (fileTemplate: load saccade format file.
    %(default: fileTemplate)
    prefs.sacctemplate = 'bothTemplate';

    %Number of timepoints to read in.  Roughly 100000 per GB of memory available.
    %(default: 100,000)
    %Setting a somewhat arbitrarily large numbers means the EP toolkit will
    %just use as much memory as it needs
    prefs.chunkSize = 10000000;

    %Minimum number of good trials per cell to avoid warning message.
    %(default: 15)
    prefs.minTrialsPerCell = 1;

    %1 to disable summary figures of artifact detection
    %(to help cope with low memory situations).
    prefs.noFigure = 0;

    %structured array with EOG channels
    %(LUVEOG, RUVEOG, LLVEOG, RLVEOG, LHEOG, RHEOG)
    %(default: [] to autodetect)
    prefs.eog  = [25 8 127 126 128 125];

    %Current reference channel (if needed)
    prefs.currReference = 129;

%*************************************************************************%
%Things you probably don't need to change
%*************************************************************************%
    %array of sample numbers to retain.
    %[] means don't drop any timepoints. (default: [])
    prefs.timePoints = [];

    %range of non-saturated data values (default: -1000 to +1000)
    prefs.saturation = [-1000 1000];

    %moving average window for smoothing during bad channel detection only
    %(default: 80 ms)
    prefs.window = 80;

    %difference from minimum to maximum for bad channel (default: 100  v)
    prefs.minmax = 100;

    %percent of bad channels exceeded to declare bad trial, rounding down
    %(default: 10)
    prefs.badnum = 15;

    %number of electrodes considered to be neighbors (default: 6)
    prefs.neighbors = 6;

    %maximum microvolt difference allowed from best matching neighbor
    %(default: 30  v)
    prefs.maxneighbor = 30;

    %minimum predictability from neighbors to not be considered
    %globally bad (default: .4)
    prefs.badchan = .4;

    %threshold correlation with blink template, 0 to 1 (default: .9)
    prefs.blink = .9;

    %threshold correlation with saccade template, 0 to 1 (default: .8)
    prefs.saccade = .8;

    %uv Saccade Fac is the minimum HEOG voltage difference required to
    %constitute a possible saccade. (default: 20)
    prefs.saccademin = 20;

    %difference from minimum to maximum for bad trial (default: 200  v)
    prefs.trialminmax = 100;

    %1 to detrend. 0 to not.  Helpful for very noisy data but can result in
    %late effects being distributed across the entire epoch so otherwise
    %not recommended.
    prefs.detrend = 0;

    %percentage of good trials chan is bad to declare a channel
    %globally bad (default: 20)
    prefs.badtrials = 20;

    %'replace' to interpolate bad channels, 'mark' to mark them with a
    %spike, and 'none' to do nothing.
    prefs.channelMode = 'replace';

    %'fix' to fix bad trial data and 'none' to do nothing.
    %This is motion correction. (default: fix)
    prefs.trialMode = 'fix';

    %1 to not allow adjacent bad channels
    %(trial or subject declared bad) (default: 1)
    prefs.noadjacent = 0;

    %number of factors to retain during movement correction.
    prefs.movefacs = 20;

    %How to identify artifacts
    %(automatic: use automatic criteria and enter marks into file)
    prefs.editMode = 'both';

    %Use BSS-CCA for EMG correction (1-yes, 0-no; default: 0, need at
    %least 1kHz sampling rate)
    prefs.EMG = 0;

    %minimum ratio of signal power to EMG ratio to retain during EMG
    %correction (default: 9)
    prefs.EMGratio = 9;

    %the hertz threshold considered to be the lower bound of possible
    %of EEG frequencies during EMG correction (default: 15)
    prefs.EMGthresh = 15;

    %threshold for saccade potential detection (default: 2)
    prefs.sacpot = 2;

    %Remove alpha using CWA-PCA
    %default = 0; (off)
    prefs.alpha = 0;

%*************************************************************************%
%Things that only get set if they're non-standard (i.e., only include them
%if you need to specify something out of the ordinary).
%*************************************************************************%

    %1 to perform gradient and ballistocardiogram artifact corrections
    %(default: 0).
    prefs.fMRI = 0;

    %size of the screen
    prefs.scrsz = [1 1 1680 1050];

    %Subject specific suffix
    %(something used by EP toolkit, not needed)
    prefs.subjectSpecSuffix = '_sub.txt';

    %spec suffix
    prefs.specSuffix = '_evt.txt';

    %smi suffix
    prefs.smisuffix = '_smi.txt';

    %font size
    prefs.fontsize = 10;

    %textprefs for reading data from text files
    textprefs = struct;
    textprefs.firstRow = 1;
    textprefs.lastRow = 0;
    textprefs.firstCol = 1;
    textprefs.lastCol = 0;
    textprefs.orientation = 1;
    textprefs.sampleRate = 500;
    prefs.textprefs = textprefs;

    %
    prefs.elecPrefs=1;

end
