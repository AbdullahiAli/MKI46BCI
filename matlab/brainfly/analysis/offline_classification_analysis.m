try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../utilities/initPaths
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

% N.B. only really need the header to get the channel information, and sample rate
buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

hdr.fsample = 250; % Manually override sampling frequency in debug mode
hdr.nchans = 10; % Manually override number of channels in debug mode
hdr.channel_names = {'TP9', 'P7', 'P3', 'Pz', ...
    'P4', 'P8', 'TP10', 'O1', 'Oz', 'O2'}; % channels to record from
hdr.labels = {'target', 'non-target'}; % labels of trials


% Constants
capFile='Capfile_hybrid.txt';
overridechnm=1; % capFile channel names override those from the header!
prompt = 'specify name of data to be loaded\n';
dname = strcat('data/',input(prompt, 's'));
cname  ='clsfr';
load(dname);
hdr.nevents= length(devents); % Manually override nevents in debug mode

% train classifier
clsfr=buffer_train_erp_clsfr(data,devents,hdr,'spatialfilter','ssep','freqband',[1 10 15 25],'badchrm',0,'capFile',capFile,'overridechnms',overridechnm);


