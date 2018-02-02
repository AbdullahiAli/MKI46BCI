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

% set the real-time-clock to use
initgetwTime;
initsleepSec;

% set hyperparameters
alphabet= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
cueDuration=2;
interTrialDuration=3;
interCharDuration=0.1;
nrRepetitions=5;
clearDuration=1;

% make the target sequence
targets ={'A','Q','R','S','P','V','Y','X','E','M'};
% randomize target presentation & start experiment
targetsShuffled = targets(randperm(numel(targets)));
sendEvent('stimulus.experiment', 'startExperiment');
for target = 1:numel(targets);
cue = targetsShuffled{target};
A = set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
 B=set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color','Green','visible','on'); 
% update the text displayed
set(h,'string',cue);
drawnow;
% send event annotating the start of current trial
sendEvent('stimulus.trial','startTrial');
% sleep for cue duration
sleepSec(cueDuration);
set(h,'string','');
drawnow;
sleepSec(clearDuration);

for rep = 1:nrRepetitions;
% make the stimulus, i.e. put a text box in the middle of the axes
alphabethShuffled = alphabet(randperm(numel(alphabet)));

for ch = 1:numel(alphabet);
char = alphabethShuffled(ch);
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','on'); 
% update the text displayed
set(h,'string',char);
sendEvent('stimulus.letter',char); 
drawnow;
% sleep (accuratly) for a certain duration
sleepSec(interCharDuration);
end

end
% sleep between trials
set(h,'string','');
drawnow;
sleepSec(interTrialDuration);
end
