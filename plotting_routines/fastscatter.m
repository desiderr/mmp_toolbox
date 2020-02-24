function h=fastscatter(X,Y,C,varargin)
%% A fast scatter plot 
% Aslak Grinsted (2020). fastscatter.m 
% (https://www.mathworks.com/matlabcentral/fileexchange/47205-fastscatter-m),
% MATLAB Central File Exchange. Retrieved February 18, 2020.
%  
% h=fastscatter(X,Y,C [,markertype,property-value pairs])
%
% Inputs: 
%    X,Y: coordinates 
%      C: color
%
%
% Examples:
%    N=100000;  
%    fastscatter(randn(N,1),randn(N,1),randn(N,1))
%  
%    N=100;  
%    fastscatter(randn(N,1),randn(N,1),randn(N,1),'+','markersize',7)
% 
%
% Copyright (c) 2014, Aslak Grinsted
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.


marker='.';
if length(varargin)>0
	if length(varargin{1})==1
    	marker=varargin{1};varargin(1)=[];
	end
end

% %h/t to Boris Babic for the method. see http://www.mathworks.com/matlabcentral/newsreader/view_thread/22966
% h=mesh([X(:) X(:)]',[Y(:) Y(:)]',zeros(2,numel(X)),'mesh','column','marker',marker,'cdata',[C(:) C(:)]',varargin{:});
% view(2)


ix=find(~isnan(C+X+Y));
if mod(length(ix),2)==1
    ix(end+1)=ix(end);
end
ix=reshape(ix,2,[]);

h=mesh(X(ix),Y(ix),zeros(size(ix)),'marker',marker,'cdata',C(ix),'edgecolor','none','markeredgecolor','flat','facecolor','none',varargin{:});
view(2)

if nargout==0
    clear h
end