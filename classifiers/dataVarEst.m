function var=dataVarEst(X,dim,varThresh,kernelp)
% estimate the variance/radius of the data as outlier-rejected variance estimate
%
% var=dataVarEst(X,dim,varThresh,kernelp)
%
% Inputs:
%  X   - [n-d] data to estimate scaling for, examples in dimension dim
%  dim - [int] dimension(s) which contain examples (ndims(X))
%  varThresh - threshold in std-deviations used for outlier rejection in 
%              variance/radius estimation (4)
%  kernelp   - [bool] flag that input is a kernel
if ( nargin < 2 || isempty(dim) ) dim=ndims(X); end;
if ( nargin < 3 || isempty(varThresh) ) varThresh=4; end;
if ( nargin < 4 ) kernelp=[]; end;
dim=dim(:); % ensure col vector
szX=size(X);
if ( isempty(kernelp) ) % guess if it's a kernel
  kernelp=( all(dim==(1:numel(dim))') || all(dim==(numel(dim)+(1:numel(dim))')) ) && ...
          ndims(X)>=numel(dim)*2 && (all(szX(1:numel(dim))==szX(numel(dim)+(1:numel(dim)))));
end
if ( kernelp ) % kernel input
  N=prod(szX(dim));
  K=reshape(X,[N N szX(2*dim(end)+1:end)]);
  var=[]; 
  diagIdx=1:N+1:N*N; % get diag elements from a sub kernel
  Kv=reshape(K,[],size(K,3)); % remake into a vector for indexing speed
  sKv = sum(Kv,1); % sum each kernel in advance for speed
  for ki=1:size(K,3);      %make work with multi-kernels
    varx=Kv(diagIdx,ki);
    si=varx(:)>0; % neg eig detection
    stdvarx = sqrt(sum((varx(si)-mean(varx(si))).^2)./sum(si));
    si=(varx(si)<=median(varx(si))+varThresh*stdvarx+eps); % outlier detection   
    if ( ~all(si) )
      var(ki) = mean(varx(si))-(sKv(ki)-sum(sum(K(~si,:,ki)))-sum(sum(K(:,~si,ki)))+sum(sum(K(~si,~si,ki))))./(sum(si)*sum(si));
    else      
      var(ki) = mean(varx)-sKv(ki)./(N*N);
    end
  end
  var = sum(var);
else
  varx=mvar(X,dim); % variance along each dir
  si=varx(:)>0;
  stdvarx = sqrt(sum((varx(si)-mean(varx(si))).^2)./sum(si));
  si=(varx(si)<=median(varx(si))+varThresh*stdvarx+eps); % outlier detection
  var = sum(varx(si)); % var is ave var
end
return;