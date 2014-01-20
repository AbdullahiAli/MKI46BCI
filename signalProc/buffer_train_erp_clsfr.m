function [clsfr,res,X,Y]=buffer_train_erp_clsfr(X,Y,hdr,varargin);
% train ERP (time-domain) classifier with ft-buffer based data/events input
%
%   [clsfr,res,X,Y]=buffer_train_erp_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  Y -- [epoch x 1] set of labels for the data epochs
%       OR
%       [struct epoch x 1] set of buf event structures which contain epoch labels in value field
%  hdr-- [struct] buffer header structure
% Options:
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr
% Outputs:
%  clsfr   -- [struct] a classifer structure
%  res     -- [struct] a results structure
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  Y       -- [ppepoch x 1] pre-processed labels (N.B. will have diff num examples to input!)
% See Also: train_erp_clsfr
opts=struct('capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
X=single(X);
if ( isstruct(Y) ) Y=cat(1,Y.value); end; % convert event struct into labels

fs=[]; chNames=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names;
  elseif( isfield(hdr,'label') )      chNames=hdr.label;
  end;
  if ( isfield(hdr,'fsample') )       fs=hdr.fsample; 
  elseif ( isfield(hdr,'Fs') )        fs=hdr.Fs;
  elseif( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
  end;
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
iseeg=false(size(X,1),1); iseeg([di.extra.iseeg])=true;

% call the actual function which does the classifier training
[clsfr,res,X,Y]=train_erp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
%---------
function testcase();
% buffer stuff
capFile='cap_tmsi_mobita_num';
clsfr=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','car','freqband',[.1 .3 8 10],'objFn','lr_cg','compKernel',0,'dim',3,'capFile',capFile,'overridechnms',1);
X=cat(3,traindata.buf);
apply_erp_clsfr(X,clsfr)
