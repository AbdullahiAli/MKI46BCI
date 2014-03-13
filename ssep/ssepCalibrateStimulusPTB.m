configureSSEP;

% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  if ( IsLinux() ) PsychGPUControl('FullScreenWindowDisablesCompositor', 1); end % exclusive disp access in FS
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
  [width,height]=Screen('WindowSize',wPtr); 
else
  wPtr=ws(1);
end
% Now make the boxes
stimPos=[]; texels=[]; destR=[]; srcR=[];
theta=linspace(0,2*pi*(nSymbs-1)/nSymbs,nSymbs); 
for stimi=1:nSymbs;
  % N.B. move to the postive quadrant and shrink to be in 0-1 range.  Also stimRadius/2 for same reason
  x=cos(theta(stimi))*.75/2+.5; y=sin(theta(stimi))*.75/2+.5;
  % N.B. PTB measures y from the top of the screen!
  destR(:,stimi)= round(rel2pixel(wPtr,[x-stimRadius/4 1-y+stimRadius/4 x+stimRadius/4 1-y-stimRadius/4]));
  srcR(:,stimi) = [0 destR(3,1)-destR(1,1) destR(2,1)-destR(4,1) 0];
  texels(stimi)  = Screen('MakeTexture',wPtr,ones(srcR([2 3],1)')*255);
end
% fixation point
destR(:,nSymbs+1)= round(rel2pixel(wPtr,[.5-stimRadius/8 .5+stimRadius/8 .5+stimRadius/8 .5-stimRadius/8]));
srcR(:,nSymbs+1) = [0 destR(3,3)-destR(1,3) destR(2,3)-destR(4,3) 0];
texels(nSymbs+1)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],3)')*255);

endTraining=false;
sendEvent('stimulus.training','start'); 
for seqi=1:nSeq;
  % make the target sequence
  tgtSeq=mkStimSeqRand(numel(texels)-1,seqLen);

  % play the stimulus
  % reset the cue and fixation point to indicate trial has finished  
  sendEvent('stimulus.sequence','start');
  for si=1:size(tgtSeq,2);
    
    sleepSec(intertrialDuration);

    % show the screen to alert the subject to trial start
    Screen('Drawtextures',wPtr,texels(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
    Screen('flip',wPtr,1,1);% re-draw the display
    sendEvent('stimulus.baseline','start');
    sleepSec(baselineDuration);
    sendEvent('stimulus.baseline','end');  
    
    tgtId=find(tgtSeq(:,si)>0);
    fprintf('%d) tgt=%s : ',si,classes{tgtId});
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    Screen('Drawtextures',wPtr,texels(tgtId),srcR(:,tgtId),destR(:,tgtId),[],[],[],tgtColor*255); 
    Screen('flip',wPtr);% re-draw the display
    ev=sendEvent('stimulus.target',classes{tgtId});
    if ( verb>1 ) fprintf('Sending target : %s\n',ev2str(ev)); end;
    sleepSec(cueDuration);
    Screen('Drawtextures',wPtr,texels,srcR,destR,[],[],[],bgColor*255); 
    Screen('flip',wPtr);% re-draw the display
    
    % make the stim-seq for this trial
    [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(texels,trialDuration,isi,periods,false);
    % now play the sequence
    sendEvent('stimulus.stimSeq',stimSeq(tgtId,:)); % event is actual target stimulus sequence
    seqStartTime=getwTime(); ei=0; ndropped=0; syncEvtTime=seqStartTime; frametime=zeros(numel(stimTime),4);
    while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
      ei=min(numel(stimTime),ei+1);
      frametime(ei,1)=getwTime()-seqStartTime;
      % find nearest stim-time, dropping frames is necessary to say on the time-line
      if ( frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
        oei = ei;
        for ei=ei+1:numel(stimTime); if ( frametime(oei,1)<stimTime(ei) ) break; end; end; % find next valid frame
        if ( verb>=0 ) fprintf('%d) Dropped %d Frame(s)!!!\n',ei,ei-oei); end;
        ndropped=ndropped+(ei-oei);
      end
      ss=stimSeq(:,ei);
      Screen('Drawtextures',wPtr,texels(ss>=0),srcR(:,ss>=0),destR(:,ss>=0),[],[],[],bgColor*255); 
      if(any(ss==1))
        Screen('Drawtextures',wPtr,texels(ss==1),srcR(:,ss==1),destR(:,ss==1),[],[],[],colors(:,1)*255); 
      end% stimSeq codes into a colortable
      if(any(ss==2))
        Screen('Drawtextures',wPtr,texels(ss==2),srcR(:,ss==2),destR(:,ss==2),[],[],[],colors(:,2)*255); 
      end;
      if(any(ss==3))
        Screen('Drawtextures',wPtr,texels(ss==3),srcR(:,ss==3),destR(:,ss==3),[],[],[],colors(:,3)*255); 
      end;

      % sleep until just before the next re-draw of the screen
      % then let PTB do the waiting until the exact right time
      sleepSec(max(0,stimTime(ei)-(getwTime()-seqStartTime)-flipInterval/2)); 
      if ( verb>0 ) frametime(ei,2)=getwTime()-seqStartTime; end;
      Screen('flip',wPtr,0,0,0);% re-draw the display, but wait for the re-fresh
      if ( verb>0 ) 
        frametime(ei,3)=getwTime()-seqStartTime;
        fprintf('%d) dStart=%8.6f dEnd=%8.6f stim=[%s] lag=%g\n',ei,...
                frametime(ei,2),frametime(ei,3),...
                sprintf('%d ',stimSeq(:,ei)),stimTime(ei)-(getwTime()-seqStartTime));
      end
      % send event saying what the updated display was
      if ( ~isempty(eventSeq{ei}) ) 
        ev=sendEvent(eventSeq{ei}{:}); 
        if (verb>0) fprintf('Event: %s\n',ev2str(ev)); end;
      end
      if ( frametime(ei,1)>syncEvtTime+1 ) % once per second a sync event
        syncEvtTime=frametime(ei,1);
        sendEvent('stimulus.frameNumber',ei);
      end
    end % while < endTime
    if ( verb>0 ) % summary info
      dt=frametime(:,3)-frametime(:,2);
      fprintf('Sum: %d dropped frametime=%g drawTime=[%g,%g,%g]\n',...
              ndropped,mean(diff(frametime(:,1))),min(dt),mean(dt),max(dt));
    end
    
    Screen('flip',wPtr);% re-draw the display, as blank
    sendEvent('stimulus.trial','end');
    
    fprintf('\n');
  end % epochs within a sequence

  if ( seqi<nSeq ) %wait for key press to continue
    msg=msgbox({sprintf('End of sequence %d/%d.',seqi,nSeq) 'Press OK to continue.'},'Thanks','modal');
    if ( ishandle(msg) ) 
      uiwait(msg,10); % wait max of 10sec
      if ( ishandle(msg) ) delete(msg); end;
    end; 
  end

end % sequences
% end training marker
sendEvent('stimulus.training','end');

% thanks message
%msgbox({'That ends the training phase.','Thanks for your patience'},'Thanks','modal');
%pause(1);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen