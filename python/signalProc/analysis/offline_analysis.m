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

% Constants
capFile='Capfile_hybrid.txt';
overridechnm=1; % capFile channel names override those from the header!
dname = '../data_right_bram';
cname  ='clsfr';

load(dname);
% train classifier
clsfr=buffer_train_erp_clsfr(data,devents,hdr,'spatialfilter','SLAP','freqband',[1 49],'badchrm',0,'capFile',capFile,'overridechnms',overridechnm);

fprintf('Saving classifier to : %s\n',cname);
save(cname,'-struct','clsfr');
%sendEvent('phase.training','start');
