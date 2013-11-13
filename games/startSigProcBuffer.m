% buffer controlled execution of the different signal processing phases.
%
% Input events: (type,value)
%  (startPhase.cmd,capfitting) -- show capfitting
%  (startPhase.cmd,calibrate)  -- start calibration phase processing (i.e. cat data)
%  (startPhase.cmd,testing)    -- start test phase, i.e. on-line prediction generation
%  (startPhase.cmd,exit)       -- stop everything
if ( ~exist('gameConfigured') || isempty(gameConfigured) ) configureGame; end;

if ( ~exist('capFile','var') ) capFile='1010'; end; %'cap_tmsi_mobita_num'; 
if ( ~isempty(strfind(capFile,'tmsi')) ) thresh=[.0 .1 .2 5]; badchThresh=1e-4; overridechnms=1;
else                                     thresh=[.5 3];  badchThresh=.5;   overridechnms=0;
end
datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));
dname='training_data';
cname='clsfr';
testname='testing_data';
if ( ~exist('verb','var') ) verb =2; end;
subject='test';

% startup the buffer etc. to wait for phase control events.
buffhost='localhost'; buffport=1972;
global ft_buff; ft_buff=struct('host',buffhost,'port',buffport);
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    fprintf('Waiting for header\n');
    hdr=[];
  end;
  pause(1);
end;
% do the initial clock alignment
initgetwTime;  initsleepSec;

% main loop waiting for commands and then executing them
state=struct('pending',[],'nevents',[],'nsamples',[],'hdr',hdr); 
phaseToRun=[]; clsSubj=[]; trainSubj=[];
while ( true )

  if ( ~isempty(phaseToRun) ) state=[]; end
  drawnow;
  
  % wait for a phase control event
  if ( verb>0 ) fprintf('Waiting for phase command\n'); end;
  [data,devents,state]=buffer_waitData(buffhost,buffport,state,'trlen_ms',0,'exitSet',{{'startPhase.cmd' 'subject'}},'verb',verb,'timeOut_ms',5000);   
  if ( numel(devents)==0 ) 
    continue;
  elseif ( numel(devents)>1 ) 
    % ensure events are processed in *temporal* order
    [ans,eventsorder]=sort([devents.sample],'ascend');
    data=data(eventsorder); devents=devents(eventsorder);
  end
  if ( verb>0 ) fprintf('Got Event: %s\n',ev2str(devents)); end;
  
  % extract the subject info
  phaseToRun=[];
  for di=1:numel(devents);
    % extract the subject info
    if ( strcmp(devents(di).type,'subject') )     
      subject=devents(di).value; 
      if ( verb>0 ) fprintf('Setting subject to : %s\n',subject); end;
      continue; 
    else
      phaseToRun=devents(di).value;
      break;
    end  
  end
  if ( isempty(phaseToRun) ) continue; end;
  fprintf('%d) Starting phase : %s\n',getwTime(),phaseToRun);
  
  switch lower(phaseToRun);
    
    %---------------------------------------------------------------------------------
   case 'capfitting';
    if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
    sendEvent(lower(phaseToRun),'start'); % mark start/end testing
    capFitting('noiseThresholds',thresh,'badChThreshold',badchThresh,'verb',verb,'showOffset',0,'capFile',capFile,'overridechnms',overridechnms);
    sendEvent(lower(phaseToRun),'end'); % mark start/end testing
    if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;

    %---------------------------------------------------------------------------------
   case 'eegviewer';
    if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
    sendEvent(lower(phaseToRun),'start'); % mark start/end testing
    eegViewer(buffhost,buffport,'capFile',capFile,'overridechnms',overridechnms);
    sendEvent(lower(phaseToRun),'end'); % mark start/end testing
    if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;        
    
   %---------------------------------------------------------------------------------
   case 'calibrate';
    if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
    [traindata,traindevents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{'stimulus.tgtFlash'},'exitSet',{'stimulus.training' 'end'},'verb',verb,'trlen_ms',trlen_ms);
    mi=matchEvents(traindevents,'stimulus.training','end'); traindevents(mi)=[]; traindata(mi)=[];%remove exit event
    fprintf('Saving %d epochs to : %s\n',numel(traindevents),[dname '_' subject '_' datestr]);
    save([dname '_' subject '_' datestr],'traindata','traindevents');
    trainSubj=subject;
    sendEvent(lower(phaseToRun),'end'); % mark start/end testing
    if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;

    %---------------------------------------------------------------------------------
   case {'train','training'};
    try
      if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
      if ( ~isequal(trainSubj,subject) || ~exist('traindata','var') )
        fprintf('Loading training data from : %s\n',[dname '_' subject '_' datestr]);
        load([dname '_' subject '_' datestr]); 
        trainSubj=subject;
      end;
      if ( verb>0 ) fprintf('%d epochs\n',numel(traindevents)); end;
      sendEvent(lower(phaseToRun),'start'); % mark start/end testing
      [clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car','freqband',[.1 .3 8 10],'badchrm',1,'badtrrm',1,'objFn','lr_cg','compKernel',0,'dim',3,'capFile',capFile,'overridechnms',overridechnms);
      clsSubj=subject;
      fprintf('Saving classifier to : %s\n',[cname '_' subject '_' datestr]);
      save([cname '_' subject '_' datestr],'-struct','clsfr');
      if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
    catch
      fprintf('Error in train classifier!');
    end
    sendEvent(lower(phaseToRun),'end'); % mark start/end testing

    %---------------------------------------------------------------------------------
   case {'test','testing'};
    if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;
    sendEvent(lower(phaseToRun),'start'); % mark start/end testing
    gameApplyClsfr(clsfr,'nSymbs',nSymbs,'verb',verb,'margin',15,'minEvents',nSymbs,'saveFile',[testname '_' subject '_' datestr]);
    sendEvent(lower(phaseToRun),'end');    
    if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;

    
    %---------------------------------------------------------------------------------
   case {'contfeedback'};
    if ( verb>0 ) fprintf('Starting : %s\n',phaseToRun); ptime=getwTime(); end;
    if ( ~isequal(clsSubj,subject) || ~exist('clsfr','var') ) 
      clsfrfile = [cname '_' subject '_' datestr];
      if ( ~exist([clsfrfile '.mat'],'file') ) clsfrfile=[cname '_' subject]; end;
      if(verb>0)fprintf('Loading classifier from file : %s\n',clsfrfile);end;
      clsfr=load(clsfrfile);
      clsSubj = subject;
    end;
    sendEvent(lower(phaseToRun),'start'); % mark start/end testing
    spContFeedbackSignals()
    sendEvent(lower(phaseToRun),'end');    
    if ( verb>0 ) fprintf('Finished : %s @ %5.3fs\n',phaseToRun,getwTime()-ptime); end;
    
   case 'exit';
    break;
    
   otherwise;
    warning(sprintf('Unrecognised experiment phase ignored! : %s',phaseToRun));
    
  end
end

%uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);