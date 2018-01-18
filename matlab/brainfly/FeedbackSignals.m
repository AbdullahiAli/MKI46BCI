try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end
try; cd(fileparts(mfilename('fullpath')));catch; end; %ARGH! fix bug with paths on Octave
  
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

verb=0;
cname='clsfr';
trlen_ms=700;
clsfr=load(cname);if(isfield(clsfr,'clsfr'))clsfr=clsfr.clsfr;end;

state=[]; 
endTest=0; 
while ( endTest==0 )
  % reset the sequence info
  endSeq=0; 
 
  while ( endSeq==0 && endTest==0 )
    % wait for data to apply the classifier to
    [data,devents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{'stimulus.hybrid'},'trlen_ms',trlen_ms,'exitSet',{'data' {'stimulus.sequence' 'stimulus.feedback' 'test'} 'end'});
    % process these events
    for ei=1:numel(devents)
        
      if ( matchEvents(devents(ei),'stimulus.sequence','end') ) % end sequence
        endSeq=ei; % record which is the end-seq event
      elseif (matchEvents(devents(ei),'stimulus.feedback','end') ) % end training
        endTest=ei; % record which is the end-feedback event
      elseif (matchEvents(devents(ei),'test','end') ) % end testing
           endTest=0;
      elseif ( matchEvents(devents(ei),{'stimulus.hybrid'}) ) % flash, apply the classifier
        if ( verb>0 ) fprintf('Processing event: %s',ev2str(devents(ei))); end;
        % apply classification pipeline to this events data
        
       [f,fraw,p]=buffer_apply_erp_clsfr(data(ei).buf,clsfr);
       last_event = 0;
       value = devents(ei).value;
     
       if(f < 0)
            if strcmp(value, 'left')
                sendEvent('classifier.prediction', -1);
                disp('left');
            else
                sendEvent('classifier.prediction', 1);
                disp('right');
            end
       
       else
           if strcmp(value, 'left')
                sendEvent('classifier.prediction', 1);
                disp('right');
            else
                sendEvent('classifier.prediction', -1);
                disp('left');
            end
          
       end
     
        if ( verb>0 ) fprintf(' = %g',f); end;
      end
    end % devents 
  end % sequences
  
end % feedback phase