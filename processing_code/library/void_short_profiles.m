function [sss] = void_short_profiles(sss, profilesImported, fieldName, nptsMin, rangeMin)
%=========================================================================
% DESCRIPTION
%   Sets the sensor data of elements of the structure array sss to an
%   empty set if either there are not enough points or the range of the
%   values in 'fieldName' is too small.
%
% USAGE:  [sss] = void_short_profiles(sss, profilesImported, fieldName, nptsMin, rangeMin)
%
%   INPUT
%     sss              = an array of structures 
%     profilesImported = vector of profile numbers selected to be processed
%     fieldName        = name of a field of sss containing column vector data
%     nptsMin          = scalar; to disable set nptsMin to -1
%     rangeMin         = scalar; to disable set rangeMin to -1 
%
%   OUTPUT
%     sss              = an array of structures
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   For each element (profile) of sss(profilesImported):
%
%      if (the number of values in fieldName <= nptsMin)
%                          or
%      if (the range of the fieldName values <= rangeMin)
%
%                         then
%
%      the sensor values in those selected elements of the structure array
%      sss as determined by the indices in sss.sensor_field_indices are
%      set to empty set.    
%
%
%   Typically eng and ctd arrays will be called with 'pressure'; because
%   the data acquisition rates are known, the nptsMin selection is 
%   equivalent to putting a minimum time restriction on the profiles.
%
%   Using the profile mask (2021-02-24 modification) ensures that in the eng
%   pressure record values that are 0 marking backtrack regions are not used
%   (a) as part of the number of points count
%   (b) as the lowest pressure value when determining pressure range.
%
%   In radMMP processing when the pressure field of a ctd or eng structure 
%   array element encountered by a processing subroutine is empty, that element
%   is skipped (not processed). For ad2cp and 3dmp acoustic currentmeter data
%   data the heading field is used for the same purpose.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-17: desiderio: expanded the number of fields to be replaced by
%..             [] to include those specified by sensor_field_indices
%..             (originally only fieldName data were set to []).
%.. 2020-01-30: desiderio: because of the changes implmented 2020-01-17,
%..             customized empty set assignments to the size of each 
%..             variables' second dimension so that concatenation routines
%..             will work with 2D array variables found in AD2CP processing.
%.. 2020-02-05: desiderio: added profilesImported to calling argument list.
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-04-13: desiderio: clarified screen output
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-02-24: desiderio: now uses profile_mask (ignores ENG backtrack markers)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================
%.. operate on array elements corresponding to imported profiles only
sssImported = sss(profilesImported);

Q = {sssImported.code_history}';  % extract elements into a cell array
%.. append mfilename to each element (each profile)
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);
%.. write back out to each element of structure array
[sssImported.code_history] = QQ{:};

%.. process
%.. .. use profile_mask to catch eng pressure anomalies due to repeated
%.. .. backtracking; will not affect ctd nor aqd,acm processing.
valCell   = {sssImported.(fieldName)};
pMaskCell = {sssImported.profile_mask};
dataCell  = cellfun(@(x,y)x(y), valCell, pMaskCell, 'UniformOutput', false);
%.. .. number of data points
%.. .. if a cell in dataCell's cells is empty, its length gives npts=0;
%.. .. no need to set UniformOutput to 0; result is not a cell array.
npts = cellfun('length', dataCell);
maskNpts = npts<=nptsMin;
%.. .. range
dataCell(cellfun('isempty', dataCell)) = {0};
dataCell(cellfun(@(x) any(isnan(x)), dataCell)) = {0};
%.. should not be nans in these records at this point in the processing,
%.. but just in case
rangeCell = cellfun(@(x) nanmax(x)-nanmin(x), dataCell);
maskRange = rangeCell<=rangeMin;
%.. if an entire profile has values of nan, nanmax-nanmin = nan.
maskAllNan = isnan(rangeCell);
%.. void short profiles by assigning the key variable fields to be empty
mask = maskNpts | maskRange | maskAllNan;
allFieldNames = fieldnames(sssImported);
for ii = sssImported(1).sensor_field_indices
    %.. for flexibility in concatenating structure array fields,
    %.. set the dimensionality of the empty sets:
    %.. .. for scalars           0x0
    %.. .. for column vectors    0x0 (not 0x1)
    %.. .. for 2D arrays mxn     0xn
    dim2 = size(sssImported(1).(allFieldNames{ii}), 2);
    if dim2 == 1, dim2 = 0; end
    emptyVariable = zeros(0, dim2);
    [sssImported(mask).(allFieldNames{ii})] = deal(emptyVariable);
end

fprintf('\nNumber of short %s profiles discarded:  ', inputname(1));
if sum(mask) == 0
    fprintf('None\n\n');
else
    fprintf('%u\n', sum(mask));  
    text = num2str(profilesImported(mask));
    fprintf('profile numbers discarded:  %s\n\n', text);
end


%.. update data status for each Imported structure array element.
R = {sssImported.data_status}';  % extract for modification
Datstat(1:length(sssImported), 1) = {'noChange'};  % initialize
Datstat(mask)                     = {'allDataSetToEMPTY'};
RR = cellfun(@(x, y) [x y], R, Datstat, 'uni', 0);  % append to each element
[sssImported.data_status] = RR{:};

%.. reconstitute output strucure array argument 
sss(profilesImported) = sssImported;
