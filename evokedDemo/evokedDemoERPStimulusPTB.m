configureDemo();
initPTBPaths();

% make the stimulus
ws=Screen('windows'); % re-use existing window 
if ( isempty(ws) )
  if ( IsLinux() ) PsychGPUControl('FullScreenWindowDisablesCompositor', 1); end % exclusive disp access in FS
  screenNum = max(Screen('Screens')); % get 2nd display
  wPtr= Screen('OpenWindow',screenNum,bgColor,windowPos)
  Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % enable alpha blending
  [flipInterval nrValid stddev]=Screen('GetFlipInterval',wPtr); % get flip-time (i.e. refresh rate)
else
  wPtr=ws(1);
end

% Now make the boxes
stimPos=[]; texels=[]; destR=[]; srcR=[];
% center block, N.B. rects are [LTRB]
destR(:,1)= round(rel2pixel(wPtr,[.5-stimRadius/2/2 .5+stimRadius/2/2 .5+stimRadius/2/2 .5-stimRadius/2/2]));
srcR(:,1) = [0 destR(3,1)-destR(1,1) destR(2,1)-destR(4,1) 0];
texels(1)  = Screen('MakeTexture',wPtr,ones(srcR([2 3],1)')*255);
% left block
destR(:,2)= round(rel2pixel(wPtr,[.25-stimRadius/2/2 .5+stimRadius/2/2 .25+stimRadius/2/2 .5-stimRadius/2/2]));
srcR(:,2) = [0 destR(3,2)-destR(1,2) destR(2,2)-destR(4,2) 0];
texels(2)  = Screen('MakeTexture',wPtr,ones(srcR([2 3],2)')*255);
% right block
destR(:,3)= round(rel2pixel(wPtr,[.75-stimRadius/2/2 .5+stimRadius/2/2 .75+stimRadius/2/2 .5-stimRadius/2/2]));
srcR(:,3) = [0 destR(3,3)-destR(1,3) destR(2,3)-destR(4,3) 0];
texels(3)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],3)')*255);
% fixation point
destR(:,4)= round(rel2pixel(wPtr,[.5-stimRadius/2/4 .5+stimRadius/2/4 .5+stimRadius/2/4 .5-stimRadius/2/4]));
srcR(:,4) = [0 destR(3,4)-destR(1,4) destR(2,4)-destR(4,4) 0];
texels(4)  = Screen('MakeTexture',wPtr,ones(srcR([3 2],4)')*255);

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
tgt=ones(4,1);
endTraining=false; si=0;
sendEvent('stimulus.training','start'); 
while ( ~endTraining ) 
  si=si+1;
  
  %sleepSec(intertrialDuration);
  % wait for key press to start the next epoch  
  seqStart=false;
  while ( ~seqStart )
    KbWait; % wait for a key press
    [keyIsDown, t, keyCode] = KbCheck;  key=KbName(keyCode); % get the pressed key
    
    switch lower(key)
     case {'v','1'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Vis(texels);     seqStart=true;
     case {'a','2'}; seqStart=false; % not implemented yet! %[stimSeq,stimTime,eventSeq,colors]=mkStimSeq_Aud(texels);     seqStart=true;
     case {'s','3'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(texels,3,1/ssvepFreq(1)/2,sprintf('SSVEP %g',ssvepFreq(1)));   seqStart=true;
     case {'p','4'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_P3(texels);      seqStart=true;
     case {'f','5'}; [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_flicker(texels); seqStart=true;
     case {'q','escape'};         endTraining=true; break; % end the phase
     case {'7'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(texels,3,1/ssvepFreq(2)/2,sprintf('SSVEP %g',ssvepFreq(2)));  seqStart=true;
     case {'8'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(texels,3,1/ssvepFreq(3)/2,sprintf('SSVEP %g',ssvepFreq(3)));  seqStart=true;
     case {'9'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(texels,3,1/ssvepFreq(4)/2,sprintf('SSVEP %g',ssvepFreq(4)));  seqStart=true;
     case {'0'};     [stimSeq,stimTime,eventSeq,colors]=mkStimSeq_SSVEP(texels,3,1/ssvepFreq(5)/2,sprintf('SSVEP %g',ssvepFreq(5)));  seqStart=true;
     otherwise; fprintf('Unrecog key: %s\n',lower(key)); seqStart=false;
    end        
  end
  if ( endTraining ) break; end;

  % show the screen to alert the subject to trial start
  Screen('Drawtextures',wPtr,texels(end),srcR(:,end),destR(:,end),[],[],[],fixColor*255); 
  Screen('flip',wPtr,1,1);% re-draw the display
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');
    
  % now play the selected sequence
  seqStartTime=getwTime(); ei=0; ndropped=0; frametime=zeros(numel(stimTime),4);
  while ( stimTime(end)>=getwTime()-seqStartTime ) % frame-dropping version    
    ei=min(numel(stimTime),ei+1);
    frametime(ei,1)=getwTime()-seqStartTime;
    % find nearest stim-time
    if ( frametime(ei,1)>=stimTime(min(numel(stimTime),ei+1)) ) 
      if ( verb>=0 ) fprintf('%d) Dropped Frame!!!\n',ei); end;
      ndropped=ndropped+1;
      ei=min(numel(stimTime),ei+1);
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

    % sleep until time to re-draw the screen
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
      %sendEvent('stimulus.tgtFlash',stimSeqRow(tgtRow,ei),stimSamp); % indicate if it was a 'target' flash
      if (1||verb>0) fprintf('Event: %s\n',ev2str(ev)); end;
    end
  end
  if ( verb>0 ) % summary info
    dt=frametime(:,3)-frametime(:,2);
    fprintf('Sum: %d dropped frametime=%g drawTime=[%g,%g,%g]\n',...
            ndropped,mean(diff(frametime(:,1))),min(dt),mean(dt),max(dt));
  end
  
  % reset the cue and fixation point to indicate trial has finished  
  Screen('flip',wPtr);% re-draw the display, as blank
  sendEvent('stimulus.trial','end');
  
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');

% % thanks message
% text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),{'That ends the training phase.','Thanks for your patience'},'HorizontalAlignment','center','color',[0 1 0],'fontunits','normalized','FontSize',.1);
% pause(3);
if ( isempty(windowPos) ) Screen('closeall'); end; % close display if fullscreen
