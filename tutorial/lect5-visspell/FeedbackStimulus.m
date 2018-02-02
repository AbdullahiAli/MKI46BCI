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
interTrialDuration=1;
interCharDuration=0.1;
nrRepetitions=5;
clearDuration=1;


sendEvent('stimulus.feedback', 'start');
for target = 1:10;
% reset the newevents function state to only return matching events after this time
[devents,state]=buffer_newevents(buffhost,buffport,[],'classifier.prediction',[],0);
A = set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
 B=set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color','Green','visible','on'); 

% update the text displayed

set(h,'string','Think of your target and get-ready');
drawnow;
% send event annotating the start of current trial
sendEvent('stimulus.trial','startTrial');
% sleep for cue duration
sleepSec(cueDuration);
set(h,'string','');
drawnow;
sleepSec(clearDuration);
charArray = '';
for rep = 1:nrRepetitions;

alphabethShuffled = alphabet(randperm(numel(alphabet)));
charArray = strcat(charArray,alphabethShuffled);
for ch = 1:numel(alphabet);
char = alphabethShuffled(ch);
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'text','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','on'); 
% update the text displayed
set(h,'string',char);
sendEvent('stimulus.letter', char);
drawnow;
% sleep (accurately) for a certain duration
sleepSec(interCharDuration);
end
end
% sleep between trials
set(h,'string','');
drawnow;
sleepSec(interTrialDuration);
sendEvent('stimulus.sequence', 'end');
[devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
if ( ~isempty(devents) ) 
    % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
    pred =[devents.value]; % get all the classifier predictions in order
    targets  = containers.Map;
    for ch = 1:length(alphabet)
        targets(alphabet(ch)) = 0;
    end
    nPred=numel(pred);
    for i = 1:nPred
        targets(charArray(i)) = targets(charArray(i)) + pred(i);
    end
    % find maximum value
    maxKey = 'none';
    maxVal = 0;
    for i = 1:length(alphabet)
        if targets(alphabet(i)) > maxVal
            maxKey = alphabet(i);
            maxVal = targets(alphabet(i));
        end
    end
    predTgt = maxKey; % predicted target is highest classification
    
    % show the classifier prediction
    set(h,'string',predTgt, 'color', 'Blue');
    % post sequence duration
    drawnow;
    sendEvent('stimulus.prediction',predTgt);
    sleepSec(2);
    clf;
end

end
sendEvent('stimulus.feedback','end');
