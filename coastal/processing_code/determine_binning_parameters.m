function [Zmin, Zbin, Zmax] = determine_binning_parameters(xtruct, fieldname)
%=========================================================================
% DESCRIPTION
%   Outputs minimum bin value, bin size, and maximum bin value preparatory
%   to binning profile data.
%
% USAGE:  [Zmin, Zbin, Zmax] = determine_binning_parameters(xtruct, fieldname)
%
%   INPUT 
%     xtruct    = an array of structures with at least two fields:
%                 (a) 'binning_parameters', which on input are either all 
%                 scalars denoting binsize or all 3 element vectors denoting
%                 minimum binvalue, binsize, and maximum binvalue.
%                 (b) fieldname
%     fieldname = the name of a field in the array of structures xtruct;
%                 usually fieldname = 'pressure'
%
%   OUTPUT
%     Zmin = minimum (centered) bin value
%     Zbin = binsize
%     Zmax = maximum (centered) bin value
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Currently only pressure binning is supported in the processing code, so
%   that this function will always be called with the second argument as
%   'pressure'. 
%
%   Action:
%   (a) If the 'binning_parameters' values of the array elements of xtruct are
%       scalars then that scalar is set to Zbin, and Zmin and Zmax are
%       calculated based on all of the fieldname ('pressure') values in
%       the array elements of xtruct.
%   (b) If instead the 'binning_parameters' values are 3-element row vectors,
%       then those values are accepted as [Zmin Zbin Zmax].
%   (c) Zmax is adjusted so that (Zmax-Zmin) is an integral multiple of binsize
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================

%.. it may be possible that a few of the profiles (a few elements of xstruct)
%.. could have trivial values for the field binning_parameters, but the vast
%.. majority will have identical binning_parameter values. therefore a median
%.. is taken of the input field values in all of the elements of xtruct.
%
%.. this statement retains the dimensionality of binning_parameters
%.. .. make sure to operate on columns in case only one profile in the
%.. .. deployment is to be processed.
binParms = median(cell2mat({xtruct.binning_parameters}'), 1);

if isscalar(binParms)  % only binsize was specified
    Zbin = binParms;
    if isempty(Zbin) || isnan(Zbin) || Zbin <= 0
        disp(' ');
        disp('*** Could not determine user-binsize: using default = 1. ***');
        disp(' ');
        Zbin = 1;
    end
    %.. find minimum and maximum values in the binning record.
    z = {xtruct.(fieldname)};  % collect fields in a cell array
    z = cat(1, z{:});  % sufficient if the fields are all column vectors
    z = z(:);          % necessary if the fields are all row vectors
    z(isnan(z)) = [];
    %
    zmin = min(z);
    zmax = max(z);
    %.. bin values will be centered, so to catch zmin, add half a bin, then
    %.. floor to get the nearest integer.
    Zmin = floor(zmin + binParms/2);
    %.. at the high end, subtract half a bin and ceil it
    Zmax = ceil(zmax - binParms/2);
else  % bin min, size, and max are all specified
    Zmin = binParms(1);
    Zbin = binParms(2);
    Zmax = binParms(3);
end

%.. set (Zmax - Zmin) to be an integral multiple of binsize for the fast
%.. binning algorithm used in pressure_bin_mmp_data.m
Zmax = Zmin + Zbin * ceil((Zmax - Zmin) / Zbin);
