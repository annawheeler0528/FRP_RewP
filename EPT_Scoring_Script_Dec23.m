function es_scoresingtrl_epts
%Function to score single-trial .ept files generated using the EP Toolkit.
%Script will output two files: one file with the single-trial measurements
%and another file with the measruements for single-subject averages.
%
%Last Modified: 3/30/18 (using EP Toolkit v2.64)
%
%Directions:
%In order to use this script, single-trial .ept files should be placed in a
%folder. The script will load all of the .ept files found in the folder, so
%be sure that only the files you want to load are located there. Note: do
%not mix file types (e.g., stimulus-locked and response-locked erp files).
%The script will simply score all of the .ept files it finds in the folder.
%
%All .ept files should be baseline adjusted and re-referenced using the
%Transform tool in the EP Toolkit PRIOR TO running this script.
%
%Also sometimes the toolbar does not show up for the window to specify the
%directory where the .ept files are. This is the first window that pops up
%for the user. Just choose where the .ept files to be loaded are located.
%
%This is a very simple script. It does not do anything fancy and will not 
%give you sensible errors. So, don't mess up :)
%

%Inputs
% The script pulls up a gui that asks the user for input
%
%Outputs
% The script saves an output file in a .csv format that contains all of the
%  single-trial scores for the ept files and another file that contaise all
%  of the single-subject average scores.
%
%
%Created by Peter Clayson (3/8/18)
%peter.clayson@gmail.com
%
%3/30/18 PC
% Adaptive mean was double the size intended. Fixed. (e.g., it used to take
%  30 ms before and after rather than splitting to 15 before and after.)
%
%10/27/23 PC
% Updated script to work with EP Toolkit v2.99

%ask the user to identify the data file to be loaded
wrkdir = uigetdir(cd,'Select the directory with single trial EPTs');

%if the user does not select a file, then take the user back to era_start
if wrkdir == 0
    es_scoresingtrl_epts;
    errordlg('No directory selected','Directory Error');
    return;
end

es_startgui(wrkdir);

end

function es_startgui(wrkdir,varargin)
%possible measurements
%mean, adpmean, peakamp, peaklat

ind = find(strcmp('inp',varargin),1);
if ~isempty(ind)
    prefs = varargin{ind+1};
    inp.wrkdir = prefs.wrkdir;
    inp.erpname = prefs.erpname;
    
    switch prefs.meas
        case 'mean'
            inp.typemeas = 1;
        case 'peakamp'
            inp.typemeas = 2;
        case 'adpmean'
            inp.typemeas = 3;
        case 'peaklat'
            inp.typemeas = 4;
    end
    
    switch prefs.pol
        case 'pos'
            inp.pol = 1;
        case 'neg'
            inp.pol = 2;
    end
    
    inp.chans = prefs.chans;
    inp.startwind = prefs.startwind;
    inp.endwind = prefs.endwind;
    inp.adpwind = prefs.adpwind;
    
else
    inp.wrkdir = wrkdir;
    inp.erpname = '';
    inp.typemeas = 1;
    inp.pol = 1;
    inp.chans = '';
    inp.startwind = '';
    inp.endwind = '';
    inp.adpwind = '';
end

%check if es_gui is open
es_gui = findobj('Tag','es_gui');
if ~isempty(es_gui)
    close(es_gui);
end

%define parameters for figure position
figwidth = 550;
figheight = 550;

%define space between rows and first row location
rowspace = 35;
row = figheight - rowspace*2;

%define locations of column 1 and 2
lcol = 30;
rcol = (figwidth/8)*5;
fsize = get(0,'DefaultTextFontSize')+2;


%create the gui
es_gui= figure('unit','pix',...
    'position',[400 400 figwidth figheight],...
    'menub','no',...
    'name','Specify Inputs',...
    'numbertitle','off',...
    'resize','off',...
    'tag','es_gui');

%Print the name of the gui
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','center',...
    'String','Score Single Trial Epts',...
    'Position',[0 row figwidth 25]);

%next row
row = row - (rowspace*1.5);

%Print the text for dependability cutoff with a box for the user to specify
%the input
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Directory with files:',...
    'Tooltip','Directory of files containing single-trial epts',...
    'Position', [lcol row figwidth/4 50]);

uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','right',...
    'String',inp.wrkdir,...
    'Tooltip','Directory of files containing single-trial epts',...
    'Position', [rcol-(figwidth/3) row figwidth/1.5 50]);

%increase distance between rows as some descriptions take up more than one
%line
rowspace = 50;
row = row - rowspace*.75;
rcol = (figwidth/4)*3;


%Name of the ERP measurement
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','ERP name',...
    'Tooltip','Label of the ERP to measure. E.g., ERN, N2, or P3',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(1) = uicontrol(es_gui,'Style','edit',...
    'fontsize',fsize,...
    'String',inp.erpname,...
    'Tooltip','Name of ERP component',...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

%Type of the ERP measurement
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Type of measurement',...
    'Tooltip','Label of the ERP to measure. E.g., ERN, N2, or P3',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(2) = uicontrol(es_gui,'Style','pop',...
    'fontsize',fsize,...
    'String',{'Mean Amplitude','Peak Amplitude','Adaptive Mean','Peak Latency'},...
    'Value',inp.typemeas,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

%Polarity of ERP
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Polarity of ERP Component',...
    'Tooltip','Polarity of ERP for measurements',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(3) = uicontrol(es_gui,'Style','pop',...
    'fontsize',fsize,...
    'String',{'Positive','Negative'},...
    'Value',inp.pol,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

%Channels for scoring
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Channel numbers to score (ROI okay)',...
    'Tooltip','Channels to score (e.g., 129 or 6 7 106 129)',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(4) = uicontrol(es_gui,'Style','edit',...
    'fontsize',fsize,...
    'String',inp.chans,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

%Beginning of ERP window
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Beginning of measurement window (msec)',...
    'Tooltip','Start of measurement window in ms',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(5) = uicontrol(es_gui,'Style','edit',...
    'fontsize',fsize,...
    'String',inp.startwind,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

%End of ERP window
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','End of measurement window (msec)',...
    'Tooltip','End of measurement window in ms',...
    'Position', [lcol row figwidth/2 25]);

inputs.h(6) = uicontrol(es_gui,'Style','edit',...
    'fontsize',fsize,...
    'String',inp.endwind,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace;

strtip = 'Size in ms. E.g., 30 would indicated 15 ms before and after the peak';

%Size of adaptive mean
uicontrol(es_gui,'Style','text','fontsize',fsize,...
    'HorizontalAlignment','left',...
    'String','Size of adaptive mean (if relevant, msec)',...
    'Tooltip',strtip,...
    'Position', [lcol row figwidth/2 25]);

inputs.h(7) = uicontrol(es_gui,'Style','edit',...
    'fontsize',fsize,...
    'String',inp.adpwind,...
    'Position', [rcol-50 row figwidth/3 25]);

%next row
row = row - rowspace*1.5;

%Create button that will load a new working directory
uicontrol(es_gui,'Style','push','fontsize',fsize,...
    'HorizontalAlignment','center',...
    'String','Load New Directory',...
    'Position', [1*figwidth/8 row figwidth/3 50],...
    'Callback',{@bb_call});

%Create button that will display preferences
uicontrol(es_gui,'Style','push','fontsize',fsize,...
    'HorizontalAlignment','center',...
    'String','Analyze',...
    'Position', [5*figwidth/8 row figwidth/3 50],...
    'Callback',{@checkinputs,'wrkdir',inp.wrkdir,'inp_lists',inputs});

end

function bb_call(varargin)

%check if es_gui is open (done with it)
es_gui = findobj('Tag','es_gui');
if ~isempty(es_gui)
    close(es_gui);
end

es_scoresingtrl_epts;
end

function checkinputs(varargin)

ind = find(strcmp('inp_lists',varargin),1);
inp = varargin{ind+1};

prefs = [];

ind = find(strcmp('wrkdir',varargin),1);
prefs.wrkdir = varargin{ind+1};

%name of the erp
prefs.erpname = inp.h(1).String;

%measurement to perform
switch inp.h(2).Value
    case 1
        prefs.meas = 'mean';
    case 2
        prefs.meas = 'peakamp';
    case 3
        prefs.meas = 'adpmean';
    case 4
        prefs.meas = 'peaklat';
end

%polarity of ERP
switch inp.h(3).Value
    case 1
        prefs.pol = 'pos';
    case 2
        prefs.pol = 'neg';
end

%channels to analyze
str = inp.h(4).String;
if contains(str, ' ')
    % Split the string based on spaces
    parts = strsplit(str, ' ');
    
    % Convert each part to double and store in a matrix
    prefs.chans = cellfun(@str2double, parts);
else
    % If no spaces, just convert the entire string to double
    prefs.chans = str2double(str);
end

%starting window of measurement
prefs.startwind = str2double(inp.h(5).String);

%end of window
prefs.endwind = str2double(inp.h(6).String);

%size of adpmean
prefs.adpwind = str2double(inp.h(7).String);

%check if es_gui is open (done with it)
es_gui = findobj('Tag','es_gui');
if ~isempty(es_gui)
    close(es_gui);
end

%prompt the user to indicate where the output should be saved
[savename, savepath] = uiputfile('*.csv',...
    'Save output file...');

%if the user does not select a file, then take the user back to es_gui
if savename == 0
    errordlg('Save location not specified','File Error');
    es_startgui(prefs.wrkdir,'inp',prefs);
    return;
end

prefs.savename = savename;
prefs.savepath = savepath;

scoreall('prefs',prefs);
end

function scoreall(varargin)
ind = find(strcmp('prefs',varargin),1);
prefs = varargin{ind+1};

%Grab the files from the specified working directory
rawfilesloc = dir(fullfile(prefs.wrkdir,'*.ept'));
nSub = length(rawfilesloc);
files = struct2cell(rawfilesloc)';
files = files(:,1);


%Specify necessary inputs for the EP Toolkit
global EPmain EPtictoc
EPmain.scrsz = [1 1 1680 1050];
EPmain.fontsize = 8;
EPmain.preferences.general.SMIsuffix = '_smi.txt';
EPmain.preferences.general.specSuffix = '_evt.txt';
EPmain.preferences.general.subjectSpecSuffix = '_sub.txt';
inputFormat = 'ep_mat';
averagingMethod = 'Average';
fileType = 'single_trial';
EPmain.preferences.average.trimLevel = .2500;
trimLevel = 0.25;
methodName = 'Mean';
smoothing = 0;
latencyName = [];
latencyMin = [];
latencyMax = [];
jitterChan = [];
jitterPolar = 1;
multiSessionSubject = [];

cfg = struct;
cfg.behav.ACC='no ACC';
cfg.behav.RT='no RT';
cfg.behav.codeCorrect='1';
cfg.behav.codeError='0';
cfg.behav.codeTimeout='2';
cfg.behav.dropBad=1;
cfg.behav.dropError=1;
cfg.behav.dropTimeout=1;
cfg.behav.minRT=100;
cfg.behav.maxRT=2;
cfg.behav.RTmethod='Median';

EPtictoc.start=[];
EPtictoc.step=1;
EPtictoc.stop=0;
ep_tictoc('begin');

started = 0;

%Cycle through and score each participant
for ii = 1:nSub
    fileloc = fullfile(prefs.wrkdir,char(files(ii)));
    
    %load ep dataset
    tempVar=load('-mat', fileloc);
        EPdata=tempVar.EPdata;
    
    %average the data so you can get a noise estimate for a participant
    warning('off','MATLAB:colon:nonIntegerIndex');
    EPtmplt = ep_averageData({fileloc},...
            inputFormat,fileType,...
            averagingMethod,trimLevel,methodName,smoothing,...
            [],1:4,[],cfg,...
            EPmain.preferences,'subject',[],3,0);
    warning('on','MATLAB:colon:nonIntegerIndex');
    
    noiseestimates = sqrt(squeeze(mean(mean(mean(EPtmplt.noise.^2,1),2),5)))';
    noise = struct;
    for n = 1:length(EPtmplt.cellNames)
        noise.(EPtmplt.cellNames{n}) = noiseestimates(n);
    end
    
    rawname = strsplit(files{ii},'.');
    subjid = rawname{1};
    
    individ = scoretrial(EPdata, prefs, subjid, noise);
    
    if started == 0
        master = individ;
        started = 1;
    else
        master = vertcat(master,individ); %#ok<AGROW>
    end
    
end

writetable(master,fullfile(prefs.savepath,prefs.savename));

ssa_long = grpstats(master,{'subjid','event'});

erp_wide = unstack(ssa_long,strcat('mean_',prefs.erpname),'event','GroupingVariables','subjid');
noise_wide = unstack(ssa_long,'mean_noise','event','GroupingVariables','subjid');

ssa_wide = innerjoin(erp_wide,noise_wide,'key','subjid');

cols = ssa_wide.Properties.VariableNames;
cols = strrep(cols,'erp_wide',prefs.erpname);
cols = strrep(cols,'noise_wide',strcat(prefs.erpname,'_noise'));

ssa_wide.Properties.VariableNames = cols;



writetable(ssa_wide,fullfile(prefs.savepath,strrep(prefs.savename,'.csv',...
    '_ssa.csv')));

disp('scoring finished');
clear EPmain EPtictoc

end

function individ = scoretrial(EPdata, prefs, subjid, noise)

for ii = 1:length(EPdata.cellNames)
    
    event = EPdata.cellNames(ii);
    
    if EPdata.analysis.badTrials(ii) == 0
        
        erp_out = zeros(0,length(prefs.chans));
        
        switch prefs.meas
            case 'mean'
                
                for chan = 1:length(prefs.chans)
                    
                    erp_out(chan) = mean(...
                        EPdata.data(prefs.chans(chan),...
                        knnsearch(EPdata.timeNames,prefs.startwind):...
                        knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    
                end
                
            case 'peakamp'
                
                for chan = 1:length(prefs.chans)
                    if strcmp(prefs.pol,'neg')
                        erp_out(chan) = min(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    elseif strcmp(prefs.pol,'pos')
                        erp_out(chan) = max(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    end
                end
                
            case 'adpmean'
                
                for chan = 1:length(prefs.chans)
                    if strcmp(prefs.pol,'neg')
                        [~,peak] = min(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    elseif strcmp(prefs.pol,'pos')
                        [~,peak] = max(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    end
                    erp_out(chan) = mean(...
                        EPdata.data(prefs.chans(chan),...
                        knnsearch(EPdata.timeNames,prefs.startwind)+...
                        peak-(prefs.adpwind/2):...
                        knnsearch(EPdata.timeNames,prefs.startwind)+...
                        peak+(prefs.adpwind/2),ii));
                end
                
            case 'peaklat'
                
                for chan = 1:length(prefs.chans)
                    if strcmp(prefs.pol,'neg')
                        [~,samp_loc] = min(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    elseif strcmp(prefs.pol,'pos')
                        [~,samp_loc] = max(...
                            EPdata.data(prefs.chans(chan),...
                            knnsearch(EPdata.timeNames,prefs.startwind):...
                            knnsearch(EPdata.timeNames,prefs.endwind),ii));
                    end
                    erp_out(chan) = EPdata.timeNames(...
                        knnsearch(EPdata.timeNames,prefs.startwind)...
                        + samp_loc);
                end
        end
        
        if length(erp_out) > 1
            erp_out = mean(erp_out);
        end

        if ~isempty(erp_out) & ~isnan(erp_out)

            if ~exist('individ','var')

                individ = table;
                individ.subjid = cellstr(subjid);
                individ.event = cellstr(event);
                individ.(prefs.erpname) = erp_out;
                individ.noise = noise.(char(event));

            elseif exist('individ','var')

                row = table;
                row.subjid = cellstr(subjid);
                row.event = cellstr(event);
                row.(prefs.erpname) = erp_out;
                row.noise = noise.(char(event));

                individ = vertcat(individ,row); %#ok<AGROW>

            end
        end
    end
end


end


