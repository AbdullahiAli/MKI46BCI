try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

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

prompt = 'specify name of data to be saved\n';
dname = strcat('../analysis/data/',input(prompt, 's'));
trlen_ms= 700;



% Grab 700ms data after every stimulus.hybrid event
[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{{'stimulus.hybrid'} {'target','non-target'}},'exitSet',{'stimulus.training'  'end'},'trlen_ms',trlen_ms);
mi=matchEvents(devents,'stimulus.sequence','stop'); devents(mi)=[]; data(mi)=[]; % remove the exit event
fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
save(dname,'data','devents');

