function [y] = Toolebox_shift(x, t)
%=========================================================================
% NOTES
%
%.. With very slight modification, this routine is the same as MP_shift
%.. from MPproc, McLane processing code from Gunnar Voet's GitHub repository:
%
%    https://github.com/modscripps/MPproc/blob/master/mpproc/MP_shift.m 
%
%.. It may have originally come from McLane processing code used and\or
%.. written by John Toole at Woods Hole.
%
%.. The documentation marked by %.. is new. Toolebox_shift is probably 
%.. faster than any vector shift routine which uses interp1.
%
%.. INPUTS: x can be either a row or column vector representing a time
%..         series of equally spaced points.
%
%..         t is the shift in vector index to be applied to the time
%..         series; t may be positive, negative, or integral; or have a
%..         fractional part, which will result in linear interpolation.
%
%..         Negative values of t shift the time series x to EARLIER time.
%..         Positive values of t shift the time series x to LATER time.
%
%.. OUTPUT: y is the shifted time series x. The ends of y are padded with
%..         the first or last value of x as appropriate.
%
%.. included as a part of:
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%=========================================================================

y = x;  % ensure size is retained (dpw,5/05)
if t==0
  return;
end

N = length(x);
int_shift = floor(t);
part_shift = t-int_shift; 
% Notice that part_shift is always greater or equal to zero.

if int_shift>0
  y(int_shift+1:N) = x(1:N-int_shift);
  y(1:int_shift) = x(1);
elseif int_shift<0
  y(1:N+int_shift) = x(1-int_shift:N);
  y(N+int_shift+1:N) = x(N);
%.. else       %.. this branch is no longer necessary.
%.. y=x;
end

if part_shift>0
    y(2:N) = (1-part_shift)*diff(y)+y(1:N-1);
    %.. for negative non-integer shifts, the original MP_shift algorithm
    %.. does not interpolate to calculate the first term; this should be
    %.. insignificant when processing McLane profiles, but for 
    %.. completeness here it is.
    if t<0
        y(1) = x(-int_shift) + ...
            (1-part_shift) * (x(1-int_shift) - x(-int_shift));
    end
    
end

end  % function Toolebox_shift
