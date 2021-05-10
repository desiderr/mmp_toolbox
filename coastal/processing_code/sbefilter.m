function [xsmooth] = sbefilter(x,acqrate,gamma)
%=========================================================================
% NOTES 
% function [xsmooth] = sbefilter(x,acqrate,gamma)
%
% sbefilter smooths the data in each of the columns of
% the matrix X using the seabird seasoft filter algorithm:
% the filter is applied twice, once in the forward direction,
% then once in the backward direction so that no lag is
% introduced to the data.
%
% ACQRATE is the scalar data acquisition rate in hertz at which  
% the data in X were acquired; typically 24 for sbe9 data, 
% 8 for sbe25 data, and either 2 or 4 for sbe19 data.
%
% GAMMA is the scalar smoothing time constant in seconds.
%
%    IF GAMMA = 0 THE INPUT DATA ARE RETURNED WITH NO CHANGES.
%
% the output matrix XSMOOTH will have the same dimensions as 
% the input matrix X. 
%
% reference: seabird seasoft manual for windows, pp 71-73
%
% desiderio 05-jan-2005
% 14-dec-2010 sbefilter enabled to work on row vectors.
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2020-12-10: desiderio: handles columns of nans and 2D empty set inputs.
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================

% trivial case
if isempty(x) || gamma==0
    xsmooth=x;
    return
end

% take out NaNs before processing! else, output values
% are all NaN; then restore NaNs after processing.

% since each column of x may have a different number of NaNs,
% trying to excise NaNs in a vectorized manner can result in
% a 2-dimensional x collapsing into a column vector - no good.
% alternative - one can knock out a row if one or more of its 
% elements are NaNs, but this throws away good data in the 
% non-NaN-containing column.
% so - process one column at a time.

% calculate coeffs:
A=1/(1+2*gamma*acqrate);
B=(1-2*gamma*acqrate)*A;

%disp([A B]);

x_is_row_vector = 0;
if isrow(x)
    x=x';
    x_is_row_vector = 1;
end

[nrx, ncx]=size(x);
xsmooth=zeros(nrx,ncx);

for jcol=1:ncx
    y=x(:,jcol);
    mask=~isnan(y);
    y=y(mask);
    if isempty(y)
        %disp(' At least one column in input x is all NaN.');
        xsmooth(:,jcol) = x(:,jcol);
        continue  % enables each column to be processed separately
    end
% apply filter in the forward direction
% preallocate the size of yforward, and
% set the first element of yforward to 
% that of y
    yforward=y;
    for i=2:length(y)
        yforward(i)=A*(y(i)+y(i-1))-B*(yforward(i-1));
    end
% apply filter in the backward direction
    ysmooth=yforward;
    for i=length(y)-1:-1:1
        ysmooth(i)=A*(yforward(i)+yforward(i+1))-B*(ysmooth(i+1));
    end
% reconstitute ysmooth with original placement of NaNs
    yrecon=nan(nrx,1);
    yrecon(mask)=ysmooth;
    xsmooth(:,jcol)=yrecon;
end

if (x_is_row_vector == 1)
    xsmooth = xsmooth';
end
