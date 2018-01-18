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
hdr.fsample = 250;
hdr.fSample = 250;
hdr.nChans = 10;
hdr.nchans = 10;
hdr.channel_names = {'TP9', 'P7', 'P3', 'Pz', ...
    'P4', 'P8', 'TP10', 'O1', 'Oz', 'O2'};
hdr.labels = {'left', 'right'};


% Constants
capFile='Capfile_hybrid.txt';
overridechnm=1; % capFile channel names override those from the header!
dname = 'data_bram';
cname  ='clsfr';
load(dname);
hdr.nEvents = length(devents);
hdr.nevents= length(devents);

% train classifier
clsfr=buffer_train_erp_clsfr(data,devents,hdr,'spatialfilter','ssep','freqband',[1 10 17 23 37 43],'badchrm',0,'capFile',capFile,'overridechnms',overridechnm);

fprintf('Saving classifier to : %s\n',cname);
save(cname,'-struct','clsfr');

