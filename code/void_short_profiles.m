function [sss] = void_short_profiles(sss, fieldName, nptsMin, rangeMin)
%=========================================================================
% DESCRIPTION
%   Sets the value in the 'fieldname' field of elements of the structure array
%   sss to [] if either there are not enough points or the range of the values
%   in 'fieldname' is too small.
%
% USAGE:  [sss] = void_short_profiles(sss, fieldName, nptsMin, rangeMin)
%
%   INPUT
%     sss       = an array of structures 
%     fieldName = name of a field of sss containing column vector data
%     nptsMin   = scalar; to disable set nptsMin to -1
%     rangeMin  = scalar; to disable set rangeMin to -1 
%
%   OUTPUT
%     sss       = an array of structures
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   For each element (profile) of the structure array sss:
%
%      if (the number of values in fieldName <= nptsMin)
%                          or
%      if (the range of the fieldName values <= rangeMin)
%
%                         then
%
%      fieldName values in those elements of the structure array are set to []    
%
%
%   In radMMP processing when the pressure field of a ctd or eng structure 
%   array element encountered by a processing subroutine is empty, that element
%   is skipped (not processed). For ad2cp data the heading field is used for 
%   the same purpose.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================

%.. here dealing with an input of an entire structure array, 
%.. instead of one element of a structure array as is usual.
Q = {sss.code_history}';  % extract elements into a cell array
%.. append mfilename to each element (each profile)
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);
%.. write back out to each element of structure array
[sss.code_history] = QQ{:};

%.. process
%.. .. number of data points
%.. .. if the data in fieldname is already empty, its length gives npts=0;
%.. .. no need to set UniformOutput to 0 and result is not a cell array.
npts = cellfun('length', {sss.(fieldName)});
maskNpts = npts<=nptsMin;
%.. .. range
valCell = {sss.(fieldName)};
valCell(cellfun('isempty', valCell)) = {0};
valCell(cellfun(@(x) any(isnan(x)), valCell)) = {0};
maskRange = cellfun(@(x) max(x)-min(x)<=rangeMin, valCell);

%.. void short profiles by assigning the key variable fieldName to be empty
mask = maskNpts | maskRange;
[sss(mask).(fieldName)] = deal([]);

disp(' ');
msg = [inputname(1) ' profile numbers with ' fieldName ' records now set to []:'];
disp(msg);
if sum(mask) == 0
    disp('None');
else
    disp(num2str(find(mask)));
end
disp(' ');

%.. update data status for each profile
R = {sss.data_status}';  % extract
Datstat(1:length(sss), 1) = {'noChange'};
Datstat(mask) = {[upper(fieldName) 'settoEMPTY']};
RR = cellfun(@(x, y) [x y], R, Datstat, 'uni', 0);  % append to each element
[sss.data_status] = RR{:};
